#!/usr/bin/env python3
"""Assemble per-player SAM track caches into one emulator_sessions.json.

Each player dir holds sam_video/*.json (tools/sam_clip_hits.py) plus source.json
(player, url, title, uploader). Windows are concatenated with 3 s gaps --
within-window timing is true, between-window dead air is compressed, and the
provenance says so. Intensity is renormalized across each player's session.

    python3 tools/sam_players_to_emulator.py work/alcaraz work/sinner -o website/emulator_sessions.json
"""
import argparse
import glob
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sam_track_to_session as st  # noqa: E402

GAP_S = 3.0


def assemble(player_dir, fps=30.0):
    src = json.load(open(os.path.join(player_dir, "source.json")))
    sess = {
        "provenance": {
            "player": src["player"],
            "source": f"{src['title']} ({src['uploader']})",
            "video_url": src["url"],
            "tracker": "SAM 3.1 video API (cached tracks, no live calls)",
            "fps_assumed": fps,
        },
        "units_note": ("intensity is unitless 0-1 from racket pixel velocity, "
                       "normalized within this player's session. It is NOT a speed in km/h."),
        "time_note": ("contact windows concatenated with 3 s gaps; "
                      "within-window timing is true."),
        "omitted": ["ball_speed", "spin", "face_angle", "contact_point"],
        "skipped_events": 0,
        "shots": [],
    }
    clips = sorted(glob.glob(os.path.join(player_dir, "sam_video", "*.json")))
    offset = 0.0
    for p in clips:
        s = st.convert(p, fps=fps, source=src["title"])
        if s["shots"]:
            first = min(sh["t_s"] for sh in s["shots"])
            for sh in s["shots"]:
                sh["t_s"] = round(sh["t_s"] - first + offset, 3)
            offset = max(sh["t_s"] for sh in s["shots"]) + GAP_S
        sess["skipped_events"] += s["skipped_events"]
        sess["shots"].extend(s["shots"])
    sess["shots"].sort(key=lambda sh: sh["t_s"])
    peaks = [sh["peak_px_s"] for sh in sess["shots"]]
    if peaks:
        lo, hi = min(peaks), max(peaks)
        span = hi - lo
        for sh in sess["shots"]:
            sh["intensity"] = round((sh["peak_px_s"] - lo) / span, 3) if span > 0 else 0.0
    for i, sh in enumerate(sess["shots"]):
        sh["index"] = i
    return {"name": src["player"], "video_url": src["url"], "session": sess}


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("players", nargs="+", help="player work dirs")
    ap.add_argument("--fps", type=float, default=30.0)
    ap.add_argument("-o", "--output", required=True)
    a = ap.parse_args(argv)
    out = {"players": [assemble(p, fps=a.fps) for p in a.players]}
    json.dump(out, open(a.output, "w"), indent=1)
    for p in out["players"]:
        print(f"{p['name']}: {len(p['session']['shots'])} shots")


if __name__ == "__main__":
    main()
