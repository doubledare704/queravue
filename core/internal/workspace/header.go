package workspace

import (
	"regexp"
	"strings"
)

// Meta is the metadata kept in a script's header comment (ADR 0011).
type Meta struct {
	Title       string
	Description string
	Connection  string
	Tags        []string
}

// IsZero reports whether no field is set.
func (m Meta) IsZero() bool {
	return m.Title == "" && m.Description == "" && m.Connection == "" && len(m.Tags) == 0
}

var headerKeys = []string{"title", "description", "connection", "tags"}

var headerLine = regexp.MustCompile(`^([A-Za-z_][A-Za-z0-9_-]*):[ \t]*(.*)$`)

type headerStyle int

const (
	styleLine headerStyle = iota
	styleBlock
)

type headerBlock struct {
	start, end int
	style      headerStyle
	lines      []string
}

func lineCommentPrefix(k Kind) string {
	if k == KindSQL {
		return "--"
	}
	return "//"
}

func isKnownKey(key string) bool {
	for _, k := range headerKeys {
		if k == key {
			return true
		}
	}
	return false
}

// findHeader locates the leading comment block and reports whether it holds
// at least one known key.
func findHeader(k Kind, content string) (headerBlock, bool) {
	start := 0
	for start < len(content) && strings.ContainsRune(" \t\r\n", rune(content[start])) {
		start++
	}
	rest := content[start:]
	var blk headerBlock
	switch prefix := lineCommentPrefix(k); {
	case strings.HasPrefix(rest, prefix):
		blk = lineBlock(rest, prefix)
	case strings.HasPrefix(rest, "/*"):
		end := strings.Index(rest, "*/")
		if end < 0 {
			return headerBlock{}, false
		}
		inner := rest[2:end]
		blk = headerBlock{end: end + 2, style: styleBlock}
		for _, l := range strings.Split(inner, "\n") {
			l = strings.TrimSpace(l)
			l = strings.TrimSpace(strings.TrimPrefix(l, "*"))
			blk.lines = append(blk.lines, l)
		}
		blk.lines = trimBlankEdges(blk.lines)
	default:
		return headerBlock{}, false
	}
	blk.start, blk.end = start, start+blk.end
	for _, l := range blk.lines {
		if m := headerLine.FindStringSubmatch(l); m != nil && isKnownKey(strings.ToLower(m[1])) {
			return blk, true
		}
	}
	return headerBlock{}, false
}

func lineBlock(rest, prefix string) headerBlock {
	blk := headerBlock{style: styleLine}
	pos := 0
	for pos < len(rest) {
		nl := strings.IndexByte(rest[pos:], '\n')
		lineEnd := len(rest)
		if nl >= 0 {
			lineEnd = pos + nl
		}
		raw := rest[pos:lineEnd]
		line := strings.TrimRight(raw, "\r")
		if !strings.HasPrefix(strings.TrimLeft(line, " \t"), prefix) {
			break
		}
		text := strings.TrimLeft(line, " \t")[len(prefix):]
		blk.lines = append(blk.lines, strings.TrimSpace(text))
		blk.end = pos + len(line)
		pos = lineEnd + 1
	}
	return blk
}

func trimBlankEdges(lines []string) []string {
	for len(lines) > 0 && lines[0] == "" {
		lines = lines[1:]
	}
	for len(lines) > 0 && lines[len(lines)-1] == "" {
		lines = lines[:len(lines)-1]
	}
	return lines
}

// ParseHeader reads the metadata from the header comment of content. A file
// without a header yields the zero Meta.
func ParseHeader(k Kind, content string) Meta {
	blk, ok := findHeader(k, content)
	if !ok {
		return Meta{}
	}
	var m Meta
	for _, l := range blk.lines {
		match := headerLine.FindStringSubmatch(l)
		if match == nil {
			continue
		}
		value := strings.TrimSpace(match[2])
		switch strings.ToLower(match[1]) {
		case "title":
			m.Title = value
		case "description":
			m.Description = value
		case "connection":
			m.Connection = value
		case "tags":
			m.Tags = splitTags(value)
		}
	}
	return m
}

func splitTags(s string) []string {
	var tags []string
	for _, t := range strings.Split(s, ",") {
		if t = strings.TrimSpace(t); t != "" {
			tags = append(tags, t)
		}
	}
	return tags
}

func oneLine(s string) string {
	return strings.TrimSpace(strings.NewReplacer("\r", " ", "\n", " ").Replace(s))
}

func metaValues(m Meta) map[string]string {
	return map[string]string{
		"title": oneLine(m.Title), "description": oneLine(m.Description), "connection": oneLine(m.Connection),
		"tags": oneLine(strings.Join(m.Tags, ", ")),
	}
}

// ApplyHeader returns content with its header comment updated to m. Known
// keys are updated in place, new ones are appended, empty ones are removed;
// other lines of the header and the body are kept. A file without a header
// gets one only if m is not zero.
func ApplyHeader(k Kind, content string, m Meta) string {
	nl := "\n"
	if strings.Contains(content, "\r\n") {
		nl = "\r\n"
	}
	values := metaValues(m)
	blk, found := findHeader(k, content)
	if !found {
		if m.IsZero() {
			return content
		}
		lines := newLines(values, nil, map[string]bool{})
		header := render(k, styleLine, lines, nl)
		if strings.TrimSpace(content) == "" {
			return header + nl
		}
		return header + nl + nl + content
	}
	written := map[string]bool{}
	var lines []string
	for _, l := range blk.lines {
		match := headerLine.FindStringSubmatch(l)
		if match == nil || !isKnownKey(strings.ToLower(match[1])) {
			lines = append(lines, l)
			continue
		}
		key := strings.ToLower(match[1])
		if written[key] || values[key] == "" {
			written[key] = true
			continue
		}
		written[key] = true
		lines = append(lines, key+": "+values[key])
	}
	lines = newLines(values, lines, written)
	if len(lines) == 0 {
		rest := strings.TrimLeft(content[blk.end:], "\r\n")
		return content[:blk.start] + rest
	}
	return content[:blk.start] + render(k, blk.style, lines, nl) + content[blk.end:]
}

func newLines(values map[string]string, lines []string, written map[string]bool) []string {
	for _, key := range headerKeys {
		if !written[key] && values[key] != "" {
			lines = append(lines, key+": "+values[key])
		}
	}
	return lines
}

func render(k Kind, style headerStyle, lines []string, nl string) string {
	var b strings.Builder
	if style == styleBlock {
		b.WriteString("/*" + nl)
		for _, l := range lines {
			b.WriteString(strings.TrimRight(" * "+l, " ") + nl)
		}
		b.WriteString(" */")
		return b.String()
	}
	prefix := lineCommentPrefix(k)
	for i, l := range lines {
		if i > 0 {
			b.WriteString(nl)
		}
		b.WriteString(strings.TrimRight(prefix+" "+l, " "))
	}
	return b.String()
}
