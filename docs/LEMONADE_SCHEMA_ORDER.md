# Finding: Lemonade sorts tool-schema keys, and llama.cpp forces tool-call arguments into that order

Measured on Lemonade Server 2026.45.3 (Windows, llama.cpp CUDA backend) on November 6, 2026. Nothing here has been sent to the Lemonade project; a draft report is at the end for the user to review and send.

## What we saw

We fine-tuned Qwen2.5-1.5B-Instruct (QLoRA) to call tools for the smart-racket coach, merged the adapter, converted it to GGUF (Q8_0) and loaded it in Lemonade. The same 243 validation cases and strict scorer gave:

| Serving path | Strict all-pass | Response errors | `objective` cases | Goal reached |
|---|---:|---:|---:|---:|
| Own Transformers server (NF4 + adapter, no grammar) | 212/243 (87.2%) | 0 | 96/127 | 100/123 |
| Lemonade, round 4 adapter (default sampling) | 115/243 (47.3%) | 0 | 6/127 | 3/123 |
| Lemonade, round 4 adapter (`temperature: 0`) | 118/243 (48.6%) | 0 | 6/127 | 2/123 |
| Lemonade, round 6 (trained on fully sorted tool schemas) | 113/243 (46.5%) | 0 | 3/127 | 0/123 |
| Lemonade, round 7 (trained on sorted `parameters` only) | 120/243 (49.4%) | 0 | 4/127 | 0/123 |

Reports are in [`evaluation/`](../evaluation) (`lemonade-tuned-r4-*`, `lemonade-tuned-r6-*`, `lemonade-tuned-r7-*`).

The failure was narrow: on goal cases the model's first `simulate_change` call omitted every change (`{"type":"forehand"}`), so the tool reported "no change" and the model said the contact was "already centered".

## Two explanations that were wrong

Each cost a training run, so they are recorded here.

1. **"The prompt text differs."** Lemonade does change the prompt: the same request is 3,009 tokens through Lemonade and 3,022 straight to the llama.cpp backend, and sorting the tool schemas by hand reproduces 3,009 exactly. Rounds 6 and 7 trained on that sorted text (round 7's training prompt was verified identical, character for character, to what llama.cpp renders). They did not fix the problem.
2. **"The weights or conversion are broken."** They are not. Given the prompt text rendered for training, the fp16 merged weights in Transformers and the Q8_0 GGUF in llama.cpp's `/completion` endpoint both produced the correct call, `{"type":"forehand","swing_percent":10}`, for both key orders.

## What it is

When a request includes `tools`, llama.cpp builds a grammar from the tool schemas and constrains the generated call to it. That grammar forces a call's **argument keys into the schema's property order**. We showed it by editing only the order of `properties` for `simulate_change` and sending the same request to the llama.cpp backend:

| Schema property order | Arguments the model produced |
|---|---|
| `session, type, swing_percent, ...` (the app's order) | `type`, `swing_percent` (correct) |
| `session, swing_percent, ..., type` (type last) | `session`, `swing_percent` (`type` lost) |
| alphabetical (what Lemonade delivers) | `type` only (`swing_percent` lost) |

Lemonade sorts the schema alphabetically, so `type` comes after `swing_percent`, `face_deg`, `path_deg` and the contact fields. A model that writes `type` first can then add nothing after it. The fine-tuned model always wrote `type` first, so every change was dropped. Our own Transformers server has no grammar, which is why the 87.2% did not show it.

## How to check any Lemonade server

```bash
python tools/lemonade_schema_order_check.py --base http://localhost:8000/api/v1
```

It sends the same request with the schema in the application's order and in sorted order and compares prompt-token counts. Through Lemonade the counts are equal (204 and 204); straight to the llama.cpp backend they differ (205 and 204). It shows that the server normalises the order, which is the precondition for the failure. It does not show the grammar effect; the table above does.

## What to do

1. **Make the model's argument order the order the grammar allows.** `tools/train_ondevice.py --sort-tool-keys` renders tool schemas with sorted `parameters` and writes every training tool call's arguments in alphabetical order (`type` last). Round 8 uses it. Result: see [ADAPTER_EVAL.md](ADAPTER_EVAL.md), recorded only after it was measured.
2. **Test through the server you will deploy on.** The 87.2% was real for the path it was measured on and said nothing about the Lemonade path.
3. A small tool-calling model should not depend on argument order; training on shuffled orders would be more robust. We have not tried it.

## Draft upstream report (not sent)

> **Title:** Tool-call argument order is forced to the (sorted) schema property order, which truncates calls from models that write keys in another order
>
> Server 2026.45.3, Windows, llama.cpp CUDA backend. Lemonade normalises request JSON so tool-schema keys arrive sorted (205 against 204 prompt tokens for a minimal tool when sent straight to the backend; equal through Lemonade). llama.cpp then builds a grammar from the schema, and the generated arguments must follow its property order. A model fine-tuned to write `type` before optional numeric fields loses those fields entirely: on 243 evaluation cases a model that scores 212 on a no-grammar server scored 118 through Lemonade, because its first tool call had no arguments after `type`. Suggest documenting that the property order of a tool schema constrains the model's output order, or preserving the client's order. Reproduction: `tools/lemonade_schema_order_check.py` and the table in `docs/LEMONADE_SCHEMA_ORDER.md` from the Tennis Buddee repository.

Before sending: re-run on the latest Lemonade release, remove local paths, and decide where to post it.
