//go:build integration

package api_test

import (
	"context"
	"fmt"
	"io"
	"log/slog"
	"os"
	"path/filepath"
	"testing"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/metadata"
	"google.golang.org/protobuf/proto"

	"github.com/doubledare704/queravue/core/internal/api"
	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/engine/mysql"
	"github.com/doubledare704/queravue/core/internal/engine/postgres"
	"github.com/doubledare704/queravue/core/internal/engine/sqlite"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/results"
	"github.com/doubledare704/queravue/core/internal/session"
)

type qbExecStream struct {
	grpc.ServerStream
	ctx    context.Context
	events []*queravuev1.ExecuteResponse
}

func (s *qbExecStream) Context() context.Context { return s.ctx }
func (s *qbExecStream) Send(r *queravuev1.ExecuteResponse) error {
	s.events = append(s.events, r)
	return nil
}
func (*qbExecStream) SetHeader(metadata.MD) error  { return nil }
func (*qbExecStream) SendHeader(metadata.MD) error { return nil }
func (*qbExecStream) SetTrailer(metadata.MD)       {}
func (*qbExecStream) SendMsg(any) error            { return nil }
func (*qbExecStream) RecvMsg(any) error            { return io.EOF }

type qbOpener struct {
	open func(context.Context) (engine.Conn, engine.Descriptor, error)
}

func (o qbOpener) Open(ctx context.Context, _ string) (engine.Conn, engine.Descriptor, error) {
	return o.open(ctx)
}

func envOrDefault(k, def string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return def
}

func runQueryBuilderIntegration(t *testing.T, schema string, open func(context.Context) (engine.Conn, engine.Descriptor, error), ddl []string) {
	t.Helper()
	log := slog.New(slog.NewTextHandler(io.Discard, nil))
	resMgr, err := results.NewManager(t.TempDir(), 0, log)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(resMgr.Shutdown)

	mgr := session.NewManager(qbOpener{open: open}, session.WithLogger(log), session.WithOnClose(resMgr.CloseSession))
	t.Cleanup(mgr.Shutdown)

	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	sess, err := mgr.Open(ctx, "qb-it")
	if err != nil {
		t.Fatalf("open session: %v", err)
	}

	qbSvc := api.NewQueryBuilderService(mgr)
	querySvc := api.NewQueryService(mgr, resMgr, log)

	execSQL := func(sqlText string) []*queravuev1.ExecuteResponse {
		t.Helper()
		st := &qbExecStream{ctx: ctx}
		if err := querySvc.Execute(&queravuev1.ExecuteRequest{
			SessionId: sess.ID,
			Text:      sqlText,
			Mode:      queravuev1.ExecuteMode_EXECUTE_MODE_ALL,
		}, st); err != nil {
			t.Fatalf("Execute(%q): %v", sqlText, err)
		}
		for _, ev := range st.events {
			if e := ev.GetError(); e != nil {
				t.Fatalf("Execute(%q) statement error: %s", sqlText, e.GetMessage())
			}
		}
		return st.events
	}

	for _, stmt := range ddl {
		execSQL(stmt)
	}

	model := &queravuev1.SqlQueryModel{
		From: &queravuev1.SqlTableRef{Schema: schema, Table: "qb_customers", Alias: "c"},
		Joins: []*queravuev1.SqlJoin{
			{
				Kind:  queravuev1.SqlJoinKind_SQL_JOIN_KIND_INNER,
				Table: &queravuev1.SqlTableRef{Schema: schema, Table: "qb_orders", Alias: "o"},
				On: &queravuev1.SqlCondition{
					Node: &queravuev1.SqlCondition_Comparison{
						Comparison: &queravuev1.SqlComparison{
							Left:     &queravuev1.SqlOperand{Kind: &queravuev1.SqlOperand_Column{Column: &queravuev1.SqlColumnRef{TableAlias: "c", Column: "id"}}},
							Op:       queravuev1.SqlOperator_SQL_OPERATOR_EQ,
							Operands: []*queravuev1.SqlOperand{{Kind: &queravuev1.SqlOperand_Column{Column: &queravuev1.SqlColumnRef{TableAlias: "o", Column: "customer_id"}}}},
						},
					},
				},
			},
		},
		Select: []*queravuev1.SqlSelectItem{
			{Expression: &queravuev1.SqlSelectItem_Column{Column: &queravuev1.SqlColumnRef{TableAlias: "c", Column: "name"}}},
			{
				Expression: &queravuev1.SqlSelectItem_Aggregate{
					Aggregate: &queravuev1.SqlAggregateExpr{
						Function: queravuev1.SqlAggregate_SQL_AGGREGATE_SUM,
						Column:   &queravuev1.SqlColumnRef{TableAlias: "o", Column: "amount"},
					},
				},
				Alias: "total_amount",
			},
		},
		Where: &queravuev1.SqlCondition{
			Node: &queravuev1.SqlCondition_Comparison{
				Comparison: &queravuev1.SqlComparison{
					Left: &queravuev1.SqlOperand{Kind: &queravuev1.SqlOperand_Column{Column: &queravuev1.SqlColumnRef{TableAlias: "o", Column: "status"}}},
					Op:   queravuev1.SqlOperator_SQL_OPERATOR_IN,
					Operands: []*queravuev1.SqlOperand{
						{Kind: &queravuev1.SqlOperand_Literal{Literal: &queravuev1.SqlLiteral{Value: &queravuev1.SqlLiteral_StringValue{StringValue: "paid"}}}},
					},
				},
			},
		},
		GroupBy: []*queravuev1.SqlColumnRef{{TableAlias: "c", Column: "name"}},
		Having: &queravuev1.SqlCondition{
			Node: &queravuev1.SqlCondition_Comparison{
				Comparison: &queravuev1.SqlComparison{
					Left: &queravuev1.SqlOperand{
						Kind: &queravuev1.SqlOperand_Aggregate{
							Aggregate: &queravuev1.SqlAggregateExpr{
								Function: queravuev1.SqlAggregate_SQL_AGGREGATE_SUM,
								Column:   &queravuev1.SqlColumnRef{TableAlias: "o", Column: "amount"},
							},
						},
					},
					Op: queravuev1.SqlOperator_SQL_OPERATOR_GT,
					Operands: []*queravuev1.SqlOperand{
						{Kind: &queravuev1.SqlOperand_Literal{Literal: &queravuev1.SqlLiteral{Value: &queravuev1.SqlLiteral_IntValue{IntValue: 20}}}},
					},
				},
			},
		},
		OrderBy: []*queravuev1.SqlOrderTerm{
			{
				Expression: &queravuev1.SqlOperand{Kind: &queravuev1.SqlOperand_Column{Column: &queravuev1.SqlColumnRef{TableAlias: "c", Column: "name"}}},
				Descending: true,
			},
		},
		Limit: proto.Uint64(5),
	}

	genResp, err := qbSvc.GenerateSql(ctx, &queravuev1.GenerateSqlRequest{SessionId: sess.ID, Model: model})
	if err != nil {
		t.Fatalf("GenerateSql: %v", err)
	}
	if genResp.GetError() != nil {
		t.Fatalf("GenerateSql error: %v", genResp.GetError())
	}

	evs := execSQL(genResp.GetSql())
	var rows []*queravuev1.Row
	for _, ev := range evs {
		if r := ev.GetRows(); r != nil {
			rows = append(rows, r.GetRows()...)
		}
	}
	if len(rows) != 2 {
		t.Fatalf("rows = %d, want 2 (sql=%q)", len(rows), genResp.GetSql())
	}
	if rows[0].GetValues()[0].GetTextValue() != "Bob" || rows[1].GetValues()[0].GetTextValue() != "Alice" {
		t.Errorf("unexpected row order/names: %v, %v", rows[0].GetValues()[0], rows[1].GetValues()[0])
	}

	parseResp, err := qbSvc.ParseSql(ctx, &queravuev1.ParseSqlRequest{SessionId: sess.ID, Sql: genResp.GetSql()})
	if err != nil {
		t.Fatalf("ParseSql: %v", err)
	}
	if parseResp.GetError() != nil {
		t.Fatalf("ParseSql error: %v", parseResp.GetError())
	}
	if !proto.Equal(parseResp.GetModel(), model) {
		t.Errorf("round-trip model mismatch:\ngot:  %v\nwant: %v", parseResp.GetModel(), model)
	}
}

