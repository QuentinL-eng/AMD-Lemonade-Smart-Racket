<img src="apple/Shared/Assets.xcassets/AppIcon.appiconset/icon-1024.png" width="120" align="right" alt="Tennis Buddee app icon">

# Tennis Buddee

**A smart tennis racket that feels every shot.** A sensor insert hidden in the handle measures each hit. The racket computes shot summaries and sends them to the player's iPhone, Mac, and Apple Watch. The app keeps session history on the player's devices and can share selected sessions with friends.

Tennis Buddee is being prepared as an entry for the AMD Lemonade Developer Challenge. The current integration work adds Lemonade as a local model server for the racket agent. The physics simulator and tool-calling behavior remain central to the product. Earlier cloud experiments are documented in [Acknowledgements](ACKNOWLEDGEMENTS.md); the challenge story describes the current work accurately.

- **Emulator:** [Tennis Buddee in the browser](https://tennisbuddy.net/emulator)
- **Lemonade setup:** [Install, connect, and troubleshoot](docs/LEMONADE.md)
- **Submission summary:** [SUBMISSION.md](SUBMISSION.md)

## What the smart racket does

- Measures hits from sensors inside the racket handle, without a clip-on device.
- Computes shot data on the racket and syncs session history with the player's Apple devices.
- Runs a physics simulator over the player's own shot data to estimate what a swing change may do.
- Uses a tool-calling agent to select racket and session data, run what-if simulations, and explain the results.
- Lets players share selected session totals with friends through Supabase. Sign-in is not required for local racket use or the local Lemonade agent path.

The simulator reports estimates. The agent is instructed to use tool results for numeric claims. A code-enforced number substitution layer is still required before the small-model path can be treated as verified.

## Lemonade status

The app has a Lemonade transport and connection controls for a local server. The transport targets the configured API base, requests the local model list, and sends OpenAI-compatible chat-completion requests with the registered tool schemas. It is designed to use a server on the same device or a laptop reachable over the local network.

The native app has not been built with Swift in this Windows environment. The full 243-case Python evaluation completed against Lemonade. A local browser replay can be launched with `node tools/emulator-server.mjs`; see [docs/LEMONADE.md](docs/LEMONADE.md) for setup and its verification limits.

## Evaluation

The prior hosted baseline was 87.7% strict all-pass on the sampled validation cases. Reproduce the baseline with access to its endpoint and credentials:

```bash
python3 tools/agent_eval.py --preset baseten --sample 243 --seed 7
```

Run the same scorer against a local Lemonade server after selecting a model:

```bash
LEMONADE_BASE_URL=http://localhost:8000/api/v1 LEMONADE_MODEL=<model-id> python3 tools/agent_eval.py --preset lemonade --sample 243 --seed 7
```

The evaluator writes a JSON report in `data/whatif/`. It reports strict all-pass, digest-first behavior, number grounding, estimate labels, errors, and per-kind scores. The first full local run is recorded in [docs/LEMONADE_EVAL.md](docs/LEMONADE_EVAL.md); it used Qwen3-1.7B-GGUF on an NVIDIA RTX 4070 Laptop GPU. It scored 51.0% strict all-pass against the historical hosted baseline of 87.7%, so the current local model is not an improvement yet. The principal gap was meeting objective targets (41/123 target cases passed).

## Firmware evidence

Raw streaming failed on court: only about 17% of the 1 kHz stream arrived. Firmware 1.6 computes each shot on the racket. The racket sends an 80-byte summary first, then the raw 448-sample window with acks and resends. With no phone nearby, windows go to flash (up to 117) and are sent later, even after a reboot.

The gyro clipped at ±2000 dps. Firmware 1.6 changes the range ST's way and checks the readback. The sweet-spot model's C++ and Python versions agree on all 296 test clips.

These firmware facts are retained from the existing documentation. Commands and firmware details live in [firmware/README.md](firmware/README.md).

## Run and verify

Open the Xcode project to run the apps. No racket is needed to explore recorded sessions.

```bash
swift test --package-path apple/RacketKit
python3 tools/agent_eval.py --preset lemonade --sample 243 --seed 7
python3 tools/agent_eval.py --preset ondevice --sample 243 --seed 7
```

The two evaluator commands require their matching server and model to be configured. They have not been run in this environment. Swift is not installed on the current Windows host, so the Swift command has not been run here.

## Repository map

| Path | Contents |
|---|---|
| [apple/](apple/) | iPhone, Mac, and Watch apps; shared racket tools, simulator, and agent |
| [firmware/](firmware/) | Racket firmware and host-side checks |
| [data/whatif/](data/whatif/) | Generated what-if data; ignored by Git |
| [ml/](ml/) | Shot models, physics mirror, and dataset generation |
| [backend/supabase/](backend/supabase/) | Account and friend-sharing backend; an optional legacy proxy remains |
| [tools/](tools/) | Evaluation, recording, labeling, and model-training scripts |
| [docs/](docs/) | Dataset, hardware, privacy, and setup documentation |
| [TennisRobot/](TennisRobot/) | Camera and arm rig for repeatable ground-truth work |

## Privacy and sharing

Shot history stays on the player's devices and private iCloud until the player chooses to share session totals with a friend. When the player selects a Lemonade server, the agent sends the question and the tool inputs needed for that answer to that server. The local path does not require a Tennis Buddee sign-in.

## License

MIT. See [LICENSE](LICENSE). The idea started from the MIT-licensed [Smart-Tennis-Racket repository](https://github.com/AahanPrajapati/Smart-Tennis-Racket).


### Measured Lemonade validation breakdown

| Validation kind | Strict all-pass | Digest-first | Grounded numbers | Estimate labels |
|---|---:|---:|---:|---:|
| objective | 31/127 | 127/127 | 117/127 | 68/98 |
| player_whatif | 48/57 | 57/57 | 56/57 | 48/56 |
| player_whatif_extreme | 11/18 | 14/18 | 18/18 | 12/18 |
| unmodeled | 20/25 | 25/25 | 23/25 | 17/20 |
| contact_spread | 12/14 | 14/14 | 13/14 | 7/8 |
| no_motion | 1/1 | 1/1 | 1/1 | n/a |
| player_whatif_error | 1/1 | 1/1 | 1/1 | n/a |
