package sqldialect

import (
	"encoding/hex"
	"fmt"
	"math"
	"regexp"
	"strconv"
	"strings"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/sqlsplit"
)

var decimalLiteral = regexp.MustCompile(`^[+-]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][+-]?[0-9]+)?$`)

// FormatDumpLiteral validates and renders values for a runnable SQL dump.
func FormatDumpLiteral(d Dialect, v engine.Value) (string, error) {
	switch v.Kind {
	case engine.VFloat:
		if math.IsNaN(v.Float) || math.IsInf(v.Float, 0) {
			if d.Lexer() != sqlsplit.Postgres && d.Lexer() != sqlsplit.DuckDB {
				return "", fmt.Errorf("data dump: %s does not support non-finite floats", d.ID())
			}
			return d.FormatLiteral(engine.Text(strconv.FormatFloat(v.Float, 'g', -1, 64))), nil
		}
		return strconv.FormatFloat(v.Float, 'g', -1, 64), nil
	case engine.VDecimal:
		if !decimalLiteral.MatchString(v.Str) {
			switch strings.ToLower(v.Str) {
			case "nan", "infinity", "+infinity", "-infinity", "inf", "+inf", "-inf":
				if d.Lexer() == sqlsplit.Postgres {
					return d.FormatLiteral(engine.Text(v.Str)) + "::numeric", nil
				}
			}
			return "", fmt.Errorf("data dump: invalid decimal literal")
		}
	case engine.VBytes:
		if d.Lexer() == sqlsplit.Postgres {
			return "decode('" + hex.EncodeToString(v.Bytes) + "', 'hex')", nil
		}
	case engine.VText, engine.VUUID, engine.VJSON:
		if d.Lexer() == sqlsplit.Postgres && strings.ContainsRune(v.Str, '\\') {
			return "E" + d.FormatLiteral(engine.Text(strings.ReplaceAll(v.Str, `\`, `\\`))), nil
		}
	case engine.VArray:
		return dumpArray(d, v.Array)
	}
	return d.FormatLiteral(v), nil
}

func dumpArray(d Dialect, values []engine.Value) (string, error) {
	prefix := "["
	switch d.Lexer() {
	case sqlsplit.Postgres:
		if len(values) == 0 {
			return "'{}'", nil
		}
		prefix = "ARRAY["
	case sqlsplit.ClickHouse, sqlsplit.DuckDB:
	default:
		return "", fmt.Errorf("data dump: %s does not support array literals", d.ID())
	}
	var out strings.Builder
	out.WriteString(prefix)
	for i, value := range values {
		if d.Lexer() == sqlsplit.Postgres && value.Kind == engine.VArray && len(value.Array) == 0 {
			return "", fmt.Errorf("data dump: PostgreSQL cannot preserve an empty array inside an array")
		}
		part, err := FormatDumpLiteral(d, value)
		if err != nil {
			return "", err
		}
		if i > 0 {
			out.WriteString(", ")
		}
		out.WriteString(part)
	}
	out.WriteByte(']')
	return out.String(), nil
}