func TestQueryBuilderIntegrationSQLite(t *testing.T) {
	dbPath := filepath.Join(t.TempDir(), "qb.db")
	runQueryBuilderIntegration(t, "", func(ctx context.Context) (engine.Conn, engine.Descriptor, error) {
		e := sqlite.New()
		c, err := e.Connect(ctx, engine.Config{
			EngineID: e.Descriptor().ID,
			Params:   map[string]string{sqlite.ParamPath: dbPath, sqlite.ParamCreateIfMissing: "true"},
		}, engine.Secret{})
		return c, e.Descriptor(), err
	}, []string{
		"CREATE TABLE qb_customers (id INTEGER PRIMARY KEY, name TEXT NOT NULL)",
		"CREATE TABLE qb_orders (id INTEGER PRIMARY KEY, customer_id INTEGER NOT NULL REFERENCES qb_customers(id), status TEXT NOT NULL, amount INTEGER NOT NULL)",
		"INSERT INTO qb_customers (id, name) VALUES (1, 'Alice'), (2, 'Bob'), (3, 'Cara')",
		"INSERT INTO qb_orders (id, customer_id, status, amount) VALUES (1, 1, 'paid', 30), (2, 2, 'paid', 50), (3, 3, 'paid', 10), (4, 1, 'cancelled', 99)",
	})
}

