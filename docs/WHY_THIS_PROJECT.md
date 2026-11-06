# Why this project, why me, what a Strix Halo laptop unlocks

Every statement below points at something in this repository. Plans are labeled as plans.

## Why this project

A smart tennis racket generates numbers a recreational player cannot read: contact position, swing speed, face angle. The interesting question is "what would happen if I changed my swing?" and answering it honestly needs two things that usually fight each other: a **physics simulator** that produces trustworthy numbers, and a **small language model** that can choose the right tool and explain the result in plain words.

The design rule is that **the model never invents a number**. It picks tools; application code supplies every figure.
- `website/api/grounded-answer.js` is a dependency-free renderer. The model selects references into tool-result JSON and the renderer resolves them to the original values. Literals and spelled-out numbers in prose are rejected. Try it: `node examples/grounded-numeric-answer.mjs`.
- That is a reusable pattern for any Lemonade developer building tool-calling apps on a small local model, which is the community-impact angle ([docs/COMMUNITY_CONTRIBUTION.md](COMMUNITY_CONTRIBUTION.md)).

## What is genuinely creative here

- **A physical product, a physics model and a local LLM in one loop**: sensor insert in the racket handle, on-racket shot computation, a what-if simulator, and a tool-calling coach.
- **Measure, don't assume**: the same 243-case validation set and scorer are used for every engine ([tools/agent_eval.py](../tools/agent_eval.py)), so Lemonade, the trained adapter and the historical hosted baseline are directly comparable.
- **Error analysis published, not hidden**: the first trained adapter scored 69.5% with 62 response errors counted as failures. The cause was traced to 377 training conversations containing an empty assistant turn, which the training loader had been teaching the model to emit ([docs/ADAPTER_EVAL.md](ADAPTER_EVAL.md)). The fix is in `tools/train_ondevice.py`, with a test (`tools/test_train_preprocessing.py`).
- **A Lemonade finding other fine-tuners will hit**: Lemonade sorts tool-schema keys and llama.cpp forces a call's argument order to match, which silently cut a tuned model from 87% to 49% until it was retrained to write arguments in that order. The model is now served by Lemonade at 81.1% on validation and 81.9% on an untouched test split, and a one-second checker is included ([docs/LEMONADE_SCHEMA_ORDER.md](LEMONADE_SCHEMA_ORDER.md)).
- **Low-cost AMD hardware coverage**: the Lemonade container was run on an RX 580 (4 GiB) homelab GPU under Vulkan, with a hardware-protecting watchdog that aborts at 75°C or low memory ([docs/HOMELAB_RX580.md](HOMELAB_RX580.md), `tools/homelab_watch.py`). That shows what Lemonade does on old, cheap AMD cards, not just flagship ones.

## Why me

What the repo shows I have already done, end to end, without a lab or a team budget:
- Built the stack across layers: firmware (`firmware/`), a native Apple app (`apple/`), a browser emulator, a physics simulator and a data pipeline (`tools/`).
- Generated a synthetic, player-split what-if dataset and trained a QLoRA adapter on a consumer laptop GPU, then moved training to a rented A100 when it was faster ([tools/modal_train.py](../tools/modal_train.py)).
- Evaluated with a fixed scorer, reported negative results (36.7 points below the hosted baseline for the untuned Lemonade model) and explained them.
- Treated hardware carefully: the RX 580 test was bounded, monitored and stopped, and the notes say what was not shown.

## What the laptop unlocks (plans, not results)

These are intentions, not completed work:
1. **Run the full agent on one machine.** Serve the model through Lemonade on the laptop's integrated GPU and run the 243-case evaluation there, replacing the current mix of laptop CUDA, a Windows run and a homelab smoke test.
2. **Larger models with more headroom.** The tuned model is 1.5B parameters. Unified memory would let me compare a tuned 7B-class model against the 1.5B one on the same scorer, which the 8 GB RTX 4070 and the 4 GiB RX 580 cannot do.
3. **Publish a compatibility report upstream.** The notes in `COMMUNITY_CONTRIBUTION.md` already list what such a report should contain. Nothing has been sent yet.
4. **Package the pipeline.** Turn the serving, training and evaluation scripts into a repeatable recipe other Lemonade developers can reuse.
