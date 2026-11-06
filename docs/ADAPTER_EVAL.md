# Step-300 adapter validation

The complete 243-case validation run scored **169/243 strict passes (69.5%)**, counting every response error as a failure. No RX 580 or homelab inference was used. The checkpoint ran on the laptop's NVIDIA RTX 4070 through Transformers/CUDA with the trained PEFT adapter and NF4 base. This is desktop validation of the trained weights, not an iPhone, MLX, Core ML, or GGUF runtime result.

| Engine | Cases | Strict all-pass | Response errors |
|---|---:|---:|---:|
| Historical hosted baseline | 243 | 87.7% | Not available |
| Lemonade · untuned Qwen3-1.7B-GGUF | 243 | 124 (51.0%) | 0 |
| Trained Qwen2.5-1.5B · desktop CUDA | 243 | 169 (69.5%) | 62 |

The trained checkpoint scored 18.5 percentage points above the Qwen3 run and 18.2 points below the historical baseline. These models and inference runtimes differ, so this is not a controlled measurement of the benefit of fine-tuning. A matched untuned Qwen2.5/NF4 control has not been evaluated.

## Separate checks

- Usable answers: 181/243. The other 62 cases failed with HTTP 502 from the adapter server. Observed server diagnostics repeatedly showed empty generated answers.
- Digest-first: 181/181 usable answers, or 181/243 across all attempted cases.
- Grounded numbers: 181/181 usable answers, or 181/243 across all attempted cases. This does not mean every attempted case received a grounded answer.
- Estimate labels: 179/179 completed cases with a simulation tool call.
- Target reached: 63/75 completed cases with a defined target. Twelve completed answers failed the target check. The objective kind's full strict result, including errors, is 67/127.

| Validation kind | Strict all-pass | Digest-first | Grounded numbers | Estimate labels | Response errors |
|---|---:|---:|---:|---:|---:|
| objective | 67/127 | 79/127 | 79/127 | 79/79 | 48 |
| player_whatif | 57/57 | 57/57 | 57/57 | 57/57 | 0 |
| player_whatif_extreme | 18/18 | 18/18 | 18/18 | 18/18 | 0 |
| unmodeled | 25/25 | 25/25 | 25/25 | 25/25 | 0 |
| contact_spread | 0/14 | 0/14 | 0/14 | n/a | 14 |
| no_motion | 1/1 | 1/1 | 1/1 | n/a | 0 |
| player_whatif_error | 1/1 | 1/1 | 1/1 | n/a | 0 |

These are synthetic, player-split validation cases; they do not establish real-world sensor accuracy or tennis improvement. The checkpoint is strong on the sampled direct what-if cases, but is not ready as a general default agent: every contact-spread case failed, and many objective cases produced no usable response.

## Method and artifacts

The scorer and sample selection are unchanged: `--sample 243 --seed 7`. The restored fixture was checked against the original validation bytes and every validation player's complete session catalog. Training and validation player sets have zero overlap. No training, validation, or test files were modified.

- [Full per-case report](../evaluation/adapter-step300-validation.json)
- [Training metadata and adapter checksum](../evaluation/training-step300.json)
- Adapter SHA-256: `6a136595521b188b7c70a918155750ff183366a6e22456d50b7b83fc37966c82`
- Validation SHA-256: `713138899ea62040c6949960317b6eba2dec02f144051f5f187a6639455d446c`
- Rank 16, 300 steps, seed 7, gradient accumulation 8; 1,809 train conversations.
- Inference: greedy decoding, NF4 with double quantization, float16 compute, 4,096 maximum completion tokens, 75-second per-generation limit. Empty, malformed, and incomplete responses fail; the server does not repair tool calls or supply fallback answers.

Reproduce in the CUDA environment from `tools/requirements-ondevice.txt`, with the saved adapter directory:

```bash
python tools/serve_adapter.py --adapter <adapter-directory>
```

In another terminal, set `ONDEVICE_MODEL=tennis-buddee-qwen2.5-1.5b-step300` and run:

```bash
python tools/prepare_eval_fixture.py
python tools/agent_eval.py --preset ondevice --data-dir data/whatif-val --sample 243 --seed 7
```

The server binds only `127.0.0.1:8001`. The evaluator writes `data/whatif/eval_ondevice_s243.json`. The weights remain outside Git; they must be supplied separately. Two protocol smoke runs preceded the final complete run; no cases were selectively retried to improve this score. The laptop validation server was stopped after completion to release GPU memory.

## Finding for the next training run

An audit found 377 training conversations with an empty intermediate assistant turn (all in the objective kind); none of those empty turns was the final answer. The current loader normalized and supervised them, teaching an end-of-turn token with no content at those positions. This may contribute to empty-answer failures, but causation has not been proven. The next recipe should remove empty intermediate assistant turns in preprocessing, retain every original conversation and all measurement files, and be evaluated again before claiming an improvement. No second training run was started as part of this validation.
