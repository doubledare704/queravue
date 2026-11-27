package mockdata

import (
	"fmt"
	"math"
	"sort"
	"strings"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
)

// SuggestTableRules proposes per-column rules and notes for a relational table.
func SuggestTableRules(
	td engine.TableDetails,
	extraFKs []engine.ForeignKeyDef,
	selectedTables map[string]bool,
	referencedCols map[string]bool,
	rows uint64,
	now time.Time,
) ([]ColumnRule, []string) {
	if now.IsZero() {
		now = time.Now().UTC()
	}
	fkByCol, compositeFKCols, warnings := collectForeignKeys(td.ForeignKeys, extraFKs)
	uniqueCols := collectSingleColUniques(td)

	rules := make([]ColumnRule, 0, len(td.Columns))

	for _, col := range td.Columns {
		lowerCol := strings.ToLower(col.Name)
		unique := uniqueCols[lowerCol]
		isReferenced := referencedCols[lowerCol]

		if fk, ok := fkByCol[lowerCol]; ok {
			parentSchema := fk.ReferencedSchema
			if parentSchema == "" {
				parentSchema = td.Schema
			}
			parent := TargetRef{
				Database: td.Database,
				Schema:   parentSchema,
				Name:     fk.ReferencedTable,
			}
			rules = append(rules, ColumnRule{
				ColumnOrPath: col.Name,
				Unique:       unique,
				Kind:         RuleForeignKey,
				ForeignKey: ForeignKeyRule{
					Parent:           parent,
					ParentColumn:     fk.ReferencedColumns[0],
					FromExistingRows: !selectedTables[parent.Key()],
				},
			})
			continue
		}

		if compositeFKCols[lowerCol] {
			rules = append(rules, ColumnRule{ColumnOrPath: col.Name, Kind: RuleSkip})
			continue
		}

		isAuto := col.Identity || isSerialType(col.TypeName) || col.DefaultValue != nil
		if isAuto && !isReferenced {
			rules = append(rules, ColumnRule{ColumnOrPath: col.Name, Kind: RuleSkip})
			continue
		}
		if isAuto && isReferenced {
			unique = true
		}

		rule, warn := suggestColumnRule(col, unique, now)
		rules = append(rules, rule)
		if warn != "" {
			warnings = append(warnings, warn)
		}
		if rule.Unique && rule.Kind == RuleFaker {
			if capLimit, ok := fakerUniqueCeiling[rule.FakerKind]; ok && rows > capLimit {
				warnings = append(warnings, fmt.Sprintf("column %q is unique with faker %q (safe ceiling ~%d), which may exhaust for %d rows; consider uuid or pattern", col.Name, rule.FakerKind, capLimit, rows))
			}
		}
	}
	return rules, warnings
}

var fakerUniqueCeiling = map[string]uint64{
	"bool":          2,
	"color":         50,
	"country_code":  50,
	"currency_code": 50,
	"state":         50,
	"city":          500,
	"company":       500,
	"country":       200,
	"first_name":    500,
	"job_title":     500,
	"last_name":     500,
	"product_name":  500,
	"word":          500,
	"email":         50_000,
	"name":          50_000,
	"username":      50_000,
}

func collectForeignKeys(primary, extra []engine.ForeignKeyDef) (map[string]engine.ForeignKeyDef, map[string]bool, []string) {
	single := map[string]engine.ForeignKeyDef{}
	compositeCols := map[string]bool{}
	seenComposite := map[string]bool{}
	var warnings []string

	for _, list := range [][]engine.ForeignKeyDef{primary, extra} {
		for _, fk := range list {
			if len(fk.Columns) == 1 && len(fk.ReferencedColumns) == 1 {
				key := strings.ToLower(fk.Columns[0])
				if _, exists := single[key]; !exists {
					single[key] = fk
				}
				continue
			}
			if len(fk.Columns) > 1 {
				for _, col := range fk.Columns {
					compositeCols[strings.ToLower(col)] = true
				}
				sig := fk.Name + ":" + strings.Join(fk.Columns, ",")
				if !seenComposite[sig] {
					seenComposite[sig] = true
					warnings = append(warnings, fmt.Sprintf("composite foreign key %q (%s) has no default rule and its columns were skipped", fk.Name, strings.Join(fk.Columns, ", ")))
				}
			}
		}
	}
	return single, compositeCols, warnings
}

