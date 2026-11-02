# Wall speed test

Ground truth for the ball-speed constants (`effectiveRadiusM`, `ImpactModel.impulseGain`), fitted with
`tools/wall_speed_fit.py`. About 30 minutes, one person plus a phone (a helper makes it easier).

**Setup.** A flat, solid wall: hard-court practice wall or a closed garage door. Mark a hitting line 8–10 m from it
and measure the distance from the contact point to the wall with a tape (note it to ±5 cm). Firmware 1.6 or later
(true gyro scale; older sessions need `--gyro-scale 0.5`). Start an app session recording before the first hit.

**Hits.** 3 effort levels (easy / medium / hard) × 15 hits, flat forehands from a self-feed (drop and hit) so the
incoming speed is near zero for some, plus a few off the rebound so it varies. Pause ~2 s between hits so the
detector's 0.6 s refractory never merges two. A missed or framed hit still counts as an impact: note it.

**Timing, video (preferred).** Phone on a tripod side-on, ~5 m away, framing both the contact point and the wall,
240 fps slow-motion. In a frame-stepping player, count frames from contact (ball leaves the strings) to the ball
touching the wall: flight time = frames / 240. One frame is 4 ms, ~1.5 % at 0.3 s.

**Timing, audio (fallback).** Record audio near the hitter; the time between the string "pop" (coincides with the
IMU impact spike) and the wall thud is the flight time, minus sound travel back from the wall (distance / 343 m/s,
~26 ms at 9 m: subtract it).

**Matching.** Detected impacts are numbered 1, 2, 3… in session order. Start each set with one deliberate, filmed bounce hit
straight down as a marker (it is an impact too: note its number); then number video hits in the same order and drop rows for hits the detector missed. The tool prints how many
impacts it found: it must match your count.

**Truth file.** `hit,distance_m,flight_time_s` (or `hit,ball_speed_ms` from a radar). distance/time is the mean
speed over the flight, a few percent below the exit speed (drag), so constants fit slightly low.

**Record also.** Racket (model, string tension), handle hardware version, grip firmness (loose / normal / tight:
grip changes the effective mass), effort level per hit, wall type, indoor/outdoor.

**Safety.** Nobody between hitter and wall or near the rebound line; eye protection for the hitter on hard hits at
short range; check the wall/door can take it and nothing breakable is behind or beside it.

**Run.** `python tools/wall_speed_fit.py session.csv truth.csv` (needs ≥ 8 hits). Try `--demo` first.
