package netpath

import (
	"crypto/tls"
	"crypto/x509"
	"encoding/pem"
	"errors"
	"fmt"
	"os"

	"github.com/youmark/pkcs8"
)

// TLSMode selects how strictly TLS is enforced. Values mirror queravue.v1.TlsMode.
type TLSMode int

// TLS modes.
const (
	TLSUnset TLSMode = iota
	TLSDisable
	TLSPrefer
	TLSRequire
	TLSVerifyCA
	TLSVerifyFull
)

// TLSSettings is the engine-independent TLS configuration.
type TLSSettings struct {
	Mode       TLSMode
	CAFile     string
	ClientCert string
	ClientKey  string
	ServerName string
	// KeyPassphrase decrypts ClientKey. It comes from the keychain.
	KeyPassphrase string
}

// Enabled reports whether the connection should use TLS at all.
func (s TLSSettings) Enabled() bool { return s.Mode > TLSDisable }

// FallbackToPlaintext reports whether a server without TLS is acceptable.
func (s TLSSettings) FallbackToPlaintext() bool { return s.Mode == TLSPrefer }

// Build returns the tls.Config for a connection to host, or nil when TLS is
// disabled or unset.
func (s TLSSettings) Build(host string) (*tls.Config, error) {
	if !s.Enabled() {
		return nil, nil
	}
	cfg := &tls.Config{MinVersion: tls.VersionTLS12, ServerName: host}
	if s.ServerName != "" {
		cfg.ServerName = s.ServerName
	}
	if s.CAFile != "" {
		pool, err := loadCAPool(s.CAFile)
		if err != nil {
			return nil, err
		}
		cfg.RootCAs = pool
	}
	if s.ClientCert != "" || s.ClientKey != "" {
		cert, err := loadClientCertificate(s.ClientCert, s.ClientKey, s.KeyPassphrase)
		if err != nil {
			return nil, err
		}
		cfg.Certificates = []tls.Certificate{cert}
	}
	switch s.Mode {
	case TLSPrefer, TLSRequire:
		cfg.InsecureSkipVerify = true
	case TLSVerifyCA:
		cfg.InsecureSkipVerify = true
		cfg.VerifyConnection = verifyChainOnly(cfg.RootCAs)
	}
	return cfg, nil
}

func verifyChainOnly(roots *x509.CertPool) func(tls.ConnectionState) error {
	return func(cs tls.ConnectionState) error {
		if len(cs.PeerCertificates) == 0 {
			return errors.New("tls: server sent no certificate")
		}
		opts := x509.VerifyOptions{Roots: roots, Intermediates: x509.NewCertPool()}
		for _, c := range cs.PeerCertificates[1:] {
			opts.Intermediates.AddCert(c)
		}
		if _, err := cs.PeerCertificates[0].Verify(opts); err != nil {
			return fmt.Errorf("tls: verify certificate chain: %w", err)
		}
		return nil
	}
}

func loadCAPool(path string) (*x509.CertPool, error) {
	b, err := os.ReadFile(path) //nolint:gosec // path is the user's CA file
	if err != nil {
		return nil, &ConfigError{Msg: fmt.Sprintf("read CA file: %v", errors.Unwrap(err))}
	}
	pool := x509.NewCertPool()
	if !pool.AppendCertsFromPEM(b) {
		return nil, &ConfigError{Msg: "CA file holds no PEM certificate"}
	}
	return pool, nil
}

func loadClientCertificate(certPath, keyPath, passphrase string) (tls.Certificate, error) {
	if keyPath == "" {
		keyPath = certPath
	}
	if certPath == "" {
		certPath = keyPath
	}
	certPEM, err := os.ReadFile(certPath) //nolint:gosec // path is the user's certificate
	if err != nil {
		return tls.Certificate{}, &ConfigError{Msg: "read client certificate: " + errors.Unwrap(err).Error()}
	}
	keyPEM, err := os.ReadFile(keyPath) //nolint:gosec // path is the user's key
	if err != nil {
		return tls.Certificate{}, &ConfigError{Msg: "read client key: " + errors.Unwrap(err).Error()}
	}
	keyPEM, err = decryptKeyPEM(keyPEM, passphrase)
	if err != nil {
		return tls.Certificate{}, err
	}
	cert, err := tls.X509KeyPair(certPEM, keyPEM)
	if err != nil {
		return tls.Certificate{}, &ConfigError{Msg: "client certificate and key do not form a pair"}
	}
	return cert, nil
}

// decryptKeyPEM returns the key blocks of data decrypted and re-encoded, so
// tls.X509KeyPair can read them. A combined cert+key file keeps its
// certificates.
func decryptKeyPEM(data []byte, passphrase string) ([]byte, error) {
	var out []byte
	for rest := data; ; {
		var block *pem.Block
		block, rest = pem.Decode(rest)
		if block == nil {
			break
		}
		switch {
		case block.Type == "ENCRYPTED PRIVATE KEY":
			key, err := pkcs8.ParsePKCS8PrivateKey(block.Bytes, []byte(passphrase))
			if err != nil {
				return nil, &ConfigError{Msg: "client key passphrase is wrong or the key is unsupported"}
			}
			der, err := x509.MarshalPKCS8PrivateKey(key)
			if err != nil {
				return nil, &ConfigError{Msg: "client key is unsupported"}
			}
			block = &pem.Block{Type: "PRIVATE KEY", Bytes: der}
		case x509.IsEncryptedPEMBlock(block): //nolint:staticcheck // legacy PEM encryption is what openssl -traditional writes
			der, err := x509.DecryptPEMBlock(block, []byte(passphrase)) //nolint:staticcheck // see above
			if err != nil {
				return nil, &ConfigError{Msg: "client key passphrase is wrong"}
			}
			block = &pem.Block{Type: block.Type, Bytes: der}
		}
		out = append(out, pem.EncodeToMemory(block)...)
	}
	if len(out) == 0 {
		return nil, &ConfigError{Msg: "client key file holds no PEM block"}
	}
	return out, nil
}
