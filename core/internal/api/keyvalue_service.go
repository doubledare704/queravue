package api

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/doubledare704/queravue/core/internal/connections"
	"github.com/doubledare704/queravue/core/internal/engine"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/rediscli"
	"github.com/doubledare704/queravue/core/internal/session"
)

// KeyValueService implements queravuev1.KeyValueServiceServer. Calls overlap
// on one session; the engine's client is safe for concurrent use.
type KeyValueService struct {
	queravuev1.UnimplementedKeyValueServiceServer

	sessions    *session.Manager
	connections *connections.Service
	log         *slog.Logger
}

// NewKeyValueService returns a KeyValueService handler. connections may be
// nil, in which case no connection counts as production.
func NewKeyValueService(s *session.Manager, c *connections.Service, log *slog.Logger) *KeyValueService {
	if log == nil {
		log = slog.Default()
	}
	return &KeyValueService{sessions: s, connections: c, log: log}
}

func (k *KeyValueService) store(sessionID string) (*session.Session, engine.KeyValueStore, error) {
	sess, err := k.sessions.Get(sessionID)
	if err != nil {
		return nil, nil, status.Error(codes.NotFound, "session not found")
	}
	kv, ok := engine.As[engine.KeyValueStore](sess.Conn)
	if !ok {
		return nil, nil, status.Error(codes.FailedPrecondition, "connection does not support key-value access")
	}
	sess.Touch()
	return sess, kv, nil
}

func (k *KeyValueService) production(ctx context.Context, sess *session.Session) bool {
	if k.connections == nil || sess.ConnectionID == "" {
		return false
	}
	c, err := k.connections.Get(ctx, sess.ConnectionID)
	return err == nil && c.Production
}

func confirmationRequired(operation string) *queravuev1.KeyValueError {
	return &queravuev1.KeyValueError{
		Kind:      queravuev1.KeyValueErrorKind_KEY_VALUE_ERROR_KIND_CONFIRMATION_REQUIRED,
		Message:   "This connection is flagged as production. Confirmation is required for: " + operation + ".",
		Operation: operation,
	}
}

func toKeyValueError(err error) *queravuev1.KeyValueError {
	var e *engine.Error
	if !errors.As(err, &e) {
		return &queravuev1.KeyValueError{Kind: queravuev1.KeyValueErrorKind_KEY_VALUE_ERROR_KIND_SERVER, Message: "operation failed"}
	}
	return &queravuev1.KeyValueError{Kind: keyValueErrorKind(e.Kind), Message: e.Msg}
}

func keyValueErrorKind(k engine.Kind) queravuev1.KeyValueErrorKind {
	switch k {
	case engine.KindConfirmationRequired:
		return queravuev1.KeyValueErrorKind_KEY_VALUE_ERROR_KIND_CONFIRMATION_REQUIRED
	case engine.KindUnsupported:
		return queravuev1.KeyValueErrorKind_KEY_VALUE_ERROR_KIND_UNSUPPORTED
	case engine.KindInvalidConfig, engine.KindParse:
		return queravuev1.KeyValueErrorKind_KEY_VALUE_ERROR_KIND_INVALID
	case engine.KindNotFound:
		return queravuev1.KeyValueErrorKind_KEY_VALUE_ERROR_KIND_NOT_FOUND
	case engine.KindCanceled:
		return queravuev1.KeyValueErrorKind_KEY_VALUE_ERROR_KIND_CANCELED
	case engine.KindKeysRefused:
		return queravuev1.KeyValueErrorKind_KEY_VALUE_ERROR_KIND_KEYS_REFUSED
	case engine.KindBlockingRefused:
		return queravuev1.KeyValueErrorKind_KEY_VALUE_ERROR_KIND_BLOCKING_REFUSED
	}
	return queravuev1.KeyValueErrorKind_KEY_VALUE_ERROR_KIND_SERVER
}

// ListKvDatabases implements the RPC.
func (k *KeyValueService) ListKvDatabases(ctx context.Context, req *queravuev1.ListKvDatabasesRequest) (*queravuev1.ListKvDatabasesResponse, error) {
	_, kv, err := k.store(req.GetSessionId())
	if err != nil {
		return nil, err
	}
	dbs, err := kv.ListDatabases(ctx)
	if err != nil {
		return &queravuev1.ListKvDatabasesResponse{Error: toKeyValueError(err)}, nil
	}
	resp := &queravuev1.ListKvDatabasesResponse{DatabaseLimit: dbs.DatabaseLimit}
	for _, d := range dbs.Databases {
		resp.Databases = append(resp.Databases, &queravuev1.KvDatabase{Index: d.Index, KeyCount: d.KeyCount, ExpiringCount: d.ExpiringCount})
	}
	return resp, nil
}

