package workspace

import (
	"bytes"
	"context"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"strings"
)

// DefaultSearchLimit bounds the hits of one search.
const DefaultSearchLimit = 200

// SearchQuery selects files. Text is matched case-insensitively against the
// path, title, description, tags and content; empty matches every script.
// Tags must all be present.
type SearchQuery struct {
	Text   string
	Tags   []string
	RootID string
	Limit  int
}

// Hit is one matching file.
type Hit struct {
	RootID  string
	Path    string
	Kind    Kind
	Meta    Meta
	Snippet string
	Line    int
}

// Search walks the roots and passes each matching script file to emit as it
// is found. It stops when ctx is cancelled, emit fails or the limit is hit.
func (s *Service) Search(ctx context.Context, q SearchQuery, emit func(Hit) error) error {
	roots, err := s.Roots()
	if err != nil {
		return err
	}
	limit := q.Limit
	if limit <= 0 {
		limit = DefaultSearchLimit
	}
	found := 0
	for _, r := range roots {
		if q.RootID != "" && r.ID != q.RootID {
			continue
		}
		realRoot, err := filepath.EvalSymlinks(r.Path)
		if err != nil {
			continue
		}
		stop, err := s.searchRoot(ctx, r.ID, realRoot, q, limit, &found, emit)
		if err != nil {
			return err
		}
		if stop {
			return nil
		}
	}
	return nil
}

func (s *Service) searchRoot(ctx context.Context, id, realRoot string, q SearchQuery, limit int, found *int, emit func(Hit) error) (bool, error) {
	needle := strings.ToLower(strings.TrimSpace(q.Text))
	stopped := false
	walkErr := filepath.WalkDir(realRoot, func(path string, d fs.DirEntry, err error) error {
		if ctxErr := ctx.Err(); ctxErr != nil {
			return fmt.Errorf("workspace: search cancelled: %w", ctxErr)
		}
		if err != nil || path == realRoot {
			return nil //nolint:nilerr // unreadable entries are skipped
		}
		if ignoredName(d.Name()) {
			if d.IsDir() {
				return filepath.SkipDir
			}
			return nil
		}
		if d.IsDir() || d.Type()&fs.ModeSymlink != 0 || !d.Type().IsRegular() {
			return nil
		}
		kind := KindOf(d.Name())
		if kind == KindOther {
			return nil
		}
		hit, ok := s.matchFile(path, relTo(realRoot, path), id, kind, needle, q.Tags)
		if !ok {
			return nil
		}
		if err := emit(hit); err != nil {
			return err
		}
		*found++
		if *found >= limit {
			stopped = true
			return fs.SkipAll
		}
		return nil
	})
	if walkErr != nil {
		return false, fmt.Errorf("workspace: search: %w", walkErr)
	}
	return stopped, nil
}

func (s *Service) matchFile(path, rel, rootID string, kind Kind, needle string, tags []string) (Hit, bool) {
	info, err := os.Stat(path)
	if err != nil || info.Size() > s.opt.MaxFileSize {
		return Hit{}, false
	}
	b, err := os.ReadFile(path) //nolint:gosec // path comes from walking the workspace root
	if err != nil || bytes.IndexByte(b, 0) >= 0 {
		return Hit{}, false
	}
	content := string(b)
	meta := ParseHeader(kind, content)
	if !hasAllTags(meta.Tags, tags) {
		return Hit{}, false
	}
	hit := Hit{RootID: rootID, Path: rel, Kind: kind, Meta: meta}
	if needle == "" || containsFold(rel, needle) || containsFold(meta.Title, needle) ||
		containsFold(meta.Description, needle) || anyTagContains(meta.Tags, needle) {
		return hit, true
	}
	for i, line := range strings.Split(content, "\n") {
		if containsFold(line, needle) {
			hit.Line, hit.Snippet = i+1, strings.TrimSpace(truncate(line, 200))
			return hit, true
		}
	}
	return Hit{}, false
}

func containsFold(s, lowerNeedle string) bool {
	return strings.Contains(strings.ToLower(s), lowerNeedle)
}

func anyTagContains(tags []string, lowerNeedle string) bool {
	for _, t := range tags {
		if containsFold(t, lowerNeedle) {
			return true
		}
	}
	return false
}

func hasAllTags(have, want []string) bool {
	for _, w := range want {
		found := false
		for _, h := range have {
			if strings.EqualFold(h, w) {
				found = true
				break
			}
		}
		if !found {
			return false
		}
	}
	return true
}

func truncate(s string, n int) string {
	if len(s) <= n {
		return s
	}
	return s[:n]
}
