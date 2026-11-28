//go:build integration

package api_test

import (
	"context"
	"fmt"
	"path/filepath"
	"slices"
	"strings"
	"testing"
	"time"

	mongodrv "go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"

	"github.com/doubledare704/queravue/core/internal/dataformat"
	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/engine/mysql"
	"github.com/doubledare704/queravue/core/internal/engine/postgres"
	"github.com/doubledare704/queravue/core/internal/engine/sqlite"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/sqldialect"
)

type sqlTarget struct {
	name   string
	open   func(t *testing.T) engine.Conn
	schema string
	create string
}

func connectEngine(t *testing.T, e engine.Engine, cfg engine.Config, secret engine.Secret) engine.Conn {
	t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	conn, err := e.Connect(ctx, cfg, secret)
	if err != nil {
		t.Fatalf("connect %s: %v (docker compose -f dev/docker-compose.yml up -d --wait)", e.Descriptor().ID, err)
	}
	t.Cleanup(func() { _ = conn.Close() })
	return conn
}

func sqlTargets() []sqlTarget {
	pgParams := map[string]string{
		postgres.ParamHost: "127.0.0.1", postgres.ParamPort: "5432", postgres.ParamUser: "queravue",
		postgres.ParamDatabase: "queravue", postgres.ParamSSLMode: "disable",
	}
	pgDDL := "CREATE TABLE %s (id bigint PRIMARY KEY, name text, amount numeric(12,2), score double precision, active boolean, created timestamptz, note text, payload bytea)"
	return []sqlTarget{
		{name: "postgres", schema: "public", create: pgDDL, open: func(t *testing.T) engine.Conn {
			return connectEngine(t, postgres.New(postgres.VariantPostgres), engine.Config{EngineID: postgres.IDPostgres, Params: pgParams}, engine.NewSecret("queravue"))
		}},
		{name: "cockroachdb", schema: "public", create: pgDDL, open: func(t *testing.T) engine.Conn {
			return connectEngine(t, postgres.New(postgres.VariantCockroach), engine.Config{EngineID: postgres.IDCockroach, Params: map[string]string{
				postgres.ParamHost: "127.0.0.1", postgres.ParamPort: "26257", postgres.ParamUser: "root", postgres.ParamDatabase: "queravue", postgres.ParamSSLMode: "disable",
			}}, engine.Secret{})
		}},
		{name: "mysql", schema: "queravue", open: func(t *testing.T) engine.Conn {
			return connectEngine(t, mysql.New(mysql.VariantMySQL), engine.Config{EngineID: mysql.IDMySQL, Params: map[string]string{
				mysql.ParamHost: "127.0.0.1", mysql.ParamPort: "3306", mysql.ParamUser: "queravue", mysql.ParamDatabase: "queravue", mysql.ParamTLS: "disable",
			}}, engine.NewSecret("queravue"))
		}, create: "CREATE TABLE %s (id bigint PRIMARY KEY, name text, amount decimal(12,2), score double, active boolean, created datetime(6), note text, payload blob)"},
		{name: "sqlite", schema: "main", open: func(t *testing.T) engine.Conn {
			return connectEngine(t, sqlite.New(), engine.Config{EngineID: sqlite.ID, Params: map[string]string{
				sqlite.ParamPath: filepath.Join(t.TempDir(), "xfer.db"), sqlite.ParamCreateIfMissing: "true",
			}}, engine.Secret{})
		}, create: "CREATE TABLE %s (id integer PRIMARY KEY, name text, amount numeric, score real, active integer, created text, note text, payload blob)"},
	}
}

type collectedRows struct{ rows [][]engine.Value }

func (*collectedRows) Columns([]engine.Column) error { return nil }
func (c *collectedRows) Batch(rows [][]engine.Value) error {
	for _, r := range rows {
		c.rows = append(c.rows, append([]engine.Value(nil), r...))
	}
	return nil
}

func run(t *testing.T, conn engine.Conn, sql string, params ...engine.Value) *collectedRows {
	t.Helper()
	sink := &collectedRows{}
	ctx, cancel := context.WithTimeout(context.Background(), time.Minute)
	defer cancel()
	if _, err := conn.(engine.Executor).Execute(ctx, engine.Statement{SQL: sql, Params: params}, sink); err != nil {
		t.Fatalf("%s: %v", sql, err)
	}
	return sink
}

