#!/usr/bin/env python3
"""Check the racket's USB IMU-window dump: turn collect mode on, wait for hits, print what arrives.

    python tools/listen_imu_test.py [seconds]      # tap the racket face or throw a ball; stops after 3 windows
"""
import sys
import time

import numpy as np
import serial
from serial.tools import list_ports

port = [p.device for p in list_ports.comports() if p.vid == 0x303A][0]
s = serial.Serial(port, 115200, timeout=0.3)
s.read_all(); s.write(b"c"); time.sleep(0.4); s.read_all()
limit = float(sys.argv[1]) if len(sys.argv) > 1 else 180
t = time.time(); n = 0
print(f"collect mode on ({port}); waiting up to {limit:.0f} s for hits", flush=True)
while time.time() - t < limit and n < 3:
    line = s.readline().decode(errors="ignore").strip()
    if line.startswith("IMUWIN,"):
        print(line[:400], flush=True)
    elif line.startswith("IMU,"):
        raw = bytes.fromhex(line[4:])
        a = np.frombuffer(raw, dtype="<i2").reshape(-1, 9)
        n += 1
        print("IMU window", a.shape, "bytes", len(raw), "| high-g peak counts", int(np.abs(a[:, 6:9]).max()),
              "| gyro lsb max", int(np.abs(a[:, 3:6]).max()), "| acc lsb range", int(a[:, 0:3].min()), int(a[:, 0:3].max()), flush=True)
    elif line.startswith(("CLIP_META", "SHOT")):
        print(line[:120], flush=True)
s.write(b"c")
print("done, windows:", n, flush=True)
