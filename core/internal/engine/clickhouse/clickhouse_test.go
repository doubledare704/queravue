package clickhouse

import (
	"errors"
	"math/big"
	"net/netip"
	"reflect"
	"testing"
	"time"

	chdriver "github.com/ClickHouse/clickhouse-go/v2"
	"github.com/shopspring/decimal"

	"github.com/doubledare704/queravue/core/internal/engine"
)

func TestParseURI(t *testing.T) {
	tests := []struct {
		name, uri string
		want      map[string]string
		password  string
		wantErr   bool
	}{
		{"full", "clickhouse://alice:s3cret@db.example:9440/analytics?secure=true",
			map[string]string{ParamUser: "alice", ParamHost: "db.example", ParamPort: "9440", ParamDatabase: "analytics", ParamTLS: "verify"}, "s3cret", false},
		{"skip verify wins", "clickhouse://h?secure=true&skip_verify=true", map[string]string{ParamHost: "h", ParamTLS: "skip-verify"}, "", false},
		{"tcp scheme", "tcp://h:9000", map[string]string{ParamHost: "h", ParamPort: "9000"}, "", false},
		{"ipv6", "clickhouse://[::1]:9000", map[string]string{ParamHost: "::1", ParamPort: "9000"}, "", false},
		{"wrong scheme", "http://h:8123", nil, "", true},
		{"bad port", "clickhouse://h:99999", nil, "", true},
		{"bad bool", "clickhouse://h?secure=maybe", nil, "", true},
		{"empty", " ", nil, "", true},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, password, err := parseURI(tt.uri)
			if (err != nil) != tt.wantErr {
				t.Fatalf("err = %v, wantErr %v", err, tt.wantErr)
			}
			if tt.wantErr {
				return
			}
			if !reflect.DeepEqual(got, tt.want) || password != tt.password {
				t.Errorf("got %v / %q, want %v / %q", got, password, tt.want, tt.password)
			}
		})
	}
}

func TestParseURIErrorsDoNotEchoPassword(t *testing.T) {
	_, _, err := parseURI("clickhouse://u:hunter2@h:notaport")
	if err == nil || containsAny(err.Error(), "hunter2") {
		t.Fatalf("err = %v", err)
	}
}

func containsAny(s string, parts ...string) bool {
	for _, p := range parts {
		for i := 0; i+len(p) <= len(s); i++ {
			if s[i:i+len(p)] == p {
				return true
			}
		}
	}
	return false
}

func TestKindOf(t *testing.T) {
	tests := map[string]engine.ValueKind{
		"Int32":                                engine.VInt,
		"UInt8":                                engine.VInt,
		"UInt64":                               engine.VDecimal,
		"Int128":                               engine.VDecimal,
		"Nullable(Int32)":                      engine.VInt,
		"LowCardinality(String)":               engine.VText,
		"LowCardinality(Nullable(String))":     engine.VText,
		"Decimal(20, 4)":                       engine.VDecimal,
		"DateTime64(3, 'Europe/Kyiv')":         engine.VTimestamptz,
		"Nullable(DateTime)":                   engine.VTimestamptz,
		"Date":                                 engine.VText,
		"UUID":                                 engine.VUUID,
		"IPv4":                                 engine.VText,
		"Enum8('a' = 1, 'b' = 2)":              engine.VText,
		"Array(Nullable(String))":              engine.VArray,
		"Map(String, UInt32)":                  engine.VJSON,
		"Tuple(a Int32, b String)":             engine.VJSON,
		"JSON":                                 engine.VJSON,
		"Bool":                                 engine.VBool,
		"Float32":                              engine.VFloat,
		"SimpleAggregateFunction(sum, UInt64)": engine.VDecimal,
	}
	for typeName, want := range tests {
		if got := kindOf(typeName); got != want {
			t.Errorf("kindOf(%q) = %v, want %v", typeName, got, want)
		}
	}
}

func TestIsNullable(t *testing.T) {
	for typeName, want := range map[string]bool{
		"Nullable(Int32)": true, "LowCardinality(Nullable(String))": true, "Int32": false,
		"Array(Nullable(Int32))": false, "LowCardinality(String)": false,
	} {
		if got := isNullable(typeName); got != want {
			t.Errorf("isNullable(%q) = %v", typeName, got)
		}
	}
}

func TestConvert(t *testing.T) {
	kyiv := time.FixedZone("EET", 2*3600)
	moment := time.Date(2026, 1, 2, 3, 4, 5, 0, kyiv)
	var missing *int32
	seven := int32(7)
	tests := []struct {
		name, typeName string
		in             any
		want           engine.Value
	}{
		{"nil pointer is NULL", "Nullable(Int32)", missing, engine.Null()},
		{"pointer", "Nullable(Int32)", &seven, engine.Int(7)},
		{"small uint", "UInt64", uint64(5), engine.Int(5)},
		{"huge uint", "UInt64", uint64(18446744073709551615), engine.Decimal("18446744073709551615")},
		{"big int", "Int128", big.NewInt(-1), engine.Decimal("-1")},
		{"decimal", "Decimal(10, 2)", decimal.RequireFromString("12.50"), engine.Decimal("12.5")},
		{"datetime", "DateTime64(3)", moment, engine.Timestamptz(moment)},
		{"date", "Date", moment, engine.Text("2026-01-02")},
		{"ip", "IPv6", netip.MustParseAddr("2001:db8::1"), engine.Text("2001:db8::1")},
		{"string", "String", "x", engine.Text("x")},
		{"bool", "Bool", true, engine.Bool(true)},
		{"float", "Float64", 1.5, engine.Float(1.5)},
		{"map", "Map(String, UInt32)", map[string]uint32{"k": 2}, engine.JSON(`{"k":2}`)},
		{"array", "Array(Int32)", []int32{1, 2}, engine.Array([]engine.Value{engine.Int(1), engine.Int(2)})},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := convert(tt.typeName, reflect.ValueOf(&tt.in).Elem())
			if got.Kind != tt.want.Kind || got.Str != tt.want.Str || got.Int != tt.want.Int || got.Bool != tt.want.Bool ||
				got.Float != tt.want.Float || !got.Time.Equal(tt.want.Time) || len(got.Array) != len(tt.want.Array) {
				t.Errorf("got %+v, want %+v", got, tt.want)
			}
		})
	}
}