const fixtureRows = 1200

func seed(t *testing.T, tg sqlTarget, conn engine.Conn, table string) {
	t.Helper()
	d := conn.(interface{ Dialect() sqldialect.Dialect }).Dialect()
	insert := fmt.Sprintf("INSERT INTO %s (id, name, amount, score, active, created, note, payload) VALUES (%s)", table,
		strings.Join([]string{d.Placeholder(1), d.Placeholder(2), d.Placeholder(3), d.Placeholder(4), d.Placeholder(5), d.Placeholder(6), d.Placeholder(7), d.Placeholder(8)}, ", "))
	stamp := time.Date(2024, 2, 29, 12, 0, 0, 0, time.UTC)
	for i := 1; i <= fixtureRows; i++ {
		name := engine.Text(fmt.Sprintf("name %d", i))
		switch i % 10 {
		case 1:
			name = engine.Text("Ada, \"the\" first\nline two é∑")
		case 2:
			name = engine.Text("")
		case 3:
			name = engine.Text("NULL")
		case 4:
			name = engine.Null()
		}
		note := engine.Text("note")
		if i%7 == 0 {
			note = engine.Null()
		}
		run(t, conn, insert, engine.Int(int64(i)), name, engine.Decimal(fmt.Sprintf("%d.%02d", i, i%100)), engine.Float(float64(i)/4),
			boolParam(tg, i%2 == 0), engine.Timestamptz(stamp.Add(time.Duration(i)*time.Minute)), note, engine.Bytes([]byte{0, byte(i), 0xff}))
	}
}

func boolParam(tg sqlTarget, v bool) engine.Value {
	if tg.name == "sqlite" || tg.name == "mysql" {
		return engine.Int(map[bool]int64{false: 0, true: 1}[v])
	}
	return engine.Bool(v)
}

func multiset(t *testing.T, conn engine.Conn, table string) []string {
	t.Helper()
	rows := run(t, conn, "SELECT id, name, amount, score, active, created, note, payload FROM "+table).rows
	out := make([]string, len(rows))
	for i, row := range rows {
		cells := make([]string, len(row))
		for j, v := range row {
			cells[j] = fmt.Sprintf("%d:%s", v.Kind, dataformat.ValueText(v))
			if v.Kind == engine.VNull {
				cells[j] = "null"
			}
		}
		out[i] = strings.Join(cells, "\x1f")
	}
	slices.Sort(out)
	return out
}

func qualify(tg sqlTarget, conn engine.Conn, name string) string {
	return conn.(interface{ Dialect() sqldialect.Dialect }).Dialect().QualifyTable(tg.schema, name)
}

func roundTripFormats() map[string]*queravuev1.ExportOptions {
	return map[string]*queravuev1.ExportOptions{
		"csv":    {Format: queravuev1.TransferFormat_TRANSFER_FORMAT_CSV, FormatOptions: csvOptions(true)},
		"tsv":    {Format: queravuev1.TransferFormat_TRANSFER_FORMAT_TSV, FormatOptions: csvOptions(true)},
		"json":   {Format: queravuev1.TransferFormat_TRANSFER_FORMAT_JSON},
		"ndjson": {Format: queravuev1.TransferFormat_TRANSFER_FORMAT_NDJSON},
		"sql":    {Format: queravuev1.TransferFormat_TRANSFER_FORMAT_SQL, FormatOptions: &queravuev1.TransferFormatOptions{SqlTargetTable: "qv_xfer_dst"}},
	}
}

