package api_test

import (
	"context"
	"testing"

	"github.com/doubledare704/queravue/core/internal/api"
	"github.com/doubledare704/queravue/core/internal/connections"
	"github.com/doubledare704/queravue/core/internal/engine"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/history"
	"github.com/doubledare704/queravue/core/internal/secrets"
	"github.com/doubledare704/queravue/core/internal/session"
)

type fakeValidatingConn struct {
	rule     engine.ValidationRule
	commands []string
}

func (*fakeValidatingConn) Ping(context.Context) error { return nil }
func (*fakeValidatingConn) ServerInfo(context.Context) (engine.ServerInfo, error) {
	return engine.ServerInfo{}, nil
}
func (*fakeValidatingConn) Close() error { return nil }

func (f *fakeValidatingConn) GetValidation(context.Context, string, string) (engine.ValidationRule, error) {
	return f.rule, nil
}

func (f *fakeValidatingConn) SetValidation(_ context.Context, _, collection string, rule engine.ValidationRule, dryRun bool) (string, error) {
	if rule.Validator == "{" {
		return "", &engine.Error{Kind: engine.KindParse, Input: engine.InputValidator, Position: 7, Msg: "bad"}
	}
	command := "collMod " + collection
	if !dryRun {
		f.rule = rule
		f.commands = append(f.commands, command)
	}
	return command, nil
}

type fakeOpener struct{ conn engine.Conn }

func (o fakeOpener) Open(context.Context, string) (engine.Conn, engine.Descriptor, error) {
	return o.conn, engine.Descriptor{}, nil
}

func validationEnv(t *testing.T, production bool) (*api.ValidationService, *session.Session, *fakeValidatingConn, *history.Store) {
	t.Helper()
	conn := &fakeValidatingConn{}
	mgr := session.NewManager(fakeOpener{conn: conn})
	t.Cleanup(mgr.Shutdown)
	sess, err := mgr.Open(context.Background(), "test-conn")
	if err != nil {
		t.Fatal(err)
	}
	hist, err := history.NewStore(":memory:", 100, nil)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = hist.Close() })
	dir := t.TempDir()
	store := connections.NewFileStore(dir)
	_ = store.Save([]connections.Connection{{ID: "test-conn", Name: "T", EngineID: "mongodb", Production: production}})
	reg, err := engine.NewRegistry()
	if err != nil {
		t.Fatal(err)
	}
	return api.NewValidationService(mgr, connections.NewService(reg, store, secrets.NewMemory()), hist), sess, conn, hist
}

func TestValidationServiceSetsAndReadsTheRule(t *testing.T) {
	svc, sess, conn, hist := validationEnv(t, false)
	ref := &queravuev1.TableRef{Database: "d", Table: "c"}
	rule := &queravuev1.ValidationRule{Validator: `{"$jsonSchema":{}}`, Level: queravuev1.ValidationLevel_VALIDATION_LEVEL_MODERATE, Action: queravuev1.ValidationAction_VALIDATION_ACTION_WARN}

	dry, _ := svc.SetValidation(context.Background(), &queravuev1.SetValidationRequest{SessionId: sess.ID, TableRef: ref, Rule: rule, DryRun: true})
	if dry.GetError() != nil || !dry.GetDryRun() || len(conn.commands) != 0 {
		t.Fatalf("dry run: %+v, ran %v", dry, conn.commands)
	}
	if resp, _ := svc.SetValidation(context.Background(), &queravuev1.SetValidationRequest{SessionId: sess.ID, TableRef: ref, Rule: rule}); resp.GetError() != nil {
		t.Fatalf("set: %+v", resp.GetError())
	}
	got, _ := svc.GetValidation(context.Background(), &queravuev1.GetValidationRequest{SessionId: sess.ID, TableRef: ref})
	if got.GetRule().GetLevel() != rule.Level || got.GetRule().GetAction() != rule.Action || got.GetRule().GetValidator() != rule.Validator {
		t.Errorf("rule = %+v", got.GetRule())
	}
	if entries, _, _ := hist.List(context.Background(), "", "", 10, 0); len(entries) != 1 {
		t.Errorf("history has %d entries, want only the applied command", len(entries))
	}
}

func TestValidationServiceProductionNeedsConfirmation(t *testing.T) {
	svc, sess, conn, _ := validationEnv(t, true)
	req := &queravuev1.SetValidationRequest{SessionId: sess.ID, TableRef: &queravuev1.TableRef{Table: "c"}, Rule: &queravuev1.ValidationRule{}}
	resp, _ := svc.SetValidation(context.Background(), req)
	if resp.GetError().GetKind() != queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_CONFIRMATION_REQUIRED || len(conn.commands) != 0 {
		t.Fatalf("response = %+v", resp)
	}
	req.Confirmed = true
	if resp, _ := svc.SetValidation(context.Background(), req); resp.GetError() != nil || len(conn.commands) != 1 {
		t.Errorf("confirmed: %+v", resp)
	}
}

func TestValidationServiceReportsParsePosition(t *testing.T) {
	svc, sess, _, _ := validationEnv(t, false)
	resp, _ := svc.SetValidation(context.Background(), &queravuev1.SetValidationRequest{
		SessionId: sess.ID, TableRef: &queravuev1.TableRef{Table: "c"}, Rule: &queravuev1.ValidationRule{Validator: "{"},
	})
	if resp.GetError().GetKind() != queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_INVALID || resp.GetError().Position == nil || resp.GetError().GetPosition() != 7 {
		t.Errorf("error = %+v", resp.GetError())
	}
}
