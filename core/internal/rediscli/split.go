// Package rediscli parses command lines and classifies commands the way
// redis-cli and ADR 0020 expect. It knows nothing about connections.
package rediscli

import (
	"errors"
	"strconv"
)

// ErrUnbalancedQuotes means a quote was opened and never closed, or a closing
// quote is followed by a character other than a space.
var ErrUnbalancedQuotes = errors.New("rediscli: unbalanced quotes")

// Split splits line into arguments with the quoting rules of redis-cli:
// double quotes understand \n \r \t \b \a \xHH and \\ \", single quotes only
// \'. Arguments are separated by spaces, tabs and newlines.
func Split(line string) ([][]byte, error) {
	var args [][]byte
	i := 0
	for {
		for i < len(line) && isSpace(line[i]) {
			i++
		}
		if i >= len(line) {
			return args, nil
		}
		arg, next, err := readArg(line, i)
		if err != nil {
			return nil, err
		}
		args = append(args, arg)
		i = next
	}
}

func readArg(line string, i int) ([]byte, int, error) {
	var arg []byte
	switch line[i] {
	case '"':
		return readDoubleQuoted(line, i+1)
	case '\'':
		return readSingleQuoted(line, i+1)
	}
	for i < len(line) && !isSpace(line[i]) {
		if line[i] == '"' || line[i] == '\'' {
			return nil, 0, ErrUnbalancedQuotes
		}
		arg = append(arg, line[i])
		i++
	}
	return arg, i, nil
}

func readDoubleQuoted(line string, i int) ([]byte, int, error) {
	arg := []byte{}
	for i < len(line) {
		c := line[i]
		switch {
		case c == '\\' && i+3 < len(line) && line[i+1] == 'x' && isHex(line[i+2]) && isHex(line[i+3]):
			b, _ := strconv.ParseUint(line[i+2:i+4], 16, 8)
			arg = append(arg, byte(b))
			i += 4
		case c == '\\' && i+1 < len(line):
			arg = append(arg, unescape(line[i+1]))
			i += 2
		case c == '"':
			return closeQuote(line, arg, i+1)
		default:
			arg = append(arg, c)
			i++
		}
	}
	return nil, 0, ErrUnbalancedQuotes
}

func readSingleQuoted(line string, i int) ([]byte, int, error) {
	arg := []byte{}
	for i < len(line) {
		c := line[i]
		switch {
		case c == '\\' && i+1 < len(line) && line[i+1] == '\'':
			arg = append(arg, '\'')
			i += 2
		case c == '\'':
			return closeQuote(line, arg, i+1)
		default:
			arg = append(arg, c)
			i++
		}
	}
	return nil, 0, ErrUnbalancedQuotes
}

func closeQuote(line string, arg []byte, next int) ([]byte, int, error) {
	if next < len(line) && !isSpace(line[next]) {
		return nil, 0, ErrUnbalancedQuotes
	}
	return arg, next, nil
}

func unescape(c byte) byte {
	switch c {
	case 'n':
		return '\n'
	case 'r':
		return '\r'
	case 't':
		return '\t'
	case 'b':
		return '\b'
	case 'a':
		return '\a'
	}
	return c
}

func isSpace(c byte) bool { return c == ' ' || c == '\t' || c == '\n' || c == '\r' }

func isHex(c byte) bool {
	return c >= '0' && c <= '9' || c >= 'a' && c <= 'f' || c >= 'A' && c <= 'F'
}
