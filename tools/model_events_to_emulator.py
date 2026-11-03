#!/usr/bin/env python3
"""SAM windows around F3Tennis-model hits -> emulator sessions with MODEL-PREDICTED stroke types.

Reads the caches written by tools/sam_model_windows.py (`<dir>/sam_video/*.json`: per-frame racket boxes plus the
model's hit events: type, hitter, confidence) and converts them with the same swing-profile logic as
tools/f3set_to_emulator.py.

What is real, predicted and estimated
- Hit times and which player hit (near/far) and the stroke type are PREDICTIONS of the F3Tennis tsm_e2espot model,
  not labels. It scored 97% on stroke type on 60 held-out hits of the Ostrava final it was tested on; its accuracy on
  these broadcasts was not measured. Every hit carries the model's confidence.
- The swing profile (`prog`) and path angle come from the hitter's SAM racket-box centre, as in f3set_to_emulator.
- Speed is unitless (racket lengths per second, normalised 0-1 per session). Ball speed, spin, face angle and the
  contact point are not observable; the emulator labels them estimates.

    python3 tools/model_events_to_emulator.py D:/.../sam --merge website/emulator_sessions.json
"""
import argparse
import glob
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import f3set_to_emulator as fe  # noqa: E402

GAP_S = 3.0
TYPES = ("serve", "forehand", "backhand", "volley")

# slug -> (display name, source title, uploader, url)
MATCHES = {
    "carlos_alcaraz": ("Alcaraz, Tokyo 2025 highlights", "Alcaraz Tokyo 2025 Extended Highlights", "Tennis TV",
                       "https://www.youtube.com/watch?v=t_C8UqLbAGw"),
    "jannik_sinner": ("Sinner v Auger-Aliassime, Cincinnati", "Sinner v Auger-Aliassime, Cincinnati", "Tennis TV",
                      "https://www.youtube.com/watch?v=HoUD4pbiFn8"),
    "novak_djokovic": ("Auger-Aliassime v Djokovic, Wimbledon", "Auger-Aliassime v Djokovic, Wimbledon", "Wimbledon",
                       "https://www.youtube.com/watch?v=vh3lqgKseCo"),
    "rafael_nadal": ("Nadal v Djokovic, Australian Open", "Nadal v Djokovic Condensed Match", "Australian Open",
                     "https://www.youtube.com/watch?v=sFjMstbZtPw"),
    "roger_federer": ("Federer, Cincinnati 2015 title run", "Federer's Perfect Tournament, Cincinnati 2015", "Tennis TV",
                      "https://www.youtube.com/watch?v=HnGxqlGUTFs"),
    "iga_swiatek": ("Swiatek v Rybakina, Doha 2024", "Swiatek v Rybakina Condensed Match, 2024 Doha", "WTA",
                    "https://www.youtube.com/watch?v=3PgQ1STfDzw"),
    "aryna_sabalenka": ("Sabalenka v Rybakina, US Open", "Sabalenka v Rybakina Extended Highlights", "US Open",
                        "https://www.youtube.com/watch?v=47hMZmSQO2I"),
    "ben_shelton": ("Alcaraz v Shelton, Toronto", "Alcaraz & Shelton First Encounter, Toronto", "Tennis TV",
                    "https://www.youtube.com/watch?v=qVeKt5eFNaQ"),
}


