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
)

var warningMessages = map[warningKind]string{
	warnNullMatchesMissing:     "IS NULL also matches documents where the field is missing",
	warnArrayEquality:          "= and IN on an array field match when any element matches",
	warnTypeBrackets:           "range comparisons only match values of the same BSON type: age > 30 skips the string \"40\"",
	warnLikeRegex:              "LIKE becomes an anchored, escaped $regex; ILIKE adds the i option",
	warnNegationMatchesMissing: "<>, NOT IN, NOT LIKE and negated conditions also match documents where the field is null or missing",
	warnNullsSortFirst:         "ORDER BY sorts null and missing values first in ascending order and last in descending order",
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
