#!/usr/bin/env python3
"""Fit the IMU's position relative to the robot's TCP (the assumed sweet spot) from accelerometer data.

In tool axes the IMU's specific force is
    f = k * R^T (a_tcp + g) + (alpha x d + omega x (omega x d)) + b
with the robot's pose giving R, a_tcp, omega, alpha, and d the vector from TCP to IMU. Solves for d, the accel
scale k and a constant bias b. Axes are mapped with the rotation part of the gyro calibration, so run
fit_gyro_calibration.py first (it writes gyro_calibration.json).

    python3 robot/fit_lever_arm.py TennisRobot/TennisBuddyDayOne_20261029 data/room-2026-10-29/runs_gyrofix \
        data/room-2026-10-29/gyro_calibration.json
"""
import argparse
import csv
import json
import re
from pathlib import Path

import numpy as np
from scipy.signal import savgol_filter
from scipy.spatial.transform import Rotation

HZ = 200
G = 9.80665


def skew(v):
    z = np.zeros(len(v))
    return np.stack([np.stack([z, -v[:, 2], v[:, 1]], -1),
                     np.stack([v[:, 2], z, -v[:, 0]], -1),
                     np.stack([-v[:, 1], v[:, 0], z], -1)], 1)


def robot_kinematics(raw: Path, grid):
    a = np.genfromtxt(raw, delimiter=",", skip_header=1)
    t = a[:, 0]
    p = np.array([np.interp(grid, t, a[:, 7 + i]) for i in range(3)]).T / 1000
    rb = Rotation.from_euler("ZYX", a[:, 10:13], degrees=True)
    # Orientation on the grid by slerp-free interpolation of the rotation vector relative to the first pose.
    rel = (rb[0].inv() * rb).as_rotvec()
    rg = rb[0] * Rotation.from_rotvec(np.array([np.interp(grid, t, rel[:, i]) for i in range(3)]).T)
    win = 41  # 205 ms at 200 Hz: the controller's pose updates every 2 ms and jitters
    acc = savgol_filter(p, win, 3, deriv=2, delta=1 / HZ, axis=0)
    dr = (rg[:-1].inv() * rg[1:]).as_rotvec() * HZ
    om = np.vstack([dr, dr[-1:]])
    om = savgol_filter(om, win, 3, axis=0)
    al = savgol_filter(om, win, 3, deriv=1, delta=1 / HZ, axis=0)
    return rg, acc, om, al


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("raw_dir", type=Path)
    ap.add_argument("runs_dir", type=Path)
    ap.add_argument("calib", type=Path)
    ap.add_argument("--out", type=Path)
    args = ap.parse_args()

    M = np.array(json.loads(args.calib.read_text())["M_imu_from_tool"])
    u, _, vt = np.linalg.svd(M)
    Q = u @ vt  # imu = Q tool

    rows = []  # (family, f_meas_tool, f_grav_tool, L) per sample
    for r in csv.DictReader(open(args.runs_dir / "alignment.csv")):
        if r["status"] != "ok":
            continue
        a = np.genfromtxt(args.runs_dir / r["imu_file"], delimiter=",", skip_header=1)
        t, acc = a[:, 0], a[:, 1:4] * G
        t0 = float(r["imu_time_of_raw_t0"])
        raw = args.raw_dir / r["raw_file"]
        dur = np.genfromtxt(raw, delimiter=",", skip_header=1, usecols=0)[-1]
        grid = np.arange(0.5, dur - 0.5, 1 / HZ)
        rg, a_tcp, om, al = robot_kinematics(raw, grid)
        k = max(1, int(len(t) / (t[-1] - t[0]) / HZ))
        sm = np.array([np.convolve(acc[:, i], np.ones(k) / k, "same") for i in range(3)]).T
        f_imu = np.array([np.interp(t0 + grid, t, sm[:, i]) for i in range(3)]).T
        f_tool = f_imu @ Q  # row-vector form of Q^T f
        grav = rg.inv().apply(a_tcp + np.array([0, 0, G]))
        L = skew(al) + skew(om) @ skew(om)
        fam = re.sub(r"_(slow|medium|fast)$", "", r["raw_file"].split("_rep")[0])
        rows.append((fam, f_tool, grav, L))

    def design(sel):
        ys, xs = [], []
        for _, f, g, L in sel:
            n = len(f)
            ys.append(f.reshape(-1))
            blocks = np.concatenate([g.reshape(n * 3, 1), L.reshape(n * 3, 3), np.tile(np.eye(3), (n, 1))], 1)
            xs.append(blocks)
        return np.vstack(xs), np.concatenate(ys)

    X, y = design(rows)
    sol, *_ = np.linalg.lstsq(X, y, rcond=None)
    k, d, b = sol[0], sol[1:4], sol[4:7]
    res = y - X @ sol
    base = y - X[:, :1] @ np.array([1.0])
    print(f"accel scale k = {k:.4f}   lever d (TCP->IMU, tool axes) = {np.round(d, 4)} m  |d| = {np.linalg.norm(d):.4f} m")
    print(f"bias b = {np.round(b / G * 1000, 1)} mg")
    print(f"residual RMS {np.sqrt((res ** 2).mean()) / G * 1000:.1f} mg;  gravity-only model RMS {np.sqrt((base ** 2).mean()) / G * 1000:.1f} mg;  signal RMS {np.sqrt((y ** 2).mean()) / G:.3f} g")
    fams = sorted({r[0] for r in rows})
    print("leave-one-family-out |d|:")
    ds = []
    for f in fams:
        Xf, yf = design([r for r in rows if r[0] != f])
        s, *_ = np.linalg.lstsq(Xf, yf, rcond=None)
        ds.append(s[1:4])
    ds = np.array(ds)
    print("  mean", np.round(ds.mean(0), 4), "std", np.round(ds.std(0), 4))
    if args.out:
        args.out.write_text(json.dumps({"accel_scale": float(k), "lever_tcp_to_imu_tool_m": d.tolist(),
                                        "bias_mps2": b.tolist(), "loo_std_m": ds.std(0).tolist()}, indent=1))


if __name__ == "__main__":
    main()
