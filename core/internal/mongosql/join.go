package mongosql

import (
	"fmt"

	"go.mongodb.org/mongo-driver/v2/bson"

	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
)

type joinScope struct {
	table     int
	variables []string
}

func (j *joinScope) variable(path string) string {
	for i, existing := range j.variables {
		if existing == path {
			return fmt.Sprintf("v%d", i)
		}
	}
	j.variables = append(j.variables, path)
	return fmt.Sprintf("v%d", len(j.variables)-1)
}

func (t *translator) lookupStages(index int, j join) ([]bson.D, *queravuev1.QueryBuilderError) {
	table := index + 1
	as := t.tables[table].as
	lookup := bson.D{{Key: "from", Value: j.table.name}}
	localField, foreignField, simple, err := t.equalityLookup(table, j.on)
	if err != nil {
		return nil, err
	}
	if simple {
		t.warnings.add(warnJoinNullKey, j.offset)
		lookup = append(lookup, bson.E{Key: "localField", Value: localField}, bson.E{Key: "foreignField", Value: foreignField})
	} else {
		letDoc, pipeline, err := t.compoundLookup(table, j)
		if err != nil {
			return nil, err
		}
		lookup = append(lookup, bson.E{Key: "let", Value: letDoc}, bson.E{Key: "pipeline", Value: pipeline})
	}
	lookup = append(lookup, bson.E{Key: "as", Value: as})
	var unwind any = "$" + as
	if j.kind == joinLeft {
		unwind = bson.D{{Key: "path", Value: "$" + as}, {Key: "preserveNullAndEmptyArrays", Value: true}}
	}
	return []bson.D{{{Key: "$lookup", Value: lookup}}, {{Key: "$unwind", Value: unwind}}}, nil
}

func (t *translator) equalityLookup(table int, on expr) (string, string, bool, *queravuev1.QueryBuilderError) {
	cmp, ok := on.(comparison)
	if !ok || cmp.op != "=" {
		return "", "", false, nil
	}
	left, leftIsField := cmp.left.(fieldRef)
	right, rightIsField := cmp.right.(fieldRef)
	if !leftIsField || !rightIsField {
		return "", "", false, nil
	}
	leftField, err := t.resolve(left)
	if err != nil {
		return "", "", false, err
	}
	rightField, err := t.resolve(right)
	if err != nil {
		return "", "", false, err
	}
	switch {
	case leftField.table < table && rightField.table == table:
		return t.mergedPath(leftField), rightField.local, true, nil
	case rightField.table < table && leftField.table == table:
		return t.mergedPath(rightField), leftField.local, true, nil
	}
	return "", "", false, nil
}

func (t *translator) compoundLookup(table int, j join) (bson.D, bson.A, *queravuev1.QueryBuilderError) {
	scope := &joinScope{table: table}
	t.onJoin = scope
	defer func() { t.onJoin = nil }()
	condition, err := t.expressionCondition(j.on)
	if err != nil {
		return nil, nil, err
	}
	t.warnings.add(warnCompoundJoin, j.offset)
	letDoc := bson.D{}
	for i, path := range scope.variables {
		letDoc = append(letDoc, bson.E{Key: fmt.Sprintf("v%d", i), Value: "$" + path})
	}
	pipeline := bson.A{bson.D{{Key: "$match", Value: bson.D{{Key: "$expr", Value: condition}}}}}
	return letDoc, pipeline, nil
}
