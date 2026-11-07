// Package workspace stores saved queries and scripts as plain files in
// user-chosen folders. See docs/adr/0011-workspace-saved-queries.md.
package workspace

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"sync"
	"time"

	"github.com/google/uuid"
)

// Defaults.
const (
	DefaultMaxFileSize = 2 << 20
	DefaultRootID      = "default"
	settingsFile       = "workspace.json"
	headerReadSize     = 8 << 10
)

// Root is a workspace folder.
type Root struct {
	ID   string `json:"id"`
	Name string `json:"name"`
	Path string `json:"path"`
}

// Entry is one file or folder of a directory listing.
type Entry struct {
	Name    string
	IsDir   bool
	Kind    Kind
	Size    int64
	ModTime time.Time
	Meta    Meta
}

// File is a file read from disk.
type File struct {
	Content string
	ModTime time.Time
	Hash    string
	Meta    Meta
	Kind    Kind
}

// Options configures a Service.
type Options struct {
	// ConfigDir holds workspace.json, the list of roots.
	ConfigDir string
	// DefaultRoot is the folder used when no roots are configured.
	DefaultRoot string
	// MaxFileSize bounds the files read, written and searched.
	MaxFileSize int64
	// DebounceInterval is the quiet time Watch waits before reporting.
	DebounceInterval time.Duration
}

// Service manages workspace roots and the files inside them.
type Service struct {
	opt Options

	mu    sync.Mutex
	roots []Root
	ready bool

	writeMu sync.Mutex

	ownMu  sync.Mutex
	ownOps map[string]time.Time
	hashes map[string]string
	subs   map[int]chan renameEvent
	nextID int
}

// NewService returns a Service. Roots are loaded on first use.
func NewService(opt Options) *Service {
	if opt.MaxFileSize <= 0 {
		opt.MaxFileSize = DefaultMaxFileSize
	}
	if opt.DebounceInterval <= 0 {
		opt.DebounceInterval = 200 * time.Millisecond
	}
	return &Service{opt: opt, ownOps: map[string]time.Time{}, hashes: map[string]string{}, subs: map[int]chan renameEvent{}}
}

// DefaultRootPath returns ~/Queravue/workspace.
func DefaultRootPath() (string, error) {
	home, err := os.UserHomeDir()
	if err != nil {
		return "", fmt.Errorf("workspace: locate home directory: %w", err)
	}
	return filepath.Join(home, "Queravue", "workspace"), nil
}

type settings struct {
	Version int    `json:"version"`
	Roots   []Root `json:"roots"`
}

func (s *Service) settingsPath() string { return filepath.Join(s.opt.ConfigDir, settingsFile) }

func (s *Service) load() error {
	if s.ready {
		return nil
	}
	b, err := os.ReadFile(s.settingsPath())
	switch {
	case err == nil:
		var f settings
		if err := json.Unmarshal(b, &f); err != nil {
			return fmt.Errorf("workspace: parse %s: %w", s.settingsPath(), err)
		}
		s.roots = f.Roots
	case errors.Is(err, os.ErrNotExist):
		path := s.opt.DefaultRoot
		if path == "" {
			if path, err = DefaultRootPath(); err != nil {
				return err
			}
		}
		s.roots = []Root{{ID: DefaultRootID, Name: "Workspace", Path: path}}
	default:
		return fmt.Errorf("workspace: read %s: %w", s.settingsPath(), err)
	}
	for _, r := range s.roots {
		if err := os.MkdirAll(r.Path, 0o750); err != nil {
			return fmt.Errorf("workspace: create %s: %w", r.Path, err)
		}
	}
	s.ready = true
	return nil
}

// Roots returns the configured roots.
func (s *Service) Roots() ([]Root, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if err := s.load(); err != nil {
		return nil, err
	}
	return append([]Root(nil), s.roots...), nil
}

