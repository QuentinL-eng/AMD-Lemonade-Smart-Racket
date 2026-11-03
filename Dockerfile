# Tennis Buddee: reproducible ML/eval slice.
# Builds the Python core (sweet-spot parity, what-if simulator, tool checks)
# with no Xcode, firmware toolchain, or racket hardware needed.
# The iOS/Mac apps, ESP32 firmware, and BLE hardware path are NOT in this
# image; see README.md and JUDGING.md for those.
FROM python:3.12-slim
WORKDIR /repo
RUN pip install --no-cache-dir numpy scipy
COPY ml/ ml/
COPY tools/ tools/
CMD ["sh", "-c", "python3 ml/test_parity.py && python3 -m unittest discover -s ml -p test_whatif_synth.py && python3 -m unittest discover -s tools -p 'test_*.py'"]