func TestIntegrationRoundTripPerEngineAndFormat(t *testing.T) {
	for _, tg := range sqlTargets() {
		t.Run(tg.name, func(t *testing.T) {
			conn := tg.open(t)
			env := newXferEnv(t, conn, false)
			src, dst := qualify(tg, conn, "qv_xfer_src"), qualify(tg, conn, "qv_xfer_dst")
			for _, name := range []string{src, dst} {
				run(t, conn, "DROP TABLE IF EXISTS "+name)
				run(t, conn, fmt.Sprintf(tg.create, name))
				t.Cleanup(func() { run(t, conn, "DROP TABLE IF EXISTS "+name) })
			}
			seed(t, tg, conn, src)
			want := multiset(t, conn, src)

			for name, options := range roundTripFormats() {
				t.Run(name, func(t *testing.T) {
					run(t, conn, "DELETE FROM "+dst)
					out := env.exportTable(t, &queravuev1.ExportTableRequest{
						Table: &queravuev1.TableRef{Schema: tg.schema, Table: "qv_xfer_src"}, Options: options,
						Sort: []*queravuev1.SortClause{{Column: "id"}},
					})
					if out.err != nil || out.summary.GetRows() != fixtureRows {
						t.Fatalf("export: err = %v, summary = %v", out.err, out.summary)
					}
					hdr := &queravuev1.ImportHeader{
						Target: &queravuev1.ImportHeader_ExistingTable{ExistingTable: &queravuev1.TableRef{Schema: tg.schema, Table: "qv_xfer_dst"}},
						Format: options.GetFormat(), FormatOptions: options.GetFormatOptions(),
					}
					res := env.runImport(t, hdr, string(out.body), 64<<10)
					if res.err != nil {
						t.Fatalf("import: %v (summary %v)", res.err, res.summary)
					}
					if got := multiset(t, conn, dst); !slices.Equal(got, want) {
						t.Fatalf("rows differ after the %s round trip: %d rows, want %d\nfirst difference: %s", name, len(got), len(want), firstDifference(got, want))
					}
				})
			}
		})
	}
}

func firstDifference(got, want []string) string {
	for i := range min(len(got), len(want)) {
		if got[i] != want[i] {
			return fmt.Sprintf("got %q\nwant %q", got[i], want[i])
		}
	}
	return fmt.Sprintf("lengths %d and %d", len(got), len(want))
}

func TestIntegrationInferThenImportIntoANewTable(t *testing.T) {
	for _, tg := range sqlTargets() {
		t.Run(tg.name, func(t *testing.T) {
			conn := tg.open(t)
			env := newXferEnv(t, conn, false)
			src := qualify(tg, conn, "qv_xfer_src")
			fresh := qualify(tg, conn, "qv_xfer_fresh")
			for _, name := range []string{src, fresh} {
				run(t, conn, "DROP TABLE IF EXISTS "+name)
			}
			run(t, conn, fmt.Sprintf(tg.create, src))
			seed(t, tg, conn, src)
			t.Cleanup(func() {
				run(t, conn, "DROP TABLE IF EXISTS "+src)
				run(t, conn, "DROP TABLE IF EXISTS "+fresh)
			})
			out := env.exportTable(t, &queravuev1.ExportTableRequest{
				Table:   &queravuev1.TableRef{Schema: tg.schema, Table: "qv_xfer_src"},
				Columns: []string{"id", "name", "amount", "score", "created"},
				Options: &queravuev1.ExportOptions{Format: queravuev1.TransferFormat_TRANSFER_FORMAT_CSV, FormatOptions: csvOptions(true)},
			})
			inferred := env.infer(t, &queravuev1.InferImportHeader{Filename: "src.csv"}, string(out.body))
			if inferred.GetError() != nil || len(inferred.GetColumns()) != 5 {
				t.Fatalf("infer: %v", inferred)
			}
			nt := &queravuev1.NewTable{Table: &queravuev1.TableRef{Schema: tg.schema, Table: "qv_xfer_fresh"}}
			for _, c := range inferred.GetColumns() {
				nt.Columns = append(nt.Columns, &queravuev1.ColumnDetails{
					Name: c.GetName(), TypeName: c.GetSuggestedTypeName(), Kind: c.GetInferredKind(), Nullable: true,
				})
			}
			hdr := &queravuev1.ImportHeader{
				Target: &queravuev1.ImportHeader_NewTable{NewTable: nt}, Format: inferred.GetFormat(), FormatOptions: inferred.GetFormatOptions(),
			}
			res := env.runImport(t, hdr, string(out.body), 32<<10)
			if res.err != nil || res.summary.GetRowsCommitted() != fixtureRows || res.summary.GetDdl() == "" {
				t.Fatalf("err = %v, summary = %v", res.err, res.summary)
			}
			count := run(t, conn, "SELECT COUNT(*) FROM "+fresh).rows[0][0]
			if count.Int != fixtureRows {
				t.Errorf("%d rows in the new table", count.Int)
			}
			sum := run(t, conn, "SELECT SUM(id) FROM "+fresh).rows[0][0]
			if dataformat.ValueText(sum) != fmt.Sprint(fixtureRows*(fixtureRows+1)/2) {
				t.Errorf("sum(id) = %s", dataformat.ValueText(sum))
			}
		})
	}
}

