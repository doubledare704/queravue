package api

import (
	"context"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/doubledare704/queravue/core/internal/engine"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/results"
	"github.com/doubledare704/queravue/core/internal/schema"
	"github.com/doubledare704/queravue/core/internal/session"
)

// SchemaService implements queravuev1.SchemaServiceServer.
type SchemaService struct {
	queravuev1.UnimplementedSchemaServiceServer

	sessions *session.Manager
	cache    *schema.Cache
}

// NewSchemaService returns a SchemaService handler.
func NewSchemaService(s *session.Manager, c *schema.Cache) *SchemaService {
	if c == nil {
		c = schema.NewCache()
	}
	return &SchemaService{sessions: s, cache: c}
}

func (s *SchemaService) getInspector(sessionID string) (*session.Session, engine.SchemaInspector, error) {
	sess, err := s.sessions.Get(sessionID)
	if err != nil {
		return nil, nil, status.Error(codes.NotFound, "session not found")
	}
	inspector, ok := engine.As[engine.SchemaInspector](sess.Conn)
	if !ok {
		return nil, nil, status.Error(codes.FailedPrecondition, "connection does not support schema inspection")
	}
	return sess, inspector, nil
}

// ListDatabases implements the RPC.
func (s *SchemaService) ListDatabases(ctx context.Context, req *queravuev1.ListDatabasesRequest) (*queravuev1.ListDatabasesResponse, error) {
	sess, inspector, err := s.getInspector(req.GetSessionId())
	if err != nil {
		return nil, err
	}

	if !req.GetRefresh() {
		if cached, ok := s.cache.GetDatabases(sess.ID); ok {
			return &queravuev1.ListDatabasesResponse{Databases: cached}, nil
		}
	}

	dbs, err := inspector.ListDatabases(ctx)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "list databases: %v", err)
	}

	s.cache.SetDatabases(sess.ID, dbs)
	return &queravuev1.ListDatabasesResponse{Databases: dbs}, nil
}

// ListSchemas implements the RPC.
func (s *SchemaService) ListSchemas(ctx context.Context, req *queravuev1.ListSchemasRequest) (*queravuev1.ListSchemasResponse, error) {
	sess, inspector, err := s.getInspector(req.GetSessionId())
	if err != nil {
		return nil, err
	}

	if !req.GetRefresh() {
		if cached, ok := s.cache.GetSchemas(sess.ID, req.GetDatabase()); ok {
			return &queravuev1.ListSchemasResponse{Schemas: cached}, nil
		}
	}

	schemas, err := inspector.ListSchemas(ctx, req.GetDatabase())
	if err != nil {
		return nil, status.Errorf(codes.Internal, "list schemas: %v", err)
	}

	s.cache.SetSchemas(sess.ID, req.GetDatabase(), schemas)
	return &queravuev1.ListSchemasResponse{Schemas: schemas}, nil
}

// ListObjects implements the RPC.
func (s *SchemaService) ListObjects(ctx context.Context, req *queravuev1.ListObjectsRequest) (*queravuev1.ListObjectsResponse, error) {
	sess, inspector, err := s.getInspector(req.GetSessionId())
	if err != nil {
		return nil, err
	}

	if !req.GetRefresh() {
		if cached, ok := s.cache.GetObjects(sess.ID, req.GetDatabase(), req.GetSchema()); ok {
			return &queravuev1.ListObjectsResponse{Objects: toProtoObjects(cached)}, nil
		}
	}

	objs, err := inspector.ListObjects(ctx, req.GetDatabase(), req.GetSchema())
	if err != nil {
		return nil, status.Errorf(codes.Internal, "list objects: %v", err)
	}

	s.cache.SetObjects(sess.ID, req.GetDatabase(), req.GetSchema(), objs)
	return &queravuev1.ListObjectsResponse{Objects: toProtoObjects(objs)}, nil
}

