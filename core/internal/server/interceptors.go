package server

import (
	"context"
	"crypto/subtle"
	"fmt"
	"log/slog"
	"runtime/debug"
	"strings"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"
)

const authHeader = "authorization"

// checkToken verifies the "authorization: Bearer <token>" metadata entry in
// constant time.
func checkToken(ctx context.Context, want []byte) error {
	md, ok := metadata.FromIncomingContext(ctx)
	if !ok {
		return status.Error(codes.Unauthenticated, "missing metadata")
	}
	vals := md.Get(authHeader)
	if len(vals) != 1 {
		return status.Error(codes.Unauthenticated, "missing token")
	}
	got, ok := strings.CutPrefix(vals[0], "Bearer ")
	if !ok || subtle.ConstantTimeCompare([]byte(got), want) != 1 {
		return status.Error(codes.Unauthenticated, "invalid token")
	}
	return nil
}

func authUnary(token []byte) grpc.UnaryServerInterceptor {
	return func(ctx context.Context, req any, _ *grpc.UnaryServerInfo, h grpc.UnaryHandler) (any, error) {
		if err := checkToken(ctx, token); err != nil {
			return nil, err
		}
		return h(ctx, req)
	}
}

func authStream(token []byte) grpc.StreamServerInterceptor {
	return func(srv any, ss grpc.ServerStream, _ *grpc.StreamServerInfo, h grpc.StreamHandler) error {
		if err := checkToken(ss.Context(), token); err != nil {
			return err
		}
		return h(srv, ss)
	}
}

// recoverUnary turns handler panics into codes.Internal so the core never
// crashes on a bug in a single request.
func recoverUnary(log *slog.Logger) grpc.UnaryServerInterceptor {
	return func(ctx context.Context, req any, info *grpc.UnaryServerInfo, h grpc.UnaryHandler) (resp any, err error) {
		defer func() {
			if r := recover(); r != nil {
				err = panicError(log, info.FullMethod, r)
			}
		}()
		return h(ctx, req)
	}
}

func recoverStream(log *slog.Logger) grpc.StreamServerInterceptor {
	return func(srv any, ss grpc.ServerStream, info *grpc.StreamServerInfo, h grpc.StreamHandler) (err error) {
		defer func() {
			if r := recover(); r != nil {
				err = panicError(log, info.FullMethod, r)
			}
		}()
		return h(srv, ss)
	}
}

func panicError(log *slog.Logger, method string, r any) error {
	log.Error("panic in handler", "method", method, "panic", fmt.Sprint(r), "stack", string(debug.Stack()))
	return status.Error(codes.Internal, "internal error")
}

// logUnary/logStream record method, status code and duration. They never log
// request payloads or metadata (which carries the token).
func logUnary(log *slog.Logger) grpc.UnaryServerInterceptor {
	return func(ctx context.Context, req any, info *grpc.UnaryServerInfo, h grpc.UnaryHandler) (any, error) {
		start := time.Now()
		resp, err := h(ctx, req)
		logCall(log, info.FullMethod, start, err)
		return resp, err
	}
}

func logStream(log *slog.Logger) grpc.StreamServerInterceptor {
	return func(srv any, ss grpc.ServerStream, info *grpc.StreamServerInfo, h grpc.StreamHandler) error {
		start := time.Now()
		err := h(srv, ss)
		logCall(log, info.FullMethod, start, err)
		return err
	}
}

func logCall(log *slog.Logger, method string, start time.Time, err error) {
	code := status.Code(err)
	level := slog.LevelDebug
	if code != codes.OK && code != codes.Canceled {
		level = slog.LevelWarn
	}
	log.Log(context.Background(), level, "rpc", "method", method, "code", code.String(), "duration", time.Since(start))
}
