package sqldialect

// referencingColumn is an added column that carries its own single-column
// foreign key, which SQLite accepts in ADD COLUMN.
type referencingColumn struct {
	Column     ColumnSpec
	ForeignKey ForeignKeySpec
}

func (referencingColumn) isChange() {}

// foldSQLiteReferences moves each single-column foreign key on a column added
// in the same script into that column's ADD COLUMN. What is left needs a
// table rebuild.
func foldSQLiteReferences(changes []Change) []Change {
	addedAt := map[string]int{}
	for i, ch := range changes {
		if a, ok := ch.(AddColumn); ok {
			addedAt[a.Column.Name] = i
		}
	}
	folded := make([]Change, len(changes))
	copy(folded, changes)
	dropped := map[int]bool{}
	for i, ch := range changes {
		fk, ok := ch.(AddForeignKey)
		if !ok || len(fk.ForeignKey.Columns) != 1 || len(fk.ForeignKey.RefColumns) != 1 {
			continue
		}
		at, added := addedAt[fk.ForeignKey.Columns[0]]
		if !added {
			continue
		}
		folded[at] = referencingColumn{Column: changes[at].(AddColumn).Column, ForeignKey: fk.ForeignKey}
		delete(addedAt, fk.ForeignKey.Columns[0])
		dropped[i] = true
	}
	out := folded[:0]
	for i, ch := range folded {
		if !dropped[i] {
			out = append(out, ch)
		}
	}
	return out
}

func hasTableLevelForeignKey(changes []Change) bool {
	for _, ch := range changes {
		if _, ok := ch.(AddForeignKey); ok {
			return true
		}
	}
	return false
}

func (b *ddlBuilder) addReferencingColumn(c referencingColumn) error {
	if !c.Column.Nullable || (c.Column.Default != nil && *c.Column.Default != "NULL") {
		return unsupported("SQLite adds a column with a foreign key only when the column starts out NULL: make %s nullable, without a default", c.Column.Name)
	}
	def, err := b.columnDefinition(c.Column)
	if err != nil {
		return err
	}
	rules, err := b.referentialRules(c.ForeignKey)
	if err != nil {
		return err
	}
	reference := b.named(c.ForeignKey.Name, b.references(c.ForeignKey, b.target.Schema)+rules)
	b.emit("ALTER TABLE "+b.table()+" ADD COLUMN "+def+" "+reference,
		"Add column "+c.Column.Name+" referencing "+c.ForeignKey.RefTable, false)
	return nil
}
