package connections

import (
	"time"

	"github.com/doubledare704/queravue/core/internal/netpath"
)

// SSHTunnel is a bastion setting. Secrets live in the keychain; the Has flags
// record which ones are stored.
type SSHTunnel struct {
	Host                  string          `json:"host"`
	Port                  int             `json:"port,omitempty"`
	User                  string          `json:"user"`
	Auth                  netpath.SSHAuth `json:"auth,omitempty"`
	KeyFile               string          `json:"keyFile,omitempty"`
	KeepAliveSeconds      int             `json:"keepAliveSeconds,omitempty"`
	ConnectTimeoutSeconds int             `json:"connectTimeoutSeconds,omitempty"`
	Jump                  *SSHTunnel      `json:"jump,omitempty"`
	HasPassword           bool            `json:"hasPassword,omitempty"`
	HasKeyPassphrase      bool            `json:"hasKeyPassphrase,omitempty"`
}

// TLSSettings mirrors netpath.TLSSettings without the passphrase.
type TLSSettings struct {
	Mode                   netpath.TLSMode `json:"mode"`
	CAFile                 string          `json:"caFile,omitempty"`
	ClientCertFile         string          `json:"clientCertFile,omitempty"`
	ClientKeyFile          string          `json:"clientKeyFile,omitempty"`
	ServerName             string          `json:"serverName,omitempty"`
	HasClientKeyPassphrase bool            `json:"hasClientKeyPassphrase,omitempty"`
}

// SSHSecrets carries tunnel secrets into the service. A nil field keeps the
// stored value, an empty string removes it.
type SSHSecrets struct {
	Password          *string
	KeyPassphrase     *string
	JumpPassword      *string
	JumpKeyPassphrase *string
	Clear             bool
}

// TLSSecrets carries the client key passphrase into the service.
type TLSSecrets struct {
	ClientKeyPassphrase *string
	Clear               bool
}

// Secrets is every secret a create, update or test request can carry.
type Secrets struct {
	Password      *string
	ClearPassword bool
	SSH           SSHSecrets
	TLS           TLSSecrets
}

func (t *SSHTunnel) netpathConfig(creds credentials, jump bool) netpath.SSHConfig {
	cfg := netpath.SSHConfig{
		Host: t.Host, Port: t.Port, User: t.User, Auth: t.Auth, KeyFile: t.KeyFile,
		KeepAlive:      time.Duration(t.KeepAliveSeconds) * time.Second,
		ConnectTimeout: time.Duration(t.ConnectTimeoutSeconds) * time.Second,
	}
	cfg.Password, cfg.KeyPassphrase = creds.sshPassword, creds.sshPassphrase
	if jump {
		cfg.Password, cfg.KeyPassphrase = creds.jumpPassword, creds.jumpPassphrase
	}
	if t.Jump != nil {
		j := t.Jump.netpathConfig(creds, true)
		cfg.Jump = &j
	}
	return cfg
}

func (t *TLSSettings) netpathSettings(passphrase string) netpath.TLSSettings {
	if t == nil {
		return netpath.TLSSettings{}
	}
	return netpath.TLSSettings{
		Mode: t.Mode, CAFile: t.CAFile, ClientCert: t.ClientCertFile, ClientKey: t.ClientKeyFile,
		ServerName: t.ServerName, KeyPassphrase: passphrase,
	}
}

func fromNetpath(s netpath.TLSSettings) *TLSSettings {
	return &TLSSettings{Mode: s.Mode, CAFile: s.CAFile, ClientCertFile: s.ClientCert, ClientKeyFile: s.ClientKey, ServerName: s.ServerName}
}

type secretSlot string

// Keychain slot names, not credentials.
//
//nolint:gosec
const (
	slotSSHPassword      secretSlot = "ssh-password"
	slotSSHPassphrase    secretSlot = "ssh-key-passphrase"
	slotJumpPassword     secretSlot = "ssh-jump-password"
	slotJumpPassphrase   secretSlot = "ssh-jump-key-passphrase"
	slotTLSKeyPassphrase secretSlot = "tls-key-passphrase"
)

var allSlots = []secretSlot{slotSSHPassword, slotSSHPassphrase, slotJumpPassword, slotJumpPassphrase, slotTLSKeyPassphrase}

func slotRef(id string, slot secretSlot) string { return secretRef(id) + "/" + string(slot) }

// flag returns the stored-secret flag for slot, or nil if the connection has
// no setting the slot belongs to.
func (c *Connection) flag(slot secretSlot) *bool {
	switch slot {
	case slotSSHPassword:
		if c.SSH != nil {
			return &c.SSH.HasPassword
		}
	case slotSSHPassphrase:
		if c.SSH != nil {
			return &c.SSH.HasKeyPassphrase
		}
	case slotJumpPassword:
		if c.SSH != nil && c.SSH.Jump != nil {
			return &c.SSH.Jump.HasPassword
		}
	case slotJumpPassphrase:
		if c.SSH != nil && c.SSH.Jump != nil {
			return &c.SSH.Jump.HasKeyPassphrase
		}
	case slotTLSKeyPassphrase:
		if c.TLS != nil {
			return &c.TLS.HasClientKeyPassphrase
		}
	}
	return nil
}

func (s Secrets) value(slot secretSlot) *string {
	switch slot {
	case slotSSHPassword:
		return s.SSH.Password
	case slotSSHPassphrase:
		return s.SSH.KeyPassphrase
	case slotJumpPassword:
		return s.SSH.JumpPassword
	case slotJumpPassphrase:
		return s.SSH.JumpKeyPassphrase
	default:
		return s.TLS.ClientKeyPassphrase
	}
}

func (s Secrets) clears(slot secretSlot) bool {
	if slot == slotTLSKeyPassphrase {
		return s.TLS.Clear
	}
	return s.SSH.Clear
}
