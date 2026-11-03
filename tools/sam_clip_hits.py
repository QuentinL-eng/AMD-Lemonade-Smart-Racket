#!/usr/bin/env python3
"""Track rackets through contact windows of an arbitrary clip with SAM 3.1 video.

1. Detect ball-hit transients in the audio (no labels needed).
2. Cut +1 s windows around them, merge overlaps, send each to sam-3.1.
3. Write sam_video/<clip>.json in the tools/sam_f3set_video.py schema, with
   events labelled "hit" (no kind/hand: the pixels can't honestly say).

Cost control: prints the frame/$ estimate, needs --yes, stops at --budget
(shared ledger across runs). This UPLOADS clip windows to Meta.

    python3 tools/sam_clip_hits.py clip.mp4 --player alcaraz --out work --probe
    python3 tools/sam_clip_hits.py clip.mp4 --player alcaraz --out work --budget 5 --yes
"""
import argparse
import base64
import json
import os
import subprocess
import sys
import tempfile
import wave

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sam_f3set_video as sv  # noqa: E402
import sam_prefill  # noqa: E402

WIN_S = 1.0          # +- seconds around each contact
MERGE_GAP_S = 0.5    # join windows closer than this
MIN_SEP_S = 1.0      # contacts can't be closer than this


def read_mono_wav(path, sr=16000):
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tf:
        tmp = tf.name
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", path, "-ac", "1", "-ar", str(sr),
                    "-c:a", "pcm_s16le", tmp], check=True)
    try:
        with wave.open(tmp, "rb") as w:
            n = w.getnframes()
            y = np.frombuffer(w.readframes(n), dtype=np.int16).astype(np.float64) / 32768.0
        return y, sr
    finally:
        os.unlink(tmp)


def find_contacts(y, sr):
    """Attack-transient peaks (ball hits): times in seconds, best-first filtered.

    Hits are sharp broadband bursts: strong 30 ms attack energy far above the
    local median. Crowd swells and commentary rise slowly and fail the attack test.
    """
    win = max(1, int(0.008 * sr))
    attack = np.convolve(np.abs(np.diff(y, prepend=y[0])), np.ones(win) / win, mode="same")
    med = np.median(attack)
    mad = np.median(np.abs(attack - med)) + 1e-9
    thr = med + 8 * mad
    cand = np.where(attack > thr)[0]
    if len(cand) == 0:
        return []
    # local maxima within +-0.5 s, min separation MIN_SEP_S
    half, groups, out = int(0.5 * sr), [], []
    for i in cand:
        if groups and i - groups[-1][-1] <= half:
            groups[-1].append(i)
        else:
            groups.append([i])
    for g in groups:
        g = np.array(g)
        peak = g[np.argmax(attack[g])]
        lo, hi = max(0, peak - 2 * sr), min(len(attack), peak + 2 * sr)
        if attack[peak] > 3 * np.median(attack[lo:hi]) + 1e-9:
            out.append(peak / sr)
    out.sort()
    return [t for i, t in enumerate(out) if i == 0 or t - out[i - 1] >= MIN_SEP_S]


def windows(contacts, dur):
    """Merge [t-WIN_S, t+WIN_S] windows; returns [(start_s, end_s, [contacts])]."""
    wins = []
    for t in contacts:
        s, e = max(0.0, t - WIN_S), min(dur, t + WIN_S)
        if wins and s - wins[-1][1] < MERGE_GAP_S:
            wins[-1][1] = e
            wins[-1][2].append(t)
        else:
            wins.append([s, e, [t]])
    return [(s, e, ts) for s, e, ts in wins]


