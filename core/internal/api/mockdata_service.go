package api

import (
	"context"
	"crypto/rand"
	"encoding/binary"
	"errors"
	"fmt"
	"log/slog"
	"strings"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/doubledare704/queravue/core/internal/connections"
	"github.com/doubledare704/queravue/core/internal/engine"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/mockdata"
	"github.com/doubledare704/queravue/core/internal/results"
	"github.com/doubledare704/queravue/core/internal/session"
)

const defaultSuggestRows = 1000

// MockDataService implements queravuev1.MockDataServiceServer.
type MockDataService struct {
	queravuev1.UnimplementedMockDataServiceServer

	sessions    *session.Manager
	connections *connections.Service
	log         *slog.Logger
}

// NewMockDataService returns a MockDataService backed by s and c. connections may be
// nil, in which case no connection counts as production.
func NewMockDataService(s *session.Manager, c *connections.Service, log *slog.Logger) *MockDataService {
	if log == nil {
		log = slog.Default()
	}
	return &MockDataService{sessions: s, connections: c, log: log}
}

func (m *MockDataService) session(id string) (*session.Session, error) {
	sess, err := m.sessions.Get(id)
	if err != nil {
		return nil, status.Error(codes.NotFound, "session not found")
	}
	return sess, nil
}

// SuggestMockSpec proposes default rules, topological table order, and cycles.
func (m *MockDataService) SuggestMockSpec(ctx context.Context, req *queravuev1.SuggestMockSpecRequest) (*queravuev1.SuggestMockSpecResponse, error) {
	sess, err := m.session(req.GetSessionId())
	if err != nil {
		return nil, err
	}

	_, hasRowLoader := engine.As[engine.RowLoader](sess.Conn)
	si, hasSchema := engine.As[engine.SchemaInspector](sess.Conn)
	_, hasDocLoader := engine.As[engine.DocumentLoader](sess.Conn)
	ds, hasDocStore := engine.As[engine.DocumentStore](sess.Conn)

	if len(req.GetTables()) > 0 && (!hasRowLoader || !hasSchema) {
		return nil, status.Error(codes.FailedPrecondition, "connection does not support bulk table loading and schema inspection")
	}
	if len(req.GetCollections()) > 0 && (!hasDocLoader || !hasDocStore) {
		return nil, status.Error(codes.FailedPrecondition, "connection does not support document loading and sampling")
	}
	if len(req.GetTables()) == 0 && len(req.GetCollections()) == 0 && (!hasRowLoader || !hasSchema) && (!hasDocLoader || !hasDocStore) {
		return nil, status.Error(codes.FailedPrecondition, "connection does not support mock data generation")
	}

	rows := req.GetRows()
	if rows == 0 {
		rows = defaultSuggestRows
	}
	sctx, finish, err := sess.Begin(ctx)
	switch {
	case errors.Is(err, session.ErrBusy):
		return nil, status.Error(codes.FailedPrecondition, "session is busy running another statement")
	case err != nil:
		return nil, status.Error(codes.NotFound, "session not found")
	}
	defer finish()

	now := time.Now().UTC()
	fakerKinds := mockdata.SupportedFakerKinds()
	var warnings []string
	var targets []mockdata.TargetSpec
	var cycles []mockdata.Cycle

	if len(req.GetTables()) > 0 {
		tableTargets, tableCycles, tableWarnings, mockErr := m.suggestTables(sctx, sess.Conn, si, req.GetTables(), rows, now)
		if mockErr != nil {
			return &queravuev1.SuggestMockSpecResponse{
				FakerKinds: fakerKinds,
				Error:      mockErr,
			}, nil
		}
		targets = append(targets, tableTargets...)
		cycles = append(cycles, tableCycles...)
		warnings = append(warnings, tableWarnings...)
	}

	for _, c := range req.GetCollections() {
		ref := mockdata.TargetRef{
			IsCollection: true,
			Database:     c.GetDatabase(),
			Name:         c.GetCollection(),
		}
		sample, err := ds.SampleFieldPaths(sctx, c.GetDatabase(), c.GetCollection(), engine.PathSampleOptions{})
		if err != nil {
			return &queravuev1.SuggestMockSpecResponse{
				FakerKinds: fakerKinds,
				Error:      toMockError(err, &ref, ""),
			}, nil
		}
		rules, colWarnings := mockdata.SuggestCollectionRules(sample, now)
		warnings = append(warnings, colWarnings...)
		targets = append(targets, mockdata.TargetSpec{
			Target: ref,
			Rows:   rows,
			Rules:  rules,
		})
	}

	return &queravuev1.SuggestMockSpecResponse{
		Spec: specToProto(mockdata.Spec{
			Seed:    newSeed(),
			Targets: targets,
		}),
		Cycles:     cyclesToProto(cycles),
		FakerKinds: fakerKinds,
		Warnings:   warnings,
	}, nil
}

