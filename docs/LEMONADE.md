# Lemonade setup

Tennis Buddee can send its tool-calling agent requests to a Lemonade server on the same device or local network. No Tennis Buddee account is needed for this path. Supabase is used only for friend sharing and account features.

> **Current verification status:** the native app transport and connection UI are implemented in source but have not been built or run here. The web emulator still uses its legacy `/api/muse` endpoint; it does not yet connect directly to a judge's Lemonade server. Browser CORS has not been tested, and this document's browser connection steps are a target setup, not a verified workflow. Do not describe the emulator as Lemonade-ready until that integration is implemented and tested.

## Install and prepare a model

Install Lemonade for your platform using the [official installation guide](https://lemonade-server.ai/docs/guide/install/). Use the Lemonade model manager, or its CLI, to pull a local chat model that supports tool calling:

```bash
lemonade pull <model-id>
```

Choose an available model in Lemonade's model list. This project does not assume that all models support the same tool-call behavior.

## Start the server

Start the Lemonade server:

```bash
lemonade-server serve
```

The app's initial server address is `http://localhost:8000/api/v1`. Use **Test connection** in the Racket agent screen. A successful test lists the models Lemonade returns and reports the request latency. Pick the model to use. The address and model choice are saved locally, and the app checks the server again on each launch. If it cannot connect, the screen shows the failure and answers with the built-in engine.

For a future direct-browser connection, the emulator will need a configurable Lemonade server address. The browser page and Lemonade are different origins, so Lemonade must allow the page's origin. Lemonade documents this with its `allowed_origins` setting; configure the exact origin of the page, including scheme and port, rather than a wildcard. See [Lemonade CORS configuration](https://lemonade-server.ai/docs/guide/configuration/#allowed-origins).

Before implementing or testing a direct-browser chat request, check that the browser preflight succeeds. Replace the example origin and address with the actual page and server values:

```bash
curl -i -X OPTIONS http://localhost:8000/api/v1/chat/completions \
  -H 'Origin: https://tennisbuddy.net' \
  -H 'Access-Control-Request-Method: POST' \
  -H 'Access-Control-Request-Headers: content-type'
```

The response must allow the page origin and the requested method and headers. If that check fails, configure `allowed_origins` and repeat it. A browser reports CORS failures as network errors, so check this before debugging the model or tool calls. The app's native HTTP client does not use browser CORS.

## Connect an iPhone over the LAN

`localhost` on an iPhone means the iPhone itself. To reach Lemonade on a laptop, use the laptop's LAN address in the app, such as `http://192.168.1.20:8000/api/v1`. The laptop server must listen on a network interface, not only loopback; launch it with the server's `--host 0.0.0.0` option when needed. Allow the server port through the laptop firewall, and keep both devices on a network that permits device-to-device traffic. The exact server address and port depend on the Lemonade launch configuration.

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
