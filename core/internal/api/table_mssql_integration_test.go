//go:build integration

package api_test

import (
	"context"
	"strings"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/api"
	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/engine/mssql"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/history"
	"github.com/doubledare704/queravue/core/internal/results"
	"github.com/doubledare704/queravue/core/internal/session"
)

type mssqlOpener struct{}

func (mssqlOpener) Open(ctx context.Context, _ string) (engine.Conn, engine.Descriptor, error) {
	e := mssql.New()
	cfg := engine.Config{EngineID: mssql.ID, Params: map[string]string{
		mssql.ParamHost: "127.0.0.1", mssql.ParamPort: "1433", mssql.ParamUser: "sa",
		mssql.ParamDatabase: "queravue", mssql.ParamEncrypt: "required", mssql.ParamTrust: "true",
	}}
	conn, err := e.Connect(ctx, cfg, engine.NewSecret("Queravue_dev1"))
	return conn, e.Descriptor(), err
}

// SQL Server cannot paginate without ORDER BY: the table view must sort by
// the primary key, and say so when it cannot.
func TestIntegration_OpenTable_MSSQL_OrderByPrimaryKey(t *testing.T) {
	dir := t.TempDir()
	mgr := session.NewManager(mssqlOpener{})
	t.Cleanup(mgr.Shutdown)
	sess, err := mgr.Open(context.Background(), "mssql-conn")
	if err != nil {
		t.Fatal(err)
	}
	resMgr, err := results.NewManager(dir, 0, nil)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(resMgr.Shutdown)
	hist, err := history.NewStore(":memory:", 100, nil)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = hist.Close() })
	svc := api.NewTableService(mgr, resMgr, nil, hist, nil)

	open := func(table string) (*openTableClientStream, string, []string) {
		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()
		stream := &openTableClientStream{ctx: ctx}
		err := svc.OpenTable(&queravuev1.OpenTableRequest{
			SessionId: sess.ID,
			TableRef:  &queravuev1.TableRef{Database: "queravue", Schema: "dbo", Table: table},
			PageSize:  2,
		}, stream)
		if err != nil {
			t.Fatalf("OpenTable(%s): %v", table, err)
		}
		var notices []string
		for _, ev := range stream.events {
			if s := ev.GetEvent().GetSummary(); s != nil {
				notices = s.GetNotices()
			}
			if e := ev.GetEvent().GetError(); e != nil {
				t.Fatalf("OpenTable(%s) error event: %v", table, e.GetMessage())
			}
		}
		return stream, stream.events[0].GetSql(), notices
	}

	_, sql, notices := open("customers")
	if !strings.Contains(sql, "ORDER BY [id] ASC OFFSET 0 ROWS FETCH NEXT 2 ROWS ONLY") || !strings.Contains(sql, "[queravue].[dbo].[customers]") {
		t.Errorf("keyed table SQL = %s", sql)
	}
	if len(notices) != 0 {
		t.Errorf("keyed table notices = %v", notices)
	}

	_, sql, notices = open("logs_no_pk")
	if !strings.Contains(sql, "ORDER BY (SELECT NULL)") {
		t.Errorf("keyless table SQL = %s", sql)
	}
	if len(notices) != 1 || !strings.Contains(notices[0], "not stable") {
		t.Errorf("keyless table notices = %v", notices)
	}

	// Edits go through BEGIN TRANSACTION … COMMIT and can be rolled back.
	str := func(s string) *queravuev1.Value {
		return &queravuev1.Value{Kind: &queravuev1.Value_TextValue{TextValue: s}}
	}
	resp, err := svc.ApplyChanges(context.Background(), &queravuev1.ApplyChangesRequest{
		SessionId: sess.ID,
		TableRef:  &queravuev1.TableRef{Database: "queravue", Schema: "dbo", Table: "customers"},
		DryRun:    true,
		Changes: []*queravuev1.RowChange{{
			Type: queravuev1.RowChangeType_ROW_CHANGE_TYPE_INSERT,
			Values: []*queravuev1.ColumnValue{
				{Column: "name", Value: str("Zed")}, {Column: "email", Value: str("zed@example.com")},
			},
		}},
	})
	if err != nil || !resp.GetSuccess() || !strings.HasPrefix(resp.GetGeneratedSql(), "BEGIN TRANSACTION;") ||
		!strings.Contains(resp.GetGeneratedSql(), "N'Zed'") {
		t.Fatalf("dry run = %+v, %v", resp, err)
	}
}
