package mongo

import (
	"context"
	"errors"
	"net/url"
	"strings"
	"testing"

	"github.com/doubledare704/queravue/core/internal/engine"
)

func TestParseURI(t *testing.T) {
	cases := []struct {
		name    string
		uri     string
		want    map[string]string
		pw      string
		wantErr string
	}{
		{"plain", "mongodb://localhost:27017", map[string]string{ParamHosts: "localhost:27017"}, "", ""},
		{"full", "mongodb://al%40ice:p%3Ass@h1:1,h2:2/app?replicaSet=rs0&authSource=admin&tls=true&tlsCAFile=/ca.pem&readPreference=secondary&directConnection=false&authMechanism=SCRAM-SHA-256",
			map[string]string{ParamUsername: "al@ice", ParamHosts: "h1:1,h2:2", ParamDatabase: "app", ParamReplicaSet: "rs0",
				ParamAuthSource: "admin", ParamTLS: "true", ParamTLSCAFile: "/ca.pem", ParamReadPreference: "secondary",
				ParamDirect: "false", ParamAuthMechanism: "SCRAM-SHA-256"}, "p:ss", ""},
		{"srv", "mongodb+srv://u:pw@cluster0.example.net/db", map[string]string{ParamSRV: "true", ParamUsername: "u", ParamHosts: "cluster0.example.net", ParamDatabase: "db"}, "pw", ""},
		{"x509", "mongodb://h/?authMechanism=MONGODB-X509&tlsCertificateKeyFile=/c.pem&tlsInsecure=true",
			map[string]string{ParamHosts: "h", ParamAuthMechanism: "MONGODB-X509", ParamTLSCertKeyFile: "/c.pem", ParamTLSInsecure: "true"}, "", ""},
		{"ssl alias", "mongodb://h/?ssl=true", map[string]string{ParamHosts: "h", ParamTLS: "true"}, "", ""},
		{"bad scheme", "postgres://x", nil, "", "unsupported scheme"},
		{"no scheme", "localhost", nil, "", "expected a mongodb"},
		{"empty", "", nil, "", "empty"},
		{"bad port", "mongodb://u:secret@host:abc", nil, "", "invalid port"},
		{"bad mechanism", "mongodb://h/?authMechanism=PLAIN", nil, "", "unsupported authMechanism"},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			got, pw, err := parseURI(tc.uri)
			if tc.wantErr != "" {
				if err == nil || !strings.Contains(err.Error(), tc.wantErr) {
					t.Fatalf("err = %v, want %q", err, tc.wantErr)
				}
				if strings.Contains(err.Error(), "secret") {
					t.Fatalf("error leaks the password: %v", err)
				}
				return
			}
			if err != nil {
				t.Fatal(err)
			}
			if pw != tc.pw {
				t.Errorf("password = %q, want %q", pw, tc.pw)
			}
			if len(got) != len(tc.want) {
				t.Errorf("params = %v, want %v", got, tc.want)
			}
			for k, v := range tc.want {
				if got[k] != v {
					t.Errorf("%s = %q, want %q", k, got[k], v)
				}
			}
			if _, ok := got[ParamPassword]; ok {
				t.Error("password in params")
			}
		})
	}
}

func TestParseURIEngineKeepsPasswordSecret(t *testing.T) {
	cfg, sec, err := New(VariantMongoDB).ParseURI("mongodb://u:pw@h")
	if err != nil {
		t.Fatal(err)
	}
	if sec.Reveal() != "pw" || cfg.Params[ParamUsername] != "u" {
		t.Fatalf("cfg=%v", cfg)
	}
	for _, v := range cfg.Params {
		if v == "pw" {
			t.Fatal("password in params")
		}
	}
}

func TestBuildURI(t *testing.T) {
	e := New(VariantMongoDB)
	cfg := e.desc.WithDefaults(engine.Config{EngineID: ID, Params: map[string]string{
		ParamHosts: "a:1,b:2", ParamReplicaSet: "rs0", ParamUsername: "us er", ParamTLS: "true",
		ParamTLSCAFile: "/ca.pem", ParamAuthSource: "admin", ParamDatabase: "app",
	}})
	builtURI := e.buildURI(cfg, engine.NewSecret("p@ss:w/rd"))
	if !strings.Contains(builtURI, "@a:1,b:2/app?") {
		t.Errorf("host list not kept in %q", builtURI)
	}
	// net/url rejects a comma-separated host list, so parse a single-host copy.
	u, err := url.Parse(strings.Replace(builtURI, "a:1,b:2", "a:1", 1))
	if err != nil {
		t.Fatal(err)
	}
	if pw, _ := u.User.Password(); pw != "p@ss:w/rd" || u.User.Username() != "us er" {
		t.Errorf("userinfo = %v", u.User)
	}
	q := u.Query()
	for k, want := range map[string]string{"replicaSet": "rs0", "tls": "true", "tlsCAFile": "/ca.pem", "authSource": "admin", "readPreference": "primary"} {
		if q.Get(k) != want {
			t.Errorf("%s = %q, want %q", k, q.Get(k), want)
		}
	}
	if q.Get("retryWrites") != "" {
		t.Error("plain MongoDB must keep retryable writes")
	}
	if u.Path != "/app" {
		t.Errorf("path = %q", u.Path)
	}
}

