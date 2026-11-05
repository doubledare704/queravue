// Package secrets stores credentials in the OS keychain (macOS Keychain,
// Windows Credential Manager, Secret Service on Linux). Nothing else in the
// core may persist a secret.
package secrets

import (
	"errors"
	"fmt"
	"sync"

	"github.com/zalando/go-keyring"
)

// Service is the keychain service name for all Queravue entries.
const Service = "Queravue"

// ErrNotFound means no secret is stored under the ref.
var ErrNotFound = errors.New("secrets: not found")

// Store saves secrets under opaque reference ids.
type Store interface {
	// Set stores or replaces the secret for ref.
	Set(ref, secret string) error
	// Get returns the secret for ref, or ErrNotFound.
	Get(ref string) (string, error)
	// Delete removes ref. Deleting a missing ref is not an error.
	Delete(ref string) error
}

// Keyring is the OS keychain store. On macOS go-keyring drives
// /usr/bin/security and passes the secret on stdin, not argv.
type Keyring struct{}

// Set implements Store.
func (Keyring) Set(ref, secret string) error {
	if err := keyring.Set(Service, ref, secret); err != nil {
		return fmt.Errorf("secrets: set: %w", err)
	}
	return nil
}

// Get implements Store.
func (Keyring) Get(ref string) (string, error) {
	s, err := keyring.Get(Service, ref)
	if errors.Is(err, keyring.ErrNotFound) {
		return "", ErrNotFound
	}
	if err != nil {
		return "", fmt.Errorf("secrets: get: %w", err)
	}
	return s, nil
}

// Delete implements Store.
func (Keyring) Delete(ref string) error {
	err := keyring.Delete(Service, ref)
	if err != nil && !errors.Is(err, keyring.ErrNotFound) {
		return fmt.Errorf("secrets: delete: %w", err)
	}
	return nil
}

// Memory is an in-process Store for tests and QUERAVUE_SECRETS=memory.
type Memory struct {
	mu sync.Mutex
	m  map[string]string
}

// NewMemory returns an empty Memory store.
func NewMemory() *Memory { return &Memory{m: map[string]string{}} }

// Set implements Store.
func (s *Memory) Set(ref, secret string) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.m[ref] = secret
	return nil
}

// Get implements Store.
func (s *Memory) Get(ref string) (string, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	v, ok := s.m[ref]
	if !ok {
		return "", ErrNotFound
	}
	return v, nil
}

// Delete implements Store.
func (s *Memory) Delete(ref string) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	delete(s.m, ref)
	return nil
}

// Len returns the number of stored secrets.
func (s *Memory) Len() int {
	s.mu.Lock()
	defer s.mu.Unlock()
	return len(s.m)
}
