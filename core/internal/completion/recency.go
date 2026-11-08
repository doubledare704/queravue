package completion

import (
	"sync"
	"time"
)

const (
	recencyVeryRecent = 2 * time.Minute
	recencyRecent     = 30 * time.Minute
	recencyMaxEntries = 1024
)

// Recency remembers which names a session used lately.
type Recency struct {
	mu   sync.Mutex
	now  func() time.Time
	last map[string]time.Time
}

// NewRecency returns an empty Recency.
func NewRecency() *Recency { return &Recency{now: time.Now, last: map[string]time.Time{}} }

// Touch marks names as just used, case-insensitively.
func (r *Recency) Touch(names ...string) {
	if r == nil {
		return
	}
	r.mu.Lock()
	defer r.mu.Unlock()
	at := r.now()
	for _, n := range names {
		r.last[lower(n)] = at
	}
	if len(r.last) > recencyMaxEntries {
		for k, t := range r.last {
			if at.Sub(t) > recencyRecent {
				delete(r.last, k)
			}
		}
	}
}

// bucket is 0 for names used very recently, 1 for recently, 2 otherwise.
func (r *Recency) bucket(name string) int {
	if r == nil {
		return 2
	}
	r.mu.Lock()
	at, ok := r.last[lower(name)]
	now := r.now()
	r.mu.Unlock()
	switch {
	case !ok:
		return 2
	case now.Sub(at) < recencyVeryRecent:
		return 0
	case now.Sub(at) < recencyRecent:
		return 1
	}
	return 2
}

// SetClock replaces the time source, for tests.
func (r *Recency) SetClock(now func() time.Time) {
	r.mu.Lock()
	r.now = now
	r.mu.Unlock()
}
