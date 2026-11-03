#!/usr/bin/env python3
"""Does the data's hit time land on the VISIBLE swing in the video? (picture-based alignment check)

The SAM racket tracks are cut from the same video timeline as the hit times, so they are a picture clock. For each
tracked hit this finds the frame where the hitter's racket moves fastest (within +-8 frames of the hit) and reports how
far that is from the data's hit frame. The human-labelled Ostrava clips are the reference: a racket's speed peak
naturally sits a frame or two off the labelled contact, so a model-predicted match is aligned if its median and spread
look like Ostrava's.

    python3 tools/f3tennis_model/swing_alignment.py data/external/f3set/sam_video  D:/.../sam
"""
import glob
import json
import os
import sys

import numpy as np

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
import f3set_to_emulator as fe  # noqa: E402

HALF = 8


def offsets(cache_files, label_of):
    """Frame offsets (speed peak minus hit frame) for every hit with a usable hitter track."""
    out = []
    for p in cache_files:
        with open(p) as fh:
            d = json.load(fh)
        frames, height = d.get("frames", {}), d.get("height", 720)
        for e in d.get("events", []):
            hitter = label_of(e)
            if hitter not in ("near", "far"):
                continue
            f0 = e["frame"]
            sm = fe.fill(fe.hitter_track(frames, f0, hitter, height), f0)
            if not sm:
                continue
            scale = sorted(q[2] for q in sm)[len(sm) // 2]
            if scale <= 0:
                continue
            sp = [np.hypot(b[0] - a[0], b[1] - a[1]) / scale for a, b in zip(sm, sm[1:])]   # speed into frame i+1
            c = fe.HALF                                                                      # index of the hit frame
            win = sp[c - HALF:c + HALF]
            if max(win) < 0.15:                      # racket barely moved: no clear peak
                continue
            out.append(int(np.argmax(win)) - HALF + 1)
    return np.array(out)


def describe(name, d):
    if len(d) < 10:
        return f"{name:38s} only {len(d)} usable hits"
    q1, med, q3 = np.percentile(d, [25, 50, 75])
    return (f"{name:38s} {len(d):4d} hits | speed peak vs data hit: median {med:+.0f} frames ({med / 25 * 1000:+.0f} ms), "
            f"IQR {q1:+.0f}..{q3:+.0f} | within +-3 frames: {100 * np.mean(np.abs(d) <= 3):.0f}%")


def main(argv=None):
    a = argv or sys.argv[1:]
    labelled, sam_root = a[0], a[1]
    ref = offsets(sorted(glob.glob(os.path.join(labelled, "*.json"))), lambda e: fe.parse_label(e.get("label"))["hitter"])
    print(describe("Ostrava (human labels, reference)", ref))
    for d in sorted(glob.glob(os.path.join(sam_root, "*", "sam_video"))):
        slug = os.path.basename(os.path.dirname(d))
        offs = offsets(sorted(glob.glob(os.path.join(d, "*.json"))), lambda e: e.get("hitter"))
        print(describe(slug, offs))


if __name__ == "__main__":
    main()