func TestQueryBuilderIntegrationPostgres(t *testing.T) {
	suffix := fmt.Sprintf("qb_%d", time.Now().UnixNano())
	t.Cleanup(func() {
		e := postgres.New(postgres.VariantPostgres)
		c, err := e.Connect(context.Background(), engine.Config{
			EngineID: postgres.IDPostgres,
			Params: map[string]string{
				postgres.ParamHost: envOrDefault("PG_HOST", "127.0.0.1"), postgres.ParamPort: envOrDefault("PG_PORT", "5432"),
				postgres.ParamUser: envOrDefault("PG_USER", "queravue"), postgres.ParamDatabase: envOrDefault("PG_DB", "queravue"),
				postgres.ParamSSLMode: "disable",
			},
		}, engine.NewSecret(envOrDefault("PG_PASSWORD", "queravue")))
		if err == nil {
			defer func() { _ = c.Close() }()
			if ex, ok := engine.As[engine.Executor](c); ok {
				_, _ = ex.Execute(context.Background(), engine.Statement{SQL: "DROP SCHEMA IF EXISTS " + suffix + " CASCADE"}, nil)
			}
		}
	})
	runQueryBuilderIntegration(t, suffix, func(ctx context.Context) (engine.Conn, engine.Descriptor, error) {
		e := postgres.New(postgres.VariantPostgres)
		c, err := e.Connect(ctx, engine.Config{
			EngineID: postgres.IDPostgres,
			Params: map[string]string{
				postgres.ParamHost: envOrDefault("PG_HOST", "127.0.0.1"), postgres.ParamPort: envOrDefault("PG_PORT", "5432"),
				postgres.ParamUser: envOrDefault("PG_USER", "queravue"), postgres.ParamDatabase: envOrDefault("PG_DB", "queravue"),
				postgres.ParamSSLMode: "disable",
			},
		}, engine.NewSecret(envOrDefault("PG_PASSWORD", "queravue")))
		return c, e.Descriptor(), err
	}, []string{
		"CREATE SCHEMA " + suffix,
		"CREATE TABLE " + suffix + ".qb_customers (id INT PRIMARY KEY, name TEXT NOT NULL)",
		"CREATE TABLE " + suffix + ".qb_orders (id INT PRIMARY KEY, customer_id INT NOT NULL REFERENCES " + suffix + ".qb_customers(id), status TEXT NOT NULL, amount INT NOT NULL)",
		"INSERT INTO " + suffix + ".qb_customers (id, name) VALUES (1, 'Alice'), (2, 'Bob'), (3, 'Cara')",
		"INSERT INTO " + suffix + ".qb_orders (id, customer_id, status, amount) VALUES (1, 1, 'paid', 30), (2, 2, 'paid', 50), (3, 3, 'paid', 10), (4, 1, 'cancelled', 99)",
	})
}

func TestQueryBuilderIntegrationMySQL(t *testing.T) {
	db := envOrDefault("MYSQL_DB", "queravue")
	t.Cleanup(func() {
		e := mysql.New(mysql.VariantMySQL)
		c, err := e.Connect(context.Background(), engine.Config{
			EngineID: e.Descriptor().ID,
			Params: map[string]string{
				mysql.ParamHost: envOrDefault("MYSQL_HOST", "127.0.0.1"), mysql.ParamPort: envOrDefault("MYSQL_PORT", "3306"),
				mysql.ParamUser: envOrDefault("MYSQL_USER", "queravue"), mysql.ParamDatabase: db, mysql.ParamTLS: "disable",
			},
		}, engine.NewSecret(envOrDefault("MYSQL_PASSWORD", "queravue")))
		if err == nil {
			defer func() { _ = c.Close() }()
			if ex, ok := engine.As[engine.Executor](c); ok {
				_, _ = ex.Execute(context.Background(), engine.Statement{SQL: "DROP TABLE IF EXISTS qb_orders, qb_customers"}, nil)
			}
		}
	})
	runQueryBuilderIntegration(t, db, func(ctx context.Context) (engine.Conn, engine.Descriptor, error) {
		e := mysql.New(mysql.VariantMySQL)
		c, err := e.Connect(ctx, engine.Config{
			EngineID: e.Descriptor().ID,
			Params: map[string]string{
				mysql.ParamHost: envOrDefault("MYSQL_HOST", "127.0.0.1"), mysql.ParamPort: envOrDefault("MYSQL_PORT", "3306"),
				mysql.ParamUser: envOrDefault("MYSQL_USER", "queravue"), mysql.ParamDatabase: db, mysql.ParamTLS: "disable",
			},
		}, engine.NewSecret(envOrDefault("MYSQL_PASSWORD", "queravue")))
		return c, e.Descriptor(), err
	}, []string{
		"DROP TABLE IF EXISTS qb_orders, qb_customers",
		"CREATE TABLE qb_customers (id INT PRIMARY KEY, name VARCHAR(80) NOT NULL)",
		"CREATE TABLE qb_orders (id INT PRIMARY KEY, customer_id INT NOT NULL, status VARCHAR(40) NOT NULL, amount INT NOT NULL, FOREIGN KEY (customer_id) REFERENCES qb_customers(id))",
		"INSERT INTO qb_customers (id, name) VALUES (1, 'Alice'), (2, 'Bob'), (3, 'Cara')",
		"INSERT INTO qb_orders (id, customer_id, status, amount) VALUES (1, 1, 'paid', 30), (2, 2, 'paid', 50), (3, 3, 'paid', 10), (4, 1, 'cancelled', 99)",
	})
}
