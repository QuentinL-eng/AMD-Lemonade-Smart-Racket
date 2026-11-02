"""Evaluate the frozen production rules on reviewed real-racket video contacts.

Video labels do not enter model training or decision thresholds. Timing-only
matching corrects the documented legacy clock offset without overwriting source
files. Conditional classification and raw-stream detection are reported apart.
"""
import argparse
import csv
import hashlib
import json
from pathlib import Path

import numpy as np
from scipy.optimize import linear_sum_assignment

from .dataset import STROKES
from .rules import classify_at, raw_app_contacts
from .train import wilson

ROOT = Path(__file__).resolve().parents[2]


def verify_review_sources(metadata):
    data = json.loads(metadata.read_text())
    for relative, expected in data["source_files_sha256"].items():
        h = hashlib.sha256()
        with (ROOT/relative).open("rb") as f:
            while chunk := f.read(4*1024*1024):
                h.update(chunk)
        if h.hexdigest() != expected:
            raise ValueError(f"Reviewed source changed: {relative}")


def match_sensor_contacts(times, high_g, video_contacts, offset=.350, radius=.120):
    """Class-independent nearest-time matching to locally complete high-g jumps."""
    jump = np.linalg.norm(high_g[3:]-high_g[:-3], axis=1)
    # A three-sample difference across a long BLE gap is not a 3ms jolt.
    complete = times[3:]-times[:-3] <= .0061
    result = []
    for contact in video_contacts:
        eligible = np.flatnonzero(complete & (abs(times[3:]-(contact+offset)) <= radius))
        if not len(eligible):
            result.append(None)
            continue
        k = eligible[np.argmax(jump[eligible])]
        result.append(int(k+1) if jump[k] >= 3 else None)  # (k+3)-2: first sample of jump
    if len([i for i in result if i is not None]) != len(set(i for i in result if i is not None)):
        raise ValueError("Sensor contact reused by multiple reviewed events")
    return result


def pair_detections(detection_times, contact_times, tolerance=.100):
    if not len(detection_times) or not len(contact_times):
        return []
    distance = abs(np.asarray(detection_times)[:, None]-np.asarray(contact_times)[None, :])
    distance = np.nan_to_num(distance, nan=1e9, posinf=1e9, neginf=1e9)
    # Large finite cost penalizes nonmatches while maximizing valid pairing count.
    cost = np.where(distance <= tolerance, distance, 1000+distance)
    a, b = linear_sum_assignment(cost)
    return [(int(i), int(j)) for i, j in zip(a, b) if distance[i, j] <= tolerance]