func collectSingleColUniques(td engine.TableDetails) map[string]bool {
	out := map[string]bool{}
	pkCount := 0
	var pkCol string
	for _, c := range td.Columns {
		if c.IsPrimaryKey {
			pkCount++
			pkCol = strings.ToLower(c.Name)
		}
	}
	if pkCount == 1 {
		out[pkCol] = true
	}
	for _, idx := range td.Indexes {
		if (idx.IsUnique || idx.IsPrimary) && len(idx.Columns) == 1 {
			out[strings.ToLower(idx.Columns[0])] = true
		}
	}
	return out
}

func isSerialType(typeName string) bool {
	t := strings.ToLower(typeName)
	return strings.Contains(t, "serial")
}

func isDateOnlyType(typeName string) bool {
	t := strings.ToLower(strings.TrimSpace(typeName))
	return t == "date"
}

func suggestColumnRule(col engine.ColumnDef, unique bool, now time.Time) (ColumnRule, string) {
	rule := ColumnRule{ColumnOrPath: col.Name, Unique: unique}
	fromMs := now.Add(-DefaultTimeWindow).UnixMilli()
	toMs := now.UnixMilli()

	if timeRule, ok := matchTimeName(col.Name, col.Kind, col.TypeName, fromMs, toMs); ok {
		rule.Kind = RuleTimeRange
		rule.TimeRange = timeRule
		return rule, ""
	}

	if kindAllowsText(col.Kind) {
		if fakerKind, ok := matchTextNameFaker(col.Name); ok {
			rule.Kind = RuleFaker
			rule.FakerKind = fakerKind
			return rule, ""
		}
	}

	switch col.Kind {
	case engine.VBool:
		rule.Kind = RuleFaker
		rule.FakerKind = "bool"
		return rule, ""
	case engine.VInt:
		if unique {
			rule.Kind = RuleSequence
			rule.Sequence = SequenceRule{Start: 1, Step: 1}
			return rule, ""
		}
		rule.Kind = RuleIntRange
		rule.IntRange = intRangeForType(col.TypeName)
		return rule, ""
	case engine.VFloat:
		rule.Kind = RuleFloatRange
		rule.FloatRange = FloatRangeRule{Min: 0, Max: 1000}
		return rule, ""
	case engine.VDecimal:
		rule.Kind = RuleDecimalRange
		rule.DecimalRange = DecimalRangeRule{Min: "0.00", Max: "1000.00", Scale: 2}
		return rule, ""
	case engine.VTimestamptz:
		rule.Kind = RuleTimeRange
		rule.TimeRange = TimeRangeRule{FromMs: fromMs, ToMs: toMs, DateOnly: isDateOnlyType(col.TypeName)}
		return rule, ""
	case engine.VUUID:
		rule.Kind = RuleFaker
		rule.FakerKind = "uuid"
		return rule, ""
	case engine.VJSON:
		rule.Kind = RuleFaker
		rule.FakerKind = "json_object"
		return rule, ""
	case engine.VArray:
		rule.Kind = RuleArray
		rule.Array = ArrayRule{
			MinLength: 1,
			MaxLength: 3,
			Element:   &ColumnRule{Kind: RuleFaker, FakerKind: "word"},
		}
		return rule, ""
	case engine.VText:
		rule.Kind = RuleFaker
		if unique {
			rule.FakerKind = "uuid"
		} else {
			rule.FakerKind = "word"
		}
		return rule, ""
	default:
		rule.Kind = RuleSkip
		return rule, fmt.Sprintf("column %q (%s) has no default rule and was skipped", col.Name, col.TypeName)
	}
}

func kindAllowsText(k engine.ValueKind) bool {
	return k == engine.VText || k == engine.VUUID || k == engine.VNull
}

func intRangeForType(typeName string) IntRangeRule {
	t := strings.ToLower(typeName)
	switch {
	case strings.Contains(t, "tinyint") || strings.Contains(t, "int1"):
		return IntRangeRule{Min: 1, Max: 127}
	case strings.Contains(t, "smallint") || strings.Contains(t, "int2"):
		return IntRangeRule{Min: 1, Max: 32767}
	default:
		return IntRangeRule{Min: 1, Max: 10000}
	}
}

