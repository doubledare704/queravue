package mockdata

import (
	"encoding/binary"
	"fmt"
	"math"
	"math/big"
	"math/rand/v2"
	"sort"
	"strconv"
	"strings"
	"time"

	"github.com/shopspring/decimal"

	"github.com/doubledare704/queravue/core/internal/engine"
)

const (
	maxUniqueRetries = 64
	maxDecimalScale  = 38
)

type colGenerator interface {
	next(ctxGen *genContext) (generatedValue, error)
}

type genContext struct {
	keys *KeyStore
}

type generatedValue struct {
	val        engine.Value
	omitted    bool
	isObjectID bool
	isDoc      bool
	isArray    bool
	fields     []docFieldValue
	elements   []generatedValue
}

type docFieldValue struct {
	name  string
	value generatedValue
}

func buildGenerator(seed uint64, target TargetRef, colPath string, rule ColumnRule) (colGenerator, error) {
	if math.IsNaN(rule.NullRatio) || rule.NullRatio < 0 || rule.NullRatio > 1 {
		return nil, parseErr(&target, colPath, fmt.Sprintf("null_ratio %v must be between 0 and 1", rule.NullRatio))
	}

	targetKey := target.Key()
	base, inherentlyUnique, err := buildBaseGenerator(seed, target, targetKey, colPath, rule)
	if err != nil {
		return nil, err
	}
	if base == nil {
		return skipGenerator{}, nil
	}

	g := base
	if rule.Unique && !inherentlyUnique {
		g = newUniqueGenerator(target, colPath, g)
	}
	if rule.NullRatio > 0 {
		g = &nullRatioGenerator{
			ratio: rule.NullRatio,
			rng:   deriveRNG(seed, targetKey, colPath, "null"),
			inner: g,
		}
	}
	return g, nil
}

func buildBaseGenerator(seed uint64, target TargetRef, targetKey, colPath string, rule ColumnRule) (colGenerator, bool, error) {
	switch rule.Kind {
	case RuleSkip:
		return skipGenerator{}, true, nil
	case RuleFaker:
		if !IsSupportedFakerKind(rule.FakerKind) {
			return nil, false, parseErr(&target, colPath, fmt.Sprintf("unknown faker kind %q", rule.FakerKind))
		}
		return &fakerGenerator{
			src:        newFakerSource(rule.FakerKind, seed, targetKey, colPath),
			isObjectID: rule.FakerKind == "object_id",
		}, false, nil
	case RuleSequence:
		step := rule.Sequence.Step
		if step == 0 {
			step = 1
		}
		return &sequenceGenerator{nextVal: rule.Sequence.Start, step: step}, true, nil
	case RuleIntRange:
		if rule.IntRange.Min > rule.IntRange.Max {
			return nil, false, parseErr(&target, colPath, fmt.Sprintf("int_range min (%d) > max (%d)", rule.IntRange.Min, rule.IntRange.Max))
		}
		return &intRangeGenerator{
			min: rule.IntRange.Min,
			max: rule.IntRange.Max,
			rng: deriveRNG(seed, targetKey, colPath, "int_range"),
		}, false, nil
	case RuleFloatRange:
		r := rule.FloatRange
		if math.IsNaN(r.Min) || math.IsNaN(r.Max) || math.IsInf(r.Min, 0) || math.IsInf(r.Max, 0) || r.Min >= r.Max {
			return nil, false, parseErr(&target, colPath, fmt.Sprintf("float_range requires finite min < max, got [%v, %v)", r.Min, r.Max))
		}
		return &floatRangeGenerator{
			min: r.Min,
			max: r.Max,
			rng: deriveRNG(seed, targetKey, colPath, "float_range"),
		}, false, nil
	case RuleDecimalRange:
		return newDecimalRangeGenerator(seed, target, targetKey, colPath, rule.DecimalRange)
	case RuleTimeRange:
		if rule.TimeRange.FromMs > rule.TimeRange.ToMs {
			return nil, false, parseErr(&target, colPath, fmt.Sprintf("time_range from_ms (%d) > to_ms (%d)", rule.TimeRange.FromMs, rule.TimeRange.ToMs))
		}
		return &timeRangeGenerator{
			fromMs:   rule.TimeRange.FromMs,
			toMs:     rule.TimeRange.ToMs,
			dateOnly: rule.TimeRange.DateOnly,
			rng:      deriveRNG(seed, targetKey, colPath, "time_range"),
		}, false, nil
	case RuleWeightedValues:
		return newWeightedGenerator(seed, target, targetKey, colPath, rule.WeightedValues)
	case RuleConstant:
		return &constantGenerator{val: rule.Constant.Value}, false, nil
	case RulePattern:
		return newPatternGenerator(seed, target, targetKey, colPath, rule.Pattern)
	case RuleForeignKey:
		if rule.ForeignKey.Parent.Name == "" || rule.ForeignKey.ParentColumn == "" {
			return nil, false, parseErr(&target, colPath, "foreign_key requires parent table and parent_column")
		}
		return &fkGenerator{
			target:    target,
			col:       colPath,
			parentKey: rule.ForeignKey.Parent.Key(),
			parentCol: rule.ForeignKey.ParentColumn,
			rng:       deriveRNG(seed, targetKey, colPath, "foreign_key"),
		}, false, nil
	case RuleDocument:
		fields := make([]compiledDocField, len(rule.Document.Fields))
		for i, f := range rule.Document.Fields {
			if f.ColumnOrPath == "" {
				return nil, false, parseErr(&target, colPath, "document field requires column_or_path")
			}
			childPath := colPath + "." + f.ColumnOrPath
			fg, err := buildGenerator(seed, target, childPath, f)
			if err != nil {
				return nil, false, err
			}
			fields[i] = compiledDocField{name: f.ColumnOrPath, gen: fg}
		}
		return &documentGenerator{fields: fields}, false, nil
	case RuleArray:
		if rule.Array.MinLength > rule.Array.MaxLength {
			return nil, false, parseErr(&target, colPath, fmt.Sprintf("array min_length (%d) > max_length (%d)", rule.Array.MinLength, rule.Array.MaxLength))
		}
		if rule.Array.Element == nil {
			return nil, false, parseErr(&target, colPath, "array rule requires an element rule")
		}
		elemGen, err := buildGenerator(seed, target, colPath+".[]", *rule.Array.Element)
		if err != nil {
			return nil, false, err
		}
		return &arrayGenerator{
			minLen:  rule.Array.MinLength,
			maxLen:  rule.Array.MaxLength,
			elemGen: elemGen,
			rng:     deriveRNG(seed, targetKey, colPath, "array"),
		}, false, nil
	default:
		return nil, false, parseErr(&target, colPath, "missing or unsupported rule kind")
	}
}

