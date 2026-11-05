//go:build integration

package api

import (
	"context"
	"log/slog"
	"os"
	"runtime"
	"strings"
	"sync/atomic"
	"testing"
	"time"

	"github.com/jackc/pgx/v5"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/engine/postgres"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/results"
	"github.com/doubledare704/queravue/core/internal/session"
)

func getenv(k, def string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return def
}

func pgConfig() (engine.Config, engine.Secret) {
	return engine.Config{EngineID: postgres.IDPostgres, Params: map[string]string{
		postgres.ParamHost:     getenv("PG_HOST", "127.0.0.1"),
		postgres.ParamPort:     getenv("PG_PORT", "5432"),
		postgres.ParamUser:     getenv("PG_USER", "queravue"),
		postgres.ParamDatabase: getenv("PG_DB", "queravue"),
		postgres.ParamSSLMode:  "disable",
	}}, engine.NewSecret(getenv("PG_PASSWORD", "queravue"))
}

type pgOpener struct{}

func (pgOpener) Open(ctx context.Context, _ string) (engine.Conn, engine.Descriptor, error) {
	e := postgres.New(postgres.VariantPostgres)
	cfg, sec := pgConfig()
	c, err := e.Connect(ctx, cfg, sec)
	return c, e.Descriptor(), err
}

func newPGFixture(t *testing.T) *fixture {
	t.Helper()
	log := slog.New(slog.DiscardHandler)
	res, err := results.NewManager(t.TempDir(), 0, log)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(res.Shutdown)
	mgr := session.NewManager(pgOpener{}, session.WithLogger(log), session.WithOnClose(res.CloseSession))
	t.Cleanup(mgr.Shutdown)
	s, err := mgr.Open(context.Background(), "pg")
	if err != nil {
		t.Fatalf("open session: %v (is `make db-up` running?)", err)
	}
	return &fixture{q: NewQueryService(mgr, res, log), sess: s, res: res}
}

func adminConn(t *testing.T) *pgx.Conn {
	t.Helper()
	cfg, sec := pgConfig()
	c, err := pgx.Connect(context.Background(), "host="+cfg.Params[postgres.ParamHost]+" port="+cfg.Params[postgres.ParamPort]+
		" user="+cfg.Params[postgres.ParamUser]+" dbname="+cfg.Params[postgres.ParamDatabase]+" password="+sec.Reveal()+" sslmode=disable")
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = c.Close(context.Background()) })
	return c
}

func TestIntegrationMillionRowsSpoolFetchAndHeap(t *testing.T) {
	f := newPGFixture(t)
	runtime.GC()
	var base runtime.MemStats
	runtime.ReadMemStats(&base)

	var peak atomic.Uint64
	stop := make(chan struct{})
	go func() {
		var m runtime.MemStats
		for {
			select {
			case <-stop:
				return
			case <-time.After(10 * time.Millisecond):
				runtime.ReadMemStats(&m)
				if m.HeapAlloc > peak.Load() {
					peak.Store(m.HeapAlloc)
				}
			}
		}
	}()

	start := time.Now()
	evs := f.exec(t, &queravuev1.ExecuteRequest{
		Text: "SELECT g AS id, 'row-' || g AS label, g % 7 = 0 AS flag FROM generate_series(1,1000000) g",
		Mode: queravuev1.ExecuteMode_EXECUTE_MODE_ALL,
	})
	close(stop)
	t.Logf("spooled 1M rows in %s", time.Since(start))

	last := evs[len(evs)-1]
	sum := last.GetSummary()
	if sum == nil || sum.GetRowsSpooled() != 1_000_000 || sum.GetTruncated() {
		t.Fatalf("last event = %v (events: %s)", last, kinds(evs[:min(len(evs), 8)]))
	}
	rowsOnStream := 0
	for _, e := range evs {
		rowsOnStream += len(e.GetRows().GetRows())
	}
	if rowsOnStream != 500 {
		t.Errorf("rows sent on the stream = %d, want only the first window (500)", rowsOnStream)
	}
	if growth := int64(peak.Load()) - int64(base.HeapAlloc); growth > 50<<20 {
		t.Errorf("heap grew %d MB while spooling 1M rows, want < 50 MB", growth>>20)
	} else {
		t.Logf("heap growth while spooling: %d MB", growth>>20)
	}

	id := evs[1].GetStarted().GetResultId()
	t0 := time.Now()
	resp, err := f.q.FetchRows(context.Background(), &queravuev1.FetchRowsRequest{ResultId: id, Offset: 900_000, Limit: 500})
	if err != nil {
		t.Fatal(err)
	}
	t.Logf("FetchRows at 900k: %s", time.Since(t0))
	if len(resp.GetRows()) != 500 || resp.GetRows()[0].GetValues()[0].GetIntValue() != 900_001 ||
		resp.GetRows()[0].GetValues()[1].GetTextValue() != "row-900001" {
		t.Errorf("rows at 900k: n=%d first=%v", len(resp.GetRows()), resp.GetRows()[0])
	}
	if f.res.Len() != 1 {
		t.Errorf("open results = %d", f.res.Len())
	}
}

