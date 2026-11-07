package api

import (
	"context"
	"errors"
	"strings"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/doubledare704/queravue/core/internal/connections"
	"github.com/doubledare704/queravue/core/internal/engine"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/history"
	"github.com/doubledare704/queravue/core/internal/session"
)

// ValidationService implements queravuev1.ValidationServiceServer.
type ValidationService struct {
	queravuev1.UnimplementedValidationServiceServer

	sessions    *session.Manager
	connections *connections.Service
	history     *history.Store
}

// NewValidationService returns a ValidationService handler.
func NewValidationService(s *session.Manager, c *connections.Service, h *history.Store) *ValidationService {
	return &ValidationService{sessions: s, connections: c, history: h}
}

func (v *ValidationService) target(sessionID string, ref *queravuev1.TableRef) (*session.Session, engine.ValidationManager, error) {
	sess, err := v.sessions.Get(sessionID)
	if err != nil {
		return nil, nil, status.Error(codes.NotFound, "session not found")
	}
	if ref.GetTable() == "" {
		return nil, nil, status.Error(codes.InvalidArgument, "table reference is required")
	}
	vm, ok := engine.As[engine.ValidationManager](sess.Conn)
	if !ok {
		return nil, nil, status.Error(codes.FailedPrecondition, "connection has no collection validation")
	}
	return sess, vm, nil
}

// GetValidation implements the RPC.
func (v *ValidationService) GetValidation(ctx context.Context, req *queravuev1.GetValidationRequest) (*queravuev1.GetValidationResponse, error) {
	_, vm, err := v.target(req.GetSessionId(), req.GetTableRef())
	if err != nil {
		return nil, err
	}
	ref := req.GetTableRef()
	rule, err := vm.GetValidation(ctx, ref.GetDatabase(), ref.GetTable())
	if err != nil {
		return &queravuev1.GetValidationResponse{Error: toAdminError(err)}, nil
	}
	return &queravuev1.GetValidationResponse{Rule: &queravuev1.ValidationRule{
		Validator: rule.Validator, Level: validationLevelToProto(rule.Level), Action: validationActionToProto(rule.Action),
	}}, nil
}

// SetValidation implements the RPC.
func (v *ValidationService) SetValidation(ctx context.Context, req *queravuev1.SetValidationRequest) (*queravuev1.SetValidationResponse, error) {
	sess, vm, err := v.target(req.GetSessionId(), req.GetTableRef())
	if err != nil {
		return nil, err
	}
	if !req.GetDryRun() && !req.GetConfirmed() && isProduction(ctx, v.connections, sess) {
		return &queravuev1.SetValidationResponse{Error: adminConfirmation("set validation",
			"This connection is flagged as production. Confirmation is required to change a validator.")}, nil
	}
	ref := req.GetTableRef()
	rule := engine.ValidationRule{
		Validator: req.GetRule().GetValidator(),
		Level:     validationLevelFromProto(req.GetRule().GetLevel()),
		Action:    validationActionFromProto(req.GetRule().GetAction()),
	}
	started := time.Now()
	command, err := vm.SetValidation(ctx, ref.GetDatabase(), ref.GetTable(), rule, req.GetDryRun())
	if !req.GetDryRun() && command != "" {
		v.record(sess, command, started, err)
	}
	if err != nil {
		return &queravuev1.SetValidationResponse{Command: command, DryRun: req.GetDryRun(), Error: toAdminError(err)}, nil
	}
	return &queravuev1.SetValidationResponse{Command: command, DryRun: req.GetDryRun()}, nil
}

func (v *ValidationService) record(sess *session.Session, command string, started time.Time, err error) {
	if v.history == nil {
		return
	}
	e := history.Entry{ConnectionID: sess.ConnectionID, QueryText: command, StartedAt: started, Duration: time.Since(started)}
	if err != nil {
		e.Error = "failed"
		var ee *engine.Error
		if errors.As(err, &ee) {
			e.Error = ee.Msg
		}
	}
	_, _ = v.history.Append(context.Background(), e)
}

func validationLevelFromProto(l queravuev1.ValidationLevel) string {
	switch l {
	case queravuev1.ValidationLevel_VALIDATION_LEVEL_OFF:
		return "off"
	case queravuev1.ValidationLevel_VALIDATION_LEVEL_MODERATE:
		return "moderate"
	case queravuev1.ValidationLevel_VALIDATION_LEVEL_STRICT:
		return "strict"
	case queravuev1.ValidationLevel_VALIDATION_LEVEL_UNSPECIFIED:
		return ""
	}
	return ""
}

func validationLevelToProto(l string) queravuev1.ValidationLevel {
	switch strings.ToLower(l) {
	case "off":
		return queravuev1.ValidationLevel_VALIDATION_LEVEL_OFF
	case "moderate":
		return queravuev1.ValidationLevel_VALIDATION_LEVEL_MODERATE
	case "strict":
		return queravuev1.ValidationLevel_VALIDATION_LEVEL_STRICT
	}
	return queravuev1.ValidationLevel_VALIDATION_LEVEL_UNSPECIFIED
}

func validationActionFromProto(a queravuev1.ValidationAction) string {
	switch a {
	case queravuev1.ValidationAction_VALIDATION_ACTION_ERROR:
		return "error"
	case queravuev1.ValidationAction_VALIDATION_ACTION_WARN:
		return "warn"
	case queravuev1.ValidationAction_VALIDATION_ACTION_UNSPECIFIED:
		return ""
	}
	return ""
}

func validationActionToProto(a string) queravuev1.ValidationAction {
	switch strings.ToLower(a) {
	case "error":
		return queravuev1.ValidationAction_VALIDATION_ACTION_ERROR
	case "warn":
		return queravuev1.ValidationAction_VALIDATION_ACTION_WARN
	}
	return queravuev1.ValidationAction_VALIDATION_ACTION_UNSPECIFIED
}