def run(args):
    if not np.isfinite(args.gyro_scale) or not 0 < args.gyro_scale <= 2:
        raise ValueError("Explicit gyro scale must be finite, positive and at most 2")
    if getattr(args, "review_metadata", None):
        verify_review_sources(args.review_metadata)
    with args.events.open(newline="") as f:
        events = list(csv.DictReader(f))
    if not events or any(e["shot_type"] not in STROKES or not e.get("reviewer") for e in events):
        raise ValueError("Need reviewed stroke labels with named reviewer")
    frames = [int(e["frame"]) for e in events]
    if frames != sorted(set(frames)):
        raise ValueError("Reviewed frames must be distinct and ordered")
    video = np.fromfile(args.session/"video_frames.bin", dtype="<u8").astype(float)/1e9
    if frames[0] < 0 or frames[-1] >= len(video):
        raise ValueError("Reviewed frame outside source recording")
    z = np.load(args.session/"imu_aligned.npz", allow_pickle=False)
    t, acc, gyro, hg = z["t_phone_s"], z["accel_g"], z["gyro_rad_s"]*args.gyro_scale, z["high_g"]
    contacts = video[frames]
    indices = match_sensor_contacts(t, hg, contacts, args.legacy_offset)
    good = [i for i in indices if i is not None]
    scores = {}
    for sign in [1., 0.]:
        typed = iter(classify_at(t, acc, gyro, hg, good, sign))
        rows = []
        for event, frame, index in zip(events, frames, indices):
            result = next(typed) if index is not None else {"predicted": "unknown"}
            row = {**event, **result, "frame": frame, "video_contact_s": float(video[frame])}
            if index is not None:
                lo, hi = np.searchsorted(t, [t[index]-.350, t[index]+.060])
                row["largest_imu_gap_ms"] = float(np.diff(t[max(0,lo-1):min(len(t),hi+1)]).max()*1000)
                row["legacy_clock_difference_ms"] = float((t[index]-video[frame])*1000)
            rows.append(row)
        right = sum(r["predicted"] == r["shot_type"] for r in rows)
        per_class = {c: {"n": sum(r["shot_type"] == c for r in rows),
                         "correct": sum(r["shot_type"] == c and r["predicted"] == c for r in rows)} for c in STROKES}
        scores["taught_sign_from_room" if sign else "learn_sign_during_session"] = {
            "correct": right, "n": len(rows), "accuracy": right/len(rows), "wilson95": wilson(right,len(rows)),
            "per_class": per_class, "events": rows,
            "scope": "Classification given video-matched contact; video timing helps find the contact, so this is not sensor-only end-to-end accuracy"}
    raw_indices = raw_app_contacts(t, gyro, hg)
    raw = classify_at(t, acc, gyro, hg, raw_indices, 1.)
    matched_contact_times = np.array([t[i] if i is not None else np.nan for i in indices])
    pairs = pair_detections([r["contact_phone_s"] for r in raw], matched_contact_times)
    correct = sum(raw[i]["predicted"] == events[j]["shot_type"] for i, j in pairs)
    paired = {i for i, _ in pairs}
    result = {"source_session": str(args.session.resolve()), "gyro_scale": args.gyro_scale,
              "reviewed_labels_sha256": hashlib.sha256(args.events.read_bytes()).hexdigest(),
              "production_source_sha256": {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest()
                                            for p in [ROOT/"apple/RacketKit/Sources/RacketKit/ShotAnalyzer.swift", ROOT/"firmware/src/shot.cpp"]},
              "legacy_clock_matching": {"seed_offset_s": args.legacy_offset, "search_radius_s": .120,
                                         "method": "Largest locally complete three-sample high-g jump near each video contact; no stroke labels used",
                                         "matched_contacts": len(good)},
              "conditional_classification": scores,
              "raw_stream_replay": {"detections": len(raw), "matched_verified_strokes": len(pairs),
                                    "correctly_typed_verified_strokes": correct,
                                    "verified_stroke_detection_recall": len(pairs)/len(events),
                                    "correctly_typed_fraction_of_verified_strokes": correct/len(events),
                                    "unmatched_detections": [r for i, r in enumerate(raw) if i not in paired],
                                    "note": "Replay on received raw BLE samples, motion path only; cannot measure missing embedded samples or microphone-assisted live detections"},
              "acceptance": {"own_racket_all_strokes_95_percent_demonstrated": False,
                             "reasons": ["This independent video contains confirmed forehands only",
                                         "No held-out backhand, serve or volley recall is available",
                                         "Small single-session sample; no ball-speed reference"]}}
    if args.output.exists():
        raise ValueError("Choose a new output file; preserve the prior evaluation")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2, allow_nan=False)+"\n")
    for name, score in scores.items():
        print(f"{name}: {score['correct']}/{score['n']} = {score['accuracy']:.2%} conditional classification")
    print(f"Raw-stream replay: {len(pairs)}/{len(events)} detected, {correct}/{len(events)} correctly typed")
    return result


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("session", type=Path)
    p.add_argument("events", type=Path)
    p.add_argument("--gyro-scale", type=float, required=True)
    p.add_argument("--review-metadata", type=Path, help="Verify SHA-256 of the reviewed source video, timestamps and IMU")
    p.add_argument("--legacy-offset", type=float, default=.350, help="Legacy aligned IMU is this much later than video")
    p.add_argument("--output", type=Path, required=True)
    args = p.parse_args()
    try:
        run(args)
    except (OSError, ValueError) as e:
        p.exit(1, f"Error: {e}\n")


if __name__ == "__main__":
    main()