func TestIntegrationPostgresErrorPoliciesCancelAndDumpImport(t *testing.T) {
	tg := sqlTargets()[0]
	conn := tg.open(t)
	env := newXferEnv(t, conn, false)
	table := qualify(tg, conn, "qv_xfer_policy")
	run(t, conn, "DROP TABLE IF EXISTS "+table)
	run(t, conn, fmt.Sprintf("CREATE TABLE %s (id bigint PRIMARY KEY, name text)", table))
	t.Cleanup(func() { run(t, conn, "DROP TABLE IF EXISTS "+table) })
	count := func() int64 { return run(t, conn, "SELECT COUNT(*) FROM "+table).rows[0][0].Int }
	header := func() *queravuev1.ImportHeader {
		return &queravuev1.ImportHeader{
			Target: &queravuev1.ImportHeader_ExistingTable{ExistingTable: &queravuev1.TableRef{Schema: "public", Table: "qv_xfer_policy"}},
			Format: queravuev1.TransferFormat_TRANSFER_FORMAT_CSV, FormatOptions: csvOptions(true),
		}
	}

	hdr := header()
	hdr.ErrorPolicy = queravuev1.ImportErrorPolicy_IMPORT_ERROR_POLICY_SKIP
	res := env.runImport(t, hdr, "id,name\n1,a\n2,b\n2,dup\nx,bad\n4,d\n", 8)
	if res.err != nil || res.summary.GetRowsCommitted() != 3 || res.summary.GetRowsSkipped() != 2 || count() != 3 {
		t.Fatalf("skip: err = %v, summary = %v, rows = %d", res.err, res.summary, count())
	}
	lines := []uint64{}
	for _, e := range res.summary.GetRowErrors() {
		lines = append(lines, e.GetLine())
		if strings.Contains(e.GetMessage(), "(2)") {
			t.Errorf("row error quotes data: %q", e.GetMessage())
		}
	}
	if !slices.Equal(lines, []uint64{4, 5}) {
		t.Errorf("row error lines = %v", lines)
	}

	run(t, conn, "DELETE FROM "+table)
	res = env.runImport(t, header(), "id,name\n1,a\n1,b\n", 8)
	if res.err.GetKind() != queravuev1.TransferErrorKind_TRANSFER_ERROR_KIND_CONSTRAINT || count() != 0 {
		t.Errorf("stop on constraint: err = %v, rows = %d", res.err, count())
	}

	var big strings.Builder
	big.WriteString("id,name\n")
	for i := 1; i <= 120_000; i++ {
		fmt.Fprintf(&big, "%d,name %d\n", i, i)
	}
	ctx, cancel := context.WithCancel(context.Background())
	h := header()
	h.SessionId = env.session.ID
	s := &importStream{ctx: ctx, in: importMessages(h, big.String(), 8<<10)}
	s.onRecv = func(n int) {
		if n == 120 {
			cancel()
		}
	}
	if err := env.svc.Import(s); err != nil {
		t.Fatal(err)
	}
	res = collectImport(s.out)
	if res.err.GetKind() != queravuev1.TransferErrorKind_TRANSFER_ERROR_KIND_CANCELED {
		t.Fatalf("cancel: err = %v", res.err)
	}
	committed := count()
	if committed == 0 || committed >= 120_000 || uint64(committed) != res.summary.GetRowsCommitted() {
		t.Errorf("cancelled import: %d rows in the table, summary says %d", committed, res.summary.GetRowsCommitted())
	}

	run(t, conn, "DELETE FROM "+table)
	script := "INSERT INTO qv_xfer_policy VALUES (1, 'a;b');\nINSERT INTO qv_xfer_policy VALUES (2, 'c');\nINSERT INTO qv_xfer_policy VALUES (2, 'dup');\nINSERT INTO qv_xfer_policy VALUES (9, 'never');\n"
	res = env.runImport(t, &queravuev1.ImportHeader{Format: queravuev1.TransferFormat_TRANSFER_FORMAT_SQL}, script, 17)
	if res.err.GetKind() != queravuev1.TransferErrorKind_TRANSFER_ERROR_KIND_SERVER || !strings.Contains(res.err.GetMessage(), "line 3") || count() != 2 {
		t.Errorf("dump import: err = %v, rows = %d", res.err, count())
	}
}

