package mongosql

import (
	"strings"

	"go.mongodb.org/mongo-driver/v2/bson"

	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
)

func (t *translator) aggregate() ([]bson.D, *queravuev1.QueryBuilderError) {
	st := t.st
	if err := t.startGrouping(); err != nil {
		return nil, err
	}
	var stages []bson.D
	baseFilters, joinedFilters := t.splitWhere()
	if err := t.appendMatch(&stages, baseFilters); err != nil {
		return nil, err
	}
	for i, j := range st.joins {
		lookup, err := t.lookupStages(i, j)
		if err != nil {
			return nil, err
		}
		stages = append(stages, lookup...)
	}
	if err := t.appendMatch(&stages, joinedFilters); err != nil {
		return nil, err
	}

	t.postGroup = t.group != nil
	root, projection, err := t.pipelineSelection()
	if err != nil {
		return nil, err
	}
	var having bson.D
	if st.having != nil {
		if having, err = t.condition(st.having); err != nil {
			return nil, err
		}
	}
	sort, err := t.sort()
	if err != nil {
		return nil, err
	}
	if err := t.checkLimit(); err != nil {
		return nil, err
	}

	if t.group != nil {
		stages = append(stages, t.groupStages()...)
	}
	if having != nil {
		stages = append(stages, bson.D{{Key: "$match", Value: having}})
	}
	if len(t.computed) > 0 {
		stages = append(stages, bson.D{{Key: "$addFields", Value: t.computed}})
	}
	if sort != nil {
		stages = append(stages, bson.D{{Key: "$sort", Value: sort}})
	}
	if root != nil {
		stages = append(stages, bson.D{{Key: "$replaceWith", Value: root}})
	}
	if projection != nil {
		stages = append(stages, bson.D{{Key: "$project", Value: projection}})
	}
	if st.offset > 0 {
		stages = append(stages, bson.D{{Key: "$skip", Value: int64(st.offset)}}) //nolint:gosec // parsed from an int64
	}
	if st.limit != nil {
		stages = append(stages, bson.D{{Key: "$limit", Value: int64(*st.limit)}}) //nolint:gosec // parsed from an int64
	}
	return stages, nil
}

func (t *translator) appendMatch(stages *[]bson.D, conjuncts []expr) *queravuev1.QueryBuilderError {
	if len(conjuncts) == 0 {
		return nil
	}
	var filter bson.D
	var err *queravuev1.QueryBuilderError
	if len(conjuncts) == 1 {
		filter, err = t.condition(conjuncts[0])
	} else {
		filter, err = t.logicalCondition(logical{and: true, operands: conjuncts, offset: conjuncts[0].pos()})
	}
	if err != nil {
		return err
	}
	*stages = append(*stages, bson.D{{Key: "$match", Value: filter}})
	return nil
}

// splitWhere separates the AND-ed conditions that only read the FROM
// collection, so they run before $lookup and can use its indexes.
func (t *translator) splitWhere() (base, joined []expr) {
	if t.st.where == nil {
		return nil, nil
	}
	conjuncts := flattenAnd(t.st.where)
	if len(t.st.joins) == 0 {
		return conjuncts, nil
	}
	for _, conjunct := range conjuncts {
		if t.readsOnlyBase(conjunct) {
			base = append(base, conjunct)
		} else {
			joined = append(joined, conjunct)
		}
	}
	return base, joined
}

func flattenAnd(e expr) []expr {
	n, ok := e.(logical)
	if !ok || !n.and {
		return []expr{e}
	}
	var out []expr
	for _, operand := range n.operands {
		out = append(out, flattenAnd(operand)...)
	}
	return out
}

func (t *translator) readsOnlyBase(e expr) bool {
	onlyBase := true
	walkExpr(e, func(n expr) {
		ref, ok := n.(fieldRef)
		if !ok {
			return
		}
		if field, err := t.resolve(ref); err != nil || field.table != 0 {
			onlyBase = false
		}
	})
	return onlyBase
}

func (t *translator) pipelineSelection() (root any, projection bson.D, err *queravuev1.QueryBuilderError) {
	items := t.st.items
	if len(items) == 1 && items[0].star {
		if t.group != nil {
			return nil, nil, unsupportedError("* cannot be used with GROUP BY, DISTINCT, HAVING or aggregate functions", items[0].offset)
		}
		return t.starSelection(items[0])
	}
	columns, err := t.outputColumns()
	if err != nil {
		return nil, nil, err
	}
	for _, column := range columns {
		projection = append(projection, bson.E{Key: column.name, Value: column.value})
	}
	return nil, withoutObjectID(projection, columns), nil
}

func (t *translator) starSelection(item selectItem) (any, bson.D, *queravuev1.QueryBuilderError) {
	if err := t.checkStarQualifier(item); err != nil {
		return nil, nil, err
	}
	ref, qualified := item.expr.(fieldRef)
	if !qualified || len(t.st.joins) == 0 {
		return nil, nil, nil
	}
	table, _ := t.qualifierTable(strings.Join(ref.parts, "."))
	if table > 0 {
		return bson.D{{Key: "$ifNull", Value: bson.A{"$" + t.tables[table].as, bson.D{}}}}, nil, nil
	}
	var excluded bson.D
	for _, scope := range t.tables[1:] {
		excluded = append(excluded, bson.E{Key: scope.as, Value: false})
	}
	return nil, excluded, nil
}
