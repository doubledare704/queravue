package mockdata

import (
	"slices"

	"github.com/doubledare704/queravue/core/internal/engine"
)

// TableRelationInfo describes a foreign-key constraint among targets.
type TableRelationInfo struct {
	Child    TargetRef
	Parent   TargetRef
	FK       engine.ForeignKeyDef
	Nullable bool
}

// PlanTables topologically orders targets (parents before children) and reports any cycles.
func PlanTables(targets []TargetRef, relations []TableRelationInfo) ([]TargetRef, []Cycle) {
	if len(targets) == 0 {
		return nil, nil
	}
	indexByKey := make(map[string]int, len(targets))
	for i, t := range targets {
		indexByKey[t.Key()] = i
	}

	type edge struct {
		to   int
		info TableRelationInfo
	}
	adj := make([][]edge, len(targets))
	inDegree := make([]int, len(targets))
	seenPair := map[[2]int]bool{}

	for _, rel := range relations {
		childIdx, okChild := indexByKey[rel.Child.Key()]
		parentIdx, okParent := indexByKey[rel.Parent.Key()]
		if !okChild || !okParent {
			continue
		}
		adj[parentIdx] = append(adj[parentIdx], edge{to: childIdx, info: rel})
		if !seenPair[[2]int{parentIdx, childIdx}] {
			seenPair[[2]int{parentIdx, childIdx}] = true
			inDegree[childIdx]++
		}
	}

	queue := make([]int, 0, len(targets))
	for i := range targets {
		if inDegree[i] == 0 {
			queue = append(queue, i)
		}
	}

	ordered := make([]TargetRef, 0, len(targets))
	placed := make([]bool, len(targets))

	for len(queue) > 0 {
		cur := queue[0]
		queue = queue[1:]
		placed[cur] = true
		ordered = append(ordered, targets[cur])

		for _, e := range adj[cur] {
			if placed[e.to] {
				continue
			}
			// Decrement once per unique (parent, child) pair.
			if seenPair[[2]int{cur, e.to}] {
				seenPair[[2]int{cur, e.to}] = false
				inDegree[e.to]--
				if inDegree[e.to] == 0 {
					queue = insertSorted(queue, e.to)
				}
			}
		}
	}

	if len(ordered) == len(targets) {
		return ordered, nil
	}

	cycles := findCycles(targets, relations, indexByKey, placed)
	for i, t := range targets {
		if !placed[i] {
			ordered = append(ordered, t)
		}
	}
	return ordered, cycles
}

func insertSorted(q []int, val int) []int {
	pos, _ := slices.BinarySearch(q, val)
	return slices.Insert(q, pos, val)
}

func findCycles(targets []TargetRef, relations []TableRelationInfo, indexByKey map[string]int, placed []bool) []Cycle {
	// Walk child -> parent edges among unplaced nodes to extract elementary cycles.
	outEdges := make([][]TableRelationInfo, len(targets))
	for _, rel := range relations {
		ci, okC := indexByKey[rel.Child.Key()]
		pi, okP := indexByKey[rel.Parent.Key()]
		if !okC || !okP || placed[ci] || placed[pi] {
			continue
		}
		outEdges[ci] = append(outEdges[ci], rel)
	}

	var cycles []Cycle
	seenCycleSig := map[string]bool{}

	for start := range targets {
		if placed[start] {
			continue
		}
		path := make([]TableRelationInfo, 0, 8)
		onPath := make([]bool, len(targets))
		visitedFromStart := make([]bool, len(targets))

		var dfs func(u int)
		dfs = func(u int) {
			onPath[u] = true
			for _, rel := range outEdges[u] {
				v := indexByKey[rel.Parent.Key()]
				if v < start {
					continue
				}
				path = append(path, rel)
				if v == start {
					sig := cycleSignature(path)
					if !seenCycleSig[sig] {
						seenCycleSig[sig] = true
						edges := make([]CycleEdge, len(path))
						for i, p := range path {
							edges[i] = CycleEdge{
								Child:          p.Child,
								Parent:         p.Parent,
								ConstraintName: p.FK.Name,
								Nullable:       p.Nullable,
							}
						}
						cycles = append(cycles, Cycle{Edges: edges})
					}
				} else if !onPath[v] && !visitedFromStart[v] {
					dfs(v)
				}
				path = path[:len(path)-1]
			}
			onPath[u] = false
			visitedFromStart[u] = true
		}
		dfs(start)
	}
	return cycles
}

func cycleSignature(rels []TableRelationInfo) string {
	var sig string
	for i, r := range rels {
		if i > 0 {
			sig += "->"
		}
		sig += r.Child.Key() + ":" + r.FK.Name + ":" + r.Parent.Key()
	}
	return sig
}

// CheckSpecCycles returns any runtime foreign-key cycles in spec (excluding
// existing-row lookups, skipped columns, and always-null FKs).
func CheckSpecCycles(spec Spec) []Cycle {
	var targets []TargetRef
	selected := map[string]bool{}
	for _, ts := range spec.Targets {
		if !ts.Target.IsCollection {
			k := ts.Target.Key()
			if !selected[k] {
				selected[k] = true
				targets = append(targets, ts.Target)
			}
		}
	}

	var rels []TableRelationInfo
	for _, ts := range spec.Targets {
		if ts.Target.IsCollection {
			continue
		}
		for _, r := range ts.Rules {
			if r.Kind != RuleForeignKey || r.ForeignKey.FromExistingRows || r.NullRatio >= 1.0 {
				continue
			}
			if !selected[r.ForeignKey.Parent.Key()] {
				continue
			}
			rels = append(rels, TableRelationInfo{
				Child:  ts.Target,
				Parent: r.ForeignKey.Parent,
				FK: engine.ForeignKeyDef{
					Name:              r.ColumnOrPath,
					Columns:           []string{r.ColumnOrPath},
					ReferencedSchema:  r.ForeignKey.Parent.Schema,
					ReferencedTable:   r.ForeignKey.Parent.Name,
					ReferencedColumns: []string{r.ForeignKey.ParentColumn},
				},
				Nullable: r.NullRatio > 0,
			})
		}
	}
	_, cycles := PlanTables(targets, rels)
	return cycles
}
