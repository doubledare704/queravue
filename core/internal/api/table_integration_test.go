//go:build integration

package api_test

import (
	"context"
	"io"
	"testing"
	"time"

	"google.golang.org/grpc/metadata"

	"github.com/doubledare704/queravue/core/internal/api"
	"github.com/doubledare704/queravue/core/internal/connections"
	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/engine/postgres"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/history"
	"github.com/doubledare704/queravue/core/internal/results"
	"github.com/doubledare704/queravue/core/internal/secrets"
	"github.com/doubledare704/queravue/core/internal/session"
)

type pgOpener struct{}

func (pgOpener) Open(ctx context.Context, _ string) (engine.Conn, engine.Descriptor, error) {
	e := postgres.New(postgres.VariantPostgres)
	cfg := engine.Config{
		EngineID: postgres.IDPostgres,
		Params: map[string]string{
			postgres.ParamHost:     "127.0.0.1",
			postgres.ParamPort:     "5432",
			postgres.ParamUser:     "queravue",
			postgres.ParamDatabase: "queravue",
			postgres.ParamSSLMode:  "disable",
		},
	}
	conn, err := e.Connect(ctx, cfg, engine.NewSecret("queravue"))
	return conn, e.Descriptor(), err
}

type openTableClientStream struct {
	events []*queravuev1.OpenTableResponse
	ctx    context.Context
}

func (s *openTableClientStream) Send(resp *queravuev1.OpenTableResponse) error {
	s.events = append(s.events, resp)
	return nil
}

func (s *openTableClientStream) SetHeader(metadata.MD) error  { return nil }
func (s *openTableClientStream) SendHeader(metadata.MD) error { return nil }
func (s *openTableClientStream) SetTrailer(metadata.MD)       {}
func (s *openTableClientStream) Context() context.Context     { return s.ctx }
func (s *openTableClientStream) SendMsg(_ any) error          { return nil }
func (s *openTableClientStream) RecvMsg(_ any) error          { return io.EOF }

func TestIntegration_OpenTable_1MillionRows_SortedJump(t *testing.T) {
	dir := t.TempDir()
	mgr := session.NewManager(pgOpener{})
	t.Cleanup(mgr.Shutdown)

	sess, err := mgr.Open(context.Background(), "pg-conn")
	if err != nil {
		t.Fatalf("open session: %v", err)
	}

	resMgr, err := results.NewManager(dir, 0, nil)
	if err != nil {
		t.Fatalf("new results manager: %v", err)
	}
	t.Cleanup(resMgr.Shutdown)

	histStore, err := history.NewStore(":memory:", 1000, nil)
	if err != nil {
		t.Fatalf("new history store: %v", err)
	}
	t.Cleanup(func() { _ = histStore.Close() })

	reg, _ := engine.NewRegistry(postgres.New(postgres.VariantPostgres))
	connStore := connections.NewFileStore(dir)
	connSvc := connections.NewService(reg, connStore, secrets.NewMemory())

	svc := api.NewTableService(mgr, resMgr, connSvc, histStore, nil)
	querySvc := api.NewQueryService(mgr, resMgr, nil)

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	stream := &openTableClientStream{ctx: ctx}
	req := &queravuev1.OpenTableRequest{
		SessionId: sess.ID,
		TableRef:  &queravuev1.TableRef{Schema: "public", Table: "million_items"},
		Sort: []*queravuev1.SortClause{
			{
				Column:    "val",
				Direction: queravuev1.SortDirection_SORT_DIRECTION_DESC,
			},
		},
		PageSize: 0, // spool full result
	}

	err = svc.OpenTable(req, stream)
	if err != nil {
		t.Fatalf("OpenTable: %v", err)
	}

	if len(stream.events) == 0 {
		t.Fatal("no events received from OpenTable")
	}

	// First event has generated SQL
	genSQL := stream.events[0].GetSql()
	if genSQL == "" {
		t.Error("expected non-empty generated SQL on first event")
	}

	// Find StatementStarted event to get result_id
	var resultID string
	for _, ev := range stream.events {
		if started := ev.GetEvent().GetStarted(); started != nil {
			resultID = started.GetResultId()
			break
		}
	}
	if resultID == "" {
		t.Fatal("no result_id returned in started event")
	}

	// Performance exit criterion:
	// "sorted jump to row 900k < 200 ms on an indexed column"
	jumpStart := time.Now()
	fetchResp, err := querySvc.FetchRows(ctx, &queravuev1.FetchRowsRequest{
		ResultId: resultID,
		Offset:   900000,
		Limit:    10,
	})
	jumpDuration := time.Since(jumpStart)
	if err != nil {
		t.Fatalf("FetchRows at offset 900k: %v", err)
	}

	if len(fetchResp.GetRows()) == 0 {
		t.Fatalf("expected rows at offset 900,000, got 0")
	}

	t.Logf("Sorted jump to row 900k took %v (budget: < 200 ms)", jumpDuration)
	if jumpDuration > 200*time.Millisecond {
		t.Errorf("sorted jump to row 900k took %v, exceeded 200 ms budget", jumpDuration)
	}

	// Verify the values are sorted DESC: at row 900k of 1M rows sorted DESC by val,
	// val should be 100,000.
	firstRowVal := fetchResp.GetRows()[0].GetValues()[1].GetIntValue()
	if firstRowVal != 100000 {
		t.Errorf("expected val at 900k offset to be 100000, got %d", firstRowVal)
	}
}
