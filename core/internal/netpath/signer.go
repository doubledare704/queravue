package netpath

import (
	"errors"
	"os"

	"golang.org/x/crypto/ssh"
)

func loadSigner(cfg SSHConfig) (ssh.Signer, error) {
	if cfg.KeyFile == "" {
		return nil, &ConfigError{Msg: "SSH key file is required"}
	}
	pemBytes, err := os.ReadFile(cfg.KeyFile)
	if err != nil {
		return nil, &ConfigError{Msg: "read SSH key file: " + errors.Unwrap(err).Error()}
	}
	signer, err := ssh.ParsePrivateKey(pemBytes)
	var missing *ssh.PassphraseMissingError
	if errors.As(err, &missing) {
		if cfg.KeyPassphrase == "" {
			return nil, &AuthError{Host: cfg.Addr(), Method: "key file", Err: errors.New("the key is encrypted and no passphrase is stored")}
		}
		signer, err = ssh.ParsePrivateKeyWithPassphrase(pemBytes, []byte(cfg.KeyPassphrase))
		if err != nil {
			return nil, &AuthError{Host: cfg.Addr(), Method: "key file", Err: errors.New("the key passphrase is wrong")}
		}
		return signer, nil
	}
	if err != nil {
		return nil, &ConfigError{Msg: "SSH key file is not a usable private key"}
	}
	return signer, nil
}
