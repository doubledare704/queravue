package sqlite

import (
	"errors"
	"net/url"
	"strings"
)

// parseURI accepts sqlite:///abs/path, sqlite://rel/path, file:path?mode=ro
// and bare paths.
func parseURI(s string) (map[string]string, error) {
	s = strings.TrimSpace(s)
	if s == "" {
		return nil, errors.New("empty connection string")
	}
	var path, query string
	switch {
	case strings.HasPrefix(s, "sqlite://"), strings.HasPrefix(s, "sqlite3://"):
		rest := s[strings.Index(s, "://")+3:]
		path, query, _ = strings.Cut(rest, "?")
	case strings.HasPrefix(s, "file:"):
		rest := strings.TrimPrefix(s, "file:")
		path, query, _ = strings.Cut(rest, "?")
		// file:///abs → /abs; file://localhost/abs → /abs.
		if after, ok := strings.CutPrefix(path, "//"); ok {
			if i := strings.IndexByte(after, '/'); i >= 0 {
				path = after[i:]
			} else {
				path = after
			}
		}
	case strings.Contains(s, "://"):
		return nil, errors.New("unsupported scheme (use sqlite:// or file:)")
	default:
		path = s
	}
	unescaped, err := url.PathUnescape(path)
	if err != nil {
		return nil, errors.New("invalid escape in path")
	}
	if unescaped == "" {
		return nil, errors.New("missing file path")
	}
	params := map[string]string{ParamPath: unescaped}
	if query != "" {
		q, err := url.ParseQuery(query)
		if err != nil {
			return nil, errors.New("invalid query string")
		}
		switch q.Get("mode") {
		case "ro":
			params[ParamReadOnly] = "true"
		case "rwc":
			params[ParamCreateIfMissing] = "true"
		}
	}
	return params, nil
}