// GetTableDetails implements the RPC.
func (s *SchemaService) GetTableDetails(ctx context.Context, req *queravuev1.GetTableDetailsRequest) (*queravuev1.GetTableDetailsResponse, error) {
	sess, inspector, err := s.getInspector(req.GetSessionId())
	if err != nil {
		return nil, err
	}

	ref := req.GetTableRef()
	if ref == nil || ref.GetTable() == "" {
		return nil, status.Error(codes.InvalidArgument, "table reference is required")
	}

	if !req.GetRefresh() {
		if cached, ok := s.cache.GetTableDetails(sess.ID, ref.GetDatabase(), ref.GetSchema(), ref.GetTable()); ok {
			return toProtoTableDetails(cached, ref), nil
		}
	}

	td, err := inspector.DescribeTable(ctx, ref.GetDatabase(), ref.GetSchema(), ref.GetTable())
	if err != nil {
		return nil, status.Errorf(codes.Internal, "describe table: %v", err)
	}

	s.cache.SetTableDetails(sess.ID, ref.GetDatabase(), ref.GetSchema(), ref.GetTable(), td)
	return toProtoTableDetails(td, ref), nil
}

// RefreshSchema implements the RPC.
func (s *SchemaService) RefreshSchema(_ context.Context, req *queravuev1.RefreshSchemaRequest) (*queravuev1.RefreshSchemaResponse, error) {
	s.cache.Invalidate(req.GetSessionId(), req.GetTableRef())
	return &queravuev1.RefreshSchemaResponse{}, nil
}

func toProtoObjects(objs []engine.SchemaObject) []*queravuev1.SchemaObject {
	out := make([]*queravuev1.SchemaObject, len(objs))
	for i, o := range objs {
		t := queravuev1.SchemaObjectType_SCHEMA_OBJECT_TYPE_TABLE
		switch o.Type {
		case engine.ObjectTypeView:
			t = queravuev1.SchemaObjectType_SCHEMA_OBJECT_TYPE_VIEW
		case engine.ObjectTypeMaterializedView:
			t = queravuev1.SchemaObjectType_SCHEMA_OBJECT_TYPE_MATERIALIZED_VIEW
		}
		out[i] = &queravuev1.SchemaObject{
			Name:             o.Name,
			Type:             t,
			RowCountEstimate: o.EstimatedRows,
		}
	}
	return out
}

func toProtoTableDetails(td engine.TableDetails, ref *queravuev1.TableRef) *queravuev1.GetTableDetailsResponse {
	t := queravuev1.SchemaObjectType_SCHEMA_OBJECT_TYPE_TABLE
	switch td.Type {
	case engine.ObjectTypeView:
		t = queravuev1.SchemaObjectType_SCHEMA_OBJECT_TYPE_VIEW
	case engine.ObjectTypeMaterializedView:
		t = queravuev1.SchemaObjectType_SCHEMA_OBJECT_TYPE_MATERIALIZED_VIEW
	}

	cols := make([]*queravuev1.ColumnDetails, len(td.Columns))
	for i, c := range td.Columns {
		cols[i] = &queravuev1.ColumnDetails{
			Name:            c.Name,
			TypeName:        c.TypeName,
			Kind:            results.KindToProto(c.Kind),
			Nullable:        c.Nullable,
			DefaultValue:    c.DefaultValue,
			IsPrimaryKey:    c.IsPrimaryKey,
			PrimaryKeyOrder: uint32(c.PrimaryKeyOrder), //nolint:gosec // order is non-negative
		}
	}

	indexes := make([]*queravuev1.IndexDetails, len(td.Indexes))
	for i, idx := range td.Indexes {
		indexes[i] = &queravuev1.IndexDetails{
			Name:      idx.Name,
			Columns:   idx.Columns,
			IsUnique:  idx.IsUnique,
			IsPrimary: idx.IsPrimary,
		}
	}

	fks := make([]*queravuev1.ForeignKeyDetails, len(td.ForeignKeys))
	for i, fk := range td.ForeignKeys {
		fks[i] = &queravuev1.ForeignKeyDetails{
			Name:              fk.Name,
			Columns:           fk.Columns,
			ReferencedSchema:  fk.ReferencedSchema,
			ReferencedTable:   fk.ReferencedTable,
			ReferencedColumns: fk.ReferencedColumns,
		}
	}

	return &queravuev1.GetTableDetailsResponse{
		TableRef:           ref,
		Type:               t,
		Columns:            cols,
		Indexes:            indexes,
		ForeignKeys:        fks,
		RowCountEstimate:   td.EstimatedRows,
		CanEdit:            td.CanEdit,
		EditDisabledReason: td.EditDisabledReason,
	}
}
