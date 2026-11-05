#!/usr/bin/env bash
# Memory-only runs (no timeline capture); results land in build/perf/.
# Usage: tool/run_all.sh [config ...]   (config = grid:mode)
set -u
cd "$(dirname "$0")/.."
configs=("$@")
[ ${#configs[@]} -eq 0 ] && configs=(fixedgrid:full fixedgrid:window tableview:full tableview:window syncfusion:full syncfusion:window trina:full pluto:full)
mkdir -p build/logs
for cfg in "${configs[@]}"; do
  g=${cfg%%:*}; m=${cfg##*:}
  echo "=== $g/$m $(date +%T)"
  # Watchdog: a hung app (e.g. syncfusion window mode) is killed after 10 min.
  ( sleep 600; pkill -f "grid_spike.app/Contents/MacOS/grid_spike" ) & wd=$!
  flutter drive --profile -d macos --dart-define=TRACE=false \
    --driver=test_driver/perf_driver.dart \
    --target=integration_test/perf_${g}_test.dart \
    --dart-define=MODE=$m > build/logs/${g}_${m}_mem.log 2>&1
  rc=$?; kill $wd 2>/dev/null
  echo "    exit=$rc $(grep -E 'All tests passed|Some tests failed|\[E\]' build/logs/${g}_${m}_mem.log | head -1) last=$(grep STEP build/logs/${g}_${m}_mem.log | tail -1)"
done
python3 tool/frame_stats.py build/perf > build/perf_summary.json
echo "=== done $(date +%T)"