func mongoDocs(count int, withInt64 bool) []engine.Document {
	docs := make([]engine.Document, count)
	for i := range docs {
		big := ""
		if withInt64 {
			big = fmt.Sprintf(`"big":{"$numberLong":"%d"},`, int64(i)*1_000_000_007)
		}
		docs[i] = fmt.Sprintf(`{"_id":{"$numberInt":"%d"},"name":"user %d é\n\"q\"",%s"score":{"$numberDouble":"%d.5"},"price":{"$numberDecimal":"%d.10"},`+
			`"at":{"$date":{"$numberLong":"%d"}},"tags":["a","b",{"$numberInt":"%d"}],"profile":{"city":"X","zip":null},"ok":true,"bin":{"$binary":{"base64":"AAEC","subType":"00"}}}`,
			i+1, i+1, big, i, i, int64(1709208000000)+int64(i)*60000, i)
	}
	return docs
}

type collectDocs struct{ docs []engine.Document }

func (c *collectDocs) Batch(docs []engine.Document) error {
	c.docs = append(c.docs, docs...)
	return nil
}

func findAll(t *testing.T, ds engine.DocumentStore, database, collection string) []engine.Document {
	t.Helper()
	sink := &collectDocs{}
	if err := ds.Find(context.Background(), engine.FindOptions{Database: database, Collection: collection, Sort: `{"_id":1}`}, sink); err != nil {
		t.Fatal(err)
	}
	return sink.docs
}

func TestIntegrationMongoRoundTripPerFormat(t *testing.T) {
	conn := connectMongo(t)
	ds := conn.(engine.DocumentStore)
	env := newXferEnv(t, conn, false)
	const database = "qv_xfer"
	ctx := context.Background()
	for _, flavor := range []queravuev1.JsonFlavor{queravuev1.JsonFlavor_JSON_FLAVOR_CANONICAL, queravuev1.JsonFlavor_JSON_FLAVOR_RELAXED} {
		for _, format := range []queravuev1.TransferFormat{queravuev1.TransferFormat_TRANSFER_FORMAT_JSON, queravuev1.TransferFormat_TRANSFER_FORMAT_NDJSON} {
			t.Run(flavor.String()+"/"+format.String(), func(t *testing.T) {
				src, dst := "src_"+strings.ToLower(format.String()), "dst_"+strings.ToLower(format.String())
				seedDocs := mongoDocs(1200, flavor == queravuev1.JsonFlavor_JSON_FLAVOR_CANONICAL)
				for i := 0; i < len(seedDocs); i += 400 {
					if _, err := ds.Insert(ctx, database, src, seedDocs[i:i+400], engine.WriteOptions{}); err != nil {
						t.Fatal(err)
					}
				}
				t.Cleanup(func() { dropCollections(t, conn, database, src, dst) })
				rec := &exportRecorder[*queravuev1.ExportCollectionResponse]{}
				err := env.svc.ExportCollection(&queravuev1.ExportCollectionRequest{
					SessionId: env.session.ID, Collection: &queravuev1.CollectionRef{Database: database, Collection: src},
					Options: &queravuev1.ExportOptions{Format: format, FormatOptions: &queravuev1.TransferFormatOptions{JsonFlavor: flavor}},
				}, rec)
				out := collectExport(rec.events)
				if err != nil || out.err != nil || out.summary.GetRows() != 1200 {
					t.Fatalf("export: %v %v %v", err, out.err, out.summary)
				}
				res := env.runImport(t, &queravuev1.ImportHeader{
					Target: &queravuev1.ImportHeader_Collection{Collection: &queravuev1.CollectionRef{Database: database, Collection: dst}},
					Format: format,
				}, string(out.body), 48<<10)
				if res.err != nil || res.summary.GetRowsCommitted() != 1200 {
					t.Fatalf("import: %v %v", res.err, res.summary)
				}
				want, got := findAll(t, ds, database, src), findAll(t, ds, database, dst)
				if !slices.Equal(got, want) {
					t.Fatalf("documents differ: %d vs %d\n%s", len(got), len(want), firstDifference(got, want))
				}
			})
		}
	}
}