func TestIntegrationCancelMidStream(t *testing.T) {
	f := newPGFixture(t)
	admin := adminConn(t)
	const marker = "qv_cancel_test_marker"
	q := "SELECT g, '" + marker + "' FROM generate_series(1, 2000000000) g"

	done := make(chan []*queravuev1.ExecuteResponse, 1)
	go func() {
		st := &execStream{ctx: context.Background()}
		_ = f.q.Execute(&queravuev1.ExecuteRequest{SessionId: f.sess.ID, Text: q, Mode: queravuev1.ExecuteMode_EXECUTE_MODE_ALL}, st)
		done <- st.events
	}()

	active := func() int {
		var n int
		err := admin.QueryRow(context.Background(),
			"SELECT count(*) FROM pg_stat_activity WHERE state = 'active' AND query LIKE $1 AND pid <> pg_backend_pid()",
			"%"+marker+"%").Scan(&n)
		if err != nil {
			t.Fatal(err)
		}
		return n
	}
	deadline := time.Now().Add(10 * time.Second)
	for active() == 0 {
		if time.Now().After(deadline) {
			t.Fatal("query never became active")
		}
		time.Sleep(20 * time.Millisecond)
	}
	time.Sleep(300 * time.Millisecond) // let rows stream into the spool

	if _, err := f.q.Cancel(context.Background(), &queravuev1.CancelRequest{SessionId: f.sess.ID}); err != nil {
		t.Fatal(err)
	}
	select {
	case evs := <-done:
		e := evs[len(evs)-1].GetError()
		if e == nil || e.GetKind() != queravuev1.QueryErrorKind_QUERY_ERROR_KIND_CANCELED {
			t.Errorf("last event = %v", evs[len(evs)-1])
		}
	case <-time.After(10 * time.Second):
		t.Fatal("Execute did not return after Cancel")
	}
	// The query must be gone on the server, not just abandoned by the core.
	deadline = time.Now().Add(5 * time.Second)
	for active() != 0 {
		if time.Now().After(deadline) {
			t.Fatal("query still active in pg_stat_activity after Cancel")
		}
		time.Sleep(50 * time.Millisecond)
	}
	// The session survives the cancel.
	evs := f.exec(t, &queravuev1.ExecuteRequest{Text: "select 1"})
	if !strings.HasSuffix(kinds(evs), "summary") {
		t.Errorf("session unusable after cancel: %s", kinds(evs))
	}
}

func TestIntegrationClientDisconnectCancelsQuery(t *testing.T) {
	f := newPGFixture(t)
	admin := adminConn(t)
	const marker = "qv_disconnect_test_marker"
	ctx, cancel := context.WithCancel(context.Background())
	done := make(chan struct{})
	go func() {
		st := &execStream{ctx: ctx}
		_ = f.q.Execute(&queravuev1.ExecuteRequest{SessionId: f.sess.ID, Mode: queravuev1.ExecuteMode_EXECUTE_MODE_ALL,
			Text: "SELECT g, '" + marker + "' FROM generate_series(1, 2000000000) g"}, st)
		close(done)
	}()
	time.Sleep(500 * time.Millisecond)
	cancel() // the client drops the stream
	select {
	case <-done:
	case <-time.After(10 * time.Second):
		t.Fatal("Execute did not return after the stream context was cancelled")
	}
	deadline := time.Now().Add(5 * time.Second)
	for {
		var n int
		_ = admin.QueryRow(context.Background(),
			"SELECT count(*) FROM pg_stat_activity WHERE state = 'active' AND query LIKE $1 AND pid <> pg_backend_pid()", "%"+marker+"%").Scan(&n)
		if n == 0 {
			return
		}
		if time.Now().After(deadline) {
			t.Fatal("query still active after the client disconnected")
		}
		time.Sleep(50 * time.Millisecond)
	}
}

