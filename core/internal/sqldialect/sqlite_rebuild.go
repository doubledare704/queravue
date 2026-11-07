package sqldialect

import (
	"errors"
	"fmt"
	"strings"
)

// rebuildSQLite alters columns the only way SQLite allows: the table's own
// CREATE TABLE text is rewritten for the altered columns, the rows are copied
// into it, and it replaces the old table. See ADR 0014.
func (b *ddlBuilder) rebuildSQLite(alters []AlterColumn) error {
	if b.current == nil || b.current.Rebuild == nil {
		return unsupported("SQLite cannot alter a column in place, and the table's definition is not available to rebuild it")
	}
	rebuild := b.current.Rebuild
	if len(rebuild.Blockers) > 0 {
		return unsupported("SQLite cannot alter a column in place and the table cannot be rebuilt safely: %s", strings.Join(rebuild.Blockers, "; "))
	}
	_, items, tail, err := splitCreateTable(rebuild.CreateSQL)
	if err != nil {
		return unsupported("the table's definition cannot be rewritten: %v", err)
	}

	typeChanged := false
	var altered []string
	for _, a := range alters {
		if a.Before.Identity != a.After.Identity {
			return unsupported("changing whether a column is auto-generated is not supported")
		}
		changed := !sameType(a.Before.TypeName, a.After.TypeName) || a.Before.Nullable != a.After.Nullable ||
			!sameOptional(a.Before.Default, a.After.Default) || !sameOptional(a.Before.Collation, a.After.Collation)
		if !changed {
			return errors.New("alter column " + a.After.Name + ": nothing differs")
		}
		typeChanged = typeChanged || !sameType(a.Before.TypeName, a.After.TypeName)
		at := columnItem(items, a.After.Name)
		if at < 0 {
			return fmt.Errorf("column %q not found in the table definition", a.After.Name)
		}
		if items[at], err = rewriteColumnItem(items[at], a); err != nil {
			return err
		}
		altered = append(altered, a.After.Name)
	}

	temp := "qv_rebuild_" + b.target.Table
	columns := make([]string, len(b.current.Columns))
	for i, c := range b.current.Columns {
		columns[i] = b.q(c.Name)
	}
	list := strings.Join(columns, ", ")
	old := b.table()
	created := b.d.QualifyTable(b.target.Schema, temp)
	definition := "CREATE TABLE " + created + " (\n  " + strings.Join(items, ",\n  ") + "\n)" + tail
	b.emit(definition, "Create the rebuilt table", typeChanged)
	b.emit("INSERT INTO "+created+" ("+list+") SELECT "+list+" FROM "+old, "Copy the rows", typeChanged)
	b.emit("DROP TABLE "+old, "Drop the old table", typeChanged)
	b.emit("ALTER TABLE "+created+" RENAME TO "+b.q(b.target.Table), "Swap in the rebuilt table (altering "+strings.Join(altered, ", ")+")", typeChanged)
	for _, dependent := range rebuild.DependentSQL {
		b.emit(dependent, "Recreate an index or trigger", false)
	}
	b.warn("SQLite rebuilds the table to alter a column: every row is copied into a new table, which is slow and holds a write lock on a large table.")
	return nil
}

// splitCreateTable cuts CREATE TABLE text into what precedes the column
// list, its top-level items, and what follows the closing parenthesis.
func splitCreateTable(sql string) (head string, items []string, tail string, err error) {
	open := -1
	depth := 0
	start := 0
	for i := 0; i < len(sql); i++ {
		switch ch := sql[i]; ch {
		case '\'', '"', '`', '[':
			end, qerr := skipQuoted(sql, i)
			if qerr != nil {
				return "", nil, "", qerr
			}
			i = end
		case '-', '/':
			if i+1 < len(sql) && (sql[i+1] == ch && ch == '-' || ch == '/' && sql[i+1] == '*') {
				return "", nil, "", errors.New("it contains a comment")
			}
		case '(':
			if depth == 0 {
				open = i
				start = i + 1
			}
			depth++
		case ')':
			depth--
			if depth == 0 {
				items = append(items, strings.TrimSpace(sql[start:i]))
				fields := strings.Fields(strings.ToUpper(sql[:open]))
				if len(fields) < 3 || fields[0] != "CREATE" || fields[1] != "TABLE" {
					return "", nil, "", errors.New("it is not a plain CREATE TABLE")
				}
				return sql[:open], items, sql[i+1:], nil
			}
		case ',':
			if depth == 1 {
				items = append(items, strings.TrimSpace(sql[start:i]))
				start = i + 1
			}
		}
	}
	return "", nil, "", errors.New("the column list is not closed")
}