func (m *MockDataService) suggestTables(
	ctx context.Context,
	conn engine.Conn,
	si engine.SchemaInspector,
	tableRefs []*queravuev1.TableRef,
	rows uint64,
	now time.Time,
) ([]mockdata.TargetSpec, []mockdata.Cycle, []string, *queravuev1.MockError) {
	refs := make([]mockdata.TargetRef, 0, len(tableRefs))
	selected := make(map[string]bool, len(tableRefs))
	for _, tr := range tableRefs {
		if tr == nil || tr.GetTable() == "" {
			return nil, nil, nil, &queravuev1.MockError{
				Kind:    queravuev1.MockErrorKind_MOCK_ERROR_KIND_PARSE,
				Message: "table reference requires a table name",
			}
		}
		r := mockdata.TargetRef{
			Database: tr.GetDatabase(),
			Schema:   tr.GetSchema(),
			Name:     tr.GetTable(),
		}
		refs = append(refs, r)
		selected[r.Key()] = true
	}

	var ordered []mockdata.TargetRef
	var cycles []mockdata.Cycle
	extraFKsByTable := map[string][]engine.ForeignKeyDef{}
	referencedColsByTable := map[string]map[string]bool{}

	rl, hasGraph := engine.As[engine.RelationLister](conn)
	if hasGraph {
		relInfos, extraFKs, refCols, err := collectGraphRelations(ctx, rl, refs, selected)
		if err != nil {
			return nil, nil, nil, toMockError(err, nil, "")
		}
		extraFKsByTable = extraFKs
		referencedColsByTable = refCols
		ordered, cycles = mockdata.PlanTables(refs, relInfos)
	} else {
		ordered = refs
	}

	targets := make([]mockdata.TargetSpec, 0, len(ordered))
	var warnings []string
	for _, ref := range ordered {
		td, err := si.DescribeTable(ctx, ref.Database, ref.Schema, ref.Name)
		if err != nil {
			return nil, nil, nil, toMockError(err, &ref, "")
		}
		if !hasGraph {
			// Without schema_graph, FK columns get no default foreign_key rule (ADR 0025).
			td.ForeignKeys = nil
		}
		rules, tw := mockdata.SuggestTableRules(td, extraFKsByTable[ref.Key()], selected, referencedColsByTable[ref.Key()], rows, now)
		warnings = append(warnings, tw...)
		targets = append(targets, mockdata.TargetSpec{
			Target: ref,
			Rows:   rows,
			Rules:  rules,
		})
	}
	return targets, cycles, warnings, nil
}

