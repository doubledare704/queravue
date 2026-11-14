package netpath

import (
	"crypto/ed25519"
	"crypto/rand"
	"encoding/pem"
	"io"
	"net"
	"os"
	"path/filepath"
	"strconv"
	"sync"
	"testing"

	"golang.org/x/crypto/ssh"
)

const testPassword = "s3cret-test-pw"

type testSSHServer struct {
	t        *testing.T
	listener net.Listener
	hostKey  ssh.Signer
	userKey  ssh.PublicKey

	mu    sync.Mutex
	conns []net.Conn
	wg    sync.WaitGroup
}

func newSigner(t *testing.T) ssh.Signer {
	t.Helper()
	_, priv, err := ed25519.GenerateKey(rand.Reader)
	if err != nil {
		t.Fatal(err)
	}
	s, err := ssh.NewSignerFromKey(priv)
	if err != nil {
		t.Fatal(err)
	}
	return s
}

func startSSHServer(t *testing.T, hostKey ssh.Signer, userKey ssh.PublicKey) *testSSHServer {
	t.Helper()
	l, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	s := &testSSHServer{t: t, listener: l, hostKey: hostKey, userKey: userKey}
	cfg := &ssh.ServerConfig{
		PasswordCallback: func(_ ssh.ConnMetadata, pw []byte) (*ssh.Permissions, error) {
			if string(pw) == testPassword {
				return nil, nil
			}
			return nil, io.ErrUnexpectedEOF
		},
		PublicKeyCallback: func(_ ssh.ConnMetadata, key ssh.PublicKey) (*ssh.Permissions, error) {
			if s.userKey != nil && string(key.Marshal()) == string(s.userKey.Marshal()) {
				return nil, nil
			}
			return nil, io.ErrUnexpectedEOF
		},
	}
	cfg.AddHostKey(hostKey)
	s.wg.Add(1)
	go func() {
		defer s.wg.Done()
		for {
			c, err := l.Accept()
			if err != nil {
				return
			}
			s.mu.Lock()
			s.conns = append(s.conns, c)
			s.mu.Unlock()
			s.wg.Add(1)
			go func() {
				defer s.wg.Done()
				s.serve(c, cfg)
			}()
		}
	}()
	t.Cleanup(s.Close)
	return s
}

func (s *testSSHServer) Addr() (string, int) {
	a := s.listener.Addr().(*net.TCPAddr)
	return a.IP.String(), a.Port
}

func (s *testSSHServer) Close() {
	_ = s.listener.Close()
	s.DropConnections()
	s.wg.Wait()
}

func (s *testSSHServer) DropConnections() {
	s.mu.Lock()
	defer s.mu.Unlock()
	for _, c := range s.conns {
		_ = c.Close()
	}
	s.conns = nil
}

func (s *testSSHServer) serve(c net.Conn, cfg *ssh.ServerConfig) {
	sc, chans, reqs, err := ssh.NewServerConn(c, cfg)
	if err != nil {
		_ = c.Close()
		return
	}
	defer sc.Close()
	go func() {
		for r := range reqs {
			if r.WantReply {
				_ = r.Reply(true, nil)
			}
		}
	}()
	for nc := range chans {
		if nc.ChannelType() != "direct-tcpip" {
			_ = nc.Reject(ssh.UnknownChannelType, "only direct-tcpip")
			continue
		}
		var req struct {
			Host     string
			Port     uint32
			OrigHost string
			OrigPort uint32
		}
		if err := ssh.Unmarshal(nc.ExtraData(), &req); err != nil {
			_ = nc.Reject(ssh.ConnectionFailed, "bad request")
			continue
		}
		target, err := net.Dial("tcp", net.JoinHostPort(req.Host, strconv.Itoa(int(req.Port))))
		if err != nil {
			_ = nc.Reject(ssh.ConnectionFailed, err.Error())
			continue
		}
		ch, chReqs, err := nc.Accept()
		if err != nil {
			_ = target.Close()
			continue
		}
		go ssh.DiscardRequests(chReqs)
		go func() {
			defer ch.Close()
			defer target.Close()
			done := make(chan struct{}, 2)
			go func() { _, _ = io.Copy(ch, target); done <- struct{}{} }()
			go func() { _, _ = io.Copy(target, ch); done <- struct{}{} }()
			<-done
		}()
	}
}

func writeOpenSSHKey(t *testing.T, passphrase string) (path string, pub ssh.PublicKey) {
	t.Helper()
	pubKey, priv, err := ed25519.GenerateKey(rand.Reader)
	if err != nil {
		t.Fatal(err)
	}
	var block *pem.Block
	if passphrase == "" {
		block, err = ssh.MarshalPrivateKey(priv, "")
	} else {
		block, err = ssh.MarshalPrivateKeyWithPassphrase(priv, "", []byte(passphrase))
	}
	if err != nil {
		t.Fatal(err)
	}
	path = filepath.Join(t.TempDir(), "id_ed25519")
	if err := os.WriteFile(path, pem.EncodeToMemory(block), 0o600); err != nil {
		t.Fatal(err)
	}
	sshPub, err := ssh.NewPublicKey(pubKey)
	if err != nil {
		t.Fatal(err)
	}
	return path, sshPub
}
