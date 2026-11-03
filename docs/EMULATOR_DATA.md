# Web emulator + pro-match data spec

Judges can't swing the physical racket, so the emulator replays a real professional match
through the app's data path: SAM 3.1 tracks the racket on video, the tracks convert to the
app's session format, and a static web page plays the sessions back. Live page:
[`website/emulator.html`](../website/emulator.html) (needs `emulator_sessions.json` beside it).

## Honesty rules (non-negotiable)

1. The page always shows its provenance banner: video source, tracker, what is derived,
   and what is illustrative. No mode hides it.
2. Broadcast footage supports exactly three quantities: shot times, stroke side/kind from
   dataset labels (never guessed from pixels), and unitless swing intensity. The labelled
   match adds the hitter's racket timing from the SAM box centre (a rough 2D guide). Ball
   speed, spin, face angle, and contact point are not observable and are never presented
   as measured; the contact point is an assumed prior (see Estimated figures).
3. No real player's name is attached to measured data. Style presets are illustrative and
   say so. Never commit source footage; derived tracks + this provenance note are the artifact.
4. The committed `emulator_sessions.json` carries one entry per player, each with its own
   provenance block (video title, uploader, URL). Current file (9 players, 2,265 hits): the
   labelled Ostrava 2022 final (60 hits, real F3Tennis stroke labels and outcomes, both
   players) plus 8 broadcast matches (2,205 hits) whose stroke type, hitter and hit time are
   **predictions of the F3Tennis tsm_e2espot model** (flagged `predicted`, with its confidence),
   with SAM 3.1 racket tracks for the swing timing (611 windows, 79,945 billed frames, $15.99;
   an earlier 291-hit audio-window pass cost $5.86 and was replaced). Source videos are
   deleted after tracking. Sessions are named by match, not by one player, because both
   players' hits are in them.
5. Stroke types for those 8 matches are model predictions, never presented as labels: the shot card, the
   info panel and the footer say so. The model scored 97% (58/60) on stroke type on 60 hits of the Ostrava test
   split; accuracy on these broadcasts was not measured, and Ostrava shares its match and camera with the
   training clips, so that number is optimistic.

## Why this is a fair analogy for racket data

The emulator exercises the same pipeline the racket feeds: contact timestamps at realistic
pro cadence, forehand/backhand mix, and rally intensity flow into session totals, the shot
feed, and the what-if questions a judge can ask. What it cannot show — sensor fidelity —
is covered separately by real racket recordings, the C++/Swift/Python parity checks, and
the labeled-session tests. The emulator answers "what does the app do with a session";
the hardware evidence answers "does the racket measure truly".

## Pipeline (runs on your machine, video stays local)

```bash
# 1. Detect contacts in a clip, track +-1 s windows with SAM 3.1 (NOT the full match
#    through the API; --budget caps dollars. ~$0.20 per 1000 frames billed.)
python3 tools/sam_clip_hits.py clip.mp4 --player alcaraz --out work/alcaraz --probe
python3 tools/sam_clip_hits.py clip.mp4 --player alcaraz --out work/alcaraz \
    --max-windows 25 --budget 3 --yes

# 2. Tracks -> per-player emulator sessions (offline, no key, no network)
python3 tools/sam_players_to_emulator.py work/alcaraz work/sinner \
    -o website/emulator_sessions.json

# 2b. Labelled match (F3Tennis clips already tracked by tools/sam_f3set_video.py): real stroke
#     labels + the hitter's racket timing per hit. Replaces the 'Ostrava' entry, keeps the rest.
python3 tools/f3set_to_emulator.py data/external/f3set/sam_video --merge website/emulator_sessions.json

# 2c. Model-predicted matches (separate CUDA environment: tools/f3tennis_model/README.md):
python3 tools/f3tennis_model/detect_pros.py        # whole video at 25 fps -> <video>.ev25.json (hits, type, hitter, conf)
python3 tools/sam_model_windows.py video.mp4 video.ev25.json --player nadal --out work/nadal \
    --frames 13500 --budget 2.75 --ledger work/ledger_nadal.json --plan   # prints the cost; add --yes to spend
python3 tools/model_events_to_emulator.py work --merge website/emulator_sessions.json

# 3. Deploy: copy index.html, emulator.html, both session files and emulator/ into .website-dist/, then publish.
```

Cost control: `--budget` caps every SAM run; ledgers (`sam_video_ledger.json`) count billed
frames across runs. A full 2-hour match at 30 fps is ~216k frames (~$43) — always window
around contacts instead. Delete source video after tracking unless you are entitled to keep
it; F3Set access follows that dataset's own terms.

## What the emulator is (web page)

[`website/emulator.html`](../website/emulator.html) is a browser copy of the iPhone app's five tabs, built to
look and behave like `apple/Shared/Views`:

