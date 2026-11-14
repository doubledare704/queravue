package diagram

import (
	"context"
	"fmt"
	"math"
	"slices"
	"strings"
	"sync"
	"unicode"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/session"
)

// Documents sampled per collection when the request names no size, and at most.
const (
	DefaultSampleSize = 100
	MaxSampleSize     = 1000
)

const (
	idField         = "_id"
	objectIDType    = "objectId"
	parallelSamples = 4
	// A match on the last words of a name is less sure than on all of it.
	shortenedNamePenalty = 0.2
)

// SampleSizeOf turns a requested sample size into the one used: 0 means
// DefaultSampleSize, and larger requests are cut to MaxSampleSize.
func SampleSizeOf(requested uint32) uint32 {
	if requested == 0 {
		return DefaultSampleSize
	}
	return min(requested, MaxSampleSize)
}

func loadSampled(ctx context.Context, sess *session.Session, inspector engine.SchemaInspector, store engine.DocumentStore, scope Scope) (*Graph, error) {
	var objects []engine.SchemaObject
	var samples map[string]engine.FieldPathSample
	var graph *Graph
	err := sess.RunWhenFree(ctx, func(ctx context.Context) (err error) {
		if objects, err = inspector.ListObjects(ctx, scope.Database, scope.Schema); err != nil {
			return fmt.Errorf("diagram: list collections: %w", err)
		}
		if samples, err = sampleAll(ctx, store, scope.Database, objects, SampleSizeOf(scope.SampleSize), scope.OnSampled); err != nil {
			return err
		}
		graph = Infer(objects, samples)
		return checkGuesses(ctx, store, scope.Database, graph)
	})
	if err != nil {
		return nil, err
	}
	return graph, nil
}

func sampleAll(ctx context.Context, store engine.DocumentStore, database string, objects []engine.SchemaObject, size uint32, onSampled func(sampled, total int)) (map[string]engine.FieldPathSample, error) {
	ctx, cancel := context.WithCancel(ctx)
	defer cancel()
	var mu sync.Mutex
	samples := make(map[string]engine.FieldPathSample, len(objects))
	var firstErr error
	fail := func(err error) {
		mu.Lock()
		defer mu.Unlock()
		if firstErr == nil {
			firstErr = err
			cancel()
		}
	}
	names := make(chan string)
	var wg sync.WaitGroup
	for range parallelSamples {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for name := range names {
				sample, err := sampleOne(ctx, store, database, name, size)
				if err != nil {
					fail(err)
					continue
				}
				mu.Lock()
				samples[name] = sample
				if onSampled != nil {
					onSampled(len(samples), len(objects))
				}
				mu.Unlock()
			}
		}()
	}
feed:
	for _, o := range objects {
		select {
		case names <- o.Name:
		case <-ctx.Done():
			break feed
		}
	}
	close(names)
	wg.Wait()
	if firstErr != nil {
		return nil, firstErr
	}
	if err := ctx.Err(); err != nil {
		return nil, fmt.Errorf("diagram: sample collections: %w", err)
	}
	return samples, nil
}

func sampleOne(ctx context.Context, store engine.DocumentStore, database, collection string, size uint32) (sample engine.FieldPathSample, err error) {
	defer func() {
		if r := recover(); r != nil {
			err = fmt.Errorf("diagram: sample %s: panic: %v", collection, r)
		}
	}()
	sample, err = store.SampleFieldPaths(ctx, database, collection, engine.PathSampleOptions{SampleSize: size})
	if err != nil {
		return sample, fmt.Errorf("diagram: sample %s: %w", collection, err)
	}
	return sample, nil
}

// Infer builds the graph of a document database from one sample per
// collection. Fields become columns, most frequent first; a field whose name
// and type point at another collection's _id becomes an inferred relation.
// The rules are in docs/diagrams.md.
func Infer(objects []engine.SchemaObject, samples map[string]engine.FieldPathSample) *Graph {
	targets := newTargetIndex(objects, samples)
	g := &Graph{Tables: make([]Table, len(objects))}
	for i, o := range objects {
		sample := samples[o.Name]
		paths := orderedPaths(sample.Paths)
		t := Table{Name: o.Name, Type: o.Type, EstimatedRows: o.EstimatedRows, ColumnsTruncated: sample.Truncated}
		for _, p := range paths {
			if len(t.Columns) == MaxColumnsPerTable {
				t.ColumnsTruncated = true
				break
			}
			t.Columns = append(t.Columns, sampledColumn(o.Name, p))
		}
		for _, p := range paths {
			if r, ok := targets.reference(p); ok {
				t.Relations = append(t.Relations, r)
			}
		}
		g.Tables[i] = t
	}
	return g
}

func orderedPaths(paths []engine.FieldPathStat) []engine.FieldPathStat {
	out := slices.Clone(paths)
	slices.SortStableFunc(out, func(a, b engine.FieldPathStat) int {
		switch {
		case a.Path == idField:
			return -1
		case b.Path == idField:
			return 1
		case a.Frequency != b.Frequency:
			if a.Frequency > b.Frequency {
				return -1
			}
			return 1
		case a.Depth != b.Depth:
			return a.Depth - b.Depth
		}
		return strings.Compare(a.Path, b.Path)
	})
	return out
}

func sampledColumn(table string, p engine.FieldPathStat) engine.KeyedColumn {
	c := engine.KeyedColumn{
		Table:    table,
		Name:     p.Path,
		TypeName: dominantType(p.Types),
		Nullable: p.Frequency < 1 || slices.ContainsFunc(p.Types, func(t engine.FieldType) bool { return t.Type == "null" }),
	}
	if p.Path == idField {
		c.PrimaryKeyOrder = 1
	}
	return c
}

