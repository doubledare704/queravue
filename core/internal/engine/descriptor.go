package engine

import (
	"fmt"
	"reflect"
	"slices"
	"strconv"
)

// Capability names an optional feature an engine supports. The UI enables
// features from these names, never from engine ids.
type Capability string

// Known capabilities. Each one beyond CapConnect corresponds to an optional
// interface on Conn (see CapabilityInterfaces).
const (
	// CapConnect: Connect, Ping, ServerInfo. Every engine has it.
	CapConnect Capability = "connect"
	// CapExecute: Executor (Iteration 2).
	CapExecute Capability = "execute"
	// CapSchemaInspector: SchemaInspector (Iteration 3).
	CapSchemaInspector Capability = "schema_inspector"
	// CapDocumentStore: DocumentStore (Iteration 5).
	CapDocumentStore Capability = "document_store"
)

// CapabilityInterfaces maps capabilities to the Conn interface that provides
// them. Registry tests use it to check that declared capabilities match what a
// Conn implements.
var CapabilityInterfaces = map[Capability]reflect.Type{
	CapExecute:         reflect.TypeFor[Executor](),
	CapSchemaInspector: reflect.TypeFor[SchemaInspector](),
	CapDocumentStore:   reflect.TypeFor[DocumentStore](),
}

// FieldKind tells the UI which input widget to render.
type FieldKind int

// Field kinds; they mirror queravue.v1.FieldKind.
const (
	FieldText FieldKind = iota + 1
	FieldInteger
	FieldPassword
	FieldFile
	FieldBoolean
	FieldSelect
)

// FieldSpec describes one form field.
type FieldSpec struct {
	Key         string
	Label       string
	Kind        FieldKind
	Required    bool
	Default     string
	Placeholder string
	Options     []string
}

// Descriptor describes an engine to the registry and the UI.
type Descriptor struct {
	// ID is stable and stored in connection configs, e.g. "postgres".
	ID string
	// DisplayName, e.g. "PostgreSQL".
	DisplayName string
	// Family is the wire-compatible family, e.g. "postgres" for CockroachDB.
	Family string
	// Fields in display order. At most one field has Kind FieldPassword; its
	// value travels as a Secret, never in Config.Params.
	Fields []FieldSpec
	// SupportsURI reports whether ParseURI is implemented.
	SupportsURI bool
	// URIExample is a placeholder for the URI input.
	URIExample string
	// Capabilities the engine's Conn provides. Must include CapConnect.
	Capabilities []Capability
}

// HasCapability reports whether d declares c.
func (d Descriptor) HasCapability(c Capability) bool {
	return slices.Contains(d.Capabilities, c)
}

// Validate checks cfg against the field specs: required fields present,
// integers parse, selects hold an allowed value. Password fields are skipped.
func (d Descriptor) Validate(cfg Config) error {
	for _, f := range d.Fields {
		if f.Kind == FieldPassword {
			continue
		}
		v := cfg.Params[f.Key]
		if v == "" {
			if f.Required && f.Default == "" {
				return Errorf(KindInvalidConfig, d.ID, "validate", "%s is required", f.Label)
			}
			continue
		}
		switch f.Kind {
		case FieldInteger:
			if _, err := strconv.Atoi(v); err != nil {
				return Errorf(KindInvalidConfig, d.ID, "validate", "%s must be a number", f.Label)
			}
		case FieldBoolean:
			if v != "true" && v != "false" {
				return Errorf(KindInvalidConfig, d.ID, "validate", "%s must be true or false", f.Label)
			}
		case FieldSelect:
			if !slices.Contains(f.Options, v) {
				return Errorf(KindInvalidConfig, d.ID, "validate", "%s must be one of %v", f.Label, f.Options)
			}
		}
	}
	return nil
}

// WithDefaults returns a copy of cfg with empty fields set to their defaults.
func (d Descriptor) WithDefaults(cfg Config) Config {
	out := Config{EngineID: cfg.EngineID, Params: make(map[string]string, len(cfg.Params))}
	for k, v := range cfg.Params {
		out.Params[k] = v
	}
	for _, f := range d.Fields {
		if f.Kind != FieldPassword && out.Params[f.Key] == "" && f.Default != "" {
			out.Params[f.Key] = f.Default
		}
	}
	return out
}

// KnownKey reports whether key is a non-password field of d.
func (d Descriptor) KnownKey(key string) bool {
	for _, f := range d.Fields {
		if f.Key == key {
			return f.Kind != FieldPassword
		}
	}
	return false
}

// String implements fmt.Stringer.
func (k FieldKind) String() string {
	switch k {
	case FieldText:
		return "text"
	case FieldInteger:
		return "integer"
	case FieldPassword:
		return "password"
	case FieldFile:
		return "file"
	case FieldBoolean:
		return "boolean"
	case FieldSelect:
		return "select"
	default:
		return fmt.Sprintf("FieldKind(%d)", int(k))
	}
}
