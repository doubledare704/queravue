package mongosql

import (
	"fmt"
	"math"
	"strconv"
	"strings"
	"time"

	"go.mongodb.org/mongo-driver/v2/bson"
)

func relaxedNumber(text string) (any, error) {
	if isIntegerText(text) {
		n, err := strconv.ParseInt(text, 10, 64)
		if err != nil {
			return nil, fmt.Errorf("integer %s does not fit in 64 bits", text)
		}
		if n >= math.MinInt32 && n <= math.MaxInt32 {
			return int32(n), nil
		}
		return n, nil
	}
	f, err := strconv.ParseFloat(text, 64)
	if err != nil || math.IsInf(f, 0) {
		return nil, fmt.Errorf("invalid number %s", text)
	}
	return f, nil
}

func isIntegerText(text string) bool {
	digits := strings.TrimPrefix(strings.TrimPrefix(text, "-"), "+")
	if digits == "" {
		return false
	}
	for _, c := range digits {
		if c < '0' || c > '9' {
			return false
		}
	}
	return true
}

func numberLong(text string) (int64, error) {
	if !isIntegerText(text) {
		return 0, fmt.Errorf("NUMBERLONG needs an integer, got %s", text)
	}
	n, err := strconv.ParseInt(text, 10, 64)
	if err != nil {
		return 0, fmt.Errorf("NUMBERLONG %s does not fit in 64 bits", text)
	}
	return n, nil
}

func numberDecimal(text string) (bson.Decimal128, error) {
	d, err := bson.ParseDecimal128(text)
	if err != nil {
		return bson.Decimal128{}, fmt.Errorf("NUMBERDECIMAL needs a decimal number, got %q", text)
	}
	return d, nil
}

func objectID(text string) (bson.ObjectID, error) {
	id, err := bson.ObjectIDFromHex(text)
	if err != nil {
		return bson.ObjectID{}, fmt.Errorf("OBJECTID needs 24 hex digits, got %q", text)
	}
	return id, nil
}

func dateLiteral(text string) (bson.DateTime, error) {
	t, err := time.Parse(time.DateOnly, text)
	if err != nil {
		return 0, fmt.Errorf("DATE needs YYYY-MM-DD, got %q", text)
	}
	return bson.NewDateTimeFromTime(t), nil
}

var timestampLayouts = []string{
	"2006-01-02 15:04:05.999Z07:00",
	"2006-01-02T15:04:05.999Z07:00",
	"2006-01-02 15:04:05.999",
	"2006-01-02T15:04:05.999",
	"2006-01-02 15:04",
	"2006-01-02T15:04",
}

func timestampLiteral(text string) (bson.DateTime, error) {
	if fractionDigits(text) > 3 {
		return 0, fmt.Errorf("TIMESTAMP %q is more precise than the milliseconds a BSON date holds", text)
	}
	for _, layout := range timestampLayouts {
		if t, err := time.Parse(layout, text); err == nil {
			return bson.NewDateTimeFromTime(t), nil
		}
	}
	return 0, fmt.Errorf("TIMESTAMP needs YYYY-MM-DD HH:MM:SS[.fff][Z|±HH:MM], got %q", text)
}

func fractionDigits(text string) int {
	dot := strings.IndexByte(text, '.')
	if dot < 0 {
		return 0
	}
	n := 0
	for _, c := range text[dot+1:] {
		if c < '0' || c > '9' {
			break
		}
		n++
	}
	return n
}
