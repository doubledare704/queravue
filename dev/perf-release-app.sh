#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
report="${QUERAVUE_PERF_OUT:-$root/app/build/perf/release-memory.md}"
mkdir -p "$(dirname "$report")"
rm -f "$report"

docker compose -f "$root/dev/docker-compose.yml" up -d --wait mongo
make -C "$root" core
(cd "$root/app" && flutter build macos --release -t perf/release_memory_main.dart)

app="$(find "$root/app/build/macos/Build/Products/Release" -maxdepth 1 -name '*.app' | head -n 1)"
binary="$(find "$app/Contents/MacOS" -maxdepth 1 -type f -perm +111 ! -name queravued | head -n 1)"
config_dir="$(mktemp -d)"
trap 'rm -rf "$config_dir"' EXIT

QUERAVUE_E2E=1 QUERAVUE_CONFIG_DIR="$config_dir" QUERAVUE_PERF_OUT="$report" "$binary"

cat "$report"
