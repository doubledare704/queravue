package netpath

import (
	"errors"
	"fmt"
	"net"
	"os"
	"path/filepath"
	"strconv"
	"sync"

	"golang.org/x/crypto/ssh"
	"golang.org/x/crypto/ssh/knownhosts"
)

// HostKeys decides which SSH host keys to trust. It reads the user's
// ~/.ssh/known_hosts and appends keys the user accepted to a file Queravue
// owns, so it never rewrites the user's own file.
type HostKeys struct {
	userFile string
	ownFile  string

	mu      sync.Mutex
	pending map[string]ssh.PublicKey
}

// NewHostKeys returns a verifier. userFile may be empty or missing.
func NewHostKeys(userFile, ownFile string) *HostKeys {
	return &HostKeys{userFile: userFile, ownFile: ownFile, pending: map[string]ssh.PublicKey{}}
}

// DefaultUserKnownHosts returns ~/.ssh/known_hosts, or "" if the home directory is unknown.
func DefaultUserKnownHosts() string {
	home, err := os.UserHomeDir()
	if err != nil {
		return ""
	}
	return filepath.Join(home, ".ssh", "known_hosts")
}

// Callback returns the ssh.HostKeyCallback. Unknown hosts fail with
// *HostKeyUnknownError, changed keys with *HostKeyChangedError.
func (h *HostKeys) Callback() ssh.HostKeyCallback {
	return func(hostname string, remote net.Addr, key ssh.PublicKey) error {
		files := h.existingFiles()
		if len(files) > 0 {
			check, err := knownhosts.New(files...)
			if err != nil {
				return &ConfigError{Msg: "cannot read known_hosts: " + err.Error()}
			}
			err = check(hostname, remote, key)
			if err == nil {
				return nil
			}
			var keyErr *knownhosts.KeyError
			var revoked *knownhosts.RevokedError
			switch {
			case errors.As(err, &keyErr) && len(keyErr.Want) > 0:
				return &HostKeyChangedError{
					Host: hostname, Fingerprint: ssh.FingerprintSHA256(key),
					TrustedFingerprint: ssh.FingerprintSHA256(keyErr.Want[0].Key),
				}
			case errors.As(err, &revoked):
				return &HostKeyChangedError{Host: hostname, Fingerprint: ssh.FingerprintSHA256(key), TrustedFingerprint: "revoked"}
			case !errors.As(err, &keyErr):
				return err
			}
		}
		h.mu.Lock()
		h.pending[knownhosts.Normalize(hostname)] = key
		h.mu.Unlock()
		return &HostKeyUnknownError{Host: hostname, Fingerprint: ssh.FingerprintSHA256(key)}
	}
}

func (h *HostKeys) existingFiles() []string {
	var files []string
	for _, f := range []string{h.userFile, h.ownFile} {
		if f == "" {
			continue
		}
		if st, err := os.Stat(f); err == nil && !st.IsDir() {
			files = append(files, f)
		}
	}
	return files
}

// Trust records the key a failed connect presented. fingerprint must equal
// the one the failure carried; a host whose key changed is never trusted.
func (h *HostKeys) Trust(host string, port int, fingerprint string) error {
	addr := knownhosts.Normalize(net.JoinHostPort(host, strconv.Itoa(port)))
	h.mu.Lock()
	key, ok := h.pending[addr]
	h.mu.Unlock()
	if !ok {
		return &ConfigError{Msg: "no pending host key for " + addr + "; connect first"}
	}
	if ssh.FingerprintSHA256(key) != fingerprint {
		return &ConfigError{Msg: "fingerprint does not match the key the host presented"}
	}
	if err := os.MkdirAll(filepath.Dir(h.ownFile), 0o700); err != nil {
		return fmt.Errorf("netpath: create known_hosts dir: %w", err)
	}
	f, err := os.OpenFile(h.ownFile, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o600) //nolint:gosec // Queravue's own file
	if err != nil {
		return fmt.Errorf("netpath: open known_hosts: %w", err)
	}
	if _, err := fmt.Fprintln(f, knownhosts.Line([]string{addr}, key)); err != nil {
		_ = f.Close()
		return fmt.Errorf("netpath: write known_hosts: %w", err)
	}
	if err := f.Close(); err != nil {
		return fmt.Errorf("netpath: write known_hosts: %w", err)
	}
	h.mu.Lock()
	delete(h.pending, addr)
	h.mu.Unlock()
	return nil
}
