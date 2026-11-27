package mockdata

import "fmt"

// ErrorKind classifies failures produced by the mock data generator.
type ErrorKind int

// Error kinds classifying mock generation failures.
const (
	ErrParse ErrorKind = iota + 1
	ErrCycle
	ErrUniqueExhausted
	ErrUnsupported
)

// Error is a structured mock generation error carrying optional target and column context.
type Error struct {
	Kind    ErrorKind
	Message string
	Target  *TargetRef
	Column  string
	Err     error
}

func (e *Error) Error() string {
	switch {
	case e.Target != nil && e.Column != "":
		return fmt.Sprintf("mockdata: %s.%s: %s", e.Target.Name, e.Column, e.Message)
	case e.Target != nil:
		return fmt.Sprintf("mockdata: %s: %s", e.Target.Name, e.Message)
	case e.Column != "":
		return fmt.Sprintf("mockdata: %s: %s", e.Column, e.Message)
	default:
		return "mockdata: " + e.Message
	}
}

func (e *Error) Unwrap() error { return e.Err }

func parseErr(target *TargetRef, col, msg string) *Error {
	return &Error{Kind: ErrParse, Message: msg, Target: target, Column: col}
}
