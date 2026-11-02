# Agent instructions

## Git

- **Push everything to `main`.** Commit straight to `main` and push it. Do not create feature branches or pull
  requests unless the owner asks for one.
- Pull before you start (`git pull origin main`) so you build on the latest work.

## Project

Tennis Buddee: a smart tennis racket (sensor insert in the handle) plus iPhone, Mac, Apple Watch and Meta Ray-Ban
Display apps, with Meta Muse Spark as a tool-calling agent. Start with [`README.md`](README.md) and
[`llms.txt`](llms.txt).

| Area | Where | Check |
|---|---|---|
| Apps, Muse agent, glasses HUD | `apple/` (see `apple/README.md`) | `swift test --package-path apple/RacketKit` |
| Firmware | `firmware/` | `pio run`; host test in `firmware/README.md` |
| Sweet-spot model, what-if data | `ml/` | `python3 ml/test_parity.py` |
| Backend, Muse proxy | `backend/supabase/` | |

## Writing rules

- The hackathon lists "sports analyzers or coaches" as an anti-project. In user-facing text (README, docs, app
  strings, video) call it a smart racket. Muse **predicts** what a change will do. Don't call the product a coach or
  an analyzer.
- Keep README numbers true to the code and run reports. Update `README.md` and `llms.txt` when a headline fact
  changes (hardware, Muse tools, test counts, model results).