// ScanKeys implements the RPC.
func (k *KeyValueService) ScanKeys(req *queravuev1.ScanKeysRequest, stream queravuev1.KeyValueService_ScanKeysServer) error {
	sess, kv, err := k.store(req.GetSessionId())
	if err != nil {
		return err
	}
	defer sess.Hold()()
	var scanned uint64
	var sendErr error
	err = kv.ScanKeys(stream.Context(), engine.ScanOptions{
		Database: req.GetDatabase(), Pattern: req.GetPattern(),
		TypeFilter: engineKeyType(req.GetTypeFilter()), PageSize: int(req.GetPageSize()),
	}, func(p engine.ScanPage) error {
		scanned = p.Scanned
		msg := &queravuev1.ScanKeysResponse{Scanned: p.Scanned, Keys: make([]*queravuev1.KeySummary, len(p.Keys))}
		for i, key := range p.Keys {
			msg.Keys[i] = &queravuev1.KeySummary{Key: key.Key, Type: wireKeyType(key.Type), TtlMs: key.TTLMs}
		}
		if sendErr = stream.Send(msg); sendErr != nil {
			return fmt.Errorf("keyvalue: send: %w", sendErr)
		}
		return nil
	})
	if sendErr != nil {
		return sendErr
	}
	if err != nil {
		if stream.Context().Err() != nil {
			return status.FromContextError(stream.Context().Err()).Err()
		}
		return stream.Send(&queravuev1.ScanKeysResponse{Scanned: scanned, Error: toKeyValueError(err)})
	}
	return stream.Send(&queravuev1.ScanKeysResponse{Scanned: scanned, Done: true})
}

// GetKeyInfo implements the RPC.
func (k *KeyValueService) GetKeyInfo(ctx context.Context, req *queravuev1.GetKeyInfoRequest) (*queravuev1.GetKeyInfoResponse, error) {
	_, kv, err := k.store(req.GetSessionId())
	if err != nil {
		return nil, err
	}
	info, err := kv.KeyInfo(ctx, req.GetDatabase(), req.GetKey())
	if err != nil {
		return &queravuev1.GetKeyInfoResponse{Error: toKeyValueError(err)}, nil
	}
	return &queravuev1.GetKeyInfoResponse{
		Type: wireKeyType(info.Type), TtlMs: info.TTLMs, Encoding: info.Encoding,
		Length: info.Length, MemoryBytes: info.MemoryBytes, BigKey: info.BigKey,
	}, nil
}

// ReadValue implements the RPC.
func (k *KeyValueService) ReadValue(ctx context.Context, req *queravuev1.ReadValueRequest) (*queravuev1.ReadValueResponse, error) {
	_, kv, err := k.store(req.GetSessionId())
	if err != nil {
		return nil, err
	}
	page, err := kv.ReadValue(ctx, engine.ReadOptions{
		Database: req.GetDatabase(), Key: req.GetKey(), Cursor: req.GetCursor(),
		PageSize: int(req.GetPageSize()), MaxBytes: int(req.GetMaxBytes()),
		Reverse: req.GetReverse(), OrderByScore: req.GetOrderByScore(),
	})
	if err != nil {
		return &queravuev1.ReadValueResponse{Error: toKeyValueError(err)}, nil
	}
	return valuePageToWire(page), nil
}

// WriteValue implements the RPC.
func (k *KeyValueService) WriteValue(ctx context.Context, req *queravuev1.WriteValueRequest) (*queravuev1.WriteValueResponse, error) {
	_, kv, err := k.store(req.GetSessionId())
	if err != nil {
		return nil, err
	}
	op, ok := writeOpFromWire(req.GetOp())
	if !ok {
		return &queravuev1.WriteValueResponse{Error: &queravuev1.KeyValueError{
			Kind: queravuev1.KeyValueErrorKind_KEY_VALUE_ERROR_KIND_INVALID, Message: "the edit names no operation",
		}}, nil
	}
	if err := kv.WriteValue(ctx, req.GetDatabase(), req.GetKey(), op); err != nil {
		return &queravuev1.WriteValueResponse{Error: toKeyValueError(err)}, nil
	}
	return &queravuev1.WriteValueResponse{}, nil
}

// RenameKey implements the RPC.
func (k *KeyValueService) RenameKey(ctx context.Context, req *queravuev1.RenameKeyRequest) (*queravuev1.RenameKeyResponse, error) {
	_, kv, err := k.store(req.GetSessionId())
	if err != nil {
		return nil, err
	}
	if err := kv.RenameKey(ctx, req.GetDatabase(), req.GetKey(), req.GetNewKey(), req.GetOverwrite()); err != nil {
		return &queravuev1.RenameKeyResponse{Error: toKeyValueError(err)}, nil
	}
	return &queravuev1.RenameKeyResponse{}, nil
}

