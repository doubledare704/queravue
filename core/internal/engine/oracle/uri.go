package oracle

import (
	"errors"
	"fmt"
	"net"
	"net/url"
	"regexp"
	"strconv"
	"strings"
)

var (
	descriptorAddress = regexp.MustCompile(`(?i)\(\s*ADDRESS\s*=`)
	descriptorField   = func(key string) *regexp.Regexp {
		return regexp.MustCompile(`(?i)\(\s*` + key + `\s*=\s*([^()\s]+)\s*\)`)
	}
	descriptorHost     = descriptorField("HOST")
	descriptorPort     = descriptorField("PORT")
	descriptorProtocol = descriptorField("PROTOCOL")
	descriptorService  = descriptorField("SERVICE_NAME")
	descriptorSID      = descriptorField("SID")
)

// parseConnString reads an oracle:// URI, an Easy Connect string
// (host:port/service, optionally prefixed user/password@) or a TNS
// descriptor. Unknown query keys are ignored.
func parseConnString(s string) (map[string]string, string, error) {
	s = strings.TrimSpace(s)
	if s == "" {
		return nil, "", errors.New("empty connection string")
	}
	params := map[string]string{}
	var password string
	if strings.HasPrefix(strings.ToLower(s), "oracle://") {
		return parseURL(s)
	}
	if user, pw, rest, ok := splitCredentials(s); ok {
		params[ParamUser], password, s = user, pw, rest
	}
	if strings.HasPrefix(s, "(") {
		if err := applyDescriptor(params, s); err != nil {
			return nil, "", err
		}
		return params, password, nil
	}
	if err := applyEasyConnect(params, strings.TrimPrefix(s, "//")); err != nil {
		return nil, "", err
	}
	return params, password, nil
}

func parseURL(s string) (map[string]string, string, error) {
	u, err := url.Parse(s)
	if err != nil {
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
		if err := applyHostPort(params, u.Host); err != nil {
			return nil, "", err
		}
	}
	if service := strings.Trim(u.Path, "/"); service != "" {
		params[ParamService] = service
	}
	for k, vs := range u.Query() {
		if len(vs) == 0 {
			continue
		}
		if err := applyQueryOption(params, strings.ToLower(k), vs[len(vs)-1]); err != nil {
			return nil, "", err
		}
	}
	return params, password, nil
}

func applyQueryOption(params map[string]string, key, v string) error {
	switch key {
	case "sid":
		params[ParamSID] = v
	case "service", "service_name":
		params[ParamService] = v
	case "role", "dba privilege":
		role := strings.ToLower(v)
		if role != RoleNormal && role != RoleSysDBA {
			return fmt.Errorf("invalid role %q; use normal or sysdba", v)
		}
		params[ParamRole] = role
	case "ssl", "ssl verify":
		b, err := strconv.ParseBool(v)
		if err != nil {
			return fmt.Errorf("invalid %s value %q", key, v)
		}
		name := ParamSSL
		if key == "ssl verify" {
			name = ParamSSLVerify
		}
		params[name] = strconv.FormatBool(b)
	case "wallet":
		params[ParamWallet] = v
	}
	return nil
}

// splitCredentials splits "user/password@rest" where the "@" comes before
// any "(" or "//" and the credentials hold no "/" beyond the first.
func splitCredentials(s string) (user, password, rest string, ok bool) {
	at := strings.LastIndex(s, "@")
	if at < 0 || strings.HasPrefix(s, "(") || strings.HasPrefix(s, "//") {
		return "", "", "", false
	}
	if paren := strings.Index(s, "("); paren >= 0 && paren < at {
		return "", "", "", false
	}
	creds := s[:at]
	user, password, _ = strings.Cut(creds, "/")
	return user, password, s[at+1:], true
}

func applyEasyConnect(params map[string]string, s string) error {
	hostPort, service, _ := strings.Cut(s, "/")
	if hostPort == "" {
		return errors.New("expected host[:port]/service")
	}
	if err := applyHostPort(params, hostPort); err != nil {
		return err
	}
	service, _, _ = strings.Cut(service, "?")
	if service != "" {
		params[ParamService] = service
	}
	return nil
}

func applyHostPort(params map[string]string, hostport string) error {
	host, port := hostport, ""
	bracketed := strings.HasPrefix(hostport, "[") && strings.HasSuffix(hostport, "]")
	if strings.Contains(hostport, ":") && !bracketed {
		h, p, err := net.SplitHostPort(hostport)
		if err != nil {
			return fmt.Errorf("invalid host:port %q", hostport)
		}
		host, port = h, p
	}
	host = strings.Trim(host, "[]")
	if host != "" {
		params[ParamHost] = host
	}
	if port != "" {
		if _, err := strconv.ParseUint(port, 10, 16); err != nil {
			return fmt.Errorf("invalid port %q", port)
		}
		params[ParamPort] = port
	}
	return nil
}

// applyDescriptor keeps the descriptor as is, except for the plain
// single-address case, which fills the host, port and service fields.
func applyDescriptor(params map[string]string, desc string) error {
	if strings.Count(desc, "(") != strings.Count(desc, ")") {
		return errors.New("unbalanced parentheses in the TNS descriptor")
	}
	host, port := descriptorHost.FindStringSubmatch(desc), descriptorPort.FindStringSubmatch(desc)
	protocol := descriptorProtocol.FindStringSubmatch(desc)
	service, sid := descriptorService.FindStringSubmatch(desc), descriptorSID.FindStringSubmatch(desc)
	plain := len(descriptorAddress.FindAllString(desc, -1)) == 1 && host != nil && port != nil &&
		(service != nil) != (sid != nil) && !strings.Contains(strings.ToUpper(desc), "ADDRESS_LIST")
	if !plain {
		params[ParamDescriptor] = desc
		return nil
	}
	params[ParamHost], params[ParamPort] = host[1], port[1]
	if service != nil {
		params[ParamService] = service[1]
	} else {
		params[ParamSID] = sid[1]
	}
	if protocol != nil && strings.EqualFold(protocol[1], "TCPS") {
		params[ParamSSL] = "true"
	}
	return nil
}
