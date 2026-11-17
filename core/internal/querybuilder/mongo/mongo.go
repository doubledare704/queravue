// Package mongo converts find models to and from Extended JSON.
package mongo

import (
	"encoding/json"
	"errors"
	"fmt"
	"strings"

	"go.mongodb.org/mongo-driver/v2/bson"

	pb "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
)

// ErrUnsupported identifies EJSON that cannot be represented by the model.
var ErrUnsupported = errors.New("unsupported construct")

// UnsupportedError identifies the location of an unsupported projection or sort entry.
type UnsupportedError struct {
	Input  string
	Path   string
	Offset int
}

func (e *UnsupportedError) Error() string {
	return fmt.Sprintf("%s: unsupported field %q", e.Input, e.Path)
}
func (e *UnsupportedError) Unwrap() error { return ErrUnsupported }

func unsupported(input, path, text string) error {
	key, _ := json.Marshal(path)
	offset := strings.Index(text, string(key))
	if offset < 0 {
		offset = 0
	}
	return &UnsupportedError{Input: input, Path: path, Offset: offset}
}

var operators = map[pb.MongoOperator]string{
	pb.MongoOperator_MONGO_OPERATOR_NE: "$ne", pb.MongoOperator_MONGO_OPERATOR_GT: "$gt", pb.MongoOperator_MONGO_OPERATOR_GTE: "$gte", pb.MongoOperator_MONGO_OPERATOR_LT: "$lt", pb.MongoOperator_MONGO_OPERATOR_LTE: "$lte", pb.MongoOperator_MONGO_OPERATOR_IN: "$in", pb.MongoOperator_MONGO_OPERATOR_NIN: "$nin", pb.MongoOperator_MONGO_OPERATOR_EXISTS: "$exists", pb.MongoOperator_MONGO_OPERATOR_REGEX: "$regex", pb.MongoOperator_MONGO_OPERATOR_TYPE: "$type",
}

func validOperand(op pb.MongoOperator, v any) bool {
	switch op {
	case pb.MongoOperator_MONGO_OPERATOR_IN, pb.MongoOperator_MONGO_OPERATOR_NIN:
		_, ok := v.(bson.A)
		return ok
	case pb.MongoOperator_MONGO_OPERATOR_EXISTS:
		_, ok := v.(bool)
		return ok
	case pb.MongoOperator_MONGO_OPERATOR_REGEX:
		_, ok := v.(string)
		return ok
	case pb.MongoOperator_MONGO_OPERATOR_TYPE:
		switch v.(type) {
		case string, int32, int64, float64:
			return true
		}
		return false
	default:
		return true
	}
}

func document(text string) (bson.D, error) {
	var d bson.D
	if strings.TrimSpace(text) == "" {
		return d, nil
	}
	var syntax json.RawMessage
	if err := json.Unmarshal([]byte(text), &syntax); err != nil {
		return nil, fmt.Errorf("decode JSON: %w", err)
	}
	if err := bson.UnmarshalExtJSON([]byte(text), false, &d); err != nil {
		return nil, fmt.Errorf("decode EJSON: %w", err)
	}
	return d, nil
}
func encode(d bson.D) (string, error) {
	b, err := bson.MarshalExtJSON(d, true, false)
	return string(b), err
}
func value(text string) (any, error) {
	d, err := document(`{"v":` + text + `}`)
	if err != nil {
		return nil, fmt.Errorf("invalid value: %w", err)
	}
	if len(d) != 1 {
		return nil, fmt.Errorf("invalid value")
	}
	return d[0].Value, nil
}
func valueText(v any) (string, error) {
	s, err := encode(bson.D{{Key: "v", Value: v}})
	if err != nil {
		return "", err
	}
	var m map[string]json.RawMessage
	if err = json.Unmarshal([]byte(s), &m); err != nil {
		return "", fmt.Errorf("decode value: %w", err)
	}
	return string(m["v"]), nil
}

