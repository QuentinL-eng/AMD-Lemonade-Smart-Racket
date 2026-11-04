# Swing film: Muse directs, the renderer draws

A swing film shows **your swing**, then **the change Muse recommends**, then the estimated effect. In the app it is a
live 3D animation on the What-if screen (Insights → Muse → What if): it loops your average forehand, backhand, serve or volley and
the changed swing in slow motion, follows the sliders as you move them, and **Show me the best change** has Muse pick
and test the change, which then sets the sliders and the title. `video/` renders the same thing as an 8-second clip.
Every film looks the same because Muse never makes pixels. Muse (Meta's open Muse Spark, served by Baseten)
reads the racket's numbers, tests changes with the `simulate_change` tool and returns a small, validated script.
A fixed Remotion scene (`video/src/swingfilm/`) turns that script into video. Meta's API has no video model, and
we would not want one here: a generated video could invent a body, a court or a ball flight the racket never measured.

```
racket shots ──► Muse Spark ──► simulate_change (ShotSimulator) ──► make_swing_film(script) ──► validator ──► renderer ──► MP4
               (picks the change)   (estimates the effect)             (≤ 2 levers, short text)    (rejects)    (fixed look)
```

## Inputs: only the racket

The film is a function of five per-stroke averages the racket already reports, and of the simulator's result:

| Input | Source |
|---|---|
| Swing speed, swing path, face angle | IMU, per shot (`ShotMetrics`) |
| Contact point across and along the strings | IMU + mic, per shot |
| Ball speed and spin before/after | `simulate_change` on the player's own average shot |

No phone camera, no photos, no body model. The arm is a fixed pivot; only the racket moves.

## What Muse may choose (the script)

`make_swing_film` takes exactly these fields. Anything else is rejected.

| Field | Limit |
|---|---|
| `stroke` | `forehand` (clip); in the app also `backhand` (mirrored), `serve` (overhead arc) and `volley` (short punch) |
| `swing_percent` | −15…15, or 0 |
| `face_deg` | −6…6, or 0 (+ opens the face) |
| `path_deg` | −10…10, or 0 (+ is more low-to-high) |
| `contact_x_cm`, `contact_y_cm` | −3…3, or 0 |
| levers changed | 1 or 2, each big enough to see: ≥ 3 %, ≥ 2°, ≥ 1 cm |
| deltas | must equal a `simulate_change` call Muse made in the same conversation, for the same stroke |
| `title` | ≤ 24 characters, no digits |
| `cue` | ≤ 60 characters, no digits: what to feel, in plain words |
| `why` | ≤ 90 characters, no digits |
| words | none of: coach, guarantee, landing, depth, net, injury, pain, always, never |

Every number on screen comes from the racket or the simulator, never from Muse's text. The validator sends a
rejected script back to Muse with the reasons, at most twice; after that no film is made.

## What Muse cannot touch (the look)

These live in `apple/Shared/Views/SwingAnimationView.swift` (app) and `video/src/swingfilm/look.ts` (clip), and
are the same for every film:

- Timing: 3 s **Your swing**, then 3 s **Try this** (2.6 s each in the app) (your swing stays as a faint ghost). The app loops the two halves
  and shows the estimates in the What-if cards; the clip is 1920×1080, 30 fps, 8 s, with a 2 s before/after card.
- One camera, one 3/4 angle, no camera moves. Studio backdrop, brand colours (lime `#DDE85B` on `#0B0C09`),
  carbon racket, lime ball.
- The same swing template and timing; 0.16× slow motion through contact in both halves.
- Fixed label slots: the half playing, the title, and (clip) swing speed, path, face and a contact dot on the string bed.
- Text only in the title, cue and card slots, in the brand fonts. Results are always labelled **Estimated**.
- No music, people, court, ball flight or landing spot. Those aren't measured.

## In the app

`SwingFilmDirector` (`apple/Shared/Coach/SwingFilm.swift`) runs the loop with the app's own tools and validator;
`SwingTemplate` there is the swing math, and `SwingAnimationView` draws it with SceneKit. The script never leaves the
device except as Muse's own tool calls, and nothing is generated when Muse is off or signed out.

## Make a clip

```bash
python3 tools/swing_film.py --sample             # asks Muse; writes video/src/config/swingFilm.json
cd video && npx remotion render SwingFilm out/swing-film.mp4
```

`--sample` uses a demo forehand session (realistic numbers, not a recording). Pass `--shots <file.shots.jsonl>` to use
a real session's forehands.