// SetRoots replaces the roots. Entries without an id get one; folders are
// created. At least one root is required and paths must be absolute and
// unique.
func (s *Service) SetRoots(roots []Root) ([]Root, error) {
	if len(roots) == 0 {
		return nil, newError(KindIO, "at least one workspace folder is required", nil)
	}
	out := make([]Root, 0, len(roots))
	seenPath, seenID := map[string]bool{}, map[string]bool{}
	for _, r := range roots {
		if !filepath.IsAbs(r.Path) {
			return nil, newError(KindIO, "workspace folder must be an absolute path: "+r.Path, nil)
		}
		r.Path = filepath.Clean(r.Path)
		if r.ID == "" {
			r.ID = uuid.NewString()
		}
		if r.Name == "" {
			r.Name = filepath.Base(r.Path)
		}
		if seenPath[r.Path] || seenID[r.ID] {
			return nil, newError(KindAlreadyExists, "duplicate workspace folder: "+r.Path, nil)
		}
		seenPath[r.Path], seenID[r.ID] = true, true
		if err := os.MkdirAll(r.Path, 0o750); err != nil {
			return nil, newError(KindIO, "cannot create "+r.Path, err)
		}
		out = append(out, r)
	}
	b, err := json.MarshalIndent(settings{Version: 1, Roots: out}, "", "  ")
	if err != nil {
		return nil, fmt.Errorf("workspace: encode settings: %w", err)
	}
	if err := os.MkdirAll(s.opt.ConfigDir, 0o750); err != nil {
		return nil, fmt.Errorf("workspace: create config dir: %w", err)
	}
	if err := atomicWrite(s.settingsPath(), b, 0o644); err != nil {
		return nil, err
	}
	s.mu.Lock()
	s.roots, s.ready = out, true
	s.mu.Unlock()
	return append([]Root(nil), out...), nil
}

func (s *Service) root(id string) (Root, error) {
	roots, err := s.Roots()
	if err != nil {
		return Root{}, err
	}
	for _, r := range roots {
		if r.ID == id {
			return r, nil
		}
	}
	return Root{}, newError(KindNotFound, "unknown workspace folder", nil)
}

func (s *Service) locate(rootID, rel string) (Root, string, error) {
	r, err := s.root(rootID)
	if err != nil {
		return r, "", err
	}
	abs, err := resolve(r.Path, rel)
	return r, abs, err
}

func hashOf(b []byte) string {
	sum := sha256.Sum256(b)
	return hex.EncodeToString(sum[:])
}

func ioError(what string, err error) error {
	switch {
	case errors.Is(err, os.ErrNotExist):
		return newError(KindNotFound, what+": not found", err)
	case errors.Is(err, os.ErrExist):
		return newError(KindAlreadyExists, what+": already exists", err)
	}
	return newError(KindIO, what+": "+err.Error(), err)
}

// ListTree lists one directory, folders first, then by name.
func (s *Service) ListTree(rootID, rel string) ([]Entry, error) {
	_, abs, err := s.locate(rootID, rel)
	if err != nil {
		return nil, err
	}
	dirEntries, err := os.ReadDir(abs)
	if err != nil {
		return nil, ioError("list "+rel, err)
	}
	out := make([]Entry, 0, len(dirEntries))
	for _, de := range dirEntries {
		if ignoredName(de.Name()) {
			continue
		}
		info, err := os.Stat(filepath.Join(abs, de.Name()))
		if err != nil {
			continue
		}
		e := Entry{Name: de.Name(), IsDir: info.IsDir(), Size: info.Size(), ModTime: info.ModTime()}
		if !e.IsDir {
			e.Kind = KindOf(e.Name)
			if e.Kind != KindOther {
				e.Meta = readMeta(filepath.Join(abs, de.Name()), e.Kind)
			}
		}
		out = append(out, e)
	}
	sort.Slice(out, func(i, j int) bool {
		if out[i].IsDir != out[j].IsDir {
			return out[i].IsDir
		}
		return strings.ToLower(out[i].Name) < strings.ToLower(out[j].Name)
	})
	return out, nil
}

func readMeta(path string, k Kind) Meta {
	f, err := os.Open(path) //nolint:gosec // path is resolved inside the workspace root
	if err != nil {
		return Meta{}
	}
	defer func() { _ = f.Close() }()
	buf := make([]byte, headerReadSize)
	n, _ := io.ReadFull(f, buf)
	return ParseHeader(k, string(buf[:n]))
}