- **Live** — the app's real textured Yonex racket (`TennisRacket.glb`, shrunk by
  [`tools/optimize_racket_glb.py`](../tools/optimize_racket_glb.py) from 15 MB to 0.65 MB) rendered with
  three.js, the same session controls, stat tiles, shot card (green/red flash), string bed and gyro/g/Hz labels.
- **Score** — working tennis scoring (sets, tiebreaks, no-ad, match tiebreak) with the app's layout.
- **Settings** — the app's Settings screen (units toggle works; the player picker switches the replayed match),
  with "Play together" opening the signed-out Together screen, as in the app.
- **Insights** — stroke chips, metric tabs, summary, chart, by-stroke bars and sessions.
- **Muse** — its own tab, as in the app since the Nov 3 restructure (tabs: Live, Score, Muse, Insights, Settings), in
  the app's dark "Lab" style: best change, drill, memory, **What if** (3D swing stage with path trail and ghost),
  **Practice plan**, **Scout yourself** and **Review queue**. The plan, scout and review texts are written by a
  template from the replay's own numbers, labelled "Demo engine · offline".

Three things are not in the app and live outside the phone: the player picker, 1×/2×/4× speed and "Skip to end".

## Estimated figures

Footage only gives shot times and a unitless intensity `i` (0-1). Everything else is estimated:

- Swing parameters from `i` and shot index (deterministic): swing = 60 + 90·i km/h; face = ±8·i°
  (sign alternates); path = 10 + 20·i° up (slice: 8-18° down on every third shot below i = 0.25);
  contact is an **assumption**, not data: bell-shaped around the sweet spot with sigma 2.0 + 0.5·i cm
  (0.9× across, 1.1× along), about 85% of hits inside the 4 cm sweet spot (82-88% per player) (sweet iff within 4 cm). Video cannot
  show where the ball met the strings, so Insights' contact and off-center results reflect this prior only.
- Ball speed, spin rpm and spin type: a JavaScript port of
  [`ShotSimulator`](../apple/RacketKit/Sources/RacketKit/ShotSimulator.swift) (acor 0.42, spin gain 0.7).
- Racket motion: a port of `SwingTemplate` (`apple/Shared/Coach/SwingFilm.swift`), using each stroke's own shape
  (forehand, backhand from the other side, overhead serve, short volley). Live turns the racket about a point 0.3 m
  from the butt, as the app's IMU view does, easing to a ready pose between hits and moving the camera to each
  stroke's viewpoint. For labelled hits the swing's timing is that hit's own SAM track in real time; for the rest it
  is the template's profile, slowed to 0.3×. Gyro °/s is the animated rate; g is a spike at contact scaled by `i`.
  In the 8 unlabelled matches every hit is "Hit" and drawn as a forehand.
- What if: baseline = mean of shots so far; levers and limits match `WhatIf.Deltas`; the sentence matches
  `WhatIf.describe`.
- Muse: the suggested questions and the "Find it" button run local ports of `get_session_digest`, `query_shots`,
  `list_shots` and `simulate_change`; a template writes the reply. It does not call Muse Spark and the page says so.

## Schema (`emulator_sessions.json`)

`{"players": [{"name", "video_url", "session"}]}`, written by
[`tools/sam_players_to_emulator.py`](../tools/sam_players_to_emulator.py) over per-window
caches converted with [`tools/sam_track_to_session.py`](../tools/sam_track_to_session.py).
Fields per shot: `t_s`, `kind`, `side` (+ `side_source`), `intensity` (unitless 0-1),
`track_cover`, `clip`. Each session carries `provenance` (player, source, video URL),
`units_note`, `time_note`, and `omitted`.

The labelled entry ([`tools/f3set_to_emulator.py`](../tools/f3set_to_emulator.py), tested by
`tools/test_f3set_emulator.py`) adds per hit: `stroke` (forehand/backhand/serve/volley, as the app's `ShotType`),
`technique`, `hitter` (near/far), `court`, `dir`, `outcome` (in/winner/forced-err/unforced-err), and, when the
hitter's racket was tracked, `prog` (25 values from -1 to +1: how far through the stroke the racket is each frame
from -12 to +12 around contact, by path length) and `path_deg` (direction of the racket centre at contact, scaled by 0.3 and clamped to -15..30 because the camera looks down and inflates upward motion). 50 of the 60 hits have a usable track; the other 10 still carry their real stroke type and
use the template's timing. F3Set video is 25 fps. `data/external/` is not committed; only this derived entry is.

The model-predicted entries (`tools/model_events_to_emulator.py`, tested by `tools/test_model_events.py`) have the same
fields with `predicted: true`, `side_source: "model_prediction"`, `conf` (the model's stroke-type confidence), and
`technique`/`outcome` null. 66% of their hits have a usable hitter's-racket track (`prog`); the rest keep the predicted
stroke type and use the template's timing.
