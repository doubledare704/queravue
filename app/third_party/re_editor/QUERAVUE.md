# re_editor 0.10.0, vendored

Upstream: https://pub.dev/packages/re_editor (MIT, Reqable). Only `lib/`, the
license and the package metadata are copied.

Patches, all in `lib/src/_code_editable.dart`:
- `_onCodeUserInputChanged` opened the autocomplete popup after
  `Future.delayed(50 ms)`. The popup now opens in the post-frame callback of the frame that
  laid out the typed text (a microtask is too early: the caret position of the new
  text is not known yet). The 50 ms alone used the whole keystroke-to-popup budget
  (ADR 0015, `docs/editor.md`).

- `_CodeCursorBlinkController.startBlink` ignores calls after `dispose`. A focus
  change while the editor is torn down restarted the blink timer on a disposed
  controller and threw from the timer.

To update: copy the new upstream `lib/`, re-apply the patch, bump the version
here and in `pubspec.yaml`.
