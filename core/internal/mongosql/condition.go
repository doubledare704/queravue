package mongosql

import (
	"regexp"
	"slices"
	"strings"

	"go.mongodb.org/mongo-driver/v2/bson"

	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
)

var mongoComparison = map[string]string{"<>": "$ne", "<": "$lt", "<=": "$lte", ">": "$gt", ">=": "$gte"}

var invertedComparison = map[string]string{"=": "<>", "<>": "=", "<": ">=", ">=": "<", ">": "<=", "<=": ">"}

var mirroredComparison = map[string]string{"=": "=", "<>": "<>", "<": ">", ">": "<", "<=": ">=", ">=": "<="}

// negate pushes NOT down to the predicates; each rewrite is exact under SQL's
// three-valued logic, so no $nor is needed.
func negate(e expr) (expr, bool) {
	switch n := e.(type) {
	case logical:
		out := logical{and: !n.and, offset: n.offset}
		for _, operand := range n.operands {
			negated, ok := negate(operand)
			if !ok {
				return nil, false
			}
			out.operands = append(out.operands, negated)
		}
		return out, true
	case negation:
		return n.operand, true
	case comparison:
		n.op = invertedComparison[n.op]
		return n, true
	case inList:
		n.negated = !n.negated
		return n, true
	case between:
		n.negated = !n.negated
		return n, true
	case likeMatch:
		n.negated = !n.negated
		return n, true
	case nullCheck:
		n.negated = !n.negated
		return n, true
	}
	return nil, false
}

func (t *translator) condition(e expr) (bson.D, *queravuev1.QueryBuilderError) {
	switch n := e.(type) {
	case logical:
		return t.logicalCondition(n)
	case negation:
		negated, ok := negate(n.operand)
		if !ok {
			return nil, t.notACondition(n.operand)
		}
		return t.condition(negated)
	case comparison:
		return t.comparisonCondition(n)
	case inList:
		return t.inCondition(n)
	case between:
		return t.betweenCondition(n)
	case likeMatch:
		return t.likeCondition(n)
	case nullCheck:
		return t.nullCondition(n)
	}
	return nil, t.notACondition(e)
}

func (t *translator) notACondition(e expr) *queravuev1.QueryBuilderError {
	switch n := e.(type) {
	case fieldRef:
		return unsupportedError("a bare field is not a condition; compare it, e.g. active = TRUE", n.offset)
	case aggregateCall:
		return unsupportedError("aggregate functions in WHERE are not valid SQL; use HAVING", n.offset)
	case arithmetic:
		return unsupportedError("arithmetic "+needsPipeline, n.offset)
	}
	return unsupportedError("this expression is not a condition", e.pos())
}

func (t *translator) logicalCondition(n logical) (bson.D, *queravuev1.QueryBuilderError) {
	operator := "$or"
	if n.and {
		operator = "$and"
	}
	var parts []bson.D
	for _, operand := range n.operands {
		doc, err := t.condition(operand)
		if err != nil {
			return nil, err
		}
		if len(doc) == 1 && doc[0].Key == operator {
			for _, nested := range doc[0].Value.(bson.A) {
				parts = append(parts, nested.(bson.D))
			}
			continue
		}
		parts = append(parts, doc)
	}
	if n.and {
		if merged, ok := mergeDisjointKeys(parts); ok {
			return merged, nil
		}
	}
	list := make(bson.A, 0, len(parts))
	for _, part := range parts {
		list = append(list, part)
	}
	return bson.D{{Key: operator, Value: list}}, nil
}

func mergeDisjointKeys(parts []bson.D) (bson.D, bool) {
	var merged bson.D
	for _, part := range parts {
		for _, e := range part {
			if slices.ContainsFunc(merged, func(m bson.E) bool { return m.Key == e.Key }) {
				return nil, false
			}
			merged = append(merged, e)
		}
	}
	return merged, true
}

func (t *translator) fieldAndValue(left, right expr, offset int) (string, any, bool, *queravuev1.QueryBuilderError) {
	leftField, leftIsField := left.(fieldRef)
	rightField, rightIsField := right.(fieldRef)
	switch {
	case leftIsField && rightIsField:
		return "", nil, false, unsupportedError("comparing two fields "+needsPipeline, offset)
	case leftIsField:
		value, err := t.value(right)
		if err != nil {
			return "", nil, false, err
		}
		path, err := t.fieldPath(leftField)
		return path, value, false, err
	case rightIsField:
		value, err := t.value(left)
		if err != nil {
			return "", nil, false, err
		}
		path, err := t.fieldPath(rightField)
		return path, value, true, err
	}
	if _, ok := left.(literal); !ok {
		return "", nil, false, t.notAValue(left)
	}
	if _, ok := right.(literal); !ok {
		return "", nil, false, t.notAValue(right)
	}
	return "", nil, false, unsupportedError("a comparison needs a field on one side", offset)
}

func (t *translator) value(e expr) (any, *queravuev1.QueryBuilderError) {
	lit, ok := e.(literal)
	if !ok {
		return nil, t.notAValue(e)
	}
	if lit.isNull {
		return nil, unsupportedError("comparing with NULL is never true in SQL; use IS NULL or IS NOT NULL", lit.offset)
	}
	return lit.value, nil
}

func (t *translator) notAValue(e expr) *queravuev1.QueryBuilderError {
	switch n := e.(type) {
	case aggregateCall:
		return unsupportedError("aggregate functions in WHERE are not valid SQL; use HAVING", n.offset)
	case arithmetic:
		return unsupportedError("arithmetic "+needsPipeline, n.offset)
	}
	return unsupportedError("expected a literal value", e.pos())
}

