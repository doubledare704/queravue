package workspace

import (
	"context"
	"io/fs"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"

	"github.com/fsnotify/fsnotify"
)

// ChangeKind is what happened to a path.
type ChangeKind int

// Change kinds.
const (
	ChangeCreated ChangeKind = iota + 1
	ChangeModified
	ChangeDeleted
	ChangeRenamed
)

// Change reports a change on disk. Path is relative to the root.
type Change struct {
	RootID  string
	Path    string
	Kind    ChangeKind
	OldPath string
	ModTime time.Time
}

const ownOpTTL = 2 * time.Second

type renameEvent struct {
	rootID, from, to, abs string
}

func (s *Service) noteWrite(abs, hash string) {
	s.ownMu.Lock()
	defer s.ownMu.Unlock()
	s.hashes[abs] = hash
	s.ownOps[abs] = time.Now()
}

// Called before touching the file: a watcher flush between the write and noteWrite must not see it as external.
func (s *Service) beginOwnWrite(abs string) {
	s.ownMu.Lock()
	defer s.ownMu.Unlock()
	delete(s.hashes, abs)
	s.ownOps[abs] = time.Now()
}

func (s *Service) noteOp(abs string) {
	s.ownMu.Lock()
	defer s.ownMu.Unlock()
	s.ownOps[abs] = time.Now()
}

// ownChange reports whether a change at abs was caused by this service.
func (s *Service) ownChange(abs string, exists bool) bool {
	s.ownMu.Lock()
	defer s.ownMu.Unlock()
	now := time.Now()
	for p, t := range s.ownOps {
		if now.Sub(t) > ownOpTTL {
			delete(s.ownOps, p)
		}
	}
	want, hasHash := s.hashes[abs]
	if exists && hasHash {
		b, err := os.ReadFile(abs) //nolint:gosec // abs lies inside a workspace root
		if err == nil && hashOf(b) == want {
			return true
		}
		delete(s.hashes, abs)
		return false
	}
	_, own := s.ownOps[abs]
	return own
}

func (s *Service) publishRename(rootID, from, to, abs string) {
	s.ownMu.Lock()
	defer s.ownMu.Unlock()
	for _, ch := range s.subs {
		select {
		case ch <- renameEvent{rootID: rootID, from: from, to: to, abs: abs}:
		default:
		}
	}
}

func (s *Service) subscribe() (<-chan renameEvent, func()) {
	s.ownMu.Lock()
	defer s.ownMu.Unlock()
	s.nextID++
	id := s.nextID
	ch := make(chan renameEvent, 64)
	s.subs[id] = ch
	return ch, func() {
		s.ownMu.Lock()
		delete(s.subs, id)
		s.ownMu.Unlock()
	}
}

type pending struct {
	created, removed bool
}

type watchedRoot struct {
	id, real string
}

// Watch reports changes under the given roots (all roots if rootIDs is
// empty) until ctx is cancelled. Bursts of events for one path are coalesced
// after the debounce interval, and changes made by this service are not
// reported, except renames, which arrive as one ChangeRenamed.
func (s *Service) Watch(ctx context.Context, rootIDs []string, emit func(Change) error) error {
	roots, err := s.watchedRoots(rootIDs)
	if err != nil {
		return err
	}
	w, err := fsnotify.NewWatcher()
	if err != nil {
		return newError(KindIO, "cannot watch the workspace", err)
	}
	defer func() { _ = w.Close() }()
	renames, unsubscribe := s.subscribe()
	defer unsubscribe()

	pend := map[string]*pending{}
	mark := func(path string, f func(*pending)) {
		p := pend[path]
		if p == nil {
			p = &pending{}
			pend[path] = p
		}
		f(p)
	}
	for _, r := range roots {
		addTree(w, r.real, nil)
	}
	timer := time.NewTimer(time.Hour)
	timer.Stop()
	defer timer.Stop()

	for {
		select {
		case <-ctx.Done():
			return nil
		case ev, ok := <-w.Events:
			if !ok {
				return nil
			}
			if skipPath(roots, ev.Name) {
				continue
			}
			s.handleEvent(w, ev, mark)
			timer.Reset(s.opt.DebounceInterval)
		case err := <-w.Errors:
			_ = err
		case r := <-renames:
			if !wantsRoot(roots, r.rootID) {
				continue
			}
			c := Change{RootID: r.rootID, Path: r.to, OldPath: r.from, Kind: ChangeRenamed}
			if info, err := os.Stat(r.abs); err == nil {
				c.ModTime = info.ModTime()
			}
			if err := emit(c); err != nil {
				return err
			}
		case <-timer.C:
			if err := s.flush(roots, pend, emit); err != nil {
				return err
			}
			pend = map[string]*pending{}
		}
	}
}

