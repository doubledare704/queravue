package redis

import (
	"context"
	"crypto/tls"
	"fmt"
	"net"
	"strconv"
	"strings"
	"sync"

	goredis "github.com/redis/go-redis/v9"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/netpath"
)

type dialFunc func(ctx context.Context, network, addr string) (net.Conn, error)

type topology struct {
	mode       string
	addrs      []string
	masterName string
	username   string
	defaultDB  uint32
}

func newTopology(cfg engine.Config, id string) (topology, error) {
	t := topology{
		mode:       cfg.Param(ParamMode, ModeStandalone),
		masterName: cfg.Param(ParamMasterName, ""),
		username:   cfg.Param(ParamUsername, ""),
	}
	for _, h := range strings.Split(cfg.Param(ParamHosts, "localhost:6379"), ",") {
		if h = strings.TrimSpace(h); h != "" {
			t.addrs = append(t.addrs, withDefaultPort(h))
		}
	}
	db, err := strconv.ParseUint(cfg.Param(ParamDatabase, "0"), 10, 32)
	if err != nil {
		return t, engine.Errorf(engine.KindInvalidConfig, id, "config", "Database must be a non-negative number")
	}
	t.defaultDB = uint32(db)
	switch {
	case len(t.addrs) == 0:
		return t, engine.Errorf(engine.KindInvalidConfig, id, "config", "Hosts is required")
	case t.mode == ModeSentinel && t.masterName == "":
		return t, engine.Errorf(engine.KindInvalidConfig, id, "config", "Sentinel master name is required in Sentinel mode")
	case t.mode == ModeCluster && t.defaultDB != 0:
		return t, engine.Errorf(engine.KindInvalidConfig, id, "config", "Redis Cluster has database 0 only")
	case t.mode != ModeStandalone && t.mode != ModeSentinel && t.mode != ModeCluster:
		return t, engine.Errorf(engine.KindInvalidConfig, id, "config", "Unknown mode %q", t.mode)
	}
	return t, nil
}

func withDefaultPort(h string) string {
	if _, _, err := net.SplitHostPort(h); err == nil {
		return h
	}
	return net.JoinHostPort(strings.Trim(h, "[]"), "6379")
}

func (t topology) newClient(db uint32, password string, dial dialFunc) goredis.UniversalClient {
	switch t.mode {
	case ModeCluster:
		return goredis.NewClusterClient(&goredis.ClusterOptions{
			Addrs: t.addrs, Username: t.username, Password: password,
			Protocol: 3, Dialer: dial, DisableIdentity: true,
			DialTimeout: dialTimeout, ReadTimeout: ioTimeout, WriteTimeout: ioTimeout, PoolSize: poolSize,
		})
	case ModeSentinel:
		return goredis.NewFailoverClient(&goredis.FailoverOptions{
			MasterName: t.masterName, SentinelAddrs: t.addrs,
			Username: t.username, Password: password,
			SentinelUsername: t.username, SentinelPassword: password,
			DB: int(db), Protocol: 3, Dialer: dial, DisableIdentity: true,
			DialTimeout: dialTimeout, ReadTimeout: ioTimeout, WriteTimeout: ioTimeout, PoolSize: poolSize,
		})
	}
	return goredis.NewClient(&goredis.Options{
		Addr: t.addrs[0], Username: t.username, Password: password,
		DB: int(db), Protocol: 3, Dialer: dial, DisableIdentity: true,
		DialTimeout: dialTimeout, ReadTimeout: ioTimeout, WriteTimeout: ioTimeout, PoolSize: poolSize,
	})
}

// newDialer returns the one dialer every socket goes through: the session
// dialer if there is one, then TLS from the shared builder. go-redis applies
// TLSConfig only to its own dialer, so TLS is done here.
func newDialer(cfg engine.Config) (dialFunc, error) {
	settings := cfg.Net.TLS
	if !cfg.Net.HasTLSSettings() && cfg.Param(ParamTLS, "false") == "true" {
		settings = netpath.TLSSettings{Mode: netpath.TLSVerifyFull, CAFile: cfg.Param(ParamTLSCAFile, "")}
		if cfg.Param(ParamTLSInsecure, "false") == "true" {
			settings.Mode = netpath.TLSRequire
		}
	}
	raw := dialFunc(cfg.Net.Dial)
	if cfg.Net.Dial == nil {
		d := &net.Dialer{Timeout: dialTimeout}
		raw = d.DialContext
	}
	if !settings.Enabled() {
		return raw, nil
	}
	if _, err := settings.Build("probe"); err != nil {
		return nil, err
	}
	var mu sync.Mutex
	byHost := map[string]*tls.Config{}
	tlsFor := func(host string) (*tls.Config, error) {
		mu.Lock()
		defer mu.Unlock()
		if c, ok := byHost[host]; ok {
			return c, nil
		}
		c, err := settings.Build(host)
		if err == nil {
			byHost[host] = c
		}
		return c, err
	}
	return func(ctx context.Context, network, addr string) (net.Conn, error) {
		host, _, err := net.SplitHostPort(addr)
		if err != nil {
			host = addr
		}
		tlsCfg, err := tlsFor(host)
		if err != nil {
			return nil, err
		}
		conn, err := raw(ctx, network, addr)
		if err != nil {
			return nil, err
		}
		tc := tls.Client(conn, tlsCfg)
		if err := tc.HandshakeContext(ctx); err != nil {
			_ = conn.Close()
			if settings.FallbackToPlaintext() {
				return raw(ctx, network, addr)
			}
			return nil, fmt.Errorf("redis: tls handshake with %s: %w", addr, err)
		}
		return tc, nil
	}, nil
}