type skipGenerator struct{}

func (skipGenerator) next(*genContext) (generatedValue, error) {
	return generatedValue{val: engine.Null(), omitted: true}, nil
}

type fakerGenerator struct {
	src        *fakerSource
	isObjectID bool
}

func (g *fakerGenerator) next(*genContext) (generatedValue, error) {
	return generatedValue{val: g.src.next(), isObjectID: g.isObjectID}, nil
}

type sequenceGenerator struct {
	nextVal int64
	step    int64
}

func (g *sequenceGenerator) next(*genContext) (generatedValue, error) {
	v := g.nextVal
	g.nextVal += g.step
	return generatedValue{val: engine.Int(v)}, nil
}

type intRangeGenerator struct {
	min int64
	max int64
	rng *rand.Rand
}

func (g *intRangeGenerator) next(*genContext) (generatedValue, error) {
	span := uint64(g.max) - uint64(g.min) //nolint:gosec // intentional unsigned modular distance
	var n uint64
	if span == math.MaxUint64 {
		n = g.rng.Uint64()
	} else {
		n = uint64(g.min) + g.rng.Uint64N(span+1) //nolint:gosec // modular two's-complement reconstruction
	}
	return generatedValue{val: engine.Int(int64(n))}, nil //nolint:gosec // exact inverse of uint64(g.min)+offset
}

type floatRangeGenerator struct {
	min float64
	max float64
	rng *rand.Rand
}

func (g *floatRangeGenerator) next(*genContext) (generatedValue, error) {
	diff := g.max - g.min
	var v float64
	if math.IsInf(diff, 0) {
		halfMin := g.min / 2
		halfMax := g.max / 2
		v = (halfMin + g.rng.Float64()*(halfMax-halfMin)) * 2
	} else {
		v = g.min + g.rng.Float64()*diff
	}
	if v >= g.max {
		v = math.Nextafter(g.max, g.min)
	}
	return generatedValue{val: engine.Float(v)}, nil
}