func (s *Service) readAbs(abs, what string) (*File, error) {
	info, err := os.Stat(abs)
	if err != nil {
		return nil, ioError(what, err)
	}
	if info.IsDir() {
		return nil, newError(KindIO, what+" is a folder", nil)
	}
	if info.Size() > s.opt.MaxFileSize {
		return nil, newError(KindTooLarge, fmt.Sprintf("%s is larger than %d bytes", what, s.opt.MaxFileSize), nil)
	}
	b, err := os.ReadFile(abs) //nolint:gosec // abs is resolved inside the workspace root
	if err != nil {
		return nil, ioError(what, err)
	}
	kind := KindOf(abs)
	text := string(b)
	return &File{Content: text, ModTime: info.ModTime(), Hash: hashOf(b), Kind: kind, Meta: ParseHeader(kind, text)}, nil
}

// Read returns a file.
func (s *Service) Read(rootID, rel string) (*File, error) {
	_, abs, err := s.locate(rootID, rel)
	if err != nil {
		return nil, err
	}
	return s.readAbs(abs, rel)
}

// WriteCheck is the optimistic-concurrency guard of Write. If ExpectedHash is
// set it alone decides; otherwise a set ExpectedMtime decides. Force skips it.
type WriteCheck struct {
	ExpectedMtime time.Time
	ExpectedHash  string
	Force         bool
}

func (c WriteCheck) active() bool {
	return !c.Force && (c.ExpectedHash != "" || !c.ExpectedMtime.IsZero())
}

func (c WriteCheck) conflicts(cur *File) bool {
	if cur == nil {
		return true
	}
	if c.ExpectedHash != "" {
		return cur.Hash != c.ExpectedHash
	}
	return !cur.ModTime.Equal(c.ExpectedMtime)
}

// Write replaces a file atomically. On a failed check it returns a
// KindConflict error carrying the current file (nil if deleted).
func (s *Service) Write(rootID, rel, content string, check WriteCheck) (*File, error) {
	if int64(len(content)) > s.opt.MaxFileSize {
		return nil, newError(KindTooLarge, fmt.Sprintf("content is larger than %d bytes", s.opt.MaxFileSize), nil)
	}
	_, abs, err := s.locate(rootID, rel)
	if err != nil {
		return nil, err
	}
	s.writeMu.Lock()
	defer s.writeMu.Unlock()
	mode := os.FileMode(0o644)
	cur, readErr := s.readAbs(abs, rel)
	var typed *Error
	switch {
	case readErr == nil:
		if info, err := os.Stat(abs); err == nil {
			mode = info.Mode().Perm()
		}
	case errors.As(readErr, &typed) && typed.Kind == KindNotFound:
		cur = nil
	case errors.As(readErr, &typed) && typed.Kind == KindTooLarge:
		cur = &File{Hash: "too-large"}
	default:
		return nil, readErr
	}
	if check.active() && check.conflicts(cur) {
		e := newError(KindConflict, rel+" changed on disk", nil)
		e.Current = cur
		return nil, e
	}
	if err := os.MkdirAll(filepath.Dir(abs), 0o750); err != nil {
		return nil, ioError("write "+rel, err)
	}
	if err := atomicWrite(abs, []byte(content), mode); err != nil {
		return nil, ioError("write "+rel, err)
	}
	s.noteWrite(abs, hashOf([]byte(content)))
	return s.readAbs(abs, rel)
}

// Create makes a new file with content, or a folder. It fails with
// KindAlreadyExists if the path exists.
func (s *Service) Create(rootID, rel string, isDir bool, content string) (*File, error) {
	if strings.Trim(rel, "/") == "" {
		return nil, newError(KindAlreadyExists, "the workspace folder already exists", nil)
	}
	if int64(len(content)) > s.opt.MaxFileSize {
		return nil, newError(KindTooLarge, fmt.Sprintf("content is larger than %d bytes", s.opt.MaxFileSize), nil)
	}
	_, abs, err := s.locate(rootID, rel)
	if err != nil {
		return nil, err
	}
	s.writeMu.Lock()
	defer s.writeMu.Unlock()
	if _, err := os.Lstat(abs); err == nil {
		return nil, newError(KindAlreadyExists, rel+" already exists", nil)
	}
	if err := os.MkdirAll(filepath.Dir(abs), 0o750); err != nil {
		return nil, ioError("create "+rel, err)
	}
	if isDir {
		if err := os.Mkdir(abs, 0o750); err != nil {
			return nil, ioError("create "+rel, err)
		}
		s.noteOp(abs)
		return nil, nil
	}
	f, err := os.OpenFile(abs, os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0o644) //nolint:gosec // abs is resolved inside the workspace root
	if err != nil {
		return nil, ioError("create "+rel, err)
	}
	_, werr := f.WriteString(content)
	if cerr := f.Close(); werr == nil {
		werr = cerr
	}
	if werr != nil {
		_ = os.Remove(abs)
		return nil, ioError("create "+rel, werr)
	}
	s.noteWrite(abs, hashOf([]byte(content)))
	return s.readAbs(abs, rel)
}

