package sqldialect_test

import (
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/sqldialect"
	"github.com/doubledare704/queravue/core/internal/sqlsplit"
)

func TestDuckDB(t *testing.T) {
	d := sqldialect.DuckDB
	if got := d.QuoteIdent(`we"ird`); got != `"we""ird"` {
		t.Errorf("QuoteIdent = %s", got)
	}
	if got := d.QualifyTable("s", "t"); got != `"s"."t"` {
		t.Errorf("QualifyTable = %s", got)
	}
	if got := d.QualifyTableIn("", "", "t"); got != `"t"` {
		t.Errorf("QualifyTableIn without database = %s", got)
	}
	if got := d.QualifyTableIn("other", "", "t"); got != `"other"."main"."t"` {
		t.Errorf("QualifyTableIn with database = %s", got)
	}
	if got := d.Placeholder(3); got != "?" {
		t.Errorf("Placeholder = %s", got)
	}
	if got := d.OrderTerm(`"a"`, true, sqldialect.NullsLast); got != `"a" DESC NULLS LAST` {
		t.Errorf("OrderTerm = %s", got)
	}
	if got, stable := d.Paginate("SELECT 1", 5, false); got != "SELECT 1 LIMIT 5" || !stable {
		t.Errorf("Paginate = %s, %v", got, stable)
	}
	if got := d.ILike(`"a"`, "?"); got != `"a" ILIKE ?` {
		t.Errorf("ILike = %s", got)
	}
	if d.Lexer() != sqlsplit.DuckDB {
		t.Errorf("Lexer = %v", d.Lexer())
	}
	literals := map[string]engine.Value{
		`'it''s'`:                  engine.Text("it's"),
		`'\x00\xFF'::BLOB`:         engine.Bytes([]byte{0, 0xff}),
		"NULL":                     engine.Null(),
		"TRUE":                     engine.Bool(true),
		"'2026-01-02 03:04:05.5Z'": engine.Timestamptz(time.Date(2026, 1, 2, 3, 4, 5, 500_000_000, time.UTC)),
	}
	for want, v := range literals {
		if got := d.FormatLiteral(v); got != want {
			t.Errorf("FormatLiteral(%+v) = %s, want %s", v, got, want)
		}
	}
}

func TestDuckDBIndexes(t *testing.T) {
	d := sqldialect.DuckDB
	sql, warnings, err := d.CreateIndex("", "main", "t", engine.IndexSpec{Name: "ix", Unique: true, Keys: []engine.IndexKey{{Name: "a"}, {Name: "b"}}})
	if err != nil || sql != `CREATE UNIQUE INDEX "ix" ON "main"."t" ("a", "b");` || len(warnings) != 1 {
		t.Errorf("CreateIndex = %q, %v, %v", sql, warnings, err)
	}
	for name, spec := range map[string]engine.IndexSpec{
		"partial": {Keys: []engine.IndexKey{{Name: "a"}}, PartialPredicate: "a > 0"},
		"include": {Keys: []engine.IndexKey{{Name: "a"}}, IncludeColumns: []string{"b"}},
		"method":  {Keys: []engine.IndexKey{{Name: "a"}}, Method: "hash"},
		"no keys": {},
	} {
		if _, _, err := d.CreateIndex("", "", "t", spec); err == nil {
			t.Errorf("%s: CreateIndex must refuse", name)
		}
	}
	for want, args := range map[string][3]string{
		`DROP INDEX "ix";`:                 {"", "", "ix"},
		`DROP INDEX "s"."ix";`:             {"", "s", "ix"},
		`DROP INDEX "other"."main"."ix";`:  {"other", "", "ix"},
		`DROP INDEX "other"."extra"."ix";`: {"other", "extra", "ix"},
	} {
		if got := d.DropIndex(args[0], args[1], "t", args[2]); got != want {
			t.Errorf("DropIndex%v = %s, want %s", args, got, want)
		}
	}
}

func TestDuckDBIdentityUsesASequence(t *testing.T) {
	script, err := sqldialect.BuildDDL(sqldialect.DuckDB, sqldialect.Target{Database: "db", Schema: "main", Table: "t"}, nil, []sqldialect.Change{
		sqldialect.CreateTable{Design: sqldialect.TableDesign{
			Columns:    []sqldialect.ColumnSpec{{Name: "id", TypeName: "integer", Identity: true}, {Name: "n", TypeName: "text", Nullable: true}},
			PrimaryKey: []string{"id"},
		}},
	})
	if err != nil {
		t.Fatal(err)
	}
	want := []string{
		`CREATE SEQUENCE "db"."main"."t_id_seq";`,
		"CREATE TABLE \"db\".\"main\".\"t\" (\n  \"id\" integer DEFAULT nextval('\"db\".\"main\".\"t_id_seq\"') NOT NULL,\n  \"n\" text,\n  PRIMARY KEY (\"id\")\n);",
	}
	if len(script.Statements) != len(want) {
		t.Fatalf("statements = %+v", script.Statements)
	}
	for i, st := range script.Statements {
		if st.SQL != want[i] {
			t.Errorf("statement %d = %q, want %q", i, st.SQL, want[i])
		}
	}
	if !script.Transactional {
		t.Error("DuckDB DDL is transactional")
	}
}
