package engine

import "context"

// ValidationRule is a collection's validator and how strictly it applies.
// Validator is canonical EJSON, empty for none. Level is "off", "moderate" or
// "strict" and Action is "error" or "warn"; empty means the server default.
type ValidationRule struct {
	Validator string
	Level     string
	Action    string
}

// ValidationManager is implemented by Conns with CapValidation.
type ValidationManager interface {
	GetValidation(ctx context.Context, database, collection string) (ValidationRule, error)
	// SetValidation replaces the rule; an empty validator removes it. With
	// dryRun it only returns the command.
	SetValidation(ctx context.Context, database, collection string, rule ValidationRule, dryRun bool) (command string, err error)
}