func TestBuildURIVariants(t *testing.T) {
	for _, v := range []Variant{VariantCosmos, VariantDocumentDB} {
		e := New(v)
		cfg := e.desc.WithDefaults(engine.Config{EngineID: e.desc.ID, Params: map[string]string{ParamHosts: "h:10255", ParamUsername: "u"}})
		u, _ := url.Parse(e.buildURI(cfg, engine.NewSecret("x")))
		q := u.Query()
		if q.Get("retryWrites") != "false" || q.Get("tls") != "true" {
			t.Errorf("%s: query = %v", e.desc.ID, q)
		}
	}
	if d := New(VariantCosmos).desc.Fields[0].Placeholder; !strings.Contains(d, ":10255") {
		t.Errorf("cosmos port placeholder = %q", d)
	}
}

func TestBuildURIX509AndSRV(t *testing.T) {
	e := New(VariantMongoDB)
	cfg := e.desc.WithDefaults(engine.Config{EngineID: ID, Params: map[string]string{
		ParamHosts: "cluster.example.net", ParamSRV: "true", ParamAuthMechanism: "MONGODB-X509", ParamAuthSource: "ignored", ParamDirect: "true"}})
	u, _ := url.Parse(e.buildURI(cfg, engine.Secret{}))
	if u.Scheme != "mongodb+srv" || u.Query().Get("authSource") != "$external" || u.Query().Get("directConnection") != "" {
		t.Errorf("uri = %s", u)
	}
}

func TestDescriptors(t *testing.T) {
	for _, v := range []Variant{VariantMongoDB, VariantCosmos, VariantDocumentDB} {
		d := New(v).Descriptor()
		if !d.HasCapability(engine.CapDocumentStore) || d.HasCapability(engine.CapExecute) {
			t.Errorf("%s: capabilities = %v", d.ID, d.Capabilities)
		}
		pw := 0
		for _, f := range d.Fields {
			if f.Kind == engine.FieldPassword {
				pw++
			}
		}
		if pw != 1 {
			t.Errorf("%s: %d password fields", d.ID, pw)
		}
		if err := d.Validate(d.WithDefaults(engine.Config{EngineID: d.ID, Params: map[string]string{ParamHosts: "h:1"}})); err != nil {
			t.Errorf("%s: %v", d.ID, err)
		}
	}
	if _, ok := any(&Conn{}).(engine.DocumentStore); !ok {
		t.Fatal("Conn is not a DocumentStore")
	}
}

func TestConnectInvalidAndUnreachable(t *testing.T) {
	e := New(VariantMongoDB)
	_, err := e.Connect(context.Background(), engine.Config{EngineID: ID, Params: map[string]string{ParamHosts: "h", ParamAuthMechanism: "bogus"}}, engine.Secret{})
	if engine.KindOf(err) != engine.KindInvalidConfig {
		t.Fatalf("err = %v", err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 1500e6)
	defer cancel()
	secret := engine.NewSecret("hunter2-secret")
	_, err = e.Connect(ctx, engine.Config{EngineID: ID, Params: map[string]string{ParamHosts: "127.0.0.1:1", ParamUsername: "u"}}, secret)
	var ee *engine.Error
	if !errors.As(err, &ee) {
		t.Fatalf("err = %v", err)
	}
	if ee.Kind != engine.KindNetwork && ee.Kind != engine.KindTimeout {
		t.Errorf("kind = %v (%s)", ee.Kind, ee.Msg)
	}
	if strings.Contains(ee.Error(), "hunter2") {
		t.Errorf("error leaks the password: %v", ee)
	}
}

func TestClassify(t *testing.T) {
	sec := engine.NewSecret("pw123")
	cases := []struct {
		err  error
		want engine.Kind
	}{
		{context.Canceled, engine.KindCanceled},
		{context.DeadlineExceeded, engine.KindTimeout},
		{errors.New("connection() error occurred during connection handshake: auth error: sasl conversation error: unable to authenticate using mechanism \"SCRAM-SHA-256\""), engine.KindAuth},
		{errors.New("server selection error: context deadline exceeded, current topology: { Type: Unknown, Servers: [] }"), engine.KindTimeout},
		{errors.New("server selection error: dial tcp 127.0.0.1:1: connect: connection refused"), engine.KindNetwork},
		{errors.New("x509: certificate signed by unknown authority"), engine.KindTLS},
	}
	for _, tc := range cases {
		if got := classify("op", tc.err, sec).Kind; got != tc.want {
			t.Errorf("%v: kind %v, want %v", tc.err, got, tc.want)
		}
	}
	if m := classify("op", errors.New("bad pw123 here"), sec).Msg; strings.Contains(m, "pw123") {
		t.Errorf("message leaks secret: %s", m)
	}
}
