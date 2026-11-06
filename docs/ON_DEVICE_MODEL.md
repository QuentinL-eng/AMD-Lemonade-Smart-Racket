# On-device model

## Candidate and training recipe

The candidate base is `Qwen/Qwen2.5-1.5B-Instruct`, an Apache-2.0 instruct model whose documented chat template supports tool calls. The training entry point is [tools/train_ondevice.py](../tools/train_ondevice.py). It reads only `data/whatif/conversations_train.jsonl`, applies 4-bit NF4 QLoRA with a configurable rank, and writes a local adapter and a manifest. The default run records its rank, step count, seed, training-data SHA-256, and CUDA hardware in that manifest.

Reproduce the intended run on a CUDA machine with the script's Python dependencies installed:

```bash
python tools/train_ondevice.py --steps 300 --rank 16 --seed 7
```

The candidate's license and documented tool-call template are described by [Qwen's model card](https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct) and [Qwen's function-calling guide](https://qwen.readthedocs.io/en/v2.5/framework/function_call.html). The model card identifies the license as Apache-2.0. This is a candidate recipe, not a completed training result.

## Current status

No fine-tuned checkpoint or training manifest is checked into this repository. I have not completed a training run, measured the fine-tuned model, converted weights for iPhone, or run the model on an iPhone. The current app does not download, checksum, report progress for, or delete model weights. It does not contain an on-device model transport or constrained decoder yet.

The current development host has an NVIDIA GPU, but the Python environment lacks the training packages. Installing the CUDA PyTorch wheel was stopped by pip's package hash verification error. Swift, Xcode, Core ML, and MLX are unavailable on this Windows host. I will not report training settings as completed-run facts or claim iPhone behavior without those runs.

## Required next evidence

Before describing this model as part of the working product, run the recipe, evaluate the same checkpoint on the unchanged validation split, export the same weights for iPhone, and record an on-device replay fixture. The rendered-answer path must be implemented so the model selects tools and wording while Swift substitutes every displayed number from structured tool results. Prompt text alone is not a numeric-grounding guardrail.
