package sqlsplit

import "unicode/utf8"

// OffsetMap converts between byte offsets into a string and UTF-16 code unit
// offsets (what Dart strings and the wire contract use).
type OffsetMap struct {
	text  string
	ascii bool
}

// NewOffsetMap prepares conversions for text.
func NewOffsetMap(text string) OffsetMap {
	ascii := true
	for i := 0; i < len(text); i++ {
		if text[i] >= utf8.RuneSelf {
			ascii = false
			break
		}
	}
	return OffsetMap{text: text, ascii: ascii}
}

// ToUTF16 converts a byte offset (clamped to the text) to UTF-16 units.
func (m OffsetMap) ToUTF16(b int) int {
	b = max(0, min(b, len(m.text)))
	if m.ascii {
		return b
	}
	n := 0
	for i, r := range m.text {
		if i >= b {
			break
		}
		n++
		if r >= 0x10000 {
			n++
		}
	}
	return n
}

// ToByte converts a UTF-16 offset (clamped) to a byte offset. An offset in the
// middle of a surrogate pair maps to the start of that rune.
func (m OffsetMap) ToByte(u int) int {
	if u <= 0 {
		return 0
	}
	if m.ascii {
		return min(u, len(m.text))
	}
	n := 0
	for i, r := range m.text {
		w := 1
		if r >= 0x10000 {
			w = 2
		}
		if n+w > u {
			return i
		}
		n += w
	}
	return len(m.text)
}
