package clickhouse

import (
	"errors"
	"fmt"
	"net"
	"net/url"
	"strconv"
	"strings"
)

func parseURI(s string) (map[string]string, string, error) {
	s = strings.TrimSpace(s)
	if s == "" {
		return nil, "", errors.New("empty connection string")
	}
	u, err := url.Parse(s)
	if err != nil {
		return nil, "", errors.New("malformed URI")
	}
	if u.Scheme != "clickhouse" && u.Scheme != "tcp" {
		return nil, "", fmt.Errorf("unsupported scheme %q; use clickhouse://", u.Scheme)
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
	if db := strings.Trim(u.Path, "/"); db != "" {
		params[ParamDatabase] = db
	}
	query := u.Query()
	secure, err := boolQuery(query, "secure")
	if err != nil {
		return nil, "", err
	}
	skipVerify, err := boolQuery(query, "skip_verify")
	if err != nil {
		return nil, "", err
	}
	switch {
	case skipVerify:
		params[ParamTLS] = "skip-verify"
	case secure:
		params[ParamTLS] = "verify"
	}
	return params, password, nil
}

func boolQuery(q url.Values, key string) (bool, error) {
	v := q.Get(key)
	if v == "" {
		return false, nil
	}
	b, err := strconv.ParseBool(v)
	if err != nil {
		return false, fmt.Errorf("invalid %s value %q", key, v)
	}
	return b, nil
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
