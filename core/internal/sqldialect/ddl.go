package sqldialect

import (
	"errors"
	"fmt"
	"regexp"
	"strings"

	"github.com/doubledare704/queravue/core/internal/engine"
)

var simpleName = regexp.MustCompile(`^[A-Za-z0-9_.-]+$`)

// UnsupportedError means the dialect cannot express a change; Reason is shown to the user.
type UnsupportedError struct{ Reason string }

func (e *UnsupportedError) Error() string { return e.Reason }

func unsupported(format string, args ...any) error {
	return &UnsupportedError{Reason: fmt.Sprintf(format, args...)}
}

// BuildDDL turns changes into statements, in order. current is the table as
// the server reports it, or nil when unknown, for example before CreateTable.
func BuildDDL(d Dialect, target Target, current *engine.TableDetails, changes []Change) (Script, error) {
	b := &ddlBuilder{d: d, target: target, current: current}
	b.script.Transactional = d.ID() != "mysql" && d.ID() != "oracle"
	if !b.script.Transactional {
		b.warn("This server commits each DDL statement as it runs. If a statement fails, the earlier ones stay applied.")
	}
	if b.is("sqlite") {
		changes = foldSQLiteReferences(changes)
	}
	if err := b.rebuildIfNeeded(changes); err != nil {
		return Script{}, err
	}
	for i, ch := range changes {
		if b.rebuilt {
			break
		}
		if err := b.apply(ch); err != nil {
			var u *UnsupportedError
			if errors.As(err, &u) {
				return Script{}, &UnsupportedError{Reason: fmt.Sprintf("change %d: %s", i+1, u.Reason)}
			}
			return Script{}, fmt.Errorf("change %d: %w", i+1, err)
		}
	}
	if len(b.script.Statements) == 0 {
		return Script{}, errors.New("no changes to apply")
	}
	return b.script, nil
}

type ddlBuilder struct {
	d       Dialect
	target  Target
	current *engine.TableDetails
	script  Script
	rebuilt bool
}

// rebuildIfNeeded handles SQLite column alters and foreign keys on existing
// columns, which are done by rebuilding the table. Only added columns may
// come with them: anything else would be lost or reordered by the rebuild
// (ADR 0014).
func (b *ddlBuilder) rebuildIfNeeded(changes []Change) error {
	if !b.is("sqlite") {
		return nil
	}
	var parts rebuildParts
	others := 0
	for _, ch := range changes {
		switch c := ch.(type) {
		case AlterColumn:
			parts.alters = append(parts.alters, c)
		case AddForeignKey:
			parts.foreignKeys = append(parts.foreignKeys, c.ForeignKey)
		case AddColumn:
			parts.added = append(parts.added, c.Column)
		case referencingColumn:
			parts.added = append(parts.added, c.Column)
			parts.foreignKeys = append(parts.foreignKeys, c.ForeignKey)
		default:
			others++
		}
	}
	if len(parts.alters) == 0 && !hasTableLevelForeignKey(changes) {
		return nil
	}
	if others > 0 {
		return &UnsupportedError{Reason: "SQLite rebuilds the table to alter a column or add a foreign key to an existing column, so only added columns can go with it: apply those changes on their own, then the rest"}
	}
	if err := b.rebuildSQLite(parts); err != nil {
		var u *UnsupportedError
		if errors.As(err, &u) {
			return err
		}
		return fmt.Errorf("alter column: %w", err)
	}
	b.rebuilt = true
	return nil
}

func (b *ddlBuilder) warn(msg string) { b.script.Warnings = append(b.script.Warnings, msg) }

func (b *ddlBuilder) emit(sql, summary string, destructive bool) {
	if !strings.HasSuffix(sql, ";") {
		sql += ";"
	}
	b.script.Statements = append(b.script.Statements, Statement{SQL: sql, Destructive: destructive, Summary: summary})
}

func (b *ddlBuilder) is(ids ...string) bool {
	for _, id := range ids {
		if b.d.ID() == id {
			return true
		}
	}
	return false
}

func (b *ddlBuilder) q(name string) string { return b.d.QuoteIdent(name) }

func (b *ddlBuilder) table() string {
	return b.d.QualifyTableIn(b.target.Database, b.target.Schema, b.target.Table)
}

