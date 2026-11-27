package dataformat

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"slices"
	"unicode/utf8"

	"github.com/doubledare704/queravue/core/internal/engine"
)

type jsonFrames struct {
	*input
	opts                              Options
	data                              []byte
	started, closed, afterComma, done bool
}

func (f *jsonFrames) next(ctx context.Context) ([]byte, position, error) {
	f.ctx = ctx
	for {
		data, start, err := f.frame()
		if err != nil {
			return nil, start, err
		}
		for i := 0; i < len(data); {
			r, n := utf8.DecodeRune(data[i:])
			if r == 0 || r == utf8.RuneError && n == 1 {
				return nil, start, relativePosition(start, data[:i]).failure(errEncoding)
			}
			i += n
		}
		if f.opts.Format == JSON || len(bytes.Trim(data, " \r\t\n")) != 0 {
			return data, start, nil
		}
	}
}

func (f *jsonFrames) frame() ([]byte, position, error) {
	f.data = f.data[:0]
	if f.done {
		return nil, f.pos, io.EOF
	}
	start := f.pos
	var b byte
	var err error
	if f.opts.Format == JSON {
		b, start, err = f.arrayStart()
		if err != nil {
			return nil, start, err
		}
	} else {
		b, err = f.readByte()
		if err != nil {
			return nil, start, frameReadError(err)
		}
	}
	depth := 0
	inString, escaped, tooLarge := false, false, false
	for f.opts.Format != NDJSON || b != '\n' {
		if f.opts.Format == JSON {
			if !inString && depth == 0 && (b == ',' || b == ']') {
				f.afterComma, f.closed = b == ',', b == ']'
				break
			}
			switch {
			case escaped:
				escaped = false
			case inString && b == '\\':
				escaped = true
			case b == '"':
				inString = !inString
			case !inString && (b == '[' || b == '{'):
				depth++
			case !inString && depth > 0 && (b == ']' || b == '}'):
				depth--
			}
		}
		if len(f.data) < f.opts.MaxRecordBytes {
			f.data = append(f.data, b)
		} else {
			tooLarge = true
		}
		b, err = f.readByte()
		if err == nil {
			continue
		}
		if errors.Is(err, io.EOF) {
			if f.opts.Format == NDJSON {
				break
			}
			f.done = true
			return nil, start, f.pos.failure(io.ErrUnexpectedEOF)
		}
		f.done = true
		return nil, start, frameReadError(err)
	}
	if tooLarge {
		return nil, start, start.failure(errRecordSize)
	}
	return f.data, start, nil
}

func (f *jsonFrames) arrayStart() (byte, position, error) {
	b, pos, err := f.nonSpace()
	if f.closed {
		f.done = true
		if err == nil {
			return 0, pos, pos.failure(errors.New("unexpected data after JSON array"))
		}
		return 0, pos, frameReadError(err)
	}
	if !f.started {
		if err == nil && b != '[' {
			f.done = true
			return 0, pos, pos.failure(errors.New("expected JSON array"))
		}
		if err == nil {
			f.started = true
			b, pos, err = f.nonSpace()
		}
	}
	if err != nil {
		f.done = true
		if errors.Is(err, io.EOF) {
			return 0, pos, pos.failure(io.ErrUnexpectedEOF)
		}
		return 0, pos, frameReadError(err)
	}
	if b == ']' {
		f.closed = true
		if f.afterComma {
			return 0, pos, pos.failure(errors.New("trailing comma in JSON array"))
		}
		return f.arrayStart()
	}
	return b, pos, nil
}

func (f *jsonFrames) nonSpace() (byte, position, error) {
	for {
		pos := f.pos
		b, err := f.readByte()
		if err != nil || b != ' ' && b != '\t' && b != '\r' && b != '\n' {
			return b, pos, err
		}
	}
}

func frameReadError(err error) error {
	if errors.Is(err, io.EOF) {
		return io.EOF
	}
	return fmt.Errorf("dataformat: read JSON record: %w", err)
}

