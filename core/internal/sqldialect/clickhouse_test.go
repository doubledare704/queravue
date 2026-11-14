package sqldialect_test

import (
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/sqldialect"
	"github.com/doubledare704/queravue/core/internal/sqlsplit"
)

func TestClickHouse(t *testing.T) {
	d := sqldialect.ClickHouse
	if got := d.QuoteIdent("we`ird\\"); got != "`we``ird\\\\`" {
		t.Errorf("QuoteIdent = %s", got)
	}
	if got := d.QualifyTableIn("db", "", "t"); got != "`db`.`t`" {
		t.Errorf("QualifyTableIn = %s", got)
	}
	if got := d.QualifyTable("", "t"); got != "`t`" {
		t.Errorf("QualifyTable = %s", got)
	}
	if got := d.Placeholder(3); got != "?" {
		t.Errorf("Placeholder = %s", got)
	}
	if got := d.OrderTerm("`a`", true, sqldialect.NullsLast); got != "`a` DESC NULLS LAST" {
		t.Errorf("OrderTerm = %s", got)
	}
	if got, stable := d.Paginate("SELECT 1", 5, false); got != "SELECT 1 LIMIT 5" || !stable {
		t.Errorf("Paginate = %s, %v", got, stable)
	}
	if got := d.ILike("`a`", "?"); got != "`a` ILIKE ?" {
		t.Errorf("ILike = %s", got)
	}
	if d.Lexer() != sqlsplit.ClickHouse {
		t.Errorf("Lexer = %v", d.Lexer())
	}
	literals := map[string]engine.Value{
		`'it''s a \\ test'`:       engine.Text(`it's a \ test`),
		"unhex('00FF')":           engine.Bytes([]byte{0, 0xff}),
		"NULL":                    engine.Null(),
		"'2026-01-02 03:04:05.5'": engine.Timestamptz(time.Date(2026, 1, 2, 3, 4, 5, 500_000_000, time.UTC)),
	}
	for want, v := range literals {
		if got := d.FormatLiteral(v); got != want {
			t.Errorf("FormatLiteral(%+v) = %s, want %s", v, got, want)
		}
	}
	if _, _, err := d.CreateIndex("", "", "t", engine.IndexSpec{Name: "i"}); err == nil {
		t.Error("CreateIndex must refuse")
	}
}
