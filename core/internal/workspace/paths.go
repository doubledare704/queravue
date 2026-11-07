package workspace

import (
	"os"
	"path/filepath"
	"strings"
)

// Kind says what a workspace file is for.
type Kind int

// File kinds.
const (
	KindOther Kind = iota
	KindSQL
	KindMongo
)

// KindOf returns the kind of a file from its name.
func KindOf(name string) Kind {
	switch {
	case strings.HasSuffix(name, ".mongo.js"):
		return KindMongo
	case strings.HasSuffix(name, ".sql"):
		return KindSQL
	}
	return KindOther
}

const tempPrefix = ".qv-write-"

func ignoredName(name string) bool {
	return name == ".git" || strings.HasPrefix(name, tempPrefix)
}

func within(root, p string) bool {
	return p == root || strings.HasPrefix(p, root+string(filepath.Separator))
}

// resolve maps a root-relative slash path to an absolute path that is
// guaranteed to stay inside root, following symlinks of the part that exists.
func resolve(root, rel string) (string, error) {
	realRoot, err := filepath.EvalSymlinks(root)
	if err != nil {
		return "", newError(KindNotFound, "workspace folder not found", err)
	}
	if strings.ContainsRune(rel, 0) || filepath.IsAbs(filepath.FromSlash(rel)) || strings.HasPrefix(rel, "/") || filepath.VolumeName(rel) != "" {
		return "", newError(KindPathEscapesRoot, "path must be relative to the workspace", nil)
	}
	clean := filepath.Clean(filepath.FromSlash(rel))
	if clean == ".." || strings.HasPrefix(clean, ".."+string(filepath.Separator)) {
		return "", newError(KindPathEscapesRoot, "path leaves the workspace", nil)
	}
	abs := filepath.Join(realRoot, clean)
	existing, tail := abs, []string{}
	for {
		if _, err := os.Lstat(existing); err == nil {
			break
		}
		parent := filepath.Dir(existing)
		if parent == existing {
			break
		}
		tail = append([]string{filepath.Base(existing)}, tail...)
		existing = parent
	}
	resolved, err := filepath.EvalSymlinks(existing)
	if err != nil {
		return "", newError(KindNotFound, "path not found", err)
	}
	if !within(realRoot, resolved) {
		return "", newError(KindPathEscapesRoot, "path leaves the workspace", nil)
	}
	return filepath.Join(append([]string{resolved}, tail...)...), nil
}

// relTo returns the slash-separated path of abs relative to root's real path.
func relTo(realRoot, abs string) string {
	rel, err := filepath.Rel(realRoot, abs)
	if err != nil || rel == "." {
		return ""
	}
	return filepath.ToSlash(rel)
}
