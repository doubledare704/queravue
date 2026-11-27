package mockdata

import (
	"context"
	"fmt"
	"math/rand/v2"
	"strings"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/sqldialect"
)

// DefaultExistingKeySampleCap bounds how many existing parent keys are loaded.
const DefaultExistingKeySampleCap = 100_000

// KeyPool stores parent keys compactly for child foreign-key sampling.
type KeyPool struct {
	ints    []int64
	strs    []string
	strKind engine.ValueKind
	vals    []engine.Value
}

// Len returns the number of keys stored in the pool.
func (p *KeyPool) Len() int {
	if p == nil {
		return 0
	}
	return len(p.ints) + len(p.strs) + len(p.vals)
}

// Add appends a non-null key value into the most compact representation.
func (p *KeyPool) Add(v engine.Value) {
	if v.Kind == engine.VNull {
		return
	}
	if len(p.vals) == 0 {
		switch v.Kind {
		case engine.VInt:
			if len(p.strs) == 0 {
				p.ints = append(p.ints, v.Int)
				return
			}
		case engine.VText, engine.VUUID, engine.VDecimal:
			if len(p.ints) == 0 && (len(p.strs) == 0 || p.strKind == v.Kind) {
				p.strKind = v.Kind
				p.strs = append(p.strs, v.Str)
				return
			}
		}
		p.spillToVals()
	}
	p.vals = append(p.vals, v)
}

func (p *KeyPool) spillToVals() {
	if len(p.ints) > 0 {
		p.vals = make([]engine.Value, len(p.ints))
		for i, n := range p.ints {
			p.vals[i] = engine.Int(n)
		}
		p.ints = nil
		return
	}
	if len(p.strs) > 0 {
		p.vals = make([]engine.Value, len(p.strs))
		for i, s := range p.strs {
			p.vals[i] = engine.Value{Kind: p.strKind, Str: s}
		}
		p.strs = nil
	}
}

// Pick returns one key chosen uniformly at random.
func (p *KeyPool) Pick(rng *rand.Rand) (engine.Value, bool) {
	n := p.Len()
	if n == 0 {
		return engine.Null(), false
	}
	idx := rng.IntN(n)
	if len(p.ints) > 0 {
		return engine.Int(p.ints[idx]), true
	}
	if len(p.strs) > 0 {
		return engine.Value{Kind: p.strKind, Str: p.strs[idx]}, true
	}
	return p.vals[idx], true
}

type keyPoolKey struct {
	target string
	column string
}

// KeyStore tracks parent key pools across targets in a single run or preview.
type KeyStore struct {
	pools map[keyPoolKey]*KeyPool
}

// NewKeyStore returns an empty KeyStore.
func NewKeyStore() *KeyStore {
	return &KeyStore{pools: map[keyPoolKey]*KeyPool{}}
}

func (s *KeyStore) ensure(targetKey, col string) *KeyPool {
	k := keyPoolKey{target: targetKey, column: strings.ToLower(col)}
	p, ok := s.pools[k]
	if !ok {
		p = &KeyPool{}
		s.pools[k] = p
	}
	return p
}

// Get returns the key pool for targetKey and column, or nil if absent.
func (s *KeyStore) Get(targetKey, col string) *KeyPool {
	return s.pools[keyPoolKey{target: targetKey, column: strings.ToLower(col)}]
}

// Set stores pool under targetKey and column.
func (s *KeyStore) Set(targetKey, col string, pool *KeyPool) {
	s.pools[keyPoolKey{target: targetKey, column: strings.ToLower(col)}] = pool
}

// ExistingKeyLoader reads a capped sample of existing parent keys.
type ExistingKeyLoader interface {
	LoadKeys(ctx context.Context, parent TargetRef, column string, limit int) (*KeyPool, error)
}

// SQLExistingKeyLoader loads existing parent keys using a streaming SELECT.
type SQLExistingKeyLoader struct {
	exec    engine.Executor
	dialect sqldialect.Dialect
}

// NewSQLExistingKeyLoader builds a key loader over ex and dialect.
func NewSQLExistingKeyLoader(ex engine.Executor, dialect sqldialect.Dialect) *SQLExistingKeyLoader {
	return &SQLExistingKeyLoader{exec: ex, dialect: dialect}
}

// LoadKeys streams up to limit non-null keys from parent's column.
func (l *SQLExistingKeyLoader) LoadKeys(ctx context.Context, parent TargetRef, column string, limit int) (*KeyPool, error) {
	if l == nil || l.exec == nil || l.dialect == nil {
		return &KeyPool{}, nil
	}
	if limit <= 0 {
		limit = DefaultExistingKeySampleCap
	}
	qCol := l.dialect.QuoteIdent(column)
	qTable := l.dialect.QualifyTableIn(parent.Database, parent.Schema, parent.Name)
	rawSQL := fmt.Sprintf("SELECT %s FROM %s WHERE %s IS NOT NULL", qCol, qTable, qCol)
	querySQL, _ := l.dialect.Paginate(rawSQL, uint64(limit), false)

	sink := &keyPoolSink{pool: &KeyPool{}, limit: limit}
	_, err := l.exec.Execute(ctx, engine.Statement{SQL: querySQL}, sink)
	if err != nil {
		return nil, fmt.Errorf("mockdata: sample parent keys %s.%s: %w", parent.Name, column, err)
	}
	return sink.pool, nil
}

type keyPoolSink struct {
	pool  *KeyPool
	limit int
}

func (s *keyPoolSink) Columns([]engine.Column) error { return nil }

func (s *keyPoolSink) Batch(rows [][]engine.Value) error {
	for _, r := range rows {
		if len(r) == 0 || r[0].Kind == engine.VNull {
			continue
		}
		s.pool.Add(r[0])
		if s.pool.Len() >= s.limit {
			return engine.ErrStop
		}
	}
	return nil
}
