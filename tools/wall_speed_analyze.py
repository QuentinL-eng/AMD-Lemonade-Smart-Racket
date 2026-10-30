#!/usr/bin/env python3
"""Ground-truth ball speed from a wall drill, compared with the speed the app derives from the IMU.

    python3 tools/wall_speed_analyze.py session.tbrec drill.mov --distance 4.0 [--effort "E M H E M H ..."]
    python3 tools/wall_speed_analyze.py --selftest

See docs/WALL_SPEED_PROTOCOL.md for how to record. The racket's impact (IMU high-g spike) is matched to its "pop" in the
audio track; the ball's flight time to the wall is the gap from that pop to the next sound (the wall thud), so the
mean ball speed is distance / flight time. The IMU gives |omega_yz| just before contact (racket frame, rad/s), and the
app's model predicts ball speed = (1 + e) * R * |omega_yz| for a ball with no incoming speed (a self-fed drop hit).
This fits the measured speeds against |omega_yz| and reports the implied radius R.

Mean speed over the flight is lower than the speed just after contact (drag), typically 5-10% over 4 m.
"""
import argparse
import csv
import os
import subprocess
import sys
import tempfile

import numpy as np
from scipy.signal import butter, find_peaks, sosfilt

REC = np.dtype([("t", "<f8"), ("v", "<f4", 9)])
M = np.array([[0, 1, 0], [1, 0, 0], [0, 0, -1]], float)   # Calibration.default (tools/shot_type_check.py)
APP_E, APP_R = 0.42, 1.15                                  # ImpactModel.acorCenter, RacketProfile.effectiveRadiusM
SOUND = 343.0
SR = 48000


def load_imu(path):
    d = np.fromfile(path, dtype=REC)
    dt = np.diff(d["t"])
    cuts = np.r_[0, np.where((dt < 0) | (dt > 1))[0] + 1, len(d)]
    a, b = max(zip(cuts, cuts[1:]), key=lambda s: s[1] - s[0])
    return d[a:b]


def imu_shots(rec, gyro_scale):
    """[(impact time, |omega_yz|, |omega|)] using the app's windows (ShotAnalyzer / shot_type_check)."""
    t = rec["t"]
    hg = rec["v"][:, 6:9]
    gyr = rec["v"][:, 3:6] * gyro_scale @ M.T
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
        lo, hi = max(3, p - 6), min(len(t), p + 7)
        best = max(range(lo, hi), key=lambda k: np.linalg.norm(hg[k] - hg[k - 3]))
        i0 = best - 2
        if i0 < 12:
            continue
        w = gyr[i0 - 10:i0 - 2].mean(0)
        out.append((t[i0], float(np.hypot(w[1], w[2])), float(np.linalg.norm(w))))
    return out


def read_audio(path):
    if path.lower().endswith(".wav"):
        import wave
        with wave.open(path) as w:
            sr = w.getframerate()
            x = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16).astype(np.float32) / 32768
            if w.getnchannels() > 1:
                x = x.reshape(-1, w.getnchannels()).mean(1)
        return x, sr
    raw = subprocess.run(["ffmpeg", "-loglevel", "error", "-i", path, "-vn", "-ac", "1", "-ar", str(SR), "-f", "f32le", "-"],
                         capture_output=True, check=True).stdout
    return np.frombuffer(raw, dtype=np.float32), SR


def audio_onsets(x, sr):
    """Times of sharp sounds: 1.5 kHz high-passed energy in 2 ms steps, adaptive threshold, 30 ms refractory."""
    y = sosfilt(butter(4, 1500, "hp", fs=sr, output="sos"), x)
    hop = int(0.002 * sr)
    n = len(y) // hop
    e = np.sqrt((y[: n * hop].reshape(n, hop) ** 2).mean(1))
    base = np.median(e)
    mad = np.median(np.abs(e - base)) + 1e-9
    pk, _ = find_peaks(e, height=base + 12 * mad, distance=15)
    return pk * hop / sr, e[pk]


