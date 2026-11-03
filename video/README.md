# Tennis Buddee: reveal + demo video

Remotion project. Everything is real-time CGI rendered from the real CAD and app
UI, plus slots for real footage. No AI-generated video.

| Composition | Length | Use |
|---|---|---|
| `Reveal` | ~60 s | CGI only, crossfades |
| `RevealSong` | 1:08 | CGI only, hard cuts on the beat of "Keep It Movin'". The X post |
| `Demo` | 2:56 | Hackathon submission (limit 3:00). CGI + footage slots. Script: [`DEMO_SCRIPT.md`](DEMO_SCRIPT.md) |
| `Hype` | 0:30 | X hype clip, CGI only, on "Keep It Movin'" |
| `RobotHype` | 0:27 | X clip from the 2026-10-29 robot-arm session: real footage cut against CGI, on "Ten" |
| `BuildLog` | 0:26 | X clip: the build as a six-step how-to (bench, robot, court footage + CGI), on "Comin Wit It" |
| `EverySwing` | 0:29 | X clip: on court under a HUD, a CGI swing, the app; tagline "Be better.", on "Not My First Rodeo" |
| `Possessed` | 0:27 | Halloween X clip: "this racket is possessed... by an AI", on "Whoop" |
| `Scenes/scene-*` | each beat | Iterate on one scene at a time |

## Run

`RevealSong` and the hype cut need `public/audio/keep-it-movin.mp3`. It is licensed to the project owner and kept out of
this public repo (see `public/audio/CREDITS.md`), so copy it in locally before rendering them.

```bash
npm install
npm run studio          # live preview at http://localhost:3000
npm run render:reveal   # -> out/reveal.mp4
npm run render:song     # -> out/reveal-song.mp4
npm run render:demo     # -> out/demo.mp4
npm run check           # what's left before the Demo can ship (length, footage, samples, voiceover, banned words)
npm run clips           # the Demo's CGI scenes and transparent overlays as files in out/clips/, for an outside editor
npm run timeline -- RevealSong   # timecodes (and bars) of any cut
FFMPEG=path/to/ffmpeg DEEP_FILTER=path/to/deep-filter.exe npm run testimonials   # isolates the voices in the filmed testimonials -> public/footage/ (see the script for the download)
npm run frames          # key frames of every scene -> out/review/
node scripts/stills.mjs RobotHype 150 372 716   # several frames, one bundle -> out/review/
```

### RobotHype (robot-arm footage + CGI)

Needs `public/audio/ten.mp3` (licensed, git-ignored) and the cut footage:

```bash
FFMPEG=path/to/ffmpeg npm run footage:robot   # marketing/Videos -> public/footage/rh-*.mp4 (+ plate stills)
npm run render:robot                          # -> out/robot-hype.mp4
```

`scripts/cut-footage.mjs` lists every clip (source, in point, speed, crop). It de-squeezes the
anamorphic Sony clips, tone-maps the iPhone HLG clips to SDR and crops portrait to 16:9, so the
composition only ever plays small 30 fps SDR files. Copy, clip names and beat positions are in
`src/config/robotHype.ts`. The song's tempo (126.0) and drop (38.095 s) were measured from the drums;
`analyze-song.mjs` reads this track as 125.3, which drifts by the drop.

Real-to-CGI hand-offs: whip-pan cuts with matching framing (the CAD arm from the handle side, like
the real shot), CGI composited over the real room (the same clip blurred, or a still of it), one grade,
grain and vignette over both, and the strung blue `Racket` drawn in the CAD arm's grip (`racket="blue"`).

### BuildLog, EverySwing, Possessed

Same footage + CGI treatment, sharing `src/hype/kit.tsx` (beat clock, grade, clips, whips, ducking)
and `src/hype/pieces.tsx` (word shots, the CAD handle, the CGI racket finale). Each needs its song
section and its clips:

```bash
FFMPEG=path/to/ffmpeg npm run songs            # marketing/Music -> public/audio/*.wav (sections, built-in drops)
FFMPEG=path/to/ffmpeg npm run footage -- bt- ev- hw-
npm run render:build                           # -> out/build-log.mp4
npm run render:swing                           # -> out/every-swing.mp4
npm run render:possessed                       # -> out/possessed.mp4
```

`scripts/prep-songs.mjs` holds each song's measured tempo and the downbeat the clip starts on.
"Comin Wit It" and "Whoop" run flat out, so the first two bars play through a low-pass and the full
mix drops on beat 8; "Not My First Rodeo" (92 BPM, not the 157.7 a plain onset comb reports) has its
own drop. Copy and beats are in `src/config/buildLog.ts`, `everySwing.ts` and `possessed.ts`. The
on-court racket is red, so those CGI shots use `<Racket finish="red" />`.

## Where to edit

You should almost never need to open a scene file.

