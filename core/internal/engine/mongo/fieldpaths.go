package mongo

import (
	"context"
	"sort"
	"strings"
	"time"

	"go.mongodb.org/mongo-driver/v2/bson"

	"github.com/doubledare704/queravue/core/internal/engine"
)

const (
	defaultPathDepth = 6
	maxPathDepth     = 12
	defaultMaxPaths  = 2000
)

// SampleFieldPaths implements engine.DocumentStore.
func (c *Conn) SampleFieldPaths(ctx context.Context, db, collection string, opts engine.PathSampleOptions) (engine.FieldPathSample, error) {
	coll, err := c.coll("sample", db, collection)
	if err != nil {
		return engine.FieldPathSample{}, err
	}
	ctx, cancel := context.WithTimeout(ctx, 15*time.Second)
	defer cancel()
	cur, fallback, err := c.openSample(ctx, coll, opts.SampleSize)
	if err != nil {
		return engine.FieldPathSample{}, err
	}
	defer closeCursor(cur)

	pc := newPathCollector(opts)
	for cur.Next(ctx) {
		pc.addDocument(cur.Current)
	}
	if err := cur.Err(); err != nil {
		return engine.FieldPathSample{}, c.fail("sample", err)
	}
	out := pc.result()
	out.UsedFallback = fallback
	return out, nil
}

type pathAccumulator struct {
	docs  uint32
	types map[string]uint32
}

type pathCollector struct {
	maxDepth  int
	maxPaths  int
	paths     map[string]*pathAccumulator
	sampled   uint32
	truncated bool
}

func newPathCollector(opts engine.PathSampleOptions) *pathCollector {
	depth := opts.MaxDepth
	if depth <= 0 {
		depth = defaultPathDepth
	}
	paths := opts.MaxPaths
	if paths <= 0 {
		paths = defaultMaxPaths
	}
	return &pathCollector{maxDepth: min(depth, maxPathDepth), maxPaths: paths, paths: map[string]*pathAccumulator{}}
}

func (pc *pathCollector) addDocument(doc bson.Raw) {
	pc.sampled++
	pc.walkDocument(doc, "", 1, map[string]bool{})
}

func (pc *pathCollector) walkDocument(doc bson.Raw, prefix string, depth int, seen map[string]bool) {
	elems, err := doc.Elements()
	if err != nil {
		return
	}
	for _, e := range elems {
		pc.visit(prefix+e.Key(), e.Value(), depth, seen)
	}
}

func (pc *pathCollector) walkArray(arr bson.RawArray, prefix string, depth int, seen map[string]bool) {
	values, err := arr.Values()
	if err != nil {
		return
	}
	for _, v := range values {
		pc.visit(prefix+".[]", v, depth, seen)
	}
}

func (pc *pathCollector) visit(path string, v bson.RawValue, depth int, seen map[string]bool) {
	if !pc.record(path, v.Type, seen) {
		return
	}
	if depth >= pc.maxDepth {
		return
	}
	switch v.Type {
	case bson.TypeEmbeddedDocument:
		pc.walkDocument(v.Document(), path+".", depth+1, seen)
	case bson.TypeArray:
		pc.walkArray(v.Array(), path, depth+1, seen)
	}
}

func (pc *pathCollector) record(path string, t bson.Type, seen map[string]bool) bool {
	a := pc.paths[path]
	if a == nil {
		if len(pc.paths) >= pc.maxPaths {
			pc.truncated = true
			return false
		}
		a = &pathAccumulator{types: map[string]uint32{}}
		pc.paths[path] = a
	}
	if !seen[path] {
		seen[path] = true
		a.docs++
	}
	a.types[typeAlias(t)]++
	return true
}

func (pc *pathCollector) result() engine.FieldPathSample {
	out := engine.FieldPathSample{Sampled: pc.sampled, Truncated: pc.truncated}
	for path, a := range pc.paths {
		stat := engine.FieldPathStat{
			Path: path, Frequency: float64(a.docs) / float64(max(pc.sampled, 1)), Depth: strings.Count(path, ".") + 1,
		}
		for t, n := range a.types {
			stat.Types = append(stat.Types, engine.FieldType{Type: t, Count: n})
		}
		sort.Slice(stat.Types, func(i, j int) bool {
			if stat.Types[i].Count != stat.Types[j].Count {
				return stat.Types[i].Count > stat.Types[j].Count
			}
			return stat.Types[i].Type < stat.Types[j].Type
		})
		out.Paths = append(out.Paths, stat)
	}
	sort.Slice(out.Paths, func(i, j int) bool {
		a, b := out.Paths[i], out.Paths[j]
		if (a.Path == "_id") != (b.Path == "_id") {
			return a.Path == "_id"
		}
		if a.Frequency != b.Frequency {
			return a.Frequency > b.Frequency
		}
		return a.Path < b.Path
	})
	return out
}
