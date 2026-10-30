#!/usr/bin/env python3
"""Find the racket in F3Set broadcast frames around labelled shots, with Meta's SAM 3.1 API.

    python3 tools/sam_f3set.py ~/tennis_data/f3set --probe            # 2 images, prints raw output, saves probe.jpg
    python3 tools/sam_f3set.py ~/tennis_data/f3set --events 30        # a pilot
    python3 tools/sam_f3set.py ~/tennis_data/f3set --events 400 --budget 15

Needs f3set/repo (labels) and f3set/videos/<match>.mp4. For each chosen near-court shot it sends the frames at the
labelled contact frame and a few either side, one image per frame ($2.50 per 1000 images), and appends the boxes to
f3set/sam_racket.jsonl. A ledger (f3set/sam_ledger.json) counts every image sent across runs and the run stops at
--budget. This UPLOADS broadcast frames to Meta.
"""
import argparse
import json
import os
import random
import sys

import cv2

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sam_prefill  # noqa: E402

PRICE_PER_IMAGE = 2.5 / 1000


def load_events(root, videos):
    out = []
    for split in ("train", "val", "test"):
        for c in json.load(open(os.path.join(root, "repo/data/f3tennis", f"{split}.json"))):
            match, start, _ = c["video"].rsplit("_", 2)
            if match not in videos:
                continue
            for e in c["events"]:
                if e["label"].startswith("near_"):
                    kind = e["label"].split("_")[2]
                    hand = e["label"].split("_")[3]
                    out.append({"match": match, "frame": int(start) + e["frame"], "label": e["label"],
                                "kind": kind, "hand": hand, "fps": c["fps"]})
    return out


def pick(events, n, seed=0):
    """Spread the pick over serve / return / stroke x fh / bh."""
    rng = random.Random(seed)
    groups = {}
    for e in events:
        groups.setdefault((e["kind"], e["hand"]), []).append(e)
    for g in groups.values():
        rng.shuffle(g)
    chosen = []
    while len(chosen) < n and any(groups.values()):
        for g in groups.values():
            if g and len(chosen) < n:
                chosen.append(g.pop())
    return chosen


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("root")
    ap.add_argument("--events", type=int, default=30)
    ap.add_argument("--offsets", default="-6,-3,0,3,6", help="frames relative to the labelled contact")
    ap.add_argument("--prompt", default="tennis racket")
    ap.add_argument("--width", type=int, default=1280)
    ap.add_argument("--budget", type=float, default=25.0, help="total dollars across all runs")
    ap.add_argument("--probe", action="store_true")
    ap.add_argument("--draw", type=int, default=12, help="save this many annotated frames to annotated/")
    a = ap.parse_args()

    root = os.path.expanduser(a.root)
    vdir = os.path.join(root, "videos")
    videos = {f[:-4] for f in os.listdir(vdir) if f.endswith(".mp4")}
    events = pick(load_events(root, videos), 1 if a.probe else a.events)
    offsets = [int(x) for x in a.offsets.split(",")] if not a.probe else [0]
    ledger_p = os.path.join(root, "sam_ledger.json")
    ledger = json.load(open(ledger_p)) if os.path.exists(ledger_p) else {"images": 0}
    out_p = os.path.join(root, "sam_racket.jsonl")
    done = set()
    if os.path.exists(out_p):
        for line in open(out_p):
            r = json.loads(line)
            done.add((r["match"], r["frame"], r["prompt"], r["width"]))

    todo = [(e, e["frame"] + o) for e in events for o in offsets if (e["match"], e["frame"] + o, a.prompt, a.width) not in done]
    spend = ledger["images"] * PRICE_PER_IMAGE
    room = int((a.budget - spend) / PRICE_PER_IMAGE)
    print(f"{len(todo)} images to send (${len(todo) * PRICE_PER_IMAGE:.2f}); ledger so far {ledger['images']} images "
          f"(${spend:.2f}); budget ${a.budget:.2f} leaves room for {room}.")
    todo = todo[: max(room, 0)]
    if not todo:
        return
    key = sam_prefill.api_key()
    if not key:
        sys.exit("No key (see sam_prefill.py)")
    from openai import OpenAI
    client = OpenAI(base_url="https://api.meta.ai/v1", api_key=key)

    os.makedirs(os.path.join(root, "annotated"), exist_ok=True)
    caps = {}
    drawn = 0
    with open(out_p, "a") as out:
        for k, (e, f) in enumerate(todo):
            cap = caps.setdefault(e["match"], cv2.VideoCapture(os.path.join(vdir, e["match"] + ".mp4")))
            cap.set(cv2.CAP_PROP_POS_FRAMES, f)
            ok, frame = cap.read()
            if not ok:
                continue
            try:
                text, boxes = sam_prefill.ask(client, a.prompt, frame, a.width)
            except Exception as ex:
                print("request failed:", ex)
                break
            ledger["images"] += 1
            json.dump(ledger, open(ledger_p, "w"))
            rec = {"match": e["match"], "frame": f, "contact_frame": e["frame"], "label": e["label"],
                   "prompt": a.prompt, "width": a.width, "boxes": boxes}
            out.write(json.dumps(rec) + "\n")
            out.flush()
            if a.probe:
                print("raw:", text[:800])
                print("boxes:", boxes)
            if boxes and (a.probe or (drawn < a.draw and f == e["frame"])):
                img = frame.copy()
                for b in boxes:
                    cv2.rectangle(img, (int(b[0]), int(b[1])), (int(b[2]), int(b[3])), (0, 255, 0), 2)
                    cv2.putText(img, f"{b[4]:.2f}", (int(b[0]), max(int(b[1]) - 4, 12)), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 0), 2)
                name = "probe.jpg" if a.probe else f"annotated/{drawn:02d}_{e['label'][:40]}_{f}.jpg"
                cv2.imwrite(os.path.join(root, name), img)
                drawn += 1
            if (k + 1) % 25 == 0:
                print(f"{k + 1}/{len(todo)}  spent ${ledger['images'] * PRICE_PER_IMAGE:.2f}")
    print(f"done; total images {ledger['images']} (${ledger['images'] * PRICE_PER_IMAGE:.2f})")


if __name__ == "__main__":
    main()
