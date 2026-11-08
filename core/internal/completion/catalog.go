// Package completion answers schema-aware SQL completion requests from an
// in-memory catalog that is warmed in the background (ADR 0015).
package completion

import (
	"slices"
	"strings"
)

// State says how much of the catalog is loaded.
type State int

// Catalog states.
const (
	StateCold State = iota
	StateWarming
	StateReady
)

// Column is one column of a Table.
type Column struct {
	Name string
	Type string
}

// Table is a table or view with the columns known so far.
type Table struct {
	Schema  string
	Name    string
	View    bool
	Columns []Column
}

// Snapshot is an immutable view of a catalog. Methods are safe for concurrent
// use, and a nil *Snapshot behaves as an empty cold catalog.
type Snapshot struct {
	state    State
	tables   []*Table
	schemas  []string
	byName   map[string][]*Table
	bySchema map[string][]*Table
}

// State reports how complete the snapshot is.
func (s *Snapshot) State() State {
	if s == nil {
		return StateCold
	}
	return s.state
}

// Tables returns every table and view.
func (s *Snapshot) Tables() []*Table {
	if s == nil {
		return nil
	}
	return s.tables
}

// Schemas returns the schema names.
func (s *Snapshot) Schemas() []string {
	if s == nil {
		return nil
	}
	return s.schemas
}

// TablesIn returns the tables of a schema, matched case-insensitively.
func (s *Snapshot) TablesIn(schema string) []*Table {
	if s == nil {
		return nil
	}
	return s.bySchema[strings.ToLower(schema)]
}

// Lookup returns the tables called name, matched case-insensitively. When
// schema is not empty only that schema's table is returned.
func (s *Snapshot) Lookup(schema, name string) []*Table {
	if s == nil {
		return nil
	}
	all := s.byName[strings.ToLower(name)]
	if schema == "" {
		return all
	}
	var out []*Table
	for _, t := range all {
		if strings.EqualFold(t.Schema, schema) {
			out = append(out, t)
		}
	}
	return out
}

// HasSchema reports whether the catalog has a schema called name.
func (s *Snapshot) HasSchema(name string) bool {
	if s == nil {
		return false
	}
	_, ok := s.bySchema[strings.ToLower(name)]
	return ok
}

var preferredDefaultSchemas = []string{"public", "dbo", "main"}

// DefaultSchema picks the schema unqualified names refer to: requested if it
// exists, else a conventional default, else the only schema.
func (s *Snapshot) DefaultSchema(requested string) string {
	if s == nil {
		return requested
	}
	if requested != "" && s.HasSchema(requested) {
		for _, name := range s.schemas {
			if strings.EqualFold(name, requested) {
				return name
			}
		}
	}
	for _, want := range preferredDefaultSchemas {
		for _, name := range s.schemas {
			if strings.EqualFold(name, want) {
				return name
			}
		}
	}
	if len(s.schemas) == 1 {
		return s.schemas[0]
	}
	return ""
}

func newSnapshot(state State, schemas []string, tables []*Table) *Snapshot {
	s := &Snapshot{
		state:    state,
		schemas:  slices.Clone(schemas),
		tables:   tables,
		byName:   make(map[string][]*Table, len(tables)),
		bySchema: make(map[string][]*Table, len(schemas)),
	}
	for _, name := range schemas {
		s.bySchema[strings.ToLower(name)] = nil
	}
	for _, t := range tables {
		name := strings.ToLower(t.Name)
		s.byName[name] = append(s.byName[name], t)
		key := strings.ToLower(t.Schema)
		s.bySchema[key] = append(s.bySchema[key], t)
	}
	return s
}

// NewSnapshot builds a ready snapshot, for callers that already hold the
// whole catalog (tests and benchmarks).
func NewSnapshot(schemas []string, tables []*Table) *Snapshot {
	return newSnapshot(StateReady, schemas, tables)
}
