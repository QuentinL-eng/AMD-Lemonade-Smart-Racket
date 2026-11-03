#!/usr/bin/env python3
"""Gross alignment check: do each session's hit times line up with the audible hits in its source video?

The audio of the YouTube video is an independent clock. For every hit (`shots[].video_t`, seconds in the source video)
this finds the strongest click within +-0.5 s and reports how tightly those clicks cluster around one offset, against a
null (the same windows moved 3.7 s off the hits). A tight cluster above chance means the hit times and the video agree
to well under a second.

Read the offset with care: in the measured matches the sound arrives 0.1-0.28 s AFTER the data's hit, by a different
amount per broadcast. That is broadcast audio delay and mic distance, not a data error, because the data's hit times
come from the PICTURE (human labels or a model watching frames). Use tools/f3tennis_model/swing_alignment.py (racket
speed peak vs hit frame) for sub-0.2 s alignment, and do not apply an audio offset as a correction unless that agrees.

    python3 tools/f3tennis_model/align_check.py AUDIO_DIR website/emulator_sessions.json
    python3 tools/f3tennis_model/align_check.py AUDIO_DIR website/emulator_sessions.json --apply   # writes session.video_bias

Audio files are named `<slug>__t0_<seconds>.<ext>`, where t0 is where the file starts in the source video
(0 for a whole video) and slug is the first 24 characters of the match name, lowercased, non-alphanumerics -> "_".
"""
import argparse
import glob
import json
import os
import re
import sys

import numpy as np

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
import sam_clip_hits as sc  # noqa: E402

TOL = 0.6          # a hit sound within this many seconds of a data hit counts as its match
TIGHT = 0.12       # "lined up" = within this many seconds (3 frames at 25 fps)


def slug_of(name):
    return re.sub(r"[^a-z0-9]+", "_", name.lower()).strip("_")[:24]


def load_audio(files):
    """[(t0, samples, sr)] for every audio file of one match."""
    out = []
    for f in files:
        t0 = float(re.search(r"__t0_([\d.]+)\.", os.path.basename(f)).group(1))
        y, sr = sc.read_mono_wav(f)
        out.append((t0, y, sr))
    return out


def click_envelope(y, sr):
    """Sharpness of broadband clicks: smoothed |second difference| (voice and crowd are low-frequency, hits are not)."""
    d = np.abs(np.diff(y, 2, prepend=[y[0]] * 2))
    w = max(1, int(0.004 * sr))
    return np.convolve(d, np.ones(w) / w, mode="same")


def local_offsets(audio, hits, shift=0.0, half=0.5, min_prom=6.0):
    """For each data hit, the time of the strongest click within +-half s of (hit + shift), minus the hit time.

    shift=0 measures alignment; a non-zero shift gives the NULL (windows moved off the hits), i.e. how tightly clicks
    would cluster by chance. Only windows whose peak stands out (peak / median >= min_prom) count.
    """
    out = []
    for h in hits:
        for t0, y, sr in audio:
            c = h + shift - t0
            if c - half < 0 or (c + half) * sr >= len(y):
                continue
            env = click_envelope(y[int((c - half) * sr):int((c + half) * sr)], sr)
            k = int(np.argmax(env))
            if env[k] / (np.median(env) + 1e-12) >= min_prom:
                out.append((k / sr - half) - shift)
            break
    return np.array(out)


def cluster(d, width=0.08):
    """(median, share of offsets within +-width of the median)."""
    if len(d) == 0:
        return 0.0, 0.0
    m = float(np.median(d))
    return m, float(np.mean(np.abs(d - m) <= width))


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("audio_dir")
    ap.add_argument("sessions")
    ap.add_argument("--apply", action="store_true", help="write the measured median offset as session.video_bias")
    a = ap.parse_args(argv)
    with open(a.sessions) as fh:
        doc = json.load(fh)
    for p in doc["players"]:
        files = sorted(glob.glob(os.path.join(a.audio_dir, slug_of(p["name"]) + "__t0_*")))
        if not files:
            print(f"{p['name'][:38]:38s} no audio")
            continue
        hits = sorted(s["video_t"] for s in p["session"]["shots"])
        audio = load_audio(files)
        d = local_offsets(audio, hits)
        null = np.concatenate([local_offsets(audio, hits, shift=sh) for sh in (3.7, -3.7)])
        if len(d) < 15:
            print(f"{p['name'][:38]:38s} only {len(d)} usable hit sounds: cannot judge")
            continue
        med, share = cluster(d)
        _, null_share = cluster(null, 0.08)
        # null share is measured around ITS OWN median, so it is the best chance would do
        trusted = share >= max(0.45, 2 * null_share)
        print(f"{p['name'][:38]:38s} {len(d):4d}/{len(hits):4d} hit sounds | median {med:+.3f}s | within 0.08s of median: "
              f"{100 * share:.0f}% (chance {100 * null_share:.0f}%) -> {'ALIGNED' if trusted else 'inconclusive'}")
        if not trusted:
            continue
        if a.apply:
            p["session"]["video_bias"] = round(med, 2)
    if a.apply:
        with open(a.sessions, "w") as fh:
            json.dump(doc, fh, separators=(",", ":"))
        print("video_bias written")


if __name__ == "__main__":
    sys.exit(main())
