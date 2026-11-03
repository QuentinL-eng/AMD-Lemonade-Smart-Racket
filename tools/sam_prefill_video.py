#!/usr/bin/env python3
"""Pre-fill ball and racket-head positions with Meta's SAM 3.1 VIDEO API. Drop-in cheaper replacement for sam_prefill.py.

    python3 tools/sam_prefill_video.py data/sessions/<session> --dry-run     # cost only, uploads nothing
    python3 tools/sam_prefill_video.py data/sessions/<session> --probe       # 1 impact, raw output + sam_probe.jpg
    python3 tools/sam_prefill_video.py data/sessions/<session> --n 3         # first 3 impacts
    python3 tools/sam_prefill_video.py data/sessions/<session>               # all impacts (prints the cost first)

For each impact it cuts a short clip (default 50 frames, the API minimum) around the expected contact and sends it
twice, once asking for the ball and once for the racket head. The result goes to <session>/sam_cache.json in the same
shape sam_prefill.py writes ({clip file: {frame: {"ball": [[x1,y1,x2,y2,conf]], "racket": [...]}}}), so
tools/label_video.py and tools/sam_scale.py read it unchanged. SAM only proposes; you still confirm every label.

Cost: $0.20 per 1000 video frames, 2 requests x 50 frames = $0.02 per impact (sam_prefill.py: about $0.045).
This UPLOADS video frames (including your face if it is in shot) to Meta.
Key: MUSE_API_KEY in the repo-root .env (git-ignored) or the environment. Needs: pip install openai opencv-python numpy
H.264 encoding: uses ffmpeg if it is on PATH, else OpenCV's own encoder (avc1, then mp4v as a last resort).
"""
import argparse
import base64
import csv
import json
import os
import shutil
import subprocess
import sys
import tempfile

import cv2
import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sam_prefill  # noqa: E402
from sam_f3set_video import MIN_FRAMES, PRICE_PER_FRAME, parse  # noqa: E402
from session_timing import impact_time  # noqa: E402


def write_clip(cap, first, last, width, dest):
    """Frames first..last of cap to an MP4 at `width` px wide. Returns the codec actually used."""
    cap.set(cv2.CAP_PROP_POS_FRAMES, first)
    frames = []
    for _ in range(first, last + 1):
        ok, fr = cap.read()
        if not ok:
            break
        h, w = fr.shape[:2]
        frames.append(cv2.resize(fr, (width, int(round(h * width / w) / 2) * 2)) if width < w else fr)
    if not frames:
        return None
    h, w = frames[0].shape[:2]
    if w % 2 or h % 2:
        frames = [f[: h - h % 2, : w - w % 2] for f in frames]
        h, w = h - h % 2, w - w % 2
    fps = 30.0
    ff = shutil.which("ffmpeg")
    raw = dest if not ff else dest + ".raw.mp4"
    for tag in (("mp4v",) if ff else ("avc1", "mp4v")):
        vw = cv2.VideoWriter(raw, cv2.VideoWriter_fourcc(*tag), fps, (w, h))
        if vw.isOpened():
            for f in frames:
                vw.write(f)
            vw.release()
            if ff:
                subprocess.run([ff, "-y", "-loglevel", "error", "-i", raw, "-an", "-c:v", "libx264",
                                "-preset", "veryfast", "-crf", "24", "-pix_fmt", "yuv420p", dest], check=True)
                os.remove(raw)
                return "ffmpeg h264"
            return tag
    return None


