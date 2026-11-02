"""Import user-labeled full impact windows without inventing missing pose state.

An app raw CSV retains sensor samples but omits each TBWindowChunk's starting
quaternion. Separate impact windows must never be integrated as a continuous
orientation recording across their inter-hit gaps.
"""
import argparse
import csv
import hashlib
import json
from pathlib import Path
import shutil

import numpy as np

from .dataset import HEADER, STROKES
from .features import VERSION, extract, validate_window
from .rules import angle_before


def split_windows(data):
    data = np.asarray(data, dtype=float)
    if data.ndim != 2 or data.shape[1] != 10 or not len(data) or not np.isfinite(data).all():
        raise ValueError("Expected finite ten-column sensor data")
    if np.any(np.diff(data[:, 0]) <= 0):
        raise ValueError("Timestamps must strictly increase")
    boundaries = np.r_[0, np.flatnonzero(np.diff(data[:, 0]) > .020)+1, len(data)]
    windows = [data[a:b] for a, b in zip(boundaries[:-1], boundaries[1:])]
    if any(len(w) != 448 for w in windows):
        raise ValueError("Expected separate 448-sample impact windows; cannot infer window metadata safely")
    return windows


def inspect_window(window, hit, scale):
    t, gyro, high_g = window[:, 0], window[:, 4:7]*scale, window[:, 7:10]
    # Capture format is 384 samples before the firmware's impact and 64 after.
    # Use that original anchor for features, keeping the full configured post span.
    contact = 384
    validate_window(t-t[contact], window[:, 1:4], gyro)
    features = extract(t-t[contact], window[:, 1:4], gyro)
    # Mirror RacketEngine.shot's local contact refinement for diagnostic features.
    best = max(range(380, 393), key=lambda k: np.linalg.norm(high_g[k]-high_g[k-3]))
    refined = best-2
    pre = gyro[refined-10:refined-2].mean(0)
    row = {"hit": hit, "samples": len(t), "window_start_sensor_s": float(t[0]),
           "window_end_sensor_s": float(t[-1]), "capture_contact_sensor_s": float(t[contact]),
           "refined_contact_sensor_s": float(t[refined]), "refined_local_index": refined,
           "largest_internal_gap_ms": float(np.diff(t).max()*1000),
           "high_g_peak_g": float(np.linalg.norm(high_g, axis=1).max()),
           "gyro_axis_peak_rad_s": np.max(abs(gyro), axis=0).tolist(),
           "swing_deg": angle_before(t, gyro, refined),
           "pre_contact_gyro_sensor_rad_s": pre.tolist(),
           "pre_contact_gyro_racket_y_rad_s": float(-pre[0]),
           "forehand_face_sign_under_default_mount": 1 if -pre[0] > 0 else -1 if -pre[0] < 0 else 0,
           "starting_orientation_available": False}
    return row, features


def face_sign_diagnostic(events):
    """Upper bound, not a full prediction: the current nonzero-sign branch.

    With swing >=45 degrees, a sign mismatch can only reach backhand or the
    earlier serve branch, neither of which is forehand, regardless of pose.
    """
    eligible = [e for e in events if e["swing_deg"] >= 45]
    counts = {str(sign): sum(e["pre_contact_gyro_racket_y_rad_s"]*sign > 0 for e in eligible)
              for sign in (-1, 1)}
    return {"scope": "Default mounting, existing rules with a nonzero taught sign; not automatic sign=0 mode",
            "long_swing_events": len(eligible), "forehand_candidates_by_taught_sign": counts,
            "best_possible_forehands_with_any_single_taught_sign": max(counts.values(), default=0),
            "note": "Pose-dependent branches can reduce this upper bound; this is not an observed app accuracy score"}


