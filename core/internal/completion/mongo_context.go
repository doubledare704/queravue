package completion

type mongoKind int

const (
	mongoNone mongoKind = iota
	mongoDBMembers
	mongoCollectionMethods
	mongoCursorMethods
	mongoKeys
	mongoGlobals
)

type memberSeg struct {
	name string
	call bool
	arg  string
}

type mongoFrame struct {
	kind      byte
	segs      []memberSeg
	arg       int
	key       string
	expectKey bool
	curKey    string
}

type mongoContext struct {
	Kind         mongoKind
	Prefix       string
	ReplaceStart int
	ReplaceEnd   int
	Quoted       bool
	Collection   string
	Role         mongoRole
	Chain        []string
}

type mongoRole int

const (
	roleNone mongoRole = iota
	roleFilter
	roleProjection
	roleSort
	roleUpdate
	rolePipeline
)

var (
	filterFirstArg  = nameSet("find findOne count countDocuments deleteOne deleteMany updateOne updateMany replaceOne findOneAndUpdate findOneAndDelete findOneAndReplace remove")
	updateSecondArg = nameSet("updateOne updateMany findOneAndUpdate update")
	cursorStarters  = nameSet("find aggregate watch")
)

func analyzeMongo(text string, cursor int) mongoContext {
	ctx := mongoContext{ReplaceStart: cursor, ReplaceEnd: cursor}
	lexed := lexJS(text[:cursor])
	if lexed.inComment {
		return ctx
	}
	toks := lexed.tokens
	if n := len(toks); n > 0 && toks[n-1].end == cursor {
		last := toks[n-1]
		switch {
		case last.kind == jsIdent:
			ctx.Prefix, ctx.ReplaceStart = last.text, last.start
			toks = toks[:n-1]
		case last.kind == jsString && last.open:
			ctx.Prefix, ctx.ReplaceStart, ctx.Quoted = last.text[1:], last.start, true
			toks = toks[:n-1]
		case last.kind == jsString || last.kind == jsNumber || last.kind == jsRegex:
			return ctx
		}
	}
	if n := len(toks); n > 0 && toks[n-1].kind == jsString && toks[n-1].open || n > 0 && toks[n-1].kind == jsRegex && toks[n-1].open {
		return ctx
	}
	frames := structure(toks)
	if top := topFrame(frames); top != nil && top.kind == '{' && top.expectKey {
		if !ctx.Quoted {
			extendDottedPrefix(&ctx, toks)
		}
		ctx.Kind = mongoKeys
		resolveKeyRole(&ctx, frames)
		return ctx
	}
	if n := len(toks); n > 1 && toks[n-1].kind == jsPunct && toks[n-1].text == "." {
		return classifyMember(ctx, memberChain(toks[:n-1]))
	}
	if n := len(toks); n == 1 && toks[0].kind == jsPunct && toks[0].text == "." {
		return ctx
	}
	if len(frames) == 0 && ctx.Prefix != "" && !ctx.Quoted {
		ctx.Kind = mongoGlobals
	}
	return ctx
}

func extendDottedPrefix(ctx *mongoContext, toks []jsToken) {
	for n := len(toks); n >= 2; n -= 2 {
		dot, word := toks[n-1], toks[n-2]
		if dot.kind != jsPunct || dot.text != "." || dot.end != ctx.ReplaceStart || word.kind != jsIdent || word.end != dot.start {
			return
		}
		ctx.Prefix, ctx.ReplaceStart = word.text+"."+ctx.Prefix, word.start
	}
}

func topFrame(frames []mongoFrame) *mongoFrame {
	if len(frames) == 0 {
		return nil
	}
	return &frames[len(frames)-1]
}

func structure(toks []jsToken) []mongoFrame {
	var frames []mongoFrame
	parentKey := func() string {
		top := topFrame(frames)
		switch {
		case top == nil:
			return ""
		case top.kind == '{' && !top.expectKey:
			return top.curKey
		case top.kind == '[':
			return top.key
		}
		return ""
	}
	for i, t := range toks {
		top := topFrame(frames)
		if t.kind != jsPunct {
			if top != nil && top.kind == '{' && top.expectKey && (t.kind == jsIdent || t.kind == jsString || t.kind == jsNumber) {
				top.curKey = unquoteJS(t.text)
				if t.kind == jsIdent || t.kind == jsNumber {
					top.curKey = t.text
				}
			}
			continue
		}
		switch t.text {
		case "(":
			frames = append(frames, mongoFrame{kind: '(', segs: memberChain(toks[:i])})
		case "[":
			frames = append(frames, mongoFrame{kind: '[', key: parentKey()})
		case "{":
			frames = append(frames, mongoFrame{kind: '{', key: parentKey(), expectKey: true})
		case ")", "]", "}":
			frames = popMatching(frames, t.text)
		case ",":
			if top != nil && top.kind == '(' {
				top.arg++
			} else if top != nil && top.kind == '{' {
				top.expectKey, top.curKey = true, ""
			}
		case ":":
			if top != nil && top.kind == '{' && top.expectKey && top.curKey != "" {
				top.expectKey = false
			}
		}
	}
	return frames
}

