#!/usr/bin/env python3
"""Labelled F3Set clips + SAM racket tracks -> one emulator player with real stroke types and swing profiles.

Reads the offline cache written by tools/sam_f3set_video.py (`sam_video/<clip>.json`: per-frame
`[[oid, x1, y1, x2, y2, conf], ...]` plus the dataset's labelled contact events). No key, video or network.

What is real here, and what is not
- Stroke type, forehand/backhand, technique, court side, direction and outcome are DATASET LABELS (F3Set).
- Which player hit (near or far from the camera) is in the label; the SAM track of that player's racket is picked
  by where it sits in the frame (near = lower half).
- The swing PROFILE is real timing from the racket-box centre: how far along its path the racket is at each frame
  from -12 to +12 around contact (-1 = start of the window, 0 = contact, +1 = end of follow-through), by path length.
  `path_deg` is the direction the racket centre was moving at contact (+ = low-to-high). Both come from a 2D box
  centre, so they are a rough guide to the swing, not a 3D measurement.
- Speed is unitless (racket lengths per second, normalised 0-1 within the session). Ball speed, spin, face angle and
  the contact point on the strings are NOT observable; the emulator labels them estimates.

    python3 tools/f3set_to_emulator.py data/external/f3set/sam_video --merge website/emulator_sessions.json
"""
import argparse
import glob
import json
import math
import os
import sys

FPS = 25.0            # F3Set videos are 25 fps (data/external/f3set/repo/README.md)
HALF = 12             # frames either side of contact kept per shot
PATH_MIN, PATH_MAX = -20.0, 35.0   # a 2D box centre over-weights vertical motion: halve the angle, keep it plausible
GAP_S = 3.0           # between clips, as in tools/sam_players_to_emulator.py
NAME = "Ostrava 2022 final (labelled)"
SOURCE = "WTA Ostrava 2022 final, Swiatek v Krejcikova, F3Tennis dataset labels + SAM 3.1 racket tracks"
DATASET_URL = "https://github.com/F3EST/F3Tennis"

TECH = {"gs": "groundstroke", "slice": "slice", "volley": "volley", "smash": "smash", "drop": "drop shot", "lob": "lob"}


def parse_label(label):
    """F3Set label -> dict. e.g. near_deuce_serve_fh_gs_W_non-approach_in. Unknown formats give None fields."""
    t = (label or "").lower().split("_")
    t += [None] * (8 - len(t))
    kind = t[2] if t[2] in ("serve", "return", "stroke") else None
    hand = {"fh": "forehand", "bh": "backhand"}.get(t[3])
    tech = TECH.get(t[4])
    outcome = t[7] if t[7] in ("in", "winner", "forced-err", "unforced-err") else None
    return {"hitter": t[0] if t[0] in ("near", "far") else None, "court": t[1], "kind": kind, "hand": hand,
            "tech": tech, "dir": t[5], "outcome": outcome}


def app_type(lab):
    """The Tennis Buddee ShotType this hit is shown as (apple/RacketKit ShotType)."""
    if lab["kind"] == "serve":
        return "serve"
    if lab["tech"] == "volley":
        return "volley"
    return lab["hand"] or "hit"


def centre(b):
    return ((b[1] + b[3]) / 2.0, (b[2] + b[4]) / 2.0, max(b[3] - b[1], b[4] - b[2]))


def hitter_track(frames, f0, hitter, height):
    """{frame: (cx, cy, size)} of the racket belonging to the hitter, in frames f0-HALF..f0+HALF.

    Near hitter = the track whose centre sits in the lower half of the frame, far = upper half. Returns {} if
    that player's racket was not tracked.
    """
    by = {}
    for f in range(f0 - HALF, f0 + HALF + 1):
        for b in frames.get(str(f), []):
            by.setdefault(b[0], {})[f] = centre(b)
    best, best_n = {}, 0
    for pts in by.values():
        cy = sum(p[1] for p in pts.values()) / len(pts)
        ok = (cy > height * 0.5) if hitter == "near" else (cy < height * 0.5) if hitter == "far" else True
        if ok and len(pts) > best_n:
            best, best_n = pts, len(pts)
    return best


def fill(pts, f0):
    """25 samples f0-HALF..f0+HALF: linear gaps, held ends, 3-frame smoothing. None when coverage is too thin."""
    fs = range(f0 - HALF, f0 + HALF + 1)
    have = sorted(pts)
    if len(have) < 14 or not any(abs(f - f0) <= 3 for f in have):
        return None
    out = []
    for f in fs:
        if f in pts:
            out.append(pts[f])
            continue
        lo = [h for h in have if h < f]
        hi = [h for h in have if h > f]
        if lo and hi:
            a, b = lo[-1], hi[0]
            w = (f - a) / (b - a)
            out.append(tuple(pts[a][k] * (1 - w) + pts[b][k] * w for k in range(3)))
        else:
            out.append(pts[(lo or hi)[-1 if lo else 0]])
    sm = []
    for i in range(len(out)):
        win = out[max(0, i - 1):i + 2]
        sm.append(tuple(sum(p[k] for p in win) / len(win) for k in range(3)))
    return sm


