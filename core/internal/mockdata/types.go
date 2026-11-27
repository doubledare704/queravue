// Package mockdata generates deterministic mock rows and documents from column rules.
package mockdata

import (
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
)

// TargetRef identifies a table or collection target.
type TargetRef struct {
	IsCollection bool
	Database     string
	Schema       string
	Name         string
}

// Key returns a canonical map key distinguishing tables from collections.
func (t TargetRef) Key() string {
	if t.IsCollection {
		return "c:" + t.Database + "." + t.Name
	}
	return "t:" + t.Database + "." + t.Schema + "." + t.Name
}

// TableKey returns a canonical key for a relational table reference.
func TableKey(database, schema, table string) string {
	return TargetRef{Database: database, Schema: schema, Name: table}.Key()
}

// RuleKind selects the generator strategy for a column or field path.
type RuleKind int

// Rule kinds supported by mock column generators.
const (
	RuleSkip RuleKind = iota
	RuleFaker
	RuleSequence
	RuleIntRange
	RuleFloatRange
	RuleDecimalRange
	RuleTimeRange
	RuleWeightedValues
	RuleConstant
	RulePattern
	RuleForeignKey
	RuleDocument
	RuleArray
)

// SequenceRule counts monotonically from Start by Step.
type SequenceRule struct {
	Start int64
	Step  int64
}

// IntRangeRule draws integers uniformly from [Min, Max].
type IntRangeRule struct {
	Min int64
	Max int64
}

// FloatRangeRule draws floats uniformly from [Min, Max).
type FloatRangeRule struct {
	Min float64
	Max float64
}

// DecimalRangeRule draws fixed-scale decimals from [Min, Max].
type DecimalRangeRule struct {
	Min   string
	Max   string
	Scale uint32
}

// TimeRangeRule draws instants uniformly from [FromMs, ToMs].
type TimeRangeRule struct {
	FromMs   int64
	ToMs     int64
	DateOnly bool
}

// WeightedValuesRule draws from Values according to Weights.
type WeightedValuesRule struct {
	Values  []engine.Value
	Weights []float64
}

// ConstantRule always emits Value.
type ConstantRule struct {
	Value engine.Value
}

// PatternRule expands # (digit), ? (letter), and \ escapes.
type PatternRule struct {
	Pattern string
}

// ForeignKeyRule draws values from a parent table's key column.
type ForeignKeyRule struct {
	Parent           TargetRef
	ParentColumn     string
	FromExistingRows bool
}

// DocumentRule generates an embedded document from nested field rules.
type DocumentRule struct {
	Fields []ColumnRule
}

// ArrayRule generates an array of elements drawn from Element.
type ArrayRule struct {
	MinLength uint32
	MaxLength uint32
	Element   *ColumnRule
}

// ColumnRule configures generation for one column or dotted field path.
type ColumnRule struct {
	ColumnOrPath string
	NullRatio    float64
	Unique       bool
	Kind         RuleKind

	FakerKind      string
	Sequence       SequenceRule
	IntRange       IntRangeRule
	FloatRange     FloatRangeRule
	DecimalRange   DecimalRangeRule
	TimeRange      TimeRangeRule
	WeightedValues WeightedValuesRule
	Constant       ConstantRule
	Pattern        PatternRule
	ForeignKey     ForeignKeyRule
	Document       DocumentRule
	Array          ArrayRule
}

// TargetSpec defines the row count and column rules for one target.
type TargetSpec struct {
	Target TargetRef
	Rows   uint64
	Rules  []ColumnRule
}

// Spec describes an entire deterministic generation run.
type Spec struct {
	Seed    uint64
	Targets []TargetSpec
}

// CycleEdge describes one foreign-key edge participating in a cycle.
type CycleEdge struct {
	Child          TargetRef
	Parent         TargetRef
	ConstraintName string
	Nullable       bool
}

// Cycle is a foreign-key cycle blocking generation until broken.
type Cycle struct {
	Edges []CycleEdge
}

// TablePreview holds generated preview data for one target.
type TablePreview struct {
	Target         TargetRef
	Columns        []string
	Rows           [][]engine.Value
	DocumentsEJSON []string
}

// Progress reports committed progress for the active target.
type Progress struct {
	Target        TargetRef
	Rows          uint64
	RowsPerSecond float64
}

// TargetDone reports completion of one target.
type TargetDone struct {
	Target    TargetRef
	Rows      uint64
	ElapsedMs uint64
}

// Summary aggregates committed targets across a run.
type Summary struct {
	Rows      uint64
	ElapsedMs uint64
	Done      []TargetDone
}

// RunEvent carries one progress or completion event emitted during Run.
type RunEvent struct {
	Progress   *Progress
	TargetDone *TargetDone
}

// SuggestedSpec holds the output of SuggestSpec.
type SuggestedSpec struct {
	Spec       Spec
	Cycles     []Cycle
	FakerKinds []string
	Warnings   []string
}

// DefaultTimeWindow is the lookback window for suggested time ranges.
var DefaultTimeWindow = 2 * 365 * 24 * time.Hour
