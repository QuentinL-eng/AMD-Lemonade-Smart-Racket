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
| Accuracy after our fine-tune | not tunable by us | 87.2% (round 4, 0 errors; Transformers/CUDA, not yet served by Lemonade) |
| Account or sign-in needed | yes, for the hosted path | no |
| Where player data goes | the provider | the server the player chose |
| Works with no internet | no | yes |
| Cost per extra evaluation run | per-token charges (not measured here) | electricity |
| Can the failures be fixed by us | no | yes: the empty-turn bug and target-miss rate were traced to training data and removed |
| Setup effort | an API key | install, pull a model, load it |

The fair reading is **parity, not victory**: after fine-tuning, the 1.5B local model scores 0.5 points below the hosted baseline's retained aggregate. What the local route adds is the ability to find a failure, fix it in the data, retrain for a few dollars, and re-measure. A hosted model offers none of those steps.

## Limits you should know before relying on this page

- The fine-tuned adapter was **served with our own Transformers server** (`tools/serve_adapter.py`), not through Lemonade. Lemonade ran the untuned model. Converting the adapter to a GGUF that Lemonade can load is planned and not done, so no number here is "our tuned model on Lemonade".
- 87.2% was chosen across rounds by looking at the same validation cases, so it is optimistic. The untouched test split has not been scored.
- The hosted baseline has no per-kind breakdown, so we cannot compare it kind by kind.
- Training data was filtered with the evaluator's own goal rule, which is disclosed in [ADAPTER_EVAL.md](ADAPTER_EVAL.md).
- The RX 580 test was 45 seconds, one request, and is not a benchmark.