func (b *ddlBuilder) apply(ch Change) error {
	switch c := ch.(type) {
	case CreateTable:
		return b.createTable(c.Design)
	case DropTable:
		b.emit("DROP TABLE "+b.table(), "Drop table "+b.target.Table, true)
	case RenameTable:
		return b.renameTable(c.NewName)
	case AddColumn:
		return b.addColumn(c.Column)
	case referencingColumn:
		return b.addReferencingColumn(c)
	case DropColumn:
		b.emit("ALTER TABLE "+b.table()+" DROP COLUMN "+b.q(c.Name), "Drop column "+c.Name, true)
	case RenameColumn:
		b.renameColumn(c.From, c.To)
	case AlterColumn:
		return b.alterColumn(c.Before, c.After)
	case AddForeignKey:
		return b.addConstraint("foreign key", c.ForeignKey.Name, func() (string, error) { return b.foreignKey(c.ForeignKey) })
	case AddUnique:
		return b.addConstraint("unique constraint", c.Unique.Name, func() (string, error) { return b.unique(c.Unique) })
	case AddCheck:
		return b.addConstraint("check constraint", c.Check.Name, func() (string, error) { return b.check(c.Check) })
	case DropConstraint:
		return b.dropConstraint(c.Name)
	case AddIndex:
		return b.addIndex(c.Index, false)
	case DropIndex:
		b.emit(b.d.DropIndex(b.target.Database, b.target.Schema, b.target.Table, c.Name), "Drop index "+c.Name, true)
	default:
		return fmt.Errorf("unknown change %T", ch)
	}
	return nil
}

func (b *ddlBuilder) createTable(design TableDesign) error {
	if len(design.Columns) == 0 {
		return errors.New("a table needs at least one column")
	}
	sqliteRowid := ""
	lines := make([]string, 0, len(design.Columns)+len(design.Uniques)+len(design.Checks)+len(design.ForeignKeys)+1)
	for _, col := range design.Columns {
		if b.is("sqlite") && col.Identity {
			if len(design.PrimaryKey) != 1 || design.PrimaryKey[0] != col.Name || !strings.EqualFold(strings.TrimSpace(col.TypeName), "integer") {
				return unsupported("SQLite allows an auto-increment column only as a single-column INTEGER primary key")
			}
			sqliteRowid = col.Name
			lines = append(lines, b.q(col.Name)+" INTEGER PRIMARY KEY AUTOINCREMENT")
			continue
		}
		def, err := b.columnDefinition(col)
		if err != nil {
			return err
		}
		lines = append(lines, def)
	}
	if len(design.PrimaryKey) > 0 && sqliteRowid == "" {
		pk := "PRIMARY KEY (" + b.columnList(design.PrimaryKey) + ")"
		lines = append(lines, b.named(design.PrimaryKeyName, pk))
	}
	for _, u := range design.Uniques {
		def, err := b.unique(u)
		if err != nil {
			return err
		}
		lines = append(lines, def)
	}
	for _, ck := range design.Checks {
		def, err := b.check(ck)
		if err != nil {
			return err
		}
		lines = append(lines, def)
	}
	for _, fk := range design.ForeignKeys {
		def, err := b.foreignKey(fk)
		if err != nil {
			return err
		}
		lines = append(lines, def)
	}
	b.emit("CREATE TABLE "+b.table()+" (\n  "+strings.Join(lines, ",\n  ")+"\n)", "Create table "+b.target.Table, false)
	for _, ix := range design.Indexes {
		if err := b.addIndex(ix, true); err != nil {
			return err
		}
	}
	return nil
}

func (b *ddlBuilder) named(name, definition string) string {
	if name == "" || (b.is("mysql") && strings.HasPrefix(definition, "PRIMARY KEY")) {
		return definition
	}
	return "CONSTRAINT " + b.q(name) + " " + definition
}

func (b *ddlBuilder) columnList(cols []string) string {
	quoted := make([]string, len(cols))
	for i, c := range cols {
		quoted[i] = b.q(c)
	}
	return strings.Join(quoted, ", ")
}

func (b *ddlBuilder) collation(col ColumnSpec) (string, error) {
	if col.Collation == nil || *col.Collation == "" {
		return "", nil
	}
	name := *col.Collation
	if !simpleName.MatchString(name) {
		return "", fmt.Errorf("invalid collation name %q", name)
	}
	if b.is("postgres") {
		return " COLLATE " + b.q(name), nil
	}
	return " COLLATE " + name, nil
}

func (b *ddlBuilder) identityClause() string {
	switch b.d.ID() {
	case "postgres":
		return " GENERATED BY DEFAULT AS IDENTITY"
	case "mysql":
		return " AUTO_INCREMENT"
	case "mssql":
		return " IDENTITY(1,1)"
	case "oracle":
		return " GENERATED BY DEFAULT AS IDENTITY"
	}
	return ""
}

