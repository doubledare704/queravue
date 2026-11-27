package mysql

import (
	"context"
	"strings"
	"testing"

	drv "github.com/go-sql-driver/mysql"

	"github.com/doubledare704/queravue/core/internal/engine"
)

func TestStatementBudget(t *testing.T) {
	tests := []struct {
		maxPacket int64
		want      int
	}{
		{64 << 20, maxStatementBytes},
		{16 << 20, maxStatementBytes},
		{1 << 20, 512 << 10},
		{4 << 10, 2 << 10},
	}
	for _, tt := range tests {
		if got := statementBudget(tt.maxPacket); got != tt.want {
			t.Errorf("statementBudget(%d) = %d, want %d", tt.maxPacket, got, tt.want)
		}
	}
}

func TestChunkEndStaysUnderTheByteBudget(t *testing.T) {
	big := engine.Bytes(make([]byte, 400))
	rows := make([][]engine.Value, 10)
	for i := range rows {
		rows[i] = []engine.Value{engine.Int(int64(i)), big}
	}
	run := &loadRun{rowsPerStatement: 1000, statementBytes: 1000}
	if got := run.chunkEnd(rows, 0); got != 2 {
		t.Errorf("chunkEnd = %d, want 2 rows of ~418 bytes under 1000", got)
	}
	run.statementBytes = 10
	if got := run.chunkEnd(rows, 3); got != 4 {
		t.Errorf("a row over the budget must still travel alone, got end %d", got)
	}
}

func TestChunkEndStopsAtTheRowCap(t *testing.T) {
	rows := make([][]engine.Value, 50)
	for i := range rows {
		rows[i] = []engine.Value{engine.Int(int64(i))}
	}
	run := &loadRun{rowsPerStatement: 20, statementBytes: 1 << 20}
	if got := run.chunkEnd(rows, 0); got != 20 {
		t.Errorf("chunkEnd = %d, want 20", got)
	}
	if got := run.chunkEnd(rows, 40); got != 50 {
		t.Errorf("chunkEnd = %d, want 50", got)
	}
}

func TestLoadErrorMapping(t *testing.T) {
	c := &Conn{id: IDMySQL}
	tests := []struct {
		name string
		err  error
		want engine.Kind
	}{
		{"duplicate", &drv.MySQLError{Number: 1062, Message: "Duplicate entry 'secret-value' for key 't.PRIMARY'"}, engine.KindConstraint},
		{"not null", &drv.MySQLError{Number: 1048, Message: "Column 'x' cannot be null"}, engine.KindConstraint},
		{"foreign key", &drv.MySQLError{Number: 1452, Message: "Cannot add or update a child row"}, engine.KindConstraint},
		{"check", &drv.MySQLError{Number: 3819, Message: "Check constraint 'c' is violated."}, engine.KindConstraint},
		{"missing table", &drv.MySQLError{Number: 1146, Message: "Table 'd.t' doesn't exist"}, engine.KindNotFound},
		{"access denied", &drv.MySQLError{Number: 1044, Message: "Access denied"}, engine.KindAuth},
		{"bad value", &drv.MySQLError{Number: 1366, Message: "Incorrect integer value: 'secret-value' for column 'x'"}, engine.KindSQL},
		{"too large", drv.ErrPktTooLarge, engine.KindSQL},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := c.loadError(context.Background(), tt.err)
			if engine.KindOf(err) != tt.want {
				t.Fatalf("kind = %v, want %v (%v)", engine.KindOf(err), tt.want, err)
			}
			if strings.Contains(err.Error(), "secret-value") {
				t.Errorf("message quotes row data: %v", err)
			}
		})
	}
}

func TestDuplicateMessageNamesTheKey(t *testing.T) {
	err := (&Conn{id: IDMySQL}).loadError(context.Background(), &drv.MySQLError{Number: 1062, Message: "Duplicate entry '5' for key 't.PRIMARY'"})
	if !strings.Contains(err.Error(), "t.PRIMARY") {
		t.Errorf("message = %v", err)
	}
}

func TestLoadErrorWhenContextCancelled(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	err := (&Conn{id: IDMySQL}).loadError(ctx, &drv.MySQLError{Number: errQueryInterrupt, Message: "Query execution was interrupted"})
	if engine.KindOf(err) != engine.KindCanceled {
		t.Fatalf("kind = %v", engine.KindOf(err))
	}
}