// Generate renders a find model as canonical Extended JSON documents.
func Generate(m *pb.MongoFindModel) (string, string, string, error) {
	if m == nil {
		return "", "", "", fmt.Errorf("missing model")
	}
	filter := bson.D{}
	if m.Filter != nil {
		var err error
		filter, err = generateCondition(m.Filter)
		if err != nil {
			return "", "", "", err
		}
	}
	f, err := encode(filter)
	if err != nil {
		return "", "", "", err
	}
	var projection, sort bson.D
	for _, p := range m.Projection {
		if p == nil || p.Path == "" {
			return "", "", "", fmt.Errorf("invalid projection")
		}
		if p.Mode != pb.MongoProjectionMode_MONGO_PROJECTION_MODE_UNSPECIFIED && p.Mode != pb.MongoProjectionMode_MONGO_PROJECTION_MODE_INCLUDE && p.Mode != pb.MongoProjectionMode_MONGO_PROJECTION_MODE_EXCLUDE {
			return "", "", "", fmt.Errorf("invalid projection mode")
		}
		n := int32(1)
		if p.Mode == pb.MongoProjectionMode_MONGO_PROJECTION_MODE_EXCLUDE {
			n = 0
		}
		projection = append(projection, bson.E{Key: p.Path, Value: n})
	}
	for _, s := range m.Sort {
		if s == nil || s.Path == "" {
			return "", "", "", fmt.Errorf("invalid sort")
		}
		n := int32(1)
		if s.Descending {
			n = -1
		}
		sort = append(sort, bson.E{Key: s.Path, Value: n})
	}
	var p, s string
	if len(projection) > 0 {
		p, err = encode(projection)
		if err != nil {
			return "", "", "", err
		}
	}
	if len(sort) > 0 {
		s, err = encode(sort)
		if err != nil {
			return "", "", "", err
		}
	}
	return f, p, s, nil
}
func generateCondition(c *pb.MongoCondition) (bson.D, error) {
	if c == nil {
		return nil, fmt.Errorf("missing condition")
	}
	switch n := c.Node.(type) {
	case *pb.MongoCondition_RawEjson:
		return document(n.RawEjson)
	case *pb.MongoCondition_Group:
		if n.Group == nil || len(n.Group.Children) == 0 {
			return nil, fmt.Errorf("empty group")
		}
		key := "$and"
		switch n.Group.Op {
		case pb.MongoBoolOp_MONGO_BOOL_OP_OR:
			key = "$or"
		case pb.MongoBoolOp_MONGO_BOOL_OP_NOR:
			key = "$nor"
		case pb.MongoBoolOp_MONGO_BOOL_OP_AND, pb.MongoBoolOp_MONGO_BOOL_OP_UNSPECIFIED:
		default:
			return nil, fmt.Errorf("unknown group operator")
		}
		a := bson.A{}
		for _, child := range n.Group.Children {
			d, err := generateCondition(child)
			if err != nil {
				return nil, err
			}
			a = append(a, d)
		}
		return bson.D{{Key: key, Value: a}}, nil
	case *pb.MongoCondition_Field:
		f := n.Field
		if f == nil || f.Path == "" {
			return nil, fmt.Errorf("missing field")
		}
		v, err := value(f.ValueEjson)
		if err != nil {
			return nil, err
		}
		op, ok := operators[f.Op]
		if !ok && f.Op != pb.MongoOperator_MONGO_OPERATOR_EQ && f.Op != pb.MongoOperator_MONGO_OPERATOR_UNSPECIFIED {
			return nil, fmt.Errorf("unknown operator")
		}
		if f.RegexOptions != "" && f.Op != pb.MongoOperator_MONGO_OPERATOR_REGEX {
			return nil, fmt.Errorf("options require regex")
		}
		if !validOperand(f.Op, v) {
			return nil, fmt.Errorf("invalid operand for %s", f.Op)
		}
		if !ok {
			valueDoc, isDoc := v.(bson.D)
			operatorDocument := isDoc && len(valueDoc) > 0 && strings.HasPrefix(valueDoc[0].Key, "$")
			if !f.Negated && !operatorDocument {
				return bson.D{{Key: f.Path, Value: v}}, nil
			}
			op = "$eq"
		}
		d := bson.D{{Key: op, Value: v}}
		if f.RegexOptions != "" {
			if op != "$regex" {
				return nil, fmt.Errorf("options require regex")
			}
			d = append(d, bson.E{Key: "$options", Value: f.RegexOptions})
		}
		if f.Negated {
			d = bson.D{{Key: "$not", Value: d}}
		}
		return bson.D{{Key: f.Path, Value: d}}, nil
	default:
		return nil, fmt.Errorf("missing condition")
	}
}

