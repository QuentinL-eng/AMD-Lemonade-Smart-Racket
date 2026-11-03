# Web emulator + pro-match data spec

Judges can't swing the physical racket, so the emulator replays a real professional match
through the app's data path: SAM 3.1 tracks the racket on video, the tracks convert to the
app's session format, and a static web page plays the sessions back. Live page:
[`website/emulator.html`](../website/emulator.html) (needs `emulator_sessions.json` beside it).

## Why this is a fair analogy for racket data

The emulator exercises the same pipeline the racket feeds: contact timestamps at realistic
pro cadence, forehand/backhand mix, and rally intensity flow into session totals, the shot
feed, and the what-if questions a judge can ask. What it cannot show — sensor fidelity —
is covered separately by real racket recordings, the C++/Swift/Python parity checks, and
the labeled-session tests. The emulator answers "what does the app do with a session";
the hardware evidence answers "does the racket measure truly".

## What the emulator is (web page)

[`website/emulator.html`](../website/emulator.html) is a browser copy of the iPhone app's five tabs, built to
look and behave like `apple/Shared/Views`:

- **Live** — the app's real textured Yonex racket (`TennisRacket.glb`, shrunk by
  [`tools/optimize_racket_glb.py`](../tools/optimize_racket_glb.py) from 15 MB to 0.65 MB) rendered with
  three.js, the same session controls, stat tiles, shot card (green/red flash), string bed and gyro/g/Hz labels.
- **Score** — working tennis scoring (sets, tiebreaks, no-ad, match tiebreak) with the app's layout.
- **Together**, **Racket** — the signed-out and settings screens (units toggle works; the player picker switches
  the replayed pro).
- **Insights** — metric tabs, summary, chart, sessions, and the Muse entry card. **Muse** and **What if** open
  from it, in the app's dark "Lab" style, including the 3D swing stage with path trail and ghost.

Three things are not in the app and live outside the phone: the player picker, 1×/2×/4× speed and "Skip to end".

## Estimated figures

Footage only gives shot times and a unitless intensity `i` (0-1). Everything else is estimated:

- Swing parameters from `i` and shot index (deterministic): swing = 60 + 90·i km/h; face = ±8·i°
  (sign alternates); path = 10 + 20·i° up (slice: 8-18° down on every third shot below i = 0.25);
  contact scatter spread 7·(1.15 − 0.6·i) cm, sweet iff within 4 cm.
- Ball speed, spin rpm and spin type: a JavaScript port of
  [`ShotSimulator`](../apple/RacketKit/Sources/RacketKit/ShotSimulator.swift) (acor 0.42, spin gain 0.7).
- Racket motion: a port of `SwingTemplate` (`apple/Shared/Coach/SwingFilm.swift`) with the forehand shape.
  Live turns the racket about a point 0.3 m from the butt, as the app's IMU view does, easing to a ready pose
  between hits (slowed to 0.3× so the swing is visible). Gyro °/s is the animated rate; g is a spike at contact
  scaled by `i`. Stroke side is unknown for all clips, so every hit is "Hit" and What if uses the forehand template.
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
