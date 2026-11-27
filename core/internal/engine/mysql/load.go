package mysql

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"regexp"
	"strings"
	"sync"

	drv "github.com/go-sql-driver/mysql"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/sqldialect"
)

var _ engine.RowLoader = (*Conn)(nil)

const (
	maxPlaceholders     = 65535
	maxRowsPerInsert    = 1000
	maxStatementBytes   = 4 << 20
	cachedStatementCap  = 8
	perValueWireBytes   = 9
	perTimestampBytes   = 32
	fallbackMaxPacket   = 4 << 20
	packetBudgetDivisor = 2
)

// LoadRows implements engine.RowLoader with prepared multi-row INSERTs, each
// kept under max_allowed_packet, in one transaction per batch.
func (c *Conn) LoadRows(ctx context.Context, t engine.LoadTarget, columns []string, src engine.RowBatchSource) (engine.LoadStats, error) {
	const op = "load rows"
	if t.Table == "" || len(columns) == 0 {
		return engine.LoadStats{}, engine.Errorf(engine.KindInvalidConfig, c.id, op, "table and columns are required")
	}
	if len(columns) > maxPlaceholders {
		return engine.LoadStats{}, engine.Errorf(engine.KindInvalidConfig, c.id, op, "too many columns")
	}
	session, err := c.loadSession(ctx, op)
	if err != nil {
		return engine.LoadStats{}, err
	}
	defer session.close()
	run := &loadRun{
		c: c, session: session, columns: columns,
		table:            sqldialect.MySQL.QualifyTable(schemaOf(t), t.Table),
		rowsPerStatement: min(maxRowsPerInsert, maxPlaceholders/len(columns)),
		statements:       map[int]*sql.Stmt{},
	}
	defer run.closeStatements()
	if err := run.rejectNonTransactionalTable(ctx, t); err != nil {
		return engine.LoadStats{}, err
	}
	run.statementBytes = statementBudget(run.maxAllowedPacket(ctx))
	return engine.DriveLoad(ctx, c.id, op, src.Next, func(rows [][]engine.Value) int { return len(rows) }, run.commitBatch)
}

func schemaOf(t engine.LoadTarget) string {
	if t.Schema != "" {
		return t.Schema
	}
	return t.Database
}

func statementBudget(maxPacket int64) int {
	return int(min(maxPacket/packetBudgetDivisor, maxStatementBytes))
}

func (r *loadRun) maxAllowedPacket(ctx context.Context) int64 {
	n := int64(fallbackMaxPacket)
	_ = r.session.cancellable(ctx, func(qctx context.Context) error {
		var got int64
		if err := r.session.conn.QueryRowContext(qctx, "SELECT @@max_allowed_packet").Scan(&got); err == nil && got > 0 {
			n = got
		}
		return nil
	})
	return n
}

// nonTransactionalEngines cannot roll back a failed batch, so a partial write
// could not be reported in LoadStats.
var nonTransactionalEngines = map[string]bool{
	"MYISAM": true, "MRG_MYISAM": true, "MEMORY": true, "HEAP": true, "ARCHIVE": true,
	"CSV": true, "BLACKHOLE": true, "ARIA": true, "FEDERATED": true,
}

func (r *loadRun) rejectNonTransactionalTable(ctx context.Context, t engine.LoadTarget) error {
	var storage sql.NullString
	err := r.session.cancellable(ctx, func(qctx context.Context) error {
		return r.session.conn.QueryRowContext(qctx,
			"SELECT ENGINE FROM information_schema.TABLES WHERE TABLE_SCHEMA = COALESCE(NULLIF(?, ''), DATABASE()) AND TABLE_NAME = ?",
			schemaOf(t), t.Table).Scan(&storage)
	})
	if errors.Is(err, sql.ErrNoRows) {
		return nil
	}
	if err != nil {
		return r.c.loadError(ctx, err)
	}
	if nonTransactionalEngines[strings.ToUpper(storage.String)] {
		return engine.Errorf(engine.KindUnsupported, r.c.id, "load rows", "table uses the %s storage engine, which cannot roll back a failed batch", storage.String)
	}
	return nil
}

type loadRun struct {
	c                *Conn
	session          *loadSession
	columns          []string
	table            string
	rowsPerStatement int
	statementBytes   int
	statements       map[int]*sql.Stmt
}

