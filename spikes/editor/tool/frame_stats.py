#!/usr/bin/env python3
"""Summarise spike timelines: python3 tool/frame_stats.py build/perf > results.md

UI time   = async "Frame" begin->end on the platform/UI thread (what
            TimelineSummary calls frame build time).
Raster    = "GPURasterizer::Draw" B->E on io.flutter.raster.
"""
import glob, json, os, sys

def pct(v, p):
    return v[min(len(v) - 1, round((len(v) - 1) * p))] if v else float('nan')

def stats(path):
    ev = json.load(open(path))['traceEvents']
    ui, rs, open_async, open_r = [], [], {}, {}
    for e in ev:
        n, ph = e.get('name'), e.get('ph')
        if n == 'Frame' and ph in ('b', 'e'):
            k = e.get('id')
            if ph == 'b': open_async[k] = e['ts']
            elif k in open_async: ui.append((e['ts'] - open_async.pop(k)) / 1000)
        elif n == 'GPURasterizer::Draw' and ph in ('B', 'E'):
            k = e['tid']
            if ph == 'B': open_r[k] = e['ts']
            elif k in open_r: rs.append((e['ts'] - open_r.pop(k)) / 1000)
    ui.sort(); rs.sort()
    tot = [u for u in ui]
    return {
        'frames': len(ui),
        'ui_p50': pct(ui, .5), 'ui_p90': pct(ui, .9), 'ui_p99': pct(ui, .99), 'ui_worst': ui[-1] if ui else float('nan'),
        'r_p90': pct(rs, .9), 'r_worst': rs[-1] if rs else float('nan'),
        'over16': sum(1 for u in ui if u > 16.67), 'over8': sum(1 for u in ui if u > 8.33),
    }

def main(d):
    runs = sorted(glob.glob(os.path.join(d, '*.json')))
    runs = [r for r in runs if not r.endswith('.timeline.json')]
    traces = ['load', 'typing', 'scroll']
    out = {}
    for r in runs:
        m = json.load(open(r))
        name = os.path.basename(r)[:-5]
        row = {k: v for k, v in m.items() if k not in traces}
        for t in traces:
            p = os.path.join(d, f'{name}_{t}.timeline.json')
            if os.path.exists(p):
                row[t] = stats(p)
        out[name] = row
    json.dump(out, sys.stdout, indent=1, default=str)

main(sys.argv[1] if len(sys.argv) > 1 else 'build/perf')
