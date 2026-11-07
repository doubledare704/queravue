package sqlite

import (
	"context"
	"database/sql"
	"fmt"
	"strings"

	"github.com/doubledare704/queravue/core/internal/engine"
)

// tableRebuild gathers what a copy-and-swap rebuild needs. A failed lookup
// becomes a blocker, so a rebuild is never planned from partial facts.
func (c *Conn) tableRebuild(ctx context.Context, target, table string) *engine.TableRebuild {
	master := quoteIdent(target) + ".sqlite_master"
	info := &engine.TableRebuild{}

	var createSQL sql.NullString
	err := c.db.QueryRowContext(ctx, fmt.Sprintf(`SELECT sql FROM %s WHERE type = 'table' AND name = ?`, master), table).Scan(&createSQL)
	if err != nil || !createSQL.Valid {
		info.Blockers = append(info.Blockers, "the table's definition could not be read")
		return info
	}
	info.CreateSQL = createSQL.String

	rows, err := c.db.QueryContext(ctx, fmt.Sprintf(`SELECT type, name, tbl_name, sql FROM %s WHERE sql IS NOT NULL AND type IN ('index', 'trigger', 'view')`, master))
	if err != nil {
		info.Blockers = append(info.Blockers, "the schema could not be read")
		return info
	}
	defer func() { _ = rows.Close() }()
	needle := strings.ToLower(table)
	for rows.Next() {
		var kind, name, owner, text string
		if err := rows.Scan(&kind, &name, &owner, &text); err != nil {
			info.Blockers = append(info.Blockers, "the schema could not be read")
			return info
		}
		switch {
		case owner == table && (kind == "index" || kind == "trigger"):
			info.DependentSQL = append(info.DependentSQL, text)
		case owner != table && (kind == "view" || kind == "trigger") && strings.Contains(strings.ToLower(text), needle):
			info.Blockers = append(info.Blockers, fmt.Sprintf("%s %q refers to the table", kind, name))
		}
	}
	if err := rows.Err(); err != nil {
		info.Blockers = append(info.Blockers, "the schema could not be read")
		return info
	}

	var enforced int
	if c.db.QueryRowContext(ctx, `PRAGMA foreign_keys;`).Scan(&enforced) == nil && enforced == 1 {
		info.Blockers = append(info.Blockers, "foreign keys are enforced on this connection (run PRAGMA foreign_keys=OFF first)")
	}
	return info
}