def fps_of(video):
    import cv2
    cap = cv2.VideoCapture(video)
    fps = cap.get(cv2.CAP_PROP_FPS) or 30.0
    n = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    cap.release()
    return fps, n / fps if fps else 0.0


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("video")
    ap.add_argument("--player", required=True)
    ap.add_argument("--out", required=True, help="work dir (sam_video/, ledger)")
    ap.add_argument("--budget", type=float, default=10.0, help="total dollars incl. ledger")
    ap.add_argument("--max-windows", type=int, default=0, help="cap windows per run (0 = all)")
    ap.add_argument("--probe", action="store_true", help="detect + send first window only")
    ap.add_argument("--force", action="store_true", help="run despite odd contact count")
    ap.add_argument("--yes", action="store_true", help="confirm the printed cost")
    a = ap.parse_args(argv)

    y, sr = read_mono_wav(a.video)
    contacts = find_contacts(y, sr)
    fps, dur = fps_of(a.video)
    gaps = np.diff(contacts) if len(contacts) > 1 else []
    print(f"{len(contacts)} contacts in {dur:.0f} s" +
          (f", mean gap {gaps.mean():.1f} s" if len(gaps) else ""), flush=True)
    mean_gap = float(gaps.mean()) if len(gaps) else dur
    if (len(contacts) < 5 or mean_gap < 1.0) and not a.force:
        sys.exit("contact pattern looks wrong (music? commentary?); inspect or --force")
    wins = windows(contacts, dur)
    frames = [max(sv.MIN_FRAMES, int((e - s) * fps) + 1) for s, e, _ in wins]
    print(f"{len(wins)} windows, {sum(frames)} frames = ${sum(frames) * sv.PRICE_PER_FRAME:.2f}", flush=True)

    outdir = os.path.join(a.out, "sam_video")
    os.makedirs(outdir, exist_ok=True)
    ledger_p = os.path.join(a.out, "sam_ledger.json")
    ledger = json.load(open(ledger_p)) if os.path.exists(ledger_p) else {"frames": 0}
    print(f"ledger {ledger['frames']} frames (${ledger['frames'] * sv.PRICE_PER_FRAME:.2f}); budget ${a.budget:.2f}")
    if not a.yes and not a.probe:
        sys.exit("re-run with --yes to spend")
    key = sam_prefill.api_key()
    if not key:
        sys.exit("No MUSE_API_KEY (env or repo-root .env)")
    from openai import OpenAI
    client = OpenAI(base_url="https://api.meta.ai/v1", api_key=key)

    import cv2
    done = 0
    if a.max_windows:
        wins, frames = wins[:a.max_windows], frames[:a.max_windows]
        print(f"capped to {len(wins)} windows", flush=True)
    for i, ((s, e, ts), n) in enumerate(zip(wins, frames)):
        name = f"{a.player}_{i:03d}"
        if os.path.exists(os.path.join(outdir, name + ".json")):
            print(f"{name}: cached, skip", flush=True)
            done += 1
            continue
        if (ledger["frames"] + n) * sv.PRICE_PER_FRAME > a.budget:
            print("budget reached")
            break
        f0, f1 = int(s * fps), int(e * fps)
        with tempfile.TemporaryDirectory() as td:
            clip_p = os.path.join(td, "clip.mp4")
            sv.cut(a.video, f0, f1, clip_p)
            cap = cv2.VideoCapture(clip_p)
            w, h = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH)), int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
            nf = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
            url = "data:video/mp4;base64," + base64.b64encode(open(clip_p, "rb").read()).decode()
        text, billed = "", None
        try:
            with client.responses.stream(
                model="sam-3.1",
                input=[{"type": "message", "role": "user", "content": [
                    {"type": "input_text", "text": "tennis racket"},
                    {"type": "input_video", "video_url": url}]}],
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
        tracks = sv.parse(text, w, h)
        evs = [{"frame": int((t - s) * fps), "label": "hit"} for t in ts]
        json.dump({"clip": name, "start": f0, "events": evs, "width": w, "height": h,
                   "n_frames": nf, "billed": billed, "frames": tracks},
                  open(os.path.join(outdir, name + ".json"), "w"))
        det = sum(1 for v in tracks.values() if v)
        print(f"{name}: {nf} frames, racket in {det}/{nf} ({(billed or n)} billed)", flush=True)
        done += 1
        if a.probe:
            break
    print(f"done: {done} windows, ledger {ledger['frames']} frames "
          f"(${ledger['frames'] * sv.PRICE_PER_FRAME:.2f})")


if __name__ == "__main__":
    main()
