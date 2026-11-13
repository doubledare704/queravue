# Testing

## Unit and widget tests
- Core: `make test-core` (`go test -race ./...`). Integration tests: `make test-integration`, against the docker databases.
- App: `make test-app` (`flutter test`), with fake repositories in `app/test/support/`.

## End-to-end tests (real app and core)
`app/integration_test/` runs the macOS app with the real core. Start them through `make` (`make test-e2e-diagram-design`, `make test-e2e-panels`, …), which builds the core and sets the environment they need.

### Why the window must stay visible
In the live test binding, every `tester.pump` asks the engine for a frame and waits until the engine draws it. macOS draws no frames for a hidden window (verified by hiding the app mid-run), and likely none for one fully covered or on a sleeping display, so the pump never returns. The run then fails after the test timeout with `'!_expectingFrame': is not true`.

This was the hang first blamed on `pumpAndSettle` in Iteration 9. A probe showed the app schedules no frames once it is idle, so `pumpAndSettle` has nothing to wait for. Hiding the app during a run made the next pump hang every time.

`flutter test -d macos` cannot always bring the app forward ("Failed to foreground app"). With `QUERAVUE_E2E=1` the app (`app/macos/Runner/MainFlutterWindow.swift`) does it itself:
- comes to the front;
- floats its window above other windows, on every Space, including over a full-screen app;
- unhides itself if hidden;
- holds an activity that stops App Nap and display sleep.

The Makefile targets and the CI jobs set the variable. The app ignores it otherwise.

Still seen once, before the window joined every Space: a few panel runs took 1 to 2.5 minutes instead of 5 s, one of them past the 3-minute timeout. The display was on (another app held a video wake lock), so the likely cause is a full-screen app on another Space. If a run is much slower than usual, check that the app window is on screen.

### Waiting in a test
- `settle(tester)` in `integration_test/support/settle.dart` is `pumpAndSettle` that fails after 20 s with the likely reason, instead of hanging for the whole timeout. Use it after taps and other UI-only steps.
- `pumpAndSettle` does not wait for calls to the core: it returns as soon as no frame is scheduled. Wait for those explicitly:
  - when the result shows in the UI, use a per-file `_pumpUntil` with a condition on providers or widgets;
  - when only the core knows it, use `pumpUntilServer` with an async check.
