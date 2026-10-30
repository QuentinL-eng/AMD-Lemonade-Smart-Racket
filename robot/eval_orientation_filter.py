#!/usr/bin/env python3
"""Run a port of the app's MahonyFilter (apple/RacketKit/Sources/RacketKit/Orientation.swift) on the gyro-corrected
IMU runs and compare its tilt and heading against the robot's orientation.

The robot arm's motions are slow and smooth, so this checks that the filter is implemented and calibrated sensibly
(tilt error, heading drift). It says little about the filter's behaviour on real swings; do not tune to it.

    python3 robot/eval_orientation_filter.py TennisRobot/TennisBuddyDayOne_20261029 data/room-2026-10-29/runs_gyrofix \
        data/room-2026-10-29/gyro_calibration.json
"""
import argparse
import csv
import json
import re
from collections import defaultdict
from pathlib import Path

import numpy as np
from scipy.spatial.transform import Rotation

HZ = 200
G = 9.80665


def mahony(gyro, accel, dt, kp=2.0, ki=0.05):
    """Same update as MahonyFilter.update; returns the world-from-sensor rotation after each step."""
    q = Rotation.identity()
    out = []
    integral = np.zeros(3)
    init = False
    for w, a in zip(gyro, accel):
        n = np.linalg.norm(a)
        if not init and n > 0.5:
            # tiltOnly: rotation taking measured up (body) to world up
            axis = np.cross(a / n, [0, 0, 1])
            s = np.linalg.norm(axis)
            q = Rotation.from_rotvec(axis / s * np.arctan2(s, (a / n)[2])) if s > 1e-9 else Rotation.identity()
            init = True
        w = np.array(w, float)
        if 0.85 < n < 1.15 and np.linalg.norm(w) < 3:
            up_body = q.inv().apply([0, 0, 1])
            e = np.cross(a / n, up_body)
            integral += ki * e * dt
            w = w + kp * e + integral
        ang = np.linalg.norm(w) * dt
        if ang > 1e-9:
            q = q * Rotation.from_rotvec(w / np.linalg.norm(w) * ang)
        out.append(q)
    return Rotation.concatenate(out)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("raw_dir", type=Path)
    ap.add_argument("runs_dir", type=Path)
    ap.add_argument("calib", type=Path)
    ap.add_argument("--kp", type=float, default=2.0)
    ap.add_argument("--ki", type=float, default=0.05)
    args = ap.parse_args()

    M = np.array(json.loads(args.calib.read_text())["M_imu_from_tool"])
    u, _, vt = np.linalg.svd(M)
    Q = Rotation.from_matrix(u @ vt)  # imu = Q tool

    by_fam = defaultdict(list)
    for r in csv.DictReader(open(args.runs_dir / "alignment.csv")):
        if r["status"] != "ok":
            continue
        a = np.genfromtxt(args.runs_dir / r["imu_file"], delimiter=",", skip_header=1)
        t = a[:, 0]
        t0 = float(r["imu_time_of_raw_t0"])
        raw = np.genfromtxt(args.raw_dir / r["raw_file"], delimiter=",", skip_header=1)
        dur = raw[-1, 0]
        s = (t >= t0 - 1.0) & (t <= t0 + dur)
        n = int((t[s][-1] - t[s][0]) * HZ)
        grid = t[s][0] + np.arange(n) / HZ
        k = max(1, int(len(t) / (t[-1] - t[0]) / HZ))
        sm = lambda col: np.convolve(a[:, col], np.ones(k) / k, "same")
        gyro = np.array([np.interp(grid, t, sm(c)) for c in (4, 5, 6)]).T
        acc = np.array([np.interp(grid, t, sm(c)) for c in (1, 2, 3)]).T
        filt = mahony(gyro, acc, 1 / HZ, args.kp, args.ki)  # world_from_sensor, own yaw
        rb = Rotation.from_euler("ZYX", raw[:, 10:13], degrees=True)
        rel = (rb[0].inv() * rb).as_rotvec()
        tt = grid - t0
        ok = (tt >= 0) & (tt <= dur)
        rbg = rb[0] * Rotation.from_rotvec(np.array([np.interp(tt[ok], raw[:, 0], rel[:, i]) for i in range(3)]).T)
        truth = rbg * Q.inv()  # world_from_sensor from the robot
        f = filt[ok]
        up_f = f.inv().apply([0, 0, 1])
        up_t = truth.inv().apply([0, 0, 1])
        tilt = np.degrees(np.arccos(np.clip((up_f * up_t).sum(1), -1, 1)))
        # Heading: yaw of the filter's rotation relative to truth, with the first sample's offset removed.
        d = f * truth.inv()
        yaw = np.unwrap(d.as_euler("zyx")[:, 0])
        yaw = np.degrees(yaw - yaw[0])
        fam = re.sub(r"_(slow|medium|fast)$", "", r["raw_file"].split("_rep")[0])
        by_fam[fam].append((np.median(tilt), np.percentile(tilt, 95), tilt.max(), yaw[-1] / max(tt[ok][-1], 1e-6)))

    print(f"kp={args.kp} ki={args.ki}")
    print(f"{'family':24s} {'n':>3s} {'tilt med':>9s} {'tilt p95':>9s} {'tilt max':>9s} {'yaw drift deg/s':>16s}")
    for fam, v in sorted(by_fam.items()):
        v = np.array(v)
        print(f"{fam:24s} {len(v):3d} {np.median(v[:, 0]):8.2f}° {np.median(v[:, 1]):8.2f}° {v[:, 2].max():8.2f}° {np.median(v[:, 3]):+14.3f}")


if __name__ == "__main__":
    main()