func (r *loadRun) insertSQL(rows int) string {
	quoted := make([]string, len(r.columns))
	for i, name := range r.columns {
		quoted[i] = sqldialect.MySQL.QuoteIdent(name)
	}
	tuple := "(" + strings.TrimSuffix(strings.Repeat("?,", len(r.columns)), ",") + ")"
	var sb strings.Builder
	sb.WriteString("INSERT INTO " + r.table + " (" + strings.Join(quoted, ", ") + ") VALUES ")
	for i := range rows {
		if i > 0 {
			sb.WriteByte(',')
		}
		sb.WriteString(tuple)
	}
	return sb.String()
}

func (r *loadRun) statement(ctx context.Context, rows int) (*sql.Stmt, error) {
	if s, ok := r.statements[rows]; ok {
		return s, nil
	}
	if len(r.statements) >= cachedStatementCap {
		r.closeStatements()
	}
	s, err := r.session.conn.PrepareContext(ctx, r.insertSQL(rows))
	if err != nil {
		return nil, fmt.Errorf("prepare insert: %w", err)
	}
	r.statements[rows] = s
	return s, nil
}

func (r *loadRun) closeStatements() {
	for n, s := range r.statements {
		_ = s.Close()
		delete(r.statements, n)
	}
}

func (r *loadRun) commitBatch(ctx context.Context, rows [][]engine.Value) (engine.LoadStats, error) {
	for i, row := range rows {
		if len(row) != len(r.columns) {
			return engine.LoadStats{}, engine.Errorf(engine.KindInvalidConfig, r.c.id, "load rows", "row %d has %d values for %d columns", i, len(row), len(r.columns))
		}
	}
	var inserted uint64
	err := r.session.cancellable(ctx, func(qctx context.Context) (err error) {
		inserted, err = r.insertInTransaction(ctx, qctx, rows)
		return err
	})
	if err != nil {
		return engine.LoadStats{}, r.c.loadError(ctx, err)
	}
	return engine.LoadStats{Rows: inserted, Batches: 1}, nil
}

func (r *loadRun) insertInTransaction(ctx, qctx context.Context, rows [][]engine.Value) (uint64, error) {
	tx, err := r.session.conn.BeginTx(qctx, nil)
	if err != nil {
		return 0, fmt.Errorf("begin: %w", err)
	}
	inserted, err := r.insertChunks(ctx, qctx, tx, rows)
	if err != nil {
		_ = tx.Rollback()
		return 0, err
	}
	if err := ctx.Err(); err != nil {
		_ = tx.Rollback()
		return 0, fmt.Errorf("cancelled before commit: %w", err)
	}
	if err := tx.Commit(); err != nil {
		return 0, fmt.Errorf("commit: %w", err)
	}
	return inserted, nil
}

func (r *loadRun) insertChunks(ctx, qctx context.Context, tx *sql.Tx, rows [][]engine.Value) (uint64, error) {
	var inserted uint64
	args := make([]any, 0, r.rowsPerStatement*len(r.columns))
	for start := 0; start < len(rows); {
		if err := ctx.Err(); err != nil {
			return 0, fmt.Errorf("cancelled between statements: %w", err)
		}
		end := r.chunkEnd(rows, start)
		stmt, err := r.statement(qctx, end-start)
		if err != nil {
			return 0, err
		}
		args = args[:0]
		for _, row := range rows[start:end] {
			rowArgs, err := toArgs(row)
			if err != nil {
				return 0, &engine.Error{Kind: engine.KindInvalidConfig, Engine: r.c.id, Op: "load rows", Msg: err.Error()}
			}
			args = append(args, rowArgs...)
		}
		res, err := tx.StmtContext(qctx, stmt).ExecContext(qctx, args...)
		if err != nil {
			return 0, fmt.Errorf("insert: %w", err)
		}
		changed, err := res.RowsAffected()
		if err != nil {
			return 0, fmt.Errorf("rows affected: %w", err)
		}
		inserted += uint64(changed) //nolint:gosec // a row count is non-negative
		start = end
	}
	return inserted, nil
}

// chunkEnd returns where the statement starting at start ends: at the row
// cap, or before the row that would push it past the byte budget.
func (r *loadRun) chunkEnd(rows [][]engine.Value, start int) int {
	size, end := 0, start
	for end < len(rows) && end-start < r.rowsPerStatement {
		rowSize := estimatedWireBytes(rows[end])
		if end > start && size+rowSize > r.statementBytes {
			break
		}
		size += rowSize
		end++
	}
	return end
}

func estimatedWireBytes(row []engine.Value) int {
	n := 0
	for _, v := range row {
		switch v.Kind {
		case engine.VDecimal, engine.VText, engine.VJSON, engine.VUUID:
			n += len(v.Str) + perValueWireBytes
		case engine.VBytes:
			n += len(v.Bytes) + perValueWireBytes
		case engine.VTimestamptz:
			n += perTimestampBytes
		default:
			n += perValueWireBytes
		}
	}
	return n
}