def track(client, prompt, clip_path, w, h):
    """Run one concept prompt over the clip. Returns ({frame: [[oid, x1, y1, x2, y2, conf]]}, text, billed)."""
    url = "data:video/mp4;base64," + base64.b64encode(open(clip_path, "rb").read()).decode()
    text, billed = "", None
    with client.responses.stream(
        model="sam-3.1",
        input=[{"type": "message", "role": "user",
                "content": [{"type": "input_text", "text": prompt}, {"type": "input_video", "video_url": url}]}],
        metadata={"include_confidence": "true", "mask_encoding": "one_bit"},
    ) as stream:
        for ev in stream:
            if ev.type == "response.output_text.delta":
                text += ev.delta
        try:
            billed = stream.get_final_response().usage.video_frames_processed
        except Exception:
            pass
    return parse(text, w, h), text, billed


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("session")
    ap.add_argument("--probe", action="store_true", help="one impact only; print raw output and save sam_probe.jpg")
    ap.add_argument("--dry-run", action="store_true", help="print the cost and exit without uploading")
    ap.add_argument("--n", type=int, help="only the first N impacts")
    ap.add_argument("--frames", type=int, default=MIN_FRAMES, help=f"frames per clip, centred on contact (min {MIN_FRAMES})")
    ap.add_argument("--ball", default="tennis ball")
    ap.add_argument("--racket", default="racket head")
    ap.add_argument("--width", type=int, default=640, help="clip width in px before upload")
    ap.add_argument("--yes", action="store_true", help="skip the cost confirmation")
    a = ap.parse_args()
    nfr = max(MIN_FRAMES, a.frames)

    d = a.session
    clips = list(csv.DictReader(open(os.path.join(d, "clips.csv"))))[: a.n]
    ft = np.array([float(r["t_s"]) for r in csv.DictReader(open(os.path.join(d, "frames.csv")))])
    cap = cv2.VideoCapture(os.path.join(d, "video.avi"))
    total = min(int(cap.get(cv2.CAP_PROP_FRAME_COUNT)), len(ft))
    W, H = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH)), int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    cache_p = os.path.join(d, "sam_cache.json")
    cache = json.load(open(cache_p)) if os.path.exists(cache_p) else {}

    todo = []
    for c in clips:
        g = int(np.searchsorted(ft, impact_time(c)))
        first = max(0, min(g - nfr // 2, total - nfr))
        last = min(total - 1, first + nfr - 1)
        if last < first:
            continue
        have = cache.get(c["file"], {})
        if sum(1 for f in range(first, last + 1) if str(f) in have) >= (last - first + 1) // 2:
            continue                                    # already prefilled (by either script)
        todo.append((c, first, last))
    if a.probe:
        todo = todo[len(todo) // 2: len(todo) // 2 + 1]

    billed_frames = sum(2 * max(MIN_FRAMES, l - f + 1) for _, f, l in todo)
    print(f"{len(todo)} impacts x 2 prompts, about {billed_frames} frames = ${billed_frames * PRICE_PER_FRAME:.2f} "
          f"at $0.20 per 1000 frames.")
    if not todo or a.dry_run:
        return
    key = sam_prefill.api_key()
    if not key:
        sys.exit("No key: put MUSE_API_KEY=... in the repo-root .env (or set it in the environment).")
    if not (a.yes or a.probe or a.n) and input("Upload these clips to Meta? [y/N] ").lower() != "y":
        return

    from openai import OpenAI
    client = OpenAI(base_url="https://api.meta.ai/v1", api_key=key)

    spent = 0
    for k, (c, first, last) in enumerate(todo):
        with tempfile.TemporaryDirectory() as td:
            clip_p = os.path.join(td, "clip.mp4")
            codec = write_clip(cap, first, last, a.width, clip_p)
            if codec is None:
                print(f"impact {c['n']}: could not write a clip, skipped")
                continue
            if k == 0:
                print("encoder:", codec + ("  (not H.264: install ffmpeg if the API rejects it)" if codec == "mp4v" else ""))
            res = {}
            for name, prompt in (("ball", a.ball), ("racket", a.racket)):
                try:
                    tracks, text, billed = track(client, prompt, clip_p, W, H)
                except Exception as e:                  # network / quota / bad codec: keep what we have
                    print("request failed:", e)
                    json.dump(cache, open(cache_p, "w"))
                    sys.exit(1)
                spent += billed or max(MIN_FRAMES, last - first + 1)
                res[name] = tracks
                if a.probe:
                    print(f"--- {name} ({prompt!r}) raw ---\n{text[:600]}")
        # clip frame i is video frame first + i. Keep the same {frame: {ball, racket}} shape as sam_prefill.py.
        entry = cache.setdefault(c["file"], {})
        nb = nr = 0
        for i in range(last - first + 1):
            balls = [r[1:] for r in res["ball"].get(i, [])]
            heads = [r[1:] for r in res["racket"].get(i, [])]
            nb += bool(balls)
            nr += bool(heads)
            entry[str(first + i)] = {"ball": balls, "racket": heads}
        json.dump(cache, open(cache_p, "w"))
        print(f"{k + 1}/{len(todo)}  impact {c['n']} frames {first}-{last}: ball in {nb}, racket in {nr}; "
              f"total ${spent * PRICE_PER_FRAME:.2f}", flush=True)
        if a.probe:
            from label_video import suggest
            sug = suggest(entry)
            if not sug:
                print("no frame has both a ball and a racket head; check the raw output above")
                break
            f, ball, head = sug
            cap.set(cv2.CAP_PROP_POS_FRAMES, f)
            ok, v = cap.read()
            if ok:
                cv2.circle(v, ball, 8, (0, 255, 255), 2)
                cv2.drawMarker(v, head, (255, 128, 0), cv2.MARKER_CROSS, 24, 2)
                out = os.path.join(d, "sam_probe.jpg")
                cv2.imwrite(out, v)
                print(f"best frame {f}: ball {ball}, head centre {head}; wrote {out}")


if __name__ == "__main__":
    main()
