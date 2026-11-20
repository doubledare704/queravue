package mongosql

import (
	"fmt"
	"slices"
	"strings"

	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
)

type tableScope struct {
	qualifiers []string
	as         string
}

type resolvedField struct {
	table int
	local string
}

func newTranslator(st *statement) (*translator, *queravuev1.QueryBuilderError) {
	refs := append([]tableRef{st.from}, joinTables(st.joins)...)
	effective := make([]string, len(refs))
	for i, ref := range refs {
		effective[i] = ref.alias
		if effective[i] == "" {
			effective[i] = ref.name
		}
		if j := slices.Index(effective[:i], effective[i]); j >= 0 {
			return nil, parseError(fmt.Sprintf("%q names two tables in this query; give one an alias", effective[i]), ref.offset)
		}
	}
	t := &translator{st: st}
	for i, ref := range refs {
		scope := tableScope{qualifiers: []string{effective[i]}}
		if i > 0 {
			scope.as = effective[i]
			if strings.Contains(scope.as, ".") || strings.HasPrefix(scope.as, "$") {
				return nil, unsupportedError(fmt.Sprintf("join alias %q cannot contain '.' or start with '$'", scope.as), ref.offset)
			}
		}
		if ref.name != effective[i] && !slices.Contains(effective, ref.name) {
			scope.qualifiers = append(scope.qualifiers, ref.name)
		}
		t.tables = append(t.tables, scope)
	}
	return t, nil
}

func joinTables(joins []join) []tableRef {
	refs := make([]tableRef, len(joins))
	for i, j := range joins {
		refs[i] = j.table
	}
	return refs
}

func (t *translator) qualifierTable(qualifier string) (int, bool) {
	for i, scope := range t.tables {
		if slices.Contains(scope.qualifiers, qualifier) {
			return i, true
		}
	}
	return 0, false
}

func (t *translator) resolve(ref fieldRef) (resolvedField, *queravuev1.QueryBuilderError) {
	parts, table := ref.parts, 0
	for k := len(parts) - 1; k >= 1; k-- {
		if index, ok := t.qualifierTable(strings.Join(parts[:k], ".")); ok {
			parts, table = parts[k:], index
			break
		}
	}
	path := strings.Join(parts, ".")
	for _, segment := range strings.Split(path, ".") {
		if segment == "" {
			return resolvedField{}, parseError(fmt.Sprintf("field path %q has an empty segment", path), ref.offset)
		}
		if strings.HasPrefix(segment, "$") {
			return resolvedField{}, unsupportedError(fmt.Sprintf("field names starting with $ are not supported (%q)", path), ref.offset)
		}
	}
	return resolvedField{table: table, local: path}, nil
}

func (t *translator) mergedPath(field resolvedField) string {
	if field.table == 0 {
		return field.local
	}
	return t.tables[field.table].as + "." + field.local
}

func (t *translator) fieldPath(ref fieldRef) (string, *queravuev1.QueryBuilderError) {
	field, err := t.resolve(ref)
	if err != nil {
		return "", err
	}
	return t.mergedPath(field), nil
}

// refPath is the path of a field in the documents the current stage sees:
// after $group that is the group key under _id.
func (t *translator) refPath(ref fieldRef) (string, *queravuev1.QueryBuilderError) {
	merged, err := t.fieldPath(ref)
	if err != nil || !t.postGroup {
		return merged, err
	}
	key, ok := t.group.keyFor(merged)
	if !ok {
		return "", unsupportedError(fmt.Sprintf("%q must appear in GROUP BY or inside an aggregate function", merged), ref.offset)
	}
	return "_id." + key.name, nil
}
