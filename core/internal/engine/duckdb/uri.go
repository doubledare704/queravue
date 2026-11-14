package duckdb

import (
	"errors"
	"net/url"
	"strings"
)

// parseURI accepts duckdb:///abs/path, duckdb://rel/path, duckdb://:memory:,
// a bare path, and ?access_mode=read_only or ?read_only=true.
func parseURI(s string) (map[string]string, error) {
	s = strings.TrimSpace(s)
	if s == "" {
		return nil, errors.New("empty connection string")
	}
	path, query := s, ""
	if strings.HasPrefix(s, "duckdb://") {
		path, query, _ = strings.Cut(s[len("duckdb://"):], "?")
	} else if strings.Contains(s, "://") {
		return nil, errors.New("unsupported scheme (use duckdb://)")
	}
	unescaped, err := url.PathUnescape(path)
	if err != nil {
		return nil, errors.New("invalid escape in path")
	}
	if unescaped == "" {
		return nil, errors.New("missing file path")
	}
	params := map[string]string{ParamPath: unescaped}
	if query == "" {
		return params, nil
	}
	q, err := url.ParseQuery(query)
	if err != nil {
		return nil, errors.New("invalid query string")
	}
	if q.Get("access_mode") == "read_only" || q.Get("read_only") == "true" {
		params[ParamReadOnly] = "true"
	}
	if limit := q.Get("memory_limit"); limit != "" {
		params[ParamMemoryLimit] = limit
	}
	return params, nil
}
