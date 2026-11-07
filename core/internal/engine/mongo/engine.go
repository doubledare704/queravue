// Package mongo implements the MongoDB engine and its wire-compatible
// variants (Azure Cosmos DB for MongoDB, Amazon DocumentDB) on top of the
// official go.mongodb.org/mongo-driver/v2. See ADR 0009.
package mongo

import (
	"context"
	"fmt"
	"net/url"
	"strconv"
	"strings"
	"sync"
	"time"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"

	"github.com/doubledare704/queravue/core/internal/engine"
)

// Engine ids.
const (
	ID         = "mongodb"
	IDCosmos   = "cosmosdb-mongo"
	IDDocument = "documentdb"
)

// Param keys.
const (
	ParamHosts          = "hosts"
	ParamSRV            = "srv"
	ParamReplicaSet     = "replica_set"
	ParamDatabase       = "database"
	ParamUsername       = "username"
	ParamPassword       = "password"
	ParamAuthSource     = "auth_source"
	ParamAuthMechanism  = "auth_mechanism"
	ParamTLS            = "tls"
	ParamTLSCAFile      = "tls_ca_file"
	ParamTLSCertKeyFile = "tls_cert_key_file"
	ParamTLSInsecure    = "tls_insecure"
	ParamDirect         = "direct_connection"
	ParamReadPreference = "read_preference"
)

// AuthMechanisms are the supported values of ParamAuthMechanism.
var AuthMechanisms = []string{"default", "SCRAM-SHA-256", "SCRAM-SHA-1", "MONGODB-X509"}

// ReadPreferences are the supported values of ParamReadPreference.
var ReadPreferences = []string{"primary", "primaryPreferred", "secondary", "secondaryPreferred", "nearest"}

// Variant selects a MongoDB-compatible server family.
type Variant int

// Variants.
const (
	VariantMongoDB Variant = iota
	VariantCosmos
	VariantDocumentDB
)

// Default timeouts.
const (
	connectTimeout = 10 * time.Second
	appName        = "Queravue"
)

// Engine is a MongoDB-family engine.
type Engine struct {
	variant Variant
	desc    engine.Descriptor
}

// New returns the engine for variant v.
func New(v Variant) *Engine {
	id, name := ID, "MongoDB"
	hosts, hostPH := "localhost:27017", "localhost:27017"
	tlsDefault, uriEx := "false", "mongodb://user@localhost:27017/?replicaSet=rs0"
	caPH := "/path/to/ca.pem"
	switch v {
	case VariantCosmos:
		id, name = IDCosmos, "Azure Cosmos DB (Mongo API)"
		hosts, hostPH, tlsDefault = "", "<account>.mongo.cosmos.azure.com:10255", "true"
		uriEx = "mongodb://account@account.mongo.cosmos.azure.com:10255/?tls=true&retryWrites=false"
	case VariantDocumentDB:
		id, name = IDDocument, "Amazon DocumentDB"
		hosts, hostPH, tlsDefault = "", "<cluster>.docdb.amazonaws.com:27017", "true"
		uriEx = "mongodb://user@cluster.docdb.amazonaws.com:27017/?tls=true&tlsCAFile=global-bundle.pem&retryWrites=false"
		caPH = "global-bundle.pem"
	}
	return &Engine{variant: v, desc: engine.Descriptor{
		ID: id, DisplayName: name, Family: ID, SupportsURI: true, URIExample: uriEx,
		Fields: []engine.FieldSpec{
			{Key: ParamHosts, Label: "Hosts", Kind: engine.FieldText, Required: true, Default: hosts, Placeholder: hostPH},
			{Key: ParamSRV, Label: "SRV (mongodb+srv)", Kind: engine.FieldBoolean, Default: "false"},
			{Key: ParamReplicaSet, Label: "Replica set", Kind: engine.FieldText, Placeholder: "rs0"},
			{Key: ParamDatabase, Label: "Default database", Kind: engine.FieldText, Placeholder: "admin"},
			{Key: ParamUsername, Label: "User", Kind: engine.FieldText},
			{Key: ParamPassword, Label: "Password", Kind: engine.FieldPassword},
			{Key: ParamAuthSource, Label: "Auth source", Kind: engine.FieldText, Placeholder: "admin"},
			{Key: ParamAuthMechanism, Label: "Auth mechanism", Kind: engine.FieldSelect, Default: "default", Options: AuthMechanisms},
			{Key: ParamTLS, Label: "TLS", Kind: engine.FieldBoolean, Default: tlsDefault},
			{Key: ParamTLSCAFile, Label: "CA file", Kind: engine.FieldFile, Placeholder: caPH},
			{Key: ParamTLSCertKeyFile, Label: "Client certificate + key", Kind: engine.FieldFile},
			{Key: ParamTLSInsecure, Label: "Allow invalid certificates", Kind: engine.FieldBoolean, Default: "false"},
			{Key: ParamDirect, Label: "Direct connection", Kind: engine.FieldBoolean, Default: "false"},
			{Key: ParamReadPreference, Label: "Read preference", Kind: engine.FieldSelect, Default: "primary", Options: ReadPreferences},
		},
		Capabilities: []engine.Capability{engine.CapConnect, engine.CapSchemaInspector, engine.CapDocumentStore, engine.CapShell},
	}}
}

// Descriptor implements engine.Engine.
func (e *Engine) Descriptor() engine.Descriptor { return e.desc }

// ParseURI implements engine.Engine.
func (e *Engine) ParseURI(uri string) (engine.Config, engine.Secret, error) {
	params, pw, err := parseURI(uri)
	if err != nil {
		return engine.Config{}, engine.Secret{}, engine.Errorf(engine.KindInvalidConfig, e.desc.ID, "parse uri", "%s", err.Error())
	}
	return engine.Config{EngineID: e.desc.ID, Params: params}, engine.NewSecret(pw), nil
}

