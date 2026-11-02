"""Frozen replay of the currently deployed shot rules, for baseline measurement.

Uses the calibrated sensor frame, corrected gyro units and actual timestamps.
This module never modifies the Swift or firmware implementation.
"""
import numpy as np

from .orientation import gravity_body


def angle_before(t, gyro, i):
    start, angle, k = t[i]-.350, 0., i-1
    while k > 0 and t[k-1] > start:
        angle += (np.linalg.norm(gyro[k])+np.linalg.norm(gyro[k-1]))*.5*min(t[k]-t[k-1], .060)
        k -= 1
    return float(np.degrees(angle))


def classify_at(t, accel, gyro, high_g, indices, taught_sign=1.):
    up = gravity_body(t, accel, gyro)
    sign, learning = taught_sign, []
    rows = []
    for i in indices:
        if i < 10:
            raise ValueError("Insufficient pre-contact samples")
        pre = gyro[i-10:i-2].mean(0)
        omega = float(np.linalg.norm(pre))
        # Calibration.default: racket x=-sensor y; racket y=-sensor x.
        tip = float(-up[max(i-3, 0), 1])
        vertical = float(np.dot(up[max(i-3, 0)], pre)/omega) if omega > .001 else 0.
        wy = float(-pre[0])
        swing = angle_before(t, gyro, i)
        if swing < 45:
            got = "volley"
        elif abs(tip) > .6 and omega > 4:
            got = "serve"
        elif sign:
            got = "backhand" if wy*sign <= 0 else ("serve" if vertical < -.1 else "forehand")
        else:
            got = "forehand" if vertical > 0 else "backhand"
        if sign == 0 and got == "forehand" and vertical > .6 and abs(wy) > 2.5:
            learning.append(wy)
            if len(learning) >= 5:
                pos = sum(v > 0 for v in learning)
                if pos in (0, len(learning)):
                    sign = 1. if pos else -1.
                learning = []
        rows.append({"sample_index": int(i), "contact_phone_s": float(t[i]), "predicted": got,
                     "swing_deg": swing, "vertical": vertical, "tip_up": tip, "gyro_racket_y": wy,
                     "forehand_sign": sign})
    return rows


def raw_app_contacts(t, gyro, high_g):
    """RacketEngine.detect/finishShot raw-stream path (motion only, no mic).

    Missing BLE samples are retained as gaps. This replay cannot reconstruct
    samples the embedded detector saw but never transmitted.
    """
    pending, last_shot, out = None, -10., []
    magnitude = np.linalg.norm(gyro, axis=1)
    for i in range(400, len(t)):
        if pending is not None:
            if t[i]-t[pending] >= .15:
                best = max(range(max(3, pending-6), min(i, pending+6)+1),
                           key=lambda k: np.linalg.norm(high_g[k]-high_g[k-3]))
                out.append(best-2)
                last_shot = t[pending]
                pending = None
            continue
        if t[i]-last_shot <= .4:
            continue
        jump = np.linalg.norm(high_g[i]-high_g[i-3])
        if jump > 10 and magnitude[max(0, i-149):i+1].max() > 5:
            pending = i
    return out