def convert_dir(slug, sam_dir):
    paths = sorted(glob.glob(os.path.join(sam_dir, "sam_video", "*.json")))
    shots, untracked, offset = [], 0, 0.0
    for p in paths:
        with open(p) as fh:
            d = json.load(fh)
        frames, height = d.get("frames", {}), d.get("height", 720)
        evs = sorted(d.get("events", []), key=lambda e: e["frame"])
        if not evs:
            continue
        first = evs[0]["frame"]
        last_t = offset
        for e in evs:
            f0 = e["frame"]
            if e.get("type") not in TYPES or e.get("hitter") not in ("near", "far"):
                continue
            sm = fe.fill(fe.hitter_track(frames, f0, e["hitter"], height), f0)
            prof = fe.profile(sm) if sm else None
            if prof is None:
                untracked += 1
            t_s = round(offset + (f0 - first) / fe.FPS, 3)
            last_t = max(last_t, t_s)
            shot = {"clip": d.get("clip", os.path.basename(p)), "contact_frame": f0, "t_s": t_s,
                    "video_t": round(float(d.get("t0_s", 0.0)) + f0 / fe.FPS, 2), "stroke": e["type"],
                    "kind": "serve" if e["type"] == "serve" else "stroke",
                    "side": e["type"] if e["type"] in ("forehand", "backhand") else "unknown",
                    "side_source": "model_prediction", "hitter": e["hitter"], "conf": round(float(e.get("conf", 0)), 3),
                    "predicted": True, "technique": None, "outcome": None}
            if prof:
                prog, path, peak, _ = prof
                shot.update({"prog": prog, "path_deg": round(path, 1), "peak_len_s": round(peak, 3), "track_cover": 1.0})
            shots.append(shot)
        offset = last_t + GAP_S
    peaks = sorted(s["peak_len_s"] for s in shots if "peak_len_s" in s)
    lo, hi = (peaks[int(0.1 * (len(peaks) - 1))], peaks[int(0.9 * (len(peaks) - 1))]) if peaks else (0.0, 0.0)
    for s in shots:
        s["intensity"] = round(min(1.0, max(0.0, (s["peak_len_s"] - lo) / (hi - lo))), 3) if "peak_len_s" in s and hi > lo else 0.5
    shots.sort(key=lambda s: s["t_s"])
    for i, s in enumerate(shots):
        s["index"] = i
    name, title, up, url = MATCHES.get(slug, (slug, slug, "", None))
    vid = url.split("v=")[-1] if url and "v=" in url else None
    return {"name": name, "video_url": url, "video_id": vid, "predicted": True, "session": {
        "provenance": {"player": "both players (near and far)", "source": f"{title} ({up})", "video_url": url,
                       "tracker": "SAM 3.1 video API (cached tracks, no live calls)", "fps_assumed": fe.FPS,
                       "predicted": True,
                       "labels": "stroke type, hitter and hit time are predictions of the F3Tennis tsm_e2espot model (97% stroke-type "
                                 "accuracy on 60 held-out Ostrava hits; not measured on this broadcast)"},
        "units_note": ("intensity is unitless 0-1 from racket-centre speed in racket lengths per second, normalised within "
                       "this session. It is NOT a speed in km/h. prog and path_deg come from the 2D box centre."),
        "time_note": "tracked windows concatenated with 3 s gaps; within-window timing is true.",
        "omitted": ["ball_speed", "spin", "face_angle", "contact_point"],
        "skipped_events": 0, "untracked_events": untracked, "shots": shots}}


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("sam_root", help="dir with one sub-dir per slug, each holding sam_video/")
    ap.add_argument("--merge", required=True)
    a = ap.parse_args(argv)
    players = []
    for slug in MATCHES:
        d = os.path.join(a.sam_root, slug)
        if os.path.isdir(os.path.join(d, "sam_video")):
            pl = convert_dir(slug, d)
            if pl["session"]["shots"]:
                players.append(pl)
                print(f"{pl['name']}: {len(pl['session']['shots'])} hits ({pl['session']['untracked_events']} without a usable track)")
    with open(a.merge) as fh:
        doc = json.load(fh)
    keep = [p for p in doc["players"] if p["name"] == fe.NAME]           # keep the labelled match, replace the rest
    doc["players"] = keep + players
    with open(a.merge, "w") as fh:
        json.dump(doc, fh, separators=(",", ":"))
    print(f"{len(doc['players'])} players -> {a.merge}")


if __name__ == "__main__":
    sys.exit(main())
