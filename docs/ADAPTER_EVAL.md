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

## Round 2: empty-turn fix (300 steps, same recipe)

After dropping the 377 empty intermediate assistant turns in preprocessing (`tools/train_ondevice.py`, tested in `tools/test_train_preprocessing.py`), the same recipe (rank 16, 300 steps, seed 7, 1,809 conversations) was retrained on a Modal A100-40GB and validated on the laptop RTX 4070 with the same server, scorer, and `--sample 243 --seed 7`. Training took about 29 minutes. Weights SHA-256 begins `5272f518`; see [training manifest](../evaluation/training-noempty-step300.json) and [full report](../evaluation/adapter-noempty-step300-validation.json).

| Engine | Strict all-pass (errors count as failures) | Response errors |
|---|---:|---:|
| Round 1: step-300 adapter (empty turns in training) | 169/243 (69.5%) | 62 |
| Round 2: empty turns dropped, 300 steps | **204/243 (84.0%)** | **0** |

All 62 response errors disappeared, and contact-spread went from 0/14 to 14/14. This supports the empty-turn explanation, though it was one change measured once. The 39 remaining failures: 30 objective cases whose chosen change misses the goal (17 of 48 `cleaner_contact`, 13 of 43 `more_spin`; `more_pace` and `fix_slice` had none), and 9 cases with an ungrounded number in the answer. For example, a model asked to center contact 3.2 cm off-center moved it only 1.7 cm. Next: more training steps, since this run covered 1.32 epochs. Because the validation set is used to choose between rounds, later rounds are tuned on it; the untouched test split should be run once at the end.

## Round 3: same data, 700 steps

Only the step count changed (700 steps, about 3.1 epochs; Modal assigned an A100-80GB this time). Weights SHA-256 begins `89c49595`; see [report](../evaluation/adapter-noempty-step700-validation.json) and [manifest](../evaluation/training-noempty-step700.json).

| Engine | Strict all-pass | Response errors |
|---|---:|---:|
| Round 2: 300 steps | 204/243 (84.0%) | 0 |
| Round 3: 700 steps | **207/243 (85.2%)** | 0 |

More training barely helped (+3 cases). The same two objectives fail: 21 of 48 `cleaner_contact` and 14 of 43 `more_spin`, plus 6 ungrounded numbers.

**Cause found in the training data.** Scoring the final `simulate_change` result of each training conversation with the evaluator's own rule (`reaches_target`) shows that 113 of 436 `cleaner_contact` and 74 of 338 `more_spin` training conversations end on a change that does not reach the goal, and 24 goal conversations run no simulation at all. The model's miss rate matches the data it imitated.

**Round 4 (in progress when this was written):** train on a target-conditioned copy of the training split made by `tools/filter_train_by_target.py` (drops 211 of 1,809 conversations: 125 `cleaner_contact`, 80 `more_spin`, 6 `more_pace`; `fix_slice` is left alone because only 1 of 61 of its training conversations reaches its goal under this rule). It reads only the training file. This is rejection sampling on the training data using the evaluator's rule, so it must be disclosed with any resulting score. Validation and test data are not used to build it. Rounds 2 to 4 were all chosen by looking at the same 243 validation cases.

## Round 4: target-conditioned training data, 400 steps

Trained on `conversations_train_target.jsonl` (1,598 of the 1,809 training conversations; built by `tools/filter_train_by_target.py`, which keeps goal conversations only when their last simulation reaches the goal under the evaluator's rule; `fix_slice` untouched). 400 steps, same seed and settings, Modal A100-40GB. Weights SHA-256 begins `33bf5786`; training-file SHA-256 `2293a5ec...`. See [report](../evaluation/adapter-target400-validation.json) and [manifest](../evaluation/training-target400.json).

| Round | Training data | Steps | Strict all-pass | Response errors |
|---|---|---:|---:|---:|
| 1 | full, empty turns kept | 300 | 169/243 (69.5%) | 62 |
| 2 | full, empty turns dropped | 300 | 204/243 (84.0%) | 0 |
| 3 | full, empty turns dropped | 700 | 207/243 (85.2%) | 0 |
| 4 | target-filtered, empty turns dropped | 400 | **212/243 (87.2%)** | 0 |

The 90% goal was **not reached**. Remaining 31 failures, all `objective`: 12 `more_spin` and 11 `cleaner_contact` answers that miss the goal (down from 29 target misses in round 3), and 8 `cleaner_contact` answers quoting a number that is not in any tool result (up from 6). Filtering helped on target misses but did not remove them, and the grounded-number failures are now the clearest next lever. Four rounds were chosen by looking at the same 243 validation cases, so 87.2% is somewhat optimistic; the untouched test split has not been run. Ideas not yet tried: also filter ungrounded-number answers out of the training data, add training examples that copy the tool's exact offset into the move, a larger LoRA rank, or a larger base model.