func TestClassify(t *testing.T) {
	secret := engine.NewSecret("hunter2")
	tests := []struct {
		name string
		err  error
		want engine.Kind
	}{
		{"wrong password", &chdriver.Exception{Code: codeWrongPassword, Message: "bad hunter2"}, engine.KindAuth},
		{"unknown database", &chdriver.Exception{Code: codeUnknownDatabase, Message: "no db"}, engine.KindNotFound},
		{"cancelled", &chdriver.Exception{Code: codeQueryWasCancelled, Message: "cancelled"}, engine.KindCanceled},
		{"syntax", &chdriver.Exception{Code: 62, Message: "syntax"}, engine.KindSQL},
		{"timeout", &chdriver.Exception{Code: codeTimeoutExceeded, Message: "slow"}, engine.KindTimeout},
		{"certificate", errors.New("x509: certificate signed by unknown authority"), engine.KindTLS},
	}
	for _, tt := range tests {
		got := classify(ID, "op", tt.err, secret)
		if got.Kind != tt.want {
			t.Errorf("%s: kind = %v, want %v", tt.name, got.Kind, tt.want)
		}
		if containsAny(got.Msg, "hunter2") {
			t.Errorf("%s: message leaks the secret: %q", tt.name, got.Msg)
		}
	}
}

func TestReturnsRows(t *testing.T) {
	for sql, want := range map[string]bool{
		"SELECT 1": true, "  select 1": true, "(SELECT 1)": true, "WITH x AS (SELECT 1) SELECT * FROM x": true,
		"-- note\nSHOW TABLES": true, "/* c */ DESCRIBE t": true, "# hash\nEXPLAIN SELECT 1": true,
		"INSERT INTO t VALUES (1)": false, "CREATE TABLE t (a Int8) ENGINE = Memory": false, "OPTIMIZE TABLE t": false,
		"ALTER TABLE t DELETE WHERE 1": false, "": false,
	} {
		if got := returnsRows(sql); got != want {
			t.Errorf("returnsRows(%q) = %v", sql, got)
		}
	}
}

func TestSplitTopLevel(t *testing.T) {
	got := splitTopLevel("a, toYYYYMM(dt), `b`, f(x, y)")
	want := []string{"a", "toYYYYMM(dt)", "`b`", "f(x, y)"}
	if !reflect.DeepEqual(got, want) {
		t.Errorf("got %q, want %q", got, want)
	}
	if got := splitTopLevel(""); len(got) != 0 {
		t.Errorf("empty key = %q", got)
	}
}

func TestKeyColumnOrder(t *testing.T) {
	got := keyColumnOrder("order_id, `item_id`, toDate(ts), name")
	want := map[string]int{"order_id": 1, "item_id": 2, "name": 4}
	if !reflect.DeepEqual(got, want) {
		t.Errorf("got %v, want %v", got, want)
	}
}

func TestTLSConfigFor(t *testing.T) {
	cases := map[string]struct {
		nilConfig, skipVerify bool
	}{"disable": {nilConfig: true}, "skip-verify": {skipVerify: true}, "verify": {}}
	for mode, want := range cases {
		cfg, err := tlsConfigFor(engine.Config{Params: map[string]string{ParamTLS: mode, ParamHost: "db.example"}})
		if err != nil {
			t.Fatal(err)
		}
		if (cfg == nil) != want.nilConfig {
			t.Fatalf("%s: config nil = %v", mode, cfg == nil)
		}
		if cfg != nil && (cfg.InsecureSkipVerify != want.skipVerify || (mode == "verify" && cfg.ServerName != "db.example")) {
			t.Errorf("%s: config = %+v", mode, cfg)
		}
	}
}

func TestDescriptor(t *testing.T) {
	d := New().Descriptor()
	for _, capability := range []engine.Capability{engine.CapExecute, engine.CapSchemaInspector, engine.CapSchemaGraph, engine.CapCompletion, engine.CapFormat} {
		if !d.HasCapability(capability) {
			t.Errorf("missing capability %s", capability)
		}
	}
	for _, capability := range []engine.Capability{engine.CapIndexManager, engine.CapStats, engine.CapDocumentStore} {
		if d.HasCapability(capability) {
			t.Errorf("must not report %s", capability)
		}
	}
	cfg := d.WithDefaults(engine.Config{EngineID: ID})
	if cfg.Param(ParamPort, "") != "9000" || cfg.Param(ParamTLS, "") != "disable" {
		t.Errorf("defaults = %v", cfg.Params)
	}
	if err := d.Validate(engine.Config{Params: map[string]string{ParamTLS: "bogus"}}); engine.KindOf(err) != engine.KindInvalidConfig {
		t.Errorf("bad tls mode err = %v", err)
	}
}
