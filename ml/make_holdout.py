"""Freeze a random 10% control set that no model may train or tune on.

    python ml/make_holdout.py            # writes ml/holdout.json once; refuses to overwrite it

"Good data" is every label in a session's labels.csv (reviewed rejects in discarded.txt are never included).
The split is random but drawn over blocks of 8 consecutive impacts, not single clips: throws seconds apart share the
grip, aim and camera state, so holding out single clips would leak the training set into the control set.
Blocks are added in seeded random order until at least 10% of all good clips are held out.
ml/train_combined.py skips every clip listed here.
"""
import csv
import hashlib
import json
import math
from pathlib import Path

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "ml/holdout.json"
SESSIONS = ["20261027-224032-long-1", "20261028-155849-long-run2", "20261103-122017-third-session"]
BLOCK = 8
FRACTION = 0.10
SEED = 20261103


def read_csv(p):
    with p.open(newline="") as fh:
        return list(csv.DictReader(fh))


def main():
    if OUT.exists():
        raise SystemExit(f"{OUT} exists. The control set is frozen; delete it only to start a new experiment.")
    good, total = [], 0
    for s in SESSIONS:
        d = ROOT / "data/sessions" / s
        n_of = {r["file"]: int(r["n"]) for r in read_csv(d / "clips.csv")}
        for r in read_csv(d / "labels.csv"):
            good.append({"session": s, "file": r["file"], "dist_cm": float(r["dist_cm"]),
                         "block": (n_of[r["file"]] - 1) // BLOCK,
                         "sha256": hashlib.sha256((d / r["file"]).read_bytes()).hexdigest()})
    blocks = sorted({(g["session"], g["block"]) for g in good})
    rng = np.random.default_rng(SEED)
    order = [blocks[i] for i in rng.permutation(len(blocks))]
    want = math.ceil(FRACTION * len(good))
    chosen, held = set(), 0
    for b in order:
        if held >= want:
            break
        chosen.add(b)
        held += sum(1 for g in good if (g["session"], g["block"]) == b)
    clips = [g for g in good if (g["session"], g["block"]) in chosen]
    json.dump({"seed": SEED, "block_size": BLOCK, "fraction": FRACTION, "good_clips": len(good), "held_out": len(clips),
               "blocks": sorted([list(b) for b in chosen]), "clips": clips}, OUT.open("w"), indent=1)
    print(f"{len(clips)} of {len(good)} good clips held out ({100 * len(clips) / len(good):.1f}%) in {len(chosen)} blocks")
    for s in SESSIONS:
        k = [c for c in clips if c["session"] == s]
        print(f"  {s}: {len(k)} held out, {sum(c['dist_cm'] <= 4 for c in k)} sweet (<=4 cm)")


if __name__ == "__main__":
    main()
