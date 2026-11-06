"""Run tools/train_ondevice.py unchanged on a Modal GPU. Training only.

Validation is still done on the laptop with tools/serve_adapter.py.

  python -m modal run tools/modal_train.py            # train, adapter lands in a Modal Volume
  python -m modal volume get tennis-buddee-adapters qwen2.5-1.5b-noempty/adapter <local-dir>

Only conversations_train.jsonl is uploaded. Validation and test files are not.
Package versions match tools/requirements-ondevice.txt.
"""
from pathlib import Path

import modal

ROOT = Path(__file__).resolve().parents[1]
REMOTE = "/root/proj"
GPU = "A100-40GB"

image = (
    modal.Image.debian_slim(python_version="3.12")
    .pip_install("torch==2.11.0", index_url="https://download.pytorch.org/whl/cu128")
    .pip_install("transformers==5.22.1", "datasets==5.1.0", "peft==0.21.2",
                 "bitsandbytes==0.50.2", "accelerate==1.15.0")
    .add_local_file(ROOT / "tools" / "train_ondevice.py", f"{REMOTE}/tools/train_ondevice.py")
    .add_local_file(ROOT / "data" / "whatif" / "conversations_train.jsonl",
                    f"{REMOTE}/data/whatif/conversations_train.jsonl")
)
volume = modal.Volume.from_name("tennis-buddee-adapters", create_if_missing=True)
app = modal.App("tennis-buddee-train", image=image)


@app.function(gpu=GPU, timeout=3 * 3600, volumes={"/out": volume})
def train(steps: int = 300, seed: int = 7):
    import subprocess
    subprocess.run(
        ["python", f"{REMOTE}/tools/train_ondevice.py", "--steps", str(steps), "--seed", str(seed),
         "--output", "/out/qwen2.5-1.5b-noempty"],
        check=True)
    volume.commit()


@app.local_entrypoint()
def main(steps: int = 300, seed: int = 7):
    train.remote(steps, seed)
