// Package mongosql translates a SELECT statement into a MongoDB find or
// aggregation (ADR 0022). It is pure: no I/O, no driver connection.
package mongosql

import (
	"fmt"
	"slices"
	"strings"

	"go.mongodb.org/mongo-driver/v2/bson"

	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
)

type findSpec struct {
	filter     bson.D
	projection bson.D
	sort       bson.D
	skip       uint64
	limit      *uint64
}

type translator struct {
	st        *statement
	tables    []tableScope
	group     *groupState
	postGroup bool
	onJoin    *joinScope
	computed  bson.D
	warnings  warnings
}

// Translate translates one SELECT statement against database.
func Translate(database, sql string) *queravuev1.TranslateMongoSqlResponse {
	st, err := parse(sql)
	if err != nil {
		return &queravuev1.TranslateMongoSqlResponse{Error: err}
	}
	t, err := newTranslator(st)
	if err != nil {
		return &queravuev1.TranslateMongoSqlResponse{Error: err}
	}
	var (
		resp      *queravuev1.TranslateMongoSqlResponse
		encodeErr error
	)
	if st.needsPipeline() {
		stages, err := t.aggregate()
		if err != nil {
			return &queravuev1.TranslateMongoSqlResponse{Error: err}
		}
		resp, encodeErr = aggregateResponse(database, st.from.name, stages)
	} else {
		spec, err := t.find()
		if err != nil {
			return &queravuev1.TranslateMongoSqlResponse{Error: err}
		}
		resp, encodeErr = findResponse(database, st.from.name, spec)
	}
	if encodeErr != nil {
		return &queravuev1.TranslateMongoSqlResponse{Error: &queravuev1.QueryBuilderError{
			Kind:    queravuev1.QueryBuilderErrorKind_QUERY_BUILDER_ERROR_KIND_INVALID_MODEL,
			Message: encodeErr.Error(),
		}}
	}
	resp.Warnings = t.warnings.proto()
	return resp
}

func (st *statement) needsPipeline() bool {
	if len(st.joins) > 0 || st.groupBy != nil || st.having != nil || st.distinct {
		return true
	}
	for _, item := range st.items {
		if _, isField := item.expr.(fieldRef); !item.star && !isField {
			return true
		}
	}
	for _, item := range st.orderBy {
		if _, isAggregate := item.expr.(aggregateCall); isAggregate {
			return true
		}
	}
	return st.where != nil && whereNeedsExpression(st.where)
}

func (t *translator) find() (findSpec, *queravuev1.QueryBuilderError) {
	st := t.st
	projection, err := t.projection()
	if err != nil {
		return findSpec{}, err
	}
	filter := bson.D{}
	if st.where != nil {
		if filter, err = t.condition(st.where); err != nil {
			return findSpec{}, err
		}
	}
	sort, err := t.sort()
	if err != nil {
		return findSpec{}, err
	}
	if err := t.checkLimit(); err != nil {
		return findSpec{}, err
	}
	return findSpec{filter: filter, projection: projection, sort: sort, skip: st.offset, limit: st.limit}, nil
}

func (t *translator) checkLimit() *queravuev1.QueryBuilderError {
	if t.st.limit != nil && *t.st.limit == 0 {
		return unsupportedError("LIMIT 0 is not supported: MongoDB treats a zero limit as no limit", t.st.limitOffset)
	}
	return nil
}

func (t *translator) projection() (bson.D, *queravuev1.QueryBuilderError) {
	items := t.st.items
	if len(items) == 1 && items[0].star {
		return nil, t.checkStarQualifier(items[0])
	}
	outputs, err := t.outputColumns()
	if err != nil {
		return nil, err
	}
	var projection bson.D
	for _, column := range outputs {
		projection = append(projection, bson.E{Key: column.name, Value: column.value})
	}
	return withoutObjectID(projection, outputs), nil
}

type outputColumn struct {
	name  string
	value any
}

func (t *translator) outputColumns() ([]outputColumn, *queravuev1.QueryBuilderError) {
	var columns []outputColumn
	for _, item := range t.st.items {
		if item.star {
			return nil, unsupportedError("* cannot be combined with other columns", item.offset)
		}
		column, err := t.outputColumn(item)
		if err != nil {
			return nil, err
		}
		if strings.Contains(column.name, ".") && item.alias != "" || strings.HasPrefix(column.name, "$") {
			return nil, unsupportedError(fmt.Sprintf("alias %q cannot contain '.' or start with '$'", column.name), item.offset)
		}
		for _, other := range columns {
			if overlaps(column.name, other.name) {
				return nil, unsupportedError(fmt.Sprintf("columns %q and %q overlap in a MongoDB projection", other.name, column.name), item.offset)
			}
		}
		columns = append(columns, column)
	}
	return columns, nil
}

