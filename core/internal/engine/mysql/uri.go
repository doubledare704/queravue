package mysql

import (
	"errors"
	"fmt"
	"net"
	"net/url"
	"strconv"
	"strings"

	drv "github.com/go-sql-driver/mysql"
)

// parseConnString parses a mysql://, mariadb:// or tidb:// URI, or a
// go-sql-driver DSN (user:pass@tcp(host:port)/db?tls=true), into params and
// a password. Unknown keys are ignored.
func parseConnString(s string) (map[string]string, string, error) {
	s = strings.TrimSpace(s)
	if s == "" {
		return nil, "", errors.New("empty connection string")
	}
	if i := strings.Index(s, "://"); i >= 0 {
		switch s[:i] {
		case "mysql", "mariadb", "tidb":
			return parseURL(s)
		}
		return nil, "", fmt.Errorf("unsupported scheme %q; use mysql://, mariadb:// or tidb://", s[:i])
	}
	return parseDSN(s)
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
		if k == "tls" || k == "ssl-mode" || k == "sslmode" {
			mode, ok := tlsMode(vs[len(vs)-1])
			if !ok {
				return nil, "", fmt.Errorf("invalid tls value %q", vs[len(vs)-1])
			}
			params[ParamTLS] = mode
		}
	}
	return params, password, nil
}

func parseDSN(s string) (map[string]string, string, error) {
	cfg, err := drv.ParseDSN(s)
	if err != nil {
		return nil, "", errors.New("malformed DSN")
	}
	params := map[string]string{}
	if cfg.User != "" {
		params[ParamUser] = cfg.User
	}
	if cfg.DBName != "" {
		params[ParamDatabase] = cfg.DBName
	}
	if cfg.Addr != "" {
		host, port, err := splitHostPort(cfg.Addr)
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
	if cfg.TLSConfig != "" {
		if mode, ok := tlsMode(cfg.TLSConfig); ok {
			params[ParamTLS] = mode
		}
	}
	return params, cfg.Passwd, nil
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

// tlsMode maps driver and MySQL ssl-mode spellings to our TLS modes.
func tlsMode(v string) (string, bool) {
	switch strings.ToLower(v) {
	case "false", "disable", "disabled":
		return "disable", true
	case "preferred", "prefer":
		return "preferred", true
	case "skip-verify", "required", "require":
		return "skip-verify", true
	case "true", "verify", "verify_ca", "verify_identity", "verify-full":
		return "verify", true
	}
	return "", false
}