// dominantType is the most frequent type other than null, or null when the
// field held nothing else.
func dominantType(types []engine.FieldType) string {
	best, bestCount := "", uint32(0)
	for _, t := range types {
		if t.Type == "null" {
			continue
		}
		if t.Count > bestCount || t.Count == bestCount && t.Type < best {
			best, bestCount = t.Type, t.Count
		}
	}
	if best == "" && len(types) > 0 {
		return "null"
	}
	return best
}

type referenceTarget struct {
	collection string
	idType     string
}

type targetIndex struct {
	exact    map[string]referenceTarget
	singular map[string][]referenceTarget
}

func newTargetIndex(objects []engine.SchemaObject, samples map[string]engine.FieldPathSample) targetIndex {
	idx := targetIndex{exact: map[string]referenceTarget{}, singular: map[string][]referenceTarget{}}
	for _, o := range objects {
		if o.Type == engine.ObjectTypeView {
			continue
		}
		target := referenceTarget{collection: o.Name}
		for _, p := range samples[o.Name].Paths {
			if p.Path == idField {
				target.idType = dominantType(p.Types)
			}
		}
		key := nameKey(o.Name)
		idx.exact[key] = target
		if one := singularOf(key); one != key {
			idx.singular[one] = append(idx.singular[one], target)
		}
	}
	return idx
}

// lookup finds the collection a stem names: the same name, or the one whose
// plural it is when only one collection matches that way.
func (idx targetIndex) lookup(stem string) (referenceTarget, bool) {
	key := nameKey(stem)
	if t, ok := idx.exact[key]; ok {
		return t, true
	}
	if found := idx.singular[key]; len(found) == 1 {
		return found[0], true
	}
	if t, ok := idx.exact[singularOf(key)]; ok {
		return t, true
	}
	return referenceTarget{}, false
}

// lookupByLastWords tries the whole stem, then, for names with an id
// suffix, ever fewer of its last words: parent_category_id names category.
func (idx targetIndex) lookupByLastWords(stem string, named bool) (target referenceTarget, shortened, ok bool) {
	words := nameWords(stem)
	for i := range words {
		if i > 0 && !named {
			break
		}
		if target, ok = idx.lookup(strings.Join(words[i:], "")); ok {
			return target, i > 0, true
		}
	}
	return referenceTarget{}, false, false
}

func nameWords(name string) []string {
	var words []string
	start := 0
	for i, r := range name {
		switch {
		case r == '_' || r == '-':
			if i > start {
				words = append(words, name[start:i])
			}
			start = i + 1
		case unicode.IsUpper(r) && i > start && !unicode.IsUpper(rune(name[i-1])):
			words = append(words, name[start:i])
			start = i
		}
	}
	if start < len(name) {
		words = append(words, name[start:])
	}
	return words
}

func (idx targetIndex) reference(p engine.FieldPathStat) (Relation, bool) {
	if p.Path == idField {
		return Relation{}, false
	}
	stem, named := referenceStem(p.Path)
	if stem == "" {
		return Relation{}, false
	}
	target, shortened, ok := idx.lookupByLastWords(stem, named)
	if !ok {
		return Relation{}, false
	}
	confidence := referenceConfidence(dominantType(p.Types), target.idType, named)
	if confidence == 0 {
		return Relation{}, false
	}
	if shortened {
		confidence = math.Round((confidence-shortenedNamePenalty)*10) / 10
	}
	return Relation{
		ForeignKeyDef: engine.ForeignKeyDef{
			Columns:           []string{p.Path},
			ReferencedTable:   target.collection,
			ReferencedColumns: []string{idField},
		},
		Inferred:   true,
		Confidence: confidence,
	}, true
}

var idSuffixes = []string{"_ids", "Ids", "IDs", "_id", "Id", "ID"}

// referenceStem is the name a field path refers by, and whether the name
// said so with an id suffix: customerId, customer_id, customer._id and
// tagIds.[] name customer and tag; a bare field name is its own stem.
func referenceStem(path string) (stem string, named bool) {
	segments := slices.DeleteFunc(strings.Split(path, "."), func(s string) bool { return s == "[]" })
	if len(segments) == 0 {
		return "", false
	}
	last := segments[len(segments)-1]
	if last == idField {
		if len(segments) < 2 {
			return "", false
		}
		return segments[len(segments)-2], true
	}
	for _, suffix := range idSuffixes {
		if base, ok := strings.CutSuffix(last, suffix); ok && base != "" {
			return strings.TrimRight(base, "_-"), true
		}
	}
	return last, false
}

func referenceConfidence(fieldType, idType string, named bool) float64 {
	switch {
	case idType != "" && fieldType != idType:
		return 0
	case fieldType == objectIDType && idType == "":
		if named {
			return 0.5
		}
		return 0
	case fieldType == objectIDType && named:
		return 0.9
	case fieldType == objectIDType:
		return 0.7
	case named && idType != "":
		return 0.6
	}
	return 0
}

func nameKey(name string) string {
	return strings.NewReplacer("_", "", "-", "").Replace(strings.ToLower(name))
}

func singularOf(word string) string {
	switch {
	case strings.HasSuffix(word, "ies") && len(word) > 3:
		return strings.TrimSuffix(word, "ies") + "y"
	case strings.HasSuffix(word, "ses"), strings.HasSuffix(word, "xes"),
		strings.HasSuffix(word, "ches"), strings.HasSuffix(word, "shes"):
		return strings.TrimSuffix(word, "es")
	case strings.HasSuffix(word, "s") && !strings.HasSuffix(word, "ss"):
		return strings.TrimSuffix(word, "s")
	}
	return word
}
