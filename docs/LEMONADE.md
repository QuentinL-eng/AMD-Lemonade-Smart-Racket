# Lemonade setup

Tennis Buddee can send its tool-calling agent requests to a Lemonade server on the same device or local network. No Tennis Buddee account is needed for this path. Supabase is used only for friend sharing and account features.

> **Current verification status:** native Swift app execution needs a Mac. Lemonade Server 2026.45.3 and the full 243-case Python evaluation ran on Windows. The local browser replay loaded successfully and its proxy passed a mock tool-loop test. A real local model answer also reached the browser, but answered a shot-count question incorrectly. Treat the current model as an experimental demo; the measured strict score is 51.0%.

## Install and prepare a model

Install Lemonade for your platform using the [official installation guide](https://lemonade-server.ai/docs/guide/install/). On Windows, the verified package command is:

```powershell
winget install --id AMD.LemonadeServer --exact
```

The installed CLI reports its version and server state with `lemonade --version` and `lemonade status`. Pull a small chat model with tool-calling support:

```bash
lemonade pull Qwen3-1.7B-GGUF
```

This model is about 1 GB in Lemonade's catalog and is marked `tool-calling`. Choose another available model from Lemonade's list if appropriate. The app sends `enable_thinking: false` to keep Qwen3 from spending its response budget on reasoning text before emitting tool calls. This request parameter is a Lemonade API extension; other providers may ignore it.

## Start the server

The Windows installer starts the local Lemonade service. Check that it is running:

```powershell
lemonade status
```

Lemonade's current default port is `13305`; this app's configured default is `8000`. Set Lemonade to the app's port once:

```powershell
lemonade config set port=8000
```

The server applies and saves the setting. Then load the model:

```powershell
lemonade load Qwen3-1.7B-GGUF
```

Use **Test connection** in the Racket agent screen. A successful test lists the models Lemonade returns and reports the request latency. Pick the model to use. The address and model choice are saved locally, and the app checks the server again on each launch. If it cannot connect, the screen shows the failure and answers with the built-in engine.

## Run the local browser emulator

With Node.js 20 or later installed, run this from the repository root:

```bash
node tools/emulator-server.mjs
```

Open `http://localhost:8765/emulator`, press **Start Session**, then **Skip to end of match** and open **Racket agent**. No racket, Apple device, or account is required. The launcher serves the committed replay assets and routes `/api/muse` to Lemonade on loopback; the route name is retained for compatibility. The default model is `Qwen3-1.7B-GGUF`. Override `LEMONADE_MODEL` and `LEMONADE_BASE_URL` in the environment to select another local model or port. `LEMONADE_API_KEY` is supported by the proxy if the server requires it.

The local proxy uses the browser's own origin, so its agent requests avoid cross-origin configuration. A direct-browser connection to Lemonade would need the proper origin headers. A loopback preflight from `http://localhost:8765` was verified to return HTTP 204 and the matching `Access-Control-Allow-Origin` header. See [Lemonade CORS configuration](https://lemonade-server.ai/docs/guide/configuration/#allowed-origins).

Browser chat now uses the `present_answer` tool and a tested numeric reference renderer; references are resolved from actual tool results in application code. Free-form numeric literals and common English number words in prose are rejected. Live accuracy and refusal rates for this new path have not yet been measured; the native app and other browser features have not adopted it. See [scope and limitations](COMMUNITY_CONTRIBUTION.md). The existing 51.0% model evaluation remains unchanged.

The separate Ubuntu RX 580 installation successfully loaded a Vulkan model and answered a short prompt, then was stopped after the user reported historical shutdowns. It remains stopped with tighter resource limits. See [the observed hardware state and bounded test policy](HOMELAB_RX580.md).

Before implementing or testing a direct-browser chat request, check that the browser preflight succeeds. Replace the example origin and address with the actual page and server values:

```bash
curl -i -X OPTIONS http://localhost:8000/api/v1/chat/completions \
  -H 'Origin: https://tennisbuddy.net' \
  -H 'Access-Control-Request-Method: POST' \
  -H 'Access-Control-Request-Headers: content-type'
```

The response must allow the page origin and the requested method and headers. If that check fails, configure `allowed_origins` and repeat it. A browser reports CORS failures as network errors, so check this before debugging the model or tool calls. The app's native HTTP client does not use browser CORS.

## Connect an iPhone over the LAN

`localhost` on an iPhone means the iPhone itself. To reach Lemonade on a laptop, use the laptop's LAN address in the app, such as `http://192.168.1.20:8000/api/v1`. The laptop server must bind to a network interface, not only loopback; the current configuration command is `lemonade config set host=0.0.0.0`. Allow the server port through the laptop firewall and restrict it to a trusted private network. Lemonade warns that binding to `0.0.0.0` exposes inference and internal control endpoints; the current app does not send an API key, so do not use this unauthenticated LAN configuration on a public or untrusted network. See [Lemonade server configuration](https://lemonade-server.ai/docs/guide/configuration/).

## What the app sends

The app calls `GET {base}/models` and `POST {base}/chat/completions`. Chat requests contain the player's question, the registered tool schemas, and any tool results needed for the answer. Local mode does not send those requests through Supabase. The connection status and engine name are visible in the app.

## Troubleshooting

- **Connection test fails:** confirm the server is running, the base address includes the correct API prefix, and `/models` is reachable from the device. On a phone, replace `localhost` with the laptop's LAN address.
- **The server is reachable but no models appear:** pull a chat model and test again.
- **A model responds without tool calls:** select a model configured for tool calling; the agent relies on tool calls for racket facts.
- **The emulator reports a network error:** check the browser's CORS preflight and allowlist the exact emulator origin. Also check the server and laptop firewall.
- **The iPhone cannot connect:** verify both devices share a reachable network, the server listens on the LAN interface, and the firewall permits the server port.
- **The engine name says Built-in engine:** the Lemonade server was not reachable at the most recent connection check, or the selected model is unavailable. The app shows the connection reason in the Racket agent settings.

Lemonade's API routes and server options can change. For the installed version, consult the [OpenAI-compatible API reference](https://lemonade-server.ai/docs/api/openai/) and [server configuration guide](https://lemonade-server.ai/docs/guide/configuration/).
