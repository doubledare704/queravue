package workspace

// ErrorKind classifies a workspace failure. Values mirror
// queravue.v1.WorkspaceErrorKind.
type ErrorKind int

// Error kinds.
const (
	KindIO ErrorKind = iota + 1
	KindPathEscapesRoot
	KindNotFound
	KindAlreadyExists
	KindConflict
	KindTooLarge
)

// Error is a typed workspace failure.
type Error struct {
	Kind ErrorKind
	Msg  string
	// Current is the file as it is on disk, for KindConflict; nil if the file
	// was deleted.
	Current *File
	Err     error
}

// Error implements error.
func (e *Error) Error() string { return "workspace: " + e.Msg }

// Unwrap returns the underlying cause.
func (e *Error) Unwrap() error { return e.Err }

func newError(kind ErrorKind, msg string, cause error) *Error {
	return &Error{Kind: kind, Msg: msg, Err: cause}
}