func relativePosition(start position, prefix []byte) position {
	start.offset += int64(len(prefix))
	if last := bytes.LastIndexByte(prefix, '\n'); last >= 0 {
		start.line += int64(bytes.Count(prefix, []byte{'\n'}))
		start.column = int64(len(prefix) - last)
	} else {
		start.column += int64(len(prefix))
	}
	return start
}

func jsonError(start position, data []byte, err error) error {
	var syntax *json.SyntaxError
	if errors.As(err, &syntax) {
		start = relativePosition(start, data[:min(len(data), max(0, int(syntax.Offset)-1))])
	}
	return start.failure(err)
}

type objectReader struct {
	frames    jsonFrames
	reader    *Reader
	projected bool
}

func (r *objectReader) read(ctx context.Context) ([]engine.Value, int, error) {
	data, start, err := r.frames.next(ctx)
	if err != nil {
		return nil, 0, err
	}
	obj, err := decodeObject(data, start, r.frames.opts.MaxRecordBytes)
	if err != nil {
		return nil, 0, err
	}
	columns := r.reader.columns
	if !r.reader.ready {
		columns = make([]string, 0, len(obj))
		for name := range obj {
			columns = append(columns, name)
		}
		slices.Sort(columns)
	}
	size := len(data) + len(columns)*valueBudget + 1
	if size > r.frames.opts.MaxRecordBytes {
		return nil, 0, start.failure(errRecordSize)
	}
	row := make([]engine.Value, len(columns))
	for i, name := range columns {
		if raw, ok := obj[name]; ok {
			row[i], err = jsonValue(raw)
			if err != nil {
				return nil, 0, start.failure(fmt.Errorf("decode column %q: %w", name, err))
			}
			delete(obj, name)
		}
	}
	if !r.projected && len(obj) > 0 {
		return nil, 0, start.failure(errors.New("JSON object has fields outside the selected columns"))
	}
	r.reader.columns, r.reader.ready = columns, true
	return row, size, nil
}

func decodeObject(data []byte, start position, limit int) (map[string]json.RawMessage, error) {
	trimmed := bytes.TrimLeft(data, " \r\n\t")
	if len(trimmed) == 0 || trimmed[0] != '{' {
		return nil, start.failure(errors.New("expected JSON object"))
	}
	// Validate the full frame so decoder offsets refer to the start of the record.
	var checked json.RawMessage
	if err := json.Unmarshal(data, &checked); err != nil {
		return nil, jsonError(start, data, fmt.Errorf("decode JSON object: %w", err))
	}
	dec := json.NewDecoder(bytes.NewReader(checked))
	_, _ = dec.Token()
	obj := make(map[string]json.RawMessage)
	for dec.More() {
		offset := dec.InputOffset()
		key, err := dec.Token()
		if err != nil {
			return nil, jsonError(start, data, fmt.Errorf("decode JSON key: %w", err))
		}
		name, ok := key.(string)
		_, duplicate := obj[name]
		if !ok || duplicate {
			return nil, relativePosition(start, data[:offset+int64(len(data)-len(trimmed))]).failure(errors.New("invalid or duplicate JSON object key"))
		}
		if len(data)+(len(obj)+1)*valueBudget+1 > limit {
			return nil, start.failure(errRecordSize)
		}
		var value json.RawMessage
		if err := dec.Decode(&value); err != nil {
			return nil, jsonError(start, data, fmt.Errorf("decode JSON value: %w", err))
		}
		obj[name] = value
	}
	return obj, nil
}

func jsonValue(raw []byte) (engine.Value, error) {
	switch raw[0] {
	case '"':
		var s string
		if err := json.Unmarshal(raw, &s); err != nil {
			return engine.Null(), fmt.Errorf("decode JSON string: %w", err)
		}
		return engine.Text(s), nil
	case 't', 'f':
		return engine.Bool(raw[0] == 't'), nil
	case 'n':
		return engine.Null(), nil
	case '{', '[':
		return engine.JSON(string(raw)), nil
	default:
		return numberValue(string(raw)), nil
	}
}
