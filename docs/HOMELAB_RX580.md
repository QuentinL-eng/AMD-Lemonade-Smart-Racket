# RX 580 homelab: observed status and resource limits

The Ubuntu 26.04 homelab has an AMD Ryzen 5 2600, 16 GB installed system RAM, and an XFX RX 580 reporting exactly 4 GiB VRAM. The host uses the `amdgpu` driver and Mesa Vulkan drivers 26.0.3. Sudo needs interactive authentication, so installation used the user's existing Docker access and the official Lemonade container.

Image: `ghcr.io/lemonade-sdk/lemonade-server:v2026.45.3`, pinned digest `sha256:7c5da79eb6ddccc65e9477e024db1ac9de4deca5ed45b1cb5840241f0336f72c`. Project container: `tennis-lemonade`. The API is published only on host loopback port 13305; testing from the laptop uses an SSH local forward. GPU device `/dev/dri` and numeric render/video groups are passed through without privileged mode.

## Observed inference

`Qwen3-1.7B-GGUF` (Q4_0) loaded successfully with `--llamacpp vulkan --ctx-size 4096`. Lemonade logged the Vulkan backend, GPU VRAM usage rose to approximately 1.59 GB, and the endpoint answered a short prompt. These observations support GPU use; per-layer offload has not been independently inspected.

The latency probe used one warmup followed by five repeated requests to "Reply with the word ready." The measured requests returned "Ready." and reused prompt cache. Total response latency, including the SSH/network transport, had a median of approximately 0.185 seconds. This is a tiny cached smoke test, not an agent response-time benchmark. It does not establish validation accuracy on the RX 580. Reproduce the method with `tools/lemonade_bench.py`, keeping the raw runs and errors.

## Resource caution and current stopped state

After the user reported unexplained historical shutdowns, the project container was stopped. Automatic restart is disabled. Limits are 0.5 CPU, 2 GiB RAM, total memory-plus-swap 2 GiB (no container swap), and 128 PIDs. The initial successful smoke test used 2 CPUs and a 4 GiB RAM limit. A later explicitly authorized, monitored test succeeded under the tighter limits with a smaller context, as recorded below.

After stopping, CPU temperature was around 60°C, GPU temperature 45°C, available memory around 8.9 GB, and swap occupancy around 3 GB. Previous-boot logs contain container cgroup OOM events; those do not establish why the entire server shut down. No full agent evaluation or stress test was started. Thermal, power-supply, and cooling faults remain unproven.

`tools/homelab_watch.py` provides a maximum 60-second test window. It refuses missing sensors, stops the project container if CPU or GPU temperature reaches 75°C or available host memory drops below 4 GiB, and stops it at the end of the window. These are conservative project limits, not manufacturer ratings. Run it on the host, with `--start` only for a planned short test. Software monitoring cannot guarantee protection against power or hardware faults. Do not run a long RX 580 validation batch until the host's shutdown cause and cooling are better understood.

## Bounded retest, November 5, 2026 (Pacific time)

With the user's explicit authorization, the watchdog ran for 45 seconds at one-second sampling. The model loaded with Vulkan and a 1,024-token context under the tighter limits. One request, capped at 16 completion tokens, returned "Ready." using three completion tokens. End-to-end response latency through the existing SSH forward was approximately 0.273 seconds. No warmup or further requests were sent.

Observed maximum CPU temperature was 74.75°C, maximum GPU temperature 51°C, and minimum available host memory 9,096 MiB. Docker reported no container OOM kill. The watchdog stopped the container at the end of its window; it remains stopped with automatic restart disabled. Container peak RAM was not captured. The CPU peak is close to the 75°C abort threshold, and other host workloads may have contributed. No sustained-stability or thermal-causation conclusion follows from this short test; further load testing is paused. Raw response and monitoring summary: [rx580-bounded-test.json](../evaluation/rx580-bounded-test.json).

Procedure: run `python3 homelab_watch.py --start --seconds 45` on the host; while monitored, load the model with `docker exec tennis-lemonade lemonade load Qwen3-1.7B-GGUF --llamacpp vulkan --ctx-size 1024`, then send a single non-thinking chat-completions request with `max_completion_tokens: 16`, `temperature: 0`, and the prompt recorded in the JSON. The watchdog must remain active throughout. The final state must be stopped.
