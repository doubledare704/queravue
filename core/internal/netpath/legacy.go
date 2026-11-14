package netpath

// Engine families whose per-engine TLS params predate TLSSettings.
const (
	FamilyPostgres   = "postgres"
	FamilyMySQL      = "mysql"
	FamilyMSSQL      = "mssql"
	FamilyMongo      = "mongodb"
	FamilyClickHouse = "clickhouse"
	FamilyOracle     = "oracle"
	FamilyRedis      = "redis"
)

// LegacyTLSKeys lists the params MigrateLegacyTLS consumes for a family.
func LegacyTLSKeys(family string) []string {
	switch family {
	case FamilyPostgres:
		return []string{"sslmode"}
	case FamilyMySQL, FamilyClickHouse:
		return []string{"tls"}
	case FamilyMSSQL:
		return []string{"encrypt", "trust_server_certificate"}
	case FamilyMongo:
		return []string{"tls", "tls_ca_file", "tls_cert_key_file", "tls_insecure"}
	case FamilyRedis:
		return []string{"tls", "tls_ca_file", "tls_insecure"}
	case FamilyOracle:
		return []string{"ssl", "ssl_verify"}
	}
	return nil
}

// MigrateLegacyTLS maps the per-engine TLS params of a stored connection to
// TLSSettings. It returns the params without the keys it consumed. ok is false
// when params hold no legacy TLS setting, or one TLSSettings cannot express
// (SQL Server encrypt=strict), in which case params come back unchanged.
func MigrateLegacyTLS(family string, params map[string]string) (settings TLSSettings, rest map[string]string, ok bool) {
	settings, ok = legacySettings(family, params)
	if !ok {
		return TLSSettings{}, params, false
	}
	rest = make(map[string]string, len(params))
	for k, v := range params {
		rest[k] = v
	}
	for _, k := range LegacyTLSKeys(family) {
		delete(rest, k)
	}
	return settings, rest, true
}

func legacySettings(family string, p map[string]string) (TLSSettings, bool) {
	switch family {
	case FamilyPostgres:
		modes := map[string]TLSMode{"disable": TLSDisable, "allow": TLSPrefer, "prefer": TLSPrefer, "require": TLSRequire, "verify-ca": TLSVerifyCA, "verify-full": TLSVerifyFull}
		m, ok := modes[p["sslmode"]]
		return TLSSettings{Mode: m}, ok
	case FamilyMySQL:
		modes := map[string]TLSMode{"disable": TLSDisable, "preferred": TLSPrefer, "skip-verify": TLSRequire, "verify": TLSVerifyFull}
		m, ok := modes[p["tls"]]
		return TLSSettings{Mode: m}, ok
	case FamilyClickHouse:
		modes := map[string]TLSMode{"disable": TLSDisable, "skip-verify": TLSRequire, "verify": TLSVerifyFull}
		m, ok := modes[p["tls"]]
		return TLSSettings{Mode: m}, ok
	case FamilyMSSQL:
		return legacyMSSQL(p)
	case FamilyMongo, FamilyRedis:
		return legacyBooleanTLS(p)
	case FamilyOracle:
		return legacyOracle(p)
	}
	return TLSSettings{}, false
}

func legacyMSSQL(p map[string]string) (TLSSettings, bool) {
	switch p["encrypt"] {
	case "disable":
		return TLSSettings{Mode: TLSDisable}, true
	case "optional":
		return TLSSettings{Mode: TLSPrefer}, true
	case "required":
		if p["trust_server_certificate"] == "true" {
			return TLSSettings{Mode: TLSRequire}, true
		}
		return TLSSettings{Mode: TLSVerifyFull}, true
	}
	return TLSSettings{}, false
}

func legacyBooleanTLS(p map[string]string) (TLSSettings, bool) {
	enabled, ok := p["tls"]
	if !ok {
		return TLSSettings{}, false
	}
	if enabled != "true" {
		return TLSSettings{Mode: TLSDisable}, true
	}
	s := TLSSettings{Mode: TLSVerifyFull, CAFile: p["tls_ca_file"], ClientCert: p["tls_cert_key_file"], ClientKey: p["tls_cert_key_file"]}
	if p["tls_insecure"] == "true" {
		s.Mode = TLSRequire
	}
	return s, true
}

func legacyOracle(p map[string]string) (TLSSettings, bool) {
	enabled, ok := p["ssl"]
	if !ok {
		return TLSSettings{}, false
	}
	switch {
	case enabled != "true":
		return TLSSettings{Mode: TLSDisable}, true
	case p["ssl_verify"] == "false":
		return TLSSettings{Mode: TLSRequire}, true
	}
	return TLSSettings{Mode: TLSVerifyFull}, true
}
