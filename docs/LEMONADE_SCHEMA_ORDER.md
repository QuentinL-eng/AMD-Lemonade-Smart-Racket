# Finding: Lemonade normalises tool-schema key order, and a fine-tuned small model can depend on it

Measured on Lemonade Server 2026.45.3 (Windows, llama.cpp backend) on November 6, 2026. Nothing here has been sent to the Lemonade project; a draft report is at the end for the user to review and send.

## What we saw

We fine-tuned Qwen2.5-1.5B-Instruct (QLoRA) to call tools for the smart-racket coach, merged the adapter, converted it to GGUF (Q8_0) and loaded it in Lemonade as `TennisBuddee-R4`. The same 243 validation cases and strict scorer gave:

| Serving path | Strict all-pass | Response errors | `objective` cases | Goal reached |
|---|---:|---:|---:|---:|
| Own Transformers server (NF4 + adapter, tool schemas in the app's key order) | 212/243 (87.2%) | 0 | 96/127 | 100/123 |
| Lemonade (GGUF Q8_0), default sampling | 115/243 (47.3%) | 0 | 6/127 | 3/123 |
| Lemonade (GGUF Q8_0), `temperature: 0` | 118/243 (48.6%) | 0 | 6/127 | 2/123 |

Reports: [`evaluation/lemonade-tuned-r4-default-sampling.json`](../evaluation/lemonade-tuned-r4-default-sampling.json), [`evaluation/lemonade-tuned-r4-unsorted-training-temp0.json`](../evaluation/lemonade-tuned-r4-unsorted-training-temp0.json).

The failure was narrow: on goal cases the model's first `simulate_change` call omitted every change (`{"type":"forehand"}`), so the tool reported "no change" and the model said the contact was "already centered".

## What it was not

| Suspect | Test | Result |
|---|---|---|
| Sampling | repeated at `temperature: 0` | still 118/243 |
| Merge into fp16 | served the merged weights in Transformers, six goal cases | non-zero changes, correct |
| GGUF conversion / quantization | sent the original request straight to the llama.cpp server that Lemonade starts | correct call: `{"type":"forehand","swing_percent":10}` |
| Chat template | rendered the same messages through the Hugging Face template and llama.cpp's `/apply-template` | byte-identical |

## What it was

The same request sent through Lemonade (port 8000) and straight to the llama.cpp backend (port 8001) differed by 13 prompt tokens (3,009 against 3,022). Sending the tool schemas to the backend with every dictionary key sorted alphabetically gave exactly 3,009 tokens and exactly the failing behavior. So Lemonade's front end re-serializes the request JSON with sorted keys before llama.cpp renders the template, and the model, trained on the application's key order, behaves differently on the sorted prompt.

You can check any Lemonade server in about a second, with no model-specific code:

```bash
python tools/lemonade_schema_order_check.py --base http://localhost:8000/api/v1
```

Against Lemonade it prints equal token counts for the application order and the sorted order (204 and 204). Against the llama.cpp backend directly it prints different counts (205 and 204). This shows the normalisation, not that normalisation is wrong; it is a reasonable thing for a server to do. The practical lesson is for fine-tuners.

## What to do

1. **Train on the schema the server delivers.** `tools/train_ondevice.py --sort-tool-keys` renders tool schemas with sorted keys. Round 6 uses it. Result: see [ADAPTER_EVAL.md](ADAPTER_EVAL.md) (recorded only after it was measured).
2. **Test through the server you will deploy on**, not only through a local Transformers loop. Our 87.2% was real for the path it was measured on and said nothing about the Lemonade path.
3. A model that is robust to key order is better than one that is not. Training on a mix of orders would do that; we have not tried it.

## Draft upstream report (not sent)

> **Title:** Request JSON is re-serialized with sorted keys, which changes tool-schema text in the rendered prompt
>
> Server 2026.45.3, Windows, llama.cpp backend. For a chat request with `tools`, the prompt rendered by the chat template contains the tool schemas in alphabetical key order, whereas the same request sent directly to the backend preserves the client's order (205 against 204 prompt tokens for a minimal tool; 3,022 against 3,009 for a ten-tool request). This is probably intentional and harmless for base models. It matters for fine-tuned models trained on a different key order: we measured 212/243 against 118/243 on the same cases. Suggest documenting it, or preserving key order. Reproduction: `tools/lemonade_schema_order_check.py` from the Tennis Buddee repository (standard library only).

Before sending: re-run the check on the latest Lemonade release, remove local paths, and decide where to post it.