func (b *ddlBuilder) columnDefinition(col ColumnSpec) (string, error) {
	if col.Name == "" || strings.TrimSpace(col.TypeName) == "" {
		return "", errors.New("a column needs a name and a type")
	}
	collation, err := b.collation(col)
	if err != nil {
		return "", err
	}
	def := b.q(col.Name) + " " + col.TypeName + collation
	if b.is("oracle") {
		return b.oracleColumnDefinition(def, col)
	}
	if col.Identity && b.is("duckdb") {
		return b.duckdbIdentityDefinition(def, col)
	}
	if col.Identity {
		clause := b.identityClause()
		if clause == "" {
			return "", unsupported("%s cannot add an auto-generated column here", b.d.ID())
		}
		def += clause
	}
	switch {
	case !col.Nullable:
		def += " NOT NULL"
	case b.is("mssql"):
		def += " NULL"
	}
	if col.Default != nil {
		def += " DEFAULT " + *col.Default
	}
	return def, nil
}

// oracleColumnDefinition orders the clauses as Oracle requires: DEFAULT,
// then the identity clause, then the nullability.
func (b *ddlBuilder) oracleColumnDefinition(def string, col ColumnSpec) (string, error) {
	if col.Identity && col.Default != nil {
		return "", unsupported("Oracle does not allow a default on an auto-generated column")
	}
	if col.Default != nil {
		def += " DEFAULT " + *col.Default
	}
	if col.Identity {
		def += b.identityClause()
	}
	if !col.Nullable {
		def += " NOT NULL"
	}
	return def, nil
}

func (b *ddlBuilder) addColumn(col ColumnSpec) error {
	def, err := b.columnDefinition(col)
	if err != nil {
		return err
	}
	keyword := " ADD COLUMN "
	if b.is("mssql", "oracle") {
		keyword = " ADD "
	}
	b.emit("ALTER TABLE "+b.table()+keyword+def, "Add column "+col.Name, false)
	return nil
}

func (b *ddlBuilder) renameTable(newName string) error {
	if newName == "" {
		return errors.New("a new table name is required")
	}
	if b.is("mssql") {
		old := b.q(b.target.Table)
		if b.target.Schema != "" {
			old = b.q(b.target.Schema) + "." + old
		}
		b.emit("EXEC sp_rename N"+quoteString(old)+", N"+quoteString(newName), "Rename table "+b.target.Table+" to "+newName, false)
		b.warn("sp_rename does not update views, procedures or scripts that use the old table name.")
	} else {
		b.emit("ALTER TABLE "+b.table()+" RENAME TO "+b.q(newName), "Rename table "+b.target.Table+" to "+newName, false)
	}
	b.target.Table = newName
	return nil
}

func (b *ddlBuilder) renameColumn(from, to string) {
	summary := "Rename column " + from + " to " + to
	if b.is("mssql") {
		path := b.q(b.target.Table) + "." + b.q(from)
		if b.target.Schema != "" {
			path = b.q(b.target.Schema) + "." + path
		}
		b.emit("EXEC sp_rename N"+quoteString(path)+", N"+quoteString(to)+", N'COLUMN'", summary, false)
		return
	}
	b.emit("ALTER TABLE "+b.table()+" RENAME COLUMN "+b.q(from)+" TO "+b.q(to), summary, false)
}

func quoteString(s string) string { return "'" + strings.ReplaceAll(s, "'", "''") + "'" }

func sameType(a, b string) bool {
	return strings.EqualFold(strings.Join(strings.Fields(a), " "), strings.Join(strings.Fields(b), " "))
}

func sameOptional(a, b *string) bool {
	if a == nil || b == nil {
		return a == b
	}
	return *a == *b
}