type decimalRangeGenerator struct {
	minInt    *big.Int
	span      *big.Int
	spanIsU64 bool
	spanU64   uint64
	scale     int32
	rng       *rand.Rand
}

func newDecimalRangeGenerator(seed uint64, target TargetRef, targetKey, colPath string, r DecimalRangeRule) (colGenerator, bool, error) {
	if r.Scale > maxDecimalScale {
		return nil, false, parseErr(&target, colPath, fmt.Sprintf("decimal_range scale %d exceeds max %d", r.Scale, maxDecimalScale))
	}
	minDec, err := decimal.NewFromString(strings.TrimSpace(r.Min))
	if err != nil {
		return nil, false, parseErr(&target, colPath, fmt.Sprintf("invalid decimal_range min %q", r.Min))
	}
	maxDec, err := decimal.NewFromString(strings.TrimSpace(r.Max))
	if err != nil {
		return nil, false, parseErr(&target, colPath, fmt.Sprintf("invalid decimal_range max %q", r.Max))
	}
	if minDec.GreaterThan(maxDec) {
		return nil, false, parseErr(&target, colPath, fmt.Sprintf("decimal_range min (%s) > max (%s)", r.Min, r.Max))
	}
	scale := int32(r.Scale)
	minInt := minDec.Shift(scale).Ceil().BigInt()
	maxInt := maxDec.Shift(scale).Floor().BigInt()
	if minInt.Cmp(maxInt) > 0 {
		return nil, false, parseErr(&target, colPath, "decimal_range contains no representable value at requested scale")
	}
	span := new(big.Int).Sub(maxInt, minInt)
	g := &decimalRangeGenerator{
		minInt:    minInt,
		span:      span,
		spanIsU64: span.IsUint64() && span.Uint64() < math.MaxUint64,
		scale:     scale,
		rng:       deriveRNG(seed, targetKey, colPath, "decimal_range"),
	}
	if g.spanIsU64 {
		g.spanU64 = span.Uint64() + 1
	}
	return g, false, nil
}

func (g *decimalRangeGenerator) next(*genContext) (generatedValue, error) {
	var offset *big.Int
	if g.spanIsU64 {
		offset = new(big.Int).SetUint64(g.rng.Uint64N(g.spanU64))
	} else {
		limit := new(big.Int).Add(g.span, big.NewInt(1))
		offset = randBigIntN(g.rng, limit)
	}
	val := new(big.Int).Add(g.minInt, offset)
	return generatedValue{val: engine.Decimal(decimal.NewFromBigInt(val, -g.scale).StringFixed(g.scale))}, nil
}

func randBigIntN(rng *rand.Rand, limit *big.Int) *big.Int {
	if limit.Sign() <= 0 {
		return big.NewInt(0)
	}
	bitLen := limit.BitLen()
	byteLen := (bitLen + 7) / 8
	buf := make([]byte, byteLen)
	topBits := bitLen % 8
	mask := byte(0xff)
	if topBits != 0 {
		mask = byte((1 << topBits) - 1)
	}
	candidate := new(big.Int)
	var chunk [8]byte
	for {
		for i := 0; i < byteLen; i += 8 {
			binary.LittleEndian.PutUint64(chunk[:], rng.Uint64())
			copy(buf[i:], chunk[:])
		}
		buf[0] &= mask
		candidate.SetBytes(buf)
		if candidate.Cmp(limit) < 0 {
			return candidate
		}
	}
}

type timeRangeGenerator struct {
	fromMs   int64
	toMs     int64
	dateOnly bool
	rng      *rand.Rand
}

func (g *timeRangeGenerator) next(*genContext) (generatedValue, error) {
	span := uint64(g.toMs) - uint64(g.fromMs) //nolint:gosec // intentional unsigned modular distance
	var ms uint64
	if span == math.MaxUint64 {
		ms = g.rng.Uint64()
	} else {
		ms = uint64(g.fromMs) + g.rng.Uint64N(span+1) //nolint:gosec // modular two's-complement reconstruction
	}
	t := time.UnixMilli(int64(ms)).UTC() //nolint:gosec // exact inverse of uint64(g.fromMs)+offset
	if g.dateOnly {
		t = t.Truncate(24 * time.Hour)
	}
	return generatedValue{val: engine.Timestamptz(t)}, nil
}

type weightedGenerator struct {
	values []engine.Value
	cdf    []float64
	total  float64
	rng    *rand.Rand
}