// Rename renames or moves a file or folder inside one root. Missing parent
// folders of the target are created.
func (s *Service) Rename(rootID, from, to string) error {
	r, src, err := s.locate(rootID, from)
	if err != nil {
		return err
	}
	_, dst, err := s.locate(rootID, to)
	if err != nil {
		return err
	}
	realRoot, _ := filepath.EvalSymlinks(r.Path)
	if src == realRoot || dst == realRoot {
		return newError(KindIO, "the workspace folder cannot be renamed", nil)
	}
	if within(src, dst) {
		return newError(KindIO, "cannot move a folder into itself", nil)
	}
	s.writeMu.Lock()
	defer s.writeMu.Unlock()
	if _, err := os.Lstat(src); err != nil {
		return ioError(from, err)
	}
	if _, err := os.Lstat(dst); err == nil {
		return newError(KindAlreadyExists, to+" already exists", nil)
	}
	if err := os.MkdirAll(filepath.Dir(dst), 0o750); err != nil {
		return ioError("rename "+from, err)
	}
	if err := os.Rename(src, dst); err != nil {
		return ioError("rename "+from, err)
	}
	s.noteOp(src)
	s.noteOp(dst)
	s.publishRename(rootID, relTo(realRoot, src), relTo(realRoot, dst), dst)
	return nil
}

// Delete removes a file, or a folder with its contents.
func (s *Service) Delete(rootID, rel string) error {
	r, abs, err := s.locate(rootID, rel)
	if err != nil {
		return err
	}
	realRoot, _ := filepath.EvalSymlinks(r.Path)
	if abs == realRoot {
		return newError(KindIO, "the workspace folder cannot be deleted", nil)
	}
	s.writeMu.Lock()
	defer s.writeMu.Unlock()
	if _, err := os.Lstat(abs); err != nil {
		return ioError(rel, err)
	}
	if err := os.RemoveAll(abs); err != nil {
		return ioError("delete "+rel, err)
	}
	s.noteOp(abs)
	s.ownMu.Lock()
	delete(s.hashes, abs)
	s.ownMu.Unlock()
	return nil
}

func atomicWrite(path string, data []byte, mode os.FileMode) error {
	dir := filepath.Dir(path)
	tmp, err := os.CreateTemp(dir, tempPrefix+"*")
	if err != nil {
		return fmt.Errorf("workspace: create temp file: %w", err)
	}
	name := tmp.Name()
	cleanup := func() { _ = os.Remove(name) }
	if _, err := io.Copy(tmp, bytes.NewReader(data)); err != nil {
		_ = tmp.Close()
		cleanup()
		return fmt.Errorf("workspace: write temp file: %w", err)
	}
	if err := tmp.Sync(); err != nil {
		_ = tmp.Close()
		cleanup()
		return fmt.Errorf("workspace: sync temp file: %w", err)
	}
	if err := tmp.Close(); err != nil {
		cleanup()
		return fmt.Errorf("workspace: close temp file: %w", err)
	}
	if err := os.Chmod(name, mode); err != nil {
		cleanup()
		return fmt.Errorf("workspace: chmod temp file: %w", err)
	}
	if err := os.Rename(name, path); err != nil {
		cleanup()
		return fmt.Errorf("workspace: replace %s: %w", filepath.Base(path), err)
	}
	if d, err := os.Open(dir); err == nil { //nolint:gosec // dir is the parent of a resolved workspace path
		_ = d.Sync()
		_ = d.Close()
	}
	return nil
}
