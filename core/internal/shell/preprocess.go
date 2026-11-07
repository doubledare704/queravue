package shell

import (
	"regexp"
	"strings"
)

var (
	useLine  = regexp.MustCompile(`^(\s*)use\s+([A-Za-z0-9_.$-]+)\s*;?\s*$`)
	showLine = regexp.MustCompile(`^(\s*)show\s+([A-Za-z]+)\s*;?\s*$`)
)

// rewriteShellLines turns the mongosh line forms `use name` and `show what`
// into calls, keeping line numbers intact.
func rewriteShellLines(code string) string {
	if !strings.Contains(code, "use") && !strings.Contains(code, "show") {
		return code
	}
	lines := strings.Split(code, "\n")
	for i, line := range lines {
		if m := useLine.FindStringSubmatch(line); m != nil {
			lines[i] = m[1] + `use("` + m[2] + `");`
		} else if m := showLine.FindStringSubmatch(line); m != nil {
			lines[i] = m[1] + `show("` + m[2] + `");`
		}
	}
	return strings.Join(lines, "\n")
}