func TestIntegrationTypedValues(t *testing.T) {
	f := newPGFixture(t)
	evs := f.exec(t, &queravuev1.ExecuteRequest{Mode: queravuev1.ExecuteMode_EXECUTE_MODE_ALL, Text: `SELECT
  NULL::int AS n,
  true AS b,
  (-9223372036854775808)::bigint AS i8,
  42::int2 AS i2,
  1.5::float8 AS f8,
  'NaN'::float8 AS nan,
  12345678901234567890.123456789::numeric AS dec,
  'héllo 😀'::text AS txt,
  '\xdeadbeef'::bytea AS bin,
  '2024-01-02 03:04:05.123456+00'::timestamptz AS ts,
  '{"a": [1, 2]}'::jsonb AS js,
  'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'::uuid AS id,
  ARRAY[1,2,NULL]::int4[] AS arr,
  ARRAY['a','b c','d"e']::text[] AS tarr,
  ARRAY[[1,2],[3,4]]::int4[] AS nested,
  '2024-01-02'::date AS d,
  '1 day'::interval AS iv,
  'infinity'::timestamptz AS inf`})
	var cols []*queravuev1.Column
	var row *queravuev1.Row
	for _, e := range evs {
		if c := e.GetColumns(); c != nil {
			cols = c.GetColumns()
		}
		if w := e.GetRows(); w != nil {
			row = w.GetRows()[0]
		}
	}
	if row == nil {
		t.Fatalf("no row: %s", kinds(evs))
	}
	v := func(name string) *queravuev1.Value {
		for i, c := range cols {
			if c.GetName() == name {
				return row.GetValues()[i]
			}
		}
		t.Fatalf("no column %s", name)
		return nil
	}
	if v("n").GetNullValue() != 0 || v("n").GetKind() == nil {
		t.Errorf("n = %v", v("n"))
	}
	checks := []struct {
		name string
		ok   bool
	}{
		{"b", v("b").GetBoolValue()},
		{"i8", v("i8").GetIntValue() == -9223372036854775808},
		{"i2", v("i2").GetIntValue() == 42},
		{"f8", v("f8").GetDoubleValue() == 1.5},
		{"dec", v("dec").GetDecimalValue() == "12345678901234567890.123456789"},
		{"txt", v("txt").GetTextValue() == "héllo 😀"},
		{"bin", string(v("bin").GetBytesValue()) == "\xde\xad\xbe\xef"},
		{"ts", v("ts").GetTimestampValue().AsTime().Equal(time.Date(2024, 1, 2, 3, 4, 5, 123456000, time.UTC))},
		{"js", strings.Contains(v("js").GetJsonValue(), `"a": [1, 2]`)},
		{"id", v("id").GetUuidValue() == "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11"},
		{"arr", len(v("arr").GetArrayValue().GetValues()) == 3 && v("arr").GetArrayValue().GetValues()[1].GetIntValue() == 2 && v("arr").GetArrayValue().GetValues()[2].GetKind() != nil},
		{"tarr", v("tarr").GetArrayValue().GetValues()[1].GetTextValue() == "b c" && v("tarr").GetArrayValue().GetValues()[2].GetTextValue() == `d"e`},
		{"nested", v("nested").GetArrayValue().GetValues()[1].GetArrayValue().GetValues()[0].GetIntValue() == 3},
		{"d", v("d").GetTextValue() == "2024-01-02"},
		{"iv", v("iv").GetTextValue() == "1 day"},
		{"inf", v("inf").GetTextValue() == "infinity"},
	}
	for _, c := range checks {
		if !c.ok {
			t.Errorf("value %s wrong: %v", c.name, v(c.name))
		}
	}
	if x := v("nan").GetDoubleValue(); x == x {
		t.Errorf("nan = %v", x)
	}
	kindOf := map[string]queravuev1.ValueKind{}
	for _, c := range cols {
		kindOf[c.GetName()] = c.GetKind()
	}
	if kindOf["dec"] != queravuev1.ValueKind_VALUE_KIND_DECIMAL || kindOf["arr"] != queravuev1.ValueKind_VALUE_KIND_ARRAY ||
		kindOf["ts"] != queravuev1.ValueKind_VALUE_KIND_TIMESTAMPTZ || kindOf["d"] != queravuev1.ValueKind_VALUE_KIND_TEXT {
		t.Errorf("column kinds = %v", kindOf)
	}
}

func TestIntegrationErrorPositionNoticesAndRowsAffected(t *testing.T) {
	f := newPGFixture(t)
	text := "select 1;\nselect 'é', foo from generate_series(1,2)"
	evs := f.exec(t, &queravuev1.ExecuteRequest{Text: text, Mode: queravuev1.ExecuteMode_EXECUTE_MODE_ALL})
	e := evs[len(evs)-1].GetError()
	if e == nil || e.GetKind() != queravuev1.QueryErrorKind_QUERY_ERROR_KIND_SQL || e.GetStatementIndex() != 1 {
		t.Fatalf("last = %v", evs[len(evs)-1])
	}
	// "foo" starts at UTF-16 offset len("select 1;\nselect 'é', ") = 10+12 = 22.
	if e.Position == nil || *e.Position != 22 {
		t.Errorf("position = %v, want 22", e.GetPosition())
	}

	evs = f.exec(t, &queravuev1.ExecuteRequest{Mode: queravuev1.ExecuteMode_EXECUTE_MODE_ALL,
		Text: "DO $$ BEGIN RAISE NOTICE 'hello; there'; END $$; CREATE TEMP TABLE qv_t (i int); INSERT INTO qv_t SELECT generate_series(1,5)"})
	var notices []string
	var affected uint64
	for _, ev := range evs {
		if s := ev.GetSummary(); s != nil {
			notices = append(notices, s.GetNotices()...)
			affected = s.GetRowsAffected()
		}
	}
	if len(notices) != 1 || !strings.Contains(notices[0], "hello; there") || affected != 5 {
		t.Errorf("notices=%v affected=%d events=%s", notices, affected, kinds(evs))
	}
}
