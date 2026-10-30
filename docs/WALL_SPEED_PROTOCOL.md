# Wall drill: ground-truth ball speed (about 1 hour, one evening)

**Why.** The app turns the gyro into ball speed with `(1 + e) * R * |ω_yz|`, with `e = 0.42` and `R = effectiveRadiusM = 1.15`
(`ShotAnalyzer.swift`, `Calibration.swift`). That radius dates from the first RacketKit commit (Oct 26), before the 2x
gyro error was found, so every displayed swing and ball speed is suspect. This drill measures real ball speed so the
radius can be fitted instead of guessed. It also gives a first labeled set of hard, real shots.

(`docs/WALL_SPEED_TEST.md` is a sibling version of this test, written for `tools/wall_speed_fit.py`: 8-10 m from the
wall, flight time counted by hand from 240 fps video, audio as a fallback. This document is the audio-timed variant,
and `tools/wall_speed_analyze.py` automates the audio timing and writes the truth file that `wall_speed_fit.py` reads.
Both use the same truth-file format, so results from either can be fitted together. A longer distance gives better
timing resolution but a bigger drag bias: expect the mean flight speed to read several percent low at 4 m and
noticeably more at 9 m, and compare fitted radii only between recordings taken at the same distance.)

**What it measures.** For each hit: the racket's pop (loudest sound, matched to the IMU's high-g spike), then the
wall thud. Mean ball speed = wall distance / flight time. The analysis fits that against the IMU's `|ω_yz|`.

## You need
- The racket on **firmware 1.6** (serial status line must say `gyro ±4000 dps`).
- The Mac app (recording to `~/Documents/Recordings`) or any build that writes a `.tbrec`.
- A phone to film, with working audio (normal video at 60 fps is fine; slow-mo audio is unreliable). Tripod or a stable surface.
- A flat, solid wall with nothing breakable, tape measure, chalk or tape, 15+ tennis balls, a notebook.
- Eye protection. Balls come back fast: clear the area behind and beside you.

## Setup
1. Stick a tape cross on the wall at about 1 m height. Mark a hitting spot **4.0 m** from the wall (measure from the
   spot where the ball leaves the racket, in line with the cross). Write the real distance down.
2. Put the phone on the floor or a stand next to you, about 1 m from the hitting spot, mic facing the wall, filming the
   wall and you. Note the distance to the phone.
3. Before hitting anything, **start recording in the app** and check the file grows:
   `ls -l ~/Documents/Recordings/*.tbrec` twice, a few seconds apart. (Last time a 2-hour recording only worked
   because the recorder was already on; do not assume.)
4. Start the phone video.

## Start-of-session checks (1 minute)
- Hold the racket still for 5 s, flat on a table.
- Lift it, rotate it 90° to tip-up, hold 5 s, lay it flat again. Repeat 3 times. (A later self-check will compare the
  gyro with gravity from these; nothing needs doing with them tonight.)
- Tap the handle 3 times, hard. This marks the start in both IMU and audio.

## The drill: self-fed drop hits
Drop the ball so it bounces once off the floor, then hit it at the wall. No ball is coming at the racket, which is
exactly the case the model assumes (`incomingBallMs = 0`). Let the return go; do not hit it.

Effort levels, **interleaved** in this order, so effort is not confounded with time in the session:
- **E** easy: just pop it onto the wall.
- **M** medium: normal rally pace.
- **H** hard: as hard as you can still keep it on the tape cross.

Round = E M H E M H E M H (9 hits). Do **5 rounds of forehands (45 hits)**, then **3 rounds of backhands (27 hits)**.
Rest between rounds, collect the balls. Write down the effort order exactly as hit, and the number of any shot that
was a miss (mishit, bad bounce, ball hit the floor or a side wall, a double hit). Count shots as the app does.

Rules that matter:
- One hit per drop; wait until the ball has stopped before the next.
- Hit the sweet spot; aim at the cross. Do not slice or kick them yet, only flat.
- No shadow swings, taps or tosses between hits that would make a sound near the racket.
- If someone talks or music plays, expect lost shots. Keep it quiet.

End with 3 handle taps, then stop the video and stop the recording.

## Part 2: rally hits (a second, separate recording)
The drop hits above have no incoming ball, so they cannot tell the app's current formula from the "impulse" model in
`tools/wall_speed_fit.py` (ball speed from how much the racket slows at contact): with a still ball the racket's
slowdown is proportional to its speed, and the impulse model's two constants cannot be told apart. To test it the incoming ball must
vary, so do a second recording:
- Hit the wall; let the ball come back off the wall (one floor bounce), and hit it again. Keep the contact point
  within about 0.5 m of your mark so the wall distance holds.
- 30 hits, forehands, effort E M H interleaved as before; mixing short and long returns is good (varied incoming
  speed is the point). Note any hit that was off the mark or a miss.
- Do it as its own recording and its own video (start the recorder and the phone again, with the same 3 handle taps
  at the start and end), so the analysis runs on it separately.

## Collect
- `~/Documents/Recordings/session-….tbrec` (the one that grew).
- The phone video (`.mov`/`.mp4`).
- Your notes: the wall distance, phone distances, effort order, miss numbers.
Keep the raw files until the fit is done, then keep only the CSV result (Mac disk is tight).

## Analyse
Run each recording (drop hits, then rally hits) through the timing script. It also writes the two files that
`tools/wall_speed_fit.py` reads, with the same hit numbering (hit N there is shot N here):
```bash
python3 tools/wall_speed_analyze.py ~/Documents/Recordings/session-….tbrec drill.mov \
    --distance 4.0 --phone-to-contact 1.0 \
    --effort "E M H E M H ... (all shots, in order)" --exclude 7,23 --csv wall_speed.csv \
    --session-csv drill_session.csv --truth-csv drill_truth.csv

python3 tools/wall_speed_fit.py drill_session.csv drill_truth.csv      # add --gyro-scale 0.5 for firmware 1.5
```
Check the timing script first without real data: `python3 tools/wall_speed_analyze.py --selftest`.

Which fit to trust:
- **Drop recording:** the current-formula fit (model A) is the only meaningful one. Its radius is the number to compare with 1.15.
- **Rally recording:** the impulse model (B) can only be judged here. Compare its leave-one-out error with A's, and
  distrust a B whose radius is far from A's or has a huge error bar: that means the two constants are not separable.
- The session CSV holds the raw gyro. The fit's `--gyro-scale` must match what you used here.

## Reading the result
- **Matched shots.** The first line should show nearly every IMU impact paired with a pop. If many are lost, the audio
  was too noisy or too quiet: redo that round.
- **`k` vs 1.633.** The app currently predicts ball speed = 1.633 × |ω_yz|. If your fitted `k` is within about 10% of
  that, the radius is fine. If not, set `effectiveRadiusM = k / 1.42` (more if you correct for drag, below).
- **R².** Above about 0.8 means a single radius is a reasonable model. A low R² or a large intercept means the
  model is structurally off (handle motion, off-centre hits): do not just retune the radius, report it.
- **By effort.** If easy shots fit but hard shots do not, the problem is hard swings (saturation, handle translation).

## Known limits
- Mean speed over the flight is lower than the speed just after contact because of drag, typically 5-10% over 4 m.
  Treat the fitted radius as a slight underestimate. A shorter distance (3 m) lowers this and raises timing error.
- The path length is longer than the wall distance if you hit at an angle. Aim straight at the cross.
- Audio timing assumes the pop and the thud are the two loudest sounds near each hit. Floor bounces are quieter.
- 70 shots from one player tells you the radius for your swing only.
