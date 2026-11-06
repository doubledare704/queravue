package mysql

import (
	"database/sql"
	"errors"
	"fmt"
	"testing"
	"time"

	drv "github.com/go-sql-driver/mysql"

	"github.com/doubledare704/queravue/core/internal/engine"
)

func TestParseConnString(t *testing.T) {
	tests := []struct {
		name, in string
		want     map[string]string
		pw       string
		wantErr  bool
	}{
		{"url", "mysql://bob:s3cret@db.example:3307/shop?tls=skip-verify",
			map[string]string{"user": "bob", "host": "db.example", "port": "3307", "database": "shop", "tls": "skip-verify"}, "s3cret", false},
		{"mariadb scheme", "mariadb://root@localhost/x", map[string]string{"user": "root", "host": "localhost", "database": "x"}, "", false},
		{"tidb scheme", "tidb://root@127.0.0.1:4000/test", map[string]string{"user": "root", "host": "127.0.0.1", "port": "4000", "database": "test"}, "", false},
		{"dsn", "bob:pw@tcp(h:3306)/d?tls=true", map[string]string{"user": "bob", "host": "h", "port": "3306", "database": "d", "tls": "verify"}, "pw", false},
		{"bad scheme", "postgres://x", nil, "", true},
		{"bad port", "mysql://h:99999999/d", nil, "", true},
		{"bad tls", "mysql://h/d?tls=wat", nil, "", true},
		{"empty", " ", nil, "", true},
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
			for k, v := range tt.want {
				if got[k] != v {
					t.Errorf("%s = %q, want %q", k, got[k], v)
				}
			}
			if len(got) != len(tt.want) {
				t.Errorf("params = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestParseURINoPasswordLeak(t *testing.T) {
	_, _, err := New(VariantMySQL).ParseURI("mysql://u:hunter2@h:bad%zz/db")
	if err == nil {
		t.Fatal("want error")
	}
	if got := err.Error(); containsStr(got, "hunter2") {
		t.Errorf("error leaks password: %s", got)
	}
}

func containsStr(s, sub string) bool {
	for i := 0; i+len(sub) <= len(s); i++ {
		if s[i:i+len(sub)] == sub {
			return true
		}
	}
	return false
}

func TestClassify(t *testing.T) {
	secret := engine.NewSecret("hunter2")
	tests := []struct {
		name string
		err  error
		want engine.Kind
	}{
		{"access denied", &drv.MySQLError{Number: 1045, Message: "Access denied for user 'u'@'h' (using password: YES)"}, engine.KindAuth},
		{"unknown db", &drv.MySQLError{Number: 1049, Message: "Unknown database 'x'"}, engine.KindNotFound},
		{"wrapped", fmt.Errorf("wrap: %w", &drv.MySQLError{Number: 1045}), engine.KindAuth},
		{"max exec time", &drv.MySQLError{Number: 3024}, engine.KindTimeout},
		{"bad conn", drv.ErrInvalidConn, engine.KindConnectionLost},
		{"tls", errors.New("x509: certificate signed by unknown authority"), engine.KindTLS},
		{"other", errors.New("boom"), engine.KindUnknown},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := classify("mysql", "connect", tt.err, secret)
			var ee *engine.Error
			if !errors.As(err, &ee) {
				t.Fatalf("not *engine.Error: %T", err)
			}
			if ee.Kind != tt.want {
				t.Errorf("kind = %v, want %v", ee.Kind, tt.want)
			}
			if containsStr(ee.Msg, "hunter2") {
				t.Error("message leaks secret")
			}
		})
	}
}

func TestParseBanner(t *testing.T) {
	tests := []struct{ in, product, version string }{
		{"8.4.13", "MySQL", "8.4.13"},
		{"8.0.36-0ubuntu0.22.04.1", "MySQL", "8.0.36"},
		{"11.4.2-MariaDB-ubu2404", "MariaDB", "11.4.2"},
		{"5.5.5-10.11.6-MariaDB-1:10.11.6", "MariaDB", "10.11.6"},
		{"8.0.11-TiDB-v8.1.0", "TiDB", "8.1.0"},
	}
	for _, tt := range tests {
		got := parseBanner(tt.in)
		if got.Product != tt.product || got.Version != tt.version {
			t.Errorf("parseBanner(%q) = %s %s, want %s %s", tt.in, got.Product, got.Version, tt.product, tt.version)
		}
	}
}

func TestConvert(t *testing.T) {
	tests := []struct {
		name, typ string
		raw       sql.RawBytes
		want      engine.Value
	}{
		{"null", "INT", nil, engine.Null()},
		{"int", "INT", sql.RawBytes("-42"), engine.Int(-42)},
		{"tinyint", "TINYINT", sql.RawBytes("1"), engine.Int(1)},
		{"unsigned fits", "UNSIGNED BIGINT", sql.RawBytes("9223372036854775807"), engine.Int(9223372036854775807)},
		{"unsigned max", "UNSIGNED BIGINT", sql.RawBytes("18446744073709551615"), engine.Decimal("18446744073709551615")},
		{"decimal", "DECIMAL", sql.RawBytes("12.3400"), engine.Decimal("12.3400")},
		{"double", "DOUBLE", sql.RawBytes("1.5"), engine.Float(1.5)},
		{"datetime", "DATETIME", sql.RawBytes("2026-01-02 03:04:05.5"), engine.Timestamptz(time.Date(2026, 1, 2, 3, 4, 5, 500_000_000, time.UTC))},
		{"zero datetime stays text", "DATETIME", sql.RawBytes("0000-00-00 00:00:00"), engine.Text("0000-00-00 00:00:00")},
		{"zero timestamp stays text", "TIMESTAMP", sql.RawBytes("0000-00-00 00:00:00"), engine.Text("0000-00-00 00:00:00")},
		{"date is text", "DATE", sql.RawBytes("2026-01-02"), engine.Text("2026-01-02")},
		{"json", "JSON", sql.RawBytes(`{"a":1}`), engine.JSON(`{"a":1}`)},
		{"blob", "BLOB", sql.RawBytes{0, 1, 0xff}, engine.Bytes([]byte{0, 1, 0xff})},
		{"bit", "BIT", sql.RawBytes{5}, engine.Bytes([]byte{5})},
		{"varchar", "VARCHAR", sql.RawBytes("héllo"), engine.Text("héllo")},
		{"empty string is not null", "VARCHAR", sql.RawBytes{}, engine.Text("")},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := convert(tt.typ, tt.raw)
			if got.Kind != tt.want.Kind || got.Int != tt.want.Int || got.Float != tt.want.Float ||
				got.Str != tt.want.Str || string(got.Bytes) != string(tt.want.Bytes) || !got.Time.Equal(tt.want.Time) {
				t.Errorf("got %+v, want %+v", got, tt.want)
			}
		})
	}
}