func popMatching(frames []mongoFrame, closer string) []mongoFrame {
	want := map[string]byte{")": '(', "]": '[', "}": '{'}[closer]
	for i := len(frames) - 1; i >= 0; i-- {
		if frames[i].kind == want {
			return frames[:i]
		}
	}
	return frames
}

func memberChain(toks []jsToken) []memberSeg {
	var segs []memberSeg
	i := len(toks) - 1
	for i >= 0 {
		var seg memberSeg
		t := toks[i]
		switch {
		case t.kind == jsPunct && t.text == ")":
			open := matchingOpen(toks, i, "(", ")")
			if open < 1 || toks[open-1].kind != jsIdent {
				return nil
			}
			seg = memberSeg{name: toks[open-1].text, call: true, arg: soleStringArg(toks[open+1 : i])}
			i = open - 1
		case t.kind == jsPunct && t.text == "]":
			open := matchingOpen(toks, i, "[", "]")
			if open < 0 || i-open != 2 || toks[open+1].kind != jsString {
				return nil
			}
			segs = append([]memberSeg{{name: unquoteJS(toks[open+1].text)}}, segs...)
			i = open - 1
			continue
		case t.kind == jsIdent:
			seg = memberSeg{name: t.text}
		default:
			return nil
		}
		segs = append([]memberSeg{seg}, segs...)
		if i >= 1 && toks[i-1].kind == jsPunct && toks[i-1].text == "." {
			i -= 2
			continue
		}
		break
	}
	return segs
}

func matchingOpen(toks []jsToken, closeAt int, open, closer string) int {
	depth := 0
	for i := closeAt; i >= 0; i-- {
		if toks[i].kind != jsPunct {
			continue
		}
		switch toks[i].text {
		case closer:
			depth++
		case open:
			depth--
			if depth == 0 {
				return i
			}
		}
	}
	return -1
}

func soleStringArg(toks []jsToken) string {
	if len(toks) == 1 && toks[0].kind == jsString {
		return unquoteJS(toks[0].text)
	}
	return ""
}

func classifyMember(ctx mongoContext, segs []memberSeg) mongoContext {
	if len(segs) == 0 || segs[0].name != "db" || segs[0].call {
		return ctx
	}
	if len(segs) == 1 {
		ctx.Kind = mongoDBMembers
		return ctx
	}
	if name := collectionOf(segs); name != "" {
		ctx.Collection = name
	}
	if len(segs) == 2 && (segs[1].call && segs[1].name != "getCollection" || !segs[1].call && dbMethodNames[segs[1].name]) {
		return ctx
	}
	if len(segs) == 2 {
		ctx.Kind = mongoCollectionMethods
		return ctx
	}
	for _, s := range segs[2:] {
		if s.call && cursorStarters[s.name] {
			ctx.Kind = mongoCursorMethods
			return ctx
		}
	}
	return ctx
}

func collectionOf(segs []memberSeg) string {
	if len(segs) < 2 || segs[0].name != "db" {
		return ""
	}
	if segs[1].call {
		if segs[1].name == "getCollection" {
			return segs[1].arg
		}
		return ""
	}
	if dbMethodNames[segs[1].name] {
		return ""
	}
	return segs[1].name
}

func resolveKeyRole(ctx *mongoContext, frames []mongoFrame) {
	paren := -1
	for i := len(frames) - 1; i >= 0; i-- {
		if frames[i].kind == '(' {
			paren = i
			break
		}
	}
	inner := frames[paren+1:]
	if paren < 0 {
		ctx.Role = roleFilter
	} else {
		p := frames[paren]
		ctx.Collection = collectionOf(p.segs)
		ctx.Role = roleOfCall(p)
	}
	root := 0
	if ctx.Role == rolePipeline {
		root = 1
		if len(inner) < 2 || inner[0].kind != '[' {
			ctx.Role = roleNone
			return
		}
	}
	if len(inner) <= root || inner[root].kind != '{' {
		ctx.Role = roleNone
		return
	}
	for _, f := range inner[root+1:] {
		if f.kind == '{' {
			ctx.Chain = append(ctx.Chain, f.key)
		}
	}
}

func roleOfCall(p mongoFrame) mongoRole {
	if len(p.segs) == 0 {
		return roleNone
	}
	name := p.segs[len(p.segs)-1].name
	switch {
	case name == "aggregate" && p.arg == 0:
		return rolePipeline
	case filterFirstArg[name] && p.arg == 0:
		return roleFilter
	case (name == "find" || name == "findOne") && p.arg == 1, name == "projection" && p.arg == 0:
		return roleProjection
	case updateSecondArg[name] && p.arg == 1:
		return roleUpdate
	case name == "distinct" && p.arg == 1:
		return roleFilter
	case name == "sort" && p.arg == 0, name == "createIndex" && p.arg == 0:
		return roleSort
	}
	return roleNone
}
