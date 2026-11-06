# RX 580 homelab: observed status and resource limits

The Ubuntu 26.04 homelab has an AMD Ryzen 5 2600, 16 GB installed system RAM, and an XFX RX 580 reporting exactly 4 GiB VRAM. The host uses the `amdgpu` driver and Mesa Vulkan drivers 26.0.3. Sudo needs interactive authentication, so installation used the user's existing Docker access and the official Lemonade container.

Image: `ghcr.io/lemonade-sdk/lemonade-server:v2026.45.3`, pinned digest `sha256:7c5da79eb6ddccc65e9477e024db1ac9de4deca5ed45b1cb5840241f0336f72c`. Project container: `tennis-lemonade`. The API is published only on host loopback port 13305; testing from the laptop uses an SSH local forward. GPU device `/dev/dri` and numeric render/video groups are passed through without privileged mode.

## Observed inference

`Qwen3-1.7B-GGUF` (Q4_0) loaded successfully with `--llamacpp vulkan --ctx-size 4096`. Lemonade logged the Vulkan backend, GPU VRAM usage rose to approximately 1.59 GB, and the endpoint answered a short prompt. These observations support GPU use; per-layer offload has not been independently inspected.

The latency probe used one warmup followed by five repeated requests to "Reply with the word ready." The measured requests returned "Ready." and reused prompt cache. Total response latency, including the SSH/network transport, had a median of approximately 0.185 seconds. This is a tiny cached smoke test, not an agent response-time benchmark. It does not establish validation accuracy on the RX 580. Reproduce the method with `tools/lemonade_bench.py`, keeping the raw runs and errors.

## Resource caution and current stopped state

After the user reported unexplained historical shutdowns, the project container was stopped. Automatic restart is disabled. Future limits are 0.5 CPU, 2 GiB RAM, total memory-plus-swap 2 GiB (no container swap), and 128 PIDs. The initial successful smoke test used 2 CPUs and a 4 GiB RAM limit; it has not been repeated under the tighter limits.

After stopping, CPU temperature was around 60°C, GPU temperature 45°C, available memory around 8.9 GB, and swap occupancy around 3 GB. Previous-boot logs contain container cgroup OOM events; those do not establish why the entire server shut down. No full agent evaluation or stress test was started. Thermal, power-supply, and cooling faults remain unproven.

`tools/homelab_watch.py` provides a maximum 60-second test window. It refuses missing sensors, stops the project container if CPU or GPU temperature reaches 75°C or available host memory drops below 4 GiB, and stops it at the end of the window. These are conservative project limits, not manufacturer ratings. Run it on the host, with `--start` only for a planned short test. Software monitoring cannot guarantee protection against power or hardware faults. Do not run a long RX 580 validation batch until the host's shutdown cause and cooling are better understood.