| To change | Edit |
|---|---|
| Any on-screen text or number | `src/config/copy.ts` |
| Example shots (cards, HUD, what-if) | The inputs at the top of `src/config/copy.ts`. They run through `src/lib/sim.ts`, a mirror of the app's simulator |
| Spoken lines and their captions | `src/config/voiceover.ts`. Save a recording as `public/audio/vo/<id>.wav` and it plays |
| Scene order, length, crossfade | `src/config/timeline.ts` (`reveal`, `demo`). Lines follow their entry when you reorder |
| Add your filmed clips | Save as `public/footage/<slot id>.mp4`. No code change |
| Cards and text over a shot | `overlays` on the entry in `src/config/timeline.ts`, drawn by `src/components/Overlays.tsx` |
| Commit counts, test counts, Muse tools, model results | Nothing: `npm run assets` reads git and `../hackathon.json` into `src/config/generated/facts.json` |
| The SAM clip and boxes | `npm run sam -- <candidate>` (uses the cache, no API call). Needs the recording in `../data/Tennis Camera/` |
| Colours, fonts, resolution | `src/config/brand.ts` |
| Music, effect files, per-scene sound cues | `src/config/sound.ts` (credits in `public/audio/CREDITS.md`) |
| Cut to a new song | run `scripts/analyze-song.mjs` on it for BPM + first downbeat, then copy the `revealSong` pattern in `src/config/timeline.ts` (scene lengths in bars, `skip` to land key moments on beats) |
| Ball-flight arc in the what-if scene | `features.showBallFlight` in `src/config/timeline.ts` (only once ShotSimulator models flight) |

### Footage slots

```ts
{ footage: 'cold-open', seconds: 8, from: 12.5, caption: '…', shot: '…', clips: [['ev-toss', 3.2, 0.5]], standIn: true }
```

- `public/footage/<footage>.mp4` fills the slot as soon as it exists. Until then it plays `clips`, then `fallback` (a CGI
  scene), then a placeholder with the `shot` notes.
- `clips`: `[name, seconds, optional rate]`, cut end to end from `public/footage/`. `standIn: true` tags them on screen and
  makes `npm run check` fail, so a stand-in can't ship by accident.
- `from`: start the clip this many seconds in (trim). `playbackRate`: speed it up.
- `layout: 'phone'`: a portrait screen recording in an iPhone frame, ungraded.
- `muted: false`: keep the clip's audio (testimonials, talking to camera).
- `caption`: burned-in subtitle, for a clip with no line in `voiceover.ts`.

The `Demo` length is computed from the list. Keep the total under 3:00, which the studio timeline shows.

### CAD

The handle and robot arm come straight from Onshape STEP exports in `cad/`:

```bash
node scripts/step-to-json.mjs handle cad/handle.step
node scripts/step-to-json.mjs robot  cad/robot-arm.step
```

Part groups (what moves and gets labelled) are the regex rules at the top of
`scripts/step-to-json.mjs`. The app icon and court photo are copied in by
`npm run assets`, which runs before studio/render.

### The racket

`src/lib/racketMesh.ts` builds a generic, unbranded racket procedurally from real
dimensions (the `D` table at the top: head size and shape, throat, 16x19 strings, grip).
The frame is one surface: the shaft, both throat arms and the hoop (whose bottom is the
bridge) are signed distance fields of a rounded-box beam swept along a centreline, joined
in the face-on outline with a smooth minimum (so the throat gets real fillets without the
beam swelling), given depth with rounded edges and meshed with surface nets (~0.7 s, once
per tab). Beam sizes vary along the frame (deeper through the throat, a slimmer bridge), and
the head has a string groove with a grommet/bumper strip and a grommet at every string.
The handle is an octagonal grip with the spiral overgrip overlap, finishing tape, a collar
into the shaft and a butt cap. `src/components/Racket.tsx` holds the paint (`PAINT`: frame
colour plus a panel on one throat arm, like the red on-court racket) and the materials.
To check the shape after editing, render the model sheet (`VIEWS` in
`src/scenes/dev/RacketSheet.tsx`: face-on, side, hero, throat close-ups, head top, handle,
each finish):

```bash
node scripts/stills.mjs racket-sheet 0 1 2 3 4 5 6 7 8 9 10   # -> out/review/
```

 The opening shot's camera moves
are the `SHOT` keyframes at the top of `src/scenes/RacketReveal.tsx`. Hero scenes pass
`hero` to `Stage3D` for 2x supersampling, bloom, filmic tone mapping and a vignette
(slower to render, so the other 3D scenes leave it off).

**Known gap:** the robot STEP has no `arm_1` (J1→J2 shoulder) link. `RobotLab.tsx`
draws a stand-in (a column on the J1 turret plus the J2 hub) until a re-export includes
it; it switches to the real part automatically then. J1/J2 positions are the constants
at the top of `RobotLab.tsx`, measured from the base turret and the arm_2 boss.

## Scene files

`src/scenes/*.tsx`, one per beat, registered in `src/scenes/index.ts`. 3D scenes use
`components/Stage3D.tsx` (shared lights/camera) and `lib/models.ts` (model loading).
Animation is driven by frame number only (no `Math.random`, no timers), so renders are deterministic.

## Copy rules

- Don't call it a coach or an analyzer: "Sports analyzers or coaches" is on the hackathon's anti-project list. `npm run check` looks.
- Mirror real app strings (`copy.ts` notes the source file of each).
- Numbers shown over real footage must be that shot's real numbers. `copy.coldOpenShot` stays tagged SAMPLE until they are.
- Label what isn't measured: example shots say so, what-if results are estimates, and the glasses scene says it's simulated.