func (b *ddlBuilder) alterColumn(before, after ColumnSpec) error {
	typeChanged := !sameType(before.TypeName, after.TypeName)
	nullChanged := before.Nullable != after.Nullable
	defaultChanged := !sameOptional(before.Default, after.Default)
	collationChanged := !sameOptional(before.Collation, after.Collation)
	identityChanged := before.Identity != after.Identity
	if !typeChanged && !nullChanged && !defaultChanged && !collationChanged && !identityChanged {
		return errors.New("alter column " + after.Name + ": nothing differs")
	}
	summary := "Alter column " + after.Name
	table := "ALTER TABLE " + b.table()
	col := b.q(after.Name)

	switch b.d.ID() {
	case "postgres", "duckdb":
		if identityChanged {
			return unsupported("changing whether a column is auto-generated is not supported on this server")
		}
		if typeChanged || collationChanged {
			collation, err := b.collation(after)
			if err != nil {
				return err
			}
			b.emit(table+" ALTER COLUMN "+col+" TYPE "+after.TypeName+collation, summary+" type", typeChanged)
		}
		if nullChanged {
			verb := "DROP"
			if !after.Nullable {
				verb = "SET"
			}
			b.emit(table+" ALTER COLUMN "+col+" "+verb+" NOT NULL", summary+" nullability", false)
		}
		if defaultChanged {
			action := "DROP DEFAULT"
			if after.Default != nil {
				action = "SET DEFAULT " + *after.Default
			}
			b.emit(table+" ALTER COLUMN "+col+" "+action, summary+" default", false)
		}
	case "mysql":
		def, err := b.columnDefinition(after)
		if err != nil {
			return err
		}
		b.emit(table+" MODIFY COLUMN "+def, summary, typeChanged)
	case "mssql":
		if defaultChanged {
			return unsupported("SQL Server stores a default as a named constraint; drop the old constraint and add a new one")
		}
		if identityChanged {
			return unsupported("SQL Server cannot change a column to or from IDENTITY in place")
		}
		collation, err := b.collation(after)
		if err != nil {
			return err
		}
		nullability := " NULL"
		if !after.Nullable {
			nullability = " NOT NULL"
		}
		b.emit(table+" ALTER COLUMN "+col+" "+after.TypeName+collation+nullability, summary, typeChanged)
	case "oracle":
		return b.oracleAlterColumn(before, after, summary)
	default:
		return unsupported("SQLite cannot alter a column in place; create a new table, copy the rows, and swap them")
	}
	return nil
}

func (b *ddlBuilder) oracleAlterColumn(before, after ColumnSpec, summary string) error {
	if before.Identity != after.Identity {
		return unsupported("Oracle cannot change a column to or from auto-generated here")
	}
	clause := b.q(after.Name)
	typeChanged := !sameType(before.TypeName, after.TypeName)
	if typeChanged || !sameOptional(before.Collation, after.Collation) {
		collation, err := b.collation(after)
		if err != nil {
			return err
		}
		clause += " " + after.TypeName + collation
	}
	if !sameOptional(before.Default, after.Default) {
		if after.Default == nil {
			clause += " DEFAULT NULL"
		} else {
			clause += " DEFAULT " + *after.Default
		}
	}
	if before.Nullable != after.Nullable {
		if after.Nullable {
			clause += " NULL"
		} else {
			clause += " NOT NULL"
		}
	}
	b.emit("ALTER TABLE "+b.table()+" MODIFY ("+clause+")", summary, typeChanged)
	return nil
}

func referentialSQL(a engine.ReferentialAction) string {
	switch a {
	case engine.ReferentialNoAction:
		return "NO ACTION"
	case engine.ReferentialRestrict:
		return "RESTRICT"
	case engine.ReferentialCascade:
		return "CASCADE"
	case engine.ReferentialSetNull:
		return "SET NULL"
	case engine.ReferentialSetDefault:
		return "SET DEFAULT"
	case engine.ReferentialDefault:
		return ""
	}
	return ""
}

func (b *ddlBuilder) foreignKey(fk ForeignKeySpec) (string, error) {
	if len(fk.Columns) == 0 || len(fk.Columns) != len(fk.RefColumns) || fk.RefTable == "" {
		return "", errors.New("a foreign key needs matching columns and a referenced table")
	}
	refSchema := fk.RefSchema
	if refSchema == "" {
		refSchema = b.target.Schema
	}
	def := "FOREIGN KEY (" + b.columnList(fk.Columns) + ") " + b.references(fk, refSchema)
	rules, err := b.referentialRules(fk)
	if err != nil {
		return "", err
	}
	return b.named(fk.Name, def+rules), nil
}

func (b *ddlBuilder) references(fk ForeignKeySpec, refSchema string) string {
	// SQLite resolves REFERENCES in the table's own database and rejects a qualified name.
	if b.is("sqlite") {
		return "REFERENCES " + b.q(fk.RefTable) + " (" + b.columnList(fk.RefColumns) + ")"
	}
	return "REFERENCES " + b.d.QualifyTable(refSchema, fk.RefTable) + " (" + b.columnList(fk.RefColumns) + ")"
}

