#!/usr/bin/env python3
"""Run the mount-independent parts of our shot typing (tools/shot_type_check.py) on the SmartTennisRacket windows.

    python3 tools/smart_tennis_racket_eval.py <SmartTennisRacket repo>/raw_datasets

Their data: BMI270 mid-frame, 3 ms sampling, +-16 g, +-2000 dps, three right-handed players, windows of 1000 samples
labelled forehand / backhand / serve / nothing. Their axes are not documented, so only features that don't need
them are used: the swing angle (integral of |gyro| over the 350 ms before contact) and the turn about the vertical
from the Mahony filter's own world frame. The impact is taken as the accelerometer maximum.
"""
import glob
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from shot_type_check import SWING_SPAN, VOLLEY_MAX_SWING_DEG, SERVE_MAX_VERTICAL, mahony, rot, swing_angle_deg  # noqa: E402

DT = 0.003
CLASSES = ["forehand", "backhand", "serve", "nothing"]


def window_features(a):
    acc, gyr = a[:, :3], np.deg2rad(a[:, 3:6])
    t = np.arange(len(a)) * DT
    an = np.linalg.norm(acc, axis=1)
    i0 = int(np.argmax(an >= an.max() - 0.05))        # first sample at the (clipped) peak
    i0 = max(i0, 130)
    q = mahony(t, acc, gyr)
    swing = swing_angle_deg(t, gyr, i0)
    w_pre = gyr[i0 - 12:i0 - 2].mean(0)
    omega = np.linalg.norm(w_pre)
    vertical = rot(q[i0 - 3], w_pre)[2] / omega if omega > 1e-3 else 0.0
    # racket long axis is unknown: tip-up cosine for each sensor axis
    tip = [abs(rot(q[i0 - 3], np.eye(3)[k])[2]) for k in range(3)]
    return i0, swing, vertical, omega, tip


def main(root):
    rows = []
    for person in sorted(glob.glob(os.path.join(root, "person_*"))):
        for cls in CLASSES:
            for f in sorted(glob.glob(os.path.join(person, cls, "*.csv"))):
                a = np.genfromtxt(f, delimiter=",", skip_header=1)
                if a.ndim == 2 and a.shape[1] == 6 and len(a) >= 300:
                    rows.append((os.path.basename(person), cls) + window_features(a))
    print(f"{len(rows)} windows; impact index median {np.median([r[2] for r in rows]):.0f}")
    persons = sorted({r[0] for r in rows})
    print(f"\nSwing angle over the 350 ms before contact (volley rule: < {VOLLEY_MAX_SWING_DEG} deg):")
    for cls in CLASSES:
        s = np.array([r[3] for r in rows if r[1] == cls])
        print(f"  {cls:9s} n={len(s):3d}  p5 {np.percentile(s, 5):4.0f}  median {np.median(s):4.0f}  p95 {np.percentile(s, 95):4.0f}  "
              f"below {VOLLEY_MAX_SWING_DEG} deg: {100 * (s < VOLLEY_MAX_SWING_DEG).mean():.0f}%")
    print("\nTurn about the vertical, forehand-way positive (right-handed), 'vertical' in ShotAnalyzer:")
    for cls in CLASSES:
        v = np.array([r[4] for r in rows if r[1] == cls])
        print(f"  {cls:9s} median {np.median(v):+.2f}   share > 0: {100 * (v > 0).mean():3.0f}%   share < {SERVE_MAX_VERTICAL}: {100 * (v < SERVE_MAX_VERTICAL).mean():3.0f}%")
    print("\nForehand vs backhand by the sign of that turn (per player):")
    for p in persons + ["all"]:
        fh = np.array([r[4] for r in rows if r[1] == "forehand" and (p == "all" or r[0] == p)])
        bh = np.array([r[4] for r in rows if r[1] == "backhand" and (p == "all" or r[0] == p)])
        if len(fh) and len(bh):
            print(f"  {p:9s} FH>0 {100 * (fh > 0).mean():3.0f}%   BH<0 {100 * (bh < 0).mean():3.0f}%   accuracy {100 * ((fh > 0).sum() + (bh < 0).sum()) / (len(fh) + len(bh)):.0f}%")
    print("\nServe vs forehand/backhand by omega and tip-up (best sensor axis taken as the racket's long axis):")
    for k in range(3):
        s = np.array([r[6][k] for r in rows if r[1] == "serve"])
        g = np.array([r[6][k] for r in rows if r[1] in ("forehand", "backhand")])
        print(f"  axis {'xyz'[k]}: |tip-up| serve median {np.median(s):.2f}, ground median {np.median(g):.2f}")


if __name__ == "__main__":
    main(sys.argv[1])
