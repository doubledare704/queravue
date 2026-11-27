# Iteration 12: app idle memory, It. 10 against main

Question: why does the release app idle at about 185 MiB RSS (Lane G release run in `iteration-12.md`) when It. 10 recorded 139.4 MiB combined?

Answer: no code change raised it. The same machine, Flutter and macOS give the same idle memory at the It. 10 commits and at main, within 3 MiB RSS. Two measurement effects explain the reported gap:

1. **The 185.1 MiB idle row was sampled while the window's drawables were being reallocated.** Its `footprint` breakdown shows 106 MB of IOSurface (53 MB in every other sample) and 124 MB of transient "owned physical footprint (unmapped) (graphics)", which is also why that row's footprint reads 341.7 MiB (†). Malloc Large was 47 MB (3 regions) and stayed there for the rest of that run, against 20 MB (2 regions) in a clean launch.
2. **The 139.4 MiB It. 10 figure does not reproduce at its own commit.** Rebuilt today, `b1a7289` (the commit that recorded it) idles at 153 to 163 MiB app RSS plus 33 MiB sidecar, 186 to 196 MiB combined. The It. 10 run's script and window state were not recorded. Its number is close to the app's *footprint* alone (136 to 147 MB in round 1 below), but that cannot be confirmed.

So there is nothing to bisect. The app is over the 150 MB combined idle budget at It. 10 as well as at main.

## Method

Apple M4 Pro, built-in Liquid Retina XDR display (3456 × 2234), macOS 27.2.1 (installed 2026-11-11), Flutter 3.47.9 (pinned in CI at every commit measured), 2026-11-27.

Commits:

| Commit | What it is |
|---|---|
| `b1a7289` | Commit whose `iteration-10.md` change recorded 139.4 MiB (Lane G verification) |
| `6ea5e86` | It. 10 close-out: merge of PR #61, after PRs #51 to #59 and the roadmap PR #60 |
| `72dc24e` | `origin/main`, after the iteration 12 close-out |

