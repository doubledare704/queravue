package api

import (
	"github.com/doubledare704/queravue/core/internal/engine"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
)

var keyTypePairs = []struct {
	engine engine.KeyType
	wire   queravuev1.KeyType
}{
	{engine.KeyTypeString, queravuev1.KeyType_KEY_TYPE_STRING},
	{engine.KeyTypeHash, queravuev1.KeyType_KEY_TYPE_HASH},
	{engine.KeyTypeList, queravuev1.KeyType_KEY_TYPE_LIST},
	{engine.KeyTypeSet, queravuev1.KeyType_KEY_TYPE_SET},
	{engine.KeyTypeZSet, queravuev1.KeyType_KEY_TYPE_ZSET},
	{engine.KeyTypeStream, queravuev1.KeyType_KEY_TYPE_STREAM},
	{engine.KeyTypeJSON, queravuev1.KeyType_KEY_TYPE_JSON},
	{engine.KeyTypeHyperLogLog, queravuev1.KeyType_KEY_TYPE_HYPERLOGLOG},
}

func engineKeyType(t queravuev1.KeyType) engine.KeyType {
	for _, p := range keyTypePairs {
		if p.wire == t {
			return p.engine
		}
	}
	return engine.KeyTypeUnknown
}

func wireKeyType(t engine.KeyType) queravuev1.KeyType {
	for _, p := range keyTypePairs {
		if p.engine == t {
			return p.wire
		}
	}
	return queravuev1.KeyType_KEY_TYPE_UNSPECIFIED
}

func valuePageToWire(p engine.ValuePage) *queravuev1.ReadValueResponse {
	resp := &queravuev1.ReadValueResponse{Type: wireKeyType(p.Type), NextCursor: p.NextCursor}
	switch p.Type {
	case engine.KeyTypeString:
		resp.Value = &queravuev1.ReadValueResponse_StringValue{StringValue: &queravuev1.StringValue{Data: p.String, TotalBytes: p.TotalBytes, Binary: p.Binary}}
	case engine.KeyTypeHash:
		h := &queravuev1.HashValues{Entries: make([]*queravuev1.HashEntry, len(p.Hash))}
		for i, e := range p.Hash {
			h.Entries[i] = &queravuev1.HashEntry{Field: e.Field, Value: e.Value}
		}
		resp.Value = &queravuev1.ReadValueResponse_Hash{Hash: h}
	case engine.KeyTypeList:
		resp.Value = &queravuev1.ReadValueResponse_List{List: &queravuev1.ListValues{Items: p.List, StartIndex: p.ListStart}}
	case engine.KeyTypeSet:
		resp.Value = &queravuev1.ReadValueResponse_Set{Set: &queravuev1.SetValues{Members: p.Set}}
	case engine.KeyTypeZSet:
		z := &queravuev1.ZsetValues{Entries: make([]*queravuev1.ZsetEntry, len(p.ZSet))}
		for i, e := range p.ZSet {
			z.Entries[i] = &queravuev1.ZsetEntry{Member: e.Member, Score: e.Score}
		}
		resp.Value = &queravuev1.ReadValueResponse_Zset{Zset: z}
	case engine.KeyTypeStream:
		resp.Value = &queravuev1.ReadValueResponse_Stream{Stream: streamToWire(p.Stream)}
	case engine.KeyTypeJSON:
		resp.Value = &queravuev1.ReadValueResponse_Json{Json: &queravuev1.JsonValue{Json: p.JSON}}
	case engine.KeyTypeHyperLogLog:
		resp.Value = &queravuev1.ReadValueResponse_Hyperloglog{Hyperloglog: &queravuev1.HyperLogLogValue{Count: p.Cardinality}}
	}
	return resp
}

func streamToWire(entries []engine.StreamEntry) *queravuev1.StreamValues {
	out := &queravuev1.StreamValues{Entries: make([]*queravuev1.StreamEntry, len(entries))}
	for i, e := range entries {
		se := &queravuev1.StreamEntry{Id: e.ID, Fields: make([]*queravuev1.HashEntry, len(e.Fields))}
		for j, f := range e.Fields {
			se.Fields[j] = &queravuev1.HashEntry{Field: f.Field, Value: f.Value}
		}
		out.Entries[i] = se
	}
	return out
}

