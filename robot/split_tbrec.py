#!/usr/bin/env python3
"""Split a raw .tbrec stream recorded during a tb_full run into one CSV per path repetition.

Each RC+ run does home, 1 s still, a +4/-4 degree racket sync twitch, 1 s still, the path, a pause and home.
The twitch shows up in the gyro as a short negative then positive spike, so run starts are found from that
and labelled in order from the tb_full sequence in Main.prg. The result is a manifest to check by eye, not
ground truth, and the order labels drift if a run was interrupted or restarted: use the robot PC's tb_events.csv when you have it.

    python3 robot/split_tbrec.py data/room-2026-10-29/robot-session-*.tbrec --out data/room-2026-10-29/runs
"""
import argparse
import csv
import json
import re
from pathlib import Path

import numpy as np
from scipy.signal import find_peaks

REC = np.dtype([("t", "<f8"), ("v", "<f4", 9)])
HEADER = "time_s,ax_g,ay_g,az_g,gx_rads,gy_rads,gz_rads,hx_g,hy_g,hz_g"
MAIN_PRG = Path(__file__).parent.parent / "TennisRobot" / "TennisBuddyDayOne_20261029" / "Main.prg"


def tb_full_sequence(prg: Path) -> list[tuple[str, int]]:
    src = prg.read_text(errors="ignore")
    start = src.index("Function tb_full")
    body = src[start:src.index("Fend", start)]
    return [(name, int(n)) for n, name in re.findall(r"For g_rep = 1 To (\d+)\s+(\w+)", body)]


def main_segment(rec: np.ndarray) -> np.ndarray:
    """The long continuous stretch: the device clock resets on every reconnect, leaving short stubs."""
    dt = np.diff(rec["t"])
    cuts = np.r_[0, np.where((dt < 0) | (dt > 1))[0] + 1, len(rec)]
    a, b = max(zip(cuts, cuts[1:]), key=lambda s: s[1] - s[0])
    return rec[a:b]


def find_twitches(t: np.ndarray, g: np.ndarray, quiet_s: float = 0.8) -> list[tuple[float, float]]:
    """(start, end) of each negative-then-positive gyro-y spike pair with a still stretch before it."""
    n = len(t) // 10 * 10
    T = t[:n].reshape(-1, 10).mean(1)
    gy = g[:n, 1].reshape(-1, 10).mean(1)
    pos, _ = find_peaks(gy, height=0.3, distance=30)
    neg, _ = find_peaks(-gy, height=0.3, distance=30)
    out = []
    for a in neg:
        later = pos[(pos > a) & (pos < a + 150)]
        if not len(later):
            continue
        b = later[0]
        if np.any(neg[(neg > a) & (neg < b)]):
            continue
        before = gy[max(0, a - 40 - int(quiet_s * 100)):max(0, a - 40)]
        if len(before) and np.abs(before).max() > 0.25:
            continue
        out.append((T[a], T[b]))
    return out


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("tbrec", type=Path)
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--racket", default="E35E")
    ap.add_argument("--prg", type=Path, default=MAIN_PRG)
    ap.add_argument("--events", type=Path, help="tb_events.csv from the run that produced the later part of the stream")
    ap.add_argument("--restart-after", type=int, default=0,
                    help="twitches 0..N-1 belong to an earlier aborted attempt; tb_events.csv is the restart's")
    args = ap.parse_args()

    rec = main_segment(np.fromfile(args.tbrec, dtype=REC))
    t = rec["t"] - rec["t"][0]
    g = rec["v"][:, 3:6]
    twitches = find_twitches(t, g)
    seq = [(name, rep) for name, n in tb_full_sequence(args.prg) for rep in range(1, n + 1)]
    path_end = {}
    if args.events:
        seen = []
        for row in csv.DictReader(open(args.events)):
            key = (row["path_id"], int(row["rep"]))
            if not seen or seen[-1] != key:
                seen.append(key)
            if row["event"] == "path_end":
                path_end[key] = float(row["time_s"])
        # The restart's own order replaces the plan for the runs it covers.
        seq = seq[:args.restart_after] + seen
    print(f"{len(rec)} samples, {t[-1] / 60:.1f} min; {len(twitches)} twitches for {len(seq)} expected runs")

    args.out.mkdir(parents=True, exist_ok=True)
    manifest = []
    for i, (name_rep, (t0, _)) in enumerate(zip(seq, twitches)):
        end = twitches[i + 1][0] - 1.5 if i + 1 < len(twitches) else t0 + 25
        # RC+ homes and holds 1 s before the twitch, so back up to catch the start of the run.
        a, b = np.searchsorted(t, t0 - 1.5), np.searchsorted(t, end)
        name, rep = name_rep
        fn = f"run{i + 1:03d}_{args.racket}_IMU.csv"
        s = rec[a:b]
        with open(args.out / fn, "w") as f:
            f.write(HEADER + "\n")
            np.savetxt(f, np.c_[s["t"] - rec["t"][0], s["v"]], delimiter=",",
                       fmt=["%.4f"] + ["%.4f"] * 6 + ["%.3f"] * 3)
        gap = end + 1.5 - t0
        ok = bool(path_end and name_rep in path_end and 1.5 < gap - path_end[name_rep] < 12)
        manifest.append({"attempt": 1 if i < args.restart_after else 2, "spacing_matches_events": ok, "file": fn, "tentative_path_id": name, "tentative_rep": rep, "twitch_s": round(float(t0), 2),
                         "start_s": round(float(t[a]), 2), "end_s": round(float(t[b - 1]), 2),
                         "peak_gyro_rads": round(float(np.linalg.norm(g[a:b], axis=1).max()), 3)})
    (args.out / "manifest.json").write_text(json.dumps(manifest, indent=1))
    with open(args.out / "manifest.csv", "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=manifest[0].keys())
        w.writeheader()
        w.writerows(manifest)
    print(f"wrote {len(manifest)} runs to {args.out}")


if __name__ == "__main__":
    main()
