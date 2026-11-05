package api

import (
	"context"
	"errors"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/timestamppb"

	"github.com/doubledare704/queravue/core/internal/connections"
	"github.com/doubledare704/queravue/core/internal/engine"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
)

// ConnectionService implements queravuev1.ConnectionServiceServer. It only
// maps between protobuf and the connections package.
type ConnectionService struct {
	queravuev1.UnimplementedConnectionServiceServer

	svc *connections.Service
}

// NewConnectionService returns a handler backed by svc.
func NewConnectionService(svc *connections.Service) *ConnectionService {
	return &ConnectionService{svc: svc}
}

// ListEngines implements the RPC.
func (h *ConnectionService) ListEngines(_ context.Context, _ *queravuev1.ListEnginesRequest) (*queravuev1.ListEnginesResponse, error) {
	ds := h.svc.Engines()
	out := make([]*queravuev1.EngineInfo, len(ds))
	for i, d := range ds {
		out[i] = engineToProto(d)
	}
	return &queravuev1.ListEnginesResponse{Engines: out}, nil
}

// ListConnections implements the RPC.
func (h *ConnectionService) ListConnections(ctx context.Context, _ *queravuev1.ListConnectionsRequest) (*queravuev1.ListConnectionsResponse, error) {
	cs, err := h.svc.List(ctx)
	if err != nil {
		return nil, grpcError(err)
	}
	out := make([]*queravuev1.Connection, len(cs))
	for i, c := range cs {
		out[i] = connToProto(c)
	}
	return &queravuev1.ListConnectionsResponse{Connections: out}, nil
}

// GetConnection implements the RPC.
func (h *ConnectionService) GetConnection(ctx context.Context, req *queravuev1.GetConnectionRequest) (*queravuev1.GetConnectionResponse, error) {
	c, err := h.svc.Get(ctx, req.GetId())
	if err != nil {
		return nil, grpcError(err)
	}
	return &queravuev1.GetConnectionResponse{Connection: connToProto(c)}, nil
}

// CreateConnection implements the RPC.
func (h *ConnectionService) CreateConnection(ctx context.Context, req *queravuev1.CreateConnectionRequest) (*queravuev1.CreateConnectionResponse, error) {
	c, err := h.svc.Create(ctx, connFromProto(req.GetConnection()), req.Password)
	if err != nil {
		return nil, grpcError(err)
	}
	return &queravuev1.CreateConnectionResponse{Connection: connToProto(c)}, nil
}

// UpdateConnection implements the RPC.
func (h *ConnectionService) UpdateConnection(ctx context.Context, req *queravuev1.UpdateConnectionRequest) (*queravuev1.UpdateConnectionResponse, error) {
	c, err := h.svc.Update(ctx, connFromProto(req.GetConnection()), req.Password, req.GetClearPassword())
	if err != nil {
		return nil, grpcError(err)
	}
	return &queravuev1.UpdateConnectionResponse{Connection: connToProto(c)}, nil
}

// DeleteConnection implements the RPC.
func (h *ConnectionService) DeleteConnection(ctx context.Context, req *queravuev1.DeleteConnectionRequest) (*queravuev1.DeleteConnectionResponse, error) {
	if err := h.svc.Delete(ctx, req.GetId()); err != nil {
		return nil, grpcError(err)
	}
	return &queravuev1.DeleteConnectionResponse{}, nil
}

// TestConnection implements the RPC.
func (h *ConnectionService) TestConnection(ctx context.Context, req *queravuev1.TestConnectionRequest) (*queravuev1.TestConnectionResponse, error) {
	tr := connections.TestRequest{
		ID:       req.GetId(),
		Password: req.Password,
		Timeout:  time.Duration(req.GetTimeoutMs()) * time.Millisecond,
	}
	if d := req.GetDraft(); d != nil {
		c := connFromProto(d)
		tr.Draft = &c
	}
	res, err := h.svc.Test(ctx, tr)
	if err != nil {
		return nil, grpcError(err)
	}
	resp := &queravuev1.TestConnectionResponse{
		Ok:        res.Err == nil,
		ConnectMs: millis(res.Connect),
		LatencyMs: millis(res.Latency),
	}
	if res.Err != nil {
		resp.Error = errorToProto(res.Err)
	} else {
		resp.Server = &queravuev1.ServerInfo{
			Product: res.Server.Product, Version: res.Server.Version, Banner: res.Server.Banner,
		}
	}
	return resp, nil
}

