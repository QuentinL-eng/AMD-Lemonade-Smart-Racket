#!/usr/bin/env bash
# Builds the racket firmware and copies it into the apps, which offer it as an over-the-air (BLE) update
# whenever the connected racket reports an older version. Run after bumping TB_FW_MINOR in protocol.h.
set -euo pipefail
cd "$(dirname "$0")/.."

PIO=${PIO:-$(command -v pio || ls ~/Library/Python/*/bin/pio 2>/dev/null | tail -1)}
"$PIO" run -e xiao_esp32c3

major=$(awk '/#define TB_FW_MAJOR/ {print $3}' include/protocol.h)
minor=$(awk '/#define TB_FW_MINOR/ {print $3}' include/protocol.h)
out=../apple/Shared/Resources
python3 - "$major.$minor" .pio/build/xiao_esp32c3/firmware.bin "$out" <<'PY'
import hashlib
import json
from pathlib import Path
import sys

version, source, destination = sys.argv[1:]
image = Path(source).read_bytes()
if len(image) <= 1024 or image[0] != 0xE9:
    raise SystemExit("Build did not produce a valid ESP32 application image")
folder = Path(destination)
binary = folder / "RacketFirmware.bin"
metadata = folder / "RacketFirmware.json"
binary.with_suffix(".bin.tmp").write_bytes(image)
metadata.with_suffix(".json.tmp").write_text(json.dumps({
    "version": version, "sha256": hashlib.sha256(image).hexdigest()
}, indent=2) + "\n")
binary.with_suffix(".bin.tmp").replace(binary)
metadata.with_suffix(".json.tmp").replace(metadata)
PY
echo "Bundled firmware $major.$minor ($(wc -c < "$out/RacketFirmware.bin" | tr -d ' ') bytes) into $out"
