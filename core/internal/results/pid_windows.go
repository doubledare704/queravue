//go:build windows

package results

// pidAlive is conservative on Windows: stale directories are kept.
func pidAlive(int) bool { return true }
