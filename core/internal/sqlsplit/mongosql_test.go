package sqlsplit

import "testing"

func TestMongoSQLTokenize(t *testing.T) {
	tests := []struct {
		name, text string
		want       []TokenKind
	}{
		{"backtick identifier", "`a b`", []TokenKind{TokenQuotedIdent}},
		{"double-quoted identifier", `"a.b"`, []TokenKind{TokenQuotedIdent}},
		{"doubled quote stays in string", `'it''s'`, []TokenKind{TokenString}},
		{"backslash is literal", `'a\' x`, []TokenKind{TokenString, TokenSpace, TokenWord}},
		{"hash is not a comment", "#x", []TokenKind{TokenPunct, TokenWord}},
		{"dollar is not a quote", "$$a$$", []TokenKind{TokenPunct, TokenPunct, TokenWord}},
		{"dash comment", "-- c\n1", []TokenKind{TokenComment, TokenNumber}},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			toks := Tokenize(MongoSQL, tt.text)
			if len(toks) != len(tt.want) {
				t.Fatalf("got %d tokens %v, want %v", len(toks), toks, tt.want)
			}
			for i, tok := range toks {
				if tok.Kind != tt.want[i] {
					t.Errorf("token %d kind = %v, want %v", i, tok.Kind, tt.want[i])
				}
			}
		})
	}
}
