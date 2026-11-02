"""Make SAM-assisted contact proposals and review sheets, without assigning truth."""
import argparse
import json
from pathlib import Path

import cv2
import numpy as np


def propose(folder, times):
    proposals = []
    for racket_file in sorted(folder.glob("candidate-*-racket.json")):
        ball_file = racket_file.with_name(racket_file.name.replace("-racket", "-ball"))
        if not ball_file.exists():
            continue
        r = json.loads(racket_file.read_text())
        b = json.loads(ball_file.read_text())
        if r["provider_frame_base"] is None or b["provider_frame_base"] is None:
            continue
        rackets = {o["source_frame"]: o["boxes"] for o in r["observations"]}
        distances = []
        for obs in b["observations"]:
            f = obs["source_frame"]
            for ball in obs["boxes"]:
                for racket in rackets.get(f, []):
                    if min(ball[5], racket[5]) < .3:
                        continue
                    bc = np.array([(ball[1]+ball[3])/2, (ball[2]+ball[4])/2])
                    rc = np.array([(racket[1]+racket[3])/2, (racket[2]+racket[4])/2])
                    distances.append((float(np.linalg.norm(bc-rc)), f))
        if not distances:
            continue
        distance, f = min(distances)
        proposals.append({"candidate": r["candidate"], "proposed_frame": f,
                          "proposed_phone_s": float(times[f]), "minimum_box_center_distance_px": distance,
                          "original_imu_candidate_phone_s": r["candidate_phone_s"],
                          "original_alignment_difference_ms": float((r["candidate_phone_s"]-times[f])*1000),
                          "stroke_label": None, "reviewed": False,
                          "note": "Closest box centers propose a contact; blur and 2-D projection can bias this frame"})
    return proposals


def sheets(session, proposals, output):
    cap = cv2.VideoCapture(str(session/"video.mov"))
    times = np.fromfile(session/"video_frames.bin", dtype="<u8").astype(float)/1e9
    for base in range(0, len(proposals), 5):
        rows = []
        for proposal in proposals[base:base+5]:
            tiles = []
            for delta in [-16, -2, 0, 4]:
                f = proposal["proposed_frame"]+delta
                cap.set(cv2.CAP_PROP_POS_FRAMES, f)
                ok, frame = cap.read()
                if not ok:
                    raise ValueError(f"Cannot read review frame {f}")
                # Same crop for every event; keeps ball, hands and racket visible.
                frame = cv2.resize(frame[180:950, :1550], (465, 231))
                cv2.putText(frame, f"C{proposal['candidate']:02d} f{f} {times[f]-times[0]:.3f}s", (5, 18),
                            cv2.FONT_HERSHEY_SIMPLEX, .5, (0, 255, 255), 1)
                tiles.append(frame)
            rows.append(np.hstack(tiles))
        cv2.imwrite(str(output/f"sam-review-{base//5+1}.jpg"), np.vstack(rows))
    cap.release()


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("session", type=Path)
    p.add_argument("sam_cache", type=Path)
    p.add_argument("--output", type=Path, required=True)
    args = p.parse_args()
    times = np.fromfile(args.session/"video_frames.bin", dtype="<u8").astype(float)/1e9
    proposals = propose(args.sam_cache, times)
    args.output.mkdir(parents=True, exist_ok=True)
    (args.output/"proposals.json").write_text(json.dumps(proposals, indent=2)+"\n")
    sheets(args.session, proposals, args.output)
    print(f"{len(proposals)} unlabeled proposals saved for visual review")


if __name__ == "__main__":
    main()
