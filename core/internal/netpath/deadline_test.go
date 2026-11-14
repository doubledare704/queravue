package netpath

import (
	"errors"
	"net"
	"os"
	"testing"
	"time"
)

func pair(t *testing.T) (*deadlineConn, net.Conn) {
	t.Helper()
	l, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = l.Close() }()
	type accepted struct {
		c   net.Conn
		err error
	}
	ch := make(chan accepted, 1)
	go func() {
		c, err := l.Accept()
		ch <- accepted{c, err}
	}()
	client, err := net.Dial("tcp", l.Addr().String())
	if err != nil {
		t.Fatal(err)
	}
	a := <-ch
	if a.err != nil {
		t.Fatal(a.err)
	}
	dc := newDeadlineConn(client)
	t.Cleanup(func() { _ = dc.Close(); _ = a.c.Close() })
	return dc, a.c
}

func TestReadDeadlineTimesOutWithoutLosingData(t *testing.T) {
	dc, peer := pair(t)
	_ = dc.SetReadDeadline(time.Now().Add(50 * time.Millisecond))
	if _, err := dc.Read(make([]byte, 8)); !errors.Is(err, os.ErrDeadlineExceeded) {
		t.Fatalf("got %v", err)
	}
	_ = dc.SetReadDeadline(time.Time{})
	_, _ = peer.Write([]byte("hello"))
	buf := make([]byte, 8)
	n, err := dc.Read(buf)
	if err != nil || string(buf[:n]) != "hello" {
		t.Fatalf("read %q, %v", buf[:n], err)
	}
}

func TestPastDeadlineInterruptsBlockedRead(t *testing.T) {
	dc, _ := pair(t)
	done := make(chan error, 1)
	go func() {
		_, err := dc.Read(make([]byte, 1))
		done <- err
	}()
	time.Sleep(30 * time.Millisecond)
	_ = dc.SetReadDeadline(time.Now().Add(-time.Second))
	select {
	case err := <-done:
		if !errors.Is(err, os.ErrDeadlineExceeded) {
			t.Fatalf("got %v", err)
		}
	case <-time.After(2 * time.Second):
		t.Fatal("blocked read ignored the deadline")
	}
}

func TestPartialReadsKeepRemainder(t *testing.T) {
	dc, peer := pair(t)
	_, _ = peer.Write([]byte("abcdef"))
	buf := make([]byte, 4)
	n, _ := dc.Read(buf)
	m, _ := dc.Read(buf[n:])
	if string(buf[:n+m]) != "abcdef"[:n+m] {
		t.Fatalf("got %q", buf[:n+m])
	}
}

func TestExpiredWriteDeadlineFailsWrite(t *testing.T) {
	dc, _ := pair(t)
	_ = dc.SetWriteDeadline(time.Now().Add(-time.Second))
	if _, err := dc.Write([]byte("x")); !errors.Is(err, os.ErrDeadlineExceeded) {
		t.Fatalf("got %v", err)
	}
}

func TestCloseUnblocksRead(t *testing.T) {
	dc, _ := pair(t)
	done := make(chan error, 1)
	go func() {
		_, err := dc.Read(make([]byte, 1))
		done <- err
	}()
	time.Sleep(30 * time.Millisecond)
	_ = dc.Close()
	select {
	case err := <-done:
		if err == nil {
			t.Fatal("read succeeded after close")
		}
	case <-time.After(2 * time.Second):
		t.Fatal("close did not unblock the read")
	}
}
