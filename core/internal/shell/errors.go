package shell

import "fmt"

// ErrorKind classifies a script failure.
type ErrorKind int

// Error kinds; they mirror queravue.v1.ShellErrorKind.
const (
	KindRuntime ErrorKind = iota + 1
	KindSyntax
	KindConfirmationRequired
	KindOutputLimit
	KindTimeout
	KindCanceled
	KindServer
	KindUnsupported
)

// Error is a typed script failure. Line and Column are 1-based; Column is in
// UTF-16 code units. Both are 0 when unknown.
type Error struct {
	Kind      ErrorKind
	Message   string
	Stack     string
	Line      int
	Column    int
	Operation string
}

// Error implements error.
func (e *Error) Error() string {
	if e.Line > 0 {
		return fmt.Sprintf("%s (line %d, column %d)", e.Message, e.Line, e.Column)
	}
	return e.Message
}