func (s *Service) watchedRoots(ids []string) ([]watchedRoot, error) {
	all, err := s.Roots()
	if err != nil {
		return nil, err
	}
	var out []watchedRoot
	for _, r := range all {
		if len(ids) > 0 && !containsString(ids, r.ID) {
			continue
		}
		resolved, err := filepath.EvalSymlinks(r.Path)
		if err != nil {
			continue
		}
		out = append(out, watchedRoot{id: r.ID, real: resolved})
	}
	return out, nil
}

func containsString(list []string, s string) bool {
	for _, v := range list {
		if v == s {
			return true
		}
	}
	return false
}

func wantsRoot(roots []watchedRoot, id string) bool {
	for _, r := range roots {
		if r.id == id {
			return true
		}
	}
	return false
}

func skipPath(roots []watchedRoot, abs string) bool {
	for _, r := range roots {
		if !within(r.real, abs) {
			continue
		}
		for _, part := range strings.Split(relTo(r.real, abs), "/") {
			if ignoredName(part) {
				return true
			}
		}
		return false
	}
	return true
}

func addTree(w *fsnotify.Watcher, dir string, visit func(path string)) {
	_ = filepath.WalkDir(dir, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return nil //nolint:nilerr // unreadable entries are skipped
		}
		if ignoredName(d.Name()) && path != dir {
			if d.IsDir() {
				return filepath.SkipDir
			}
			return nil
		}
		if d.IsDir() {
			_ = w.Add(path)
		}
		if visit != nil && path != dir {
			visit(path)
		}
		return nil
	})
}

func (s *Service) handleEvent(w *fsnotify.Watcher, ev fsnotify.Event, mark func(string, func(*pending))) {
	if ev.Has(fsnotify.Create) {
		mark(ev.Name, func(p *pending) { p.created = true })
		if info, err := os.Lstat(ev.Name); err == nil && info.IsDir() {
			addTree(w, ev.Name, func(path string) {
				mark(path, func(p *pending) { p.created = true })
			})
		}
	}
	if ev.Has(fsnotify.Write) || ev.Has(fsnotify.Chmod) {
		mark(ev.Name, func(*pending) {})
	}
	if ev.Has(fsnotify.Remove) || ev.Has(fsnotify.Rename) {
		mark(ev.Name, func(p *pending) { p.removed = true })
	}
}

func (s *Service) flush(roots []watchedRoot, pend map[string]*pending, emit func(Change) error) error {
	paths := make([]string, 0, len(pend))
	for p := range pend {
		paths = append(paths, p)
	}
	sort.Strings(paths)
	for _, abs := range paths {
		p := pend[abs]
		info, err := os.Lstat(abs)
		exists := err == nil
		if exists && info.IsDir() && !p.created {
			continue
		}
		if !exists && p.created && !p.removed {
			continue
		}
		var kind ChangeKind
		switch {
		case !exists:
			if p.created {
				continue
			}
			kind = ChangeDeleted
		case p.created && !p.removed:
			kind = ChangeCreated
		default:
			kind = ChangeModified
		}
		if s.ownChange(abs, exists) {
			continue
		}
		for _, r := range roots {
			if !within(r.real, abs) {
				continue
			}
			c := Change{RootID: r.id, Path: relTo(r.real, abs), Kind: kind}
			if exists {
				c.ModTime = info.ModTime()
			}
			if err := emit(c); err != nil {
				return err
			}
		}
	}
	return nil
}
