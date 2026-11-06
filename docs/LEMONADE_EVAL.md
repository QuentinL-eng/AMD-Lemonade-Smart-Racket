# Lemonade evaluation record

Run on November 5, 2026 against the project’s 243-case, player-split validation sample (`--seed 7`) using the unchanged evaluator and strict scorer. Lemonade Server 2026.45.3 served `Qwen3-1.7B-GGUF` (Q4_0, listed as tool-calling) on an NVIDIA GeForce RTX 4070 Laptop GPU. Requests used `enable_thinking: false` so Qwen3 could emit tools within its response budget. This is a Lemonade-served base model, **not** the proposed fine-tuned iPhone model.

Reproduce with:

```powershell
$env:LEMONADE_MODEL = "Qwen3-1.7B-GGUF"
python tools/agent_eval.py --preset lemonade --sample 243 --seed 7
```

The evaluator writes the per-case JSON report to the ignored `data/whatif/eval_lemonade_s243.json`. The summary below is retained here so the measured result is visible in the repository.

| Engine | Cases | Strict all-pass | Digest-first | Grounded numbers | Estimate labels | Target reached | Request errors |
|---|---:|---:|---:|---:|---:|---:|---:|
| Historical hosted baseline | 243 | 87.7% | Not available | Not available | Not available | Not available | Not available |
| Lemonade · Qwen3-1.7B-GGUF | 243 | 124 (51.0%) | 239 (98.4%) | 229 (94.2%) | 152/200 (76.0%) | 41/123 (33.3%) | 0 |
| Trained Qwen2.5-1.5B · desktop CUDA | 243 | 169 (69.5%) | 181/243 | 181/243 | 179/179 | 63/75 | 62 |

The historical baseline’s only retained aggregate is 87.7%; its per-kind report was not available during this run. The Lemonade result is 36.7 percentage points below that baseline. Tool calls and grounded numbers are generally strong; the dominant failure is whether an objective is actually reached, plus a smaller set of ungrounded-number and estimate-label failures. Do not present this result as an improvement over the hosted baseline.

| Validation kind | Strict all-pass | Digest-first | Grounded numbers | Estimate labels |
|---|---:|---:|---:|---:|
| objective | 31/127 | 127/127 | 117/127 | 68/98 |
| player_whatif | 48/57 | 57/57 | 56/57 | 48/56 |
| player_whatif_extreme | 11/18 | 14/18 | 18/18 | 12/18 |
| unmodeled | 20/25 | 25/25 | 23/25 | 17/20 |
| contact_spread | 12/14 | 14/14 | 13/14 | 7/8 |
| no_motion | 1/1 | 1/1 | 1/1 | n/a |
| player_whatif_error | 1/1 | 1/1 | 1/1 | n/a |

Target reached was 41/123 for cases with a defined target. Overall strict all-pass requires digest-first behavior, grounded numbers, estimate labels for simulations, known tools, and any applicable target to pass. See [`tools/agent_eval.py`](../tools/agent_eval.py) for the exact scorer. No validation or test data was modified.

The trained checkpoint comparison is documented in [ADAPTER_EVAL.md](ADAPTER_EVAL.md); it used a different base model and Transformers/CUDA runtime. Conditional metric denominators exclude failed requests; strict all-pass includes all attempts.
