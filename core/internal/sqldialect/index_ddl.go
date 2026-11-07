package sqldialect

import (
	"errors"
	"fmt"
	"strings"

	"github.com/doubledare704/queravue/core/internal/engine"
)

type indexSyntax struct {
	dialect          Dialect
	method           bool
	methodAfterKeys  bool
	include          bool
	partial          bool
	expressions      bool
	descending       bool
	qualifyDropName  bool
	schemaOnNewIndex bool
	dropNeedsTable   bool
	largeTableNote   string
	concurrently     bool
	onlineSuffix     string
	onlineNote       string
}

// OptionOnline in IndexSpec.Options asks for a build that does not block writes.
const OptionOnline = "online"

func (x indexSyntax) canBuildOnline() bool { return x.concurrently || x.onlineSuffix != "" }

func (x indexSyntax) create(database, schema, table string, spec engine.IndexSpec) (string, []string, error) {
	if len(spec.Keys) == 0 {
		return "", nil, errors.New("an index needs at least one key")
	}
	if spec.Method != "" && !x.method {
		return "", nil, fmt.Errorf("%s does not support choosing an index method", x.dialect.ID())
	}
	if len(spec.IncludeColumns) > 0 && !x.include {
		return "", nil, fmt.Errorf("%s does not support included columns", x.dialect.ID())
	}
	if spec.PartialPredicate != "" && !x.partial {
		return "", nil, fmt.Errorf("%s does not support partial indexes", x.dialect.ID())
	}
	online := spec.Options[OptionOnline] == "true"
	if online && !x.canBuildOnline() {
		return "", nil, fmt.Errorf("%s cannot build an index online", x.dialect.ID())
	}
	keys := make([]string, 0, len(spec.Keys))
	for _, k := range spec.Keys {
		part, err := x.key(k)
		if err != nil {
			return "", nil, err
		}
		keys = append(keys, part)
	}
	name := spec.Name
	if name == "" {
		name = DefaultIndexName(table, spec.Keys)
	}

	var b strings.Builder
	b.WriteString("CREATE ")
	if spec.Unique {
		b.WriteString("UNIQUE ")
	}
	b.WriteString("INDEX ")
	if online && x.concurrently {
		b.WriteString("CONCURRENTLY ")
	}
	if x.schemaOnNewIndex {
		b.WriteString(x.indexName(schema, name))
		b.WriteString(" ON " + x.dialect.QuoteIdent(table))
	} else {
		b.WriteString(x.dialect.QuoteIdent(name))
		b.WriteString(" ON " + x.dialect.QualifyTableIn(database, schema, table))
	}
	if spec.Method != "" && !x.methodAfterKeys {
		b.WriteString(" USING " + spec.Method)
	}
	b.WriteString(" (" + strings.Join(keys, ", ") + ")")
	if spec.Method != "" && x.methodAfterKeys {
		b.WriteString(" USING " + spec.Method)
	}
	if len(spec.IncludeColumns) > 0 {
		cols := make([]string, len(spec.IncludeColumns))
		for i, c := range spec.IncludeColumns {
			cols[i] = x.dialect.QuoteIdent(c)
		}
		b.WriteString(" INCLUDE (" + strings.Join(cols, ", ") + ")")
	}
	if spec.PartialPredicate != "" {
		b.WriteString(" WHERE " + spec.PartialPredicate)
	}
	if online {
		b.WriteString(x.onlineSuffix)
	}
	b.WriteString(";")

	var warnings []string
	switch {
	case online:
		warnings = append(warnings, x.onlineNote)
	case x.largeTableNote != "":
		warnings = append(warnings, x.largeTableNote)
	}
	return b.String(), warnings, nil
}

func (x indexSyntax) key(k engine.IndexKey) (string, error) {
	switch k.Kind {
	case engine.IndexKeyHashed, engine.IndexKeyText, engine.IndexKeyGeo2DSphere:
		return "", fmt.Errorf("%s does not support this index key kind", x.dialect.ID())
	case engine.IndexKeyAscending, engine.IndexKeyDescending:
	}
	if k.Name == "" {
		return "", errors.New("an index key needs a column")
	}
	part := x.dialect.QuoteIdent(k.Name)
	if k.IsExpression {
		if !x.expressions {
			return "", fmt.Errorf("%s does not support expression indexes", x.dialect.ID())
		}
		part = "(" + k.Name + ")"
	}
	if k.Kind == engine.IndexKeyDescending && x.descending {
		part += " DESC"
	}
	return part, nil
}

