package mongo

import (
	"context"
	"fmt"
	"time"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"

	"github.com/doubledare704/queravue/core/internal/engine"
)

var _ engine.ShellBackend = (*Conn)(nil)

// RunCommand implements engine.ShellBackend.
func (c *Conn) RunCommand(ctx context.Context, database string, command engine.Document) (engine.Document, error) {
	cl, err := c.live("run command")
	if err != nil {
		return "", err
	}
	if database == "" {
		database = c.defaultDB
	}
	if database == "" {
		database = "admin"
	}
	cmd, err := parseDocument(command, true, engine.InputDocument)
	if err != nil {
		return "", c.parseErr(err)
	}
	raw, err := cl.Database(database).RunCommand(ctx, cmd).Raw()
	if err != nil {
		return "", c.fail("run command", err)
	}
	out, err := toEJSON(raw)
	if err != nil {
		return "", relabel(&engine.Error{Kind: engine.KindServer, Op: "run command", Msg: err.Error(), Err: err}, c.id)
	}
	return out, nil
}

// OpenCursor implements engine.ShellBackend.
func (c *Conn) OpenCursor(ctx context.Context, spec engine.CursorSpec) (engine.DocCursor, error) {
	coll, err := c.coll("cursor", spec.Database, spec.Collection)
	if err != nil {
		return nil, err
	}
	cctx, cancel := withTimeout(ctx, spec.MaxTimeMS)
	var cur *mongo.Cursor
	if spec.Kind == engine.CursorAggregate {
		cur, err = c.aggregate(cctx, coll, spec)
	} else {
		cur, err = c.find(cctx, coll, spec)
	}
	if err != nil {
		cancel()
		return nil, err
	}
	return &docCursor{conn: c, cur: cur, cancel: cancel}, nil
}

func (c *Conn) find(ctx context.Context, coll *mongo.Collection, spec engine.CursorSpec) (*mongo.Cursor, error) {
	filter, err := optionalDoc(spec.Filter, engine.InputFilter)
	if err != nil {
		return nil, c.parseErr(err)
	}
	if filter == nil {
		filter = bson.Raw{5, 0, 0, 0, 0}
	}
	fo := options.Find()
	for _, f := range []struct {
		text  string
		in    engine.Input
		apply func(any)
	}{
		{spec.Sort, engine.InputSort, func(v any) { fo.SetSort(v) }},
		{spec.Projection, engine.InputProjection, func(v any) { fo.SetProjection(v) }},
		{spec.Hint, engine.InputDocument, func(v any) { fo.SetHint(v) }},
	} {
		doc, err := optionalDoc(f.text, f.in)
		if err != nil {
			return nil, c.parseErr(err)
		}
		if doc != nil {
			f.apply(doc)
		}
	}
	if spec.BatchSize > 0 {
		fo.SetBatchSize(int32(min(spec.BatchSize, 5000)))
	}
	if spec.Skip > 0 {
		fo.SetSkip(int64(spec.Skip)) //nolint:gosec // bounded by the int64 range of the server
	}
	if spec.Limit > 0 {
		fo.SetLimit(int64(spec.Limit)) //nolint:gosec // bounded by the int64 range of the server
	}
	cur, err := coll.Find(ctx, filter, fo)
	if err != nil {
		return nil, c.fail("find", err)
	}
	return cur, nil
}

func (c *Conn) aggregate(ctx context.Context, coll *mongo.Collection, spec engine.CursorSpec) (*mongo.Cursor, error) {
	var wrapped struct {
		V []bson.D `bson:"v"`
	}
	text := `{"v":` + spec.Pipeline + `}`
	if err := checkSyntax(text, engine.InputDocument); err != nil {
		return nil, c.parseErr(err)
	}
	if err := bson.UnmarshalExtJSON([]byte(text), true, &wrapped); err != nil {
		return nil, c.parseErr(&engine.Error{Kind: engine.KindParse, Engine: ID, Op: "parse", Input: engine.InputDocument, Msg: err.Error(), Err: err})
	}
	pipeline := wrapped.V
	if spec.Skip > 0 {
		pipeline = append(pipeline, bson.D{{Key: "$skip", Value: int64(spec.Skip)}}) //nolint:gosec // bounded by the int64 range of the server
	}
	if spec.Limit > 0 {
		pipeline = append(pipeline, bson.D{{Key: "$limit", Value: int64(spec.Limit)}}) //nolint:gosec // bounded by the int64 range of the server
	}
	ao := options.Aggregate()
	if spec.BatchSize > 0 {
		ao.SetBatchSize(int32(min(spec.BatchSize, 5000)))
	}
	if doc, err := optionalDoc(spec.Hint, engine.InputDocument); err != nil {
		return nil, c.parseErr(err)
	} else if doc != nil {
		ao.SetHint(doc)
	}
	cur, err := coll.Aggregate(ctx, pipeline, ao)
	if err != nil {
		return nil, c.fail("aggregate", err)
	}
	return cur, nil
}

type docCursor struct {
	conn   *Conn
	cur    *mongo.Cursor
	cancel context.CancelFunc
}

func (d *docCursor) Next(ctx context.Context) (engine.Document, bool, error) {
	if !d.cur.Next(ctx) {
		if err := d.cur.Err(); err != nil {
			return "", false, d.conn.fail("next", err)
		}
		return "", false, nil
	}
	text, err := toEJSON(d.cur.Current)
	if err != nil {
		return "", false, relabel(&engine.Error{Kind: engine.KindServer, Op: "next", Msg: err.Error(), Err: err}, d.conn.id)
	}
	return text, true, nil
}

func (d *docCursor) Close() error {
	defer d.cancel()
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()
	if err := d.cur.Close(ctx); err != nil {
		return fmt.Errorf("%s: close cursor: %w", d.conn.id, err)
	}
	return nil
}
