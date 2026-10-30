#!/usr/bin/env python3
"""Track rackets through F3Set clips with Meta's SAM 3.1 video API ($0.20 per 1000 frames, 50-frame minimum).

    python3 tools/sam_f3set_video.py ~/tennis_data/f3set --clips 1 --show     # one clip, prints raw output
    python3 tools/sam_f3set_video.py ~/tennis_data/f3set --clips 10           # a pilot
    python3 tools/sam_f3set_video.py ~/tennis_data/f3set --clips 80 --budget 25

Cuts each labelled clip out of f3set/videos/<match>.mp4 with ffmpeg, sends it with the concept prompt "tennis racket",
and writes f3set/sam_video/<clip>.json: {frame: [[object_id, x1, y1, x2, y2, conf], ...]}. A ledger
(f3set/sam_video_ledger.json) counts frames billed across runs; the run stops at --budget. This UPLOADS broadcast
footage to Meta.
"""
import argparse
import base64
import json
import os
import random
import re
import subprocess
import sys
import tempfile

import cv2

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sam_prefill  # noqa: E402

PRICE_PER_FRAME = 0.20 / 1000
MIN_FRAMES = 50
FRAME = re.compile(r"<(\d+)f>")
REC = re.compile(r"(\d+)<\|box;x1=(-?\d+);y1=(-?\d+);x2=(-?\d+);y2=(-?\d+);w=(\d+);h=(\d+)(?:;c=([\d.]+))?\|>")


def parse(text, w_out, h_out):
    """{frame: [[object_id, x1, y1, x2, y2, conf], ...]} in the clip's pixels."""
    parts = FRAME.split(text)
    out = {}
    for i in range(1, len(parts), 2):
        frame = int(parts[i])
        recs = []
        for oid, x1, y1, x2, y2, w, h, c in REC.findall(parts[i + 1]):
            sx, sy = w_out / int(w), h_out / int(h)
            recs.append([int(oid), int(x1) * sx, int(y1) * sy, (int(x2) + 1) * sx, (int(y2) + 1) * sy, float(c) if c else 1.0])
        out[frame] = recs
    return out


def cut(video, start, end, dest):
    """Frames start..end inclusive, re-encoded H.264 (the API wants MP4/H.264)."""
    vf = f"select='between(n,{start},{end})',setpts=N/FRAME_RATE/TB"
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", video, "-vf", vf, "-an", "-c:v", "libx264",
                    "-preset", "veryfast", "-crf", "24", "-pix_fmt", "yuv420p", dest], check=True)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("root")
    ap.add_argument("--clips", type=int, default=1)
    ap.add_argument("--prompt", default="tennis racket")
    ap.add_argument("--budget", type=float, default=25.0, help="total dollars across all runs")
    ap.add_argument("--seed", type=int, default=0)
    ap.add_argument("--per-match", type=int, default=0, help="at most this many clips per match across all runs (0 = no limit)")
    ap.add_argument("--show", action="store_true")
    a = ap.parse_args()

    root = os.path.expanduser(a.root)
    vdir = os.path.join(root, "videos")
    videos = {f[:-4] for f in os.listdir(vdir) if f.endswith(".mp4")}
    clips = []
    for split in ("train", "val", "test"):
        for c in json.load(open(os.path.join(root, "repo/data/f3tennis", f"{split}.json"))):
            match, s, e = c["video"].rsplit("_", 2)
            if match in videos and any(ev["label"].startswith("near_") for ev in c["events"]):
                clips.append({"clip": c["video"], "match": match, "start": int(s), "end": int(e), "events": c["events"]})
    random.Random(a.seed).shuffle(clips)

    outdir = os.path.join(root, "sam_video")
    os.makedirs(outdir, exist_ok=True)
    ledger_p = os.path.join(root, "sam_video_ledger.json")
    ledger = json.load(open(ledger_p)) if os.path.exists(ledger_p) else {"frames": 0}
    have = {}
    for f in os.listdir(outdir):
        m = f.rsplit("_", 2)[0]
        have[m] = have.get(m, 0) + 1
    todo = []
    for c in clips:
        if os.path.exists(os.path.join(outdir, c["clip"] + ".json")):
            continue
        if a.per_match and have.get(c["match"], 0) >= a.per_match:
            continue
        have[c["match"]] = have.get(c["match"], 0) + 1
        todo.append(c)
        if len(todo) >= a.clips:
            break
    est = sum(max(MIN_FRAMES, c["end"] - c["start"] + 1) for c in todo)
    print(f"{len(todo)} clips, about {est} frames (${est * PRICE_PER_FRAME:.2f}); ledger {ledger['frames']} frames "
          f"(${ledger['frames'] * PRICE_PER_FRAME:.2f}); budget ${a.budget:.2f}", flush=True)
    key = sam_prefill.api_key()
    if not key:
        sys.exit("No key (see sam_prefill.py)")
    from openai import OpenAI
    client = OpenAI(base_url="https://api.meta.ai/v1", api_key=key)

    for c in todo:
        n = max(MIN_FRAMES, c["end"] - c["start"] + 1)
        if (ledger["frames"] + n) * PRICE_PER_FRAME > a.budget:
            print("budget reached")
            break
        with tempfile.TemporaryDirectory() as td:
            clip_p = os.path.join(td, "clip.mp4")
            cut(os.path.join(vdir, c["match"] + ".mp4"), c["start"], c["end"], clip_p)
            cap = cv2.VideoCapture(clip_p)
            w, h = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH)), int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
            nf = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
            url = "data:video/mp4;base64," + base64.b64encode(open(clip_p, "rb").read()).decode()
        text, billed = "", None
        try:
            with client.responses.stream(
                model="sam-3.1",
                input=[{"type": "message", "role": "user",
                        "content": [{"type": "input_text", "text": a.prompt}, {"type": "input_video", "video_url": url}]}],
                metadata={"include_confidence": "true", "mask_encoding": "one_bit"},
            ) as stream:
                for ev in stream:
                    if ev.type == "response.output_text.delta":
                        text += ev.delta
                try:
                    billed = stream.get_final_response().usage.video_frames_processed
                except Exception:
                    pass
        except Exception as ex:
            print("request failed:", ex)
            break
        ledger["frames"] += billed or n
        json.dump(ledger, open(ledger_p, "w"))
        tracks = parse(text, w, h)
        json.dump({"clip": c["clip"], "start": c["start"], "events": c["events"], "width": w, "height": h,
                   "n_frames": nf, "billed": billed, "frames": tracks}, open(os.path.join(outdir, c["clip"] + ".json"), "w"))
        det = sum(1 for v in tracks.values() if v)
        print(f"{c['clip'][-40:]}: {nf} frames, racket in {det} of them, ids {sorted({r[0] for v in tracks.values() for r in v})[:8]}, "
              f"billed {billed}; total ${ledger['frames'] * PRICE_PER_FRAME:.2f}", flush=True)
        if a.show:
            print("raw:", text[:700])


if __name__ == "__main__":
    main()
