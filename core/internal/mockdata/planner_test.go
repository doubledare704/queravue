package mockdata

import (
	"testing"

	"github.com/doubledare704/queravue/core/internal/engine"
)

func TestPlanTablesTopologicalOrder(t *testing.T) {
	orgs := TargetRef{Database: "app", Schema: "public", Name: "orgs"}
	users := TargetRef{Database: "app", Schema: "public", Name: "users"}
	orders := TargetRef{Database: "app", Schema: "public", Name: "orders"}
	items := TargetRef{Database: "app", Schema: "public", Name: "order_items"}

	// Pass child-first input order to verify topological sort puts parents first.
	targets := []TargetRef{items, orders, users, orgs}
	rels := []TableRelationInfo{
		{Child: users, Parent: orgs, FK: engine.ForeignKeyDef{Name: "fk_user_org"}},
		{Child: orders, Parent: users, FK: engine.ForeignKeyDef{Name: "fk_order_user"}},
		{Child: items, Parent: orders, FK: engine.ForeignKeyDef{Name: "fk_item_order"}},
	}

	ordered, cycles := PlanTables(targets, rels)
	if len(cycles) != 0 {
		t.Fatalf("unexpected cycles: %+v", cycles)
	}
	want := []string{"orgs", "users", "orders", "order_items"}
	for i, w := range want {
		if ordered[i].Name != w {
			t.Fatalf("ordered[%d]=%s, want %s (full=%v)", i, ordered[i].Name, w, ordered)
		}
	}
}

func TestPlanTablesCycleReportsEdgesAndNullability(t *testing.T) {
	a := TargetRef{Database: "app", Schema: "public", Name: "a"}
	b := TargetRef{Database: "app", Schema: "public", Name: "b"}

	rels := []TableRelationInfo{
		{Child: a, Parent: b, FK: engine.ForeignKeyDef{Name: "fk_a_b"}, Nullable: true},
		{Child: b, Parent: a, FK: engine.ForeignKeyDef{Name: "fk_b_a"}, Nullable: false},
	}

	_, cycles := PlanTables([]TargetRef{a, b}, rels)
	if len(cycles) != 1 {
		t.Fatalf("cycles = %d, want 1", len(cycles))
	}
	if len(cycles[0].Edges) != 2 {
		t.Fatalf("edges = %d, want 2: %+v", len(cycles[0].Edges), cycles[0].Edges)
	}

	nullableByName := map[string]bool{}
	for _, e := range cycles[0].Edges {
		nullableByName[e.ConstraintName] = e.Nullable
	}
	if !nullableByName["fk_a_b"] || nullableByName["fk_b_a"] {
		t.Fatalf("unexpected nullability on cycle edges: %+v", cycles[0].Edges)
	}
}

func TestPlanTablesSelfCycleAndSpecCycleBreaking(t *testing.T) {
	emp := TargetRef{Database: "app", Schema: "public", Name: "employees"}
	rels := []TableRelationInfo{
		{Child: emp, Parent: emp, FK: engine.ForeignKeyDef{Name: "fk_manager"}, Nullable: true},
	}
	_, cycles := PlanTables([]TargetRef{emp}, rels)
	if len(cycles) != 1 || len(cycles[0].Edges) != 1 || cycles[0].Edges[0].ConstraintName != "fk_manager" {
		t.Fatalf("self cycle = %+v", cycles)
	}

	// Setting null_ratio = 1.0 breaks the runtime cycle.
	spec := Spec{
		Seed: 1,
		Targets: []TargetSpec{
			{
				Target: emp,
				Rows:   10,
				Rules: []ColumnRule{
					{ColumnOrPath: "id", Kind: RuleSequence, Sequence: SequenceRule{Start: 1, Step: 1}},
					{
						ColumnOrPath: "manager_id",
						NullRatio:    1.0,
						Kind:         RuleForeignKey,
						ForeignKey:   ForeignKeyRule{Parent: emp, ParentColumn: "id"},
					},
				},
			},
		},
	}
	if got := CheckSpecCycles(spec); len(got) != 0 {
		t.Fatalf("expected null_ratio=1.0 to break cycle, got %+v", got)
	}
}
