# Demo video script (3:00 hard cap)

Weights: Impact 30, Meta AI 25, Demo 25, Technical depth 20. Judges decide in the first 30 s and remember the last 20 s.
So the hook is a real swing, Meta tech is on screen by about 0:47, Muse Spark gets the longest block, and the close is
something to try. The live cut is `demo` in [`src/config/timeline.ts`](src/config/timeline.ts); this page says why.
To see it with real timecodes, run `npm run timeline`. To see what's left, run `npm run check`.

Rules: say "smart racket", Muse **predicts**. Never the two anti-project words. Everything is captioned, because most
judges watch muted. Every number on screen comes from the repo.

## The cut

| Time | Beat | Kind | Rubric |
|---|---|---|---|
| 0:00 | Your serve, slow-mo, then a forehand: "Which ones are good?" | Real | Demo |
| 0:08 | Racket reveal, on the app's real racket model | CGI | Demo |
| 0:13 | You on camera: what you built | Real | Impact |
| 0:25 | Exploded handle from the real CAD | CGI | Tech |
| 0:32 | Build montage | Real | Tech |
| 0:38 | Robot arm: the first 24 beats of the X clip, on its own song, no voiceover | Real + CGI | Tech |
| 0:49 | Two models: our own on the ESP32, open Muse Spark on Baseten in the app | CGI | Meta, Tech |
| 0:57 | Measured: 296/296, 1.83 cm, 87.7%. Replace the distance card when the IMU + mic sessions are scored | CGI, **line not recorded** | Tech |
| 1:05 | A real serve beside the app's 3D racket, at their real offset | Real | Demo |
| 1:13 | Phone, Watch, Ray-Ban Display with the Meta Wearables badge | CGI | Meta |
| 1:22 | The player's court view with the HUD fields drawn on, labelled simulated | Real + CGI | Meta |
| 1:28 | Tap the handle to score | Real | Demo |
| 1:33 | Muse Spark as an agent: 10 tools lighting up | CGI, **line not recorded** | Meta |
| 1:43 | What-if: `simulate_change`, an estimate on an example shot | CGI, real simulator numbers | Meta |
| 1:52 | Hero: live simulator recording with real Muse Spark Open calls: best change, What if, drill, an answer | Real, labelled | Meta, Demo |
| 2:12 | Watch and serve selects | Real | Impact |
| 2:18 | SAM 3.1: the real cached boxes on your real 240 fps forehand | CGI over real | Meta |
| 2:26 | Swing film from Muse's real script, on a demo session | CGI, **line not recorded** | Meta |
| 2:32 | Two players, their own lines | Real | Impact |
| 2:46 | The online simulator, tennisbuddy.net/emulator | Real | Impact, Demo |
| 2:54 | Endcard: online simulator, no racket needed | CGI | Impact |

Build it: `scripts/cut-selects.py` (selects, interviews, voice takes), `scripts/capture-emulator.mjs` then `scripts/cut-emulator.py`
(simulator clips; check its spans and `museCallouts` after a new run, because Muse's answers change), `npm run render:demo`,
then `scripts/master-demo.py` for the upload file, `out/tennis-buddee-demo.mp4`.

Words to keep true: the model on the ESP32 is ridge regression, so it is "our own ML model", not a neural net, until one ships. The
87.7% was scored on open Muse Spark, the model the app uses, served by Baseten. The swing film's script came from `muse-spark-1.3`, and its badge says only "Muse Spark". A number measured on thrown balls says so on screen.

## Voiceover

All lines live in [`src/config/voiceover.ts`](src/config/voiceover.ts), with their captions. Record one line per file and save
it as `public/audio/vo/<id>.wav`. It starts playing and the music ducks, with no other change.

## What to film today

**Court**
1. `cold-open.mp4`: the serve, 240 fps from the side, toss to contact.
2. Keep the app on Live while you serve and note one real shot: stroke, ball speed, spin, swing, sweet spot. Those numbers go
   in `copy.coldOpenShot` in `src/config/copy.ts`, because the card sits on real footage. It wears a SAMPLE tag until they do.

**Bedroom**
1. `talk-intro.mp4`: landscape, racket in hand, 9 s. Change the slot's `caption` in `timeline.ts` to what you actually said.
2. `muse-screen-recording.mp4`: portrait iPhone screen recording, slowly, from a build with the Nov 3 tabs (Live, Score,
   Muse, Insights, Settings). Muse tab → What if → ask → wait for the numbers, then Next drill → Start on Watch.
3. `drill-on-watch.mp4`: close on the Watch as the to-go count drops, ending on the phone's Live tab: "Drill complete!".
4. `simulator.mp4`: landscape screen recording of tennisbuddy.net/emulator: pick a match, Start Session, let a few hits land, open Muse and What if.
5. The voiceover, one line at a time, with a duvet around you for a quiet room.

Save each clip under that name in `public/footage/`. It replaces the stand-in on its own.

## Check before final render

- A real shot may read oddly. A new indoor session scored 3/8 on stroke type (`ml/stroke_system/README.md`), and ball speed
  has no measured reference yet. Show what the app really says; pick another take rather than editing a number.
- Run `npm run check` until it says Ready, then `npm run render:demo`.
