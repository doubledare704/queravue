package diagram

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"math"
	"slices"
	"strings"
	"sync"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
)

const (
	checkedValues     = 20
	checkTimeoutMS    = 500
	checkTimeout      = checkTimeoutMS * time.Millisecond
	maxChecked        = 200
	parallelChecks    = 4
	checkedConfidence = 0.95
	// Under this share of values found in the target, a guess is dropped.
	minFoundShare = 0.5
)

type guess struct {
	table, relation int
}

// checkGuesses looks up a few values of each inferred relation in the
// collection it points at and adjusts or drops the guess by how many exist.
// A check that fails or times out leaves the guess as it was.
func checkGuesses(ctx context.Context, store engine.DocumentStore, database string, g *Graph) error {
	var guesses []guess
	for ti, t := range g.Tables {
		for ri, r := range t.Relations {
			if r.Inferred && len(guesses) < maxChecked {
				guesses = append(guesses, guess{ti, ri})
			}
		}
	}
	shares := make([]float64, len(guesses))
	next := make(chan int)
	var wg sync.WaitGroup
	for range parallelChecks {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for i := range next {
				gs := guesses[i]
				shares[i] = foundShare(ctx, store, database, g.Tables[gs.table].Name, g.Tables[gs.table].Relations[gs.relation])
			}
		}()
	}
feed:
	for i := range guesses {
		select {
		case next <- i:
		case <-ctx.Done():
			break feed
		}
	}
	close(next)
	wg.Wait()
	if err := ctx.Err(); err != nil {
		return fmt.Errorf("diagram: check guessed relations: %w", err)
	}
	dropped := map[guess]bool{}
	for i, gs := range guesses {
		r := &g.Tables[gs.table].Relations[gs.relation]
		switch share := shares[i]; {
		case share < 0:
		case share == 1:
			r.Confidence = math.Max(r.Confidence, checkedConfidence)
		case share < minFoundShare:
			dropped[gs] = true
		default:
			r.Confidence = math.Round(r.Confidence*share*100) / 100
		}
	}
	for ti := range g.Tables {
		kept := g.Tables[ti].Relations[:0]
		for ri, r := range g.Tables[ti].Relations {
			if !dropped[guess{ti, ri}] {
				kept = append(kept, r)
			}
		}
		g.Tables[ti].Relations = kept
	}
	return nil
}

// foundShare is the share of sampled values of r found as _id in its target,
// or -1 when that could not be told.
func foundShare(ctx context.Context, store engine.DocumentStore, database, collection string, r Relation) (share float64) {
	defer func() {
		if recover() != nil {
			share = -1
		}
	}()
	ctx, cancel := context.WithTimeout(ctx, checkTimeout)
	defer cancel()
	segments := slices.DeleteFunc(strings.Split(r.Columns[0], "."), func(s string) bool { return s == "[]" })
	field := strings.Join(segments, ".")
	quoted, _ := json.Marshal(field)
	values := &valueSink{segments: segments, seen: map[string]bool{}}
	err := store.Find(ctx, engine.FindOptions{
		Database: database, Collection: collection,
		Filter:     fmt.Sprintf(`{%s: {"$exists": true, "$ne": null}}`, quoted),
		Projection: fmt.Sprintf(`{%s: 1}`, quoted),
		Limit:      checkedValues,
	}, values)
	if err != nil || len(values.values) == 0 {
		return -1
	}
	count, err := store.Count(ctx, database, r.ReferencedTable,
		`{"_id": {"$in": [`+strings.Join(values.values, ", ")+`]}}`, checkTimeoutMS)
	if err != nil {
		return -1
	}
	return math.Min(1, float64(count.N)/float64(len(values.values)))
}

// valueSink keeps the distinct values at a dotted path of each document,
// reaching into arrays as MongoDB dot notation does.
type valueSink struct {
	segments []string
	seen     map[string]bool
	values   []string
}

func (s *valueSink) Batch(docs []engine.Document) error {
	for _, doc := range docs {
		var v any
		d := json.NewDecoder(strings.NewReader(doc))
		d.UseNumber()
		if err := d.Decode(&v); err != nil {
			return fmt.Errorf("diagram: read sampled value: %w", err)
		}
		s.collect(v, s.segments)
		if len(s.values) >= checkedValues {
			return engine.ErrStopDocs
		}
	}
	return nil
}

func (s *valueSink) collect(v any, rest []string) {
	if list, ok := v.([]any); ok {
		for _, item := range list {
			s.collect(item, rest)
		}
		return
	}
	if len(rest) == 0 {
		s.keep(v)
		return
	}
	if doc, ok := v.(map[string]any); ok {
		s.collect(doc[rest[0]], rest[1:])
	}
}

func (s *valueSink) keep(v any) {
	if v == nil || len(s.values) >= checkedValues {
		return
	}
	var buf bytes.Buffer
	enc := json.NewEncoder(&buf)
	enc.SetEscapeHTML(false)
	if enc.Encode(v) != nil {
		return
	}
	text := strings.TrimSpace(buf.String())
	if !s.seen[text] {
		s.seen[text] = true
		s.values = append(s.values, text)
	}
}

var _ engine.DocSink = (*valueSink)(nil)