func matchTimeName(name string, kind engine.ValueKind, typeName string, fromMs, toMs int64) (TimeRangeRule, bool) {
	if kind != engine.VTimestamptz && kind != engine.VNull {
		return TimeRangeRule{}, false
	}
	lower := strings.ToLower(name)
	switch {
	case strings.HasSuffix(lower, "_date") || lower == "date" || lower == "birthday" || lower == "dob" || lower == "birth_date":
		return TimeRangeRule{FromMs: fromMs, ToMs: toMs, DateOnly: true}, true
	case strings.HasSuffix(lower, "_at") || strings.HasSuffix(lower, "_time") || lower == "created" || lower == "updated" || lower == "timestamp":
		return TimeRangeRule{FromMs: fromMs, ToMs: toMs, DateOnly: isDateOnlyType(typeName)}, true
	default:
		return TimeRangeRule{}, false
	}
}

func matchTextNameFaker(name string) (string, bool) {
	lower := strings.ToLower(name)
	switch {
	case lower == "uuid" || lower == "guid" || strings.HasSuffix(lower, "_uuid"):
		return "uuid", true
	case lower == "email" || lower == "e_mail" || strings.HasSuffix(lower, "_email"):
		return "email", true
	case lower == "first_name" || lower == "fname" || lower == "given_name":
		return "first_name", true
	case lower == "last_name" || lower == "lname" || lower == "surname" || lower == "family_name":
		return "last_name", true
	case lower == "username" || lower == "user_name" || lower == "handle":
		return "username", true
	case lower == "name" || lower == "full_name" || lower == "display_name":
		return "name", true
	case lower == "phone" || lower == "phone_number" || lower == "mobile" || lower == "tel" || strings.HasSuffix(lower, "_phone"):
		return "phone", true
	case lower == "city" || lower == "town":
		return "city", true
	case lower == "state" || lower == "province" || lower == "region":
		return "state", true
	case lower == "country_code":
		return "country_code", true
	case lower == "country":
		return "country", true
	case lower == "zip" || lower == "zip_code" || lower == "postal_code" || lower == "postcode":
		return "zip", true
	case lower == "street" || lower == "street_address" || lower == "address" || lower == "address_line1":
		return "street", true
	case lower == "company" || lower == "company_name" || lower == "organization" || lower == "org_name":
		return "company", true
	case lower == "url" || lower == "website" || lower == "homepage" || strings.HasSuffix(lower, "_url"):
		return "url", true
	case lower == "domain" || lower == "domain_name" || lower == "host" || lower == "hostname":
		return "domain", true
	case lower == "ipv4" || lower == "ip" || lower == "ip_address":
		return "ipv4", true
	case lower == "ipv6":
		return "ipv6", true
	case lower == "job_title" || lower == "occupation" || lower == "role_title":
		return "job_title", true
	case lower == "currency" || lower == "currency_code":
		return "currency_code", true
	case lower == "color" || lower == "colour":
		return "color", true
	case lower == "product_name" || lower == "product":
		return "product_name", true
	case lower == "description" || lower == "summary" || lower == "bio" || lower == "notes" || lower == "body" || lower == "comment":
		return "paragraph", true
	case lower == "title" || lower == "subject" || lower == "headline":
		return "sentence", true
	case lower == "user_agent":
		return "user_agent", true
	default:
		return "", false
	}
}

type pathTreeNode struct {
	name     string
	stat     *engine.FieldPathStat
	fields   map[string]*pathTreeNode
	elem     *pathTreeNode
	orderIdx int
}

// SuggestCollectionRules builds hierarchical rules from sampled Mongo field paths.
func SuggestCollectionRules(sample engine.FieldPathSample, now time.Time) ([]ColumnRule, []string) {
	if now.IsZero() {
		now = time.Now().UTC()
	}
	if len(sample.Paths) == 0 {
		return nil, []string{"collection has no sampled documents; add rules manually"}
	}

	root := &pathTreeNode{fields: map[string]*pathTreeNode{}}
	for idx, st := range sample.Paths {
		if st.Path == "_id" {
			continue
		}
		segs := strings.Split(st.Path, ".")
		cur := root
		for i, seg := range segs {
			if seg == "" {
				continue
			}
			if seg == "[]" {
				if cur.elem == nil {
					cur.elem = &pathTreeNode{name: "[]", fields: map[string]*pathTreeNode{}, orderIdx: idx}
				}
				cur = cur.elem
			} else {
				ch, ok := cur.fields[seg]
				if !ok {
					ch = &pathTreeNode{name: seg, fields: map[string]*pathTreeNode{}, orderIdx: idx}
					cur.fields[seg] = ch
				}
				cur = ch
			}
			if i == len(segs)-1 {
				stCopy := st
				cur.stat = &stCopy
			}
		}
	}

	var warnings []string
	rules := buildTreeRules(root, now, &warnings)
	return rules, warnings
}

