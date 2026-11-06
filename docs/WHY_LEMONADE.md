# How Tennis Buddee uses AMD Lemonade, and what it would lose without it

Everything marked **measured** has a file in this repository. Everything marked **reasoning** is an argument, not a measurement. Limits are stated at the end and are part of the argument.

## How we used Lemonade

| Where | What Lemonade does | Evidence |
|---|---|---|
| iPhone/Mac app | The racket agent sends tool-calling chat requests to a Lemonade server on the player's own network. No Tennis Buddee account is involved. | `apple/Shared/Coach/AgentTransport.swift` (`LemonadeTransport`), [LEMONADE.md](LEMONADE.md) |
| Browser emulator | `tools/emulator-server.mjs` routes the agent to Lemonade on loopback, so a judge can try the whole product with no racket, phone or account. | `node tools/judge-demo.mjs`, [JUDGE_QUICKSTART.md](JUDGE_QUICKSTART.md) |
| Evaluation | `tools/agent_eval.py --preset lemonade` runs the same 243-case scorer used for every other engine. | [LEMONADE_EVAL.md](LEMONADE_EVAL.md) |
| Cheap AMD hardware | The official Lemonade container ran on a 4 GiB RX 580 under Vulkan, with a watchdog that aborts at 75°C or low memory. | [HOMELAB_RX580.md](HOMELAB_RX580.md), `tools/homelab_watch.py` |
| Windows | Installed with one command, `winget install --id AMD.LemonadeServer --exact`, and served `Qwen3-1.7B-GGUF` for the full evaluation. | [LEMONADE.md](LEMONADE.md) |

## What the project would lose without it

1. **One interface for every engine (measured).** Lemonade speaks the OpenAI chat-completions format. The Swift transport, the browser proxy and the evaluator all use that one format, so moving between a hosted model, Lemonade and our own adapter is a base-URL change. The evaluator has four presets (`meta`, `baseten`, `lemonade`, `ondevice`) behind one scorer. Without a local server that speaks the same protocol, the local path would be a second integration to build and keep in sync.

2. **A zero-cost, zero-error measurement loop (measured).** The first Lemonade run covered all 243 validation cases with **0 request errors**. It found a 36.7-point gap to the hosted baseline (51.0% against 87.7%), and that gap is what started the fine-tuning work. Repeated 243-case runs on our own hardware have no per-request charge and no rate limit. That is why we could afford four train-and-evaluate rounds.

3. **A baseline we can open up (measured).** The hosted baseline survives only as one aggregate, 87.7%. Its per-kind report was not kept, so we cannot say why it passes or fails. Every local run keeps the per-case JSON, the tool sequence, the exact answer and the numbers the tool returned, so we found the empty-turn bug in the training data (62 errors to 0) and the target-miss pattern from those logs.

4. **Privacy by construction (design, matches the code).** [PRIVACY.md](PRIVACY.md) states that the agent sends the question and tool results only to the server the player configured. A racket records swing and contact data, and the product's job is to explain it. A local server means that explanation needs no account and no third-party processor.

5. **Reach on hardware people already own (measured, small scale).** The same container loaded a 1.7B model on a 4 GiB RX 580 using about 1.59 GB of VRAM. We did not run an accuracy evaluation there; it was a bounded smoke test. It shows the path works below flagship hardware.

6. **Pinned weights (reasoning).** We publish the SHA-256 of the adapter we evaluated. A hosted endpoint serves whatever weights the provider chooses at the time of the call, so a published score cannot be reproduced later on the same weights.

## Local model against a large hosted model: where each wins

The hosted engine in this project is Muse Spark served by Baseten ([SWING_FILM.md](SWING_FILM.md)). The repository's name for it is a hosted open-weights model, not necessarily a closed one, so this table compares hosted against local rather than closed against open.

| | Large hosted model | Local model through Lemonade |
|---|---|---|
| Accuracy on our 243 cases, untuned | **87.7%** (single retained aggregate) | 51.0% (`Qwen3-1.7B-GGUF`) |
| Accuracy after our fine-tune | not tunable by us | **81.1% on validation, 81.9% on the untouched test split, 0 errors, served by Lemonade** (87.2% on our own Transformers server, which has no tool grammar) |
| Account or sign-in needed | yes, for the hosted path | no |
| Where player data goes | the provider | the server the player chose |
| Works with no internet | no | yes |
| Cost per extra evaluation run | per-token charges (not measured here) | electricity |
| Can the failures be fixed by us | no | yes: the empty-turn bug and target-miss rate were traced to training data and removed |
| Setup effort | an API key | install, pull a model, load it |

The fair reading is **close, not equal**: served by Lemonade, the tuned 1.5B model scores 6.6 points below the hosted baseline's retained aggregate (81.1% against 87.7%) and 30 points above the untuned Lemonade model (51.0%). The test-split result (81.9%) agrees with validation, so the number is not an artifact of repeated tuning. What the local route adds is the ability to find a failure, fix it in the data, retrain for a few dollars, and re-measure. A hosted model offers none of those steps. It also surfaced a Lemonade behaviour worth documenting for other fine-tuners: [LEMONADE_SCHEMA_ORDER.md](LEMONADE_SCHEMA_ORDER.md).

## Limits you should know before relying on this page

- The Lemonade-served numbers use `temperature: 0` (greedy), set by `EVAL_TEMPERATURE=0` in the evaluator. Lemonade's own default sampling scored lower in an earlier run of an older adapter (47.3% against 48.6%, similar), so the choice is small here, but it is a choice.
- Validation was reused across eight training rounds, so 81.1% is somewhat optimistic; the test split, run once on the final model, gave 81.9%, which does not suggest overfitting.
- Training data was filtered with the evaluator's own goal rule, two kinds were repeated once, and tool-call arguments were written alphabetically. All of it is disclosed in [ADAPTER_EVAL.md](ADAPTER_EVAL.md).
- The hosted baseline has no per-kind breakdown, so we cannot compare it kind by kind. It was also measured at a different time and by a different route.
- The RX 580 test was 45 seconds, one request, and is not a benchmark. The Lemonade-served numbers were measured on an RTX 4070 laptop GPU through Lemonade's CUDA llama.cpp backend, not on AMD hardware.
- Remaining failures on the validation split: 40 of 127 `objective` cases and 5 of 18 `player_whatif_extreme` cases.
