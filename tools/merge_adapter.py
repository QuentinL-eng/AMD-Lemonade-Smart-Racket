#!/usr/bin/env python3
"""Merge a QLoRA adapter into its fp16 base so llama.cpp / Lemonade can serve it.

  python tools/merge_adapter.py --adapter <adapter-dir> --output <merged-dir>

Then convert and quantize (see docs/LEMONADE_ADAPTER.md):
  python convert_hf_to_gguf.py <merged-dir> --outtype f16 --outfile model-f16.gguf
  llama-quantize model-f16.gguf model-Q8_0.gguf Q8_0

The adapter was trained against a 4-bit NF4 copy of the base, and this merges into the
fp16 weights, so the merged model is close to but not bit-identical to what was
evaluated through tools/serve_adapter.py. Re-run the evaluation on the merged model.
"""
import argparse
from pathlib import Path

import torch
from peft import PeftModel
from transformers import AutoModelForCausalLM, AutoTokenizer

ap = argparse.ArgumentParser()
ap.add_argument("--adapter", type=Path, required=True)
ap.add_argument("--output", type=Path, required=True)
ap.add_argument("--base", default="Qwen/Qwen2.5-1.5B-Instruct")
a = ap.parse_args()

base = AutoModelForCausalLM.from_pretrained(a.base, torch_dtype=torch.float16)
merged = PeftModel.from_pretrained(base, str(a.adapter)).merge_and_unload()
a.output.mkdir(parents=True, exist_ok=True)
merged.save_pretrained(a.output, safe_serialization=True)
AutoTokenizer.from_pretrained(str(a.adapter)).save_pretrained(a.output)
print("merged ->", a.output)