def profile(sm):
    """(prog[25], path_deg, peak_len_per_s, scale) from smoothed samples, or None when the racket barely moved."""
    scale = sorted(p[2] for p in sm)[len(sm) // 2]
    if scale <= 0:
        return None
    steps = [0.0]
    for a, b in zip(sm, sm[1:]):
        d = math.hypot(b[0] - a[0], b[1] - a[1]) / scale
        steps.append(max(0.0, d - 0.01))           # ignore box jitter
    L = []
    run = 0.0
    for s in steps:
        run += s
        L.append(run)
    lc, lt = L[HALF], L[-1]
    if lc < 0.15 or lt - lc < 0.05:
        return None
    prog = []
    for i, v in enumerate(L):
        prog.append(round(-(1 - v / lc) if i <= HALF else (v - lc) / (lt - lc), 3))
    i0, i1 = HALF - 2, HALF + 2
    vx = (sm[i1][0] - sm[i0][0]) / scale
    vy = (sm[i1][1] - sm[i0][1]) / scale
    path = max(PATH_MIN, min(PATH_MAX, 0.5 * math.degrees(math.atan2(-vy, abs(vx) + 1e-9))))
    peak = max(math.hypot(b[0] - a[0], b[1] - a[1]) / scale * FPS for a, b in zip(sm, sm[1:]))
    return prog, path, peak, scale


def convert(paths):
    shots, skipped, untracked, offset = [], 0, 0, 0.0
    for p in sorted(paths):
        with open(p) as fh:
            d = json.load(fh)
        frames, height = d.get("frames", {}), d.get("height", 720)
        evs = sorted(d.get("events", []), key=lambda e: e.get("frame", 0))
        if not evs:
            continue
        first = evs[0]["frame"]
        last_t = offset
        for e in evs:
            f0 = e.get("frame")
            lab = parse_label(e.get("label"))
            if f0 is None or not lab["hitter"]:
                skipped += 1
                continue
            sm = fill(hitter_track(frames, f0, lab["hitter"], height), f0)
            prof = profile(sm) if sm else None
            if prof is None:
                untracked += 1
            t_s = round(offset + (f0 - first) / FPS, 3)
            last_t = max(last_t, t_s)
            shot = {"clip": d.get("clip", os.path.basename(p)), "contact_frame": f0, "t_s": t_s,
                    "stroke": app_type(lab), "kind": lab["kind"] or "stroke", "side": lab["hand"] or "unknown",
                    "side_source": "dataset_label", "technique": lab["tech"], "hitter": lab["hitter"],
                    "court": lab["court"], "dir": lab["dir"], "outcome": lab["outcome"]}
            if prof:
                prog, path, peak, scale = prof
                shot.update({"prog": prog, "path_deg": round(path, 1), "peak_len_s": round(peak, 3),
                             "track_cover": round(len([1 for _ in sm]) / 25.0, 2)})
            shots.append(shot)
        offset = last_t + GAP_S
    peaks = sorted(s["peak_len_s"] for s in shots if "peak_len_s" in s)
    # 10th-90th percentile, so a tracking glitch can't squash every other hit toward zero
    lo, hi = (peaks[int(0.1 * (len(peaks) - 1))], peaks[int(0.9 * (len(peaks) - 1))]) if peaks else (0.0, 0.0)
    for s in shots:
        s["intensity"] = round(min(1.0, max(0.0, (s["peak_len_s"] - lo) / (hi - lo))), 3) if "peak_len_s" in s and hi > lo else 0.5
    shots.sort(key=lambda s: s["t_s"])
    for i, s in enumerate(shots):
        s["index"] = i
    return {
        "name": NAME, "video_url": DATASET_URL,
        "session": {
            "provenance": {"player": "both players (near and far)", "source": SOURCE, "video_url": DATASET_URL,
                           "tracker": "SAM 3.1 video API (cached tracks, no live calls)", "fps_assumed": FPS,
                           "labels": "F3Tennis dataset (stroke, forehand/backhand, technique, court, direction, outcome)"},
            "units_note": ("intensity is unitless 0-1 from racket-centre speed in racket lengths per second, normalised "
                           "within this session. It is NOT a speed in km/h. prog and path_deg come from the 2D box "
                           "centre, a rough guide to the swing."),
            "time_note": "labelled clips concatenated with 3 s gaps; within-clip timing is true.",
            "omitted": ["ball_speed", "spin", "face_angle", "contact_point"],
            "skipped_events": skipped, "untracked_events": untracked, "shots": shots}}


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("sam_video_dir", help="data/external/f3set/sam_video")
    ap.add_argument("--merge", required=True, help="emulator_sessions.json to update (entry is replaced by name)")
    a = ap.parse_args(argv)
    player = convert(glob.glob(os.path.join(a.sam_video_dir, "*.json")))
    doc = {"players": []}
    if os.path.exists(a.merge):
        with open(a.merge) as fh:
            doc = json.load(fh)
    doc["players"] = [player] + [p for p in doc["players"] if p["name"] != NAME]
    with open(a.merge, "w") as fh:
        json.dump(doc, fh, indent=1)
    sh = player["session"]["shots"]
    print(f"{len(sh)} labelled shots ({player['session']['untracked_events']} without a usable track) -> {a.merge}")


if __name__ == "__main__":
    sys.exit(main())