func TestReturnsRows(t *testing.T) {
	for sql, rows := range map[string]bool{
		"SELECT 1":                              true,
		"  insert into t values (1)":            false,
		"/* c */ UPDATE t SET a=1":              false,
		"-- x\nDELETE FROM t":                   false,
		"INSERT INTO t VALUES (1) RETURNING id": true,
		"SHOW TABLES":                           true,
		"(SELECT 1) UNION (SELECT 2)":           true,
	} {
		if got := returnsRows(sql); got != rows {
			t.Errorf("returnsRows(%q) = %v, want %v", sql, got, rows)
		}
	}
}

func TestDescriptors(t *testing.T) {
	ports := map[Variant]string{VariantMySQL: "3306", VariantMariaDB: "3306", VariantTiDB: "4000"}
	for v, port := range ports {
		d := New(v).Descriptor()
		if d.Family != "mysql" || !d.HasCapability(engine.CapExecute) || !d.HasCapability(engine.CapSchemaInspector) {
			t.Errorf("%s: bad descriptor %+v", d.ID, d)
		}
		cfg := d.WithDefaults(engine.Config{EngineID: d.ID, Params: map[string]string{}})
		if cfg.Params[ParamPort] != port {
			t.Errorf("%s: default port %q, want %q", d.ID, cfg.Params[ParamPort], port)
		}
		if err := d.Validate(cfg); err != nil {
			t.Errorf("%s: defaults invalid: %v", d.ID, err)
		}
	}
}