func (b *ddlBuilder) referentialRules(fk ForeignKeySpec) (string, error) {
	def := ""
	for _, rule := range []struct {
		event  string
		action engine.ReferentialAction
	}{{"DELETE", fk.OnDelete}, {"UPDATE", fk.OnUpdate}} {
		if b.is("oracle") {
			clause, err := oracleReferentialRule(rule.event, rule.action)
			if err != nil {
				return "", err
			}
			def += clause
			continue
		}
		text := referentialSQL(rule.action)
		if text == "" {
			continue
		}
		if b.is("duckdb") && !duckdbReferentialAction(rule.action) {
			return "", unsupported("DuckDB foreign keys support only NO ACTION and RESTRICT")
		}
		if b.is("mssql") && (rule.action == engine.ReferentialRestrict) {
			return "", unsupported("SQL Server has no RESTRICT; use NO ACTION")
		}
		if b.is("mysql") && rule.action == engine.ReferentialSetDefault {
			return "", unsupported("InnoDB does not support SET DEFAULT in foreign keys")
		}
		def += " ON " + rule.event + " " + text
	}
	return def, nil
}

// oracleReferentialRule allows only ON DELETE CASCADE and ON DELETE SET NULL;
// every other rule is what Oracle does without a clause.
func oracleReferentialRule(event string, action engine.ReferentialAction) (string, error) {
	switch action {
	case engine.ReferentialDefault, engine.ReferentialNoAction:
		return "", nil
	case engine.ReferentialCascade, engine.ReferentialSetNull:
		if event == "DELETE" {
			return " ON DELETE " + referentialSQL(action), nil
		}
	case engine.ReferentialRestrict, engine.ReferentialSetDefault:
	}
	return "", unsupported("Oracle supports only ON DELETE CASCADE and ON DELETE SET NULL on a foreign key")
}

func (b *ddlBuilder) unique(u UniqueSpec) (string, error) {
	if len(u.Columns) == 0 {
		return "", errors.New("a unique constraint needs columns")
	}
	return b.named(u.Name, "UNIQUE ("+b.columnList(u.Columns)+")"), nil
}

func (b *ddlBuilder) check(c CheckSpec) (string, error) {
	if strings.TrimSpace(c.Expression) == "" {
		return "", errors.New("a check constraint needs an expression")
	}
	return b.named(c.Name, "CHECK ("+c.Expression+")"), nil
}

func (b *ddlBuilder) addConstraint(kind, name string, build func() (string, error)) error {
	if b.is("sqlite") {
		return unsupported("SQLite cannot add a %s to an existing table; for uniqueness add a unique index", kind)
	}
	if b.is("duckdb") && kind != "unique constraint" {
		return unsupported("DuckDB cannot add a %s to an existing table; define it when creating the table", kind)
	}
	def, err := build()
	if err != nil {
		return err
	}
	summary := "Add " + kind
	if name != "" {
		summary += " " + name
	}
	b.emit("ALTER TABLE "+b.table()+" ADD "+def, summary, false)
	return nil
}

func (b *ddlBuilder) dropConstraint(name string) error {
	if b.is("sqlite") {
		return unsupported("SQLite cannot drop a constraint from an existing table")
	}
	if b.is("duckdb") {
		return unsupported("DuckDB cannot drop a constraint; create a new table without it, copy the rows, and swap them")
	}
	if name == "" {
		return errors.New("a constraint name is required")
	}
	action := "DROP CONSTRAINT " + b.q(name)
	if b.is("mysql") {
		action = b.mysqlDropConstraint(name)
	}
	b.emit("ALTER TABLE "+b.table()+" "+action, "Drop constraint "+name, true)
	return nil
}

func (b *ddlBuilder) mysqlDropConstraint(name string) string {
	if b.current != nil {
		for _, fk := range b.current.ForeignKeys {
			if fk.Name == name {
				return "DROP FOREIGN KEY " + b.q(name)
			}
		}
		for _, ix := range b.current.Indexes {
			if ix.Name == name {
				return "DROP INDEX " + b.q(name)
			}
		}
	}
	return "DROP CONSTRAINT " + b.q(name)
}

func (b *ddlBuilder) addIndex(spec engine.IndexSpec, onNewTable bool) error {
	sql, warnings, err := b.d.CreateIndex(b.target.Database, b.target.Schema, b.target.Table, spec)
	if err != nil {
		return err
	}
	name := spec.Name
	if name == "" {
		name = DefaultIndexName(b.target.Table, spec.Keys)
	}
	b.emit(sql, "Add index "+name, false)
	if !onNewTable {
		for _, w := range warnings {
			b.warn(w)
		}
	}
	return nil
}
