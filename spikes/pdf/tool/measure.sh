#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
SPIKE_DIR="$PWD"
PERF_DIR="$SPIKE_DIR/build/perf"
FIXTURES_DIR="$SPIKE_DIR/build/fixtures"
BASELINE_DIR="/tmp/queravue_pdf_baseline_$$"
IDLE_SECONDS="${SPIKE_IDLE_SECONDS:-30}"

cleanup() {
  rm -rf "$BASELINE_DIR"
}
trap cleanup EXIT

mkdir -p "$PERF_DIR"

echo "=== 1. Generating PDF fixtures ==="
python3 "$SPIKE_DIR/tool/generate_fixtures.py" --out "$FIXTURES_DIR"

echo "=== 2. Building baseline macOS release app (no pdfrx) ==="
rm -rf "$BASELINE_DIR"
mkdir -p "$BASELINE_DIR"
rsync -a \
  --exclude='build/' \
  --exclude='.dart_tool/' \
  --exclude='macos/Pods/' \
  --exclude='macos/Flutter/ephemeral/' \
  --exclude='lib/pdfrx_preview.dart' \
  --exclude='lib/main.dart' \
  "$SPIKE_DIR/" "$BASELINE_DIR/"
cp "$SPIKE_DIR/lib/main_baseline.dart" "$BASELINE_DIR/lib/main.dart"
python3 -c '
import pathlib, re
p = pathlib.Path("'"$BASELINE_DIR"'/pubspec.yaml")
text = re.sub(r"^\s*pdfrx:.*\n", "", p.read_text(), flags=re.M)
p.write_text(text)
'
(
  cd "$BASELINE_DIR"
  flutter pub get
  flutter build macos --release
)

BASELINE_APP="$BASELINE_DIR/build/macos/Build/Products/Release/pdf_spike.app"
BASELINE_BIN="$BASELINE_APP/Contents/MacOS/pdf_spike"
if [ -d "$BASELINE_APP/Contents/Frameworks/PDFium.framework" ]; then
  echo "ERROR: baseline build unexpectedly includes PDFium.framework" >&2
  exit 1
fi
python3 "$SPIKE_DIR/tool/summarize.py" bundle-size "$BASELINE_APP" --out "$PERF_DIR/bundle_baseline.json"

echo "=== 3. Measuring baseline idle RSS (${IDLE_SECONDS}s x3) ==="
for i in 1 2 3; do
  python3 "$SPIKE_DIR/tool/summarize.py" run-monitored "$BASELINE_BIN" \
    --report "$PERF_DIR/idle_baseline_${i}.json" \
    --env "SPIKE_SCENARIO=idle" \
    --env "SPIKE_IDLE_SECONDS=$IDLE_SECONDS" \
    --env "SPIKE_FIXTURES_DIR=$FIXTURES_DIR"
done

echo "=== 4. Measuring system viewer baseline ==="
python3 "$SPIKE_DIR/tool/summarize.py" run-monitored "$BASELINE_BIN" \
  --report "$PERF_DIR/system_viewer.json" \
  --env "SPIKE_SCENARIO=system_viewer" \
  --env "SPIKE_FIXTURES_DIR=$FIXTURES_DIR"
osascript -e '
tell application "Preview"
  try
    close (every window whose name contains "one_page" or name contains "text_300" or name contains "images_30mib")
  end try
end tell
' >/dev/null 2>&1 || true

echo "=== 5. Building pdfrx macOS release app ==="
flutter pub get
flutter build macos --release

PDFRX_APP="$SPIKE_DIR/build/macos/Build/Products/Release/pdf_spike.app"
PDFRX_BIN="$PDFRX_APP/Contents/MacOS/pdf_spike"
python3 "$SPIKE_DIR/tool/summarize.py" bundle-size "$PDFRX_APP" --out "$PERF_DIR/bundle_pdfrx.json"

echo "=== 6. Inspecting linkage and architectures ==="
otool -L "$PDFRX_BIN" > "$PERF_DIR/otool_main.txt"
if [ -f "$PDFRX_APP/Contents/Frameworks/PDFium.framework/PDFium" ]; then
  lipo -info "$PDFRX_APP/Contents/Frameworks/PDFium.framework/PDFium" > "$PERF_DIR/lipo_pdfium.txt"
  otool -L "$PDFRX_APP/Contents/Frameworks/PDFium.framework/PDFium" > "$PERF_DIR/otool_pdfium.txt"
fi
cat "$PERF_DIR/otool_main.txt"
[ -f "$PERF_DIR/lipo_pdfium.txt" ] && cat "$PERF_DIR/lipo_pdfium.txt"

echo "=== 7. Measuring pdfrx idle RSS (linked, unused, ${IDLE_SECONDS}s x3) ==="
for i in 1 2 3; do
  python3 "$SPIKE_DIR/tool/summarize.py" run-monitored "$PDFRX_BIN" \
    --report "$PERF_DIR/idle_pdfrx_${i}.json" \
    --env "SPIKE_SCENARIO=idle" \
    --env "SPIKE_IDLE_SECONDS=$IDLE_SECONDS" \
    --env "SPIKE_FIXTURES_DIR=$FIXTURES_DIR"
done

echo "=== 8. Measuring pdfrx idle RSS (eager pdfrxFlutterInitialize, ${IDLE_SECONDS}s x3) ==="
for i in 1 2 3; do
  python3 "$SPIKE_DIR/tool/summarize.py" run-monitored "$PDFRX_BIN" \
    --report "$PERF_DIR/idle_eager_${i}.json" \
    --env "SPIKE_SCENARIO=idle_eager_init" \
    --env "SPIKE_IDLE_SECONDS=$IDLE_SECONDS" \
    --env "SPIKE_FIXTURES_DIR=$FIXTURES_DIR"
done

echo "=== 9. Measuring pdfrx per-fixture render, scroll, and close RSS (x3 each) ==="
for fid in one_page text_300 images_30mib; do
  for i in 1 2 3; do
    echo "--- $fid run $i ---"
    python3 "$SPIKE_DIR/tool/summarize.py" run-monitored "$PDFRX_BIN" \
      --report "$PERF_DIR/pdfrx_${fid}_${i}.json" \
      --env "SPIKE_SCENARIO=pdfrx_single" \
      --env "SPIKE_FIXTURE=$fid" \
      --env "SPIKE_FIXTURES_DIR=$FIXTURES_DIR"
  done
done

echo "=== 10. Measuring pdfrx sequential multi-file session ==="
python3 "$SPIKE_DIR/tool/summarize.py" run-monitored "$PDFRX_BIN" \
  --report "$PERF_DIR/pdfrx_sequence.json" \
  --timeout 240 \
  --env "SPIKE_SCENARIO=pdfrx_sequence" \
  --env "SPIKE_FIXTURES_DIR=$FIXTURES_DIR"

echo "=== 11. Summary ==="
python3 "$SPIKE_DIR/tool/summarize.py" summary "$PERF_DIR"
