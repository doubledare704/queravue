package engine

import (
	"context"
	"time"
)

// KeyType is the data type of a key.
type KeyType int

// Key types; they mirror queravue.v1.KeyType.
const (
	KeyTypeUnknown KeyType = iota
	KeyTypeString
	KeyTypeHash
	KeyTypeList
	KeyTypeSet
	KeyTypeZSet
	KeyTypeStream
	KeyTypeJSON
	KeyTypeHyperLogLog
)

// NoTTL and UnknownTTL are the TTL sentinels of KeySummary and KeyInfo.
const (
	NoTTL      int64 = -1
	UnknownTTL int64 = -2
)

// Defaults for paged key-value reads.
const (
	DefaultScanPageSize   = 500
	DefaultValuePageSize  = 200
	DefaultStringMaxBytes = 1 << 20
)

// KVDatabase is one logical database with its key counts.
type KVDatabase struct {
	Index         uint32
	KeyCount      uint64
	ExpiringCount uint64
}

// KVDatabases lists databases and how many the server allows.
type KVDatabases struct {
	Databases     []KVDatabase
	DatabaseLimit uint32
}

// ScanOptions selects keys for ScanKeys.
type ScanOptions struct {
	Database uint32
	// Pattern is the MATCH glob; empty matches everything.
	Pattern string
	// TypeFilter limits keys to one type; KeyTypeUnknown means any.
	TypeFilter KeyType
	PageSize   int
}

// KeySummary is one scanned key.
type KeySummary struct {
	Key   []byte
	Type  KeyType
	TTLMs int64
}

// ScanPage is one page of scanned keys; Scanned counts keys seen so far.
type ScanPage struct {
	Keys    []KeySummary
	Scanned uint64
}

// KeyInfo describes one key.
type KeyInfo struct {
	Type        KeyType
	TTLMs       int64
	Encoding    string
	Length      uint64
	MemoryBytes *uint64
	BigKey      bool
}

// ReadOptions selects one page of a value.
type ReadOptions struct {
	Database     uint32
	Key          []byte
	Cursor       string
	PageSize     int
	MaxBytes     int
	Reverse      bool
	OrderByScore bool
}

// HashEntry is a field and its value.
type HashEntry struct{ Field, Value []byte }

// ZSetEntry is a member with its score.
type ZSetEntry struct {
	Member []byte
	Score  float64
}

// StreamEntry is one stream entry.
type StreamEntry struct {
	ID     string
	Fields []HashEntry
}

// ValuePage is one page of a value. Only the field matching Type is set.
type ValuePage struct {
	Type        KeyType
	String      []byte
	TotalBytes  uint64
	Binary      bool
	Hash        []HashEntry
	List        [][]byte
	ListStart   uint64
	Set         [][]byte
	ZSet        []ZSetEntry
	Stream      []StreamEntry
	JSON        string
	Cardinality uint64
	NextCursor  string
}

// WriteKind selects the typed edit of a WriteOp.
type WriteKind int

// Write kinds.
const (
	WriteSetString WriteKind = iota + 1
	WriteHashSet
	WriteHashDelete
	WriteListPush
	WriteListSet
	WriteListRemove
	WriteSetAdd
	WriteSetRemove
	WriteZSetAdd
	WriteZSetRemove
	WriteStreamAdd
	WriteStreamDelete
	WriteJSONSet
)

// WriteOp is one typed edit; only the fields its Kind uses are read.
type WriteOp struct {
	Kind     WriteKind
	Value    []byte
	Field    []byte
	Values   [][]byte
	AtHead   bool
	Index    int64
	Count    int64
	ZSet     []ZSetEntry
	ID       string
	Fields   []HashEntry
	IDs      []string
	JSONPath string
}

// ReplyKind is the RESP3 type of a Reply.
type ReplyKind int

// Reply kinds.
const (
	ReplyNil ReplyKind = iota
	ReplyString
	ReplyInteger
	ReplyDouble
	ReplyBoolean
	ReplyArray
	ReplyMap
	ReplySet
	ReplyVerbatim
	ReplyError
)

// ReplyEntry is one key and value of a map reply.
type ReplyEntry struct{ Key, Value Reply }

// Reply is a typed server reply.
type Reply struct {
	Kind    ReplyKind
	Bytes   []byte
	Int     int64
	Float   float64
	Bool    bool
	Items   []Reply
	Entries []ReplyEntry
	Format  string
	Text    string
}

// PubSubMessage is one delivered message.
type PubSubMessage struct {
	Channel    string
	Pattern    string
	Payload    []byte
	ReceivedAt time.Time
}

// KeyValueStore is implemented by Conns with CapKeyValueStore (ADR 0020).
// Reads are paged and nothing returns a whole collection.
type KeyValueStore interface {
	ListDatabases(ctx context.Context) (KVDatabases, error)
	// ScanKeys pages through keys with SCAN, never KEYS, until ctx is cancelled
	// or the scan ends. On a cluster it scans every master.
	ScanKeys(ctx context.Context, opts ScanOptions, emit func(ScanPage) error) error
	KeyInfo(ctx context.Context, database uint32, key []byte) (KeyInfo, error)
	ReadValue(ctx context.Context, opts ReadOptions) (ValuePage, error)
	WriteValue(ctx context.Context, database uint32, key []byte, op WriteOp) error
	RenameKey(ctx context.Context, database uint32, key, newKey []byte, overwrite bool) error
	// SetExpiry removes the TTL when ttl is nil.
	SetExpiry(ctx context.Context, database uint32, key []byte, ttl *time.Duration) error
	DeleteKeys(ctx context.Context, database uint32, keys [][]byte) (uint64, error)
	// ExecuteCommand refuses KEYS and blocking commands with KindKeysRefused
	// and KindBlockingRefused.
	ExecuteCommand(ctx context.Context, database uint32, args [][]byte) (Reply, error)
	// Subscribe delivers messages until ctx is cancelled.
	Subscribe(ctx context.Context, channels, patterns []string, emit func(PubSubMessage) error) error
	Publish(ctx context.Context, channel string, payload []byte) (uint64, error)
}