func writeOpFromWire(op *queravuev1.WriteOp) (engine.WriteOp, bool) {
	switch o := op.GetOp().(type) {
	case *queravuev1.WriteOp_SetString_:
		return engine.WriteOp{Kind: engine.WriteSetString, Value: o.SetString.GetValue()}, true
	case *queravuev1.WriteOp_HashSet_:
		return engine.WriteOp{Kind: engine.WriteHashSet, Field: o.HashSet.GetField(), Value: o.HashSet.GetValue()}, true
	case *queravuev1.WriteOp_HashDelete_:
		return engine.WriteOp{Kind: engine.WriteHashDelete, Field: o.HashDelete.GetField()}, true
	case *queravuev1.WriteOp_ListPush_:
		return engine.WriteOp{Kind: engine.WriteListPush, Values: o.ListPush.GetValues(), AtHead: o.ListPush.GetAtHead()}, true
	case *queravuev1.WriteOp_ListSet_:
		return engine.WriteOp{Kind: engine.WriteListSet, Index: o.ListSet.GetIndex(), Value: o.ListSet.GetValue()}, true
	case *queravuev1.WriteOp_ListRemove_:
		return engine.WriteOp{Kind: engine.WriteListRemove, Value: o.ListRemove.GetValue(), Count: o.ListRemove.GetCount()}, true
	case *queravuev1.WriteOp_SetAdd_:
		return engine.WriteOp{Kind: engine.WriteSetAdd, Values: o.SetAdd.GetMembers()}, true
	case *queravuev1.WriteOp_SetRemove_:
		return engine.WriteOp{Kind: engine.WriteSetRemove, Values: o.SetRemove.GetMembers()}, true
	case *queravuev1.WriteOp_ZsetAdd_:
		entries := make([]engine.ZSetEntry, len(o.ZsetAdd.GetEntries()))
		for i, e := range o.ZsetAdd.GetEntries() {
			entries[i] = engine.ZSetEntry{Member: e.GetMember(), Score: e.GetScore()}
		}
		return engine.WriteOp{Kind: engine.WriteZSetAdd, ZSet: entries}, true
	case *queravuev1.WriteOp_ZsetRemove_:
		return engine.WriteOp{Kind: engine.WriteZSetRemove, Values: o.ZsetRemove.GetMembers()}, true
	case *queravuev1.WriteOp_StreamAdd_:
		fields := make([]engine.HashEntry, len(o.StreamAdd.GetFields()))
		for i, f := range o.StreamAdd.GetFields() {
			fields[i] = engine.HashEntry{Field: f.GetField(), Value: f.GetValue()}
		}
		return engine.WriteOp{Kind: engine.WriteStreamAdd, ID: o.StreamAdd.GetId(), Fields: fields}, true
	case *queravuev1.WriteOp_StreamDelete_:
		return engine.WriteOp{Kind: engine.WriteStreamDelete, IDs: o.StreamDelete.GetIds()}, true
	case *queravuev1.WriteOp_JsonSet_:
		return engine.WriteOp{Kind: engine.WriteJSONSet, JSONPath: o.JsonSet.GetPath(), Value: []byte(o.JsonSet.GetJson())}, true
	}
	return engine.WriteOp{}, false
}

func replyToWire(r engine.Reply) *queravuev1.RespValue {
	switch r.Kind {
	case engine.ReplyString:
		return &queravuev1.RespValue{Kind: &queravuev1.RespValue_StringValue{StringValue: nonNilBytes(r.Bytes)}}
	case engine.ReplyInteger:
		return &queravuev1.RespValue{Kind: &queravuev1.RespValue_Integer{Integer: r.Int}}
	case engine.ReplyDouble:
		return &queravuev1.RespValue{Kind: &queravuev1.RespValue_DoubleValue{DoubleValue: r.Float}}
	case engine.ReplyBoolean:
		return &queravuev1.RespValue{Kind: &queravuev1.RespValue_Boolean{Boolean: r.Bool}}
	case engine.ReplyArray:
		return &queravuev1.RespValue{Kind: &queravuev1.RespValue_Array{Array: &queravuev1.RespValue_Items{Items: repliesToWire(r.Items)}}}
	case engine.ReplySet:
		return &queravuev1.RespValue{Kind: &queravuev1.RespValue_Set{Set: &queravuev1.RespValue_Items{Items: repliesToWire(r.Items)}}}
	case engine.ReplyMap:
		m := &queravuev1.RespValue_Entries{Entries: make([]*queravuev1.RespValue_MapEntry, len(r.Entries))}
		for i, e := range r.Entries {
			m.Entries[i] = &queravuev1.RespValue_MapEntry{Key: replyToWire(e.Key), Value: replyToWire(e.Value)}
		}
		return &queravuev1.RespValue{Kind: &queravuev1.RespValue_Map{Map: m}}
	case engine.ReplyVerbatim:
		return &queravuev1.RespValue{Kind: &queravuev1.RespValue_Verbatim_{Verbatim: &queravuev1.RespValue_Verbatim{Format: r.Format, Text: r.Text}}}
	case engine.ReplyError:
		return &queravuev1.RespValue{Kind: &queravuev1.RespValue_Error{Error: r.Text}}
	}
	return &queravuev1.RespValue{Kind: &queravuev1.RespValue_Nil{Nil: true}}
}

func repliesToWire(items []engine.Reply) []*queravuev1.RespValue {
	out := make([]*queravuev1.RespValue, len(items))
	for i, it := range items {
		out[i] = replyToWire(it)
	}
	return out
}

// nonNilBytes keeps an empty string distinct from an unset oneof on the wire.
func nonNilBytes(b []byte) []byte {
	if b == nil {
		return []byte{}
	}
	return b
}