// ParseConnectionString implements the RPC.
func (h *ConnectionService) ParseConnectionString(_ context.Context, req *queravuev1.ParseConnectionStringRequest) (*queravuev1.ParseConnectionStringResponse, error) {
	params, sec, err := h.svc.ParseURI(req.GetEngineId(), req.GetConnectionString())
	if err != nil {
		return nil, grpcError(err)
	}
	resp := &queravuev1.ParseConnectionStringResponse{Params: params}
	if !sec.IsZero() {
		pw := sec.Reveal()
		resp.Password = &pw
	}
	return resp, nil
}

func millis(d time.Duration) uint32 {
	ms := d.Milliseconds()
	if ms <= 0 && d > 0 {
		return 1
	}
	return uint32(min(ms, 1<<31)) //nolint:gosec // bounded above
}

// grpcError maps domain errors to status codes. Messages come from typed
// errors that are already redacted.
func grpcError(err error) error {
	if errors.Is(err, connections.ErrNotFound) {
		return status.Error(codes.NotFound, "connection not found")
	}
	if errors.Is(err, context.Canceled) {
		return status.Error(codes.Canceled, "cancelled")
	}
	if errors.Is(err, context.DeadlineExceeded) {
		return status.Error(codes.DeadlineExceeded, "deadline exceeded")
	}
	var e *engine.Error
	if errors.As(err, &e) && e.Kind == engine.KindInvalidConfig {
		return status.Error(codes.InvalidArgument, e.Msg)
	}
	return status.Error(codes.Internal, err.Error())
}

func engineToProto(d engine.Descriptor) *queravuev1.EngineInfo {
	fields := make([]*queravuev1.FieldSpec, len(d.Fields))
	for i, f := range d.Fields {
		fields[i] = &queravuev1.FieldSpec{
			Key:          f.Key,
			Label:        f.Label,
			Kind:         queravuev1.FieldKind(f.Kind), //nolint:gosec // small enum
			Required:     f.Required,
			DefaultValue: f.Default,
			Placeholder:  f.Placeholder,
			Options:      f.Options,
		}
	}
	caps := make([]string, len(d.Capabilities))
	for i, c := range d.Capabilities {
		caps[i] = string(c)
	}
	return &queravuev1.EngineInfo{
		Id: d.ID, DisplayName: d.DisplayName, Family: d.Family,
		Fields: fields, SupportsUri: d.SupportsURI, Capabilities: caps, UriExample: d.URIExample,
	}
}

func connToProto(c connections.Connection) *queravuev1.Connection {
	return &queravuev1.Connection{
		Id:          c.ID,
		Name:        c.Name,
		EngineId:    c.EngineID,
		Params:      c.Params,
		Folder:      c.Folder,
		Color:       queravuev1.ColorTag(c.Color), //nolint:gosec // small enum
		Production:  c.Production,
		HasPassword: c.HasPassword(),
		CreatedAt:   timestamppb.New(c.CreatedAt),
		UpdatedAt:   timestamppb.New(c.UpdatedAt),
	}
}

func connFromProto(p *queravuev1.Connection) connections.Connection {
	return connections.Connection{
		ID:         p.GetId(),
		Name:       p.GetName(),
		EngineID:   p.GetEngineId(),
		Params:     p.GetParams(),
		Folder:     p.GetFolder(),
		Color:      connections.Color(p.GetColor()),
		Production: p.GetProduction(),
	}
}

func errorToProto(e *engine.Error) *queravuev1.ConnectionError {
	kinds := map[engine.Kind]queravuev1.ErrorKind{
		engine.KindAuth:          queravuev1.ErrorKind_ERROR_KIND_AUTH,
		engine.KindNetwork:       queravuev1.ErrorKind_ERROR_KIND_NETWORK,
		engine.KindTLS:           queravuev1.ErrorKind_ERROR_KIND_TLS,
		engine.KindNotFound:      queravuev1.ErrorKind_ERROR_KIND_NOT_FOUND,
		engine.KindTimeout:       queravuev1.ErrorKind_ERROR_KIND_TIMEOUT,
		engine.KindInvalidConfig: queravuev1.ErrorKind_ERROR_KIND_INVALID_CONFIG,
	}
	return &queravuev1.ConnectionError{Kind: kinds[e.Kind], Message: e.Msg}
}