func newWeightedGenerator(seed uint64, target TargetRef, targetKey, colPath string, r WeightedValuesRule) (colGenerator, bool, error) {
	if len(r.Values) == 0 {
		return nil, false, parseErr(&target, colPath, "weighted_values requires at least one value")
	}
	rng := deriveRNG(seed, targetKey, colPath, "weighted_values")
	if len(r.Weights) == 0 {
		return &weightedGenerator{values: r.Values, rng: rng}, false, nil
	}
	if len(r.Weights) != len(r.Values) {
		return nil, false, parseErr(&target, colPath, fmt.Sprintf("weighted_values has %d values and %d weights", len(r.Values), len(r.Weights)))
	}
	cdf := make([]float64, len(r.Weights))
	var sum float64
	for i, w := range r.Weights {
		if math.IsNaN(w) || math.IsInf(w, 0) || w < 0 {
			return nil, false, parseErr(&target, colPath, fmt.Sprintf("weighted_values weight[%d] (%v) must be finite and >= 0", i, w))
		}
		sum += w
		cdf[i] = sum
	}
	if sum <= 0 {
		return nil, false, parseErr(&target, colPath, "weighted_values total weight must be > 0")
	}
	return &weightedGenerator{values: r.Values, cdf: cdf, total: sum, rng: rng}, false, nil
}

func (g *weightedGenerator) next(*genContext) (generatedValue, error) {
	if len(g.cdf) == 0 {
		return generatedValue{val: g.values[g.rng.IntN(len(g.values))]}, nil
	}
	x := g.rng.Float64() * g.total
	idx := sort.SearchFloat64s(g.cdf, x)
	if idx >= len(g.values) {
		idx = len(g.values) - 1
	}
	return generatedValue{val: g.values[idx]}, nil
}

type constantGenerator struct {
	val engine.Value
}

func (g *constantGenerator) next(*genContext) (generatedValue, error) {
	return generatedValue{val: g.val}, nil
}

type patternTokenKind uint8

const (
	tokenLit patternTokenKind = iota
	tokenDigit
	tokenLetter
)

type patternToken struct {
	kind patternTokenKind
	ch   byte
}

type patternGenerator struct {
	tokens []patternToken
	rng    *rand.Rand
}

func newPatternGenerator(seed uint64, target TargetRef, targetKey, colPath string, r PatternRule) (colGenerator, bool, error) {
	tokens := make([]patternToken, 0, len(r.Pattern))
	for i := 0; i < len(r.Pattern); i++ {
		c := r.Pattern[i]
		switch c {
		case '\\':
			if i+1 >= len(r.Pattern) {
				return nil, false, parseErr(&target, colPath, "pattern ends with trailing escape '\\'")
			}
			i++
			tokens = append(tokens, patternToken{kind: tokenLit, ch: r.Pattern[i]})
		case '#':
			tokens = append(tokens, patternToken{kind: tokenDigit})
		case '?':
			tokens = append(tokens, patternToken{kind: tokenLetter})
		default:
			tokens = append(tokens, patternToken{kind: tokenLit, ch: c})
		}
	}
	return &patternGenerator{
		tokens: tokens,
		rng:    deriveRNG(seed, targetKey, colPath, "pattern"),
	}, false, nil
}

func (g *patternGenerator) next(*genContext) (generatedValue, error) {
	buf := make([]byte, len(g.tokens))
	for i, tok := range g.tokens {
		switch tok.kind {
		case tokenDigit:
			buf[i] = '0' + byte(g.rng.IntN(10)) //nolint:gosec // IntN(10) fits in byte
		case tokenLetter:
			buf[i] = 'A' + byte(g.rng.IntN(26)) //nolint:gosec // IntN(26) fits in byte
		default:
			buf[i] = tok.ch
		}
	}
	return generatedValue{val: engine.Text(string(buf))}, nil
}

type fkGenerator struct {
	target    TargetRef
	col       string
	parentKey string
	parentCol string
	rng       *rand.Rand
}

func (g *fkGenerator) next(ctxGen *genContext) (generatedValue, error) {
	if ctxGen == nil || ctxGen.keys == nil {
		return generatedValue{}, parseErr(&g.target, g.col, fmt.Sprintf("no parent keys available for %s.%s", g.parentKey, g.parentCol))
	}
	pool := ctxGen.keys.Get(g.parentKey, g.parentCol)
	v, ok := pool.Pick(g.rng)
	if !ok {
		return generatedValue{}, parseErr(&g.target, g.col, fmt.Sprintf("parent %s has no non-null keys in %s", g.parentKey, g.parentCol))
	}
	return generatedValue{val: v}, nil
}

