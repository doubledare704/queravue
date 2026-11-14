package duckdb

import (
	"context"
	"database/sql/driver"

	"github.com/duckdb/duckdb-go/v2/mapping"
)

// StreamContext keeps the query interruptible while consume reads its rows; the callback must not reuse the connection or close the rows.
func (s *Stmt) StreamContext(ctx context.Context, args []driver.NamedValue, consume func(driver.Rows) error) error {
	defer s.conn.setContext(ctx)()
	return runWithCtxInterrupt(ctx, s.conn.conn, func(wctx context.Context) error {
		res, err := s.execute(wctx, args, mapping.PendingPreparedStreaming)
		if err != nil {
			return err
		}
		s.rows = true
		rows := newRowsWithStmt(*res, s)
		defer func() { _ = rows.Close() }()
		return consume(rows)
	})
}
