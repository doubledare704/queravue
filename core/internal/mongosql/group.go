package mongosql

import (
	"fmt"
	"slices"
	"strings"

	"go.mongodb.org/mongo-driver/v2/bson"

	"github.com/doubledare704/queravue/core/internal/engine/mongo"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
)

type groupKey struct {
	path string
	name string
}

type accumulator struct {
	name     string
	spec     bson.D
	finalize any
}

type groupState struct {
	keys         []groupKey
	accumulators []accumulator
	usedNames    map[string]bool
}

func (g *groupState) keyFor(path string) (groupKey, bool) {
	i := slices.IndexFunc(g.keys, func(k groupKey) bool { return k.path == path })
	if i < 0 {
		return groupKey{}, false
	}
	return g.keys[i], true
}

func (g *groupState) addKey(path string) {
	if _, exists := g.keyFor(path); exists {
		return
	}
	g.keys = append(g.keys, groupKey{path: path, name: g.freshName(strings.ReplaceAll(path, ".", "_"))})
}

func (g *groupState) freshName(base string) string {
	name := base
	for n := 2; g.usedNames[name]; n++ {
		name = fmt.Sprintf("%s_%d", base, n)
	}
	g.usedNames[name] = true
	return name
}

func containsAggregate(e expr) bool {
	found := false
	walkExpr(e, func(n expr) {
		if _, ok := n.(aggregateCall); ok {
			found = true
		}
	})
	return found
}

func (t *translator) startGrouping() *queravuev1.QueryBuilderError {
	st := t.st
	hasAggregate := slices.ContainsFunc(st.items, func(item selectItem) bool { return item.expr != nil && containsAggregate(item.expr) }) ||
		slices.ContainsFunc(st.orderBy, func(item orderItem) bool { return containsAggregate(item.expr) })
	if st.groupBy == nil && st.having == nil && !st.distinct && !hasAggregate {
		return nil
	}
	t.group = &groupState{usedNames: map[string]bool{}}
	for _, item := range st.items {
		if item.alias != "" {
			t.group.usedNames[item.alias] = true
		}
	}
	if st.distinct {
		if st.groupBy != nil || st.having != nil || hasAggregate {
			return unsupportedError("DISTINCT cannot be combined with GROUP BY, HAVING or aggregate functions", st.distinctOffset)
		}
		return t.distinctKeys()
	}
	for _, e := range st.groupBy {
		path, err := t.groupByPath(e)
		if err != nil {
			return err
		}
		t.group.addKey(path)
	}
	return nil
}

func (t *translator) distinctKeys() *queravuev1.QueryBuilderError {
	for _, item := range t.st.items {
		ref, ok := item.expr.(fieldRef)
		if !ok {
			return unsupportedError("DISTINCT supports only plain fields", item.offset)
		}
		path, err := t.fieldPath(ref)
		if err != nil {
			return err
		}
		t.group.addKey(path)
	}
	return nil
}

func (t *translator) groupByPath(e expr) (string, *queravuev1.QueryBuilderError) {
	switch n := e.(type) {
	case fieldRef:
		if len(n.parts) == 1 {
			if index, ok := t.selectedByAlias(n.parts[0]); ok {
				return t.groupedItemPath(index, n.offset)
			}
		}
		return t.fieldPath(n)
	case literal:
		ordinal, ok := n.value.(int32)
		if !ok || ordinal < 1 || int(ordinal) > len(t.st.items) {
			return "", parseError("GROUP BY ordinal is out of range", n.offset)
		}
		return t.groupedItemPath(int(ordinal)-1, n.offset)
	}
	return "", unsupportedError("GROUP BY accepts fields, aliases and column ordinals", e.pos())
}

func (t *translator) groupedItemPath(index, offset int) (string, *queravuev1.QueryBuilderError) {
	ref, ok := t.st.items[index].expr.(fieldRef)
	if !ok {
		return "", unsupportedError("GROUP BY must name a plain field", offset)
	}
	return t.fieldPath(ref)
}

