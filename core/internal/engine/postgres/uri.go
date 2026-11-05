package postgres

import (
	"errors"
	"fmt"
	"net"
	"net/url"
	"slices"
	"strconv"
	"strings"
	"unicode"
)

// parseConnString parses a postgres:// / postgresql:// URI or a libpq
// keyword/value DSN into params and a password. Unknown keys are ignored.
func parseConnString(s string) (map[string]string, string, error) {
	s = strings.TrimSpace(s)
	if s == "" {
		return nil, "", errors.New("empty connection string")
	}
	if strings.HasPrefix(s, "postgres://") || strings.HasPrefix(s, "postgresql://") {
		return parseURL(s)
	}
	if strings.Contains(s, "://") {
		return nil, "", fmt.Errorf("unsupported scheme in %q; use postgres:// or postgresql://", schemeOf(s))
	}
	return parseKeywordValue(s)
}

func schemeOf(s string) string {
	if i := strings.Index(s, "://"); i >= 0 {
		return s[:i]
	}
	return ""
}

func parseURL(s string) (map[string]string, string, error) {
	u, err := url.Parse(s)
	if err != nil {
		// url.Parse errors quote the input, which may hold the password.
		return nil, "", errors.New("malformed URI")
	}
	params := map[string]string{}
	var password string
	if u.User != nil {
		if name := u.User.Username(); name != "" {
			params[ParamUser] = name
		}
		password, _ = u.User.Password()
	}
	if strings.Contains(u.Host, ",") {
		return nil, "", errors.New("multiple hosts are not supported yet")
	}
	if u.Host != "" {
		host, port, err := splitHostPort(u.Host)
		if err != nil {
			return nil, "", err
		}
		if host != "" {
			params[ParamHost] = host
		}
		if port != "" {
			params[ParamPort] = port
		}
	}
	if db := strings.TrimPrefix(u.Path, "/"); db != "" {
		params[ParamDatabase] = db
	}
	for k, vs := range u.Query() {
		if len(vs) == 0 {
			continue
		}
		if err := applyKey(params, &password, k, vs[len(vs)-1]); err != nil {
			return nil, "", err
		}
	}
	return params, password, nil
}

func splitHostPort(hostport string) (string, string, error) {
	if !strings.Contains(hostport, ":") || (strings.HasPrefix(hostport, "[") && strings.HasSuffix(hostport, "]")) {
		return strings.Trim(hostport, "[]"), "", nil
	}
	host, port, err := net.SplitHostPort(hostport)
	if err != nil {
		return "", "", fmt.Errorf("invalid host:port %q", hostport)
	}
	if port != "" {
		if _, err := strconv.ParseUint(port, 10, 16); err != nil {
			return "", "", fmt.Errorf("invalid port %q", port)
		}
	}
	return host, port, nil
}

// applyKey stores a libpq key in params (or password). Unknown keys are
// ignored so URIs copied from other tools still import.
func applyKey(params map[string]string, password *string, k, v string) error {
	switch k {
	case "host":
		params[ParamHost] = v
	case "port":
		if _, err := strconv.ParseUint(v, 10, 16); err != nil {
			return fmt.Errorf("invalid port %q", v)
		}
		params[ParamPort] = v
	case "dbname", "database":
		params[ParamDatabase] = v
	case "user":
		params[ParamUser] = v
	case "password":
		*password = v
	case "sslmode":
		if !validSSLMode(v) {
			return fmt.Errorf("invalid sslmode %q", v)
		}
		params[ParamSSLMode] = v
	}
	return nil
}

func validSSLMode(v string) bool { return slices.Contains(SSLModes, v) }

// parseKeywordValue parses `host=a port=5432 password='x y'` with libpq
// quoting rules (single quotes, backslash escapes).
func parseKeywordValue(s string) (map[string]string, string, error) {
	params := map[string]string{}
	var password string
	for s = strings.TrimLeftFunc(s, unicode.IsSpace); s != ""; s = strings.TrimLeftFunc(s, unicode.IsSpace) {
		eq := strings.IndexByte(s, '=')
		if eq <= 0 {
			return nil, "", errors.New("expected key=value")
		}
		key := strings.TrimSpace(s[:eq])
		s = strings.TrimLeftFunc(s[eq+1:], unicode.IsSpace)
		var val string
		var err error
		val, s, err = readValue(s)
		if err != nil {
			return nil, "", err
		}
		if err := applyKey(params, &password, key, val); err != nil {
			return nil, "", err
		}
	}
	return params, password, nil
}

func readValue(s string) (val, rest string, err error) {
	var b strings.Builder
	if strings.HasPrefix(s, "'") {
		for i := 1; i < len(s); i++ {
			switch s[i] {
			case '\\':
				if i+1 < len(s) {
					i++
					b.WriteByte(s[i])
				}
			case '\'':
				return b.String(), s[i+1:], nil
			default:
				b.WriteByte(s[i])
			}
		}
		return "", "", errors.New("unterminated quoted value")
	}
	i := 0
	for ; i < len(s) && !unicode.IsSpace(rune(s[i])); i++ {
		if s[i] == '\\' && i+1 < len(s) {
			i++
		}
		b.WriteByte(s[i])
	}
	return b.String(), s[i:], nil
}
