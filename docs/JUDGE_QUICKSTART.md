# Judge quick start

Requirements: Node.js 20+, a current Lemonade installation, and enough memory for the selected model. No Apple hardware, racket, account, or package installation is needed for the browser code. Install Lemonade using its [official guide](https://lemonade-server.ai/docs/guide/install/).

## Prepare Lemonade

```bash
lemonade config set port=8000
lemonade pull Qwen3-1.7B-GGUF
lemonade load Qwen3-1.7B-GGUF --ctx-size 8192
```

The backend is selected automatically. For an older AMD GPU, add `--llamacpp vulkan`; the RX 580 is under test. The context size above is a demo setting, not the context used for the published Windows benchmark. Reduce it if the machine cannot allocate enough memory, and record the resulting limit.

## One command

```bash
node tools/judge-demo.mjs
```

Runs the offline checks, probes Lemonade (printing the exact `lemonade pull`/`load` commands if it is missing), then starts the emulator at `http://localhost:8765/emulator`. Add `--check` to stop before starting the server. The longer steps below are the same thing done by hand.

## Check and launch

```bash
node tools/judge-check.mjs
node tools/emulator-server.mjs
```

Open `http://localhost:8765/emulator`. Start Session, skip to the end, and open Racket agent. The replay banner distinguishes dataset labels, tracked timing, and illustrative estimates. The source video loads from YouTube only when requested. The launcher routes agent requests to the local Lemonade API and logs their destination without prompts or shot content.

For a different local endpoint or model, set `LEMONADE_BASE_URL` and `LEMONADE_MODEL` before launching. The proxy supports `LEMONADE_API_KEY`. Do not put keys into a public URL or repository.

Chat uses numeric tool references. Invalid answers fail visibly. The current experimental model has known accuracy failures; see [the unchanged validation score](LEMONADE_EVAL.md). Numeric reference tests do not establish semantic correctness. The native Swift and iPhone model paths still need Apple hardware verification.

## Reproduce the exact validation context

Python and NumPy are needed for the optional evaluator. The small committed fixture contains the original validation conversations and their synthetic context. It contains no training or test conversations. Restore it into a separate ignored directory:

```bash
python -m pip install numpy
python tools/prepare_eval_fixture.py
```

Then set `LEMONADE_MODEL=Qwen3-1.7B-GGUF` in your shell and run:

```bash
python tools/agent_eval.py --preset lemonade --data-dir data/whatif-val --sample 243 --seed 7
```

The scorer, sample selection, and original measurement files are unchanged. The fixture's per-file hashes are verified before restoration. The evaluator writes its report under `data/whatif/`; model sampling and backend differences can produce different answers. Record server/backend versions, quantization, context size, hardware, and errors with every result.

For checks without a running model: `node tools/judge-check.mjs --offline`.
