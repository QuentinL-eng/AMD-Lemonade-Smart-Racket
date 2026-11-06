# Hosted emulator on quentinengineering.com/tennisbuddy

The browser emulator and an info page, served from `quentinengineering.com/tennisbuddy`, with the racket agent answered by the same tuned model as the Lemonade path but hosted on Fireworks AI instead of a laptop.

| URL | What |
|---|---|
| `/tennisbuddy` | Info page (`website/index.html`) |
| `/tennisbuddy/emulator` | Emulator (`website/emulator.html`) |
| `/tennisbuddy/api/muse` | Agent endpoint, the only path that runs worker code |

The local Lemonade emulator (`node tools/emulator-server.mjs`) is unchanged. Both builds use the same page and the same agent; the page gets its engine label and API path from one `ENGINE` constant that `tools/build_hosted_emulator.mjs` rewrites.

## What differs from the Lemonade path

- The worker (`website/hosted/worker.js`) holds the Fireworks key. It never reaches the browser.
- Requests go to `https://api.fireworks.ai/inference/v1/chat/completions` with `max_tokens` and `temperature: 0`, and without `enable_thinking`.
- Request keys keep the app's order by default, which is what Fireworks delivers and what a model trained on the repo's normal data expects. Lemonade sorts keys ([LEMONADE_SCHEMA_ORDER.md](LEMONADE_SCHEMA_ORDER.md)); if you train with `--sort-tool-keys`, set the worker variable `SORT_TOOL_KEYS = "true"` in `wrangler.tennisbuddy.toml` to match. Train and serve with the same order.
- A best-effort limit of 20 requests per minute per client protects the key. It lives in one worker instance, so it is a speed bump, not a quota. Set a spending limit on the Fireworks account.

## Deploy

1. Finish training on Fireworks and deploy the resulting model. Until `FIREWORKS_MODEL` is set the site works but the Racket agent answers "not configured yet", so the site can go live first. Note the model id (`accounts/<account>/models/<name>`; a deployed fine-tune may need `#accounts/<account>/deployments/<id>` appended).
2. Build and set secrets:

```bash
node tools/build_hosted_emulator.mjs
npx wrangler secret put FIREWORKS_API_KEY -c wrangler.tennisbuddy.toml
npx wrangler secret put FIREWORKS_MODEL -c wrangler.tennisbuddy.toml
```

3. Deploy:

```bash
npx wrangler deploy -c wrangler.tennisbuddy.toml
```

The routes in `wrangler.tennisbuddy.toml` need `quentinengineering.com` to be a zone in the same Cloudflare account as the login Wrangler uses. If the domain is elsewhere, either move its DNS to Cloudflare or tell me where it is hosted and the build can be adapted.

If `quentinengineering.com` already has its own site on Cloudflare, these two routes take over only `/tennisbuddy` and `/tennisbuddy/*`; the rest of the site is unaffected.

## Try it locally without a key

Create `.dev.vars` (git-ignored) with `FIREWORKS_API_KEY`, `FIREWORKS_MODEL` and, for a mock, `FIREWORKS_BASE_URL=http://127.0.0.1:<port>/v1`, then:

```bash
node tools/build_hosted_emulator.mjs
npx wrangler dev -c wrangler.tennisbuddy.toml --local --port 8790
```

Open `http://127.0.0.1:8790/tennisbuddy/emulator`. This was run against a mock Fireworks endpoint, which confirmed routing, same-origin checks, the request format (bearer key, `max_tokens`, `temperature`, no `enable_thinking`; key sorting was checked in the earlier always-sorted version) and the tool loop. It has not been run against real Fireworks.
