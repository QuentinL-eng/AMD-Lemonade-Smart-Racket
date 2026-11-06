#!/usr/bin/env python3
"""QLoRA fine-tune the tool-calling racket agent on the player-split train set.

Example:
  python tools/train_ondevice.py --steps 300 --seed 7

Only conversations_train.jsonl is accepted. Validation and test files are never read.
Requires a CUDA workstation with transformers, datasets, peft, bitsandbytes and torch.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
TRAIN = ROOT / "data" / "whatif" / "conversations_train.jsonl"
DEFAULT_MODEL = "Qwen/Qwen2.5-1.5B-Instruct"


def digest(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for block in iter(lambda: f.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", default=DEFAULT_MODEL)
    ap.add_argument("--steps", type=int, default=300)
    ap.add_argument("--seed", type=int, default=7)
    ap.add_argument("--rank", type=int, default=16)
    ap.add_argument("--max-length", type=int, default=4096)
    ap.add_argument("--output", type=Path, default=ROOT / "models" / "ondevice" / "qwen2.5-1.5b")
    args = ap.parse_args()
    if args.steps <= 0 or args.rank <= 0:
        ap.error("--steps and --rank must be positive")
    if not TRAIN.is_file():
        ap.error(f"Training data not found: {TRAIN}")

    import torch
    from datasets import Dataset
    from peft import LoraConfig, get_peft_model, prepare_model_for_kbit_training
    from transformers import (AutoModelForCausalLM, AutoTokenizer, BitsAndBytesConfig,
                              DataCollatorForLanguageModeling, Trainer, TrainingArguments,
                              set_seed)

    if not torch.cuda.is_available():
        ap.error("CUDA is required for this QLoRA recipe")
    set_seed(args.seed)
    raw = [json.loads(line) for line in TRAIN.read_text(encoding="utf-8").splitlines() if line.strip()]
    tokenizer = AutoTokenizer.from_pretrained(args.model, trust_remote_code=False)
    if tokenizer.pad_token is None:
        tokenizer.pad_token = tokenizer.eos_token

    def render(item):
        messages = item["messages"]
        tools = item.get("tools") or []
        text = tokenizer.apply_chat_template(messages, tools=tools, tokenize=False,
                                             add_generation_prompt=False)
        return {"text": text}

    dataset = Dataset.from_list([render(item) for item in raw])

    def tokenize(batch):
        return tokenizer(batch["text"], truncation=True, max_length=args.max_length)

    tokenized = dataset.map(tokenize, batched=True, remove_columns=["text"])
    quantization = BitsAndBytesConfig(load_in_4bit=True, bnb_4bit_quant_type="nf4",
                                      bnb_4bit_use_double_quant=True,
                                      bnb_4bit_compute_dtype=torch.float16)
    model = AutoModelForCausalLM.from_pretrained(
        args.model, quantization_config=quantization, device_map="auto",
        torch_dtype=torch.float16, trust_remote_code=False)
    model.config.use_cache = False
    model = prepare_model_for_kbit_training(model, use_gradient_checkpointing=True)
    lora = LoraConfig(
        r=args.rank, lora_alpha=args.rank * 2, lora_dropout=0.05,
        target_modules=["q_proj", "k_proj", "v_proj", "o_proj", "gate_proj", "up_proj", "down_proj"],
        bias="none", task_type="CAUSAL_LM")
    model = get_peft_model(model, lora)
    args.output.mkdir(parents=True, exist_ok=True)
    training = TrainingArguments(
        output_dir=str(args.output / "trainer"), max_steps=args.steps,
        per_device_train_batch_size=1, gradient_accumulation_steps=8,
        learning_rate=2e-4, fp16=True, gradient_checkpointing=True,
        logging_steps=10, save_steps=args.steps, save_total_limit=1,
        optim="adamw_torch", seed=args.seed, data_seed=args.seed,
        report_to="none", remove_unused_columns=False)
    trainer = Trainer(model=model, args=training, train_dataset=tokenized,
                      data_collator=DataCollatorForLanguageModeling(tokenizer, mlm=False))
    trainer.train()
    model.save_pretrained(args.output / "adapter")
    tokenizer.save_pretrained(args.output / "adapter")
    info = {
        "base_model": args.model,
        "base_license": "Apache-2.0",
        "parameter_count": int(model.get_base_model().num_parameters()),
        "qlora": True,
        "quantization": "4-bit NF4 with double quantization",
        "rank": args.rank,
        "steps": args.steps,
        "seed": args.seed,
        "training_examples": len(raw),
        "training_data": "data/whatif/conversations_train.jsonl",
        "training_data_sha256": digest(TRAIN),
        "hardware": torch.cuda.get_device_name(0),
        "cuda": torch.version.cuda,
        "adapter_path": str((args.output / "adapter").resolve()),
        "validation_or_test_loaded": False,
    }
    (args.output / "training_manifest.json").write_text(json.dumps(info, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(info, indent=2))


if __name__ == "__main__":
    main()