func (t *translator) outputColumn(item selectItem) (outputColumn, *queravuev1.QueryBuilderError) {
	switch e := item.expr.(type) {
	case fieldRef:
		merged, err := t.fieldPath(e)
		if err != nil {
			return outputColumn{}, err
		}
		name := merged
		if item.alias != "" {
			name = item.alias
		}
		if t.postGroup {
			source, err := t.refPath(e)
			return outputColumn{name: name, value: "$" + source}, err
		}
		if name == merged {
			return outputColumn{name: name, value: true}, nil
		}
		return outputColumn{name: name, value: "$" + merged}, nil
	case aggregateCall:
		accumulator, err := t.accumulator(e, item.alias)
		if err != nil {
			return outputColumn{}, err
		}
		if item.alias == "" || item.alias == accumulator {
			return outputColumn{name: accumulator, value: true}, nil
		}
		return outputColumn{name: item.alias, value: "$" + accumulator}, nil
	case arithmetic:
		if item.alias == "" {
			return outputColumn{}, unsupportedError("a computed column needs an alias: add AS name", e.offset)
		}
		value, err := t.expression(e)
		if err != nil {
			return outputColumn{}, err
		}
		t.computed = append(t.computed, bson.E{Key: item.alias, Value: value})
		return outputColumn{name: item.alias, value: true}, nil
	}
	return outputColumn{}, unsupportedError("a literal column is not supported", item.offset)
}

func withoutObjectID(projection bson.D, outputs []outputColumn) bson.D {
	if !slices.ContainsFunc(outputs, func(c outputColumn) bool { return overlaps(c.name, "_id") }) {
		projection = append(projection, bson.E{Key: "_id", Value: false})
	}
	return projection
}

func (t *translator) checkStarQualifier(item selectItem) *queravuev1.QueryBuilderError {
	ref, ok := item.expr.(fieldRef)
	if !ok {
		return nil
	}
	if _, known := t.qualifierTable(strings.Join(ref.parts, ".")); !known {
		return parseError(fmt.Sprintf("unknown qualifier %q", strings.Join(ref.parts, ".")), item.offset)
	}
	return nil
}

func overlaps(a, b string) bool {
	return a == b || strings.HasPrefix(a, b+".") || strings.HasPrefix(b, a+".")
}

func (t *translator) sort() (bson.D, *queravuev1.QueryBuilderError) {
	if len(t.st.orderBy) == 0 {
		return nil, nil
	}
	t.warnings.add(warnNullsSortFirst, t.st.orderBy[0].offset)
	var sort bson.D
	for _, item := range t.st.orderBy {
		path, err := t.sortPath(item)
		if err != nil {
			return nil, err
		}
		if slices.ContainsFunc(sort, func(e bson.E) bool { return e.Key == path }) {
			continue
		}
		direction := int32(1)
		if item.descending {
			direction = -1
		}
		sort = append(sort, bson.E{Key: path, Value: direction})
	}
	return sort, nil
}

func (t *translator) sortPath(item orderItem) (string, *queravuev1.QueryBuilderError) {
	switch e := item.expr.(type) {
	case fieldRef:
		if len(e.parts) == 1 {
			if index, ok := t.selectedByAlias(e.parts[0]); ok {
				return t.selectedPath(index)
			}
		}
		return t.refPath(e)
	case literal:
		ordinal, ok := e.value.(int32)
		if !ok {
			return "", unsupportedError("ORDER BY accepts fields, aliases and column ordinals", e.offset)
		}
		if ordinal < 1 || int(ordinal) > len(t.st.items) {
			return "", parseError(fmt.Sprintf("ORDER BY %d is out of range 1..%d", ordinal, len(t.st.items)), e.offset)
		}
		if t.st.items[ordinal-1].star {
			return "", unsupportedError("ORDER BY ordinal cannot refer to *", e.offset)
		}
		return t.selectedPath(int(ordinal) - 1)
	case aggregateCall:
		if !t.postGroup {
			return "", unsupportedError("aggregate functions in ORDER BY need a GROUP BY or aggregate query", e.offset)
		}
		return t.accumulator(e, "")
	}
	return "", unsupportedError("ORDER BY accepts fields, aliases, ordinals and aggregates; select the expression with an alias and order by that", item.offset)
}

func (t *translator) selectedPath(index int) (string, *queravuev1.QueryBuilderError) {
	item := t.st.items[index]
	switch e := item.expr.(type) {
	case fieldRef:
		return t.refPath(e)
	case aggregateCall:
		return t.accumulator(e, item.alias)
	case arithmetic:
		return item.alias, nil
	}
	return "", unsupportedError("a literal column is not supported", item.offset)
}

func (t *translator) selectedByAlias(name string) (int, bool) {
	for i, item := range t.st.items {
		if item.alias == name {
			return i, true
		}
	}
	return 0, false
}