func skipQuoted(s string, at int) (int, error) {
	closer := map[byte]byte{'\'': '\'', '"': '"', '`': '`', '[': ']'}[s[at]]
	for i := at + 1; i < len(s); i++ {
		if s[i] != closer {
			continue
		}
		if closer != ']' && i+1 < len(s) && s[i+1] == closer {
			i++
			continue
		}
		return i, nil
	}
	return 0, errors.New("a quoted name or string is not closed")
}

// tokenize splits a column item into words, quoted names and strings, and
// whole parenthesised groups.
func tokenize(s string) ([]string, error) {
	var tokens []string
	for i := 0; i < len(s); {
		switch s[i] {
		case ' ', '\t', '\n', '\r':
			i++
		case '\'', '"', '`', '[':
			end, err := skipQuoted(s, i)
			if err != nil {
				return nil, err
			}
			tokens = append(tokens, s[i:end+1])
			i = end + 1
		case '(':
			depth, j := 0, i
			for ; j < len(s); j++ {
				switch s[j] {
				case '\'', '"', '`', '[':
					end, err := skipQuoted(s, j)
					if err != nil {
						return nil, err
					}
					j = end
				case '(':
					depth++
				case ')':
					depth--
				}
				if depth == 0 {
					break
				}
			}
			if depth != 0 {
				return nil, errors.New("a parenthesis is not closed")
			}
			tokens = append(tokens, s[i:j+1])
			i = j + 1
		default:
			j := i
			for j < len(s) && !strings.ContainsRune(" \t\n\r('\"`[", rune(s[j])) {
				j++
			}
			tokens = append(tokens, s[i:j])
			i = j
		}
	}
	return tokens, nil
}

func unquoteName(token string) string {
	if len(token) >= 2 {
		switch token[0] {
		case '"', '`':
			return strings.ReplaceAll(token[1:len(token)-1], string(token[0])+string(token[0]), string(token[0]))
		case '[':
			return token[1 : len(token)-1]
		}
	}
	return token
}

var tableConstraintKeywords = map[string]bool{"CONSTRAINT": true, "PRIMARY": true, "UNIQUE": true, "CHECK": true, "FOREIGN": true}

func columnItem(items []string, name string) int {
	for i, item := range items {
		tokens, err := tokenize(item)
		if err != nil || len(tokens) == 0 || tableConstraintKeywords[strings.ToUpper(tokens[0])] {
			continue
		}
		if strings.EqualFold(unquoteName(tokens[0]), name) {
			return i
		}
	}
	return -1
}

var columnConstraintKeywords = map[string]bool{
	"CONSTRAINT": true, "PRIMARY": true, "NOT": true, "NULL": true, "UNIQUE": true, "CHECK": true,
	"DEFAULT": true, "COLLATE": true, "REFERENCES": true, "GENERATED": true, "AS": true,
}

// rewriteColumnItem gives the column its wanted type, nullability, default
// and collation while keeping every other constraint as written.
func rewriteColumnItem(item string, a AlterColumn) (string, error) {
	tokens, err := tokenize(item)
	if err != nil {
		return "", err
	}
	rest := tokens[1:]
	typeEnd := 0
	for typeEnd < len(rest) && !columnConstraintKeywords[strings.ToUpper(rest[typeEnd])] {
		typeEnd++
	}
	collationChanged := !sameOptional(a.Before.Collation, a.After.Collation)

	var kept []string
	for i := typeEnd; i < len(rest); i++ {
		switch word := strings.ToUpper(rest[i]); word {
		case "CONSTRAINT", "GENERATED", "AS":
			return "", unsupported("column %q has a named constraint or is generated; its definition cannot be rewritten safely", a.After.Name)
		case "NOT":
			if i+1 >= len(rest) || !strings.EqualFold(rest[i+1], "NULL") {
				kept = append(kept, rest[i])
				continue
			}
			i++
			if i+1 < len(rest) && strings.EqualFold(rest[i+1], "ON") {
				return "", unsupported("column %q has a conflict clause on NOT NULL", a.After.Name)
			}
		case "NULL":
		case "DEFAULT":
			if i+1 >= len(rest) {
				return "", errors.New("DEFAULT has no value")
			}
			i++
		case "COLLATE":
			if !collationChanged {
				kept = append(kept, rest[i])
				if i+1 < len(rest) {
					i++
					kept = append(kept, rest[i])
				}
				continue
			}
			i++
		default:
			kept = append(kept, rest[i])
		}
	}

	out := tokens[0] + " " + a.After.TypeName
	if collationChanged && a.After.Collation != nil && *a.After.Collation != "" {
		if !simpleName.MatchString(*a.After.Collation) {
			return "", fmt.Errorf("invalid collation name %q", *a.After.Collation)
		}
		out += " COLLATE " + *a.After.Collation
	}
	if len(kept) > 0 {
		out += " " + strings.Join(kept, " ")
	}
	if !a.After.Nullable {
		out += " NOT NULL"
	}
	if a.After.Default != nil {
		out += " DEFAULT " + *a.After.Default
	}
	return out, nil
}
