#!/usr/bin/env python3
"""Bundle size inspector, external ps RSS sampler, and summary generator."""

from __future__ import annotations

import argparse
import json
import os
import pathlib
import statistics
import subprocess
import sys
import time


def _apparent_dir_bytes(path: pathlib.Path) -> int:
    total = 0
    for root, dirs, files in os.walk(path, followlinks=False):
        root_path = pathlib.Path(root)
        for name in dirs:
            entry = root_path / name
            if entry.is_symlink():
                total += entry.lstat().st_size
        for name in files:
            entry = root_path / name
            total += entry.lstat().st_size
    return total


def _du_kib(path: pathlib.Path) -> int:
    out = subprocess.check_output(["du", "-sk", str(path)], text=True).strip()
    return int(out.split()[0])


def cmd_bundle_size(args: argparse.Namespace) -> None:
    app_path = pathlib.Path(args.app_path)
    if not app_path.exists():
        raise SystemExit(f"App bundle not found: {app_path}")

    total_bytes = _apparent_dir_bytes(app_path)
    total_du_kib = _du_kib(app_path)

    frameworks_dir = app_path / "Contents" / "Frameworks"
    frameworks: dict[str, dict[str, int]] = {}
    if frameworks_dir.exists():
        for item in sorted(frameworks_dir.iterdir()):
            frameworks[item.name] = {
                "bytes": item.lstat().st_size if item.is_file() or item.is_symlink() else _apparent_dir_bytes(item),
                "duKib": _du_kib(item),
            }

    payload = {
        "appPath": str(app_path),
        "totalBytes": total_bytes,
        "totalMiB": round(total_bytes / (1024 * 1024), 3),
        "totalMB": round(total_bytes / 1_000_000, 3),
        "duKib": total_du_kib,
        "duMiB": round(total_du_kib / 1024, 3),
        "frameworks": frameworks,
    }
    out_path = pathlib.Path(args.out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(json.dumps(payload, indent=2) + "\n")
    print(json.dumps(payload, indent=2))


def cmd_run_monitored(args: argparse.Namespace) -> None:
    env = os.environ.copy()
    for kv in args.env:
        k, v = kv.split("=", 1)
        env[k] = v

    report_path = pathlib.Path(args.report)
    report_path.parent.mkdir(parents=True, exist_ok=True)
    env["SPIKE_REPORT_PATH"] = str(report_path)

    start = time.monotonic()
    proc = subprocess.Popen([args.binary], env=env)
    ps_samples: list[dict[str, float | int]] = []
    peak_kib = 0

    while proc.poll() is None:
        try:
            out = subprocess.check_output(
                ["ps", "-o", "rss=", "-p", str(proc.pid)],
                text=True,
                stderr=subprocess.DEVNULL,
            ).strip()
            if out:
                kib = int(out)
                if kib > 0:
                    if kib > peak_kib:
                        peak_kib = kib
                    ps_samples.append(
                        {
                            "elapsedMs": int((time.monotonic() - start) * 1000),
                            "rssBytes": kib * 1024,
                        }
                    )
        except subprocess.CalledProcessError:
            pass
        if time.monotonic() - start > args.timeout:
            proc.kill()
            raise SystemExit(f"Timed out after {args.timeout}s running {args.binary}")
        time.sleep(0.1)

    rc = proc.wait()
    if rc != 0:
        raise SystemExit(f"Process exited with code {rc}")

    data = json.loads(report_path.read_text())
    ps_t5 = next((s["rssBytes"] for s in ps_samples if s["elapsedMs"] >= 5000), None)
    ps_end = ps_samples[-1]["rssBytes"] if ps_samples else None
    data["psRss"] = {
        "sampleCount": len(ps_samples),
        "peakBytes": peak_kib * 1024,
        "t5Bytes": ps_t5,
        "endBytes": ps_end,
    }
    report_path.write_text(json.dumps(data, indent=2) + "\n")


def _mib(value: float | int) -> str:
    return f"{value / (1024 * 1024):.2f} MiB"


def _mb(value: float | int) -> str:
    return f"{value / 1_000_000:.2f} MB"


def _median_int(values: list[int]) -> float:
    return float(statistics.median(values))


def cmd_summary(args: argparse.Namespace) -> None:
    perf_dir = pathlib.Path(args.perf_dir)
    bundle_base = json.loads((perf_dir / "bundle_baseline.json").read_text())
    bundle_pdfrx = json.loads((perf_dir / "bundle_pdfrx.json").read_text())

    added_bytes = bundle_pdfrx["totalBytes"] - bundle_base["totalBytes"]
    added_du_kib = bundle_pdfrx["duKib"] - bundle_base["duKib"]

    idle_base = [json.loads((perf_dir / f"idle_baseline_{i}.json").read_text()) for i in (1, 2, 3)]
    idle_pdfrx = [json.loads((perf_dir / f"idle_pdfrx_{i}.json").read_text()) for i in (1, 2, 3)]
    idle_eager = [json.loads((perf_dir / f"idle_eager_{i}.json").read_text()) for i in (1, 2, 3)]

    base_end_med = _median_int([r["endRssBytes"] for r in idle_base])
    pdfrx_end_med = _median_int([r["endRssBytes"] for r in idle_pdfrx])
    eager_end_med = _median_int([r["endRssBytes"] for r in idle_eager])

    base_ps_med = _median_int([r["psRss"]["endBytes"] for r in idle_base if r["psRss"]["endBytes"]])
    pdfrx_ps_med = _median_int([r["psRss"]["endBytes"] for r in idle_pdfrx if r["psRss"]["endBytes"]])
    eager_ps_med = _median_int([r["psRss"]["endBytes"] for r in idle_eager if r["psRss"]["endBytes"]])

    fixtures_summary: dict[str, dict[str, object]] = {}
    for fid in ("one_page", "text_300", "images_30mib"):
        runs = [json.loads((perf_dir / f"pdfrx_{fid}_{i}.json").read_text()) for i in (1, 2, 3)]
        fixtures_summary[fid] = {
            "bytes": runs[0]["bytes"],
            "pageCount": runs[0]["pageCount"],
            "paintedPagesCounts": [r["paintedPagesCount"] for r in runs],
            "viewerReadyMsMedian": _median_int([r["viewerReadyMs"] for r in runs]),
            "firstPageMsMedian": _median_int([r["firstPageMs"] for r in runs]),
            "firstPageMsRuns": [r["firstPageMs"] for r in runs],
            "beforeLoadMiB": round(_median_int([r["beforeLoadRssBytes"] for r in runs]) / (1024 * 1024), 2),
            "bytesLoadedMiB": round(_median_int([r["bytesLoadedRssBytes"] for r in runs]) / (1024 * 1024), 2),
            "afterPage1MiB": round(_median_int([r["afterPage1RssBytes"] for r in runs]) / (1024 * 1024), 2),
            "peakDuringShowMiB": round(_median_int([r["peakDuringShowRssBytes"] for r in runs]) / (1024 * 1024), 2),
            "psPeakMiB": round(_median_int([r["psRss"]["peakBytes"] for r in runs]) / (1024 * 1024), 2),
            "afterClose5sMiB": round(_median_int([r["afterClose5sRssBytes"] for r in runs]) / (1024 * 1024), 2),
            "afterClose10sMiB": round(_median_int([r["afterClose10sRssBytes"] for r in runs]) / (1024 * 1024), 2),
            "afterImageCacheClearMiB": round(
                _median_int([r["afterImageCacheClearRssBytes"] for r in runs]) / (1024 * 1024), 2
            ),
        }

    seq = json.loads((perf_dir / "pdfrx_sequence.json").read_text())
    sys_viewer = json.loads((perf_dir / "system_viewer.json").read_text())

    summary = {
        "bundle": {
            "baselineBytes": bundle_base["totalBytes"],
            "pdfrxBytes": bundle_pdfrx["totalBytes"],
            "addedBytes": added_bytes,
            "baselineDuKib": bundle_base["duKib"],
            "pdfrxDuKib": bundle_pdfrx["duKib"],
            "addedDuKib": added_du_kib,
        },
        "idle": {
            "baseline30sDartBytes": [r["endRssBytes"] for r in idle_base],
            "pdfrx30sDartBytes": [r["endRssBytes"] for r in idle_pdfrx],
            "eager30sDartBytes": [r["endRssBytes"] for r in idle_eager],
            "baseline30sDartMedian": base_end_med,
            "pdfrx30sDartMedian": pdfrx_end_med,
            "eager30sDartMedian": eager_end_med,
            "idleDeltaUnusedBytes": pdfrx_end_med - base_end_med,
            "idleDeltaEagerBytes": eager_end_med - base_end_med,
            "psIdleDeltaUnusedBytes": pdfrx_ps_med - base_ps_med,
            "psIdleDeltaEagerBytes": eager_ps_med - base_ps_med,
        },
        "fixtures": fixtures_summary,
        "sequence": seq,
        "systemViewer": sys_viewer,
    }
    (perf_dir / "summary.json").write_text(json.dumps(summary, indent=2) + "\n")

    print("=== Bundle Size (macOS Release) ===")
    print(
        f"Baseline: {_mib(bundle_base['totalBytes'])} ({_mb(bundle_base['totalBytes'])}, du {bundle_base['duKib']} KiB)"
    )
    print(
        f"pdfrx:    {_mib(bundle_pdfrx['totalBytes'])} ({_mb(bundle_pdfrx['totalBytes'])}, du {bundle_pdfrx['duKib']} KiB)"
    )
    print(
        f"Added:    +{_mib(added_bytes)} (+{_mb(added_bytes)}, +{added_du_kib / 1024:.2f} MiB du)"
    )
    print("\n=== Idle RSS (30s, median of 3 runs) ===")
    print(f"Baseline:        {_mib(base_end_med)} (ps {_mib(base_ps_med)})")
    print(
        f"pdfrx unused:    {_mib(pdfrx_end_med)} (delta +{_mib(pdfrx_end_med - base_end_med)} / +{_mb(pdfrx_end_med - base_end_med)})"
    )
    print(
        f"pdfrx eagerInit: {_mib(eager_end_med)} (delta +{_mib(eager_end_med - base_end_med)} / +{_mb(eager_end_med - base_end_med)})"
    )
    print("\n=== pdfrx Fixtures (median of 3 runs) ===")
    for fid, info in fixtures_summary.items():
        print(
            f"{fid}: firstPage={info['firstPageMsMedian']:.0f} ms (runs={info['firstPageMsRuns']}), "
            f"before={info['beforeLoadMiB']} MiB, peak={info['peakDuringShowMiB']} MiB (ps {info['psPeakMiB']} MiB), "
            f"close5s={info['afterClose5sMiB']} MiB, close10s={info['afterClose10sMiB']} MiB, "
            f"painted={info['paintedPagesCounts']}"
        )
    print("\n=== System Viewer (baseline build) ===")
    for f in sys_viewer["fixtures"]:
        print(
            f"{f['fixture']}: write={f['writeMs']} ms, launch={f['launchMs']} ms, exit={f['exitCode']}"
        )


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="cmd", required=True)

    p_bundle = sub.add_parser("bundle-size")
    p_bundle.add_argument("app_path")
    p_bundle.add_argument("--out", required=True)
    p_bundle.set_defaults(func=cmd_bundle_size)

    p_run = sub.add_parser("run-monitored")
    p_run.add_argument("binary")
    p_run.add_argument("--report", required=True)
    p_run.add_argument("--timeout", type=int, default=180)
    p_run.add_argument("--env", action="append", default=[])
    p_run.set_defaults(func=cmd_run_monitored)

    p_sum = sub.add_parser("summary")
    p_sum.add_argument("perf_dir")
    p_sum.set_defaults(func=cmd_summary)

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