// buildURI assembles the connection URI from fields. It contains the
// password: callers must not log it.
func (e *Engine) buildURI(cfg engine.Config, secret engine.Secret) string {
	scheme := "mongodb"
	if cfg.Param(ParamSRV, "false") == "true" {
		scheme = "mongodb+srv"
	}
	u := url.URL{Scheme: scheme, Host: cfg.Param(ParamHosts, "localhost:27017"), Path: "/" + cfg.Param(ParamDatabase, "")}
	if name := cfg.Param(ParamUsername, ""); name != "" {
		if secret.IsZero() {
			u.User = url.User(name)
		} else {
			u.User = url.UserPassword(name, secret.Reveal())
		}
	}
	q := url.Values{}
	q.Set("appName", appName)
	if rs := cfg.Param(ParamReplicaSet, ""); rs != "" {
		q.Set("replicaSet", rs)
	}
	mech := cfg.Param(ParamAuthMechanism, "default")
	if mech != "default" {
		q.Set("authMechanism", mech)
	}
	switch src := cfg.Param(ParamAuthSource, ""); {
	case mech == "MONGODB-X509":
		q.Set("authSource", "$external")
	case src != "":
		q.Set("authSource", src)
	}
	if cfg.Param(ParamTLS, "false") == "true" {
		q.Set("tls", "true")
		if f := cfg.Param(ParamTLSCAFile, ""); f != "" {
			q.Set("tlsCAFile", f)
		}
		if f := cfg.Param(ParamTLSCertKeyFile, ""); f != "" {
			q.Set("tlsCertificateKeyFile", f)
		}
		if cfg.Param(ParamTLSInsecure, "false") == "true" {
			q.Set("tlsInsecure", "true")
		}
	}
	if cfg.Param(ParamDirect, "false") == "true" && scheme == "mongodb" {
		q.Set("directConnection", "true")
	}
	q.Set("readPreference", cfg.Param(ParamReadPreference, "primary"))
	if e.variant != VariantMongoDB {
		q.Set("retryWrites", "false")
	}
	q.Set("serverSelectionTimeoutMS", strconv.Itoa(int(connectTimeout/time.Millisecond)))
	u.RawQuery = q.Encode()
	return u.String()
}

// Connect implements engine.Engine.
func (e *Engine) Connect(ctx context.Context, cfg engine.Config, secret engine.Secret) (engine.Conn, error) {
	cfg = e.desc.WithDefaults(cfg)
	if err := e.desc.Validate(cfg); err != nil {
		return nil, err
	}
	opts := options.Client().ApplyURI(e.buildURI(cfg, secret))
	if err := opts.Validate(); err != nil {
		return nil, &engine.Error{Kind: engine.KindInvalidConfig, Engine: e.desc.ID, Op: "config",
			Msg: engine.Redact(err.Error(), secret), Err: err}
	}
	client, err := mongo.Connect(opts)
	if err != nil {
		return nil, relabel(classify("connect", err, secret), e.desc.ID)
	}
	c := &Conn{variant: e.variant, id: e.desc.ID, secret: secret, client: client, defaultDB: cfg.Param(ParamDatabase, "")}
	// Connect is lazy: a ping forces server selection and authentication.
	if err := client.Ping(ctx, nil); err != nil {
		_ = client.Disconnect(context.Background())
		return nil, relabel(classify("connect", err, secret), e.desc.ID)
	}
	return c, nil
}

func relabel(e *engine.Error, id string) *engine.Error { e.Engine = id; return e }

// Conn is a live MongoDB connection. The driver pools connections and is
// safe for concurrent use.
type Conn struct {
	variant   Variant
	id        string
	secret    engine.Secret
	defaultDB string

	mu     sync.Mutex
	client *mongo.Client
}

func (c *Conn) live(op string) (*mongo.Client, error) {
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.client == nil {
		return nil, &engine.Error{Kind: engine.KindConnectionLost, Engine: c.id, Op: op, Msg: "connection is closed"}
	}
	return c.client, nil
}

// fail classifies err for op with this connection's id and secret.
func (c *Conn) fail(op string, err error) error {
	return relabel(classify(op, err, c.secret), c.id)
}

// Ping implements engine.Conn.
func (c *Conn) Ping(ctx context.Context) error {
	cl, err := c.live("ping")
	if err != nil {
		return err
	}
	if err := cl.Ping(ctx, nil); err != nil {
		return c.fail("ping", err)
	}
	return nil
}

// ServerInfo implements engine.Conn.
func (c *Conn) ServerInfo(ctx context.Context) (engine.ServerInfo, error) {
	cl, err := c.live("server info")
	if err != nil {
		return engine.ServerInfo{}, err
	}
	var bi struct {
		Version string `bson:"version"`
	}
	if err := cl.Database("admin").RunCommand(ctx, bson.D{{Key: "buildInfo", Value: 1}}).Decode(&bi); err != nil {
		return engine.ServerInfo{}, c.fail("server info", err)
	}
	product := map[Variant]string{VariantMongoDB: "MongoDB", VariantCosmos: "Azure Cosmos DB", VariantDocumentDB: "Amazon DocumentDB"}[c.variant]
	return engine.ServerInfo{Product: product, Version: bi.Version, Banner: strings.TrimSpace(fmt.Sprintf("%s %s", product, bi.Version))}, nil
}

// Close implements engine.Conn.
func (c *Conn) Close() error {
	c.mu.Lock()
	cl := c.client
	c.client = nil
	c.mu.Unlock()
	if cl == nil {
		return nil
	}
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := cl.Disconnect(ctx); err != nil {
		return fmt.Errorf("%s: close: %w", c.id, err)
	}
	return nil
}
