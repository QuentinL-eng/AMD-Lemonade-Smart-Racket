# Hosted site on quentinengineering.com/tennisbuddee

| URL | What | Source |
|---|---|---|
| `/tennisbuddee` | Info page with the overview video (https://youtu.be/wqH2P8v8PkI) | `website/index.html` |
| `/tennisbuddee/paper` | White paper | `docs/WHITE_PAPER.html` |
| `/tennisbuddee/emulator` | Browser emulator, same page as `tennisbuddy.net/emulator` | `website/emulator.html` |
| `/tennisbuddee/api/muse`, `/api/warm` | Agent endpoint and warm-up; the only paths that run worker code | `website/hosted/worker.js` |

`node tools/build_hosted_emulator.mjs` assembles these into `.website-hosted/tennisbuddee/`. It rewrites one `ENGINE` constant in the emulator page (label, API path, warm-up path) and a few agent-related lines on the info page; everything else is the page as it is. Local Lemonade use (`node tools/emulator-server.mjs`) is unchanged. The only visible difference from the live `tennisbuddy.net/emulator` is the agent's name and engine ("Racket agent", "Modal · hosted model") in place of "Muse", "Baseten".

## How the agent is served

The round-4 merged model runs on Modal under vLLM (`tools/modal_serve.py`, an L4 GPU, scale-to-zero, API key required). The worker calls it with `temperature: 0` and the app's key order; vLLM's `hermes` tool parser reads the model's own `<tool_call>` text, so no grammar reorders arguments. Set `SORT_TOOL_KEYS = "true"` in the wrangler config only for a model trained with `--sort-tool-keys`.

Cold starts take minutes. When the emulator opens, the page calls `/api/warm`, which makes the worker wake the GPU in the background; a question asked before it is ready gets "temporarily unavailable, try again shortly". Idle time costs nothing; a GPU stays up for five minutes after the last request. A best-effort limit of 20 requests a minute per client applies in the worker; set a spending limit on the Modal workspace too.

## Deploy

1. Serve the model (once; see the header of `tools/modal_serve.py`):

```bash
python -m modal volume put tennis-buddee-models <merged-model-dir> /r4
python -m modal secret create tennis-buddee-vllm-key VLLM_API_KEY=<random key>
python -m modal deploy tools/modal_serve.py
```

2. Build, add the same key to Cloudflare, and deploy:

```bash
node tools/build_hosted_emulator.mjs
npx wrangler login
npx wrangler secret put AGENT_API_KEY -c wrangler.tennisbuddee.toml
npx wrangler deploy -c wrangler.tennisbuddee.toml
```

`AGENT_BASE_URL` and `AGENT_MODEL` are plain variables in `wrangler.tennisbuddee.toml`. The routes need `quentinengineering.com` to be a Cloudflare zone in the account Wrangler is logged into. They take over only `/tennisbuddee` and `/tennisbuddee/*`.

On Windows Git Bash, run `modal` with `MSYS_NO_PATHCONV=1` so `/r4` is not rewritten into a Windows path.

## Stop or remove the model server

```bash
python -m modal app stop -y tennis-buddee-serve
```

## Tested locally

All routes, assets, the agent loop (against a mock upstream), same-origin checks and the warm-up endpoint passed under `wrangler dev`, and the page loaded in a browser with no errors. The Modal server itself was tested directly by the scoring run (see the evaluation report). Not yet tested: the deployed Cloudflare routes, and a cold start through the worker.
