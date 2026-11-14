package netpath

import (
	"net"
	"os"
	"sync"
	"time"
)

// An ssh channel has no deadlines, but drivers set them for timeouts and to
// interrupt a blocked read. deadlineConn adds them: reads are pumped through a
// goroutine so a read can time out without losing data, and a write deadline
// that already passed fails the write.

const pumpChunk = 32 << 10

type chunk struct {
	data []byte
	err  error
}

type deadlineConn struct {
	net.Conn

	pumpOnce sync.Once
	chunks   chan chunk
	closed   chan struct{}
	closeMu  sync.Once

	readMu sync.Mutex
	left   []byte
	err    error

	readDL  deadline
	writeDL deadline
}

func newDeadlineConn(c net.Conn) *deadlineConn {
	return &deadlineConn{
		Conn: c, chunks: make(chan chunk), closed: make(chan struct{}),
		readDL: newDeadline(), writeDL: newDeadline(),
	}
}

func (c *deadlineConn) pump() {
	for {
		buf := make([]byte, pumpChunk)
		n, err := c.Conn.Read(buf)
		select {
		case c.chunks <- chunk{buf[:n], err}:
		case <-c.closed:
			return
		}
		if err != nil {
			return
		}
	}
}

func (c *deadlineConn) Read(p []byte) (int, error) {
	c.pumpOnce.Do(func() { go c.pump() })
	c.readMu.Lock()
	defer c.readMu.Unlock()
	for {
		if len(c.left) > 0 {
			n := copy(p, c.left)
			c.left = c.left[n:]
			return n, nil
		}
		if c.err != nil {
			return 0, c.err
		}
		select {
		case ch := <-c.chunks:
			c.left, c.err = ch.data, ch.err
		case <-c.readDL.wait():
			return 0, os.ErrDeadlineExceeded
		case <-c.closed:
			return 0, net.ErrClosed
		}
	}
}

func (c *deadlineConn) Write(p []byte) (int, error) {
	select {
	case <-c.writeDL.wait():
		return 0, os.ErrDeadlineExceeded
	default:
	}
	return c.Conn.Write(p)
}

func (c *deadlineConn) Close() error {
	c.closeMu.Do(func() { close(c.closed) })
	c.readDL.stop()
	c.writeDL.stop()
	return c.Conn.Close()
}

func (c *deadlineConn) SetDeadline(t time.Time) error {
	c.readDL.set(t)
	c.writeDL.set(t)
	return nil
}

func (c *deadlineConn) SetReadDeadline(t time.Time) error  { c.readDL.set(t); return nil }
func (c *deadlineConn) SetWriteDeadline(t time.Time) error { c.writeDL.set(t); return nil }

// deadline is a resettable timer that closes a channel when it fires, the way
// net.Pipe does it.
type deadline struct {
	mu     sync.Mutex
	timer  *time.Timer
	cancel chan struct{}
}

func newDeadline() deadline { return deadline{cancel: make(chan struct{})} }

func (d *deadline) set(t time.Time) {
	d.mu.Lock()
	defer d.mu.Unlock()
	if d.timer != nil && !d.timer.Stop() {
		<-d.cancel
	}
	d.timer = nil
	closed := isClosed(d.cancel)
	if t.IsZero() {
		if closed {
			d.cancel = make(chan struct{})
		}
		return
	}
	if dur := time.Until(t); dur > 0 {
		if closed {
			d.cancel = make(chan struct{})
		}
		cancel := d.cancel
		d.timer = time.AfterFunc(dur, func() { close(cancel) })
		return
	}
	if !closed {
		close(d.cancel)
	}
}

func (d *deadline) stop() {
	d.mu.Lock()
	defer d.mu.Unlock()
	if d.timer != nil && d.timer.Stop() {
		d.timer = nil
	}
}

func (d *deadline) wait() chan struct{} {
	d.mu.Lock()
	defer d.mu.Unlock()
	return d.cancel
}

func isClosed(c chan struct{}) bool {
	select {
	case <-c:
		return true
	default:
		return false
	}
}
