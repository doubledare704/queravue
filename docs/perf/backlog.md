# Performance backlog

Items measured or suspected, not scheduled. Check with the `perf-check` skill.

## Grid
- **Fast-scroll text painting.** At 100 new rows per frame the grid costs ~18 ms p90 (ADR 0004 finding 6): one `Text` widget per cell. Options: paragraph cache keyed by (text, style, width), or painting text directly in the `FixedGridView` render object. Out of scope for Iteration 2.
