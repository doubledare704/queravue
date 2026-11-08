package format

import "strings"

const keywordList = `SELECT DISTINCT ALL FROM WHERE GROUP BY HAVING ORDER LIMIT OFFSET UNION INTERSECT EXCEPT JOIN INNER LEFT RIGHT FULL
OUTER CROSS NATURAL ON USING AS AND OR NOT IN IS NULL LIKE ILIKE BETWEEN EXISTS ANY SOME CASE WHEN THEN ELSE END INSERT INTO
VALUES UPDATE SET DELETE WITH RECURSIVE ASC DESC NULLS TRUE FALSE RETURNING OVER PARTITION CONFLICT DO NOTHING DUPLICATE TOP
APPLY LATERAL FOR ESCAPE COLLATE FETCH QUALIFY WINDOW REPLACE IGNORE`

const headWordList = `FIRST NEXT SHARE NO KEY NOWAIT PERCENT TIES STRAIGHT_JOIN OUTPUT BROWSE JSON XML SKIP LOCKED ROW ROWS ONLY WITH`

var (
	keywords  = wordSet(keywordList)
	headWords = wordSet(headWordList)
)

func wordSet(list string) map[string]bool {
	set := map[string]bool{}
	for _, w := range strings.Fields(list) {
		set[w] = true
	}
	return set
}

func isKeyword(word string) bool { return keywords[strings.ToUpper(word)] }

func caseChangeable(word string) bool {
	upper := strings.ToUpper(word)
	return keywords[upper] || headWords[upper]
}

var operandKeywords = wordSet(`END NULL TRUE FALSE`)

var functionLikeKeywords = wordSet(`LEFT RIGHT REPLACE IF`)
