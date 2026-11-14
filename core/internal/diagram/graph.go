// Package diagram loads the tables, columns and relations of a schema in bulk
// for schema diagrams, or infers them from samples on document stores
// (ADR 0017).
package diagram

import (
	"context"
	"errors"
	"fmt"
	"strconv"
	"strings"
	"sync"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/session"
)

// MaxColumnsPerTable caps the columns kept for one table.
const MaxColumnsPerTable = 200

// ErrNotSupported means the connection can neither list relations in bulk
// nor sample documents.
var ErrNotSupported = errors.New("diagram: connection cannot list schema relations")

// Scope selects the graph to load. SampleSize applies to document stores.
type Scope struct {
	Database   string
	Schema     string
	SampleSize uint32
	// OnSampled is told, on document stores, how many collections are sampled
	// after each one; calls never overlap. It is not part of the cache key.
	OnSampled func(sampled, total int)
}

// Relation is a foreign key, or a reference guessed from sampled documents.
type Relation struct {
	engine.ForeignKeyDef
	Inferred bool
	// Confidence is in (0, 1] for inferred relations and 0 otherwise.
	Confidence float64
}

// Table is one node of the graph.
type Table struct {
	Name             string
	Type             engine.ObjectType
	EstimatedRows    int64
	Columns          []engine.KeyedColumn
	Relations        []Relation
	ColumnsTruncated bool
}

// Graph is every table of one schema, in the order the engine lists objects.
type Graph struct {
	Tables []Table
}

// Assemble joins the three bulk listings. Columns and relations of objects
// that are not listed are dropped.
func Assemble(objects []engine.SchemaObject, columns []engine.KeyedColumn, relations []engine.TableRelation) *Graph {
	g := &Graph{Tables: make([]Table, len(objects))}
	byName := make(map[string]*Table, len(objects))
	for i, o := range objects {
		g.Tables[i] = Table{Name: o.Name, Type: o.Type, EstimatedRows: o.EstimatedRows}
		byName[o.Name] = &g.Tables[i]
	}
	for _, c := range columns {
		t, ok := byName[c.Table]
		if !ok {
			continue
		}
		if len(t.Columns) == MaxColumnsPerTable {
			t.ColumnsTruncated = true
			continue
		}
		t.Columns = append(t.Columns, c)
	}
	for _, r := range relations {
		if t, ok := byName[r.Table]; ok {
			t.Relations = append(t.Relations, Relation{ForeignKeyDef: r.ForeignKeyDef})
		}
	}
	return g
}

// Load reads the graph of one schema, waiting for a running statement on the
// session to finish first. SQL engines answer with three queries; document
// stores have each collection sampled.
func Load(ctx context.Context, sess *session.Session, scope Scope) (*Graph, error) {
	inspector, canInspect := engine.As[engine.SchemaInspector](sess.Conn)
	if !canInspect {
		return nil, ErrNotSupported
	}
	if lister, ok := engine.As[engine.RelationLister](sess.Conn); ok {
		return loadListed(ctx, sess, inspector, lister, scope)
	}
	if store, ok := engine.As[engine.DocumentStore](sess.Conn); ok {
		return loadSampled(ctx, sess, inspector, store, scope)
	}
	return nil, ErrNotSupported
}

func loadListed(ctx context.Context, sess *session.Session, inspector engine.SchemaInspector, lister engine.RelationLister, scope Scope) (*Graph, error) {
	var objects []engine.SchemaObject
	var columns []engine.KeyedColumn
	var relations []engine.TableRelation
	err := sess.RunWhenFree(ctx, func(ctx context.Context) (err error) {
		if objects, err = inspector.ListObjects(ctx, scope.Database, scope.Schema); err != nil {
			return fmt.Errorf("diagram: list objects: %w", err)
		}
		if columns, err = lister.ListKeyedColumns(ctx, scope.Database, scope.Schema); err != nil {
			return fmt.Errorf("diagram: list columns: %w", err)
		}
		if relations, err = lister.ListRelations(ctx, scope.Database, scope.Schema); err != nil {
			return fmt.Errorf("diagram: list relations: %w", err)
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return Assemble(objects, columns, relations), nil
}

// Store keeps loaded graphs per session until the session's schema changes.
type Store struct {
	mu     sync.Mutex
	graphs map[string]*Graph
}

// NewStore returns an empty Store.
func NewStore() *Store { return &Store{graphs: map[string]*Graph{}} }

func storeKey(sessionID string, scope Scope) string {
	return strings.Join([]string{sessionID, scope.Database, scope.Schema, strconv.FormatUint(uint64(scope.SampleSize), 10)}, "\x00")
}

// Get returns the cached graph, or loads and caches it. refresh skips the cache.
func (s *Store) Get(ctx context.Context, sess *session.Session, scope Scope, refresh bool) (*Graph, error) {
	key := storeKey(sess.ID, scope)
	if !refresh {
		s.mu.Lock()
		g, ok := s.graphs[key]
		s.mu.Unlock()
		if ok {
			return g, nil
		}
	}
	g, err := Load(ctx, sess, scope)
	if err != nil {
		return nil, err
	}
	s.mu.Lock()
	s.graphs[key] = g
	s.mu.Unlock()
	return g, nil
}

// Invalidate drops every graph of the session.
func (s *Store) Invalidate(sessionID string) {
	prefix := sessionID + "\x00"
	s.mu.Lock()
	defer s.mu.Unlock()
	for k := range s.graphs {
		if strings.HasPrefix(k, prefix) {
			delete(s.graphs, k)
		}
	}
}
