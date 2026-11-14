package sqldialect

import (
	"github.com/doubledare704/queravue/core/internal/engine"
)

// duckdbIdentityDefinition gives an auto-generated column its own sequence,
// because DuckDB has no AUTO_INCREMENT. The sequence is created before the
// statement that uses it.
func (b *ddlBuilder) duckdbIdentityDefinition(def string, col ColumnSpec) (string, error) {
	if col.Default != nil {
		return "", unsupported("a DuckDB auto-generated column takes its default from a sequence, so it cannot have another default")
	}
	sequence := b.d.QualifyTableIn(b.target.Database, b.target.Schema, b.target.Table+"_"+col.Name+"_seq")
	b.emit("CREATE SEQUENCE "+sequence, "Create sequence for "+col.Name, false)
	def += " DEFAULT nextval(" + quoteString(sequence) + ")"
	if !col.Nullable {
		def += " NOT NULL"
	}
	return def, nil
}

func duckdbReferentialAction(a engine.ReferentialAction) bool {
	switch a {
	case engine.ReferentialDefault, engine.ReferentialNoAction, engine.ReferentialRestrict:
		return true
	case engine.ReferentialCascade, engine.ReferentialSetNull, engine.ReferentialSetDefault:
	}
	return false
}
