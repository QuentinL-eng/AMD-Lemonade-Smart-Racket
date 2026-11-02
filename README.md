<img src="apple/Shared/Assets.xcassets/AppIcon.appiconset/icon-1024.png" width="120" align="right" alt="Tennis Buddee app icon">

# 🎾 Tennis Buddee

**A smart tennis racket that feels every shot.** A sensor insert hidden in the handle measures each hit: swing speed,
ball speed, spin, face angle, stroke type and where the ball met the strings. The racket computes the shot itself
and sends it to an iPhone, Mac, Apple Watch and **Meta Ray-Ban Display** glasses. **Meta Muse Spark** works as a
tool-calling agent over the player's own shot data: it runs a physics simulator to predict what a change to the swing
would do, then plans a drill that the Watch tracks.

- **Website:** [tennisbuddy.net](https://tennisbuddy.net)
- **Try the app:** [TestFlight public beta](https://testflight.apple.com/join/137F7kvd) (iPhone + Apple Watch). It
  starts on a built-in simulated racket, so every screen works without the hardware.
- **Built for:** the Meta Global AI Developer Hackathon. All 89 commits in this repo date from Oct 26 to Nov 2, 2026.

## The problem

A club player hits hundreds of shots a night and can't tell which ones were good. Sensors that clip onto a racket
cost money, change its feel and report a few numbers. Video needs someone filming. Tennis Buddee fits inside the
racket's own handle, keeps its feel, and turns every hit into data the player can act on the same night.

## How Meta AI is used

| Meta technology | What it does here | Code |
|---|---|---|
| **Muse Spark** (`muse-spark-1.3`, native function calling) | An agent with 10 tools over the player's data. It fetches shots, compares sessions, reads live sensors and racket status, keeps long-term player notes, and calls `simulate_change` to **predict** the effect of a swing change before the player tries it. | [`apple/Shared/Coach/`](apple/Shared/Coach/), [`CoachTools.swift`](apple/Shared/Coach/CoachTools.swift) |
| **Muse Spark via a server proxy** | A Supabase edge function holds the Meta API key, so the app never ships a key. Bounded loop: at most 5 requests and 8 tool calls per answer, 45 s timeout, instant fallback on HTTP 429. | [`backend/supabase/functions/muse/`](backend/supabase/functions/muse/index.ts) |
| **Meta Wearables Device Access Toolkit** (`MWDATCore`, `MWDATDisplay`) | Mirrors the live session to **Meta Ray-Ban Display**: latest shot, sweet-spot rate, score and drill progress, on the lens, mid-rally. | [`apple/iOS/Glasses/`](apple/iOS/Glasses/) |
| **Synthetic tool-use dataset for Muse** | 400 simulated players whose tool results match the app exactly (Python mirror of the Swift simulator, checked by tests). Teaches the "test a change, don't just describe it" pattern. | [`ml/whatif_synth.py`](ml/whatif_synth.py), [`docs/WHATIF_DATASET.md`](docs/WHATIF_DATASET.md) |

If Muse is off, signed out or rate-limited, a deterministic built-in engine answers, and the UI names the engine that
answered. Muse never receives Health data or session notes unless the player allows notes.

## What it does

1. **Hit a ball.** The racket detects the impact on board and computes the full shot in firmware
   ([`firmware/src/shot.cpp`](firmware/src/shot.cpp), a C++ port of the app's Swift `ShotAnalyzer`).
2. **See it at once.** A shot card on the phone, a tap on the Watch (crisp = sweet spot, double buzz = mishit), and
   the numbers on the glasses.
3. **Keep score by tapping the handle.** A tiny classifier on the racket tells which side of the handle was tapped
   ([`firmware/src/tap_classify.cpp`](firmware/src/tap_classify.cpp)), so a double-tap scores the point.
4. **Ask "what if?"** Drag sliders for swing speed, face, path and contact on your average stroke, or ask Muse.
   Muse calls the simulator, reports the predicted ball speed and spin, and plans a drill.
5. **Do the drill.** The Watch counts it down and logs it.
6. **Play together.** Accounts, friends, shared scores and session summaries (Supabase, Sign in with Apple, Google).

## Architecture

```
┌──────────── Racket handle ────────────┐        BLE         ┌──────── iPhone / Mac app (SwiftUI) ────────┐
│ LSM6DSV320X: gyro ±4000 dps,          │  hit → shot summary │ RacketKit: decode, orientation, analysis   │
│   accel ±16 g and ±320 g, 1 kHz       │  → 448 ms window   │ SwiftData + iCloud sync                    │
│ INMP441 mic → sweet-spot model        │  (acked, resent,   │ Muse Spark agent ──► Supabase edge fn ──► Meta API
│ ESP32-C3: impact detect, shot physics,│   flash backlog)   │ What-if simulator (ShotSimulator)          │
│   tap scoring, OTA update             │ ─────────────────► │                                            │
└───────────────────────────────────────┘                    └───────┬──────────────────────┬─────────────┘
                                                                     │ WatchConnectivity    │ Meta Wearables DAT
                                                              Apple Watch: haptics,   Meta Ray-Ban Display:
                                                              workout, drills, score  live HUD
```

- **On-racket computing.** Raw streaming delivered only about 17% of samples on a real court
  ([`docs/CLUB_2026-10-28.md`](docs/CLUB_2026-10-28.md)). So firmware 1.6 computes each shot on the racket, sends an
  80-byte summary first, then the raw 448-sample window with acks and resends. With no phone nearby, windows are kept
  in flash (117 windows) and sent later, across reboots.
- **One analysis, two languages.** The firmware's C++ shot analyzer and the app's Swift one are checked against each
  other by `ShotParityTests`.
- **Simulator first.** A simulated racket and a record/replay system let every screen be built and tested without
  hardware.

## Evidence and honest numbers

| Check | Result | Source |
|---|---|---|
| Swift tests (RacketKit + app) | 76 tests: shot parity C++ ↔ Swift, labeled real sessions, replay, scoring, simulator, Muse agent with mocked HTTP | [`apple/RacketKit/Tests/`](apple/RacketKit/Tests/), [`apple/Tests/`](apple/Tests/) |
| Python tests (ML, tools, robot) | 50 tests | `ml/test_*.py`, `tools/test_*.py`, `TennisRobot/tests/` |
| Firmware host test | Flash backlog against a fake flash; passes under ASan/UBSan | [`firmware/tools/backlog_test`](firmware/tools/backlog_test) |
| Firmware ↔ Python ML parity | Identical decisions on all 274 real clips + 22 synthetic; max distance error 7e-7 cm | `ml/test_parity.py` |
| Sweet-spot model on real hits | 67.2% accuracy (baseline 60.6%), 1.83 cm mean distance error, 274 labeled clips, grouped 5-fold | [`ml/runs/SUMMARY-20261028.md`](ml/runs/SUMMARY-20261028.md) |
| Real court session | 15 recordings, 86 min at a club; findings drove the move to on-racket shot computing | [`docs/CLUB_2026-10-28.md`](docs/CLUB_2026-10-28.md) |

We report the weak results too. The sweet-spot model only modestly beats the baseline, and the summary explains why
(label scale between sessions) and what comes next.

## Who it is for and where it goes

Club and high-school players who want the data that pros get without a camera crew.
The insert is built from off-the-shelf parts (ESP32-C3, LSM6DSV320X, INMP441, 1S LiPo) in a 3D-printed core that
replaces the handle's foam, so it can fit many rackets. Next steps: more labeled sessions, a "close to sweet spot"
state, and a robot-arm test rig for repeatable ground truth ([`TennisRobot/`](TennisRobot/), [`robot/`](robot/)).

## Run it

```bash
# Apps: open in Xcode and run TennisBuddy-iOS or TennisBuddy-macOS (no racket needed: Simulator source)
open apple/TennisBuddy.xcodeproj

# Tests
swift test --package-path apple/RacketKit
python3 ml/test_parity.py
python3 -m unittest discover -s ml -p test_whatif_synth.py

# Firmware (Seeed XIAO ESP32C3)
cd firmware && pio run -t upload && pio device monitor
```

Details: [`apple/README.md`](apple/README.md), [`firmware/README.md`](firmware/README.md),
[`docs/WIRING.md`](docs/WIRING.md), [`backend/supabase/README.md`](backend/supabase/README.md).

## Repository map

| Folder | Contents |
|---|---|
| [`apple/`](apple/) | Xcode project: iPhone + Mac app, Watch app, Ray-Ban Display HUD, Muse Spark agent, shared `RacketKit` Swift package |
| [`firmware/`](firmware/) | PlatformIO firmware for the XIAO ESP32C3: impact detection, on-racket shot analysis, tap scoring, mic model, BLE protocol, OTA |
| [`ml/`](ml/) | Sweet-spot audio model (trainer, firmware export, parity tests), Muse what-if dataset generator, model run reports |
| [`backend/`](backend/) | Supabase schema (accounts, friends, shared sessions) and the `muse` edge function |
| [`tools/`](tools/) | Python scripts for recording, labeling and checking sessions |
| [`data/`](data/) | Small calibration and tap recordings (large raw sessions stay local) |
| [`TennisRobot/`](TennisRobot/), [`robot/`](robot/) | Camera + Epson C8 arm rig to swing the racket repeatably for ground truth (framework, simulated) |
| [`video/`](video/) | Remotion source for the 3-minute demo video |
| [`website/`](website/) | [tennisbuddy.net](https://tennisbuddy.net) |
| [`docs/`](docs/) | Wiring, data collection, club session report, privacy, TestFlight, original build plan |

## Privacy

Shot data stays on the player's devices and private iCloud. Shared scores and summaries go to our Supabase
backend only when the player shares them. Only what Muse fetches for an answer goes to Meta, through our proxy. See [`docs/PRIVACY.md`](docs/PRIVACY.md).

## License

MIT. See [`LICENSE`](LICENSE). Started from the idea in
[AahanPrajapati/Smart-Tennis-Racket](https://github.com/AahanPrajapati/Smart-Tennis-Racket) (MIT).