func TestIntegrationMongoCSVExportAndFlatImport(t *testing.T) {
	conn := connectMongo(t)
	ds := conn.(engine.DocumentStore)
	env := newXferEnv(t, conn, false)
	const database, src, dst = "qv_xfer", "csv_src", "csv_dst"
	if _, err := ds.Insert(context.Background(), database, src, mongoDocs(50, true), engine.WriteOptions{}); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { dropCollections(t, conn, database, src, dst) })
	rec := &exportRecorder[*queravuev1.ExportCollectionResponse]{}
	err := env.svc.ExportCollection(&queravuev1.ExportCollectionRequest{
		SessionId: env.session.ID, Collection: &queravuev1.CollectionRef{Database: database, Collection: src},
		SortEjson: `{"_id":1}`, FieldPaths: []string{"_id", "name", "profile.city", "tags", "at"},
		Options: &queravuev1.ExportOptions{Format: queravuev1.TransferFormat_TRANSFER_FORMAT_CSV, FormatOptions: csvOptions(true)},
	}, rec)
	out := collectExport(rec.events)
	if err != nil || out.err != nil || out.summary.GetRows() != 50 {
		t.Fatalf("export: %v %v %v", err, out.err, out.summary)
	}
	res := env.runImport(t, &queravuev1.ImportHeader{
		Target: &queravuev1.ImportHeader_Collection{Collection: &queravuev1.CollectionRef{Database: database, Collection: dst}},
		Format: queravuev1.TransferFormat_TRANSFER_FORMAT_CSV, FormatOptions: csvOptions(true),
	}, string(out.body), 4096)
	if res.err != nil || res.summary.GetRowsCommitted() != 50 {
		t.Fatalf("import: %v %v", res.err, res.summary)
	}
	docs := findAllBy(t, ds, database, dst)
	if len(docs) != 50 || !strings.Contains(docs[0], `"profile.city":"X"`) || !strings.Contains(docs[0], `"tags":"[`) {
		t.Errorf("first flat document = %s", docs[0])
	}
}

func findAllBy(t *testing.T, ds engine.DocumentStore, database, collection string) []engine.Document {
	t.Helper()
	sink := &collectDocs{}
	if err := ds.Find(context.Background(), engine.FindOptions{Database: database, Collection: collection, Sort: `{"name":1}`}, sink); err != nil {
		t.Fatal(err)
	}
	return sink.docs
}

func connectMongo(t *testing.T) engine.Conn {
	t.Helper()
	conn, _, err := mongoTestOpener{}.Open(context.Background(), "c")
	if err != nil {
		t.Fatalf("connect mongo: %v (docker compose -f dev/docker-compose.yml up -d --wait mongo)", err)
	}
	t.Cleanup(func() { _ = conn.Close() })
	return conn
}

func dropCollections(t *testing.T, _ engine.Conn, database string, names ...string) {
	t.Helper()
	cl, err := mongodrv.Connect(options.Client().ApplyURI("mongodb://" + mongoHostPort() + "/?replicaSet=rs0"))
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = cl.Disconnect(context.Background()) }()
	for _, n := range names {
		_ = cl.Database(database).Collection(n).Drop(context.Background())
	}
}
