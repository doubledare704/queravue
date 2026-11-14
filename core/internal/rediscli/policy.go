package rediscli

import (
	"bytes"
	"fmt"
	"strings"
)

// Verdict says what core does with a command before it reaches the server.
type Verdict struct {
	// Keys: the command is KEYS.
	Keys bool
	// Blocking: the command would hold the connection open.
	Blocking bool
	// ConfirmOperation is non-empty when production connections need
	// confirmation, and says what to confirm.
	ConfirmOperation string
}

var blockingCommands = map[string]bool{
	"BLPOP": true, "BRPOP": true, "BRPOPLPUSH": true, "BLMOVE": true, "BLMPOP": true,
	"BZPOPMIN": true, "BZPOPMAX": true, "BZMPOP": true,
	"SUBSCRIBE": true, "PSUBSCRIBE": true, "SSUBSCRIBE": true, "MONITOR": true,
	"SYNC": true, "PSYNC": true, "WAIT": true, "WAITAOF": true,
}

// Inspect classifies one pre-split command.
func Inspect(args [][]byte) Verdict {
	if len(args) == 0 {
		return Verdict{}
	}
	name := strings.ToUpper(string(args[0]))
	switch {
	case name == "KEYS":
		return Verdict{Keys: true}
	case blockingCommands[name], isBlockingStreamRead(name, args):
		return Verdict{Blocking: true}
	}
	return Verdict{ConfirmOperation: confirmOperation(name, args)}
}

func isBlockingStreamRead(name string, args [][]byte) bool {
	if name != "XREAD" && name != "XREADGROUP" {
		return false
	}
	for _, a := range args[1:] {
		if bytes.EqualFold(a, []byte("BLOCK")) {
			return true
		}
	}
	return false
}

func confirmOperation(name string, args [][]byte) string {
	switch name {
	case "FLUSHALL":
		return "FLUSHALL on every database"
	case "FLUSHDB":
		return "FLUSHDB on the selected database"
	case "SHUTDOWN":
		return "SHUTDOWN of the server"
	case "DEBUG":
		return "DEBUG " + subcommand(args)
	case "CONFIG":
		if strings.EqualFold(subcommand(args), "SET") {
			return "CONFIG SET"
		}
	case "DEL", "UNLINK":
		if len(args) > 2 {
			return fmt.Sprintf("%s %d keys", name, len(args)-1)
		}
	}
	return ""
}

func subcommand(args [][]byte) string {
	if len(args) < 2 {
		return ""
	}
	return strings.ToUpper(string(args[1]))
}

// DeleteNeedsConfirmation reports whether deleting n keys needs confirmation
// on a production connection.
func DeleteNeedsConfirmation(n int) bool { return n > 1 }