func (t *translator) accumulator(call aggregateCall, preferred string) (string, *queravuev1.QueryBuilderError) {
	spec, finalize, err := t.accumulatorSpec(call)
	if err != nil {
		return "", err
	}
	identity, encodeErr := mongo.CanonicalEJSON(spec)
	if encodeErr != nil {
		return "", &queravuev1.QueryBuilderError{Kind: queravuev1.QueryBuilderErrorKind_QUERY_BUILDER_ERROR_KIND_INVALID_MODEL, Message: encodeErr.Error()}
	}
	for _, existing := range t.group.accumulators {
		if existingIdentity, _ := mongo.CanonicalEJSON(existing.spec); existingIdentity == identity {
			return existing.name, nil
		}
	}
	base := preferred
	if base == "" {
		base = defaultAccumulatorName(call)
	} else {
		delete(t.group.usedNames, preferred)
	}
	name := t.group.freshName(base)
	if call.distinct {
		finalize = bson.D{{Key: "$size", Value: bson.D{{Key: "$setDifference", Value: bson.A{"$" + name, bson.A{nil}}}}}}
	}
	t.group.accumulators = append(t.group.accumulators, accumulator{name: name, spec: spec, finalize: finalize})
	t.noteAggregateSemantics(call)
	return name, nil
}

func (t *translator) noteAggregateSemantics(call aggregateCall) {
	if len(t.group.keys) == 0 {
		t.warnings.add(warnEmptyGlobalAggregate, call.offset)
	}
	switch {
	case call.name == "COUNT" && !call.star && !call.distinct:
		t.warnings.add(warnCountNonNull, call.offset)
	case call.name == "SUM":
		t.warnings.add(warnSumWithoutValues, call.offset)
	}
}

func defaultAccumulatorName(call aggregateCall) string {
	name := strings.ToLower(call.name)
	if call.distinct {
		name += "_distinct"
	}
	if ref, ok := call.arg.(fieldRef); ok {
		name += "_" + strings.ReplaceAll(strings.Join(ref.parts, "_"), ".", "_")
	} else if call.arg != nil {
		name += "_expr"
	}
	return name
}

func (t *translator) accumulatorSpec(call aggregateCall) (bson.D, any, *queravuev1.QueryBuilderError) {
	if call.distinct && call.name != "COUNT" {
		return nil, nil, unsupportedError("DISTINCT is supported only inside COUNT(DISTINCT ...)", call.offset)
	}
	if call.star {
		return bson.D{{Key: "$sum", Value: int32(1)}}, nil, nil
	}
	arg, err := t.rawExpression(call.arg)
	if err != nil {
		return nil, nil, err
	}
	switch {
	case call.name == "COUNT" && call.distinct:
		return bson.D{{Key: "$addToSet", Value: arg}}, nil, nil
	case call.name == "COUNT":
		present := bson.D{{Key: "$ne", Value: bson.A{bson.D{{Key: "$ifNull", Value: bson.A{arg, nil}}}, nil}}}
		return bson.D{{Key: "$sum", Value: bson.D{{Key: "$cond", Value: bson.A{present, int32(1), int32(0)}}}}}, nil, nil
	}
	return bson.D{{Key: "$" + strings.ToLower(call.name), Value: arg}}, nil, nil
}

func (t *translator) groupStages() []bson.D {
	var id any
	if len(t.group.keys) > 0 {
		keyDoc := bson.D{}
		for _, key := range t.group.keys {
			keyDoc = append(keyDoc, bson.E{Key: key.name, Value: "$" + key.path})
		}
		id = keyDoc
	}
	doc := bson.D{{Key: "_id", Value: id}}
	var finalized bson.D
	for _, acc := range t.group.accumulators {
		doc = append(doc, bson.E{Key: acc.name, Value: acc.spec})
		if acc.finalize != nil {
			finalized = append(finalized, bson.E{Key: acc.name, Value: acc.finalize})
		}
	}
	stages := []bson.D{{{Key: "$group", Value: doc}}}
	if len(finalized) > 0 {
		stages = append(stages, bson.D{{Key: "$addFields", Value: finalized}})
	}
	return stages
}
