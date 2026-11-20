package mongosql

import (
	"fmt"
	"strings"

	"go.mongodb.org/mongo-driver/v2/bson"

	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
)

var arithmeticOperators = map[string]string{"+": "$add", "-": "$subtract", "*": "$multiply", "/": "$divide"}

var expressionComparison = map[string]string{"=": "$eq", "<>": "$ne", "<": "$lt", "<=": "$lte", ">": "$gt", ">=": "$gte"}

func walkExpr(e expr, visit func(expr)) {
	if e == nil {
		return
	}
	visit(e)
	switch n := e.(type) {
	case logical:
		for _, operand := range n.operands {
			walkExpr(operand, visit)
		}
	case negation:
		walkExpr(n.operand, visit)
	case comparison:
		walkExpr(n.left, visit)
		walkExpr(n.right, visit)
	case inList:
		walkExpr(n.operand, visit)
		for _, value := range n.values {
			walkExpr(value, visit)
		}
	case between:
		walkExpr(n.operand, visit)
		walkExpr(n.low, visit)
		walkExpr(n.high, visit)
	case likeMatch:
		walkExpr(n.operand, visit)
	case nullCheck:
		walkExpr(n.operand, visit)
	case arithmetic:
		walkExpr(n.left, visit)
		walkExpr(n.right, visit)
	case aggregateCall:
		walkExpr(n.arg, visit)
	}
}

func isArithmetic(e expr) bool {
	_, ok := e.(arithmetic)
	return ok
}

func isPathOperand(e expr) bool {
	switch e.(type) {
	case fieldRef, aggregateCall:
		return true
	}
	return false
}

func anyArithmetic(operands ...expr) bool {
	for _, e := range operands {
		if isArithmetic(e) {
			return true
		}
	}
	return false
}

func anyPathOperand(operands []expr) bool {
	for _, e := range operands {
		if isPathOperand(e) {
			return true
		}
	}
	return false
}

// needsExpression reports whether a predicate cannot be written as a plain
// query document and must run as an aggregation expression under $expr.
func needsExpression(e expr) bool {
	switch n := e.(type) {
	case comparison:
		return anyArithmetic(n.left, n.right) || isPathOperand(n.left) && isPathOperand(n.right)
	case between:
		return anyArithmetic(n.operand, n.low, n.high) || anyPathOperand([]expr{n.low, n.high})
	case inList:
		return anyArithmetic(n.operand) || anyArithmetic(n.values...) || anyPathOperand(n.values)
	case likeMatch:
		return isArithmetic(n.operand)
	case nullCheck:
		return isArithmetic(n.operand)
	}
	return false
}

func whereNeedsExpression(e expr) bool {
	switch n := e.(type) {
	case logical:
		for _, operand := range n.operands {
			if whereNeedsExpression(operand) {
				return true
			}
		}
		return false
	case negation:
		return whereNeedsExpression(n.operand)
	}
	return needsExpression(e)
}

func (t *translator) rawExpression(e expr) (any, *queravuev1.QueryBuilderError) {
	postGroup := t.postGroup
	t.postGroup = false
	defer func() { t.postGroup = postGroup }()
	return t.expression(e)
}

func (t *translator) expression(e expr) (any, *queravuev1.QueryBuilderError) {
	switch n := e.(type) {
	case literal:
		if n.isNull {
			return nil, nil
		}
		if s, ok := n.value.(string); ok && strings.HasPrefix(s, "$") {
			return bson.D{{Key: "$literal", Value: s}}, nil
		}
		return n.value, nil
	case fieldRef:
		return t.fieldExpression(n)
	case arithmetic:
		return t.arithmeticExpression(n)
	case aggregateCall:
		if !t.postGroup {
			return nil, unsupportedError("aggregate functions are valid only in the select list, HAVING and ORDER BY", n.offset)
		}
		name, err := t.accumulator(n, "")
		return "$" + name, err
	}
	return nil, unsupportedError("this expression is not supported here", e.pos())
}

func (t *translator) arithmeticExpression(n arithmetic) (any, *queravuev1.QueryBuilderError) {
	left, err := t.expression(n.left)
	if err != nil {
		return nil, err
	}
	right, err := t.expression(n.right)
	if err != nil {
		return nil, err
	}
	t.warnings.add(warnArithmetic, n.offset)
	return bson.D{{Key: arithmeticOperators[n.op], Value: bson.A{left, right}}}, nil
}

func (t *translator) fieldExpression(ref fieldRef) (any, *queravuev1.QueryBuilderError) {
	if t.onJoin == nil {
		path, err := t.refPath(ref)
		return "$" + path, err
	}
	field, err := t.resolve(ref)
	if err != nil {
		return nil, err
	}
	switch {
	case field.table == t.onJoin.table:
		return "$" + field.local, nil
	case field.table < t.onJoin.table:
		return "$$" + t.onJoin.variable(t.mergedPath(field)), nil
	}
	return nil, parseError(fmt.Sprintf("ON refers to %q, which is joined later", ref.parts[0]), ref.offset)
}

