#!/usr/bin/env python3
"""Write copies of IMU recordings with the gyro scaled by 0.5.

The racket ran firmware 1.5 on 2026-10-29: it flagged the gyro as +-4000 dps while the sensor was still at
+-2000, so the app decoded every rate 2.0x too high (measured 1.99-2.05x against the robot's own poses).
Originals are left untouched; outputs get a gyrofix suffix or go to a new directory.

    python3 robot/fix_gyro_scale.py data/room-2026-10-29/runs data/room-2026-10-29/runs_gyrofix
    python3 robot/fix_gyro_scale.py data/room-2026-10-29/robot-session-2026-10-29T205312.tbrec
"""
import argparse
import shutil
from pathlib import Path

import numpy as np

SCALE = 0.5
REC = np.dtype([("t", "<f8"), ("v", "<f4", 9)])


def fix_csv_dir(src: Path, dest: Path) -> int:
    dest.mkdir(parents=True, exist_ok=True)
    n = 0
    for f in sorted(src.glob("run*_IMU.csv")):
        a = np.genfromtxt(f, delimiter=",", skip_header=1)
        a[:, 4:7] *= SCALE
        with open(dest / f.name, "w") as out:
            out.write(f.read_text().splitlines()[0] + "\n")
            np.savetxt(out, a, delimiter=",", fmt=["%.4f"] + ["%.4f"] * 6 + ["%.3f"] * 3)
        n += 1
    for name in ("manifest.json", "manifest.csv", "alignment.csv"):
        if (src / name).exists():
            shutil.copy2(src / name, dest / name)
    (dest / "README.txt").write_text(
        "Gyro columns (gx,gy,gz) multiplied by 0.5: racket firmware 1.5 over-read the gyro 2x on 2026-10-29.\n"
        "Accel and high-g are unchanged. Originals are in the parent runs/ directory.\n")
    return n


def fix_tbrec(src: Path) -> Path:
    d = np.fromfile(src, dtype=REC)
    d["v"][:, 3:6] *= SCALE
    out = src.with_name(src.stem + "-gyrofix.tbrec")
    d.tofile(out)
    return out


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("src", type=Path)
    ap.add_argument("dest", type=Path, nargs="?")
    args = ap.parse_args()
    if args.src.is_dir():
        print(f"{fix_csv_dir(args.src, args.dest or args.src.with_name(args.src.name + '_gyrofix'))} CSVs written")
    else:
        print(fix_tbrec(args.src))


if __name__ == "__main__":
    main()
