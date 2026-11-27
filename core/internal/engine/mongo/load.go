package mongo

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"regexp"
	"runtime"
	"runtime/debug"
	"sync"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"

	"github.com/doubledare704/queravue/core/internal/engine"
)

var _ engine.DocumentLoader = (*Conn)(nil)

const (
	loadDocumentsOperation = "load documents"
	insertChunkBytes       = 2 << 20
	maxParseWorkers        = 4
	minDocsPerWorker       = 256
)

// Server codes of write errors that are constraint violations.
const (
	codeDuplicateKey       = 11000
	codeDuplicateKeyUpdate = 11001
	codeDuplicateKeyCapped = 12582
	codeDocumentValidation = 121
)

// LoadDocuments implements engine.DocumentLoader. Each source batch is parsed
// first, so a malformed document commits nothing from its batch, then inserted
// with unordered InsertMany calls of about insertChunkBytes of BSON. A server
// rejection (duplicate key, validator) does not stop the other documents of
// that call, and the stats count what was inserted.
func (c *Conn) LoadDocuments(ctx context.Context, database, collection string, src engine.DocumentBatchSource) (engine.LoadStats, error) {
	coll, err := c.coll(loadDocumentsOperation, database, collection)
	if err != nil {
		return engine.LoadStats{}, err
	}
	commit := func(ctx context.Context, docs []engine.Document) (engine.LoadStats, error) {
		return c.insertBatch(ctx, coll, docs)
	}
	return engine.DriveLoad(ctx, c.id, loadDocumentsOperation, src.Next, func(docs []engine.Document) int { return len(docs) }, commit)
}

func (c *Conn) insertBatch(ctx context.Context, coll *mongo.Collection, docs []engine.Document) (engine.LoadStats, error) {
	parsed, failedAt, err := parseBatch(docs)
	if err != nil {
		return engine.LoadStats{}, c.loadParseError(err, failedAt)
	}
	var stats engine.LoadStats
	for start := 0; start < len(parsed); {
		end := chunkEnd(parsed, start)
		chunk := make([]any, end-start)
		for i, raw := range parsed[start:end] {
			chunk[i] = raw
		}
		res, err := coll.InsertMany(ctx, chunk, options.InsertMany().SetOrdered(false))
		if res != nil {
			stats.Rows += uint64(len(res.InsertedIDs))
		}
		if err != nil {
			return stats, c.loadError(ctx, err)
		}
		stats.Batches++
		start = end
	}
	return stats, nil
}

// parseBatch parses docs on a few goroutines, because EJSON parsing costs
// about as much as the insert. On failure it returns the lowest failing index.
func parseBatch(docs []engine.Document) (parsed []bson.Raw, failedAt int, err error) {
	parsed = make([]bson.Raw, len(docs))
	workers := min(runtime.GOMAXPROCS(0), maxParseWorkers, (len(docs)+minDocsPerWorker-1)/minDocsPerWorker)
	if workers <= 1 {
		failedAt, err = parseRange(docs, parsed, 0, len(docs))
		return parsed, failedAt, err
	}
	type failure struct {
		index int
		err   error
	}
	failures := make([]failure, workers)
	var wg sync.WaitGroup
	per := (len(docs) + workers - 1) / workers
	for w := range workers {
		from, to := w*per, min((w+1)*per, len(docs))
		wg.Add(1)
		go func() {
			defer wg.Done()
			i, e := parseRange(docs, parsed, from, to)
			failures[w] = failure{i, e}
		}()
	}
	wg.Wait()
	for _, f := range failures {
		if f.err != nil {
			return parsed, f.index, f.err
		}
	}
	return parsed, 0, nil
}

func parseRange(docs []engine.Document, out []bson.Raw, from, to int) (failedAt int, err error) {
	i := from
	defer func() {
		if r := recover(); r != nil {
			slog.Error("mongo: parse panic", "panic", fmt.Sprint(r), "stack", string(debug.Stack()))
			failedAt, err = i, errors.New("internal error while parsing")
		}
	}()
	for ; i < to; i++ {
		raw, perr := parseDocument(docs[i], true, engine.InputDocument)
		if perr != nil {
			return i, perr
		}
		out[i] = raw
	}
	return 0, nil
}

func chunkEnd(docs []bson.Raw, start int) int {
	size, end := 0, start
	for end < len(docs) {
		if end > start && size+len(docs[end]) > insertChunkBytes {
			break
		}
		size += len(docs[end])
		end++
	}
	return end
}

// loadParseError keeps where the problem is but drops the parser's message,
// which quotes the offending text.
func (c *Conn) loadParseError(err error, index int) error {
	e := &engine.Error{Kind: engine.KindParse, Engine: c.id, Op: loadDocumentsOperation, Input: engine.InputDocument, Msg: "document is not valid canonical Extended JSON", Err: err}
	var typed *engine.Error
	if errors.As(err, &typed) {
		e.Position = typed.Position
	}
	e.DocumentIndex, e.HasIndex = index, true
	return e
}

var dupIndexRe = regexp.MustCompile(`index: (\S+)`)

// loadError classifies a failed insert. Messages name indexes and codes but
// never the rejected documents, which server messages often quote.
func (c *Conn) loadError(ctx context.Context, err error) error {
	if ctx.Err() != nil {
		return engine.LoadCanceled(ctx, c.id, loadDocumentsOperation)
	}
	if rejected, ok := writeErrors(err); ok {
		return c.writeRejection(err, rejected)
	}
	classified := classify(loadDocumentsOperation, err, c.secret)
	classified.Engine = c.id
	var cmd mongo.CommandError
	if errors.As(err, &cmd) && classified.Kind == engine.KindServer {
		classified.Msg = fmt.Sprintf("the server rejected the insert (code %d)", cmd.Code)
	}
	return classified
}

func writeErrors(err error) ([]mongo.WriteError, bool) {
	var bulk mongo.BulkWriteException
	if errors.As(err, &bulk) && len(bulk.WriteErrors) > 0 {
		out := make([]mongo.WriteError, len(bulk.WriteErrors))
		for i, we := range bulk.WriteErrors {
			out[i] = we.WriteError
		}
		return out, true
	}
	var write mongo.WriteException
	if errors.As(err, &write) && len(write.WriteErrors) > 0 {
		return write.WriteErrors, true
	}
	return nil, false
}

func (c *Conn) writeRejection(err error, rejected []mongo.WriteError) error {
	first := rejected[0]
	e := &engine.Error{Engine: c.id, Op: loadDocumentsOperation, Err: err, Code: first.Code}
	switch first.Code {
	case codeDuplicateKey, codeDuplicateKeyUpdate, codeDuplicateKeyCapped:
		e.Kind, e.Msg = engine.KindConstraint, "duplicate key violates a unique index"
		if m := dupIndexRe.FindStringSubmatch(first.Message); m != nil {
			e.Msg = "duplicate key violates unique index " + m[1]
		}
	case codeDocumentValidation:
		e.Kind, e.Msg = engine.KindConstraint, "document failed the collection validator"
	default:
		e.Kind, e.Msg = engine.KindServer, fmt.Sprintf("the server rejected %d document(s) (code %d)", len(rejected), first.Code)
	}
	return e
}
