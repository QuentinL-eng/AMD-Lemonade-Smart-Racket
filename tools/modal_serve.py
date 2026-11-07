"""Serve a merged fp16 racket model on Modal with vLLM (OpenAI-compatible, scales to zero).

  python -m modal volume put tennis-buddee-models <merged-model-dir> /r4
  python -m modal secret create tennis-buddee-vllm-key VLLM_API_KEY=<random key>
  python -m modal deploy tools/modal_serve.py
  python -m modal app stop tennis-buddee-serve          # stops billing

vLLM reads the key from the VLLM_API_KEY variable of that Modal secret; it is never written to
this repository. Clients send it as a Bearer token. Tool calls use vLLM's `hermes` parser, which reads the model's own <tool_call> text:
no grammar is applied, so the model's argument order is kept (unlike Lemonade/llama.cpp,
docs/LEMONADE_SCHEMA_ORDER.md).
"""
import os
import subprocess

import modal

GPU = os.environ.get("MODAL_SERVE_GPU", "L4")
MODEL_DIR = "/models/r4"
PORT = 8000

image = (
    modal.Image.from_registry("nvidia/cuda:12.9.0-devel-ubuntu22.04", add_python="3.12")
    .entrypoint([])
    .uv_pip_install("vllm==0.21.0")
)
models = modal.Volume.from_name("tennis-buddee-models", create_if_missing=True)
app = modal.App("tennis-buddee-serve")
secrets = [modal.Secret.from_name("tennis-buddee-vllm-key")]


@app.function(image=image, gpu=GPU, volumes={"/models": models}, secrets=secrets,
              scaledown_window=300, timeout=3600)
@modal.concurrent(max_inputs=16)
@modal.web_server(port=PORT, startup_timeout=900)
def serve():
    subprocess.Popen([
        "vllm", "serve", MODEL_DIR, "--served-model-name", "r4",
        "--host", "0.0.0.0", "--port", str(PORT), "--dtype", "float16",
        "--max-model-len", "8192", "--enforce-eager",
        "--enable-auto-tool-choice", "--tool-call-parser", "hermes",
    ])
