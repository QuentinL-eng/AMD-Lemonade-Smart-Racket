# Tennis Buddee · Lemonade Developer Challenge

Tennis Buddee is a smart racket with a local-first agent experience. The racket measures shots; the app computes shot summaries and physics what-ifs; Lemonade serves the local model. A full 243-case Lemonade evaluation completed on Windows. The native Swift app and iPhone model runtime still need Mac/device verification. A local browser launcher and agent proxy are included with their verification status in the setup guide.

## Community impact

The project helps recreational players connect their own racket data to understandable shot history and physics-based what-ifs. The submission should be easy to reproduce from the repo: [Lemonade setup](docs/LEMONADE.md), [dataset notes](docs/WHATIF_DATASET.md), and the [README](README.md) explain the product and its limits. The Lemonade path is designed to keep inference on the player's local server; sharing sessions with friends remains an explicit account-backed feature.

## Technical depth and quality

The racket-side shot computation and physics simulator remain core. The agent uses registered tools for racket and session facts. The Lemonade integration targets its OpenAI-compatible chat route and local model list, and reports connection state in the app. [The evaluator](tools/agent_eval.py) uses the same validation data and scoring rules for hosted and local endpoints.

| Engine | Validation cases | Strict all-pass | Digest-first | Grounded numbers | Estimate labels |
|---|---:|---:|---:|---:|---:|
| Prior hosted baseline | 243 | 87.7% | Not available | Not available | Not available |
| Lemonade · Qwen3-1.7B-GGUF | 243 | 124 (51.0%) | 239 (98.4%) | 229 (94.2%) | 152/200 (76.0%) |
| Trained Qwen2.5-1.5B · desktop CUDA | 243 | 169 (69.5%) | 181/243 | 181/243 | 179/179 |

Reproduce the baseline when its endpoint and credentials are available:

```bash
python3 tools/agent_eval.py --preset baseten --sample 243 --seed 7
```

Run the local comparison after starting the endpoints and selecting model IDs:

```bash
LEMONADE_BASE_URL=http://localhost:8000/api/v1 LEMONADE_MODEL=<model-id> python3 tools/agent_eval.py --preset lemonade --sample 243 --seed 7
ONDEVICE_BASE_URL=<openai-compatible-local-endpoint> ONDEVICE_MODEL=<checkpoint-id> python3 tools/agent_eval.py --preset ondevice --sample 243 --seed 7
```

The local model is 36.7 percentage points below the historical baseline. It reached 41/123 objective targets, despite a 98.4% digest-first rate and 94.2% grounded-number rate. Full per-kind results and exact scorer are in [docs/LEMONADE_EVAL.md](docs/LEMONADE_EVAL.md). The trained Qwen2.5 checkpoint scored 69.5% in desktop CUDA validation, with 62 response errors. Native iPhone execution is unverified; see [the full adapter report](docs/ADAPTER_EVAL.md).

## Creativity

The smart racket pairs an instrumented handle with a physics simulator: a player can ask what a measured swing change would do and then compare the estimate with later shots. The local model is intended to choose tools and explain results while application code supplies every numeric value.

## Open source and entry requirements

The project is MIT licensed and retains its origin note in the [README](README.md). The [acknowledgements](ACKNOWLEDGEMENTS.md) record earlier model hosting, labeling, and optional wearable integrations. AMD's challenge page says entrants must be members of the AMD AI Developer Program, join its Lemonade Discord channel, and submit through the member form. Confirm membership and current prize availability before submitting; the challenge is advertised as ending when supplies are exhausted. See the [official challenge page](https://www.amd.com/en/developer/resources/technical-articles/2026/join-the-lemonade-developer-challenge.html).


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
