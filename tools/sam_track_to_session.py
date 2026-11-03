#!/usr/bin/env python3
"""Convert cached SAM 3.1 racket tracks into an emulator session JSON.

Reads the offline cache written by tools/sam_f3set_video.py
(`sam_video/<clip>.json`: per-frame `[[oid, x1, y1, x2, y2, conf], ...]`
plus labelled contact events). No API key, video, or network needed.

A broadcast camera can honestly support only three quantities, so the output
carries only three: shot times, stroke side/kind taken from dataset labels
(never guessed from pixels), and a unitless per-shot intensity from racket
pixel velocity, normalized 0-1 within the session. Ball speed, spin, face
angle, and contact point on the strings are NOT observable here and are
omitted; anything downstream that shows them must label them illustrative.

    python3 tools/sam_track_to_session.py sam_video/clip.json --fps 30 -o session.json
"""
import argparse
import json
import os
import sys

KINDS = ("serve", "return", "stroke")
HANDS = ("forehand", "backhand")


def parse_label(label):
    """(kind, side) from a dataset event label; (None, None) when absent.

    Labels look like "shot_near_stroke_forehand_02". Tokens are searched, not
    positionally indexed, so unknown formats degrade to None instead of lying.
    """
    toks = (label or "").lower().split("_")
    kind = next((k for k in KINDS if k in toks), None)
    hand = next((h for h in HANDS if h in toks), None)
    return kind, hand


def centre(box):
    return ((box[1] + box[3]) / 2.0, (box[2] + box[4]) / 2.0)


def dominant_track(frames, lo, hi):
    """Longest same-object track in [lo, hi] as [(frame, cx, cy)], by object id."""
    by_id = {}
    for f in range(lo, hi + 1):
        for b in frames.get(str(f), []):
            by_id.setdefault(b[0], []).append((f,) + centre(b))
    if not by_id:
        return []
    return max(by_id.values(), key=len)


def peak_speed(track, fps):
    """Peak pixel velocity (px/s) along a track; 0.0 when too short to judge."""
    if len(track) < 2:
        return 0.0
    best = 0.0
    for (f0, x0, y0), (f1, x1, y1) in zip(track, track[1:]):
        dt = (f1 - f0) / fps
        if dt > 0:
            best = max(best, ((x1 - x0) ** 2 + (y1 - y0) ** 2) ** 0.5 / dt)
    return best


def convert(path, fps=30.0, source="SAM 3.1 video cache"):
    """Clip JSON -> session dict. Events with no track coverage are skipped."""
    d = json.load(open(path))
    frames = d.get("frames", {})
    start = d.get("start", 0)
    shots, skipped = [], 0
    for e in d.get("events", []):
        f0 = e.get("frame")
        if f0 is None:
            skipped += 1
            continue
        track = dominant_track(frames, f0 - 15, f0 + 15)
        if not track:
            skipped += 1
            continue
        kind, hand = parse_label(e.get("label", ""))
        shots.append({
            "contact_frame": f0,
            "t_s": round((f0 - start) / fps, 3),
            "kind": kind or "unknown",
            "side": hand or "unknown",
            "side_source": "dataset_label" if hand else "none",
            "peak_px_s": round(peak_speed(track, fps), 1),
            "track_cover": round(len(track) / 31.0, 3),
            "clip": d.get("clip", os.path.basename(path)),
        })
    peaks = [s["peak_px_s"] for s in shots]
    lo, hi = (min(peaks), max(peaks)) if peaks else (0.0, 0.0)
    span = hi - lo
    for s in shots:
        s["intensity"] = round((s["peak_px_s"] - lo) / span, 3) if span > 0 else 0.0
    return {
        "provenance": {
            "source": source,
            "tracker": "SAM 3.1 video API (cached tracks, no live calls)",
            "fps_assumed": fps,
            "inputs": [os.path.basename(path)],
        },
        "units_note": ("intensity is unitless 0-1 from racket pixel velocity, "
                       "normalized within this session. It is NOT a speed in km/h."),
        "omitted": ["ball_speed", "spin", "face_angle", "contact_point"],
        "skipped_events": skipped,
        "shots": shots,
    }


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("inputs", nargs="+", help="sam_video/<clip>.json cache files")
    ap.add_argument("--fps", type=float, default=30.0, help="source frame rate")
    ap.add_argument("--source", default="SAM 3.1 video cache")
    ap.add_argument("-o", "--output", required=True)
    a = ap.parse_args(argv)
    merged = None
    for p in a.inputs:
        s = convert(p, fps=a.fps, source=a.source)
        if merged is None:
            merged = s
        else:
            merged["shots"].extend(s["shots"])
            merged["skipped_events"] += s["skipped_events"]
            merged["provenance"]["inputs"].append(os.path.basename(p))
    merged["shots"].sort(key=lambda s: (s["clip"], s["t_s"]))
    for i, s in enumerate(merged["shots"]):
        s["index"] = i
    json.dump(merged, open(a.output, "w"), indent=1)
    print(f"{len(merged['shots'])} shots, {merged['skipped_events']} skipped -> {a.output}")


if __name__ == "__main__":
    sys.exit(main())
