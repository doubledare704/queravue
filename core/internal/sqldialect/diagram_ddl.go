package sqldialect

import (
	"errors"
	"fmt"
	"slices"
	"strings"

	"github.com/doubledare704/queravue/core/internal/engine"
)

// TableChanges is the ordered list of changes to one table of a diagram.
type TableChanges struct {
	Target  Target
	Current *engine.TableDetails
	Changes []Change
}

type tablePhases struct {
	table       TableChanges
	creates     bool
	main        []Change
	foreignKeys []Change
}

// BuildDiagramDDL turns changes to several tables into one script: created
// tables first, then the other changes, then foreign keys, so references to
// tables of the same script and cycles work (ADR 0017 §6).
func BuildDiagramDDL(d Dialect, tables []TableChanges) (Script, error) {
	if len(tables) == 0 {
		return Script{}, errors.New("no changes to apply")
	}
	if err := checkDistinctTables(tables); err != nil {
		return Script{}, err
	}
	// SQLite and DuckDB cannot add a foreign key to an existing table, so references stay inside CREATE TABLE.
	deferForeignKeys := d.ID() != "sqlite" && d.ID() != "duckdb"
	phases := make([]tablePhases, len(tables))
	for i, t := range tables {
		phases[i] = splitForeignKeys(t, deferForeignKeys)
	}
	if !deferForeignKeys {
		phases = referencedFirst(phases)
	}
	slices.SortStableFunc(phases, func(a, b tablePhases) int {
		switch {
		case a.creates == b.creates:
			return 0
		case a.creates:
			return -1
		}
		return 1
	})

	out := Script{Transactional: true}
	add := func(t TableChanges, changes []Change) error {
		if len(changes) == 0 {
			return nil
		}
		script, err := BuildDDL(d, t.Target, t.Current, changes)
		if err != nil {
			var u *UnsupportedError
			if errors.As(err, &u) {
				return &UnsupportedError{Reason: t.Target.Table + ": " + u.Reason}
			}
			return fmt.Errorf("%s: %w", t.Target.Table, err)
		}
		for _, st := range script.Statements {
			if !slices.Contains(strings.Fields(st.Summary), t.Target.Table) {
				st.Summary += " on " + t.Target.Table
			}
			out.Statements = append(out.Statements, st)
		}
		for _, w := range script.Warnings {
			if !slices.Contains(out.Warnings, w) {
				out.Warnings = append(out.Warnings, w)
			}
		}
		out.Transactional = out.Transactional && script.Transactional
		return nil
	}
	for _, p := range phases {
		if err := add(p.table, p.main); err != nil {
			return Script{}, err
		}
	}
	for _, p := range phases {
		if err := add(p.table, p.foreignKeys); err != nil {
			return Script{}, err
		}
	}
	if len(out.Statements) == 0 {
		return Script{}, errors.New("no changes to apply")
	}
	return out, nil
}

func checkDistinctTables(tables []TableChanges) error {
	seen := map[Target]bool{}
	for _, t := range tables {
		if t.Target.Table == "" {
			return errors.New("every table needs a name")
		}
		if len(t.Changes) == 0 {
			return fmt.Errorf("%s: no changes", t.Target.Table)
		}
		if seen[t.Target] {
			return fmt.Errorf("%s: listed more than once; put all its changes in one entry", t.Target.Table)
		}
		seen[t.Target] = true
	}
	return nil
}

func splitForeignKeys(t TableChanges, deferForeignKeys bool) tablePhases {
	p := tablePhases{table: t}
	if len(t.Changes) > 0 {
		_, p.creates = t.Changes[0].(CreateTable)
	}
	if !deferForeignKeys {
		p.main = t.Changes
		return p
	}
	for _, ch := range t.Changes {
		switch c := ch.(type) {
		case CreateTable:
			design := c.Design
			for _, fk := range design.ForeignKeys {
				p.foreignKeys = append(p.foreignKeys, AddForeignKey{ForeignKey: fk})
			}
			design.ForeignKeys = nil
			p.main = append(p.main, CreateTable{Design: design})
		case AddForeignKey:
			p.foreignKeys = append(p.foreignKeys, c)
		default:
			p.main = append(p.main, ch)
		}
	}
	return p
}

// referencedFirst orders created tables so a table follows the tables it
// references, keeping the given order otherwise; cycles keep their order.
func referencedFirst(phases []tablePhases) []tablePhases {
	index := map[string]int{}
	for i, p := range phases {
		if p.creates {
			index[p.table.Target.Table] = i
		}
	}
	out := make([]tablePhases, 0, len(phases))
	state := make([]int, len(phases))
	const visiting, visited = 1, 2
	var visit func(i int)
	visit = func(i int) {
		if state[i] != 0 {
			return
		}
		state[i] = visiting
		for _, ref := range referencedTables(phases[i]) {
			if j, ok := index[ref]; ok && j != i {
				visit(j)
			}
		}
		state[i] = visited
		out = append(out, phases[i])
	}
	for i := range phases {
		visit(i)
	}
	return out
}

func referencedTables(p tablePhases) []string {
	var refs []string
	for _, ch := range p.main {
		switch c := ch.(type) {
		case CreateTable:
			for _, fk := range c.Design.ForeignKeys {
				refs = append(refs, fk.RefTable)
			}
		case AddForeignKey:
			refs = append(refs, c.ForeignKey.RefTable)
		}
	}
	return refs
}