func collectGraphRelations(
	ctx context.Context,
	rl engine.RelationLister,
	refs []mockdata.TargetRef,
	selected map[string]bool,
) ([]mockdata.TableRelationInfo, map[string][]engine.ForeignKeyDef, map[string]map[string]bool, error) {
	type scope struct{ db, schema string }
	seenScope := map[scope]bool{}
	var relInfos []mockdata.TableRelationInfo
	extraFKs := map[string][]engine.ForeignKeyDef{}
	refCols := map[string]map[string]bool{}

	for _, ref := range refs {
		sc := scope{db: ref.Database, schema: ref.Schema}
		if seenScope[sc] {
			continue
		}
		seenScope[sc] = true

		keyed, err := rl.ListKeyedColumns(ctx, sc.db, sc.schema)
		if err != nil {
			return nil, nil, nil, fmt.Errorf("list keyed columns: %w", err)
		}
		nullableCol := make(map[string]bool, len(keyed))
		for _, kc := range keyed {
			nullableCol[strings.ToLower(kc.Table)+"."+strings.ToLower(kc.Name)] = kc.Nullable
		}

		rels, err := rl.ListRelations(ctx, sc.db, sc.schema)
		if err != nil {
			return nil, nil, nil, fmt.Errorf("list relations: %w", err)
		}
		for _, tr := range rels {
			child := mockdata.TargetRef{Database: sc.db, Schema: sc.schema, Name: tr.Table}
			if !selected[child.Key()] {
				continue
			}
			extraFKs[child.Key()] = append(extraFKs[child.Key()], tr.ForeignKeyDef)
			parentSchema := tr.ReferencedSchema
			if parentSchema == "" {
				parentSchema = sc.schema
			}
			parent := mockdata.TargetRef{Database: sc.db, Schema: parentSchema, Name: tr.ReferencedTable}

			allNullable := len(tr.Columns) > 0
			for _, col := range tr.Columns {
				if !nullableCol[strings.ToLower(tr.Table)+"."+strings.ToLower(col)] {
					allNullable = false
					break
				}
			}
			relInfos = append(relInfos, mockdata.TableRelationInfo{
				Child:    child,
				Parent:   parent,
				FK:       tr.ForeignKeyDef,
				Nullable: allNullable,
			})
			if selected[parent.Key()] {
				cols := refCols[parent.Key()]
				if cols == nil {
					cols = map[string]bool{}
					refCols[parent.Key()] = cols
				}
				for _, rc := range tr.ReferencedColumns {
					cols[strings.ToLower(rc)] = true
				}
			}
		}
	}
	return relInfos, extraFKs, refCols, nil
}

// PreviewMock generates sample rows or documents without writing to the database.
func (m *MockDataService) PreviewMock(ctx context.Context, req *queravuev1.PreviewMockRequest) (*queravuev1.PreviewMockResponse, error) {
	sess, err := m.session(req.GetSessionId())
	if err != nil {
		return nil, err
	}

	spec, err := protoToSpec(req.GetSpec())
	if err != nil {
		return &queravuev1.PreviewMockResponse{Error: toMockError(err, nil, "")}, nil
	}
	if err := checkLoadCapabilities(sess.Conn, spec); err != nil {
		return nil, err
	}

	sctx, finish, err := sess.Begin(ctx)
	switch {
	case errors.Is(err, session.ErrBusy):
		return nil, status.Error(codes.FailedPrecondition, "session is busy running another statement")
	case err != nil:
		return nil, status.Error(codes.NotFound, "session not found")
	}
	defer finish()

	previews, err := mockdata.Preview(sctx, spec, req.GetRows(), existingKeyLoader(sess))
	if err != nil {
		return &queravuev1.PreviewMockResponse{Error: toMockError(err, nil, "")}, nil
	}

	out := make([]*queravuev1.MockPreview, len(previews))
	for i, p := range previews {
		mp := &queravuev1.MockPreview{
			Target:         targetRefToProto(p.Target),
			Columns:        p.Columns,
			DocumentsEjson: p.DocumentsEJSON,
		}
		if len(p.Rows) > 0 || len(p.Columns) > 0 {
			mp.Rows = &queravuev1.RowBatch{Rows: results.RowsToProto(p.Rows)}
		}
		out[i] = mp
	}
	return &queravuev1.PreviewMockResponse{Previews: out}, nil
}

