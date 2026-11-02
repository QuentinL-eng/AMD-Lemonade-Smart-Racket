#!/usr/bin/env python3
"""Racket head speed from a TennisCamera session's 240 fps video, to check the gyro's scale independently.

    python3 tools/sam_session_racket.py "data/Tennis Camera/<session>" --hits 5

For the hits with the most complete IMU data it cuts a window around the impact (phone clock, from
imu_aligned.npz written by tools/phone_session.py), sends it to Meta's SAM 3.1 video API with the prompt "tennis
racket", and compares the racket's peak image speed with what the gyro implies (|omega_yz| * R). Scale comes from the
box's long side taken as the racket length (0.686 m) and corrected from box centre to sweet spot, so expect +-25%: this is for telling 2x from 1x, not for fine
calibration. Spend is added to data/external/f3set/sam_video_ledger.json. UPLOADS footage to Meta.
"""
import argparse
import base64
import json
import os
import subprocess
import sys
import tempfile

import cv2
import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sam_prefill  # noqa: E402
from sam_f3set_video import PRICE_PER_FRAME, cut, parse  # noqa: E402

LEDGER = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "data/external/f3set/sam_video_ledger.json")
RACKET_LEN_M, R_APP = 0.686, 1.15
# Racket geometry from the CAD picture: sweet spot 0.521 m from the butt (0.480 m from the IMU), box centre at half length.
# The box centre moves slower than the sweet spot: (pivot + 0.521) / (pivot + 0.343), pivot = hand-to-rotation-centre
# distance behind the butt (about 0.65 m for a forehand; 0.5-0.8 changes the factor only from 1.21 to 1.16).
SWEET_FROM_BUTT_M, PIVOT_M = 0.521, 0.65
SWEET_OVER_CENTRE = (PIVOT_M + SWEET_FROM_BUTT_M) / (PIVOT_M + RACKET_LEN_M / 2)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("session")
    ap.add_argument("--hits", type=int, default=5)
    ap.add_argument("--pre", type=float, default=0.7, help="seconds before the impact")
    ap.add_argument("--post", type=float, default=0.3)
    ap.add_argument("--budget", type=float, default=25.0)
    a = ap.parse_args()

    z = np.load(os.path.join(a.session, "imu_aligned.npz"))
    t, gyr, imp = z["t_phone_s"], z["gyro_rad_s"], z["impacts_phone_s"]
    video_t = np.fromfile(os.path.join(a.session, "video_frames.bin"), dtype="<u8").astype(np.float64) / 1e9
    video = os.path.join(a.session, "video.mov")

    cands = []
    for ti in imp:
        lo, hi = np.searchsorted(t, ti - 0.35), np.searchsorted(t, ti)
        cover = (hi - lo) / 350.0
        j = np.searchsorted(t, ti) - 5
        if j < 20 or cover < 0.9:
            continue
        w = gyr[j - 10:j - 2].mean(0)
        # Calibration.default: the shaft (racket x) is sensor y, so across the shaft is sensor x and z
        cands.append((cover, ti, float(np.hypot(w[0], w[2])), float(np.linalg.norm(w))))
    cands.sort(reverse=True)
    picks = sorted(cands[: a.hits], key=lambda c: c[1])
    print(f"{len(cands)} hits with >=90% IMU coverage before contact; using {len(picks)}")

    ledger = json.load(open(LEDGER)) if os.path.exists(LEDGER) else {"frames": 0}
    key = sam_prefill.api_key()
    if not key:
        sys.exit("No key (see sam_prefill.py)")
    from openai import OpenAI
    client = OpenAI(base_url="https://api.meta.ai/v1", api_key=key)
    out_dir = os.path.join(a.session, "sam_racket")
    os.makedirs(out_dir, exist_ok=True)
    results = []
    for k, (cover, ti, w_yz, w_all) in enumerate(picks):
        f0, f1 = int(np.searchsorted(video_t, ti - a.pre)), int(np.searchsorted(video_t, ti + a.post))
        n = f1 - f0 + 1
        if (ledger["frames"] + n) * PRICE_PER_FRAME > a.budget:
            print("budget reached")
            break
        with tempfile.TemporaryDirectory() as td:
            clip = os.path.join(td, "c.mp4")
            cut(video, f0, f1, clip)
            cap = cv2.VideoCapture(clip)
            w, h = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH)), int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
            url = "data:video/mp4;base64," + base64.b64encode(open(clip, "rb").read()).decode()
        text = ""
        with client.responses.stream(
            model="sam-3.1",
            input=[{"type": "message", "role": "user",
                    "content": [{"type": "input_text", "text": "tennis racket"}, {"type": "input_video", "video_url": url}]}],
            metadata={"include_confidence": "true", "mask_encoding": "one_bit"},
        ) as stream:
            for ev in stream:
                if ev.type == "response.output_text.delta":
                    text += ev.delta
        ledger["frames"] += n
        json.dump(ledger, open(LEDGER, "w"))
        tr = parse(text, w, h)
        # follow the highest-confidence box per frame; speed of its centre between frames
        base = min(tr) if tr else 0                       # SAM numbers frames from 0 or 1
        cen, longside = [], []
        for f in range(n):
            bs = tr.get(base + f, [])
            if not bs:
                cen.append((np.nan, np.nan)); longside.append(np.nan); continue
            b = max(bs, key=lambda b: b[5])
            cen.append(((b[1] + b[3]) / 2, (b[2] + b[4]) / 2)); longside.append(max(b[3] - b[1], b[4] - b[2]))
        cen = np.array(cen)
        dt = np.median(np.diff(video_t[f0:f1 + 1]))
        step = np.hypot(*np.diff(cen, axis=0).T) / dt                  # px/s between consecutive frames
        step[np.hypot(*np.diff(cen, axis=0).T) > 0.25 * w] = np.nan        # a jump to another object
        ls = np.nanmedian(longside)
        scale = RACKET_LEN_M / ls if ls > 0 else np.nan               # m/px
        peak_px = np.nanpercentile(step, 95) if np.isfinite(step).any() else np.nan
        v_video = peak_px * scale * SWEET_OVER_CENTRE       # box-centre speed -> sweet-spot speed
        v_gyro = w_yz * R_APP
        results.append({"impact_s": float(ti), "coverage": cover, "frames": n, "found": int(np.isfinite(cen[:, 0]).sum()),
                        "box_long_px": float(ls), "peak_px_s": float(peak_px), "v_video_ms": float(v_video),
                        "w_yz_rad_s": w_yz, "v_gyro_ms": float(v_gyro), "ratio_gyro_over_video": float(v_gyro / v_video) if v_video else None})
        print(f"hit {k + 1}: found racket in {results[-1]['found']}/{n} frames, box {ls:.0f}px; "
              f"video peak ~{v_video:.1f} m/s vs gyro {w_yz:.1f} rad/s x {R_APP} = {v_gyro:.1f} m/s  (gyro/video {v_gyro / v_video:.2f})"
              f"   [${ledger['frames'] * PRICE_PER_FRAME:.2f} spent]", flush=True)
    json.dump(results, open(os.path.join(out_dir, "summary.json"), "w"), indent=1)
    r = [x["ratio_gyro_over_video"] for x in results if x["ratio_gyro_over_video"]]
    if r:
        print(f"\nmedian gyro/video speed ratio {np.median(r):.2f} over {len(r)} hits (1.0 = gyro scale right; about 2 = still 2x high)")


if __name__ == "__main__":
    main()
