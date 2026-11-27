package mockdata

import (
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
)

func TestSuggestTableRulesHeuristics(t *testing.T) {
	now := time.Date(2026, 6, 1, 12, 0, 0, 0, time.UTC)
	defVal := "now()"
	td := engine.TableDetails{
		Database: "app",
		Schema:   "public",
		Table:    "users",
		Columns: []engine.ColumnDef{
			{Name: "id", TypeName: "serial", Kind: engine.VInt, IsPrimaryKey: true, Identity: true},
			{Name: "org_id", TypeName: "int4", Kind: engine.VInt},
			{Name: "email", TypeName: "text", Kind: engine.VText},
			{Name: "full_name", TypeName: "text", Kind: engine.VText},
			{Name: "phone", TypeName: "text", Kind: engine.VText},
			{Name: "city", TypeName: "text", Kind: engine.VText},
			{Name: "country", TypeName: "text", Kind: engine.VText},
			{Name: "website", TypeName: "text", Kind: engine.VText},
			{Name: "created_at", TypeName: "timestamptz", Kind: engine.VTimestamptz, DefaultValue: &defVal},
			{Name: "updated_at", TypeName: "timestamptz", Kind: engine.VTimestamptz},
			{Name: "birth_date", TypeName: "date", Kind: engine.VTimestamptz},
			{Name: "active", TypeName: "bool", Kind: engine.VBool},
			{Name: "balance", TypeName: "numeric", Kind: engine.VDecimal},
			{Name: "external_id", TypeName: "uuid", Kind: engine.VUUID},
			{Name: "meta", TypeName: "jsonb", Kind: engine.VJSON},
			{Name: "avatar", TypeName: "bytea", Kind: engine.VBytes},
		},
		ForeignKeys: []engine.ForeignKeyDef{
			{Name: "fk_org", Columns: []string{"org_id"}, ReferencedTable: "orgs", ReferencedColumns: []string{"id"}},
		},
		Indexes: []engine.IndexDef{
			{Name: "users_email_idx", Columns: []string{"email"}, IsUnique: true},
		},
	}

	selected := map[string]bool{
		TableKey("app", "public", "users"): true,
		TableKey("app", "public", "orgs"):  true,
	}
	// Users.id is referenced by a child table in the same run, so it uses sequence instead of skip.
	refCols := map[string]bool{"id": true}

	rules, warnings := SuggestTableRules(td, nil, selected, refCols, now)
	byName := map[string]ColumnRule{}
	for _, r := range rules {
		byName[r.ColumnOrPath] = r
	}

	if r := byName["id"]; r.Kind != RuleSequence || !r.Unique {
		t.Fatalf("referenced identity id = %+v, want unique sequence", r)
	}
	if r := byName["org_id"]; r.Kind != RuleForeignKey || r.ForeignKey.FromExistingRows || r.ForeignKey.Parent.Name != "orgs" {
		t.Fatalf("org_id = %+v, want FK from current run", r)
	}
	if r := byName["email"]; r.Kind != RuleFaker || r.FakerKind != "email" || !r.Unique {
		t.Fatalf("email = %+v, want unique email faker", r)
	}
	if r := byName["full_name"]; r.Kind != RuleFaker || r.FakerKind != "name" {
		t.Fatalf("full_name = %+v", r)
	}
	if r := byName["phone"]; r.FakerKind != "phone" {
		t.Fatalf("phone = %+v", r)
	}
	if r := byName["city"]; r.FakerKind != "city" {
		t.Fatalf("city = %+v", r)
	}
	if r := byName["country"]; r.FakerKind != "country" {
		t.Fatalf("country = %+v", r)
	}
	if r := byName["website"]; r.FakerKind != "url" {
		t.Fatalf("website = %+v", r)
	}
	if r := byName["created_at"]; r.Kind != RuleSkip {
		t.Fatalf("created_at with default = %+v, want skip", r)
	}
	if r := byName["updated_at"]; r.Kind != RuleTimeRange || r.TimeRange.DateOnly {
		t.Fatalf("updated_at = %+v, want timestamp range", r)
	}
	if r := byName["birth_date"]; r.Kind != RuleTimeRange || !r.TimeRange.DateOnly {
		t.Fatalf("birth_date = %+v, want date_only range", r)
	}
	if r := byName["active"]; r.FakerKind != "bool" {
		t.Fatalf("active = %+v", r)
	}
	if r := byName["balance"]; r.Kind != RuleDecimalRange {
		t.Fatalf("balance = %+v", r)
	}
	if r := byName["external_id"]; r.FakerKind != "uuid" {
		t.Fatalf("external_id = %+v", r)
	}
	if r := byName["meta"]; r.FakerKind != "json_object" {
		t.Fatalf("meta = %+v", r)
	}
	if r := byName["avatar"]; r.Kind != RuleSkip {
		t.Fatalf("avatar bytea = %+v, want skip", r)
	}
	if len(warnings) != 1 {
		t.Fatalf("warnings = %v, want 1 warning for bytea", warnings)
	}
}

func TestSuggestCollectionRulesNestedAndArrays(t *testing.T) {
	now := time.Date(2026, 6, 1, 12, 0, 0, 0, time.UTC)
	sample := engine.FieldPathSample{
		Sampled: 10,
		Paths: []engine.FieldPathStat{
			{Path: "_id", Frequency: 1, Types: []engine.FieldType{{Type: "objectId", Count: 10}}},
			{Path: "email", Frequency: 1, Types: []engine.FieldType{{Type: "string", Count: 10}}},
			{Path: "address", Frequency: 0.8, Types: []engine.FieldType{{Type: "object", Count: 8}}},
			{Path: "address.city", Frequency: 0.8, Types: []engine.FieldType{{Type: "string", Count: 8}}},
			{Path: "tags", Frequency: 1, Types: []engine.FieldType{{Type: "array", Count: 10}}},
			{Path: "tags.[]", Frequency: 1, Types: []engine.FieldType{{Type: "string", Count: 20}}},
			{Path: "items", Frequency: 1, Types: []engine.FieldType{{Type: "array", Count: 10}}},
			{Path: "items.[]", Frequency: 1, Types: []engine.FieldType{{Type: "object", Count: 15}}},
			{Path: "items.[].qty", Frequency: 1, Types: []engine.FieldType{{Type: "int", Count: 15}}},
		},
	}

	rules, warnings := SuggestCollectionRules(sample, now)
	if len(warnings) != 0 {
		t.Fatalf("unexpected warnings: %v", warnings)
	}
	byName := map[string]ColumnRule{}
	for _, r := range rules {
		byName[r.ColumnOrPath] = r
	}
	if _, hasID := byName["_id"]; hasID {
		t.Fatal("_id should not appear in suggested collection rules")
	}
	if byName["email"].FakerKind != "email" {
		t.Fatalf("email = %+v", byName["email"])
	}
	addr := byName["address"]
	if addr.Kind != RuleDocument || addr.NullRatio != 0.2 || len(addr.Document.Fields) != 1 || addr.Document.Fields[0].FakerKind != "city" {
		t.Fatalf("address = %+v", addr)
	}
	tags := byName["tags"]
	if tags.Kind != RuleArray || tags.Array.Element == nil || tags.Array.Element.FakerKind != "word" {
		t.Fatalf("tags = %+v", tags)
	}
	items := byName["items"]
	if items.Kind != RuleArray || items.Array.Element == nil || items.Array.Element.Kind != RuleDocument ||
		len(items.Array.Element.Document.Fields) != 1 || items.Array.Element.Document.Fields[0].Kind != RuleIntRange {
		t.Fatalf("items = %+v", items)
	}
}
