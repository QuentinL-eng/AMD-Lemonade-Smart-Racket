#!/usr/bin/env python3
"""Track rackets with SAM 3.1 in windows around hits that the F3Tennis model found (not audio, not dataset labels).

Input is a detections file {"events": [{"frame", "t_s", "type", "hitter", "conf", "peak"}], "fps": 25.0} made by
the F3Tennis tsm_e2espot run (events are on the model's 25 fps timeline). Each window is [t-1 s, t+1 s], merged when
close, cut from the source video resampled to 25 fps, and sent to sam-3.1 with the prompt "tennis racket".

Windows are spread evenly through the match, so the session covers the whole match, until the per-match frame
budget is used. A shared ledger stops the run at --budget dollars. This UPLOADS clip windows to Meta.

    python3 tools/sam_model_windows.py video.mp4 events.json --player nadal --out work/nadal --frames 11000 --plan
    python3 tools/sam_model_windows.py video.mp4 events.json --player nadal --out work/nadal --frames 11000 \
        --budget 18 --ledger work/sam_ledger.json --yes
"""
import argparse
import base64
import json
import os
import subprocess
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sam_f3set_video as sv  # noqa: E402
import sam_prefill  # noqa: E402

FPS = 25.0
WIN_S = 1.0
MERGE_GAP_S = 0.5


def windows(events, dur):
    """Merge [t-WIN_S, t+WIN_S] into [(start, end, [events])]."""
    out = []
    for e in sorted(events, key=lambda e: e["t_s"]):
        s, t = max(0.0, e["t_s"] - WIN_S), min(dur, e["t_s"] + WIN_S)
        if out and s - out[-1][1] < MERGE_GAP_S:
            out[-1][1] = t
            out[-1][2].append(e)
        else:
            out.append([s, t, [e]])
    return [(s, e, ev) for s, e, ev in out]


def cost_frames(w):
    return max(sv.MIN_FRAMES, int((w[1] - w[0]) * FPS) + 1)


def plan(wins, frame_budget):
    """Pick windows spread evenly through the match until the frame budget is used. Returns indices in time order."""
    costs = [cost_frames(w) for w in wins]
    if sum(costs) <= frame_budget:
        return list(range(len(wins)))
    # take every k-th window with a rotating offset until the budget is spent
    frac = frame_budget / sum(costs)
    chosen, acc = [], 0.0
    for i, c in enumerate(costs):
        acc += frac
        if acc >= 1.0:
            acc -= 1.0
            if sum(costs[j] for j in chosen) + c <= frame_budget:
                chosen.append(i)
    return chosen


def cut(video, s, e, dest):
    """Resample to 25 fps and cut [s, e) seconds; accurate seek, re-encoded."""
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-ss", f"{s:.3f}", "-t", f"{e - s:.3f}", "-i", video,
                    "-vf", f"fps={FPS}", "-an", "-c:v", "libx264", "-preset", "veryfast", "-crf", "24",
                    "-pix_fmt", "yuv420p", dest], check=True)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("video")
    ap.add_argument("events")
    ap.add_argument("--player", required=True)
    ap.add_argument("--out", required=True)
    ap.add_argument("--frames", type=int, required=True, help="frame budget for this video")
    ap.add_argument("--budget", type=float, default=18.0, help="total dollars across all runs (shared ledger)")
    ap.add_argument("--ledger", help="shared ledger json (default <out>/sam_ledger.json)")
    ap.add_argument("--min-conf", type=float, default=0.8, help="skip hits the model is unsure about")
    ap.add_argument("--plan", action="store_true", help="print the plan and cost, spend nothing")
    ap.add_argument("--probe", action="store_true", help="send the first chosen window only")
    ap.add_argument("--yes", action="store_true")
    a = ap.parse_args(argv)

    d = json.load(open(a.events))
    evs = [e for e in d["events"] if e["conf"] >= a.min_conf]
    dur = d["frames"] / d["fps"]
    wins = windows(evs, dur)
    pick = plan(wins, a.frames)
    frames = [cost_frames(wins[i]) for i in pick]
    nev = sum(len(wins[i][2]) for i in pick)
    print(f"{len(d['events'])} model hits, {len(evs)} with conf >= {a.min_conf}; {len(wins)} windows; "
          f"chosen {len(pick)} windows with {nev} hits, {sum(frames)} frames = ${sum(frames) * sv.PRICE_PER_FRAME:.2f}", flush=True)
    if a.plan:
        return
    if not (a.yes or a.probe):
        sys.exit("re-run with --yes to spend")

    outdir = os.path.join(a.out, "sam_video")
    os.makedirs(outdir, exist_ok=True)
    ledger_p = a.ledger or os.path.join(a.out, "sam_ledger.json")
    ledger = json.load(open(ledger_p)) if os.path.exists(ledger_p) else {"frames": 0}
    print(f"ledger {ledger['frames']} frames (${ledger['frames'] * sv.PRICE_PER_FRAME:.2f}); budget ${a.budget:.2f}")
    key = sam_prefill.api_key()
    if not key:
        sys.exit("No MUSE_API_KEY (env or repo-root .env)")
    from openai import OpenAI
    import cv2
    client = OpenAI(base_url="https://api.meta.ai/v1", api_key=key)

    done = 0
    for k, i in enumerate(pick):
        s, e, ts = wins[i]
        n = frames[k]
        name = f"{a.player}_{i:04d}"
        path = os.path.join(outdir, name + ".json")
        if os.path.exists(path):
            done += 1
            continue
        if (ledger["frames"] + n) * sv.PRICE_PER_FRAME > a.budget:
            print("budget reached", flush=True)
            break
        with tempfile.TemporaryDirectory() as td:
            clip_p = os.path.join(td, "clip.mp4")
            cut(a.video, s, e, clip_p)
            cap = cv2.VideoCapture(clip_p)
            w, h = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH)), int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
            nf = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
            cap.release()
            url = "data:video/mp4;base64," + base64.b64encode(open(clip_p, "rb").read()).decode()
        text, billed = "", None
        try:
            with client.responses.stream(
                model="sam-3.1",
                input=[{"type": "message", "role": "user", "content": [
                    {"type": "input_text", "text": "tennis racket"}, {"type": "input_video", "video_url": url}]}],
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
            print("request failed:", ex, flush=True)
            break
        ledger["frames"] += billed or n
        json.dump(ledger, open(ledger_p, "w"))
        tracks = sv.parse(text, w, h)
        evl = [{"frame": int(round((t["t_s"] - s) * FPS)), "label": "hit", "type": t["type"], "hitter": t["hitter"],
                "conf": t["conf"], "peak": t["peak"]} for t in ts]
        json.dump({"clip": name, "start": int(round(s * FPS)), "t0_s": round(s, 3), "events": evl, "width": w,
                   "height": h, "n_frames": nf, "billed": billed, "frames": tracks}, open(path, "w"))
        det = sum(1 for v in tracks.values() if v)
        print(f"{name}: {nf} frames, racket in {det}/{nf}, {len(ts)} hits ({billed or n} billed; "
              f"ledger ${ledger['frames'] * sv.PRICE_PER_FRAME:.2f})", flush=True)
        done += 1
        if a.probe:
            break
    print(f"done: {done} windows, ledger {ledger['frames']} frames (${ledger['frames'] * sv.PRICE_PER_FRAME:.2f})")


if __name__ == "__main__":
    main()