func buildTreeRules(parent *pathTreeNode, now time.Time, warnings *[]string) []ColumnRule {
	children := make([]*pathTreeNode, 0, len(parent.fields))
	for _, ch := range parent.fields {
		children = append(children, ch)
	}
	sort.Slice(children, func(i, j int) bool {
		if children[i].orderIdx != children[j].orderIdx {
			return children[i].orderIdx < children[j].orderIdx
		}
		return children[i].name < children[j].name
	})

	out := make([]ColumnRule, 0, len(children))
	for _, ch := range children {
		rule := buildNodeRule(ch.name, ch, now, warnings)
		out = append(out, rule)
	}
	return out
}

func buildNodeRule(name string, node *pathTreeNode, now time.Time, warnings *[]string) ColumnRule {
	var nullRatio float64
	if node.stat != nil && node.stat.Frequency > 0 && node.stat.Frequency < 1 {
		nullRatio = math.Round((1-node.stat.Frequency)*100) / 100
	}

	if node.elem != nil {
		elemRule := buildNodeRule("", node.elem, now, warnings)
		elemRule.ColumnOrPath = ""
		return ColumnRule{
			ColumnOrPath: name,
			NullRatio:    nullRatio,
			Kind:         RuleArray,
			Array: ArrayRule{
				MinLength: 1,
				MaxLength: 3,
				Element:   &elemRule,
			},
		}
	}

	if len(node.fields) > 0 {
		return ColumnRule{
			ColumnOrPath: name,
			NullRatio:    nullRatio,
			Kind:         RuleDocument,
			Document: DocumentRule{
				Fields: buildTreeRules(node, now, warnings),
			},
		}
	}

	dominant := dominantBSONType(node.stat)
	rule := suggestBSONScalarRule(name, dominant, now, warnings)
	rule.NullRatio = nullRatio
	return rule
}

func dominantBSONType(stat *engine.FieldPathStat) string {
	if stat == nil {
		return "string"
	}
	for _, ft := range stat.Types {
		if ft.Type != "null" && ft.Type != "undefined" {
			return ft.Type
		}
	}
	if len(stat.Types) > 0 {
		return stat.Types[0].Type
	}
	return "string"
}

func suggestBSONScalarRule(name, bsonType string, now time.Time, warnings *[]string) ColumnRule {
	rule := ColumnRule{ColumnOrPath: name}
	fromMs := now.Add(-DefaultTimeWindow).UnixMilli()
	toMs := now.UnixMilli()

	switch bsonType {
	case "objectId":
		rule.Kind = RuleFaker
		rule.FakerKind = "object_id"
	case "bool":
		rule.Kind = RuleFaker
		rule.FakerKind = "bool"
	case "int", "long":
		rule.Kind = RuleIntRange
		rule.IntRange = IntRangeRule{Min: 1, Max: 10000}
	case "double":
		rule.Kind = RuleFloatRange
		rule.FloatRange = FloatRangeRule{Min: 0, Max: 1000}
	case "decimal":
		rule.Kind = RuleDecimalRange
		rule.DecimalRange = DecimalRangeRule{Min: "0.00", Max: "1000.00", Scale: 2}
	case "date", "timestamp":
		if tr, ok := matchTimeName(name, engine.VTimestamptz, bsonType, fromMs, toMs); ok {
			rule.Kind = RuleTimeRange
			rule.TimeRange = tr
		} else {
			rule.Kind = RuleTimeRange
			rule.TimeRange = TimeRangeRule{FromMs: fromMs, ToMs: toMs}
		}
	case "string":
		if tr, ok := matchTimeName(name, engine.VNull, "", fromMs, toMs); ok {
			rule.Kind = RuleTimeRange
			rule.TimeRange = tr
		} else if fk, ok := matchTextNameFaker(name); ok {
			rule.Kind = RuleFaker
			rule.FakerKind = fk
		} else {
			rule.Kind = RuleFaker
			rule.FakerKind = "word"
		}
	case "object":
		rule.Kind = RuleFaker
		rule.FakerKind = "json_object"
	case "array":
		rule.Kind = RuleArray
		rule.Array = ArrayRule{
			MinLength: 1,
			MaxLength: 3,
			Element:   &ColumnRule{Kind: RuleFaker, FakerKind: "word"},
		}
	default:
		rule.Kind = RuleSkip
		if name != "" {
			*warnings = append(*warnings, fmt.Sprintf("field %q (%s) has no default rule and was skipped", name, bsonType))
		}
	}
	return rule
}
