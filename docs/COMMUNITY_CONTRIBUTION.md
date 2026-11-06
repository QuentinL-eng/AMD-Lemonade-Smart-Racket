# Reusable Lemonade contribution

The self-contained numeric reference renderer is available in `website/api/grounded-answer.js` under this repository's MIT license. It needs no runtime packages. Run `node examples/grounded-numeric-answer.mjs` and `node tools/test_grounded_answer.mjs`.

The model uses a `present_answer` function call to select prose and references into tool-result JSON. The renderer resolves each reference to the original finite numeric value. Invalid references, numeric literals in prose, and common English number words are rejected. Chat retries within its existing request limit and fails visibly when no valid answer is produced. The browser proxy uses this path for chat; other browser features and the native Swift app have not yet adopted it.

This prevents a class of invented numeric strings. It does not prove that the selected metric, units, recommendation, prose, or source data is correct. It is not a complete natural-language claim verifier or a native constrained decoder. Report refusal rates alongside answer accuracy when comparing it with free-form generation; do not replace the existing 51.0% model score with renderer test results.

## Useful upstream contribution to prepare

After the RX 580 test, submit a reproducible compatibility report or documentation PR if the result adds information beyond the existing Vulkan guide. Include OS, kernel, GPU VRAM, Mesa version, Lemonade version/image digest, backend build, exact model quantization, context size, GPU-offload evidence, limitations, and a minimal command sequence. Use the original logs with credentials and private hostnames removed.

No upstream issue, PR, Discord post, or public claim has been sent. The user should review the concrete evidence and intended destination before publication.
