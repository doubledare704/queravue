package api

import (
	"context"
	"errors"
	"fmt"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/doubledare704/queravue/core/internal/diagram"
	"github.com/doubledare704/queravue/core/internal/engine"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/session"
)

const graphBatchTables = 50

// DiagramService implements queravuev1.DiagramServiceServer.
type DiagramService struct {
	queravuev1.UnimplementedDiagramServiceServer

	sessions *session.Manager
	graphs   *diagram.Store
}

// NewDiagramService returns a DiagramService handler. A nil store gets a private one.
func NewDiagramService(s *session.Manager, graphs *diagram.Store) *DiagramService {
	if graphs == nil {
		graphs = diagram.NewStore()
	}
	return &DiagramService{sessions: s, graphs: graphs}
}

func designModeNotImplementedYet() *queravuev1.AdminError {
	return unsupported("applying a diagram is not available yet")
}

func (d *DiagramService) session(id string) (*session.Session, error) {
	sess, err := d.sessions.Get(id)
	if err != nil {
		return nil, status.Error(codes.NotFound, "session not found")
	}
	return sess, nil
}

func graphError(ctx context.Context, err error) *queravuev1.AdminError {
	switch {
	case errors.Is(err, diagram.ErrNotSupported):
		return unsupported("this connection cannot list schema relations")
	case ctx.Err() != nil || errors.Is(err, context.Canceled):
		return adminErr(queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_CANCELED, "loading the schema graph was cancelled")
	}
	return toAdminError(err)
}

// GetSchemaGraph implements the RPC.
func (d *DiagramService) GetSchemaGraph(req *queravuev1.GetSchemaGraphRequest, stream queravuev1.DiagramService_GetSchemaGraphServer) error {
	sess, err := d.session(req.GetSessionId())
	if err != nil {
		return err
	}
	ctx := stream.Context()
	send := func(m *queravuev1.GetSchemaGraphResponse) error {
		if err := stream.Send(m); err != nil {
			return fmt.Errorf("diagram: send: %w", err)
		}
		return nil
	}
	graph, err := d.graphs.Get(ctx, sess, req.GetDatabase(), req.GetSchema(), req.GetRefresh())
	if err != nil {
		return send(&queravuev1.GetSchemaGraphResponse{Done: true, Error: graphError(ctx, err)})
	}
	tables := graphTablesToProto(filterSystemTables(graph.Tables))
	total := uint32(len(tables)) //nolint:gosec // a schema has far fewer tables than 2^32
	for start := 0; start < len(tables); start += graphBatchTables {
		if ctx.Err() != nil {
			return send(&queravuev1.GetSchemaGraphResponse{Done: true, TablesTotal: total, Error: graphError(ctx, ctx.Err())})
		}
		end := min(start+graphBatchTables, len(tables))
		if err := send(&queravuev1.GetSchemaGraphResponse{
			Tables:      tables[start:end],
			TablesTotal: total,
			TablesDone:  uint32(end),
		}); err != nil {
			return err
		}
	}
	return send(&queravuev1.GetSchemaGraphResponse{Done: true, TablesTotal: total, TablesDone: total})
}

func filterSystemTables(tables []diagram.Table) []diagram.Table {
	objects := make([]engine.SchemaObject, len(tables))
	for i, t := range tables {
		objects[i] = engine.SchemaObject{Name: t.Name, Type: t.Type}
	}
	kept := map[string]bool{}
	for _, o := range filterSystem(objects, false) {
		kept[o.Name] = true
	}
	out := make([]diagram.Table, 0, len(tables))
	for _, t := range tables {
		if kept[t.Name] {
			out = append(out, t)
		}
	}
	return out
}

func graphTablesToProto(tables []diagram.Table) []*queravuev1.GraphTable {
	objects := make([]engine.SchemaObject, len(tables))
	for i, t := range tables {
		objects[i] = engine.SchemaObject{Name: t.Name, Type: t.Type, EstimatedRows: t.EstimatedRows}
	}
	described := toProtoObjects(objects)
	out := make([]*queravuev1.GraphTable, len(tables))
	for i, t := range tables {
		columns := make([]*queravuev1.GraphColumn, len(t.Columns))
		for j, c := range t.Columns {
			columns[j] = &queravuev1.GraphColumn{
				Name:            c.Name,
				TypeName:        c.TypeName,
				Nullable:        c.Nullable,
				PrimaryKeyOrder: uint32(max(c.PrimaryKeyOrder, 0)), //nolint:gosec // clamped to >= 0
			}
		}
		relations := make([]*queravuev1.GraphRelation, len(t.Relations))
		for j, r := range t.Relations {
			relations[j] = &queravuev1.GraphRelation{
				Name:              r.Name,
				Columns:           r.Columns,
				ReferencedSchema:  r.ReferencedSchema,
				ReferencedTable:   r.ReferencedTable,
				ReferencedColumns: r.ReferencedColumns,
				OnDelete:          referentialActionToProto(r.OnDelete),
				OnUpdate:          referentialActionToProto(r.OnUpdate),
			}
		}
		out[i] = &queravuev1.GraphTable{
			Name:             t.Name,
			Type:             described[i].GetType(),
			RowCountEstimate: t.EstimatedRows,
			Columns:          columns,
			Relations:        relations,
			ColumnsTruncated: t.ColumnsTruncated,
		}
	}
	return out
}

// PreviewDiagramDDL implements the RPC.
func (d *DiagramService) PreviewDiagramDDL(_ context.Context, req *queravuev1.PreviewDiagramDDLRequest) (*queravuev1.PreviewDiagramDDLResponse, error) {
	if _, err := d.session(req.GetSessionId()); err != nil {
		return nil, err
	}
	return &queravuev1.PreviewDiagramDDLResponse{Error: designModeNotImplementedYet()}, nil
}

// ApplyDiagramDDL implements the RPC.
func (d *DiagramService) ApplyDiagramDDL(_ context.Context, req *queravuev1.ApplyDiagramDDLRequest) (*queravuev1.ApplyDiagramDDLResponse, error) {
	if _, err := d.session(req.GetSessionId()); err != nil {
		return nil, err
	}
	return &queravuev1.ApplyDiagramDDLResponse{Error: designModeNotImplementedYet()}, nil
}
