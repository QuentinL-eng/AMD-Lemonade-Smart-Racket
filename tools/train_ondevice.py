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


def template_messages(messages):
    """Convert OpenAI wire messages to the tokenizer's structured tool format."""
    result = []
    for original in messages:
        message = {**original, "content": original.get("content") or ""}
        if original.get("tool_calls"):
            calls = []
            for call in original["tool_calls"]:
                function = dict(call["function"])
                if isinstance(function.get("arguments"), str):
                    function["arguments"] = json.loads(function["arguments"])
                calls.append({**call, "function": function})
            message["tool_calls"] = calls
        result.append(message)
    return result


def drop_empty_assistant_turns(messages):
    """Remove assistant turns with no content and no tool calls.

    377 training conversations contain such a turn between a tool result and the
    next tool call. Supervising it teaches the model to emit end-of-turn with
    nothing, which the serving layer rejects as an empty response. The source
    data file is never modified; this only filters what is rendered for training.
    """
    return [m for m in messages
            if not (m.get("role") == "assistant"
                    and not (m.get("content") or "").strip()
                    and not m.get("tool_calls"))]


def sort_tool_parameters(tools):
    """Sort the keys inside each tool's `parameters` only.

    Lemonade re-serializes request JSON with sorted keys, but llama.cpp then rebuilds each tool
    wrapper in its own fixed order (type, function, name, description, parameters). The prompt a
    model sees through Lemonade therefore has the wrapper in canonical order and `parameters`
    sorted. Verified byte for byte against llama-server's /apply-template."""
    out = []
    for tool in tools:
        fn = dict(tool["function"])
        if "parameters" in fn:
            fn["parameters"] = sort_keys(fn["parameters"])
        out.append({**tool, "function": fn})
    return out


