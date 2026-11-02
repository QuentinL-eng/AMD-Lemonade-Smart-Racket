"""Cached SAM 3.1 video observations for contact review, never stroke truth.

Sends only bounded clips to the existing Meta endpoint. Each returned frame maps
back to an exact source frame and capture timestamp. No secrets enter artifacts.
"""
import argparse
import base64
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor, as_completed

import cv2
import numpy as np

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT/"tools"))
from sam_prefill import api_key
from sam_f3set_video import parse


def atomic_json(path, value):
    tmp = path.with_suffix(".tmp")
    tmp.write_text(json.dumps(value, indent=2)+"\n")
    tmp.replace(path)


def clip_bytes(source, start, count, width=960):
    cap = cv2.VideoCapture(str(source))
    cap.set(cv2.CAP_PROP_POS_FRAMES, start)
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT)*width/cap.get(cv2.CAP_PROP_FRAME_WIDTH))//2*2
    with tempfile.TemporaryDirectory() as td:
        output = Path(td)/"clip.mp4"
        process = subprocess.Popen(["ffmpeg", "-y", "-loglevel", "error", "-f", "rawvideo", "-pix_fmt", "bgr24",
                                    "-s", f"{width}x{height}", "-r", "240", "-i", "pipe:0", "-an", "-c:v", "libx264",
                                    "-threads", "2", "-preset", "veryfast", "-crf", "23", "-pix_fmt", "yuv420p", str(output)],
                                   stdin=subprocess.PIPE, stderr=subprocess.PIPE)
        try:
            for _ in range(count):
                ok, frame = cap.read()
                if not ok:
                    raise ValueError("Video ended inside requested clip")
                process.stdin.write(cv2.resize(frame, (width, height)).tobytes())
            process.stdin.close()
            code = process.wait(timeout=30)
            if code:
                raise ValueError("Clip encoder failed")
            data = output.read_bytes()
        finally:
            cap.release()
            if process.poll() is None:
                process.kill(); process.wait()
    return data, width, height


def request(key, source, job):
    from openai import OpenAI
    data, width, height = clip_bytes(source, job["start_frame"], job["n_frames"])
    client = OpenAI(base_url="https://api.meta.ai/v1", api_key=key, timeout=120, max_retries=0)
    url = "data:video/mp4;base64,"+base64.b64encode(data).decode()
    output, billed = "", None
    with client.responses.stream(model="sam-3.1", input=[{"type": "message", "role": "user", "content": [
            {"type": "input_text", "text": job["prompt"]}, {"type": "input_video", "video_url": url}]}],
            metadata={"include_confidence": "true", "mask_encoding": "one_bit"}) as stream:
        for event in stream:
            if event.type == "response.output_text.delta":
                output += event.delta
        try:
            billed = stream.get_final_response().usage.video_frames_processed
        except (AttributeError, TypeError):
            pass
    tracks = parse(output, width, height)
    indices = sorted(tracks)
    # Validate provider numbering instead of silently shifting tracks.
    base = 0 if indices and min(indices) == 0 else 1 if indices and min(indices) == 1 else None
    if base is not None and max(indices)-base >= job["n_frames"]:
        base = None
    observations = []
    for index, boxes in sorted(tracks.items()):
        observations.append({"provider_frame": index,
                             "source_frame": job["start_frame"]+index-base if base is not None else None,
                             "boxes": boxes})
    return {**job, "model": "sam-3.1", "width": width, "height": height,
            "billed_frames": billed, "provider_frame_base": base, "observations": observations,
            "note": "Segmentation observations only; contact and stroke label still require video review"}


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("session", type=Path)
    p.add_argument("--output", type=Path, required=True)
    p.add_argument("--max-frames", type=int, default=15000, help="Total reserved across this output, including failed calls")
    p.add_argument("--max-clips", type=int, default=31)
    p.add_argument("--workers", type=int, default=2)
    args = p.parse_args()
    if args.max_frames < 50 or args.max_clips < 1 or not 1 <= args.workers <= 4:
        p.error("Invalid frame, clip or worker limit")
    key = api_key()
    if not key:
        p.exit(1, "No Meta API credential found in the existing environment/configuration\n")
    source = args.session/"video.mov"
    times = np.fromfile(args.session/"video_frames.bin", dtype="<u8").astype(float)/1e9
    z = np.load(args.session/"imu_aligned.npz", allow_pickle=False)
    t = z["t_phone_s"]
    hg = np.linalg.norm(z["high_g"], axis=1)
    peaks = []
    for i in np.flatnonzero(hg > 4):
        if peaks and t[i]-t[peaks[-1]] < .6:
            if hg[i] > hg[peaks[-1]]:
                peaks[-1] = i
        else:
            peaks.append(i)
    args.output.mkdir(parents=True, exist_ok=True)
    ledger_path = args.output/"ledger.json"
    config = {"source": str(source.resolve()), "source_bytes": source.stat().st_size,
              "capture_timestamps_sha256": hashlib.sha256((args.session/"video_frames.bin").read_bytes()).hexdigest()}
    ledger = json.loads(ledger_path.read_text()) if ledger_path.exists() else {"configuration": config, "reserved_frames": 0, "requests": []}
    if ledger["configuration"] != config:
        p.error("Output cache belongs to a different recording")
    jobs = []
    # Include synchronization/handling candidates too, so review can expose false
    # positives. First 31 candidates includes the final real swing in this session.
    for index, peak in enumerate(peaks[:args.max_clips]):
        start = max(0, int(np.searchsorted(times, t[peak]-.85)))
        end = min(len(times), int(np.searchsorted(times, t[peak]+.20)))
        n = end-start
        for prompt in ("tennis racket", "tennis ball"):
            job_id = f"candidate-{index+1:02d}-{'racket' if prompt == 'tennis racket' else 'ball'}"
            target = args.output/f"{job_id}.json"
            if target.exists():
                continue
            # A failed/uncertain call needs an explicit new run/cache, not an
            # automatic second charge hidden behind retries.
            if any(r["id"] == job_id for r in ledger["requests"]):
                continue
            reserved = max(50, n)
            if ledger["reserved_frames"]+reserved > args.max_frames:
                break
            job = {"id": job_id, "candidate": index+1, "prompt": prompt, "start_frame": start,
                   "n_frames": n, "start_phone_s": float(times[start]), "candidate_phone_s": float(t[peak])}
            ledger["requests"].append({"id": job_id, "reserved_frames": reserved, "status": "reserved"})
            ledger["reserved_frames"] += reserved
            jobs.append((job, target))
    atomic_json(ledger_path, ledger)
    print(f"SAM 3.1: {len(jobs)} bounded clip requests, total reserved frames {ledger['reserved_frames']}", flush=True)
    with ThreadPoolExecutor(max_workers=args.workers) as pool:
        futures = {pool.submit(request, key, source, job): (job, target) for job, target in jobs}
        for future in as_completed(futures):
            job, target = futures[future]
            record = next(r for r in ledger["requests"] if r["id"] == job["id"])
            try:
                result = future.result()
                atomic_json(target, result)
                record["status"] = "completed"
                record["billed_frames"] = result["billed_frames"]
                found = sum(bool(r["boxes"]) for r in result["observations"])
                print(f"{job['id']}: {found} frames with observations / {job['n_frames']}", flush=True)
            except Exception as error:
                # Do not print request objects, headers, credentials or encoded media.
                record["status"] = "failed"
                record["error_type"] = type(error).__name__
                print(f"{job['id']}: failed ({type(error).__name__})", flush=True)
            atomic_json(ledger_path, ledger)


if __name__ == "__main__":
    main()
