package mssql

import (
	"errors"
	"fmt"
	"net"
	"net/url"
	"strconv"
	"strings"
)

// parseConnString parses a sqlserver:// (or mssql://) URI into params and a
// password. Unknown query keys are ignored.
func parseConnString(s string) (map[string]string, string, error) {
	s = strings.TrimSpace(s)
	if s == "" {
		return nil, "", errors.New("empty connection string")
	}
	i := strings.Index(s, "://")
	if i < 0 {
		return nil, "", errors.New("expected a sqlserver:// URI")
	}
	if sch := s[:i]; sch != "sqlserver" && sch != "mssql" {
		return nil, "", fmt.Errorf("unsupported scheme %q; use sqlserver:// or mssql://", sch)
	}
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
	if inst := strings.Trim(u.Path, "/"); inst != "" {
		return nil, "", errors.New("named instances are not supported; give the port instead")
	}
	for k, vs := range u.Query() {
		if len(vs) == 0 {
			continue
		}
		v := vs[len(vs)-1]
		switch strings.ToLower(k) {
		case "database":
			params[ParamDatabase] = v
		case "encrypt":
			mode, ok := encryptMode(v)
			if !ok {
				return nil, "", fmt.Errorf("invalid encrypt value %q", v)
			}
			params[ParamEncrypt] = mode
		case "trustservercertificate":
			b, err := strconv.ParseBool(v)
			if err != nil {
				return nil, "", fmt.Errorf("invalid TrustServerCertificate value %q", v)
			}
			params[ParamTrust] = strconv.FormatBool(b)
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

// encryptMode maps driver and ADO spellings to our encrypt modes.
func encryptMode(v string) (string, bool) {
	switch strings.ToLower(v) {
	case "disable", "disabled":
		return "disable", true
	case "false", "no", "optional":
		return "optional", true
	case "true", "yes", "mandatory", "required":
		return "required", true
	case "strict":
		return "strict", true
	}
	return "", false
}
