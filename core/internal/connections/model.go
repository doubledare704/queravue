// Package connections manages saved connection profiles: persistence without
// secrets, keychain-backed passwords, and connection tests.
package connections

import (
	"errors"
	"strings"
	"time"
)

// Color is a connection's color tag. Values mirror queravue.v1.ColorTag.
type Color int

// Color tags.
const (
	ColorNone Color = iota
	ColorRed
	ColorOrange
	ColorYellow
	ColorGreen
	ColorBlue
	ColorPurple
	ColorGray
)

var colorNames = []string{"", "red", "orange", "yellow", "green", "blue", "purple", "gray"}

// MarshalText stores colors by name so the JSON file stays readable.
func (c Color) MarshalText() ([]byte, error) {
	if c < 0 || int(c) >= len(colorNames) {
		return nil, errors.New("connections: invalid color")
	}
	return []byte(colorNames[c]), nil
}

// UnmarshalText implements encoding.TextUnmarshaler. Unknown names map to
// ColorNone so a newer file never fails to load.
func (c *Color) UnmarshalText(b []byte) error {
	for i, n := range colorNames {
		if n == string(b) {
			*c = Color(i)
			return nil
		}
	}
	*c = ColorNone
	return nil
}

// Connection is a saved profile. It deliberately has no password field: the
// secret lives in the keychain under SecretRef.
type Connection struct {
	ID         string            `json:"id"`
	Name       string            `json:"name"`
	EngineID   string            `json:"engine"`
	Params     map[string]string `json:"params,omitempty"`
	Folder     string            `json:"folder,omitempty"`
	Color      Color             `json:"color,omitempty"`
	Production bool              `json:"production,omitempty"`
	// SecretRef is the keychain account holding the password; empty if none.
	SecretRef string    `json:"secretRef,omitempty"`
	CreatedAt time.Time `json:"createdAt"`
	UpdatedAt time.Time `json:"updatedAt"`
}

// HasPassword reports whether a password is stored for c.
func (c Connection) HasPassword() bool { return c.SecretRef != "" }

// NormalizeFolder trims each "/"-separated segment and drops empty ones:
// " Work / /Clients/ " → "Work/Clients".
func NormalizeFolder(f string) string {
	var segs []string
	for _, s := range strings.Split(f, "/") {
		if s = strings.TrimSpace(s); s != "" {
			segs = append(segs, s)
		}
	}
	return strings.Join(segs, "/")
}

func secretRef(id string) string { return "conn/" + id }