def sort_keys(value):
    """Recursively sort dict keys."""
    if isinstance(value, dict):
        return {k: sort_keys(value[k]) for k in sorted(value)}
    if isinstance(value, list):
        return [sort_keys(v) for v in value]
    return value


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--model", default=DEFAULT_MODEL)
    ap.add_argument("--steps", type=int, default=300)
    ap.add_argument("--seed", type=int, default=7)
    ap.add_argument("--rank", type=int, default=16)
    ap.add_argument("--max-length", type=int, default=4608)
    ap.add_argument("--gradient-accumulation", type=int, default=8)
    ap.add_argument("--resume", type=Path)
    ap.add_argument("--train-file", type=Path, default=TRAIN,
                    help="Training conversations; defaults to the full train split. Never a validation or test file.")
    ap.add_argument("--sort-tool-keys", action="store_true",
                    help="Render tool schemas with alphabetically sorted keys, as Lemonade delivers them.")
    ap.add_argument("--output", type=Path, default=ROOT / "models" / "ondevice" / "qwen2.5-1.5b")
    args = ap.parse_args()
    if args.steps <= 0 or args.rank <= 0 or args.gradient_accumulation <= 0:
        ap.error("--steps and --rank must be positive")
    if not args.train_file.is_file():
        ap.error(f"Training data not found: {args.train_file}")
    if any(x in args.train_file.name for x in ("val", "test")):
        ap.error("Refusing a validation or test file as training data")

    import torch
    from datasets import Dataset
    from peft import LoraConfig, get_peft_model, prepare_model_for_kbit_training
    from transformers import (AutoModelForCausalLM, AutoTokenizer, BitsAndBytesConfig,
                              Trainer, TrainingArguments,
                              set_seed)

    if not torch.cuda.is_available():
        ap.error("CUDA is required for this QLoRA recipe")
    set_seed(args.seed)
    torch.backends.cuda.enable_math_sdp(False)
    raw = [json.loads(line) for line in args.train_file.read_text(encoding="utf-8").splitlines() if line.strip()]
    tokenizer = AutoTokenizer.from_pretrained(args.model, trust_remote_code=False)
    if tokenizer.pad_token is None:
        tokenizer.pad_token = tokenizer.eos_token

    def render(item):
        messages = template_messages(drop_empty_assistant_turns(item["messages"]))
        tools = item.get("tools") or []
        if args.sort_tool_keys:
            tools = sort_tool_parameters(tools)
        text = tokenizer.apply_chat_template(messages, tools=tools, tokenize=False,
                                             add_generation_prompt=False)
        ids = tokenizer(text)["input_ids"]
        if len(ids) > args.max_length:
            raise ValueError("Training conversation exceeds --max-length; refusing to truncate its answer")
        labels = [-100] * len(ids)
        for i, message in enumerate(messages):
            if message["role"] != "assistant":
                continue
            prefix = tokenizer(tokenizer.apply_chat_template(messages[:i], tools=tools,
                tokenize=False, add_generation_prompt=True))["input_ids"]
            end = tokenizer(tokenizer.apply_chat_template(messages[:i+1], tools=tools,
                tokenize=False, add_generation_prompt=False))["input_ids"]
            if ids[:len(prefix)] != prefix or ids[:len(end)] != end:
                raise ValueError("Chat template is not prefix-stable; refusing incorrect assistant labels")
            labels[len(prefix):len(end)] = ids[len(prefix):len(end)]
        if not any(x != -100 for x in labels[1:]):
            raise ValueError("Conversation has no assistant training tokens")
        return {"input_ids": ids, "attention_mask": [1]*len(ids), "labels": labels}

    dataset = Dataset.from_list([render(item) for item in raw])

    quantization = BitsAndBytesConfig(load_in_4bit=True, bnb_4bit_quant_type="nf4",
                                      bnb_4bit_use_double_quant=True,
                                      bnb_4bit_compute_dtype=torch.float16)
    model = AutoModelForCausalLM.from_pretrained(
        args.model, quantization_config=quantization, device_map="auto",
        torch_dtype=torch.float16, trust_remote_code=False, attn_implementation="sdpa")
    print("Loaded with attention:", model.config._attn_implementation, flush=True)
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
        per_device_train_batch_size=1, gradient_accumulation_steps=args.gradient_accumulation,
        learning_rate=2e-4, fp16=True, gradient_checkpointing=True,
        logging_steps=10, save_steps=min(25, args.steps), save_total_limit=2,
        optim="adamw_torch", seed=args.seed, data_seed=args.seed,
        report_to="none", remove_unused_columns=False)
    class AssistantTrainer(Trainer):
        def compute_loss(self, model, inputs, return_outputs=False, **kwargs):
            labels = inputs.pop("labels")
            # Batch size is one. Compute vocabulary logits only where the next
            # token is an assistant target, avoiding a full context x vocabulary tensor.
            positions = torch.where(labels[0, 1:] != -100)[0]
            targets = labels[:, positions + 1]
            outputs = model(**inputs, logits_to_keep=positions)
            loss = torch.nn.functional.cross_entropy(
                outputs.logits.float().reshape(-1, outputs.logits.shape[-1]), targets.reshape(-1))
            return (loss, outputs) if return_outputs else loss

    def collate(features):
        assert len(features) == 1, "Selective logits require per-device batch size one"
        return {key: torch.tensor([features[0][key]], dtype=torch.long)
                for key in ("input_ids", "attention_mask", "labels")}

    trainer = AssistantTrainer(model=model, args=training, train_dataset=dataset,
                               data_collator=collate)
    trainer.model_accepts_loss_kwargs = False
    trainer.train(resume_from_checkpoint=str(args.resume) if args.resume else None)
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
        "max_length": args.max_length,
        "gradient_accumulation": args.gradient_accumulation,
        "supervision": "assistant messages only; selective vocabulary logits",
        "training_examples": len(raw),
        "empty_assistant_turns_dropped": sum(len(i["messages"]) - len(drop_empty_assistant_turns(i["messages"])) for i in raw),
        "sort_tool_keys": args.sort_tool_keys,
        "training_data": str(args.train_file.name),
        "training_data_sha256": digest(args.train_file),
        "hardware": torch.cuda.get_device_name(0),
        "cuda": torch.version.cuda,
        "adapter_path": str((args.output / "adapter").resolve()),
        "validation_or_test_loaded": False,
    }
    (args.output / "training_manifest.json").write_text(json.dumps(info, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(info, indent=2))


if __name__ == "__main__":
    main()