def run(args):
    if args.output.exists():
        raise ValueError("Choose a new output directory to preserve prior evidence")
    if not np.isfinite(args.gyro_scale) or not 0 < args.gyro_scale <= 2:
        raise ValueError("Gyro scale must be finite, positive and at most 2")
    with args.recording.open() as f:
        if f.readline().strip().split(",") != HEADER:
            raise ValueError("Unexpected app CSV header")
    data = np.loadtxt(args.recording, delimiter=",", skiprows=1, ndmin=2)
    windows = split_windows(data)
    if len(windows) != args.expected_hits:
        raise ValueError(f"Found {len(windows)} windows, but {args.expected_hits} labeled shots were expected")
    events, features = [], []
    for i, window in enumerate(windows, 1):
        row, x = inspect_window(window, i, args.gyro_scale)
        events.append({**row, "shot_type": args.label, "label_source": "User statement in chat"})
        features.append(x)
    report = {"source_file": str(args.recording.resolve()),
              "source_sha256": hashlib.sha256(args.recording.read_bytes()).hexdigest(),
              "source_format": "App raw sensor CSV, inferred 448-sample impact windows",
              "provenance": "real_racket", "firmware_reported_by_user": args.firmware,
              "gyro_scale": args.gyro_scale, "sample_count": len(data), "labeled_hits": len(events),
              "shot_type": args.label, "pace": args.pace, "setting": "indoors",
              "dataset_role": "Separate validation session; not used to fit classification thresholds or model weights",
              "feature_version": VERSION, "feature_shape": [len(features), len(features[0])],
              "quality": {"complete_windows": len(windows), "passes_12ms_gap_policy": len(windows),
                          "inter_window_gaps": "Intentional unrecorded time between impact windows, not missing samples inside hits",
                          "starting_orientation_exported": False,
                          "firmware_version_exported": False,
                          "maximum_absolute_gyro_axis_rad_s": float(np.max(abs(data[:, 4:7]*args.gyro_scale))),
                          "scale_note": "Scale follows user-reported firmware. Link metadata is needed to confirm device version/range; no scale was chosen by classification score."},
              "events": events, "fixed_face_sign_diagnostic": face_sign_diagnostic(events),
              "classification_accuracy": None,
              "accuracy_limit": "Exact live shot typing needs each starting quaternion or the live .shots.jsonl summaries. Dynamic window starts are not valid stationary tilt measurements.",
              "companion_files": [args.recording.stem+".shots.jsonl", args.recording.stem+".link.json"],
              "acceptance": {"all_four_types_95_percent_demonstrated": False,
                             "ball_speed_validated": False}}
    args.output.mkdir(parents=True)
    shutil.copy2(args.recording, args.output/args.recording.name)
    with (args.output/"labels.csv").open("w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=["hit", "shot_type", "capture_contact_sensor_s", "label_source"])
        writer.writeheader()
        writer.writerows({k: row[k] for k in writer.fieldnames} for row in events)
    np.savez_compressed(args.output/"windows-and-features.npz", samples=np.stack(windows),
                        features=np.stack(features), labels=np.array([args.label]*len(windows)),
                        contact_indices=np.full(len(windows), 384), gyro_scale=np.array(args.gyro_scale),
                        columns=np.array(HEADER))
    (args.output/"report.json").write_text(json.dumps(report, indent=2)+"\n")
    print(f"Imported {len(events)} complete windows, feature shape {report['feature_shape']}")
    print(f"Fixed face-sign diagnostic: {report['fixed_face_sign_diagnostic']}")
    print("Live classification accuracy: unavailable without companion pose/shot metadata")
    return report


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("recording", type=Path)
    p.add_argument("--output", type=Path, required=True)
    p.add_argument("--label", choices=STROKES, required=True)
    p.add_argument("--expected-hits", type=int, required=True)
    p.add_argument("--firmware", required=True)
    p.add_argument("--gyro-scale", type=float, required=True)
    p.add_argument("--pace", default="medium to low, user reported")
    try:
        run(p.parse_args())
    except (OSError, ValueError) as e:
        p.exit(1, f"Error: {e}\n")


if __name__ == "__main__":
    main()
