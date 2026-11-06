# Lemonade Developer Challenge video script (about 3:00)

The existing `video/DEMO_SCRIPT.md` is for a different contest (Meta rubric). This one is written for the Lemonade
challenge, which scores **community impact, technical depth and creativity**, and gives bonus points for recorded demos.
Spoken lines are in quotes. Brackets are what is on screen. All numbers in the script are measured and recorded in `docs/ADAPTER_EVAL.md`; re-read it before recording.

Say "smart racket". Say "estimate", not "prediction", for simulator output. Every number on screen comes from a file in
the repo.

## The cut

**0:00 to 0:15, hook (creativity)**
[Real serve in slow motion. Cut to the phone showing one shot: ball speed, spin, contact point.]
"A smart racket gives me numbers I can't use. The useful question is: what happens if I change my swing? To answer it
honestly I need a physics simulator and a small language model, and I wanted the model to run on my own machine."

**0:15 to 0:40, what it is (creativity)**
[Racket, sensor in the handle, then the Muse screen with What-if.]
"This is Tennis Buddee. The racket measures contact and swing. A simulator, `simulate_change`, produces every number.
The model's only job is to pick tools and explain the result. It never invents a figure."
[Zoom on `website/api/grounded-answer.js`.] "That rule is a small open-source file anyone can reuse: the model points at
numbers in tool results and code fills them in."

**0:40 to 1:10, Lemonade in the loop (technical depth)**
[Terminal: `lemonade --version`, `lemonade status`, then `node tools/judge-demo.mjs`. Then the browser emulator, Racket
agent, a question answered.]
"Lemonade is the engine. The phone app, the browser demo and my evaluator all talk to it through the same
OpenAI-style endpoint, so swapping models is a base-URL change. One command starts the demo for a judge: no racket, no
account."

**1:10 to 1:50, the honest result (technical depth)**
[Table from `docs/LEMONADE_EVAL.md` and `docs/ADAPTER_EVAL.md`, bars drawn from the numbers.]
"I scored every engine on the same 243 validation cases with the same strict scorer. Untuned Qwen3 1.7B on Lemonade got
51.0%. The hosted baseline got 87.7%. I didn't hide that. I fine-tuned a 1.5-billion-parameter model with QLoRA on a rented
GPU, and my first result had 62 response errors. I traced them to 377 training conversations with an empty assistant turn,
removed them, and errors went to zero. Then I removed training examples that ended on a change that didn't hit the goal,
and that took my own server to 87.2%."

**1:50 to 2:25, closing the loop on Lemonade (community impact)**
[Terminal: the model loaded with `lemonade load`, then the evaluation summary from `python tools/summarize_eval.py`.]
"Then I converted the tuned model to GGUF and loaded it into Lemonade as a custom model. The first score through Lemonade
was 48 percent, and I found out why. Lemonade sorts the tool schema, and llama.cpp forces the model's call arguments into
that order, so my model, which writes the stroke type first, lost every change after it. I trained it to write arguments
in that order. Through Lemonade, 197 of 243 on validation, 81.1 percent, and 136 of 166 on a test set I touched exactly
once, 81.9 percent. Zero response errors."
[On screen, small print: "6.6 points below the hosted baseline's 87.7%. Greedy decoding. Validation reused across rounds; test run once."]
[Show `tools/lemonade_schema_order_check.py` printing 204 and 204.]
"I wrote a one-second check so any Lemonade developer can see whether their server does this."

**2:25 to 2:50, why local (community impact)**
[Slide with four lines from `docs/WHY_LEMONADE.md`.]
"Why this matters. No account, no data leaving the player's network. Zero request errors on 243 runs. Evaluations on my
own hardware cost nothing, which is why I could afford four rounds. And the Lemonade container loaded a model on a
4-gigabyte RX 580, so this isn't only for flagship machines."

**2:50 to 3:00, close**
[Endcard: repo URL, `node tools/judge-demo.mjs`.]
"Everything is open source. One command runs the demo. A Strix Halo machine would let me compare a tuned 7-billion-
parameter model against this one on the same scorer, and publish the recipe for other Lemonade developers."

## Shots to record

1. Real serve, 240 fps if you have it, and one real shot on the phone (use the footage already in `video/public/footage/`).
2. Terminal capture: `lemonade --version`, `lemonade status`, `node tools/judge-demo.mjs --check`.
3. Browser capture: emulator, Start Session, skip to end, Racket agent, one question.
4. Screen capture of `docs/ADAPTER_EVAL.md` results table.
5. Lemonade custom-model load and the evaluation summary from `python tools/summarize_eval.py`.

## Claims to keep true

- Never call any of these numbers "better than the hosted model". Served by Lemonade it is 81.1% (validation) and 81.9% (test) against the hosted 87.7%. The 87.2% was on my own server.
- The Lemonade-served numbers ran on an RTX 4070 laptop GPU with Lemonade's CUDA backend, not AMD hardware. Don't imply otherwise.
- The RX 580 test was one short smoke test, not a benchmark. Don't call it a performance result.
- Don't show or read out the form data (address, phone) anywhere.
- Every number in the script is recorded in `docs/ADAPTER_EVAL.md`; re-read it before recording.
