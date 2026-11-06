# Run the fine-tuned racket model in Lemonade

Recipe to take a QLoRA adapter from this repository into a Lemonade server as a normal model, and to score it through that server. Every step below was run on Windows with Lemonade Server 2026.45.3. The model and adapter weights are not in the repository (see `docs/ON_DEVICE_MODEL.md`); train one with `tools/modal_train.py` or `tools/train_ondevice.py`.

## 1. Merge the adapter into the base model

```bash
python tools/merge_adapter.py --adapter <adapter-dir> --output merged
```

The adapter was trained against a 4-bit copy of the base and is merged into fp16 weights, so the result is close to, not identical to, the model scored through `tools/serve_adapter.py`. Re-score it (step 5).

## 2. Convert to GGUF and quantize

You need llama.cpp's converter and the `gguf` Python package. Lemonade already ships `llama-quantize` under its cache (`~/.cache/lemonade/bin/llamacpp/<backend>/`).

```bash
python convert_hf_to_gguf.py merged --outtype f16 --outfile model-f16.gguf
llama-quantize model-f16.gguf TennisBuddee-Q8_0.gguf Q8_0
```

Q8_0 is 1.5 GB for the 1.5B model. The converter is third-party code from llama.cpp's repository; read it before running it.

## 3. Make Lemonade see it

`lemonade pull --checkpoint` accepts Hugging Face checkpoints, not local file paths. For local files, point Lemonade at a folder:

```bash
mkdir -p models/TennisBuddee
cp TennisBuddee-Q8_0.gguf models/TennisBuddee/
lemonade config set extra_models_dir=<absolute path to models>
lemonade list            # shows TennisBuddee, Downloaded: Yes
lemonade load TennisBuddee --ctx-size 8192
```

## 4. Train for what Lemonade delivers

Lemonade re-serializes request JSON with sorted keys, so tool schemas reach the model in a different order than the app wrote them. Train with `--sort-tool-keys` (`tools/modal_train.py --sort-tools`). Details and the one-second check: [LEMONADE_SCHEMA_ORDER.md](LEMONADE_SCHEMA_ORDER.md).

## 5. Score through Lemonade

```bash
export LEMONADE_MODEL=TennisBuddee EVAL_TEMPERATURE=0
python tools/agent_eval.py --preset lemonade --data-dir data/whatif-val --sample 243 --seed 7
python tools/summarize_eval.py data/whatif/eval_lemonade_s243.json
```

`EVAL_TEMPERATURE=0` makes llama.cpp decode greedily; without it the server's own sampling defaults apply (temperature 0.7, top-k 20, repeat penalty 1.1 on this model). The 243-case run takes about 6 minutes through Lemonade, compared with about 2.5 hours through the Transformers/NF4 server.
