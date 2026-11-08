package completion

import (
	"strings"
	"unicode"
)

// Match classes, best first.
const (
	matchPrefix = iota
	matchWord
	matchSubstring
	matchFuzzy
)

func lower(s string) string { return strings.ToLower(s) }

// matchName reports how name matches the typed prefix, case-insensitively:
// prefix, then the start of a word inside the name or the initials of its
// words (camelCase and underscore words), then any substring, then any
// subsequence.
func matchName(prefix, name string) (class int, ok bool) {
	if prefix == "" {
		return matchPrefix, true
	}
	p, n := []rune(lower(prefix)), []rune(lower(name))
	if hasRunePrefix(n, p) {
		return matchPrefix, true
	}
	if wordMatch(p, splitWords(name)) {
		return matchWord, true
	}
	if hasRuneSubstring(n, p) {
		return matchSubstring, true
	}
	if isSubsequence(p, n) {
		return matchFuzzy, true
	}
	return 0, false
}

func hasRunePrefix(s, prefix []rune) bool {
	if len(prefix) > len(s) {
		return false
	}
	for i := range prefix {
		if s[i] != prefix[i] {
			return false
		}
	}
	return true
}

func hasRuneSubstring(s, sub []rune) bool {
	for i := 0; i+len(sub) <= len(s); i++ {
		if hasRunePrefix(s[i:], sub) {
			return true
		}
	}
	return false
}

func isSubsequence(p, s []rune) bool {
	i := 0
	for _, r := range s {
		if i < len(p) && r == p[i] {
			i++
		}
	}
	return i == len(p)
}

func splitWords(name string) [][]rune {
	var words [][]rune
	var cur []rune
	flush := func() {
		if len(cur) > 0 {
			words = append(words, cur)
			cur = nil
		}
	}
	rs := []rune(name)
	for i, r := range rs {
		switch {
		case r == '_' || r == '-' || r == ' ' || r == '.' || r == '$':
			flush()
			continue
		case unicode.IsUpper(r) && i > 0 && (unicode.IsLower(rs[i-1]) || unicode.IsDigit(rs[i-1])):
			flush()
		case unicode.IsDigit(r) && i > 0 && !unicode.IsDigit(rs[i-1]):
			flush()
		}
		cur = append(cur, unicode.ToLower(r))
	}
	flush()
	return words
}

// wordMatch reports whether p is spelled by prefixes of consecutive words,
// starting at any word, with each used word contributing at least one rune.
func wordMatch(p []rune, words [][]rune) bool {
	for start := range words {
		if consume(p, words, start) {
			return true
		}
	}
	return false
}

func consume(p []rune, words [][]rune, at int) bool {
	if len(p) == 0 {
		return true
	}
	if at >= len(words) {
		return false
	}
	w := words[at]
	for k := min(len(w), len(p)); k >= 1; k-- {
		if hasRunePrefix(w, p[:k]) && consume(p[k:], words, at+1) {
			return true
		}
	}
	return false
}