type compiledDocField struct {
	name string
	gen  colGenerator
}

type documentGenerator struct {
	fields []compiledDocField
}

func (g *documentGenerator) next(ctxGen *genContext) (generatedValue, error) {
	out := make([]docFieldValue, 0, len(g.fields))
	for _, f := range g.fields {
		v, err := f.gen.next(ctxGen)
		if err != nil {
			return generatedValue{}, err
		}
		if v.omitted {
			continue
		}
		out = append(out, docFieldValue{name: f.name, value: v})
	}
	return generatedValue{isDoc: true, fields: out}, nil
}

type arrayGenerator struct {
	minLen  uint32
	maxLen  uint32
	elemGen colGenerator
	rng     *rand.Rand
}

func (g *arrayGenerator) next(ctxGen *genContext) (generatedValue, error) {
	span := int(g.maxLen-g.minLen) + 1
	n := int(g.minLen) + g.rng.IntN(span)
	elems := make([]generatedValue, 0, n)
	vals := make([]engine.Value, 0, n)
	for range n {
		ev, err := g.elemGen.next(ctxGen)
		if err != nil {
			return generatedValue{}, err
		}
		if ev.omitted {
			continue
		}
		elems = append(elems, ev)
		vals = append(vals, ev.val)
	}
	return generatedValue{val: engine.Array(vals), isArray: true, elements: elems}, nil
}

type nullRatioGenerator struct {
	ratio float64
	rng   *rand.Rand
	inner colGenerator
}

func (g *nullRatioGenerator) next(ctxGen *genContext) (generatedValue, error) {
	if g.ratio >= 1 || g.rng.Float64() < g.ratio {
		return generatedValue{val: engine.Null(), omitted: true}, nil
	}
	return g.inner.next(ctxGen)
}

type uniqueGenerator struct {
	target TargetRef
	col    string
	inner  colGenerator
	seen   map[string]struct{}
	ints   map[int64]struct{}
}

func newUniqueGenerator(target TargetRef, col string, inner colGenerator) *uniqueGenerator {
	return &uniqueGenerator{target: target, col: col, inner: inner}
}

func (g *uniqueGenerator) next(ctxGen *genContext) (generatedValue, error) {
	for range maxUniqueRetries {
		v, err := g.inner.next(ctxGen)
		if err != nil {
			return generatedValue{}, err
		}
		if v.val.Kind == engine.VNull {
			return v, nil
		}
		if v.val.Kind == engine.VInt && len(v.fields) == 0 && len(v.elements) == 0 {
			if g.ints == nil {
				g.ints = map[int64]struct{}{}
			}
			if _, dup := g.ints[v.val.Int]; dup {
				continue
			}
			g.ints[v.val.Int] = struct{}{}
			return v, nil
		}
		key := uniqueValueKey(v)
		if g.seen == nil {
			g.seen = map[string]struct{}{}
		}
		if _, dup := g.seen[key]; dup {
			continue
		}
		g.seen[key] = struct{}{}
		return v, nil
	}
	return generatedValue{}, &Error{
		Kind:    ErrUniqueExhausted,
		Message: fmt.Sprintf("exhausted unique values after %d attempts", maxUniqueRetries),
		Target:  &g.target,
		Column:  g.col,
	}
}

func uniqueValueKey(v generatedValue) string {
	if len(v.fields) > 0 || len(v.elements) > 0 {
		var b strings.Builder
		writeEJSONValue(&b, v)
		return "d:" + b.String()
	}
	switch v.val.Kind {
	case engine.VBool:
		if v.val.Bool {
			return "b:1"
		}
		return "b:0"
	case engine.VInt:
		return "i:" + strconv.FormatInt(v.val.Int, 10)
	case engine.VFloat:
		return "f:" + strconv.FormatUint(math.Float64bits(v.val.Float), 16)
	case engine.VTimestamptz:
		return "t:" + strconv.FormatInt(v.val.Time.UnixNano(), 10)
	case engine.VBytes:
		return "x:" + string(v.val.Bytes)
	default:
		return strconv.Itoa(int(v.val.Kind)) + ":" + v.val.Str
	}
}
