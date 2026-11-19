package mongosql

type statement struct {
	distinct       bool
	distinctOffset int
	items          []selectItem
	from           tableRef
	joins          []join
	where          expr
	groupBy        []expr
	groupByOffset  int
	having         expr
	havingOffset   int
	orderBy        []orderItem
	limit          *uint64
	limitOffset    int
	offset         uint64
}

type tableRef struct {
	name   string
	alias  string
	offset int
}

type joinKind int

const (
	joinInner joinKind = iota + 1
	joinLeft
)

type join struct {
	kind   joinKind
	table  tableRef
	on     expr
	offset int
}

type selectItem struct {
	star   bool
	expr   expr
	alias  string
	offset int
}

type orderItem struct {
	expr       expr
	descending bool
	offset     int
}

type expr interface {
	pos() int
}

type fieldRef struct {
	parts  []string
	offset int
}

type literal struct {
	value  any
	isNull bool
	offset int
}

type logical struct {
	and      bool
	operands []expr
	offset   int
}

type negation struct {
	operand expr
	offset  int
}

type comparison struct {
	op          string
	left, right expr
	offset      int
}

type inList struct {
	operand expr
	values  []expr
	negated bool
	offset  int
}

type between struct {
	operand, low, high expr
	negated            bool
	offset             int
}

type likeMatch struct {
	operand         expr
	pattern         string
	escape          rune
	caseInsensitive bool
	negated         bool
	offset          int
}

type nullCheck struct {
	operand expr
	negated bool
	offset  int
}

type arithmetic struct {
	op          string
	left, right expr
	offset      int
}

type aggregateCall struct {
	name     string
	star     bool
	distinct bool
	arg      expr
	offset   int
}

func (e fieldRef) pos() int      { return e.offset }
func (e literal) pos() int       { return e.offset }
func (e logical) pos() int       { return e.offset }
func (e negation) pos() int      { return e.offset }
func (e comparison) pos() int    { return e.offset }
func (e inList) pos() int        { return e.offset }
func (e between) pos() int       { return e.offset }
func (e likeMatch) pos() int     { return e.offset }
func (e nullCheck) pos() int     { return e.offset }
func (e arithmetic) pos() int    { return e.offset }
func (e aggregateCall) pos() int { return e.offset }
