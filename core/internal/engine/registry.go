package engine

import (
	"fmt"
	"sync"
)

// Registry holds the engines a core supports, in registration order.
type Registry struct {
	mu      sync.RWMutex
	order   []string
	engines map[string]Engine
}

// NewRegistry returns a registry with the given engines.
func NewRegistry(engines ...Engine) (*Registry, error) {
	r := &Registry{engines: map[string]Engine{}}
	for _, e := range engines {
		if err := r.Register(e); err != nil {
			return nil, err
		}
	}
	return r, nil
}

// Register adds e. Its id must be unique and it must declare CapConnect.
func (r *Registry) Register(e Engine) error {
	d := e.Descriptor()
	if d.ID == "" {
		return fmt.Errorf("engine: register: empty id")
	}
	if !d.HasCapability(CapConnect) {
		return fmt.Errorf("engine: register %s: missing %q capability", d.ID, CapConnect)
	}
	r.mu.Lock()
	defer r.mu.Unlock()
	if _, dup := r.engines[d.ID]; dup {
		return fmt.Errorf("engine: register %s: duplicate id", d.ID)
	}
	r.engines[d.ID] = e
	r.order = append(r.order, d.ID)
	return nil
}

// Get returns the engine with id.
func (r *Registry) Get(id string) (Engine, bool) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	e, ok := r.engines[id]
	return e, ok
}

// List returns all engines in registration order.
func (r *Registry) List() []Engine {
	r.mu.RLock()
	defer r.mu.RUnlock()
	out := make([]Engine, 0, len(r.order))
	for _, id := range r.order {
		out = append(out, r.engines[id])
	}
	return out
}