func (t *translator) comparisonCondition(n comparison) (bson.D, *queravuev1.QueryBuilderError) {
	path, value, mirrored, err := t.fieldAndValue(n.left, n.right, n.offset)
	if err != nil {
		return nil, err
	}
	op := n.op
	if mirrored {
		op = mirroredComparison[op]
	}
	switch op {
	case "=":
		t.warnings.add(warnArrayEquality, n.offset)
		return bson.D{{Key: path, Value: value}}, nil
	case "<>":
		t.warnings.add(warnNegationMatchesMissing, n.offset)
	default:
		t.warnings.add(warnTypeBrackets, n.offset)
	}
	return bson.D{{Key: path, Value: bson.D{{Key: mongoComparison[op], Value: value}}}}, nil
}

func (t *translator) operandPath(operand expr) (string, *queravuev1.QueryBuilderError) {
	ref, ok := operand.(fieldRef)
	if !ok {
		if _, isLiteral := operand.(literal); isLiteral {
			return "", unsupportedError("the left side must be a field", operand.pos())
		}
		return "", t.notAValue(operand)
	}
	return t.fieldPath(ref)
}

func (t *translator) inCondition(n inList) (bson.D, *queravuev1.QueryBuilderError) {
	path, err := t.operandPath(n.operand)
	if err != nil {
		return nil, err
	}
	values := make(bson.A, 0, len(n.values))
	for _, e := range n.values {
		lit, ok := e.(literal)
		if ok && lit.isNull {
			return nil, unsupportedError("NULL in an IN list never matches in SQL; use IS NULL", lit.offset)
		}
		v, err := t.value(e)
		if err != nil {
			return nil, err
		}
		values = append(values, v)
	}
	operator := "$in"
	if n.negated {
		operator = "$nin"
		t.warnings.add(warnNegationMatchesMissing, n.offset)
	} else {
		t.warnings.add(warnArrayEquality, n.offset)
	}
	return bson.D{{Key: path, Value: bson.D{{Key: operator, Value: values}}}}, nil
}

func (t *translator) betweenCondition(n between) (bson.D, *queravuev1.QueryBuilderError) {
	path, err := t.operandPath(n.operand)
	if err != nil {
		return nil, err
	}
	low, err := t.value(n.low)
	if err != nil {
		return nil, err
	}
	high, err := t.value(n.high)
	if err != nil {
		return nil, err
	}
	t.warnings.add(warnTypeBrackets, n.offset)
	if n.negated {
		return bson.D{{Key: "$or", Value: bson.A{
			bson.D{{Key: path, Value: bson.D{{Key: "$lt", Value: low}}}},
			bson.D{{Key: path, Value: bson.D{{Key: "$gt", Value: high}}}},
		}}}, nil
	}
	return bson.D{{Key: path, Value: bson.D{{Key: "$gte", Value: low}, {Key: "$lte", Value: high}}}}, nil
}

func (t *translator) likeCondition(n likeMatch) (bson.D, *queravuev1.QueryBuilderError) {
	path, err := t.operandPath(n.operand)
	if err != nil {
		return nil, err
	}
	regex, err := likeRegex(n)
	if err != nil {
		return nil, err
	}
	t.warnings.add(warnLikeRegex, n.offset)
	if n.negated {
		t.warnings.add(warnNegationMatchesMissing, n.offset)
		return bson.D{{Key: path, Value: bson.D{{Key: "$not", Value: regex}}}}, nil
	}
	return bson.D{{Key: path, Value: regex}}, nil
}

type likePart struct {
	regex    string
	wildcard bool
}

func likeRegex(n likeMatch) (bson.Regex, *queravuev1.QueryBuilderError) {
	parts, err := likeParts(n)
	if err != nil {
		return bson.Regex{}, err
	}
	anchorStart, anchorEnd := "^", "$"
	for len(parts) > 0 && parts[0].regex == ".*" {
		parts, anchorStart = parts[1:], ""
	}
	for len(parts) > 0 && parts[len(parts)-1].regex == ".*" {
		parts, anchorEnd = parts[:len(parts)-1], ""
	}
	var body strings.Builder
	hasWildcard := false
	for _, part := range parts {
		body.WriteString(part.regex)
		hasWildcard = hasWildcard || part.wildcard
	}
	options := ""
	if n.caseInsensitive {
		options += "i"
	}
	if hasWildcard {
		options += "s"
	}
	return bson.Regex{Pattern: anchorStart + body.String() + anchorEnd, Options: options}, nil
}

func likeParts(n likeMatch) ([]likePart, *queravuev1.QueryBuilderError) {
	var parts []likePart
	escaped := false
	for _, r := range n.pattern {
		switch {
		case escaped:
			parts = append(parts, likePart{regex: regexp.QuoteMeta(string(r))})
			escaped = false
		case n.escape != 0 && r == n.escape:
			escaped = true
		case r == '%':
			parts = append(parts, likePart{regex: ".*", wildcard: true})
		case r == '_':
			parts = append(parts, likePart{regex: ".", wildcard: true})
		default:
			parts = append(parts, likePart{regex: regexp.QuoteMeta(string(r))})
		}
	}
	if escaped {
		return nil, parseError("the LIKE pattern ends with its escape character", n.offset)
	}
	return parts, nil
}

func (t *translator) nullCondition(n nullCheck) (bson.D, *queravuev1.QueryBuilderError) {
	path, err := t.operandPath(n.operand)
	if err != nil {
		return nil, err
	}
	if n.negated {
		return bson.D{{Key: path, Value: bson.D{{Key: "$ne", Value: nil}}}}, nil
	}
	t.warnings.add(warnNullMatchesMissing, n.offset)
	return bson.D{{Key: path, Value: nil}}, nil
}
