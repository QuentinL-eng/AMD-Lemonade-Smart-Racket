#!/usr/bin/env python3
"""Track rackets in F3Set matches one at a time on a laptop: download, run SAM on a few clips, delete the video.

    python3 tools/f3set_local_run.py data/external/f3set --matches 6

Needs data/external/f3set/repo (labels) and MUSE_API_KEY in the repo-root .env. Each match is a 720p video-only
download of about 0.9 GB that is deleted once its clips are tracked; the SAM results (sam_video/*.json) and the
spend ledger stay. Spend is capped by the ledger via tools/sam_f3set_video.py --budget. This UPLOADS broadcast
footage to Meta.
"""
import argparse
import csv
import os
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("root")
    ap.add_argument("--matches", type=int, default=6)
    ap.add_argument("--clips-per-match", type=int, default=20)
    ap.add_argument("--budget", type=float, default=25.0)
    a = ap.parse_args()

    root = os.path.abspath(a.root)
    vdir = os.path.join(root, "videos")
    os.makedirs(vdir, exist_ok=True)
    rows = list(csv.DictReader(open(os.path.join(root, "repo/data/f3tennis/videos.csv"))))
    done_p = os.path.join(root, "local_done.txt")
    done = set(open(done_p).read().split()) if os.path.exists(done_p) else set()
    todo = [r for r in rows if r["video_name"] not in done][: a.matches]

    for r in todo:
        name = r["video_name"]
        dest = os.path.join(vdir, name + ".mp4")
        print(f"== {name}", flush=True)
        ok = subprocess.run(
            ["yt-dlp", "-f", "bv*[height<=720][vcodec^=avc1]/bv*[height<=720]", "--merge-output-format", "mp4",
             "-o", os.path.join(vdir, name + ".%(ext)s"), "--no-progress", "--retries", "5",
             "https://www.youtube.com/watch?v=" + r["yt_id"]]).returncode == 0 and os.path.exists(dest)
        if ok:
            subprocess.run([sys.executable, "-u", os.path.join(HERE, "sam_f3set_video.py"), root,
                            "--clips", str(a.clips_per_match), "--per-match", str(a.clips_per_match),
                            "--budget", str(a.budget)])
        else:
            print("download failed, skipping", name, flush=True)
        for f in os.listdir(vdir):
            if f.startswith(name):
                os.remove(os.path.join(vdir, f))
        with open(done_p, "a") as f:
            f.write(name + "\n")
        print(subprocess.run([sys.executable, os.path.join(HERE, "eval_sam_f3set.py"), root], capture_output=True, text=True).stdout,
              flush=True)


if __name__ == "__main__":
    main()
