// Package schema provides an in-memory session-scoped cache for database schema metadata.
package schema

import (
	"sync"

	"github.com/doubledare704/queravue/core/internal/engine"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
)

type sessionCache struct {
	databases    []string
	schemas      map[string][]string
	objects      map[string][]engine.SchemaObject
	tableDetails map[string]engine.TableDetails
}

func newSessionCache() *sessionCache {
	return &sessionCache{
		schemas:      make(map[string][]string),
		objects:      make(map[string][]engine.SchemaObject),
		tableDetails: make(map[string]engine.TableDetails),
	}
}

// Cache provides thread-safe, session-scoped schema metadata caching with explicit invalidation.
type Cache struct {
	mu       sync.RWMutex
	sessions map[string]*sessionCache
}

// NewCache initializes an empty schema cache.
func NewCache() *Cache {
	return &Cache{
		sessions: make(map[string]*sessionCache),
	}
}

func (c *Cache) getOrCreate(sessionID string) *sessionCache {
	sc, ok := c.sessions[sessionID]
	if !ok {
		sc = newSessionCache()
		c.sessions[sessionID] = sc
	}
	return sc
}

// GetDatabases returns cached database names for sessionID.
func (c *Cache) GetDatabases(sessionID string) ([]string, bool) {
	c.mu.RLock()
	defer c.mu.RUnlock()
	sc, ok := c.sessions[sessionID]
	if !ok || sc.databases == nil {
		return nil, false
	}
	return sc.databases, true
}

// SetDatabases caches database names for sessionID.
func (c *Cache) SetDatabases(sessionID string, dbs []string) {
	c.mu.Lock()
	defer c.mu.Unlock()
	sc := c.getOrCreate(sessionID)
	sc.databases = dbs
}

// GetSchemas returns cached schemas for database in sessionID.
func (c *Cache) GetSchemas(sessionID, database string) ([]string, bool) {
	c.mu.RLock()
	defer c.mu.RUnlock()
	sc, ok := c.sessions[sessionID]
	if !ok {
		return nil, false
	}
	s, ok := sc.schemas[database]
	return s, ok
}

// SetSchemas caches schemas for database in sessionID.
func (c *Cache) SetSchemas(sessionID, database string, schemas []string) {
	c.mu.Lock()
	defer c.mu.Unlock()
	sc := c.getOrCreate(sessionID)
	sc.schemas[database] = schemas
}

func objKey(database, schema string) string {
	return database + "." + schema
}

// GetObjects returns cached objects for schema in sessionID.
func (c *Cache) GetObjects(sessionID, database, schema string) ([]engine.SchemaObject, bool) {
	c.mu.RLock()
	defer c.mu.RUnlock()
	sc, ok := c.sessions[sessionID]
	if !ok {
		return nil, false
	}
	objs, ok := sc.objects[objKey(database, schema)]
	return objs, ok
}

// SetObjects caches objects for schema in sessionID.
func (c *Cache) SetObjects(sessionID, database, schema string, objs []engine.SchemaObject) {
	c.mu.Lock()
	defer c.mu.Unlock()
	sc := c.getOrCreate(sessionID)
	sc.objects[objKey(database, schema)] = objs
}

func tableKey(database, schema, table string) string {
	return database + "." + schema + "." + table
}

// GetTableDetails returns cached table details for sessionID.
func (c *Cache) GetTableDetails(sessionID, database, schema, table string) (engine.TableDetails, bool) {
	c.mu.RLock()
	defer c.mu.RUnlock()
	sc, ok := c.sessions[sessionID]
	if !ok {
		return engine.TableDetails{}, false
	}
	td, ok := sc.tableDetails[tableKey(database, schema, table)]
	return td, ok
}

// SetTableDetails caches table details for sessionID.
func (c *Cache) SetTableDetails(sessionID, database, schema, table string, details engine.TableDetails) {
	c.mu.Lock()
	defer c.mu.Unlock()
	sc := c.getOrCreate(sessionID)
	sc.tableDetails[tableKey(database, schema, table)] = details
}

// Invalidate clears all or targeted schema cache entries for a session.
func (c *Cache) Invalidate(sessionID string, ref *queravuev1.TableRef) {
	c.mu.Lock()
	defer c.mu.Unlock()
	sc, ok := c.sessions[sessionID]
	if !ok {
		return
	}
	if ref == nil || (ref.GetDatabase() == "" && ref.GetSchema() == "" && ref.GetTable() == "") {
		delete(c.sessions, sessionID)
		return
	}
	if ref.GetTable() != "" {
		delete(sc.tableDetails, tableKey(ref.GetDatabase(), ref.GetSchema(), ref.GetTable()))
		delete(sc.objects, objKey(ref.GetDatabase(), ref.GetSchema()))
		return
	}
	if ref.GetSchema() != "" {
		delete(sc.objects, objKey(ref.GetDatabase(), ref.GetSchema()))
		delete(sc.schemas, ref.GetDatabase())
		return
	}
	if ref.GetDatabase() != "" {
		delete(sc.schemas, ref.GetDatabase())
		sc.databases = nil
	}
}

// CloseSession discards all cache data for sessionID.
func (c *Cache) CloseSession(sessionID string) {
	c.mu.Lock()
	defer c.mu.Unlock()
	delete(c.sessions, sessionID)
}
