package netpath

import "fmt"

// HostKeyUnknownError means the bastion's host key is in no known_hosts file.
type HostKeyUnknownError struct {
	Host        string
	Fingerprint string
}

func (e *HostKeyUnknownError) Error() string {
	return fmt.Sprintf("ssh host key of %s is not trusted yet (%s)", e.Host, e.Fingerprint)
}

// HostKeyChangedError means the bastion presents a different key than the trusted one.
type HostKeyChangedError struct {
	Host               string
	Fingerprint        string
	TrustedFingerprint string
}

func (e *HostKeyChangedError) Error() string {
	return fmt.Sprintf("ssh host key of %s changed: presented %s, trusted %s", e.Host, e.Fingerprint, e.TrustedFingerprint)
}

// AuthError means the bastion rejected the credentials.
type AuthError struct {
	Host   string
	Method string
	Err    error
}

func (e *AuthError) Error() string {
	return fmt.Sprintf("ssh authentication to %s failed (%s)", e.Host, e.Method)
}

// Unwrap returns the cause.
func (e *AuthError) Unwrap() error { return e.Err }

// TunnelLostError means the tunnel dropped after it was established.
type TunnelLostError struct {
	Host string
	Err  error
}

func (e *TunnelLostError) Error() string { return fmt.Sprintf("ssh tunnel to %s was lost", e.Host) }

// Unwrap returns the cause.
func (e *TunnelLostError) Unwrap() error { return e.Err }

// ConfigError means the tunnel or TLS settings cannot be used.
type ConfigError struct{ Msg string }

func (e *ConfigError) Error() string { return e.Msg }