// Parse reads Extended JSON documents into a find model.
func Parse(filter, projection, sort string) (*pb.MongoFindModel, error) {
	f, err := document(filter)
	if err != nil {
		return nil, fmt.Errorf("filter: %w", err)
	}
	p, err := document(projection)
	if err != nil {
		return nil, fmt.Errorf("projection: %w", err)
	}
	s, err := document(sort)
	if err != nil {
		return nil, fmt.Errorf("sort: %w", err)
	}
	m := &pb.MongoFindModel{}
	if len(f) > 0 {
		m.Filter, err = parseCondition(f)
		if err != nil {
			return nil, err
		}
	}
	for _, e := range p {
		n, ok := integer(e.Value)
		if !ok || (n != 0 && n != 1) {
			return nil, unsupported("projection", e.Key, projection)
		}
		mode := pb.MongoProjectionMode_MONGO_PROJECTION_MODE_INCLUDE
		if n == 0 {
			mode = pb.MongoProjectionMode_MONGO_PROJECTION_MODE_EXCLUDE
		}
		m.Projection = append(m.Projection, &pb.MongoProjectionField{Path: e.Key, Mode: mode})
	}
	for _, e := range s {
		if _, ok := e.Value.(bool); ok {
			return nil, unsupported("sort", e.Key, sort)
		}
		n, ok := integer(e.Value)
		if !ok || (n != 1 && n != -1) {
			return nil, unsupported("sort", e.Key, sort)
		}
		m.Sort = append(m.Sort, &pb.MongoSortField{Path: e.Key, Descending: n < 0})
	}
	return m, nil
}
func integer(v any) (int64, bool) {
	switch n := v.(type) {
	case int32:
		return int64(n), true
	case int64:
		return n, true
	case float64:
		if n == float64(int64(n)) {
			return int64(n), true
		}
	case bool:
		if n {
			return 1, true
		}
		return 0, true
	}
	return 0, false
}
func raw(d bson.D) (*pb.MongoCondition, error) {
	s, err := encode(d)
	if err != nil {
		return nil, err
	}
	return &pb.MongoCondition{Node: &pb.MongoCondition_RawEjson{RawEjson: s}}, nil
}
func parseCondition(d bson.D) (*pb.MongoCondition, error) {
	if len(d) == 0 {
		return raw(d)
	}
	if len(d) != 1 {
		children := make([]*pb.MongoCondition, 0, len(d))
		for _, e := range d {
			c, err := parseCondition(bson.D{e})
			if err != nil {
				return nil, err
			}
			children = append(children, c)
		}
		return &pb.MongoCondition{Node: &pb.MongoCondition_Group{Group: &pb.MongoConditionGroup{Op: pb.MongoBoolOp_MONGO_BOOL_OP_AND, Children: children}}}, nil
	}
	e := d[0]
	if strings.HasPrefix(e.Key, "$") {
		var op pb.MongoBoolOp
		switch e.Key {
		case "$and":
			op = pb.MongoBoolOp_MONGO_BOOL_OP_AND
		case "$or":
			op = pb.MongoBoolOp_MONGO_BOOL_OP_OR
		case "$nor":
			op = pb.MongoBoolOp_MONGO_BOOL_OP_NOR
		default:
			return raw(d)
		}
		a, ok := e.Value.(bson.A)
		if !ok || len(a) == 0 {
			return raw(d)
		}
		children := make([]*pb.MongoCondition, 0, len(a))
		for _, v := range a {
			child, ok := v.(bson.D)
			if !ok {
				return raw(d)
			}
			c, err := parseCondition(child)
			if err != nil {
				return nil, err
			}
			children = append(children, c)
		}
		return &pb.MongoCondition{Node: &pb.MongoCondition_Group{Group: &pb.MongoConditionGroup{Op: op, Children: children}}}, nil
	}
	op := pb.MongoOperator_MONGO_OPERATOR_EQ
	operand := e.Value
	negated := false
	options := ""
	if fields, ok := operand.(bson.D); ok && len(fields) > 0 && strings.HasPrefix(fields[0].Key, "$") {
		if len(fields) == 1 && fields[0].Key == "$not" {
			negated = true
			var ok bool
			fields, ok = fields[0].Value.(bson.D)
			if !ok {
				return raw(d)
			}
		}
		if len(fields) == 2 && fields[0].Key == "$options" && fields[1].Key == "$regex" {
			fields = bson.D{fields[1], fields[0]}
		}
		if !negated && len(fields) > 1 && (len(fields) != 2 || fields[0].Key != "$regex" || fields[1].Key != "$options") {
			children := make([]*pb.MongoCondition, 0, len(fields))
			for _, part := range fields {
				child, err := parseCondition(bson.D{{Key: e.Key, Value: bson.D{part}}})
				if err != nil {
					return nil, err
				}
				if child.GetField() == nil {
					return raw(d)
				}
				children = append(children, child)
			}
			return &pb.MongoCondition{Node: &pb.MongoCondition_Group{Group: &pb.MongoConditionGroup{Op: pb.MongoBoolOp_MONGO_BOOL_OP_AND, Children: children}}}, nil
		}
		if len(fields) == 0 || len(fields) > 2 {
			return raw(d)
		}
		key := fields[0].Key
		found := false
		if key == "$eq" {
			found = true
		} else {
			for k, v := range operators {
				if v == key {
					op = k
					found = true
					break
				}
			}
		}
		if !found {
			return raw(d)
		}
		operand = fields[0].Value
		if !validOperand(op, operand) {
			return raw(d)
		}
		if key == "$eq" {
			if _, isRegex := operand.(bson.Regex); isRegex {
				return raw(d)
			}
		}
		if len(fields) == 2 {
			if key != "$regex" || fields[1].Key != "$options" {
				return raw(d)
			}
			var ok bool
			options, ok = fields[1].Value.(string)
			if !ok {
				return raw(d)
			}
		}
	}
	text, err := valueText(operand)
	if err != nil {
		return nil, err
	}
	return &pb.MongoCondition{Node: &pb.MongoCondition_Field{Field: &pb.MongoFieldCondition{Path: e.Key, Op: op, ValueEjson: text, RegexOptions: options, Negated: negated}}}, nil
}
