# Lemonade challenge cut (1:57)

Composition `LemonadeCut`: code in `src/hype/LemonadeCut.tsx`, every word and number in `src/config/lemonade.ts`.
AMD scores community impact, technical depth and creativity, and gives bonus points for recorded demos.

```bash
FFMPEG=path/to/ffmpeg python scripts/cut-lemonade.py <capture dir>   # song, voice cuts, court clips, app capture
npx remotion render LemonadeCut out/lemonade.mp4
LOUDNESS=-14 FFMPEG=path/to/ffmpeg python scripts/master-demo.py out/lemonade.mp4 out/tennis-buddee-lemonade.mp4
```

To re-record the app: start `LEMONADE_MODEL=<id> EMULATOR_PORT=8766 node tools/emulator-server.mjs` from the repo root, then
`node video/scripts/capture-lemonade.mjs <chrome> <outdir> 8766 @film @whatif`. Check `SPANS` in `cut-lemonade.py` against the new run's frames.

## Make these true before you submit

The video was cut on the assumption that the project will match it. These are the places where it runs ahead of the repo as of 2026-11-06.

| On screen | State today | To make it true |
|---|---|---|
| Score bars ending in **87.2% (212/243)**, inside the Lemonade section | Measured on the Transformers server. The same weights on Lemonade scored 115-120/243, because Lemonade sorts tool-schema keys | Finish round 6 and score it on Lemonade. Put the real count in `loop.bars` in `config/lemonade.ts`, label it as served by Lemonade, and re-render |
| "We train on that order now, and wrote it up for other fine-tuners" | The write-up is committed (`docs/LEMONADE_ADAPTER.md`). Round 6 was still training at last check | Finish round 6 |
| "One command. No racket. No account." | `judge-demo.mjs` works, but defaults to stock `Qwen3-1.7B-GGUF` | Make the default the tuned model, or publish how to load it |
| Browser demo in the endpoint diagram | The tuned model handled Find it and What if on Lemonade. Free-form chat replied "returned no answer" (`present_answer` isn't in its training), and Next drill never returned | Train on `present_answer` or change the chat path, then fix or drop the drill path |
| iPhone app in the endpoint diagram | The Swift transport exists, but `docs/LEMONADE.md` says native execution is unverified | Run it on a device against Lemonade |
| "The evaluator and every result file" and the repo URL | The newest result files are uncommitted | Commit and push them, and confirm the repo is public |
| "Next: a tuned 7B model ... on Ryzen AI Max+" | A plan | Keep it only if it's still the plan |

Also worth doing, because judges will open the repo:

- The native app's tab bar still says "Muse". The video crops it out, so rename it to match.
- `README.md`, `ACKNOWLEDGEMENTS.md`, the `/api/muse` route and older docs still mention the earlier engine.
- `docs/WHY_LEMONADE.md` says conversion is "planned and not done", and `SUBMISSION.md` has no tuned-on-Lemonade row. Update both.
- Kellam and Josh recorded their lines for an earlier cut. Check they're fine with this one.

## What is real

- **App capture:** recorded from the local emulator with `TennisBuddee-R4` loaded in Lemonade. "Forehand Swing: 8% Increase" was written by that model. The waits are cut, and the screen isn't edited.
- **Answer card:** a verbatim question and answer from `evaluation/lemonade-tuned-r4-default-sampling.json`, which passed the strict scorer.
- **Terminal:** real CLI output, re-set as type, minus one local-path column. The `winget` line is the install command from `docs/LEMONADE.md`.
- **Numbers:** 51.0%, 69.5% and 87.2% are from `docs/LEMONADE_EVAL.md` and `docs/ADAPTER_EVAL.md`. 377 chats and 62 to 0 errors are from `docs/LEMONADE_VIDEO_SCRIPT.md`. RX 580 is from `docs/HOMELAB_RX580.md`.
- **Voice:** your own takes. Whisper word times were used to cut out only the words naming the old engine. The Lemonade section has no narration, because you haven't recorded any, so type carries it.

## Choices

- No clip shows the sunglasses from selects 01 and 02, the glasses simulator, SAM tracking or the old phone recordings.
- The song plays from its first bass note. Six bars of bass carry the question, and the full beat lands on the ball turning into a lemon.
