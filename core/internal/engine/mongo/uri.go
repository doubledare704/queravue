package mongo

import (
	"errors"
	"fmt"
	"net/url"
	"strconv"
	"strings"
)

// parseURI splits a mongodb:// or mongodb+srv:// URI into params and a
// password without touching the network (no SRV lookup). Unknown options are
// ignored. Errors never quote the input, which may hold the password.
func parseURI(s string) (map[string]string, string, error) {
	s = strings.TrimSpace(s)
	if s == "" {
		return nil, "", errors.New("empty connection string")
	}
	i := strings.Index(s, "://")
	if i < 0 {
		return nil, "", errors.New("expected a mongodb:// or mongodb+srv:// URI")
	}
	params := map[string]string{}
	switch scheme := s[:i]; scheme {
	case "mongodb":
	case "mongodb+srv":
		params[ParamSRV] = "true"
	default:
		return nil, "", fmt.Errorf("unsupported scheme %q; use mongodb:// or mongodb+srv://", scheme)
	}
	rest := s[i+3:]
	authority, tail := rest, ""
	if j := strings.IndexAny(rest, "/?"); j >= 0 {
		authority, tail = rest[:j], rest[j:]
	}
	var password string
	if at := strings.LastIndexByte(authority, '@'); at >= 0 {
		userinfo := authority[:at]
		authority = authority[at+1:]
		user, pw, hasPw := strings.Cut(userinfo, ":")
		u, err := url.PathUnescape(user)
		if err != nil {
			return nil, "", errors.New("malformed user name")
		}
		if u != "" {
			params[ParamUsername] = u
		}
		if hasPw {
			if password, err = url.PathUnescape(pw); err != nil {
				return nil, "", errors.New("malformed password")
			}
		}
	}
	if authority == "" {
		return nil, "", errors.New("missing host")
	}
	for _, h := range strings.Split(authority, ",") {
		if h == "" {
			return nil, "", errors.New("empty host in host list")
		}
		if idx := strings.LastIndexByte(h, ':'); idx >= 0 && !strings.HasSuffix(h, "]") {
			if _, err := strconv.ParseUint(h[idx+1:], 10, 16); err != nil {
				return nil, "", fmt.Errorf("invalid port in host %q", h[:idx])
			}
		}
	}
	params[ParamHosts] = authority

	pathPart, query, _ := strings.Cut(tail, "?")
	if db := strings.TrimPrefix(pathPart, "/"); db != "" {
		d, err := url.PathUnescape(db)
		if err != nil {
			return nil, "", errors.New("malformed database name")
		}
		params[ParamDatabase] = d
	}
	vals, err := url.ParseQuery(query)
	if err != nil {
		return nil, "", errors.New("malformed query options")
	}
	for k, vs := range vals {
		if len(vs) == 0 {
			continue
		}
		v := vs[len(vs)-1]
		switch strings.ToLower(k) {
		case "replicaset":
			params[ParamReplicaSet] = v
		case "authsource":
			params[ParamAuthSource] = v
		case "authmechanism":
			if !validMechanism(v) {
				return nil, "", fmt.Errorf("unsupported authMechanism %q", v)
			}
			params[ParamAuthMechanism] = v
		case "tls", "ssl":
			b, err := strconv.ParseBool(v)
			if err != nil {
				return nil, "", fmt.Errorf("invalid %s value", k)
			}
			params[ParamTLS] = strconv.FormatBool(b)
		case "tlscafile", "sslcafile":
			params[ParamTLSCAFile] = v
		case "tlscertificatekeyfile":
			params[ParamTLSCertKeyFile] = v
		case "tlsinsecure", "tlsallowinvalidcertificates":
			b, err := strconv.ParseBool(v)
			if err != nil {
				return nil, "", fmt.Errorf("invalid %s value", k)
			}
			params[ParamTLSInsecure] = strconv.FormatBool(b)
		case "directconnection":
			b, err := strconv.ParseBool(v)
			if err != nil {
				return nil, "", errors.New("invalid directConnection value")
			}
			params[ParamDirect] = strconv.FormatBool(b)
		case "readpreference":
			if !validReadPref(v) {
				return nil, "", fmt.Errorf("unsupported readPreference %q", v)
			}
			params[ParamReadPreference] = v
		}
	}
	return params, password, nil
}

func validMechanism(m string) bool {
	for _, o := range AuthMechanisms {
		if strings.EqualFold(o, m) {
			return true
		}
	}
	return false
}

func validReadPref(m string) bool {
	for _, o := range ReadPreferences {
		if o == m {
			return true
		}
	}
	return false
}