// RunMock generates and loads every target in order, streaming progress and summary events.
func (m *MockDataService) RunMock(req *queravuev1.RunMockRequest, stream queravuev1.MockDataService_RunMockServer) error {
	sess, err := m.session(req.GetSessionId())
	if err != nil {
		return err
	}

	spec, err := protoToSpec(req.GetSpec())
	if err != nil {
		return sendMockErrAndSummary(stream, toMockError(err, nil, ""), mockdata.Summary{})
	}
	if err := checkLoadCapabilities(sess.Conn, spec); err != nil {
		return err
	}

	if isProduction(stream.Context(), m.connections, sess) && !req.GetConfirmed() {
		return sendMockErrAndSummary(stream, &queravuev1.MockError{
			Kind:    queravuev1.MockErrorKind_MOCK_ERROR_KIND_CONFIRMATION_REQUIRED,
			Message: "connection is flagged production; confirmation required",
		}, mockdata.Summary{})
	}

	ctx, finish, err := sess.Begin(stream.Context())
	switch {
	case errors.Is(err, session.ErrBusy):
		return status.Error(codes.FailedPrecondition, "session is busy running another statement")
	case err != nil:
		return status.Error(codes.NotFound, "session not found")
	}
	defer finish()

	rowLoader, _ := engine.As[engine.RowLoader](sess.Conn)
	docLoader, _ := engine.As[engine.DocumentLoader](sess.Conn)

	summary, runErr := mockdata.Run(ctx, spec, rowLoader, docLoader, existingKeyLoader(sess), func(ev mockdata.RunEvent) error {
		if ev.Progress != nil {
			return sendRunEvent(stream, &queravuev1.RunMockResponse{
				Event: &queravuev1.RunMockResponse_Progress{
					Progress: &queravuev1.MockProgress{
						Target:        targetRefToProto(ev.Progress.Target),
						Rows:          ev.Progress.Rows,
						RowsPerSecond: ev.Progress.RowsPerSecond,
					},
				},
			})
		}
		if ev.TargetDone != nil {
			return sendRunEvent(stream, &queravuev1.RunMockResponse{
				Event: &queravuev1.RunMockResponse_TargetDone{
					TargetDone: &queravuev1.MockTargetDone{
						Target:    targetRefToProto(ev.TargetDone.Target),
						Rows:      ev.TargetDone.Rows,
						ElapsedMs: ev.TargetDone.ElapsedMs,
					},
				},
			})
		}
		return nil
	})
	if runErr != nil {
		return sendMockErrAndSummary(stream, toMockError(runErr, nil, ""), summary)
	}
	return sendRunEvent(stream, &queravuev1.RunMockResponse{
		Event: &queravuev1.RunMockResponse_Summary{Summary: summaryToProto(summary)},
	})
}

func checkLoadCapabilities(conn engine.Conn, spec mockdata.Spec) error {
	_, hasRowLoader := engine.As[engine.RowLoader](conn)
	_, hasDocLoader := engine.As[engine.DocumentLoader](conn)

	var needRow, needDoc bool
	for _, t := range spec.Targets {
		if t.Target.IsCollection {
			needDoc = true
		} else {
			needRow = true
		}
	}
	if needRow && !hasRowLoader {
		return status.Error(codes.FailedPrecondition, "connection does not support bulk row loading")
	}
	if needDoc && !hasDocLoader {
		return status.Error(codes.FailedPrecondition, "connection does not support document loading")
	}
	if !needRow && !needDoc && !hasRowLoader && !hasDocLoader {
		return status.Error(codes.FailedPrecondition, "connection does not support mock data loading")
	}
	return nil
}

func existingKeyLoader(sess *session.Session) mockdata.ExistingKeyLoader {
	ex, ok := engine.As[engine.Executor](sess.Conn)
	if !ok || sess.Dialect == nil {
		return nil
	}
	return mockdata.NewSQLExistingKeyLoader(ex, sess.Dialect)
}

func sendRunEvent(stream queravuev1.MockDataService_RunMockServer, msg *queravuev1.RunMockResponse) error {
	if err := stream.Send(msg); err != nil {
		return fmt.Errorf("mockdata: send: %w", err)
	}
	return nil
}

func sendMockErrAndSummary(stream queravuev1.MockDataService_RunMockServer, mockErr *queravuev1.MockError, summary mockdata.Summary) error {
	if err := sendRunEvent(stream, &queravuev1.RunMockResponse{
		Event: &queravuev1.RunMockResponse_Error{Error: mockErr},
	}); err != nil {
		return err
	}
	return sendRunEvent(stream, &queravuev1.RunMockResponse{
		Event: &queravuev1.RunMockResponse_Summary{Summary: summaryToProto(summary)},
	})
}

func newSeed() uint64 {
	var b [8]byte
	if _, err := rand.Read(b[:]); err == nil {
		return binary.LittleEndian.Uint64(b[:])
	}
	return uint64(time.Now().UnixNano())
}
