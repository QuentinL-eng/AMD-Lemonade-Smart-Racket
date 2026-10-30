#!/usr/bin/env python3
"""Summarise SAM racket tracks (tools/sam_f3set_video.py) around F3Set's labelled near-court shots.

    python3 tools/eval_sam_f3set.py ~/tennis_data/f3set

For each labelled near-court shot it looks at the boxes in the lower half of the frame (the near player) within
+-3 frames of contact: was a racket found, how big, how confident, and how continuous is the track +-15 frames
around it. No ground truth is used, so this measures coverage and stability, not box accuracy.
"""
import collections
import glob
import json
import os
import sys

import numpy as np


def near_boxes(frames, f, height):
    return [b for b in frames.get(str(f), []) if (b[2] + b[4]) / 2 > height / 2]


def main(root):
    root = os.path.expanduser(root)
    rows = []
    for p in sorted(glob.glob(os.path.join(root, "sam_video", "*.json"))):
        d = json.load(open(p))
        h = d["height"]
        for e in d["events"]:
            if not e["label"].startswith("near_"):
                continue
            f0 = e["frame"]
            _, kind, hand = e["label"].split("_")[1:4]
            hit = [b for f in range(f0 - 3, f0 + 4) for b in near_boxes(d["frames"], f, h)]
            win = [f for f in range(f0 - 15, f0 + 16) if near_boxes(d["frames"], f, h)]
            ids = collections.Counter(b[0] for f in range(f0 - 15, f0 + 16) for b in near_boxes(d["frames"], f, h))
            best = max(hit, key=lambda b: b[5]) if hit else None
            rows.append({"clip": d["clip"], "kind": kind, "hand": hand, "found": bool(hit),
                         "cover": len(win) / 31, "n_ids": len(ids),
                         "w": (best[3] - best[1]) if best else np.nan, "hgt": (best[4] - best[2]) if best else np.nan,
                         "conf": best[5] if best else np.nan})
    if not rows:
        print("no tracks yet")
        return
    print(f"{len(rows)} near-court shots in {len({r['clip'] for r in rows})} clips")
    groups = {"all": rows}
    for k in ("serve", "return", "stroke"):
        groups[k] = [r for r in rows if r["kind"] == k]
    for name, g in groups.items():
        if not g:
            continue
        fnd = np.array([r["found"] for r in g])
        print(f"  {name:7s} n={len(g):4d}  racket at contact {100 * fnd.mean():3.0f}%  track cover +-15f {100 * np.mean([r['cover'] for r in g]):3.0f}%  "
              f"ids/shot {np.mean([r['n_ids'] for r in g]):.1f}  box {np.nanmedian([r['w'] for r in g]):.0f}x{np.nanmedian([r['hgt'] for r in g]):.0f}px  conf {np.nanmedian([r['conf'] for r in g]):.2f}")


if __name__ == "__main__":
    main(sys.argv[1])
