package completion

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"slices"
	"strings"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/sqlsplit"
)

// MongoSource supplies the server-side facts Mongo completion needs.
type MongoSource interface {
	Collections(ctx context.Context, database string) ([]string, error)
	// FieldPaths reports ready=false while the first sample is still running.
	FieldPaths(ctx context.Context, database, collection string) (sample engine.FieldPathSample, ready bool, err error)
}

// MongoRequest is the input of CompleteMongo.
type MongoRequest struct {
	// Shell selects shell scripts; otherwise the text is an EJSON query bar.
	Shell      bool
	Text       string
	Cursor     int
	MaxItems   int
	Database   string
	Collection string
	Source     MongoSource
}

type mongoCandidate struct {
	label, insert, detail string
	kind                  Kind
	tier                  int
	frequency             float64
}

// CompleteMongo returns ranked candidates for a Mongo shell script or query
// bar. It never fails on text that does not parse; it returns an error only
// when ctx ends.
func CompleteMongo(ctx context.Context, req MongoRequest) (Result, error) {
	om := sqlsplit.NewOffsetMap(req.Text)
	cursor := om.ToByte(req.Cursor)
	a := analyzeMongo(req.Text, cursor)
	if a.Kind == mongoNone {
		return Result{}, nil
	}
	if a.Collection == "" {
		a.Collection = req.Collection
	}
	var res Result
	cands := mongoCandidates(ctx, req, a, &res)
	if err := ctx.Err(); err != nil {
		return res, fmt.Errorf("completion: %w", err)
	}
	if a.Quoted && cursor < len(req.Text) && req.Text[cursor] == req.Text[a.ReplaceStart] {
		a.ReplaceEnd = cursor + 1
	} else {
		a.ReplaceEnd = cursor
	}
	start, end := om.ToUTF16(a.ReplaceStart), om.ToUTF16(a.ReplaceEnd)
	items := make([]Item, 0, len(cands))
	for _, c := range cands {
		class, ok := matchName(a.Prefix, c.label)
		if !ok {
			continue
		}
		exact := 1
		if strings.EqualFold(a.Prefix, c.label) && a.Prefix != "" {
			exact = 0
		}
		insert := c.insert
		if a.Quoted && c.kind != KindMethod {
			insert = jsonString(c.label)
		}
		items = append(items, Item{
			Label: c.label, Kind: c.kind, Detail: c.detail, InsertText: insert, ReplaceStart: start, ReplaceEnd: end,
			SortKey: fmt.Sprintf("%d%d%d%d%d%s", c.tier, class, exact, 9-int(c.frequency*9), 0, strings.ToLower(c.label)),
		})
	}
	slices.SortFunc(items, func(x, y Item) int { return strings.Compare(x.SortKey, y.SortKey) })
	limit := req.MaxItems
	if limit <= 0 {
		limit = DefaultMaxItems
	}
	limit = min(limit, MaxItemsLimit)
	if len(items) > limit {
		items, res.Incomplete = items[:limit], true
	}
	res.Items = items
	return res, nil
}

func mongoCandidates(ctx context.Context, req MongoRequest, a mongoContext, res *Result) []mongoCandidate {
	switch a.Kind {
	case mongoDBMembers:
		out := describedCandidates(dbMethods, KindMethod, 2)
		names, err := req.Source.Collections(ctx, req.Database)
		if err != nil {
			return out
		}
		for _, name := range names {
			insert := name
			if !simpleJSIdent(name) || dbMethodNames[name] {
				insert = "getCollection(" + jsonString(name) + ")"
			}
			out = append(out, mongoCandidate{label: name, insert: insert, detail: "collection", kind: KindCollection, tier: 1})
		}
		return out
	case mongoCollectionMethods:
		return describedCandidates(collectionMethods, KindMethod, 1)
	case mongoCursorMethods:
		return describedCandidates(cursorMethods, KindMethod, 1)
	case mongoGlobals:
		return describedCandidates(shellGlobals, KindKeyword, 1)
	}
	return keyCandidates(ctx, req, a, res)
}

func describedCandidates(list []described, kind Kind, tier int) []mongoCandidate {
	out := make([]mongoCandidate, len(list))
	for i, d := range list {
		out[i] = mongoCandidate{label: d.name, insert: d.name, detail: d.detail, kind: kind, tier: tier, frequency: listPosition(i, len(list))}
	}
	return out
}

func listPosition(i, n int) float64 { return 1 - float64(i)/float64(n) }

func (a mongoContext) keyInsert(label string, shell bool) string {
	if shell && simpleJSIdent(label) {
		return label
	}
	return jsonString(label)
}

