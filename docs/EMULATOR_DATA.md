# Web emulator + pro-match data spec

Judges can't swing the physical racket, so the emulator replays a real professional match
through the app's data path: SAM 3.1 tracks the racket on video, the tracks convert to the
app's session format, and a static web page plays the session back. Live page:
[`website/emulator.html`](../website/emulator.html) (needs `emulator_session.json` beside it).

## Honesty rules (non-negotiable)

1. The page always shows its provenance banner: video source, tracker, what is derived,
   and what is illustrative. No mode hides it.
2. Broadcast footage supports exactly three quantities: shot times, stroke side/kind from
   dataset labels, and unitless swing intensity. Ball speed, spin, face angle, and contact
   point are not observable and are never presented as measured.
3. No real player's name is attached to measured data. Style presets are illustrative and
   say so. Never commit source footage; derived tracks + this provenance note are the artifact.
4. The committed `emulator_session.json` is synthetic demo data (seed 7) until a real
   `sam_track_to_session.py` run replaces it. Its provenance block says exactly that.

## Why this is a fair analogy for racket data

The emulator exercises the same pipeline the racket feeds: contact timestamps at realistic
pro cadence, forehand/backhand mix, and rally intensity flow into session totals, the shot
feed, and the what-if questions a judge can ask. What it cannot show — sensor fidelity —
is covered separately by real racket recordings, the C++/Swift/Python parity checks, and
the labeled-session tests. The emulator answers "what does the app do with a session";
the hardware evidence answers "does the racket measure truly".

## Pipeline (runs on your machine, video stays local)

```bash
# 1. SAM 3.1 video tracking on labelled clips (NOT the full match through the API:
#    F3Set labels pick the clips; --budget caps dollars. ~$0.20 per 1000 frames billed.)
python3 tools/sam_f3set_video.py ~/tennis_data/f3set --clips 10   # pilot first
python3 tools/sam_f3set_video.py ~/tennis_data/f3set --clips 80 --budget 25

# 2. Tracks -> emulator session (offline, no key, no network)
python3 tools/sam_track_to_session.py ~/tennis_data/f3set/sam_video/qf.json \
    --fps 30 --source "F3Set broadcast footage (local, deleted after tracking)" \
    -o website/emulator_session.json

# 3. Deploy: copy both files into .website-dist/ next to index.html, then publish.
```

Cost control: `--budget` caps every SAM run; ledgers (`sam_video_ledger.json`) count billed
frames across runs. A full 2-hour match at 30 fps is ~216k frames (~$43) — always window
around contacts instead. Delete source video after tracking unless you are entitled to keep
it; F3Set access follows that dataset's own terms.

## Schema (`emulator_session.json`)

Written by [`tools/sam_track_to_session.py`](../tools/sam_track_to_session.py), tested by
[`tools/test_sam_track_session.py`](../tools/test_sam_track_session.py) against the fixture
in `tools/fixtures/`. Fields per shot: `t_s`, `kind`, `side` (+ `side_source`), `intensity`
(unitless 0-1), `track_cover`, `clip`. Top level: `provenance`, `units_note`, `omitted`.
