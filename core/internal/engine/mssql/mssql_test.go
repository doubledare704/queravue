package mssql

import (
	"errors"
	"fmt"
	"strings"
	"testing"
	"time"

	mssqldb "github.com/microsoft/go-mssqldb"

	"github.com/doubledare704/queravue/core/internal/engine"
)

func TestParseConnString(t *testing.T) {
	tests := []struct {
		name, in string
		want     map[string]string
		pw       string
		wantErr  bool
	}{
		{"full", "sqlserver://sa:S3cret!@db.example:1444?database=shop&encrypt=strict&TrustServerCertificate=true",
			map[string]string{"user": "sa", "host": "db.example", "port": "1444", "database": "shop", "encrypt": "strict", "trust_server_certificate": "true"}, "S3cret!", false},
		{"mssql scheme", "mssql://u@h", map[string]string{"user": "u", "host": "h"}, "", false},
		{"ado encrypt spellings", "sqlserver://u@h?encrypt=false", map[string]string{"user": "u", "host": "h", "encrypt": "optional"}, "", false},
		{"named instance", "sqlserver://u@h/SQLEXPRESS", nil, "", true},
		{"bad scheme", "postgres://u@h", nil, "", true},
		{"no scheme", "Server=h;User Id=u", nil, "", true},
		{"bad port", "sqlserver://u@h:99999999", nil, "", true},
		{"bad encrypt", "sqlserver://u@h?encrypt=maybe", nil, "", true},
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
			if len(got) != len(tt.want) {
				t.Errorf("params = %v, want %v", got, tt.want)
			}
			for k, v := range tt.want {
				if got[k] != v {
					t.Errorf("%s = %q, want %q", k, got[k], v)
				}
			}
		})
	}
}

func TestParseURINoPasswordLeak(t *testing.T) {
	_, _, err := New().ParseURI("sqlserver://u:hunter2@h:bad%zz")
	if err == nil || strings.Contains(err.Error(), "hunter2") {
		t.Fatalf("err = %v; want an error without the password", err)
	}
}

func TestClassify(t *testing.T) {
	secret := engine.NewSecret("hunter2")
	tests := []struct {
		name string
		err  error
		want engine.Kind
	}{
		{"login failed", mssqldb.Error{Number: 18456, Message: "Login failed for user 'sa'."}, engine.KindAuth},
		{"login failed ptr", &mssqldb.Error{Number: 18456, Message: "Login failed"}, engine.KindAuth},
		{"wrapped", fmt.Errorf("wrap: %w", mssqldb.Error{Number: 18456}), engine.KindAuth},
		{"cannot open db", mssqldb.Error{Number: 4060, Message: "Cannot open database"}, engine.KindNotFound},
		{"tls", errors.New("TLS Handshake failed: x509: certificate signed by unknown authority"), engine.KindTLS},
		{"other", errors.New("boom"), engine.KindUnknown},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			ee := classify(ID, "connect", tt.err, secret)
			if ee.Kind != tt.want {
				t.Errorf("kind = %v, want %v", ee.Kind, tt.want)
			}
			if strings.Contains(ee.Msg, "hunter2") {
				t.Error("message leaks secret")
			}
		})
	}
}

func TestConvert(t *testing.T) {
	ts := time.Date(2026, 1, 2, 3, 4, 5, 0, time.UTC)
	// 16 bytes in wire order: the first three groups are little-endian.
	wire := []byte{0x78, 0x56, 0x34, 0x12, 0xbc, 0x9a, 0xf0, 0xde, 0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef}
	tests := []struct {
		name, typ string
		in        any
		want      engine.Value
	}{
		{"null", "INT", nil, engine.Null()},
		{"int", "BIGINT", int64(-7), engine.Int(-7)},
		{"bit", "BIT", true, engine.Bool(true)},
		{"float", "FLOAT", 1.5, engine.Float(1.5)},
		{"decimal", "DECIMAL", []byte("12.3400"), engine.Decimal("12.3400")},
		{"money", "MONEY", []byte("922337203685477.5807"), engine.Decimal("922337203685477.5807")},
		{"nvarchar", "NVARCHAR", "héllo", engine.Text("héllo")},
		{"xml", "XML", "<a/>", engine.Text("<a/>")},
		{"datetime2", "DATETIME2", ts, engine.Timestamptz(ts)},
		{"date", "DATE", ts, engine.Text("2026-01-02")},
		{"time", "TIME", ts, engine.Text("03:04:05")},
		{"varbinary", "VARBINARY", []byte{0, 1, 0xff}, engine.Bytes([]byte{0, 1, 0xff})},
		{"rowversion", "TIMESTAMP", []byte{0, 0, 0, 0, 0, 0, 0x07, 0xd1}, engine.Bytes([]byte{0, 0, 0, 0, 0, 0, 0x07, 0xd1})},
		{"uniqueidentifier byte order", "UNIQUEIDENTIFIER", wire, engine.UUID("12345678-9ABC-DEF0-0123-456789ABCDEF")},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := convert(tt.typ, tt.in)
			if got.Kind != tt.want.Kind || got.Int != tt.want.Int || got.Bool != tt.want.Bool || got.Float != tt.want.Float ||
				got.Str != tt.want.Str || string(got.Bytes) != string(tt.want.Bytes) || !got.Time.Equal(tt.want.Time) {
				t.Errorf("got %+v, want %+v", got, tt.want)
			}
		})
	}
}

func TestReturnsRows(t *testing.T) {
	for sql, want := range map[string]bool{
		"SELECT 1":                                    true,
		"  insert into t values (1)":                  false,
		"/* c */ UPDATE t SET a=1":                    false,
		"-- x\nDELETE FROM t":                         false,
		"INSERT INTO t OUTPUT inserted.id VALUES (1)": true,
		"BEGIN TRANSACTION;":                          true,
		"EXEC sp_who":                                 true,
	} {
		if got := returnsRows(sql); got != want {
			t.Errorf("returnsRows(%q) = %v, want %v", sql, got, want)
		}
	}
}

func TestTypeLabel(t *testing.T) {
	tests := []struct {
		name          string
		max, pr, scal int
		want          string
	}{
		{"nvarchar", 200, 0, 0, "nvarchar(100)"},
		{"nvarchar", -1, 0, 0, "nvarchar(max)"},
		{"varchar", 50, 0, 0, "varchar(50)"},
		{"decimal", 9, 18, 2, "decimal(18,2)"},
		{"datetimeoffset", 10, 34, 7, "datetimeoffset(7)"},
		{"int", 4, 10, 0, "int"},
	}
	for _, tt := range tests {
		if got := typeLabel(tt.name, tt.max, tt.pr, tt.scal); got != tt.want {
			t.Errorf("typeLabel(%s) = %s, want %s", tt.name, got, tt.want)
		}
	}
}

func TestDescriptor(t *testing.T) {
	d := New().Descriptor()
	if d.Family != "mssql" || !d.HasCapability(engine.CapExecute) || !d.HasCapability(engine.CapSchemaInspector) {
		t.Fatalf("descriptor = %+v", d)
	}
	cfg := d.WithDefaults(engine.Config{EngineID: ID, Params: map[string]string{}})
	if cfg.Params[ParamPort] != "1433" || cfg.Params[ParamEncrypt] != "required" {
		t.Errorf("defaults = %v", cfg.Params)
	}
	if err := d.Validate(cfg); err != nil {
		t.Errorf("defaults invalid: %v", err)
	}
}