// SetExpiry implements the RPC.
func (k *KeyValueService) SetExpiry(ctx context.Context, req *queravuev1.SetExpiryRequest) (*queravuev1.SetExpiryResponse, error) {
	_, kv, err := k.store(req.GetSessionId())
	if err != nil {
		return nil, err
	}
	var ttl *time.Duration
	if req.TtlMs != nil {
		d := time.Duration(min(req.GetTtlMs(), uint64(1<<62/uint64(time.Millisecond)))) * time.Millisecond
		ttl = &d
	}
	if err := kv.SetExpiry(ctx, req.GetDatabase(), req.GetKey(), ttl); err != nil {
		return &queravuev1.SetExpiryResponse{Error: toKeyValueError(err)}, nil
	}
	return &queravuev1.SetExpiryResponse{}, nil
}

// DeleteKeys implements the RPC. Production connections need confirmed=true
// for more than one key.
func (k *KeyValueService) DeleteKeys(ctx context.Context, req *queravuev1.DeleteKeysRequest) (*queravuev1.DeleteKeysResponse, error) {
	sess, kv, err := k.store(req.GetSessionId())
	if err != nil {
		return nil, err
	}
	keys := req.GetKeys()
	if !req.GetConfirmed() && rediscli.DeleteNeedsConfirmation(len(keys)) && k.production(ctx, sess) {
		return &queravuev1.DeleteKeysResponse{Error: confirmationRequired(fmt.Sprintf("delete %d keys", len(keys)))}, nil
	}
	n, err := kv.DeleteKeys(ctx, req.GetDatabase(), keys)
	if err != nil {
		return &queravuev1.DeleteKeysResponse{Deleted: n, Error: toKeyValueError(err)}, nil
	}
	return &queravuev1.DeleteKeysResponse{Deleted: n}, nil
}

// ExecuteCommand implements the RPC. Production connections need
// confirmed=true for the commands of ADR 0020.
func (k *KeyValueService) ExecuteCommand(ctx context.Context, req *queravuev1.ExecuteCommandRequest) (*queravuev1.ExecuteCommandResponse, error) {
	sess, kv, err := k.store(req.GetSessionId())
	if err != nil {
		return nil, err
	}
	args := req.GetArgs()
	if op := rediscli.Inspect(args).ConfirmOperation; op != "" && !req.GetConfirmed() && k.production(ctx, sess) {
		return &queravuev1.ExecuteCommandResponse{Error: confirmationRequired(op)}, nil
	}
	started := time.Now()
	reply, err := kv.ExecuteCommand(ctx, req.GetDatabase(), args)
	if err != nil {
		return &queravuev1.ExecuteCommandResponse{Error: toKeyValueError(err)}, nil
	}
	elapsed := uint32(min(time.Since(started).Milliseconds(), 1<<31)) //nolint:gosec // clamped
	return &queravuev1.ExecuteCommandResponse{Reply: replyToWire(reply), ElapsedMs: elapsed}, nil
}

// Subscribe implements the RPC.
func (k *KeyValueService) Subscribe(req *queravuev1.SubscribeRequest, stream queravuev1.KeyValueService_SubscribeServer) error {
	sess, kv, err := k.store(req.GetSessionId())
	if err != nil {
		return err
	}
	defer sess.Hold()()
	var sendErr error
	err = kv.Subscribe(stream.Context(), req.GetChannels(), req.GetPatterns(), func(m engine.PubSubMessage) error {
		sendErr = stream.Send(&queravuev1.SubscribeResponse{
			Channel: m.Channel, Pattern: m.Pattern, Payload: m.Payload, ReceivedUnixMs: m.ReceivedAt.UnixMilli(),
		})
		if sendErr != nil {
			return fmt.Errorf("keyvalue: send: %w", sendErr)
		}
		return nil
	})
	switch {
	case sendErr != nil:
		return sendErr
	case stream.Context().Err() != nil:
		return nil
	case err != nil:
		return stream.Send(&queravuev1.SubscribeResponse{Error: toKeyValueError(err)})
	}
	return nil
}

// Publish implements the RPC.
func (k *KeyValueService) Publish(ctx context.Context, req *queravuev1.PublishRequest) (*queravuev1.PublishResponse, error) {
	_, kv, err := k.store(req.GetSessionId())
	if err != nil {
		return nil, err
	}
	n, err := kv.Publish(ctx, req.GetChannel(), req.GetPayload())
	if err != nil {
		return &queravuev1.PublishResponse{Error: toKeyValueError(err)}, nil
	}
	return &queravuev1.PublishResponse{Receivers: n}, nil
}
