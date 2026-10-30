#!/usr/bin/env python3
"""Align RC+ *_RCPLUS_RAW.csv logs with the IMU runs cut by split_tbrec.py.

Angular speed is frame independent, so the robot's TCP orientation rate is cross-correlated with the IMU gyro
magnitude per run. The lag gives the IMU time at which each RAW file's t=0 happened.

    python3 robot/align_raw_imu.py TennisRobot/TennisBuddyDayOne_20261029 data/room-2026-10-29/runs
"""
import argparse
import csv
import json
from pathlib import Path

import numpy as np
from scipy.spatial.transform import Rotation

HZ = 100


def raw_speed(path: Path):
    """(t, rad/s) of the TCP orientation, 20 ms window like export_rcplus_logs.py."""
    if not path.stat().st_size or not path.read_text().strip():
        return None
    a = np.genfromtxt(path, delimiter=",", skip_header=1)
    if a.ndim < 2 or len(a) < 50:
        return None
    t = a[:, 0]
    rb = Rotation.from_euler("ZYX", a[:, 10:13], degrees=True).as_matrix()
    left = np.arange(len(t) - 1)
    right = np.minimum(np.searchsorted(t, t[:-1] + 0.02), len(t) - 1)
    wd = np.maximum(t[right] - t[left], 1e-3)
    w = Rotation.from_matrix(rb[left].transpose(0, 2, 1) @ rb[right]).magnitude() / wd
    return t[:-1], w


def imu_speed(path: Path):
    a = np.genfromtxt(path, delimiter=",", skip_header=1)
    g = a[:, 4:7]
    still = a[:, 0] < a[0, 0] + 0.5  # each cut starts 1.5 s before the twitch, with the arm at rest
    return a[:, 0], np.linalg.norm(g - np.median(g[still], axis=0), axis=1)


def on_grid(t, y, t0, t1):
    grid = np.arange(t0, t1, 1 / HZ)
    k = max(1, int(len(t) / max(t[-1] - t[0], 1e-6) / HZ))
    ys = np.convolve(y, np.ones(k) / k, "same")
    return grid, np.interp(grid, t, ys, left=0, right=0)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("raw_dir", type=Path)
    ap.add_argument("runs_dir", type=Path)
    ap.add_argument("--max-lag", type=float, default=4.0)
    args = ap.parse_args()

    manifest = json.loads((args.runs_dir / "manifest.json").read_text())
    rows = []
    for m in manifest:
        if m["attempt"] != 2:
            continue
        raw = args.raw_dir / f"{m['tentative_path_id']}_rep{m['tentative_rep']:02d}_E35E_RCPLUS_RAW.csv"
        base = {"imu_file": m["file"], "raw_file": raw.name, "twitch_s": m["twitch_s"]}
        sp = raw_speed(raw) if raw.exists() else None
        if sp is None:
            rows.append({**base, "status": "no_raw"})
            continue
        ti, wi = imu_speed(args.runs_dir / m["file"])
        tr, wr = sp
        lo, hi = -args.max_lag, args.max_lag
        # IMU time axis is absolute; the cut starts 1.5 s before the twitch, which the robot commands at ~1.0 s
        # into the run, so the guess for the IMU time of RAW t=0 is twitch - 1.0.
        guess = m["twitch_s"] - 1.0
        gr, yr = on_grid(tr, wr, 0, tr[-1])
        best = (-2, 0.0)
        for lag in np.arange(lo, hi, 1 / HZ):
            t0 = guess + lag
            ya = np.interp(t0 + gr, ti, wi, left=0, right=0)
            if ya.std() < 1e-6 or yr.std() < 1e-6:
                continue
            c = float(np.corrcoef(ya, yr)[0, 1])
            if c > best[0]:
                best = (c, lag)
        c, lag = best
        rows.append({**base, "status": "ok", "imu_time_of_raw_t0": round(guess + lag, 3),
                     "lag_vs_twitch_guess_s": round(lag, 2), "corr": round(c, 3),
                     "raw_peak_rads": round(float(wr.max()), 3), "imu_peak_rads": round(float(wi.max()), 3),
                     "imu_over_raw_median": round(float(np.median(
                         np.interp(guess + lag + gr, ti, wi)[yr > 0.05] / yr[yr > 0.05])), 3)})
    out = args.runs_dir / "alignment.csv"
    fields = sorted({k for r in rows for k in r}, key=lambda k: ["imu_file", "raw_file", "status"].index(k)
                    if k in ("imu_file", "raw_file", "status") else 9)
    with open(out, "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        w.writerows(rows)
    ok = [r for r in rows if r["status"] == "ok"]
    c = np.array([r["corr"] for r in ok])
    print(f"{len(ok)} aligned, {len(rows) - len(ok)} without RAW; corr median {np.median(c):.3f}, "
          f"<0.8: {(c < 0.8).sum()}; lag median {np.median([r['lag_vs_twitch_guess_s'] for r in ok]):.2f} s")
    print(out)


if __name__ == "__main__":
    main()