def match_clocks(imu_t, onsets, energy, tol=0.015):
    """Offset (audio time = IMU time + offset) matching most IMU impacts to an onset.

    A drop-fed hit has a floor bounce about 0.4 s before the pop, so timing alone can match either; among offsets
    with the same number of matches, the one whose matched onsets are loudest wins (the racket pop is the loudest
    sharp sound)."""
    cands = []
    for i in imu_t[: min(8, len(imu_t))]:
        for o in onsets:
            off = o - i
            d = np.abs(onsets[None, :] - (imu_t[:, None] + off))
            n = int((d.min(1) < tol).sum())
            hit = d.argmin(1)[d.min(1) < tol]
            cands.append((n, float(np.median(energy[hit])) if len(hit) else 0.0, off))
    top = max(c[0] for c in cands)
    near = [c for c in cands if c[0] == top]
    n, _, off = max(near, key=lambda c: c[1])
    return off, n


def analyze(rec, x, sr, distance, phone_contact, phone_wall, gyro_scale, effort, exclude):
    shots = imu_shots(rec, gyro_scale)
    onsets, energy = audio_onsets(x, sr)
    if not shots or not len(onsets):
        raise SystemExit("no IMU impacts or no audio onsets found")
    off, n_match = match_clocks(np.array([s[0] for s in shots]), onsets, energy)
    extra = (phone_wall - phone_contact) / SOUND       # the wall thud reaches the phone this much later than it happened
    rows = []
    for k, (t, w_yz, w) in enumerate(shots):
        pop = t + off
        j = np.searchsorted(onsets, pop - 0.015)
        if j >= len(onsets) or abs(onsets[j] - pop) > 0.015:
            rows.append(dict(shot=k + 1, status="no pop in audio"))
            continue
        nxt = onsets[j + 1] if j + 1 < len(onsets) else None
        if nxt is None or not (0.05 < nxt - onsets[j] < 1.6):
            rows.append(dict(shot=k + 1, status="no wall sound"))
            continue
        flight = nxt - onsets[j] - extra
        rows.append(dict(shot=k + 1, status="ok", effort=effort[k] if k < len(effort) else "",
                         omega_yz=w_yz, omega=w, flight_s=flight, v_ball=distance / flight,
                         excluded=(k + 1) in exclude))
    return rows, n_match, len(shots), len(onsets)


def report(rows, n_match, n_imu, n_aud, out_csv=None):
    good = [r for r in rows if r["status"] == "ok" and not r["excluded"]]
    print(f"{n_imu} IMU impacts, {n_aud} audio onsets, {n_match} matched; {len(good)} usable shots "
          f"({sum(1 for r in rows if r['status'] != 'ok')} without a pop or wall sound, {sum(1 for r in rows if r.get('excluded'))} excluded)")
    if len(good) < 6:
        print("too few shots to fit")
        return
    w = np.array([r["omega_yz"] for r in good])
    v = np.array([r["v_ball"] for r in good])
    k = float(w @ v / (w @ w))                       # through the origin: v = k * omega_yz
    res = v - k * w
    r2 = 1 - (res ** 2).sum() / ((v - v.mean()) ** 2).sum()
    A = np.c_[w, np.ones_like(w)]
    (a, b), *_ = np.linalg.lstsq(A, v, rcond=None)
    app_k = (1 + APP_E) * APP_R
    print(f"\nball speed = k * |omega_yz|:  k = {k:.3f}  (app currently uses (1+e)R = {app_k:.3f})")
    print(f"  fit R^2 {r2:.2f}, rms error {100 * np.sqrt((res ** 2).mean()) / v.mean():.0f}% of mean speed {v.mean():.1f} m/s")
    print(f"  with an intercept: v = {a:.3f} * omega + {b:+.1f} m/s")
    print(f"  implied effective radius at e = {APP_E}: {k / (1 + APP_E):.2f} m  (app: {APP_R} m; mean flight speed reads low by drag, so true R is a little higher)")
    print(f"  app prediction error on these shots: {100 * np.mean((app_k * w - v) / v):+.0f}% mean")
    for e in sorted({r["effort"] for r in good if r["effort"]}):
        g = [r for r in good if r["effort"] == e]
        print(f"  effort {e}: n={len(g):2d}  |omega_yz| {np.mean([r['omega_yz'] for r in g]):5.1f} rad/s  ball {np.mean([r['v_ball'] for r in g]):5.1f} m/s")
    if out_csv:
        with open(out_csv, "w", newline="") as f:
            wr = csv.DictWriter(f, fieldnames=["shot", "status", "effort", "omega_yz", "omega", "flight_s", "v_ball", "excluded"])
            wr.writeheader()
            wr.writerows(rows)
        print(f"\nper-shot table: {out_csv}")


