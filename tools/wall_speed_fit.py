#!/usr/bin/env python3
"""Fit the ball-speed constants against measured ball speeds (docs/WALL_SPEED_TEST.md).

    python tools/wall_speed_fit.py SESSION.csv TRUTH.csv [--gyro-scale 0.5]
    python tools/wall_speed_fit.py --demo

SESSION.csv: the app's session export (time_s,ax_g,...,hz_g). Impacts are found as in tools/shot_type_check.py.
TRUTH.csv: `hit,ball_speed_ms`, or `hit,distance_m,flight_time_s` from wall timing (hit = 1-based order of the
detected impacts; leave a hit out to skip it). distance/time is the MEAN speed over the flight, a few percent
below the exit speed (drag), so fitted constants come out slightly low.

Per hit, as ShotAnalyzer: w_pre = |(y,z)| of the mean gyro over (i0-10)..<(i0-2), w_post over (i0+12)..<(i0+30).
  model A (current):  v = (1+e) * r * w_pre, e = 0.43                      fit r
  model B (impulse):  v = r * (w_pre + k * max(0, w_pre - w_post))       fit r, k
Reports leave-one-out RMS error, mean bias and per-hit predictions.
"""
import argparse
import os
import sys

import numpy as np

E = 0.43
MIN_HITS = 8
M = np.array([[0, 1, 0], [1, 0, 0], [0, 0, -1]], float)   # Calibration.default, as in shot_type_check.py


def impact_features(path, gyro_scale=1.0):
    """[(w_pre, w_post)] per detected impact, rad/s across the shaft."""
    d = np.loadtxt(path, delimiter=",", skiprows=1, ndmin=2)
    t = d[:, 0]
    gyr, hg = d[:, 4:7] * gyro_scale @ M.T, d[:, 7:10] @ M.T
    hgm = np.linalg.norm(hg, axis=1)
    peaks = []
    for i in np.where(hgm > 4)[0]:
        if peaks and t[i] - t[peaks[-1]] < 0.6:
            if hgm[i] > hgm[peaks[-1]]:
                peaks[-1] = i
        else:
            peaks.append(i)
    out = []
    for p in peaks:
        best = max(range(max(3, p - 6), min(len(t), p + 7)), key=lambda k: np.linalg.norm(hg[k] - hg[k - 3]))
        i0 = best - 2
        pre, post = gyr[max(0, i0 - 10):max(0, i0 - 2)], gyr[max(0, i0 + 12):min(len(t), i0 + 30)]
        if len(pre) == 0 or len(post) == 0:
            out.append((np.nan, np.nan))
            continue
        out.append((np.linalg.norm(pre.mean(0)[1:]), np.linalg.norm(post.mean(0)[1:])))
    return out


def read_truth(path):
    """{hit: speed m/s}."""
    lines = [l.strip() for l in open(path) if l.strip()]
    head = [h.strip() for h in lines[0].split(",")]
    truth = {}
    for l in lines[1:]:
        row = dict(zip(head, (x.strip() for x in l.split(","))))
        if "ball_speed_ms" in row:
            v = float(row["ball_speed_ms"])
        else:
            v = float(row["distance_m"]) / float(row["flight_time_s"])
        truth[int(row["hit"])] = v
    return truth


def design(w_pre, w_post):
    return np.column_stack([w_pre, np.maximum(0, w_pre - w_post)])


def fit_a(w_pre, v):
    x = (1 + E) * w_pre
    r = x @ v / (x @ x)
    res = v - r * x
    dof = max(1, len(v) - 1)
    se = np.sqrt(res @ res / dof / (x @ x))
    return r, se


def fit_b(w_pre, w_post, v):
    X = design(w_pre, w_post)
    (a, b), *_ = np.linalg.lstsq(X, v, rcond=None)
    res = v - X @ (a, b)
    dof = max(1, len(v) - 2)
    try:
        cov = np.linalg.inv(X.T @ X) * (res @ res / dof)
    except np.linalg.LinAlgError:
        cov = np.full((2, 2), np.nan)
    k = b / a
    # delta method for k = b/a
    g = np.array([-b / a ** 2, 1 / a])
    return a, k, np.sqrt(cov[0, 0]), np.sqrt(max(0.0, g @ cov @ g))


def predict_a(r, w_pre, w_post):
    return (1 + E) * r * w_pre


def predict_b(r, k, w_pre, w_post):
    return r * (w_pre + k * np.maximum(0, w_pre - w_post))


