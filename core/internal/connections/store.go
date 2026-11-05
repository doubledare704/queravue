package connections

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"sync"
)

// FileName is the config file inside the config dir.
const FileName = "connections.json"

const fileVersion = 1

type fileFormat struct {
	Version     int          `json:"version"`
	Connections []Connection `json:"connections"`
}

// FileStore persists connections as JSON in one file, written atomically.
type FileStore struct {
	dir string
	mu  sync.Mutex
}

// NewFileStore returns a store for dir/connections.json. dir is created on
// first save.
func NewFileStore(dir string) *FileStore { return &FileStore{dir: dir} }

// Path returns the file path.
func (s *FileStore) Path() string { return filepath.Join(s.dir, FileName) }

// Load reads all connections. A missing file is an empty list. A corrupt file
// is an error, and the file is left untouched.
func (s *FileStore) Load() ([]Connection, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	b, err := os.ReadFile(s.Path())
	if errors.Is(err, os.ErrNotExist) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("connections: read %s: %w", s.Path(), err)
	}
	var f fileFormat
	if err := json.Unmarshal(b, &f); err != nil {
		return nil, fmt.Errorf("connections: parse %s: %w", s.Path(), err)
	}
	if f.Version > fileVersion {
		return nil, fmt.Errorf("connections: %s has version %d; this core supports %d", s.Path(), f.Version, fileVersion)
	}
	return f.Connections, nil
}

// Save replaces the file with conns. It writes a temp file in the same
// directory, fsyncs it, renames it over the target and fsyncs the directory,
// so a crash leaves either the old or the new file, never a partial one.
func (s *FileStore) Save(conns []Connection) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	if conns == nil {
		conns = []Connection{}
	}
	b, err := json.MarshalIndent(fileFormat{Version: fileVersion, Connections: conns}, "", "  ")
	if err != nil {
		return fmt.Errorf("connections: encode: %w", err)
	}
	b = append(b, '\n')
	if err := os.MkdirAll(s.dir, 0o700); err != nil {
		return fmt.Errorf("connections: create dir: %w", err)
	}
	return writeAtomic(s.Path(), b)
}

func writeAtomic(path string, data []byte) (err error) {
	dir := filepath.Dir(path)
	tmp, err := os.CreateTemp(dir, "."+filepath.Base(path)+".tmp-*")
	if err != nil {
		return fmt.Errorf("connections: create temp: %w", err)
	}
	tmpName := tmp.Name()
	defer func() {
		if err != nil {
			_ = tmp.Close()
			_ = os.Remove(tmpName)
		}
	}()
	if err = tmp.Chmod(0o600); err != nil {
		return fmt.Errorf("connections: chmod temp: %w", err)
	}
	if _, err = tmp.Write(data); err != nil {
		return fmt.Errorf("connections: write temp: %w", err)
	}
	if err = tmp.Sync(); err != nil {
		return fmt.Errorf("connections: sync temp: %w", err)
	}
	if err = tmp.Close(); err != nil {
		return fmt.Errorf("connections: close temp: %w", err)
	}
	if err = os.Rename(tmpName, path); err != nil {
		return fmt.Errorf("connections: rename: %w", err)
	}
	if d, derr := os.Open(dir); derr == nil { //nolint:gosec // dir is our own config dir
		_ = d.Sync()
		_ = d.Close()
	}
	return nil
}