// loadSession is a connection of its own for one load, so the load can neither
// end the caller's open transaction nor be mixed up with it.
type loadSession struct {
	c      *Conn
	conn   *sql.Conn
	connID uint64
}

func (c *Conn) loadSession(ctx context.Context, op string) (*loadSession, error) {
	if _, err := c.live(op); err != nil {
		return nil, err
	}
	c.mu.Lock()
	db := c.db
	c.mu.Unlock()
	if db == nil {
		return nil, &engine.Error{Kind: engine.KindConnectionLost, Engine: c.id, Op: op, Msg: "connection is closed"}
	}
	conn, err := db.Conn(ctx)
	if err != nil {
		return nil, c.loadError(ctx, err)
	}
	s := &loadSession{c: c, conn: conn}
	if err := s.cancellable(ctx, func(qctx context.Context) error {
		return conn.QueryRowContext(qctx, "SELECT CONNECTION_ID()").Scan(&s.connID)
	}); err != nil {
		_ = conn.Close()
		return nil, c.loadError(ctx, err)
	}
	return s, nil
}

func (s *loadSession) close() { _ = s.conn.Close() }

// cancellable runs fn on a context that cancelling ctx does not reach, because
// the driver reacts to that by closing the socket and losing the session.
// Instead a watcher sends KILL QUERY, and cuts the socket if that fails. It
// waits for the watcher before returning, so a late KILL cannot hit a later
// statement.
func (s *loadSession) cancellable(ctx context.Context, fn func(qctx context.Context) error) error {
	qctx, cutSocket := context.WithCancel(context.WithoutCancel(ctx))
	defer cutSocket()
	done := make(chan struct{})
	var wg sync.WaitGroup
	wg.Add(1)
	go func() {
		defer wg.Done()
		select {
		case <-ctx.Done():
			if err := s.c.killConnectionQuery(s.connID); err != nil {
				cutSocket()
			}
		case <-done:
		}
	}()
	err := fn(qctx)
	close(done)
	wg.Wait()
	return err
}

var duplicateKeyRe = regexp.MustCompile(`for key '([^']*)'$`)

var dataErrorNumbers = map[uint16]bool{1264: true, 1265: true, 1292: true, 1366: true, 1406: true, 1411: true, 1525: true, 1367: true}

var constraintErrorNumbers = map[uint16]bool{
	1022: true, 1048: true, 1062: true, 1169: true, 1216: true, 1217: true, 1364: true,
	1451: true, 1452: true, 1586: true, 3819: true, 4025: true,
}

// loadError classifies a failed load. Messages name columns, keys and
// constraints but never the rejected values.
func (c *Conn) loadError(ctx context.Context, err error) error {
	var typed *engine.Error
	if errors.As(err, &typed) {
		return typed
	}
	e := &engine.Error{Engine: c.id, Op: "load rows", Err: err}
	var me *drv.MySQLError
	switch {
	case ctx.Err() != nil || (errors.As(err, &me) && me.Number == errQueryInterrupt):
		e.Kind, e.Msg = engine.KindCanceled, "load cancelled"
		if errors.Is(ctx.Err(), context.DeadlineExceeded) {
			e.Kind, e.Msg = engine.KindTimeout, "load timed out"
		}
	case errors.As(err, &me):
		e.Kind, e.Msg = loadErrorKind(c, err, me), loadErrorMessage(me)
	case errors.Is(err, drv.ErrPktTooLarge):
		e.Kind, e.Msg = engine.KindSQL, "a row is larger than max_allowed_packet"
	default:
		classified := classify(c.id, "load rows", err, c.secret)
		e.Kind, e.Msg = classified.Kind, classified.Msg
	}
	return e
}

func loadErrorKind(c *Conn, err error, me *drv.MySQLError) engine.Kind {
	switch {
	case constraintErrorNumbers[me.Number]:
		return engine.KindConstraint
	case me.Number == 1146:
		return engine.KindNotFound
	}
	if k := classify(c.id, "load rows", err, c.secret).Kind; k != engine.KindUnknown {
		return k
	}
	return engine.KindSQL
}

func loadErrorMessage(me *drv.MySQLError) string {
	switch {
	case me.Number == 1062:
		if m := duplicateKeyRe.FindStringSubmatch(me.Message); m != nil {
			return "duplicate value violates unique key '" + m[1] + "'"
		}
		return "duplicate value violates a unique key"
	case dataErrorNumbers[me.Number]:
		return "a value was rejected by its column type"
	}
	return me.Message
}
