package oracle

import (
	"database/sql"
	"errors"
	"reflect"
	"strings"
	"testing"
	"time"

	"github.com/sijms/go-ora/v2/network"

	"github.com/doubledare704/queravue/core/internal/engine"
)

func TestParseConnString(t *testing.T) {
	tests := []struct {
		name, in string
		want     map[string]string
		pw       string
		wantErr  bool
	}{
		{"url", "oracle://scott:tiger@db.example:1522/ORCLPDB1", map[string]string{"user": "scott", "host": "db.example", "port": "1522", "service_name": "ORCLPDB1"}, "tiger", false},
		{"url with sid and role", "oracle://sys:pw@h/?sid=XE&role=SYSDBA", map[string]string{"user": "sys", "host": "h", "sid": "XE", "role": "sysdba"}, "pw", false},
		{"url with tls and wallet", "oracle://u@h:2484/svc?ssl=true&ssl%20verify=false&wallet=/w", map[string]string{"user": "u", "host": "h", "port": "2484", "service_name": "svc", "ssl": "true", "ssl_verify": "false", "wallet": "/w"}, "", false},
		{"easy connect", "db.example:1521/FREEPDB1", map[string]string{"host": "db.example", "port": "1521", "service_name": "FREEPDB1"}, "", false},
		{"easy connect with slashes", "//db.example/FREEPDB1", map[string]string{"host": "db.example", "service_name": "FREEPDB1"}, "", false},
		{"sqlplus style", "scott/tiger@db.example:1521/FREEPDB1", map[string]string{"user": "scott", "host": "db.example", "port": "1521", "service_name": "FREEPDB1"}, "tiger", false},
		{"plain descriptor", "(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=h)(PORT=1521))(CONNECT_DATA=(SERVICE_NAME=svc)))", map[string]string{"host": "h", "port": "1521", "service_name": "svc"}, "", false},
		{"tcps descriptor with sid", "u/p@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCPS)(HOST=h)(PORT=2484))(CONNECT_DATA=(SID=XE)))", map[string]string{"user": "u", "host": "h", "port": "2484", "sid": "XE", "ssl": "true"}, "p", false},
		{"failover descriptor stays whole", "(DESCRIPTION=(ADDRESS_LIST=(ADDRESS=(HOST=a)(PORT=1))(ADDRESS=(HOST=b)(PORT=1)))(CONNECT_DATA=(SERVICE_NAME=s)))", map[string]string{"tns_descriptor": "(DESCRIPTION=(ADDRESS_LIST=(ADDRESS=(HOST=a)(PORT=1))(ADDRESS=(HOST=b)(PORT=1)))(CONNECT_DATA=(SERVICE_NAME=s)))"}, "", false},
		{"unbalanced descriptor", "(DESCRIPTION=(ADDRESS=", nil, "", true},
		{"bad port", "h:99999999/svc", nil, "", true},
		{"bad role", "oracle://u@h/s?role=root", nil, "", true},
		{"missing host", "/svc", nil, "", true},
		{"empty", "", nil, "", true},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, pw, err := parseConnString(tt.in)
			if (err != nil) != tt.wantErr {
				t.Fatalf("err = %v, wantErr %v", err, tt.wantErr)
			}
			if tt.wantErr {
				return
			}
			if pw != tt.pw {
				t.Errorf("password = %q, want %q", pw, tt.pw)
			}
			if !reflect.DeepEqual(got, tt.want) {
				t.Errorf("params = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestParseURINoPasswordLeak(t *testing.T) {
	_, _, err := New().ParseURI("oracle://u:hunter2@h:bad%zz")
	if err == nil || strings.Contains(err.Error(), "hunter2") {
		t.Fatalf("err = %v; want an error without the password", err)
	}
}

func TestDataSourceName(t *testing.T) {
	cfg := func(params map[string]string) engine.Config {
		return New().desc.WithDefaults(engine.Config{EngineID: ID, Params: params})
	}
	t.Run("service", func(t *testing.T) {
		dsn, err := dataSourceName(cfg(map[string]string{"host": "h", "service_name": "svc", "user": "u"}), engine.NewSecret("p@ss/word"))
		if err != nil {
			t.Fatal(err)
		}
		for _, want := range []string{"oracle://u:p@ss%2Fword@h:1521/svc?", "PREFETCH_ROWS=500"} {
			if !strings.Contains(dsn, want) {
				t.Errorf("dsn lacks %q", want)
			}
		}
	})
	t.Run("sid sysdba tls", func(t *testing.T) {
		dsn, err := dataSourceName(cfg(map[string]string{"host": "h", "sid": "XE", "user": "sys", "role": "sysdba", "ssl": "true", "wallet": "/w"}), engine.NewSecret("p"))
		if err != nil {
			t.Fatal(err)
		}
		for _, want := range []string{"SID=XE", "DBA PRIVILEGE=SYSDBA", "SSL=true", "SSL VERIFY=true", "WALLET=%2Fw"} {
			if !strings.Contains(dsn, want) {
				t.Errorf("dsn %q lacks %q", dsn, want)
			}
		}
	})
	t.Run("needs a target", func(t *testing.T) {
		if _, err := dataSourceName(cfg(map[string]string{"host": "h", "user": "u"}), engine.NewSecret("p")); engine.KindOf(err) != engine.KindInvalidConfig {
			t.Errorf("err = %v, want invalid config", err)
		}
	})
	t.Run("descriptor", func(t *testing.T) {
		dsn, err := dataSourceName(cfg(map[string]string{"tns_descriptor": "(DESCRIPTION=(X=1))", "user": "u"}), engine.NewSecret("p"))
		if err != nil || !strings.Contains(dsn, "connStr=") {
			t.Errorf("dsn = %q, err = %v", dsn, err)
		}
	})
}

func TestDescriptorCapabilitiesMatchConn(t *testing.T) {
	for _, capability := range New().Descriptor().Capabilities {
		if !engine.Provides(&Conn{}, capability) {
			t.Errorf("declares %s but Conn does not implement it", capability)
		}
	}
}

func TestColumnKind(t *testing.T) {
	tests := []struct {
		native    string
		precision int64
		scale     int64
		hasSize   bool
		want      engine.ValueKind
	}{
		{"NUMBER", 10, 0, true, engine.VInt},
		{"NUMBER", 18, 0, true, engine.VInt},
		{"NUMBER", 19, 0, true, engine.VDecimal},
		{"NUMBER", 10, 2, true, engine.VDecimal},
		{"NUMBER", 0, 0, false, engine.VDecimal},
		{"FLOAT", 0, 0, false, engine.VDecimal},
		{"BINARY_DOUBLE", 0, 0, false, engine.VFloat},
		{"DATE", 0, 0, false, engine.VTimestamptz},
		{"TIMESTAMP WITH LOCAL TIME ZONE", 0, 0, false, engine.VTimestamptz},
		{"INTERVAL DAY TO SECOND", 0, 0, false, engine.VText},
		{"BLOB", 0, 0, false, engine.VBytes},
		{"RAW", 0, 0, false, engine.VBytes},
		{"CLOB", 0, 0, false, engine.VText},
		{"ROWID", 0, 0, false, engine.VText},
	}
	for _, tt := range tests {
		if got := columnKind(tt.native, tt.precision, tt.scale, tt.hasSize); got != tt.want {
			t.Errorf("columnKind(%s, %d, %d) = %v, want %v", tt.native, tt.precision, tt.scale, got, tt.want)
		}
	}
}

func TestKindOfDataType(t *testing.T) {
	tests := []struct {
		dataType  string
		precision sql.NullInt64
		scale     sql.NullInt64
		want      engine.ValueKind
	}{
		{"NUMBER", sql.NullInt64{Int64: 10, Valid: true}, sql.NullInt64{Valid: true}, engine.VInt},
		{"NUMBER", sql.NullInt64{}, sql.NullInt64{}, engine.VDecimal},
		{"TIMESTAMP(6) WITH TIME ZONE", sql.NullInt64{}, sql.NullInt64{}, engine.VTimestamptz},
		{"TIMESTAMP(6)", sql.NullInt64{}, sql.NullInt64{}, engine.VTimestamptz},
		{"INTERVAL DAY(2) TO SECOND(6)", sql.NullInt64{}, sql.NullInt64{}, engine.VText},
		{"VARCHAR2", sql.NullInt64{}, sql.NullInt64{}, engine.VText},
	}
	for _, tt := range tests {
		if got := kindOfDataType(tt.dataType, tt.precision.Int64, tt.scale.Int64, tt.precision.Valid); got != tt.want {
			t.Errorf("kindOfDataType(%s) = %v, want %v", tt.dataType, got, tt.want)
		}
	}
}

func TestNativeName(t *testing.T) {
	for in, want := range map[string]string{
		"TimeStampTZ_DTY": "TIMESTAMP WITH TIME ZONE", "IntervalDS_DTY": "INTERVAL DAY TO SECOND", "LongVarChar": "CLOB",
		"OCIBlobLocator": "BLOB", "IBDouble": "BINARY_DOUBLE", "NUMBER": "NUMBER", "rowid": "ROWID",
	} {
		if got := nativeName(in); got != want {
			t.Errorf("nativeName(%q) = %q, want %q", in, got, want)
		}
	}
}

func TestConvert(t *testing.T) {
	when := time.Date(2026, 1, 2, 3, 4, 5, 0, time.UTC)
	if v := convert(engine.VInt, "NUMBER", "42"); v.Kind != engine.VInt || v.Int != 42 {
		t.Errorf("int = %+v", v)
	}
	if v := convert(engine.VDecimal, "NUMBER", "12345678901234567890.123456"); v.Kind != engine.VDecimal || v.Str != "12345678901234567890.123456" {
		t.Errorf("decimal = %+v", v)
	}
	if v := convert(engine.VTimestamptz, "DATE", when); v.Kind != engine.VTimestamptz || !v.Time.Equal(when) {
		t.Errorf("time = %+v", v)
	}
	if v := convert(engine.VFloat, "BINARY_FLOAT", float32(1.5)); v.Kind != engine.VFloat || v.Float != 1.5 {
		t.Errorf("float = %+v", v)
	}
	if v := convert(engine.VText, "VARCHAR2", nil); v.Kind != engine.VNull {
		t.Errorf("null = %+v", v)
	}
	if v := convert(engine.VBytes, "RAW", []byte{0, 255}); v.Kind != engine.VBytes || len(v.Bytes) != 2 {
		t.Errorf("bytes = %+v", v)
	}
}

func TestConvertCapsLOBs(t *testing.T) {
	long := strings.Repeat("ж", maxLOBBytes)
	text := convert(engine.VText, "CLOB", long)
	if len(text.Str) > maxLOBBytes+len(truncationMarker) || !strings.HasSuffix(text.Str, truncationMarker) {
		t.Errorf("clob of %d bytes kept %d bytes", len(long), len(text.Str))
	}
	if short := convert(engine.VText, "CLOB", "abc"); short.Str != "abc" {
		t.Errorf("short clob = %q", short.Str)
	}
	blob := convert(engine.VBytes, "BLOB", make([]byte, maxLOBBytes+10))
	if len(blob.Bytes) != maxLOBBytes {
		t.Errorf("blob kept %d bytes, want %d", len(blob.Bytes), maxLOBBytes)
	}
}

func TestToArgs(t *testing.T) {
	got, err := toArgs([]engine.Value{engine.Null(), engine.Bool(true), engine.Int(7), engine.Decimal("1.50"), engine.Text("x")})
	if err != nil {
		t.Fatal(err)
	}
	want := []any{nil, 1, int64(7), "1.50", "x"}
	if !reflect.DeepEqual(got, want) {
		t.Errorf("args = %#v, want %#v", got, want)
	}
	if _, err := toArgs([]engine.Value{{Kind: engine.VArray}}); err == nil {
		t.Error("an array parameter must be rejected")
	}
}

func TestWithoutTerminator(t *testing.T) {
	tests := map[string]string{
		"SELECT 1 FROM dual;":                                  "SELECT 1 FROM dual",
		"SELECT 1 FROM dual\n/":                                "SELECT 1 FROM dual",
		"  SELECT 1 FROM dual ;  ":                             "SELECT 1 FROM dual",
		"BEGIN NULL; END;":                                     "BEGIN NULL; END;",
		"BEGIN NULL; END;\n/":                                  "BEGIN NULL; END;",
		"CREATE OR REPLACE PROCEDURE p AS BEGIN NULL; END;\n/": "CREATE OR REPLACE PROCEDURE p AS BEGIN NULL; END;",
		"CREATE INDEX i ON t (a);":                             "CREATE INDEX i ON t (a)",
	}
	for in, want := range tests {
		if got := withoutTerminator(in); got != want {
			t.Errorf("withoutTerminator(%q) = %q, want %q", in, got, want)
		}
	}
}

func TestReturnsRows(t *testing.T) {
	for sql, want := range map[string]bool{
		"SELECT 1 FROM dual": true, "  with x as (select 1 from dual) select * from x": true, "-- c\nSELECT 1 FROM dual": true,
		"INSERT INTO t VALUES (1)": false, "BEGIN NULL; END;": false, "CREATE TABLE t (a INT)": false, "": false,
	} {
		if got := returnsRows(sql); got != want {
			t.Errorf("returnsRows(%q) = %v, want %v", sql, got, want)
		}
	}
}

func TestLeadingWords(t *testing.T) {
	if got := leadingWords("/* x */ set  transaction read write", 3); !reflect.DeepEqual(got, []string{"SET", "TRANSACTION", "READ"}) {
		t.Errorf("leadingWords = %v", got)
	}
}

func TestClassify(t *testing.T) {
	secret := engine.NewSecret("hunter2")
	tests := []struct {
		code int
		want engine.Kind
	}{
		{oraInvalidLogin, engine.KindAuth},
		{oraAccountLocked, engine.KindAuth},
		{oraNoSuchObject, engine.KindNotFound},
		{oraCanceled, engine.KindCanceled},
		{oraNoListener, engine.KindNetwork},
		{oraUnknownService, engine.KindNotFound},
		{oraEndOfChannel, engine.KindConnectionLost},
		{904, engine.KindSQL},
	}
	for _, tt := range tests {
		err := classify("execute", &network.OracleError{ErrCode: tt.code, ErrMsg: "ORA-" + "x hunter2"}, secret)
		if err.Kind != tt.want {
			t.Errorf("ORA-%05d kind = %v, want %v", tt.code, err.Kind, tt.want)
		}
		if err.Code != tt.code {
			t.Errorf("code = %d, want %d", err.Code, tt.code)
		}
		if strings.Contains(err.Msg, "hunter2") {
			t.Errorf("message leaks the secret: %q", err.Msg)
		}
	}
	if e := classify("connect", errors.New("x509: certificate signed by unknown authority"), secret); e.Kind != engine.KindTLS {
		t.Errorf("tls kind = %v", e.Kind)
	}
}

func TestTypeLabel(t *testing.T) {
	n := func(v int64) sql.NullInt64 { return sql.NullInt64{Int64: v, Valid: true} }
	tests := []struct {
		tc   tableColumn
		want string
	}{
		{tableColumn{dataType: "VARCHAR2", length: n(100), charLength: n(25), charUsed: sql.NullString{String: "B", Valid: true}}, "VARCHAR2(100)"},
		{tableColumn{dataType: "VARCHAR2", length: n(100), charLength: n(25), charUsed: sql.NullString{String: "C", Valid: true}}, "VARCHAR2(25 CHAR)"},
		{tableColumn{dataType: "NUMBER", precision: n(10), scale: n(0)}, "NUMBER(10)"},
		{tableColumn{dataType: "NUMBER", precision: n(10), scale: n(2)}, "NUMBER(10,2)"},
		{tableColumn{dataType: "NUMBER"}, "NUMBER"},
		{tableColumn{dataType: "NUMBER", scale: n(0)}, "NUMBER(*,0)"},
		{tableColumn{dataType: "RAW", length: n(16)}, "RAW(16)"},
		{tableColumn{dataType: "TIMESTAMP(6) WITH TIME ZONE"}, "TIMESTAMP(6) WITH TIME ZONE"},
		{tableColumn{dataType: "CLOB"}, "CLOB"},
	}
	for _, tt := range tests {
		if got := typeLabel(tt.tc); got != tt.want {
			t.Errorf("typeLabel = %q, want %q", got, tt.want)
		}
	}
}

func TestIndexKey(t *testing.T) {
	expr := func(s string) sql.NullString { return sql.NullString{String: s, Valid: true} }
	if k := indexKey("SYS_NC00001$", expr(`"b"`)); k.Name != "b" || k.IsExpression {
		t.Errorf("descending column = %+v", k)
	}
	if k := indexKey("SYS_NC00002$", expr(`UPPER("name")`)); k.Name != `UPPER("name")` || !k.IsExpression {
		t.Errorf("expression = %+v", k)
	}
	if k := indexKey("a", sql.NullString{}); k.Name != "a" || k.IsExpression {
		t.Errorf("plain = %+v", k)
	}
}
