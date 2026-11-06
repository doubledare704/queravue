//go:build integration

package postgres_test

import (
	"context"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/engine/postgres"
)

func pgConfig() (engine.Config, engine.Secret) {
	return engine.Config{
		EngineID: postgres.IDPostgres,
		Params: map[string]string{
			postgres.ParamHost:     "127.0.0.1",
			postgres.ParamPort:     "5432",
			postgres.ParamUser:     "queravue",
			postgres.ParamDatabase: "queravue",
			postgres.ParamSSLMode:  "disable",
		},
	}, engine.NewSecret("queravue")
}

func connectPG(t *testing.T) engine.Conn {
	t.Helper()
	e := postgres.New(postgres.VariantPostgres)
	cfg, sec := pgConfig()
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	c, err := e.Connect(ctx, cfg, sec)
	if err != nil {
		t.Fatalf("connect pg: %v (make db-up)", err)
	}
	t.Cleanup(func() { _ = c.Close() })
	return c
}

func TestIntegration_SchemaInspector_Postgres(t *testing.T) {
	conn := connectPG(t)
	inspector, ok := engine.As[engine.SchemaInspector](conn)
	if !ok {
		t.Fatal("postgres Conn does not implement SchemaInspector")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	// 1. ListDatabases
	dbs, err := inspector.ListDatabases(ctx)
	if err != nil {
		t.Fatalf("ListDatabases: %v", err)
	}
	var foundDB bool
	for _, db := range dbs {
		if db == "queravue" {
			foundDB = true
			break
		}
	}
	if !foundDB {
		t.Errorf("queravue not found in databases: %v", dbs)
	}

	// 2. ListSchemas
	schemas, err := inspector.ListSchemas(ctx, "queravue")
	if err != nil {
		t.Fatalf("ListSchemas: %v", err)
	}
	var foundPublic bool
	for _, s := range schemas {
		if s == "public" {
			foundPublic = true
			break
		}
	}
	if !foundPublic {
		t.Errorf("public schema not found: %v", schemas)
	}

	// 3. ListObjects
	objs, err := inspector.ListObjects(ctx, "queravue", "public")
	if err != nil {
		t.Fatalf("ListObjects: %v", err)
	}
	objMap := make(map[string]engine.SchemaObject)
	for _, o := range objs {
		objMap[o.Name] = o
	}

	expectedObjects := map[string]engine.ObjectType{
		"customers":                   engine.ObjectTypeTable,
		"orders":                      engine.ObjectTypeTable,
		"order_items":                 engine.ObjectTypeTable,
		"logs_no_pk":                  engine.ObjectTypeTable,
		"пользователи":                engine.ObjectTypeTable,
		"café":                        engine.ObjectTypeTable,
		"million_items":               engine.ObjectTypeTable,
		"customer_order_summary_view": engine.ObjectTypeView,
		"monthly_sales_matview":       engine.ObjectTypeMaterializedView,
	}

	for name, wantType := range expectedObjects {
		obj, ok := objMap[name]
		if !ok {
			t.Errorf("missing object %q in ListObjects", name)
			continue
		}
		if obj.Type != wantType {
			t.Errorf("object %q type = %v, want %v", name, obj.Type, wantType)
		}
	}

	// Verify reltuples row count estimate on million_items
	millionObj, ok := objMap["million_items"]
	if !ok || millionObj.EstimatedRows < 900000 {
		t.Errorf("million_items estimated rows = %d, want ~1,000,000", millionObj.EstimatedRows)
	}

	// 4. DescribeTable on composite PK table with foreign keys
	orderItemsDetails, err := inspector.DescribeTable(ctx, "queravue", "public", "order_items")
	if err != nil {
		t.Fatalf("DescribeTable(order_items): %v", err)
	}
	if !orderItemsDetails.CanEdit {
		t.Errorf("order_items should be editable (composite PK)")
	}
	var pkCount int
	for _, c := range orderItemsDetails.Columns {
		if c.IsPrimaryKey {
			pkCount++
		}
	}
	if pkCount != 2 {
		t.Errorf("order_items has %d PK columns, want 2", pkCount)
	}
	if len(orderItemsDetails.ForeignKeys) == 0 {
		t.Errorf("order_items missing foreign key to orders")
	}

	// 5. DescribeTable on table with no PK
	logsDetails, err := inspector.DescribeTable(ctx, "queravue", "public", "logs_no_pk")
	if err != nil {
		t.Fatalf("DescribeTable(logs_no_pk): %v", err)
	}
	if logsDetails.CanEdit {
		t.Errorf("logs_no_pk should be read-only")
	}
	if logsDetails.EditDisabledReason == "" {
		t.Errorf("logs_no_pk should have EditDisabledReason")
	}

	// 6. DescribeTable on unicode tables
	cyrillicDetails, err := inspector.DescribeTable(ctx, "queravue", "public", "пользователи")
	if err != nil {
		t.Fatalf("DescribeTable(пользователи): %v", err)
	}
	if !cyrillicDetails.CanEdit || len(cyrillicDetails.Columns) != 3 {
		t.Errorf("пользователи details unexpected: %+v", cyrillicDetails)
	}

	// 7. DescribeTable on views and materialized views
	matviewDetails, err := inspector.DescribeTable(ctx, "queravue", "public", "monthly_sales_matview")
	if err != nil {
		t.Fatalf("DescribeTable(monthly_sales_matview): %v", err)
	}
	if matviewDetails.Type != engine.ObjectTypeMaterializedView {
		t.Errorf("monthly_sales_matview type = %v, want matview", matviewDetails.Type)
	}
	if matviewDetails.CanEdit {
		t.Errorf("materialized views must be read-only")
	}
}
