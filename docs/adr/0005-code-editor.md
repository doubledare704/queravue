# ADR 0005 — SQL editor: re_editor

**Status:** Accepted · 2026-11-05

## Context
ROADMAP It. 2 needs a SQL editor with syntax highlighting, run statement or selection, and cancel. It. 8 adds schema-aware autocomplete (≤ 50 ms, PRD) and richer editing. The editor must stay responsive on large scripts and must let us render our own completion popup, fed by schema metadata from core. Candidates: `re_editor` and `flutter_code_editor`.

## Spike
Code is in `spikes/editor/`; method is in `spikes/README.md`.

- **Setup:** profile build, macOS 27.2, Apple M4 Pro, window 1440×900, Flutter 3.47.9.
- **Input:** a generated 5,000-line SQL script (DDL, CTEs, joins, window functions, comments, strings).
- **Scenario:** load the script, then type 207 characters at line 2,500 through each editor's own editing path, with one frame per keystroke. Then wheel-scroll 200 frames, find "JOIN", replace-all, type a completion prefix through the platform text-input channel, and switch theme.

## Results
"Keystroke latency" is the time from one edit to the end of the frame that shows it. On a 120 Hz display, about 8 ms of that is waiting for vsync.

| | re_editor 0.10.0 | flutter_code_editor 0.3.5 |
|---|---|---|
| Open 5,000 lines, first frame | **24–37 ms** | 2,531 ms (one 2.5 s frame) |
| Memory after load (RSS delta) | **+49 MB** | +495 MB (peak 1.4 GB during the run) |
| Keystroke latency p50 / p90 / worst | **8.3 / 8.6 / 10.4 ms** (UI work ≈ 1.1 ms p50, 2.2 ms worst) | **4,174 / 4,363 / 4,363 ms**: only 16 keystrokes got through before the 60 s cap |
| Wheel scroll, UI p90 / worst | **1.3 / 2.3 ms** | 57.8 / 67.2 ms (every frame > 16 ms) |
| Highlighting | SQL via re_highlight (highlight.js port), computed off the UI thread in an isolate; light/dark from `CodeHighlightTheme` | SQL via `highlight`, recomputed for the **whole document on the UI thread** on every edit (the cause of the 4 s keystrokes) |
| Rendering model | per-line paragraphs, only visible lines laid out | one `TextField` holding the whole document |
| Find | yes; regex and case toggles; 119 matches in 12 ms | yes; 119 matches in 57 ms |
| Replace / replace all | **yes** (replace-all of 119 in 24 ms) | **no** |
| Multi-cursor / column selection | no (single `CodeLineSelection`) | no (single `TextSelection`) |
| Custom completion popup | **yes**: `CodeAutocomplete.viewBuilder` returns our widget; prompts come from a `CodeAutocompletePromptsBuilder` | no: the popup is a private built-in `Popup`; only the word list can be changed |
| Popup opens on typed input (spike check) | **yes, confirmed manually**: typing `cust` on an empty line shows our `viewBuilder` popup. The automated test could not open it: programmatic edits don't trigger it by design, and typing through `TestTextInput` didn't either | n/a |
| Other hooks we need | `shortcutsActivatorsBuilder` / `shortcutOverrideActions` (Run, Run selection, Cancel), `findBuilder` (own find bar), `indicatorBuilder` (gutter), code folding, read-only mode | `onChanged`, gutter style |
| License | MIT (Reqable) | Apache-2.0 / MIT (Akvelon) |
| Last release | 2026-07 | 2025-09 |

Light and dark snapshots are in `spikes/editor/build/perf/*_{light,dark}.png`.

## Decision
Use **`re_editor`** (with `re_highlight` for SQL grammars) for the SQL editor in `app/lib/features/editor/`.

- Completions: we own the popup (`viewBuilder`) and the prompt builder. `CodeAutocompletePromptsBuilder.build` is synchronous, so prompts are computed from a schema cache that core fills ahead of time (tables, columns, functions per connection) rather than from a per-keystroke RPC. This also keeps us inside the 50 ms autocomplete budget.
- Run statement, run selection and cancel are bound through `shortcutOverrideActions` and exposed in the command palette.
- Statement splitting for "run statement under cursor" is done in core, which knows each engine's dialect. The editor only sends text plus cursor offset.

## Consequences
- **Multi-cursor is missing in both candidates.** If we want it (It. 8 "editor intelligence"), we contribute it upstream or maintain a fork. re_editor's single-selection model makes that a non-trivial change. Track it as an It. 8 risk.
- Completions only open on real text input (`_onCodeUserInputChanged`), not on programmatic edits. A manual check confirmed the custom popup works. The spike could not drive it from an automated test, so It. 8 must work out how widget tests can trigger it.
- re_editor is mainly maintained by one company (Reqable). It is MIT, so a fork is possible if it stalls.
- Highlighting runs in an isolate, so very large files show plain text for a moment before colours appear. That is acceptable, and it is what keeps typing at about 1 ms of UI work.

- **No range decorations (found in Iteration 2).** re_editor can only highlight its own selection and find matches, so the statement that ran or failed is marked in the gutter (▸ ran, ✕ failed, via `DefaultCodeLineNumber.customLineIndex2Text`) and a failure moves the caret to the position the server reported. A real underline would need an upstream change or a fork.

## Alternatives considered
- **flutter_code_editor:** rejected. Every keystroke re-highlights and re-lays out the whole document on the UI thread (4.2 s per keystroke on 5k lines). It also has no replace and its completion popup can't be customised.
- **Wrapping a web editor (Monaco/CodeMirror) in a webview:** out of scope by ADR 0001 (no webview).
