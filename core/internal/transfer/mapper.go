package transfer

import (
	"fmt"
	"slices"
	"strings"

	"github.com/doubledare704/queravue/core/internal/engine"
)

// Mapping sends one file column to one target column.
type Mapping struct {
	SourceIndex int
	Target      string
}

// Mapper picks and coerces the mapped file columns of a row, in load order.
type Mapper struct {
	sources []int
	kinds   []engine.ValueKind
	names   []string
}

// Columns are the target column names, in the order rows come out.
func (m *Mapper) Columns() []string { return m.names }

// convert maps one record; a failure names the column and never quotes the value.
func (m *Mapper) convert(row []engine.Value) ([]engine.Value, *problem) {
	out := make([]engine.Value, len(m.sources))
	for i, src := range m.sources {
		if src >= len(row) {
			return nil, &problem{KindMapping, m.names[i], fmt.Sprintf("the record has no column at position %d", src)}
		}
		v, err := Coerce(row[src], m.kinds[i])
		if err != nil {
			return nil, &problem{KindMapping, m.names[i], "the value does not fit the column type " + kindName(m.kinds[i])}
		}
		out[i] = v
	}
	return out, nil
}

// BuildMapper maps file columns onto target columns. Without mappings the file
// columns go by position into the target's leading columns, or by name when
// the file's column names are keys (JSON, Parquet). Unknown target columns
// (target nil) allow only explicit mappings and no coercion.
func BuildMapper(fileColumns []string, mappings []Mapping, target []engine.ColumnDef, byName bool) (*Mapper, *Error) {
	m, err := buildMapper(fileColumns, mappings, target, byName)
	if err == nil && len(m.names) == 0 {
		return nil, newError(KindMapping, "no file columns are mapped")
	}
	return m, err
}

func buildMapper(fileColumns []string, mappings []Mapping, target []engine.ColumnDef, byName bool) (*Mapper, *Error) {
	m := &Mapper{}
	if len(mappings) == 0 {
		if target == nil {
			return nil, newError(KindMapping, "map the file columns to target columns: the target's columns are unknown")
		}
		if byName {
			for i, name := range fileColumns {
				j := indexOfColumn(target, name)
				if j < 0 {
					return nil, newError(KindMapping, "the target has no column %q; map the file columns by hand", name)
				}
				if slices.Contains(m.names, target[j].Name) {
					return nil, newError(KindMapping, "column %q is mapped twice", target[j].Name)
				}
				m.add(i, target[j].Name, target[j].Kind)
			}
			return m, nil
		}
		if len(fileColumns) > len(target) {
			return nil, newError(KindMapping, "the file has %d columns but the target has %d", len(fileColumns), len(target))
		}
		for i := range fileColumns {
			m.add(i, target[i].Name, target[i].Kind)
		}
		return m, nil
	}
	for _, mp := range mappings {
		if mp.SourceIndex < 0 || mp.SourceIndex >= len(fileColumns) {
			return nil, newError(KindMapping, "mapping for %q uses file column %d, but the file has %d columns", mp.Target, mp.SourceIndex, len(fileColumns))
		}
		name, kind := mp.Target, engine.VNull
		if target != nil {
			i := indexOfColumn(target, mp.Target)
			if i < 0 {
				return nil, newError(KindMapping, "the target has no column %q", mp.Target)
			}
			name, kind = target[i].Name, target[i].Kind
		}
		if slices.Contains(m.names, name) {
			return nil, newError(KindMapping, "column %q is mapped twice", name)
		}
		m.add(mp.SourceIndex, name, kind)
	}
	return m, nil
}

// BuildFieldMapper names document fields: mapped names, or the file's own column names.
func BuildFieldMapper(fileColumns []string, mappings []Mapping) (*Mapper, *Error) {
	m := &Mapper{}
	if len(mappings) == 0 {
		for i, name := range fileColumns {
			m.add(i, name, engine.VNull)
		}
		return m, nil
	}
	for _, mp := range mappings {
		if mp.SourceIndex < 0 || mp.SourceIndex >= len(fileColumns) {
			return nil, newError(KindMapping, "mapping for %q uses file column %d, but the file has %d columns", mp.Target, mp.SourceIndex, len(fileColumns))
		}
		m.add(mp.SourceIndex, mp.Target, engine.VNull)
	}
	return m, nil
}

func (m *Mapper) add(source int, name string, kind engine.ValueKind) {
	m.sources = append(m.sources, source)
	m.names = append(m.names, name)
	m.kinds = append(m.kinds, kind)
}

func indexOfColumn(cols []engine.ColumnDef, name string) int {
	if i := slices.IndexFunc(cols, func(c engine.ColumnDef) bool { return c.Name == name }); i >= 0 {
		return i
	}
	return slices.IndexFunc(cols, func(c engine.ColumnDef) bool { return strings.EqualFold(c.Name, name) })
}

func kindName(k engine.ValueKind) string {
	switch k {
	case engine.VBool:
		return "boolean"
	case engine.VInt:
		return "integer"
	case engine.VFloat:
		return "float"
	case engine.VDecimal:
		return "decimal"
	case engine.VBytes:
		return "binary"
	case engine.VTimestamptz:
		return "timestamp"
	case engine.VJSON:
		return "JSON"
	case engine.VUUID:
		return "UUID"
	}
	return "text"
}