func keyCandidates(ctx context.Context, req MongoRequest, a mongoContext, res *Result) []mongoCandidate {
	plan := planKeys(a)
	var out []mongoCandidate
	opTier := 2
	if strings.HasPrefix(a.Prefix, "$") {
		opTier = 1
	}
	for _, list := range plan.operators {
		for i, d := range list {
			out = append(out, mongoCandidate{
				label: d.name, insert: a.keyInsert(d.name, req.Shell), detail: d.detail, kind: KindOperator, tier: opTier,
				frequency: listPosition(i, len(list)),
			})
		}
	}
	for i, d := range plan.words {
		out = append(out, mongoCandidate{
			label: d.name, insert: a.keyInsert(d.name, req.Shell), detail: d.detail, kind: KindField, tier: 1,
			frequency: listPosition(i, len(plan.words)),
		})
	}
	if !plan.paths || a.Collection == "" || req.Source == nil {
		return out
	}
	sample, ready, err := req.Source.FieldPaths(ctx, req.Database, a.Collection)
	if err != nil {
		return out
	}
	if !ready {
		res.Incomplete = true
		return out
	}
	for _, p := range queryPaths(sample, plan.base) {
		out = append(out, mongoCandidate{
			label: p.label, insert: a.keyInsert(p.label, req.Shell), detail: p.detail, kind: KindField, tier: 1, frequency: p.frequency,
		})
	}
	return out
}

type keyPlan struct {
	paths     bool
	base      string
	operators [][]described
	words     []described
}

type filterState int

const (
	filterNone filterState = iota
	filterObject
	filterField
	filterElement
)

func planKeys(a mongoContext) keyPlan {
	switch a.Role {
	case roleFilter:
		return planFilter(a.Chain, "")
	case roleProjection, roleSort:
		return keyPlan{paths: len(a.Chain) == 0}
	case roleUpdate:
		switch {
		case len(a.Chain) == 0:
			return keyPlan{operators: [][]described{updateOperators}}
		case len(a.Chain) == 1 && updateFieldOperators[a.Chain[0]]:
			return keyPlan{paths: true}
		}
	case rolePipeline:
		return planStage(a.Chain)
	}
	return keyPlan{}
}

func planStage(chain []string) keyPlan {
	if len(chain) == 0 {
		return keyPlan{operators: [][]described{pipelineStages}}
	}
	stage, rest := chain[0], chain[1:]
	switch {
	case stage == "$match":
		return planFilter(rest, "")
	case pathOnlyStages[stage] && len(rest) == 0:
		return keyPlan{paths: true}
	case stage == "$group" && len(rest) == 0:
		return keyPlan{words: []described{{"_id", "group key"}}}
	case stage == "$group" && len(rest) == 1:
		return keyPlan{operators: [][]described{accumulators}}
	case stage == "$lookup" && len(rest) == 0:
		return keyPlan{words: lookupKeys}
	case stage == "$unwind" && len(rest) == 0:
		return keyPlan{words: unwindKeys}
	}
	return keyPlan{}
}

func planFilter(chain []string, base string) keyPlan {
	state := filterObject
	for _, k := range chain {
		switch state {
		case filterObject, filterElement:
			switch {
			case k == "$and" || k == "$or" || k == "$nor":
			case k == "" || strings.HasPrefix(k, "$"):
				return keyPlan{}
			default:
				base, state = joinPath(base, k), filterField
			}
		case filterField:
			switch k {
			case "$elemMatch":
				base, state = base+".[]", filterElement
			case "$not":
			default:
				return keyPlan{}
			}
		}
	}
	switch state {
	case filterObject:
		return keyPlan{paths: true, base: base, operators: [][]described{logicalOperators}}
	case filterElement:
		return keyPlan{paths: true, base: base, operators: [][]described{fieldOperators, logicalOperators}}
	case filterField:
		return keyPlan{operators: [][]described{fieldOperators}}
	}
	return keyPlan{}
}

func joinPath(base, key string) string {
	if base == "" {
		return key
	}
	return base + "." + key
}

type pathCandidate struct {
	label     string
	detail    string
	frequency float64
}

func queryPaths(sample engine.FieldPathSample, base string) []pathCandidate {
	seen := map[string]bool{}
	var out []pathCandidate
	for _, p := range sample.Paths {
		rel := p.Path
		if base != "" {
			rest, ok := strings.CutPrefix(rel, base+".")
			if !ok {
				continue
			}
			rel = rest
		}
		segs := strings.Split(rel, ".")
		kept := segs[:0]
		for _, s := range segs {
			if s != "[]" {
				kept = append(kept, s)
			}
		}
		if len(kept) == 0 {
			continue
		}
		label := strings.Join(kept, ".")
		if seen[label] {
			continue
		}
		seen[label] = true
		out = append(out, pathCandidate{label: label, detail: pathDetail(p), frequency: p.Frequency})
	}
	return out
}

func pathDetail(p engine.FieldPathStat) string {
	types := make([]string, 0, 2)
	for i, t := range p.Types {
		if i == 2 {
			types = append(types, "…")
			break
		}
		types = append(types, t.Type)
	}
	return fmt.Sprintf("%s · %d%%", strings.Join(types, "|"), int(p.Frequency*100+0.5))
}

func simpleJSIdent(s string) bool {
	if s == "" || !isJSIdentStart(s[0]) {
		return false
	}
	for i := 1; i < len(s); i++ {
		if !isJSIdentPart(s[i]) || s[i] >= 0x80 {
			return false
		}
	}
	return s[0] < 0x80
}

func jsonString(s string) string {
	var b bytes.Buffer
	enc := json.NewEncoder(&b)
	enc.SetEscapeHTML(false)
	_ = enc.Encode(s)
	return strings.TrimSuffix(b.String(), "\n")
}
