# Tennis Buddee · Lemonade Developer Challenge

Tennis Buddee is a smart racket with a local-first agent experience. The racket measures shots; the app computes shot summaries and physics what-ifs; Lemonade is the local model-serving path being integrated for the challenge. The server transport and connection UI are implemented in source but have not been built or run here. No end-to-end Lemonade evaluation or iPhone model run has been verified.

## Community impact

The project helps recreational players connect their own racket data to understandable shot history and physics-based what-ifs. The submission should be easy to reproduce from the repo: [Lemonade setup](docs/LEMONADE.md), [dataset notes](docs/WHATIF_DATASET.md), and the [README](README.md) explain the product and its limits. The Lemonade path is designed to keep inference on the player's local server; sharing sessions with friends remains an explicit account-backed feature.

## Technical depth and quality

The racket-side shot computation and physics simulator remain core. The agent uses registered tools for racket and session facts. The Lemonade integration targets its OpenAI-compatible chat route and local model list, and reports connection state in the app. [The evaluator](tools/agent_eval.py) uses the same validation data and scoring rules for hosted and local endpoints.

| Engine | Validation cases | Strict all-pass | Digest-first | Grounded numbers | Estimate labels |
|---|---:|---:|---:|---:|---:|
| Prior hosted baseline | 243 | 87.7% | See generated report | See generated report | See generated report |
| Lemonade | Not run | Not measured | Not measured | Not measured | Not measured |
| Fine-tuned on-device model | Not trained | Not measured | Not measured | Not measured | Not measured |

Reproduce the baseline when its endpoint and credentials are available:

```bash
python3 tools/agent_eval.py --preset baseten --sample 243 --seed 7
```

Run the local comparison after starting the endpoints and selecting model IDs:

```bash
LEMONADE_BASE_URL=http://localhost:8000/api/v1 LEMONADE_MODEL=<model-id> python3 tools/agent_eval.py --preset lemonade --sample 243 --seed 7
ONDEVICE_BASE_URL=<openai-compatible-local-endpoint> ONDEVICE_MODEL=<checkpoint-id> python3 tools/agent_eval.py --preset ondevice --sample 243 --seed 7
```

The baseline is stronger evidence than an unmeasured local result; do not treat the blank local rows as wins. The complete score table will be updated only after the exact commands above produce reports.

## Creativity

The smart racket pairs an instrumented handle with a physics simulator: a player can ask what a measured swing change would do and then compare the estimate with later shots. The local model is intended to choose tools and explain results while application code supplies every numeric value.

## Open source and entry requirements

The project is MIT licensed and retains its origin note in the [README](README.md). The [acknowledgements](ACKNOWLEDGEMENTS.md) record earlier model hosting, labeling, and optional wearable integrations. AMD's challenge page says entrants must be members of the AMD AI Developer Program, join its Lemonade Discord channel, and submit through the member form. Confirm membership and current prize availability before submitting; the challenge is advertised as ending when supplies are exhausted. See the [official challenge page](https://www.amd.com/en/developer/resources/technical-articles/2026/join-the-lemonade-developer-challenge.html).
