# Demo video script (3:00 hard cap)

Weights: Impact 30, Meta AI 25, Demo 25, Technical depth 20. Judges decide in the first 30 s and remember the last 20 s.
So the hook is a real swing, Meta tech is on screen by about 1:05, Muse Spark gets the longest block, and the close is
proof plus something to try. The live cut is `demo` in [`src/config/timeline.ts`](src/config/timeline.ts); this page says why.
To see it with real timecodes, run `npm run timeline`. To see what's left, run `npm run check`.

Rules: say "smart racket", Muse **predicts**. Never the two anti-project words. Everything is captioned, because most
judges watch muted. Every number on screen comes from the repo.

## The cut

| Time | Beat | Kind | Rubric |
|---|---|---|---|
| 0:00 | Your serve, slow-mo, "Which ones were good?", then the real shot card | **Film** (stand-in plays now) | Demo |
| 0:08 | Racket reveal | CGI, done | Demo |
| 0:13 | You on camera in the bedroom: the problem, what you built | **Film** | Impact |
| 0:22 | Exploded handle from the real CAD | CGI, done | Tech |
| 0:31 | Build montage: solder, board, printed insert, code | Real, cut | Tech |
| 0:37 | Club session: 17% of the stream arrived, so the racket computes each shot | CGI, new | Tech, Impact |
| 0:46 | Real arm, then its CGI twin; it helped catch a gyro reading 2× too high | Real + CGI | Tech |
| 0:56 | Evidence: 296/296, 1.83 cm, 67.2% with its baseline | CGI, new | Tech, trust |
| 1:05 | Phone, Watch, Ray-Ban Display with the Meta Wearables badge | CGI | Meta |
| 1:10 | Through the lens | CGI (labelled simulated), or **film** the real one | Meta |
| 1:17 | Muse Spark as an agent: real trace, 10 tools lighting up | CGI, new | Meta |
| 1:29 | What-if: `simulate_change`, an estimate on an example shot | CGI, real simulator numbers | Meta |
| 1:39 | Hero: real iPhone recording of the what-if and the drill | **Film** | Meta, Demo |
| 2:07 | Watch counts down, phone says "Drill complete!" | **Film** | Impact |
| 2:12 | SAM 3.1: the real cached boxes on your real 240 fps forehand | CGI over real, new | Meta |
| 2:20 | Swing film from Muse's real script, on a demo session | CGI | Meta |
| 2:28 | Three players, one line each | **Film** (or delete and give the time to the hero) | Impact |
| 2:42 | Proof: commits by day and the test counts, read from the repo | CGI, new | Trust |
| 2:50 | Endcard: tennisbuddy.net, TestFlight, no hardware needed | CGI, done | Impact |

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
4. The voiceover, one line at a time, with a duvet around you for a quiet room.

**If anyone is around:** `testimonial-1.mp4` and so on, with their OK to use it on camera. If not, delete those entries. The
`muse-screen-recording` slot can take the 15 s.

Save each clip under that name in `public/footage/`. It replaces the stand-in on its own.

## Check before final render

- A real shot may read oddly. A new indoor session scored 3/8 on stroke type (`ml/stroke_system/README.md`), and ball speed
  has no measured reference yet. Show what the app really says; pick another take rather than editing a number.
- Run `npm run check` until it says Ready, then `npm run render:demo`.
