"""Audit the actual available labels and timestamp coverage, without rewriting data."""
from collections import Counter
import argparse
import json
from pathlib import Path
import zipfile

import numpy as np

from .features import validate_window

ROOT = Path(__file__).resolve().parents[2]


def room_audit():
    folder = ROOT/"data/room-2026-10-29"
    d = np.loadtxt(next(folder.glob("*racket.csv")), delimiter=",", skiprows=1)
    t, high = d[:, 0], np.linalg.norm(d[:, 7:10], axis=1)
    peaks = []
    for i in np.flatnonzero(high > 4):
        if peaks and t[i]-t[peaks[-1]] < .6:
            if high[i] > high[peaks[-1]]:
                peaks[-1] = i
        else:
            peaks.append(i)
    labels = (folder/"labels.txt").read_text().replace(",", " ").split()
    if len(labels) != len(peaks):
        raise ValueError("Room labels do not match candidate peak count")
    rows = []
    for label, i in zip(labels, peaks):
        lo = max(0, np.searchsorted(t, t[i]-.350)-1)
        hi = min(len(t), np.searchsorted(t, t[i]+.060)+1)
        w = d[lo:hi]
        try:
            validate_window(w[:, 0]-t[i], w[:, 1:4], w[:, 4:7]*.5)
            reason = None
        except ValueError as e:
            reason = str(e)
        dt = np.diff(w[:, 0])
        rows.append({"label": label, "candidate_contact_s": float(t[i]), "relative_s": float(t[i]-t[0]),
                     "samples": len(w), "largest_gap_ms": float(dt.max()*1000),
                     "passes_12ms_gap_policy": reason is None, "reject_reason": reason})
    return {"labeled_hits": len(labels), "class_counts": dict(Counter(labels)), "events": rows,
            "note": "Peak/label ordering comes from the existing checker; contact times are not independently video-reviewed here. The 12ms policy is a conservative research setting, not a proven accuracy boundary.",
            "existing_rule_result": "22/22 on the same session used to tune the rules; not independent validation"}


def camera_audit():
    result = []
    for p in sorted((ROOT/"data").glob("**/imu_aligned.npz")):
        z = np.load(p, allow_pickle=False)
        t = z["t_phone_s"]
        events = []
        for contact in z["impacts_phone_s"]:
            lo = max(0, np.searchsorted(t, contact-.350)-1)
            hi = min(len(t), np.searchsorted(t, contact+.060)+1)
            try:
                validate_window(t[lo:hi]-contact, z["accel_g"][lo:hi], z["gyro_rad_s"][lo:hi])
                reason = None
            except ValueError as e:
                reason = str(e)
            events.append({"contact_phone_s": float(contact), "reject_reason": reason})
        result.append({"session": str(p.parent.relative_to(ROOT)), "candidate_impacts": len(events),
                       "passes_12ms_gap_policy": sum(r["reject_reason"] is None for r in events),
                       "reviewed_stroke_labels_found": (p.parent/"shot-events.json").exists(),
                       "video_present": (p.parent/"video.mov").exists(), "events": events})
    return result


def card_audit(card):
    if not card.exists():
        return {"mounted": False}
    folder = card/"imu/synced/3DTennisDS"
    archives = []
    for p in sorted(folder.glob("*.zip")):
        try:
            with zipfile.ZipFile(p) as z:
                files = [i for i in z.infolist() if not i.is_dir() and not Path(i.filename).name.startswith("._")]
                archives.append({"name": p.name, "files": len(files), "c3d": sum(i.filename.lower().endswith(".c3d") for i in files)})
        except (OSError, zipfile.BadZipFile) as e:
            archives.append({"name": p.name, "files": 0, "c3d": 0, "error": str(e)})
    return {"mounted": True, "root": str(card), "3dtennis_archives": archives,
            "3dtennis_c3d_files": sum(a["c3d"] for a in archives),
            "source_notes": [str(p) for p in (card/"README.md", card/"imu/racket/SOURCES.md", card/"imu/synced/SOURCES.md") if p.exists()],
            "limitations": ["3DTennisDS is motion capture; simulated IMU is not a Tennis Buddee field test",
                             "TTSwing, RacketSports and T3Set use other racket sports/sensor placements",
                             "Match statistics and video without synchronized handle IMU cannot supply paired IMU stroke labels"]}


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--card", type=Path, default=Path("/Volumes/Untitled/TennisData"))
    p.add_argument("--output", type=Path, required=True)
    args = p.parse_args()
    report = {"room": room_audit(), "camera": camera_audit(), "card": card_audit(args.card),
              "acceptance": {"own_racket_95_percent_demonstrated": False,
                             "reason": "No independent reviewed multi-class Tennis Buddee field test found"}}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, indent=2)+"\n")
    print(f"Wrote {args.output}. Room passes quality policy: {sum(r['passes_12ms_gap_policy'] for r in report['room']['events'])}/22")


if __name__ == "__main__":
    main()
