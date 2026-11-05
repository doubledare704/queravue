//go:build !windows

package results

import (
	"errors"
	"syscall"
)

// pidAlive reports whether a process with pid exists.
func pidAlive(pid int) bool {
	err := syscall.Kill(pid, 0)
	return err == nil || errors.Is(err, syscall.EPERM)
}
