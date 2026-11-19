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

const needsPipeline = "needs an aggregation pipeline, which SQL mode does not translate yet"

type findSpec struct {
	filter     bson.D
	projection bson.D
	sort       bson.D
	skip       uint64
	limit      *uint64
}

type translator struct {
	st         *statement
	qualifiers []string
	warnings   warnings
}

// Translate translates one SELECT statement against database.
func Translate(database, sql string) *queravuev1.TranslateMongoSqlResponse {
	st, err := parse(sql)
	if err != nil {
		return &queravuev1.TranslateMongoSqlResponse{Error: err}
	}
	t := &translator{st: st, qualifiers: qualifiersOf(st.from)}
	spec, err := t.find()
	if err != nil {
		return &queravuev1.TranslateMongoSqlResponse{Error: err}
	}
	resp, encodeErr := findResponse(database, st.from.name, spec)
	if encodeErr != nil {
		return &queravuev1.TranslateMongoSqlResponse{Error: &queravuev1.QueryBuilderError{
			Kind:    queravuev1.QueryBuilderErrorKind_QUERY_BUILDER_ERROR_KIND_INVALID_MODEL,
			Message: encodeErr.Error(),
		}}
	}
	resp.Warnings = t.warnings.proto()
	return resp
}

func qualifiersOf(from tableRef) []string {
	if from.alias != "" && from.alias != from.name {
		return []string{from.alias, from.name}
	}
	return []string{from.name}
}

func (t *translator) find() (findSpec, *queravuev1.QueryBuilderError) {
	st := t.st
	if st.distinct {
		return findSpec{}, unsupportedError("DISTINCT "+needsPipeline, st.distinctOffset)
	}
	projection, err := t.projection()
	if err != nil {
		return findSpec{}, err
	}
	if len(st.joins) > 0 {
		return findSpec{}, unsupportedError("JOIN "+needsPipeline, st.joins[0].offset)
	}
	filter := bson.D{}
	if st.where != nil {
		if filter, err = t.condition(st.where); err != nil {
			return findSpec{}, err
		}
	}
	if st.groupBy != nil {
		return findSpec{}, unsupportedError("GROUP BY "+needsPipeline, st.groupByOffset)
	}
	if st.having != nil {
		return findSpec{}, unsupportedError("HAVING "+needsPipeline, st.havingOffset)
	}
	sort, err := t.sort()
	if err != nil {
		return findSpec{}, err
	}
	if st.limit != nil && *st.limit == 0 {
		return findSpec{}, unsupportedError("LIMIT 0 is not supported: MongoDB treats a zero limit as no limit", st.limitOffset)
	}
	return findSpec{filter: filter, projection: projection, sort: sort, skip: st.offset, limit: st.limit}, nil
}

func (t *translator) fieldPath(ref fieldRef) (string, *queravuev1.QueryBuilderError) {
	parts := ref.parts
	for k := len(parts) - 1; k >= 1; k-- {
		if slices.Contains(t.qualifiers, strings.Join(parts[:k], ".")) {
			parts = parts[k:]
			break
		}
	}
	path := strings.Join(parts, ".")
	for _, segment := range strings.Split(path, ".") {
		if segment == "" {
			return "", parseError(fmt.Sprintf("field path %q has an empty segment", path), ref.offset)
		}
		if strings.HasPrefix(segment, "$") {
			return "", unsupportedError(fmt.Sprintf("field names starting with $ are not supported (%q)", path), ref.offset)
		}
	}
	return path, nil
}

func (t *translator) projection() (bson.D, *queravuev1.QueryBuilderError) {
	items := t.st.items
	if len(items) == 1 && items[0].star {
		return nil, t.checkStarQualifier(items[0])
	}
	var projection bson.D
	var outputs []string
	for _, item := range items {
		if item.star {
			return nil, unsupportedError("* cannot be combined with other columns", item.offset)
		}
		path, err := t.selectedField(item)
		if err != nil {
			return nil, err
		}
		name := path
		if item.alias != "" {
			name = item.alias
			if strings.Contains(name, ".") || strings.HasPrefix(name, "$") {
				return nil, unsupportedError(fmt.Sprintf("alias %q cannot contain '.' or start with '$'", name), item.offset)
			}
		}
		for _, other := range outputs {
			if overlaps(name, other) {
				return nil, unsupportedError(fmt.Sprintf("columns %q and %q overlap in a MongoDB projection", other, name), item.offset)
			}
		}
		outputs = append(outputs, name)
		if name == path {
			projection = append(projection, bson.E{Key: name, Value: true})
		} else {
			projection = append(projection, bson.E{Key: name, Value: "$" + path})
		}
	}
	if !slices.ContainsFunc(outputs, func(name string) bool { return overlaps(name, "_id") }) {
		projection = append(projection, bson.E{Key: "_id", Value: false})
	}
	return projection, nil
}

func (t *translator) checkStarQualifier(item selectItem) *queravuev1.QueryBuilderError {
	ref, ok := item.expr.(fieldRef)
	if !ok {
		return nil
	}
	if !slices.Contains(t.qualifiers, strings.Join(ref.parts, ".")) {
		return parseError(fmt.Sprintf("unknown qualifier %q", strings.Join(ref.parts, ".")), item.offset)
	}
	return nil
}

func (t *translator) selectedField(item selectItem) (string, *queravuev1.QueryBuilderError) {
	switch e := item.expr.(type) {
	case fieldRef:
		return t.fieldPath(e)
	case aggregateCall:
		return "", unsupportedError("an aggregate function "+needsPipeline, e.offset)
	}
	return "", unsupportedError("a computed column "+needsPipeline, item.offset)
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
			if selected, ok := t.selectedByAlias(e.parts[0]); ok {
				return t.selectedField(selected)
			}
		}
		return t.fieldPath(e)
	case literal:
		ordinal, ok := e.value.(int32)
		if !ok {
			return "", unsupportedError("ORDER BY accepts fields, aliases and column ordinals", e.offset)
		}
		if ordinal < 1 || int(ordinal) > len(t.st.items) {
			return "", parseError(fmt.Sprintf("ORDER BY %d is out of range 1..%d", ordinal, len(t.st.items)), e.offset)
		}
		selected := t.st.items[ordinal-1]
		if selected.star {
			return "", unsupportedError("ORDER BY ordinal cannot refer to *", e.offset)
		}
		return t.selectedField(selected)
	case aggregateCall:
		return "", unsupportedError("ORDER BY an aggregate "+needsPipeline, e.offset)
	}
	return "", unsupportedError("an ORDER BY expression "+needsPipeline, item.offset)
}

func (t *translator) selectedByAlias(name string) (selectItem, bool) {
	for _, item := range t.st.items {
		if item.alias == name {
			return item, true
		}
	}
	return selectItem{}, false
}
