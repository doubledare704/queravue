package mongosql

import (
	"sort"

	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
)

type warningKind int

const (
	warnNullMatchesMissing warningKind = iota + 1
	warnArrayEquality
	warnTypeBrackets
	warnLikeRegex
	warnNegationMatchesMissing
	warnNullsSortFirst
	warnCountNonNull
	warnArithmetic
	warnExpressionNullOrdering
	warnCompoundJoin
	warnJoinNullKey
	warnEmptyGlobalAggregate
	warnSumWithoutValues
)

var warningMessages = map[warningKind]string{
	warnNullMatchesMissing:     "IS NULL also matches documents where the field is missing",
	warnArrayEquality:          "= and IN on an array field match when any element matches",
	warnTypeBrackets:           "range comparisons only match values of the same BSON type: age > 30 skips the string \"40\"",
	warnLikeRegex:              "LIKE becomes an anchored, escaped $regex; ILIKE adds the i option",
	warnNegationMatchesMissing: "<>, NOT IN, NOT LIKE and negated conditions also match documents where the field is null or missing",
	warnNullsSortFirst:         "ORDER BY sorts null and missing values first in ascending order and last in descending order",
	warnCountNonNull:           "COUNT(f) counts documents where f is neither null nor missing",
	warnArithmetic:             "+ - * / run as $add, $subtract, $multiply and $divide: operands must be numbers, a null or missing operand gives null, and / always returns a double",
	warnExpressionNullOrdering: "comparisons computed with $expr rank null and missing below every other value, so a null operand can satisfy < and <=",
	warnCompoundJoin:           "a JOIN with more than one ON condition becomes $lookup with let and pipeline, which older DocumentDB and Cosmos DB servers reject",
	warnJoinNullKey:            "JOIN matches a null or missing key with null or missing keys in the other collection, which SQL never does",
	warnEmptyGlobalAggregate:   "an aggregate without GROUP BY over no matching documents returns no row, where SQL returns one",
	warnSumWithoutValues:       "SUM of no numeric values is 0, where SQL returns NULL",
}

type warnings struct {
	firstOffset map[warningKind]int
}

func (w *warnings) add(kind warningKind, offset int) {
	if w.firstOffset == nil {
		w.firstOffset = map[warningKind]int{}
	}
	if prev, ok := w.firstOffset[kind]; !ok || offset < prev {
		w.firstOffset[kind] = offset
	}
}

func (w *warnings) proto() []*queravuev1.MongoSqlWarning {
	kinds := make([]warningKind, 0, len(w.firstOffset))
	for kind := range w.firstOffset {
		kinds = append(kinds, kind)
	}
	sort.Slice(kinds, func(i, j int) bool {
		oi, oj := w.firstOffset[kinds[i]], w.firstOffset[kinds[j]]
		if oi != oj {
			return oi < oj
		}
		return kinds[i] < kinds[j]
	})
	out := make([]*queravuev1.MongoSqlWarning, 0, len(kinds))
	for _, kind := range kinds {
		out = append(out, &queravuev1.MongoSqlWarning{Message: warningMessages[kind], Offset: offsetOf(w.firstOffset[kind])})
	}
	return out
}
