// Package history persists and searches query execution history in an embedded SQLite database.
package history

import (
	"context"
	"database/sql"
	"fmt"
	"log/slog"
	"os"
	"path/filepath"
	"sync"
	"time"

	_ "modernc.org/sqlite" // SQLite database driver.
)

// DefaultCap is the default maximum number of entries to retain.
const DefaultCap = 10000

// Entry represents a single executed query record.
type Entry struct {
	ID           int64
	ConnectionID string
	QueryText    string
	StartedAt    time.Time
	Duration     time.Duration
	RowsAffected uint64
	Error        string
}

// Store persists and searches executed queries using a local SQLite database.
type Store struct {
	db         *sql.DB
	maxEntries int
	log        *slog.Logger
	mu         sync.Mutex
}

// NewStore opens or creates a SQLite history database at path.
// If maxEntries <= 0, DefaultCap is used.
func NewStore(path string, maxEntries int, log *slog.Logger) (*Store, error) {
	if log == nil {
		log = slog.Default()
	}
	if maxEntries <= 0 {
		maxEntries = DefaultCap
	}

	if path != ":memory:" {
		if err := os.MkdirAll(filepath.Dir(path), 0o750); err != nil {
			return nil, fmt.Errorf("history: create dir: %w", err)
		}
	}

	dsn := path
	if path != ":memory:" {
		dsn = path + "?_pragma=busy_timeout(5000)&_pragma=journal_mode(WAL)&_pragma=synchronous(NORMAL)"
	}

	db, err := sql.Open("sqlite", dsn)
	if err != nil {
		return nil, fmt.Errorf("history: open sqlite: %w", err)
	}

	// SQLite WAL mode supports one writer safely
	db.SetMaxOpenConns(1)

	schema := `
CREATE TABLE IF NOT EXISTS query_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    connection_id TEXT NOT NULL,
    query_text TEXT NOT NULL,
    started_at_ms INTEGER NOT NULL,
    duration_ns INTEGER NOT NULL,
    rows_affected INTEGER NOT NULL,
    error_text TEXT NOT NULL DEFAULT ''
);
CREATE INDEX IF NOT EXISTS idx_query_history_started ON query_history(started_at_ms DESC);
CREATE INDEX IF NOT EXISTS idx_query_history_conn ON query_history(connection_id, started_at_ms DESC);
`
	if _, err := db.Exec(schema); err != nil {
		_ = db.Close()
		return nil, fmt.Errorf("history: init schema: %w", err)
	}

	return &Store{
		db:         db,
		maxEntries: maxEntries,
		log:        log,
	}, nil
}

// Append records a query execution and enforces the entry cap.
func (s *Store) Append(ctx context.Context, e Entry) (int64, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	startedMS := e.StartedAt.UnixMilli()
	if startedMS <= 0 {
		startedMS = time.Now().UnixMilli()
	}

	query := `INSERT INTO query_history (connection_id, query_text, started_at_ms, duration_ns, rows_affected, error_text)
VALUES (?, ?, ?, ?, ?, ?);`

	res, err := s.db.ExecContext(ctx, query, e.ConnectionID, e.QueryText, startedMS, e.Duration.Nanoseconds(), e.RowsAffected, e.Error)
	if err != nil {
		return 0, fmt.Errorf("history: append: %w", err)
	}

	id, err := res.LastInsertId()
	if err != nil {
		return 0, fmt.Errorf("history: last insert id: %w", err)
	}

	// Prune oldest if cap exceeded
	pruneQuery := `DELETE FROM query_history WHERE id NOT IN (
    SELECT id FROM query_history ORDER BY id DESC LIMIT ?
);`
	if _, err := s.db.ExecContext(ctx, pruneQuery, s.maxEntries); err != nil {
		s.log.Warn("history: failed to prune old entries", "err", err)
	}

	return id, nil
}

// List searches and paginates history entries, ordered newest first.
func (s *Store) List(ctx context.Context, connID, search string, limit, offset int) ([]Entry, int64, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	if limit <= 0 {
		limit = 50
	}
	if limit > 500 {
		limit = 500
	}
	if offset < 0 {
		offset = 0
	}

	where := "1=1"
	var args []any

	if connID != "" {
		where += " AND connection_id = ?"
		args = append(args, connID)
	}
	if search != "" {
		where += " AND query_text LIKE ?"
		args = append(args, "%"+search+"%")
	}

	// Get total count
	var total int64
	countQuery := fmt.Sprintf("SELECT COUNT(*) FROM query_history WHERE %s;", where)
	if err := s.db.QueryRowContext(ctx, countQuery, args...).Scan(&total); err != nil {
		return nil, 0, fmt.Errorf("history: count: %w", err)
	}

	// Fetch entries
	selectQuery := fmt.Sprintf(`SELECT id, connection_id, query_text, started_at_ms, duration_ns, rows_affected, error_text
FROM query_history
WHERE %s
ORDER BY started_at_ms DESC, id DESC
LIMIT ? OFFSET ?;`, where)

	queryArgs := make([]any, 0, len(args)+2)
	queryArgs = append(queryArgs, args...)
	queryArgs = append(queryArgs, limit, offset)

	rows, err := s.db.QueryContext(ctx, selectQuery, queryArgs...)
	if err != nil {
		return nil, 0, fmt.Errorf("history: list: %w", err)
	}
	defer func() { _ = rows.Close() }()

	var entries []Entry
	for rows.Next() {
		var e Entry
		var startedMS, durNS int64
		if err := rows.Scan(&e.ID, &e.ConnectionID, &e.QueryText, &startedMS, &durNS, &e.RowsAffected, &e.Error); err != nil {
			return nil, 0, fmt.Errorf("history: scan: %w", err)
		}
		e.StartedAt = time.UnixMilli(startedMS)
		e.Duration = time.Duration(durNS)
		entries = append(entries, e)
	}

	if err := rows.Err(); err != nil {
		return nil, 0, fmt.Errorf("history: rows err: %w", err)
	}
	return entries, total, nil
}

// Clear removes entries, optionally restricted to connID.
func (s *Store) Clear(ctx context.Context, connID string) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	var err error
	if connID != "" {
		_, err = s.db.ExecContext(ctx, "DELETE FROM query_history WHERE connection_id = ?;", connID)
	} else {
		_, err = s.db.ExecContext(ctx, "DELETE FROM query_history;")
	}
	if err != nil {
		return fmt.Errorf("history: clear: %w", err)
	}
	return nil
}

// Close closes the underlying database.
func (s *Store) Close() error {
	if err := s.db.Close(); err != nil {
		return fmt.Errorf("history: close: %w", err)
	}
	return nil
}