func (t *translator) operandExpression(e expr) (any, *queravuev1.QueryBuilderError) {
	if lit, ok := e.(literal); ok && lit.isNull {
		return nil, unsupportedError("comparing with NULL is never true in SQL; use IS NULL or IS NOT NULL", lit.offset)
	}
	return t.expression(e)
}

func (t *translator) expressionCondition(e expr) (any, *queravuev1.QueryBuilderError) {
	switch n := e.(type) {
	case logical:
		operator := "$or"
		if n.and {
			operator = "$and"
		}
		operands := make(bson.A, 0, len(n.operands))
		for _, operand := range n.operands {
			doc, err := t.expressionCondition(operand)
			if err != nil {
				return nil, err
			}
			operands = append(operands, doc)
		}
		return bson.D{{Key: operator, Value: operands}}, nil
	case negation:
		negated, ok := negate(n.operand)
		if !ok {
			return nil, t.notACondition(n.operand)
		}
		return t.expressionCondition(negated)
	case comparison:
		return t.comparisonExpression(n)
	case inList:
		return t.inExpression(n)
	case between:
		return t.betweenExpression(n)
	case likeMatch:
		return t.likeExpression(n)
	case nullCheck:
		operand, err := t.expression(n.operand)
		if err != nil {
			return nil, err
		}
		operator := "$eq"
		if n.negated {
			operator = "$ne"
		} else {
			t.warnings.add(warnNullMatchesMissing, n.offset)
		}
		nullified := bson.D{{Key: "$ifNull", Value: bson.A{operand, nil}}}
		return bson.D{{Key: operator, Value: bson.A{nullified, nil}}}, nil
	}
	return nil, t.notACondition(e)
}

func (t *translator) comparisonExpression(n comparison) (any, *queravuev1.QueryBuilderError) {
	left, err := t.operandExpression(n.left)
	if err != nil {
		return nil, err
	}
	right, err := t.operandExpression(n.right)
	if err != nil {
		return nil, err
	}
	t.warnings.add(warnExpressionNullOrdering, n.offset)
	if n.op == "<>" {
		t.warnings.add(warnNegationMatchesMissing, n.offset)
	}
	return bson.D{{Key: expressionComparison[n.op], Value: bson.A{left, right}}}, nil
}

func (t *translator) inExpression(n inList) (any, *queravuev1.QueryBuilderError) {
	operand, err := t.operandExpression(n.operand)
	if err != nil {
		return nil, err
	}
	values := make(bson.A, 0, len(n.values))
	for _, e := range n.values {
		if lit, ok := e.(literal); ok && lit.isNull {
			return nil, unsupportedError("NULL in an IN list never matches in SQL; use IS NULL", lit.offset)
		}
		value, err := t.expression(e)
		if err != nil {
			return nil, err
		}
		values = append(values, value)
	}
	t.warnings.add(warnExpressionNullOrdering, n.offset)
	in := bson.D{{Key: "$in", Value: bson.A{operand, values}}}
	if n.negated {
		t.warnings.add(warnNegationMatchesMissing, n.offset)
		return bson.D{{Key: "$not", Value: bson.A{in}}}, nil
	}
	return in, nil
}

func (t *translator) betweenExpression(n between) (any, *queravuev1.QueryBuilderError) {
	operand, err := t.operandExpression(n.operand)
	if err != nil {
		return nil, err
	}
	low, err := t.operandExpression(n.low)
	if err != nil {
		return nil, err
	}
	high, err := t.operandExpression(n.high)
	if err != nil {
		return nil, err
	}
	t.warnings.add(warnExpressionNullOrdering, n.offset)
	if n.negated {
		return bson.D{{Key: "$or", Value: bson.A{
			bson.D{{Key: "$lt", Value: bson.A{operand, low}}},
			bson.D{{Key: "$gt", Value: bson.A{operand, high}}},
		}}}, nil
	}
	return bson.D{{Key: "$and", Value: bson.A{
		bson.D{{Key: "$gte", Value: bson.A{operand, low}}},
		bson.D{{Key: "$lte", Value: bson.A{operand, high}}},
	}}}, nil
}

func (t *translator) likeExpression(n likeMatch) (any, *queravuev1.QueryBuilderError) {
	operand, err := t.expression(n.operand)
	if err != nil {
		return nil, err
	}
	regex, err := likeRegex(n)
	if err != nil {
		return nil, err
	}
	t.warnings.add(warnLikeRegex, n.offset)
	spec := bson.D{{Key: "input", Value: operand}, {Key: "regex", Value: regex.Pattern}}
	if regex.Options != "" {
		spec = append(spec, bson.E{Key: "options", Value: regex.Options})
	}
	match := bson.D{{Key: "$regexMatch", Value: spec}}
	if n.negated {
		t.warnings.add(warnNegationMatchesMissing, n.offset)
		return bson.D{{Key: "$not", Value: bson.A{match}}}, nil
	}
	return match, nil
}
