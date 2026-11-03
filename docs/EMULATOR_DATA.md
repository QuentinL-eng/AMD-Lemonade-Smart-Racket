# Web emulator + pro-match data spec

Judges can't swing the physical racket, so the emulator replays a real professional match
through the app's data path: SAM 3.1 tracks the racket on video, the tracks convert to the
app's session format, and a static web page plays the sessions back. Live page:
[`website/emulator.html`](../website/emulator.html) (needs `emulator_sessions.json` beside it).

## Honesty rules (non-negotiable)

1. The page always shows its provenance banner: video source, tracker, what is derived,
   and what is illustrative. No mode hides it.
2. Broadcast footage supports exactly three quantities: shot times, stroke side/kind from
   dataset labels, and unitless swing intensity. Ball speed, spin, face angle, and contact
   point are not observable and are never presented as measured.
3. No real player's name is attached to measured data. Style presets are illustrative and
   say so. Never commit source footage; derived tracks + this provenance note are the artifact.
4. The committed `emulator_sessions.json` carries one entry per player, each with its own
   provenance block (video title, uploader, URL). Current file: 8 pro players, 291 shots
   from SAM 3.1-tracked broadcast windows (29,296 billed frames, $5.86), source videos
   deleted after tracking.

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

# 3. Deploy: copy both files into .website-dist/ next to index.html, then publish.
```

Cost control: `--budget` caps every SAM run; ledgers (`sam_video_ledger.json`) count billed
frames across runs. A full 2-hour match at 30 fps is ~216k frames (~$43) — always window
around contacts instead. Delete source video after tracking unless you are entitled to keep
it; F3Set access follows that dataset's own terms.

## Illustrative figures (web emulator only)

[`website/emulator.html`](../website/emulator.html) mirrors the app's Live tab
(`apple/Shared/Views/LiveView.swift`, `Components.swift`: string-bed geometry ported 1:1),
so it needs speeds the footage cannot supply. These are computed deterministically from
intensity `i` (0-1) and shot index, and every surface labels them illustrative:

- swing = 60 + 90·i km/h; ball = swing·1.35 + 8 (+ small deterministic jitter)
- spin = 800 + 2200·i rpm (topspin; slice below i = 0.25 on every third shot)
- face = ±8·i° (sign alternates); path = 10 + 20·i° up (slice: 8-18° down)
- contact (cm): deterministic scatter, spread 7·(1.15 − 0.6·i), clamped to the head;
  sweet iff within 4 cm. Sweet-spot verdicts and the green/red flash follow from this.

## Schema (`emulator_sessions.json`)

`{"players": [{"name", "video_url", "session"}]}`, written by
[`tools/sam_players_to_emulator.py`](../tools/sam_players_to_emulator.py) over per-window
caches converted with [`tools/sam_track_to_session.py`](../tools/sam_track_to_session.py).
Fields per shot: `t_s`, `kind`, `side` (+ `side_source`), `intensity` (unitless 0-1),
`track_cover`, `clip`. Each session carries `provenance` (player, source, video URL),
`units_note`, `time_note`, and `omitted`.
