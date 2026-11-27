package mongo

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"testing"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"

	"github.com/doubledare704/queravue/core/internal/engine"
)

func TestParseBatchReportsTheLowestFailingIndex(t *testing.T) {
	docs := make([]engine.Document, 1000)
	for i := range docs {
		docs[i] = fmt.Sprintf(`{"_id":{"$numberInt":"%d"}}`, i)
	}
	docs[300], docs[900] = `{"_id": 1}`, `{"_id": 2}`
	_, failedAt, err := parseBatch(docs)
	if err == nil || failedAt != 300 {
		t.Fatalf("failedAt = %d, err = %v", failedAt, err)
	}
}

func TestParseBatchKeepsOrder(t *testing.T) {
	docs := make([]engine.Document, 1000)
	for i := range docs {
		docs[i] = fmt.Sprintf(`{"_id":{"$numberInt":"%d"}}`, i)
	}
	parsed, _, err := parseBatch(docs)
	if err != nil {
		t.Fatal(err)
	}
	for i, raw := range parsed {
		if id, _ := raw.Lookup("_id").Int32OK(); int(id) != i {
			t.Fatalf("document %d has _id %d", i, id)
		}
	}
}

func TestLoadParseErrorDropsTheParserMessage(t *testing.T) {
	_, _, err := parseBatch([]engine.Document{`{"secret": 12345}`})
	got := (&Conn{id: ID}).loadParseError(err, 7)
	var e *engine.Error
	if !errors.As(got, &e) || e.Kind != engine.KindParse || !e.HasIndex || e.DocumentIndex != 7 {
		t.Fatalf("err = %#v", got)
	}
	if strings.Contains(got.Error(), "12345") {
		t.Errorf("message quotes the document: %v", got)
	}
}

func TestChunkEndSplitsAtTheByteTarget(t *testing.T) {
	big := make(bson.Raw, insertChunkBytes/2+1)
	docs := []bson.Raw{big, big, big, big, big}
	if got := chunkEnd(docs, 0); got != 1 {
		t.Errorf("chunkEnd = %d, want 1: two such documents exceed the target", got)
	}
	small := []bson.Raw{{5, 0, 0, 0, 0}, {5, 0, 0, 0, 0}}
	if got := chunkEnd(small, 0); got != 2 {
		t.Errorf("chunkEnd = %d, want 2", got)
	}
}

func TestLoadErrorMapsWriteRejections(t *testing.T) {
	c := &Conn{id: ID}
	bulk := func(code int, msg string) error {
		return mongo.BulkWriteException{WriteErrors: []mongo.BulkWriteError{{WriteError: mongo.WriteError{Code: code, Message: msg}}}}
	}
	tests := []struct {
		name    string
		err     error
		want    engine.Kind
		mention string
	}{
		{"duplicate", bulk(11000, "E11000 duplicate key error collection: d.c index: _id_ dup key: { _id: secret-value }"), engine.KindConstraint, "_id_"},
		{"validator", bulk(121, "Document failed validation"), engine.KindConstraint, "validator"},
		{"other", bulk(2, "bad value secret-value"), engine.KindServer, "code 2"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := c.loadError(context.Background(), tt.err)
			if engine.KindOf(err) != tt.want || !strings.Contains(err.Error(), tt.mention) {
				t.Fatalf("err = %v (kind %v)", err, engine.KindOf(err))
			}
			if strings.Contains(err.Error(), "secret-value") {
				t.Errorf("message quotes document data: %v", err)
			}
		})
	}
}

func TestLoadErrorWhenContextCancelled(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	if got := (&Conn{id: ID}).loadError(ctx, context.Canceled); engine.KindOf(got) != engine.KindCanceled {
		t.Fatalf("kind = %v", engine.KindOf(got))
	}
}