func (x indexSyntax) indexName(schema, name string) string {
	if schema != "" && schema != "main" {
		return x.dialect.QuoteIdent(schema) + "." + x.dialect.QuoteIdent(name)
	}
	return x.dialect.QuoteIdent(name)
}

func (x indexSyntax) drop(database, schema, table, name string) string {
	if x.dropNeedsTable {
		return "DROP INDEX " + x.dialect.QuoteIdent(name) + " ON " + x.dialect.QualifyTableIn(database, schema, table) + ";"
	}
	if x.qualifyDropName {
		return "DROP INDEX " + x.indexName(schema, name) + ";"
	}
	return "DROP INDEX " + x.dialect.QuoteIdent(name) + ";"
}

// DefaultIndexName is the name CreateIndex gives an index whose spec has none.
func DefaultIndexName(table string, keys []engine.IndexKey) string {
	parts := []string{"ix", table}
	for _, k := range keys {
		parts = append(parts, sanitizeNamePart(k.Name))
	}
	return strings.Join(parts, "_")
}

func sanitizeNamePart(s string) string {
	return strings.Map(func(r rune) rune {
		switch {
		case r >= 'a' && r <= 'z', r >= 'A' && r <= 'Z', r >= '0' && r <= '9', r == '_':
			return r
		}
		return '_'
	}, s)
}

var (
	postgresIndexes = indexSyntax{dialect: Postgres, method: true, include: true, partial: true, expressions: true, descending: true, qualifyDropName: true,
		largeTableNote: "CREATE INDEX blocks writes to the table while it builds.",
		concurrently:   true,
		onlineNote:     "CONCURRENTLY does not block writes but takes longer. If it fails or is cancelled it leaves an INVALID index that must be dropped before retrying."}
	mysqlIndexes = indexSyntax{dialect: MySQL, method: true, methodAfterKeys: true, expressions: true, descending: true, dropNeedsTable: true,
		onlineSuffix: " ALGORITHM=INPLACE LOCK=NONE",
		onlineNote:   "ALGORITHM=INPLACE, LOCK=NONE makes the server refuse the build instead of locking the table if it cannot be done online."}
	mssqlIndexes = indexSyntax{dialect: MSSQL, include: true, partial: true, descending: true, dropNeedsTable: true,
		largeTableNote: "Unless ONLINE is used, CREATE INDEX blocks writes to the table while it builds.",
		onlineSuffix:   " WITH (ONLINE = ON)",
		onlineNote:     "ONLINE = ON needs an edition of SQL Server that supports online index operations (Enterprise or Developer)."}
	sqliteIndexes = indexSyntax{dialect: SQLite, partial: true, expressions: true, descending: true, qualifyDropName: true, schemaOnNewIndex: true}
)

func (d postgres) CreateIndex(database, schema, table string, spec engine.IndexSpec) (string, []string, error) {
	return postgresIndexes.create(database, schema, table, spec)
}

func (d postgres) DropIndex(database, schema, table, name string) string {
	return postgresIndexes.drop(database, schema, table, name)
}

func (d mysqlDialect) CreateIndex(database, schema, table string, spec engine.IndexSpec) (string, []string, error) {
	return mysqlIndexes.create(database, schema, table, spec)
}

func (d mysqlDialect) DropIndex(database, schema, table, name string) string {
	return mysqlIndexes.drop(database, schema, table, name)
}

func (d mssqlDialect) CreateIndex(database, schema, table string, spec engine.IndexSpec) (string, []string, error) {
	return mssqlIndexes.create(database, schema, table, spec)
}

func (d mssqlDialect) DropIndex(database, schema, table, name string) string {
	return mssqlIndexes.drop(database, schema, table, name)
}

func (d sqliteDialect) CreateIndex(database, schema, table string, spec engine.IndexSpec) (string, []string, error) {
	return sqliteIndexes.create(database, schema, table, spec)
}

func (d sqliteDialect) DropIndex(database, schema, table, name string) string {
	return sqliteIndexes.drop(database, schema, table, name)
}
