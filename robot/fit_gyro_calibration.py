#!/usr/bin/env python3
"""Fit a 3x3 gyro calibration matrix M from the robot's tool angular velocity to the IMU gyro.

    imu_gyro (rad/s, sensor axes, bias removed) = M @ tool_omega (rad/s, tool axes)

M holds the scale, axis misalignment and the fixed sensor-to-tool rotation. Uses the gyro-corrected run CSVs
(runs_gyrofix) and alignment.csv from align_raw_imu.py. Held-out error is measured per path family.

    python3 robot/fit_gyro_calibration.py TennisRobot/TennisBuddyDayOne_20261029 data/room-2026-10-29/runs_gyrofix
"""
import argparse
import csv
import json
import re
from pathlib import Path

import numpy as np
from scipy.spatial.transform import Rotation

HZ = 100


def tool_omega(raw: Path):
    """(t, omega in tool axes, rad/s) over 20 ms windows."""
    a = np.genfromtxt(raw, delimiter=",", skip_header=1)
    t = a[:, 0]
    rb = Rotation.from_euler("ZYX", a[:, 10:13], degrees=True)
    left = np.arange(len(t) - 1)
    right = np.minimum(np.searchsorted(t, t[:-1] + 0.02), len(t) - 1)
    wd = np.maximum(t[right] - t[left], 1e-3)
    w = (rb[left].inv() * rb[right]).as_rotvec() / wd[:, None]
    return (t[left] + t[right]) / 2, w


def run_pairs(raw_dir: Path, runs_dir: Path):
    for r in csv.DictReader(open(runs_dir / "alignment.csv")):
        if r["status"] != "ok":
            continue
        raw = raw_dir / r["raw_file"]
        a = np.genfromtxt(runs_dir / r["imu_file"], delimiter=",", skip_header=1)
        t, g = a[:, 0], a[:, 4:7]
        g = g - np.median(g[t < t[0] + 0.5], axis=0)
        tr, w = tool_omega(raw)
        grid = np.arange(0.2, tr[-1] - 0.2, 1 / HZ)
        t0 = float(r["imu_time_of_raw_t0"])
        k = max(1, int(len(t) / (t[-1] - t[0]) / HZ))
        gs = np.array([np.convolve(g[:, i], np.ones(k) / k, "same") for i in range(3)]).T
        y = np.array([np.interp(t0 + grid, t, gs[:, i]) for i in range(3)]).T
        x = np.array([np.interp(grid, tr, w[:, i]) for i in range(3)]).T
        yield r["raw_file"].split("_rep")[0], x, y


def fit(x, y):
    m, *_ = np.linalg.lstsq(x, y, rcond=None)
    return m.T


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("raw_dir", type=Path)
    ap.add_argument("runs_dir", type=Path)
    ap.add_argument("--out", type=Path)
    args = ap.parse_args()

    data = list(run_pairs(args.raw_dir, args.runs_dir))
    fam = np.array([re.sub(r"_(slow|medium|fast)$", "", d[0]) for d in data])
    X = np.vstack([d[1] for d in data])
    Y = np.vstack([d[2] for d in data])
    F = np.concatenate([[f] * len(d[1]) for f, d in zip(fam, data)])
    M = fit(X, Y)
    u, s, vt = np.linalg.svd(M)
    print("M =\n", np.round(M, 4))
    print("singular values (axis scales):", np.round(s, 4))
    rot = Rotation.from_matrix(u @ vt)
    print("rotation part (deg, xyz euler):", np.round(rot.as_euler("xyz", degrees=True), 2))
    res = Y - X @ M.T
    rms = lambda a: float(np.sqrt((a ** 2).mean()))
    print(f"fit RMS {rms(res):.4f} rad/s vs signal RMS {rms(Y):.4f} (identity-scaled 1.0: {rms(Y - X @ (u @ vt).T):.4f})")
    print("held-out error by path family:")
    for f in sorted(set(F)):
        tr, te = F != f, F == f
        Mf = fit(X[tr], Y[tr])
        e = Y[te] - X[te] @ Mf.T
        print(f"  {f:24s} n={te.sum():6d} signal {rms(Y[te]):.3f} heldout rms {rms(e):.4f} ({100 * rms(e) / max(rms(Y[te]), 1e-9):.1f}%)")
    if args.out:
        args.out.write_text(json.dumps({"M_imu_from_tool": M.tolist(), "singular_values": s.tolist(),
                                        "note": "gyro-corrected (x0.5) IMU, firmware 1.5 sensor stuck at +-2000"}, indent=1))


if __name__ == "__main__":
    main()