Each commit was checked out in a scratch worktree and built with `make core` and `flutter build macos --release` (the real `lib/main.dart`; the "Embed queravued" phase puts the sidecar next to the app binary). Each launch used a fresh `mktemp -d` as `QUERAVUE_CONFIG_DIR`, with or without `QUERAVUE_E2E=1`, and nothing else touched the window. At 30 s the sampler read `ps -o rss=` for the app and the sidecar (the app's child `queravued`) and `footprint -p` for the app. The app was then killed. Launches were interleaved across commits and modes. Values are medians of 3 launches.

The harness from Lane G (`app/perf/release_memory_main.dart` at main) was also built and sampled from outside the same way, at 28 s and 34 s, without Docker. Its own idle row read 157.1 MiB RSS and 140.9 MiB footprint.

## Results

Two rounds, 15 minutes apart, landed in two different window-server states with the same binaries. Within each round the commits agree. Between rounds they do not: IOSurface was 53 MB in every round-1 launch and 15 MB in every round-2 launch, and Malloc Large was 20 MB and 28 MB respectively. Footprint fell by about 40 MB from round 1 to round 2 while RSS rose by about 8 MiB.

### Round 1 (IOSurface 53 MB)

| Commit | `QUERAVUE_E2E` | App RSS MiB | App footprint MB | Sidecar RSS MiB | Combined RSS MiB |
|---|---|---:|---:|---:|---:|
| `b1a7289` | 1 | 153.7 | 145 | 33.1 | 186.8 |
| `b1a7289` | unset | 153.3 | 136 | 33.2 | 186.5 |
| `6ea5e86` | 1 | 153.5 | 140 | 32.7 | 186.2 |
| `6ea5e86` | unset | 154.2 | 141 | 33.0 | 187.2 |
| `72dc24e` | 1 | 156.0 | 146 | 33.3 | 189.3 |
| `72dc24e` | unset | 157.3 | 142 | 33.4 | 190.7 |
| harness at `72dc24e`, 28 s | 1 | 155.3 | 147 | 33.1 | 188.4 |

### Round 2 (IOSurface 15 MB)

| Commit | `QUERAVUE_E2E` | App RSS MiB | App footprint MB | Sidecar RSS MiB | Combined RSS MiB |
|---|---|---:|---:|---:|---:|
| `b1a7289` | 1 | 161.7 | 102 | 33.2 | 194.9 |
| `b1a7289` | unset | 162.7 | 102 | 33.2 | 195.9 |
| `6ea5e86` | 1 | 163.5 | 104 | 33.1 | 196.6 |
| `6ea5e86` | unset | 163.1 | 102 | 32.8 | 195.9 |
| `72dc24e` | 1 | 164.4 | 104 | 33.2 | 197.6 |
| `72dc24e` | unset | 163.4 | 103 | 33.0 | 196.4 |

`QUERAVUE_E2E=1` makes no measurable difference at idle. The code at `MainFlutterWindow.swift` only keeps the window floating and on screen, and that code was already present at `b1a7289`.

### Footprint categories

Medians over all six launches of a commit (MB):

| Category | `b1a7289` R1 | `6ea5e86` R1 | `72dc24e` R1 | `b1a7289` R2 | `6ea5e86` R2 | `72dc24e` R2 |
|---|---:|---:|---:|---:|---:|---:|
| IOSurface (window drawables) | 53 | 53 | 53 | 15 | 15 | 15 |
| Malloc Large | 20 | 20 | 20 | 28 | 28 | 28 |
| Malloc Small | 21 | 21 | 22.5 | 21.5 | 23 | 21.5 |
| Untagged (Dart heap) | 14 | 14 | 14 | 15 | 15 | 15 |
| Owned unmapped graphics | 12 | 12 | 12 | not recorded | not recorded | not recorded |

Malloc Small ranges from 20 to 25 MB between launches of the same commit, with no pattern by commit. The Dart heap is the same, and the image cache is empty at idle (0.0 MiB in the harness row).

### What moves the number on an unchanged binary

- **Focus changes.** Launching, then giving focus back to another app, raised Malloc Large from 20 to 28 MB and RSS from 157 to 165 MiB, and both stayed there. Hiding and showing the window did not change IOSurface or Malloc Large. Round 2 may be this state, if the app the measurement ran from took focus back.
- **Resizes.** Resizing the window during startup also left Malloc Large at 28 MB (3 regions). `heap` finds no live block larger than 528 KB, so this is freed memory the allocator keeps (as Lane G found for previews), not retained data.
- **A startup peak.** `heap` reports a physical footprint peak of about 325 MB at launch (413 MB in round 1) at all three commits. The idle number depends on how much of that peak the allocator and the window server keep afterwards.
- **IOSurface 15 versus 53 MB.** The window is 800 × 628 points at every launch. What switched the drawable count between the rounds was not identified: no display, sleep or Space change was logged.

## Proposed next steps (not in this PR)

No code change explains the gap, so there is no fix here. To meet the 150 MB combined budget:

1. **Measure one way.** Record `footprint` (with its category breakdown and `phys_footprint_peak`) and RSS for each sample, keep the window focused and untouched until the sample, and sample several launches. Flag a row whose IOSurface differs from the run's baseline. `dev/perf-release-app.sh` can take this method.
2. **Find the launch-time peak.** A 325 to 413 MB footprint peak during the first seconds sets how much large-block memory the allocator keeps (20 to 47 MB here). Profile startup with Instruments (Allocations and Metal) on a profile build to see whether it comes from first-frame rendering, font loading or sidecar handshake buffers.
3. **Sidecar baseline.** The sidecar is 33 MiB RSS at idle with no connections; with the app at about 155 MiB, the budget is missed by about 40 MiB in either state.