def selftest():
    """Synthetic drill with known speeds: 24 hits, drop-feed floor bounce before each, wall 4 m away."""
    rng = np.random.default_rng(1)
    D, k_true, n = 4.0, 1.55, 24
    t0 = 5.0
    times = t0 + np.cumsum(rng.uniform(3.2, 5.5, n))
    w_yz = rng.uniform(3, 20, n)
    v = k_true * w_yz
    fs = 1000
    T = times[-1] + 6
    t = np.arange(0, T, 1 / fs)
    d = np.zeros(len(t), dtype=REC)
    d["t"] = t + 100.0
    d["v"][:, 2] = 1.0
    for ti, w in zip(times, w_yz):
        i = int(ti * fs)
        d["v"][i - 200:i - 2, 3] = w                        # sensor x -> racket y under Calibration.default
        d["v"][i:i + 4, 6:9] = [0, 0, 30]                   # high-g spike
    x = rng.normal(0, 0.002, int(T * SR)).astype(np.float32)
    def burst(at, amp):
        s = int(at * SR)
        x[s:s + 200] += rng.normal(0, amp, 200).astype(np.float32)
    phone_wall = 4.0
    for ti, vv in zip(times, v):
        flight = D / vv
        burst(ti - rng.uniform(0.35, 0.55), 0.25)           # floor bounce of the drop feed (quiet)
        burst(ti, 0.8)                                      # racket pop (loudest)
        burst(ti + flight + phone_wall / SOUND, 0.5)        # wall thud, heard late by the phone beside the hitter
    rows, nm, ni, na = analyze(d, x, SR, D, 0.0, phone_wall, 1.0, ["E", "M", "H"] * 8, set())
    report(rows, nm, ni, na)
    good = [r for r in rows if r["status"] == "ok"]
    w = np.array([r["omega_yz"] for r in good]); vm = np.array([r["v_ball"] for r in good])
    k = float(w @ vm / (w @ w))
    assert len(good) == n and abs(k - k_true) / k_true < 0.03, (len(good), k)
    print(f"\nselftest ok: recovered k = {k:.3f} (true {k_true})")


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("tbrec", nargs="?")
    ap.add_argument("audio", nargs="?", help="the drill video (.mov/.mp4) or a .wav")
    ap.add_argument("--distance", type=float, help="metres from the contact point to the wall")
    ap.add_argument("--phone-to-contact", type=float, default=1.0, help="metres from the phone to the racket contact point")
    ap.add_argument("--phone-to-wall", type=float, help="metres from the phone to where the ball hits the wall (default: from geometry)")
    ap.add_argument("--gyro-scale", type=float, default=1.0, help="0.5 for firmware 1.5 recordings")
    ap.add_argument("--effort", default="", help='effort per shot in order, e.g. "E M H E M H"')
    ap.add_argument("--exclude", default="", help="shot numbers to drop, e.g. 3,17")
    ap.add_argument("--csv")
    ap.add_argument("--selftest", action="store_true")
    a = ap.parse_args()
    if a.selftest:
        return selftest()
    if not (a.tbrec and a.audio and a.distance):
        ap.error("tbrec, audio and --distance are required")
    rec = load_imu(a.tbrec)
    x, sr = read_audio(a.audio)
    wall = a.phone_to_wall or float(np.hypot(a.distance, a.phone_to_contact))
    ex = {int(s) for s in a.exclude.split(",") if s}
    rows, nm, ni, na = analyze(rec, x, sr, a.distance, a.phone_to_contact, wall, a.gyro_scale, a.effort.split(), ex)
    report(rows, nm, ni, na, a.csv)


if __name__ == "__main__":
    main()