def loo(w_pre, w_post, v):
    pa, pb = np.empty_like(v), np.empty_like(v)
    for i in range(len(v)):
        m = np.arange(len(v)) != i
        pa[i] = predict_a(fit_a(w_pre[m], v[m])[0], w_pre[i], w_post[i])
        r, k, _, _ = fit_b(w_pre[m], w_post[m], v[m])
        pb[i] = predict_b(r, k, w_pre[i], w_post[i])
    return pa, pb


def report(hits, w_pre, w_post, v, out=sys.stdout):
    w_pre, w_post, v = (np.asarray(x, float) for x in (w_pre, w_post, v))
    if len(v) < MIN_HITS:
        raise ValueError(f"{len(v)} hits with ground truth; need at least {MIN_HITS}")
    ra, sea = fit_a(w_pre, v)
    rb, k, serb, sek = fit_b(w_pre, w_post, v)
    pa, pb = loo(w_pre, w_post, v)
    res = {
        "A": dict(r=ra, r_se=sea, rms=float(np.sqrt(np.mean((pa - v) ** 2))), bias=float(np.mean(pa - v))),
        "B": dict(r=rb, r_se=serb, k=k, k_se=sek, rms=float(np.sqrt(np.mean((pb - v) ** 2))),
                  bias=float(np.mean(pb - v))),
    }
    print(" hit  w_pre  w_post   truth   A(loo)  B(loo)   m/s", file=out)
    for h, a, b, t, x, y in zip(hits, w_pre, w_post, v, pa, pb):
        print(f"{h:4d}  {a:5.1f}  {b:6.1f}  {t:6.1f}  {x:7.1f} {y:7.1f}", file=out)
    A, B = res["A"], res["B"]
    print(f"\nA (current, e={E}): r = {A['r']:.3f} ± {A['r_se']:.3f} m   "
          f"LOO RMS {A['rms']:.2f} m/s  bias {A['bias']:+.2f}", file=out)
    print(f"B (impulse):        r = {B['r']:.3f} ± {B['r_se']:.3f} m  k = {B['k']:.2f} ± {B['k_se']:.2f}   "
          f"LOO RMS {B['rms']:.2f} m/s  bias {B['bias']:+.2f}", file=out)
    return res


def synth(n=45, seed=1, r=1.15, k=1.3, e=E, noise=0.8):
    """Hits from the physics: v_out = (1+e)V + e*u, racket drop dV = e(V+u)/k (so v_out = V + k dV)."""
    rng = np.random.default_rng(seed)
    V = rng.uniform(10, 30, n)          # sweet-spot speed, m/s
    u = rng.uniform(0, 25, n)           # incoming ball speed, varies (rally / feed)
    v = (1 + e) * V + e * u
    dV = e * (V + u) / k
    w_pre = V / r + rng.normal(0, 0.3, n)
    w_post = (V - dV) / r + rng.normal(0, 0.3, n)
    return w_pre, w_post, v + rng.normal(0, noise, n)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("session", nargs="?")
    ap.add_argument("truth", nargs="?")
    ap.add_argument("--gyro-scale", type=float, default=1.0, help="0.5 for sessions recorded on firmware < 1.6")
    ap.add_argument("--demo", action="store_true", help="synthetic hits, no data needed")
    a = ap.parse_args(argv)
    if a.demo:
        w_pre, w_post, v = synth()
        print("Demo: 45 synthetic hits, true r = 1.15 m, k = 1.30, incoming ball 0-25 m/s\n")
        report(list(range(1, len(v) + 1)), w_pre, w_post, v)
        return 0
    if not (a.session and a.truth):
        ap.error("need SESSION.csv and TRUTH.csv, or --demo")
    feats = impact_features(a.session, a.gyro_scale)
    truth = read_truth(a.truth)
    print(f"{len(feats)} impacts detected, {len(truth)} ground-truth rows")
    hits = [h for h in sorted(truth) if 1 <= h <= len(feats) and np.isfinite(feats[h - 1][0])]
    missing = sorted(set(truth) - set(hits))
    if missing:
        print(f"skipping hits with no usable impact: {missing}")
    try:
        report(hits, [feats[h - 1][0] for h in hits], [feats[h - 1][1] for h in hits], [truth[h] for h in hits])
    except ValueError as ex:
        sys.exit(str(ex))
    return 0


if __name__ == "__main__":
    sys.exit(main())
