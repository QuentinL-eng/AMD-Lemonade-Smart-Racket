# On-device model

## Candidate and training recipe

The candidate base is `Qwen/Qwen2.5-1.5B-Instruct`, an Apache-2.0 instruct model whose documented chat template supports tool calls. The training entry point is [tools/train_ondevice.py](../tools/train_ondevice.py). It reads only `data/whatif/conversations_train.jsonl`, applies 4-bit NF4 QLoRA with a configurable rank, and writes a local adapter and a manifest. The default run records its rank, step count, seed, training-data SHA-256, and CUDA hardware in that manifest.

Reproduce the intended run on a CUDA machine with the script's Python dependencies installed:

```bash
python tools/train_ondevice.py --steps 300 --rank 16 --seed 7
```

The candidate's license and documented tool-call template are described by [Qwen's model card](https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct) and [Qwen's function-calling guide](https://qwen.readthedocs.io/en/v2.5/framework/function_call.html). The model card identifies the license as Apache-2.0. This is a candidate recipe, not a completed training result.

## Current status

No weights are checked into this repository. A one-step QLoRA diagnostic completed and saved an adapter and manifest under the user's cache; it proves training execution only. The full 300-step run completed in 7,885 seconds and saved its adapter and manifest. Full validation completed on the laptop with Transformers/CUDA: 169/243 strict passes (69.5%), 62 response errors, and 12 target failures. This is not an iPhone runtime run. No weights have been converted or run on an iPhone. The app does not yet download, checksum, report progress for, or delete model weights, and has no on-device model transport or constrained decoder.

The Windows training environment now has CUDA PyTorch 2.11.0+cu128, Transformers 5.22.1, PEFT 0.21.2, and bitsandbytes 0.50.2 installed. CUDA recognizes the NVIDIA RTX 4070 Laptop GPU. The first install attempt failed its hash check; the pinned official CUDA wheel subsequently installed successfully with integrity checks enabled. The 300-step, rank-16, seed-7 run produced a completed checkpoint. Its adapter SHA-256 is `6a136595521b188b7c70a918155750ff183366a6e22456d50b7b83fc37966c82`. Swift, Xcode, Core ML, and MLX are unavailable on this host.

The diagnostic completed one optimizer update in 5.26 seconds with gradient accumulation one; its training loss was 1.496. This is not a validation result. The full run uses gradient accumulation eight and checkpoints every 25 steps, retaining two checkpoints. Its output is `C:\Users\qslma\.cache\tennis-buddee-qlora\output\qwen2.5-1.5b`; stdout and stderr logs are in that cache directory as `full-training.log` and `full-training.err`. Reproduce the diagnostic with `python tools/train_ondevice.py --steps 1 --gradient-accumulation 1 --output <diagnostic-directory>`. Resume a saved full-run checkpoint with `--resume <checkpoint-directory>`.

Install the pinned training dependencies with `python -m pip install -r tools/requirements-ondevice.txt`. The loader normalizes OpenAI null content and serialized tool arguments for Qwen's tokenizer, labels assistant messages only, and refuses to truncate conversations. Selective vocabulary logits reduce loss memory; a CPU comparison against the full masked loss produced equal losses within 1e-6. All 1,809 training conversations render successfully, with a maximum length of 4,509 tokens under the 4,608-token training limit. These are loader checks, not fine-tuning results.

## Lemonade-served comparison

The installed Lemonade Server was tested with its catalog model `Qwen3-1.7B-GGUF` (Q4_0). This is a separate untuned model used to measure the Lemonade integration; it is not the Qwen2.5 fine-tuning candidate above and is not an iPhone run. On the fixed 243-case validation sample it scored 124/243 (51.0%) strict all-pass, below the historical hosted baseline of 87.7%. Full global and per-kind tables, including grounded-number and estimate-label rates, are in [docs/LEMONADE_EVAL.md](LEMONADE_EVAL.md).

## Required next evidence

Before describing this model as part of the working product, run the recipe, evaluate the same checkpoint on the unchanged validation split, export the same weights for iPhone, and record an on-device replay fixture. The rendered-answer path must be implemented so the model selects tools and wording while Swift substitutes every displayed number from structured tool results. Prompt text alone is not a numeric-grounding guardrail.


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


## Completed trained-checkpoint validation

See [ADAPTER_EVAL.md](ADAPTER_EVAL.md) for the full comparison, per-kind breakdown, runtime, checksums, reproduction commands, and empty-turn training-data finding. All 181 usable answers passed number grounding, but 62 attempts failed to produce a usable answer. The checkpoint is not ready as a general default agent.
