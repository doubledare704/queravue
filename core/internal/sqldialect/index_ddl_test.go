package sqldialect_test

import (
	"strings"
	"testing"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/sqldialect"
)

func asc(names ...string) []engine.IndexKey {
	keys := make([]engine.IndexKey, len(names))
	for i, n := range names {
		keys[i] = engine.IndexKey{Name: n}
	}
	return keys
}

func TestCreateIndexSQL(t *testing.T) {
	composite := engine.IndexSpec{Name: "orders_cust_created", Keys: []engine.IndexKey{{Name: "customer_id"}, {Name: "created_at", Kind: engine.IndexKeyDescending}}}
	tests := []struct {
		name   string
		d      sqldialect.Dialect
		schema string
		spec   engine.IndexSpec
		want   string
	}{
		{"postgres composite", sqldialect.Postgres, "public", composite,
			`CREATE INDEX "orders_cust_created" ON "public"."orders" ("customer_id", "created_at" DESC);`},
		{"postgres full", sqldialect.Postgres, "public", engine.IndexSpec{
			Name: "ix", Unique: true, Method: "btree", Keys: asc("email"), IncludeColumns: []string{"name"}, PartialPredicate: "deleted_at IS NULL"},
			`CREATE UNIQUE INDEX "ix" ON "public"."orders" USING btree ("email") INCLUDE ("name") WHERE deleted_at IS NULL;`},
		{"postgres expression", sqldialect.Postgres, "", engine.IndexSpec{
			Name: "ix_lower", Keys: []engine.IndexKey{{Name: "lower(email)", IsExpression: true}}},
			`CREATE INDEX "ix_lower" ON "orders" ((lower(email)));`},
		{"postgres default name", sqldialect.Postgres, "", engine.IndexSpec{Keys: asc("a", "b c")},
			`CREATE INDEX "ix_orders_a_b_c" ON "orders" ("a", "b c");`},
		{"mysql", sqldialect.MySQL, "shop", composite,
			"CREATE INDEX `orders_cust_created` ON `shop`.`orders` (`customer_id`, `created_at` DESC);"},
		{"mysql method", sqldialect.MySQL, "", engine.IndexSpec{Name: "ix", Method: "HASH", Keys: asc("a")},
			"CREATE INDEX `ix` ON `orders` (`a`) USING HASH;"},
		{"mssql include partial", sqldialect.MSSQL, "dbo", engine.IndexSpec{
			Name: "ix", Keys: asc("a"), IncludeColumns: []string{"b"}, PartialPredicate: "[a] > 0"},
			"CREATE INDEX [ix] ON [dbo].[orders] ([a]) INCLUDE ([b]) WHERE [a] > 0;"},
		{"sqlite main", sqldialect.SQLite, "main", engine.IndexSpec{Name: "ix", Unique: true, Keys: asc("a")},
			`CREATE UNIQUE INDEX "ix" ON "orders" ("a");`},
		{"sqlite attached", sqldialect.SQLite, "aux", engine.IndexSpec{Name: "ix", Keys: asc("a")},
			`CREATE INDEX "aux"."ix" ON "orders" ("a");`},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, _, err := tt.d.CreateIndex("", tt.schema, "orders", tt.spec)
			if err != nil {
				t.Fatal(err)
			}
			if got != tt.want {
				t.Errorf("got  %s\nwant %s", got, tt.want)
			}
		})
	}
}

func TestCreateIndexSQLRefuses(t *testing.T) {
	tests := []struct {
		name string
		d    sqldialect.Dialect
		spec engine.IndexSpec
		want string
	}{
		{"no keys", sqldialect.Postgres, engine.IndexSpec{Name: "ix"}, "at least one key"},
		{"mysql include", sqldialect.MySQL, engine.IndexSpec{Keys: asc("a"), IncludeColumns: []string{"b"}}, "included columns"},
		{"mysql partial", sqldialect.MySQL, engine.IndexSpec{Keys: asc("a"), PartialPredicate: "a > 0"}, "partial"},
		{"mssql method", sqldialect.MSSQL, engine.IndexSpec{Keys: asc("a"), Method: "hash"}, "index method"},
		{"mssql expression", sqldialect.MSSQL, engine.IndexSpec{Keys: []engine.IndexKey{{Name: "lower(a)", IsExpression: true}}}, "expression"},
		{"sqlite include", sqldialect.SQLite, engine.IndexSpec{Keys: asc("a"), IncludeColumns: []string{"b"}}, "included columns"},
		{"mongo key kind", sqldialect.Postgres, engine.IndexSpec{Keys: []engine.IndexKey{{Name: "a", Kind: engine.IndexKeyText}}}, "key kind"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			_, _, err := tt.d.CreateIndex("", "", "orders", tt.spec)
			if err == nil || !strings.Contains(err.Error(), tt.want) {
				t.Fatalf("error = %v, want one containing %q", err, tt.want)
			}
		})
	}
}

func TestCreateIndexWarnsAboutLocking(t *testing.T) {
	for _, d := range []sqldialect.Dialect{sqldialect.Postgres, sqldialect.MSSQL} {
		_, warnings, err := d.CreateIndex("", "", "t", engine.IndexSpec{Keys: asc("a")})
		if err != nil || len(warnings) == 0 {
			t.Errorf("%s: warnings = %v, err = %v", d.ID(), warnings, err)
		}
	}
	_, warnings, _ := sqldialect.SQLite.CreateIndex("", "", "t", engine.IndexSpec{Keys: asc("a")})
	if len(warnings) != 0 {
		t.Errorf("sqlite warnings = %v", warnings)
	}
}

func TestDropIndexSQL(t *testing.T) {
	tests := []struct {
		d            sqldialect.Dialect
		schema, want string
	}{
		{sqldialect.Postgres, "public", `DROP INDEX "public"."ix";`},
		{sqldialect.Postgres, "", `DROP INDEX "ix";`},
		{sqldialect.MySQL, "shop", "DROP INDEX `ix` ON `shop`.`orders`;"},
		{sqldialect.MSSQL, "dbo", "DROP INDEX [ix] ON [dbo].[orders];"},
		{sqldialect.SQLite, "main", `DROP INDEX "ix";`},
	}
	for _, tt := range tests {
		t.Run(tt.d.ID()+tt.schema, func(t *testing.T) {
			if got := tt.d.DropIndex("", tt.schema, "orders", "ix"); got != tt.want {
				t.Errorf("got %s want %s", got, tt.want)
			}
		})
	}
}
