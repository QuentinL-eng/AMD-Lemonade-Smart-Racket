#!/usr/bin/env python3
"""Self-test for wall_speed_fit.py: synthetic hits recover r and k, model B beats A when the incoming speed
varies, a session CSV with known impacts gives the right windows, and too few hits refuse to fit.

    python tools/test_wall_speed_fit.py
"""
import io
import os
import sys
import tempfile

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
import wall_speed_fit as wf  # noqa: E402

HEADER = "time_s,ax_g,ay_g,az_g,gx_rads,gy_rads,gz_rads,hx_g,hy_g,hz_g\n"


def test_recovers_constants():
    w_pre, w_post, v = wf.synth(n=60, seed=3, noise=0.3)
    res = wf.report(list(range(1, 61)), w_pre, w_post, v, out=io.StringIO())
    assert abs(res["B"]["r"] - 1.15) < 0.05, res
    assert abs(res["B"]["k"] - 1.3) < 0.15, res
    assert res["B"]["rms"] < 0.6 * res["A"]["rms"], res


def test_session_windows_and_truth():
    # 1 kHz, 10 hits 1 s apart. Raw gyro x maps to racket y (Calibration.default M), so w_pre/w_post come from gx.
    n = 11000
    rows = np.zeros((n, 10))
    rows[:, 0] = np.arange(n) / 1000.0
    rows[:, 3] = 1.0
    hits = [1000 * (j + 1) for j in range(10)]
    for i in hits:
        rows[i - 20:i, 4] = 20.0
        rows[i:i + 40, 4] = 12.0
        rows[i + 2, 9] = 30.0           # high-g spike; the 3-sample jump puts i0 two samples before it
    with tempfile.TemporaryDirectory() as tmp:
        s, t = os.path.join(tmp, "s.csv"), os.path.join(tmp, "t.csv")
        with open(s, "w") as fh:
            fh.write(HEADER)
            for r in rows:
                fh.write(",".join(f"{x:.4f}" for x in r) + "\n")
        with open(t, "w") as fh:
            fh.write("hit,distance_m,flight_time_s\n1,9.0,0.3\n")
        feats = wf.impact_features(s, gyro_scale=0.5)
        assert len(feats) == 10, len(feats)
        for pre, post in feats:
            assert abs(pre - 10.0) < 1e-3 and abs(post - 6.0) < 1e-3, (pre, post)
        assert abs(wf.read_truth(t)[1] - 30.0) < 1e-9


def test_refuses_few_hits():
    w_pre, w_post, v = wf.synth(n=7)
    try:
        wf.report(list(range(1, 8)), w_pre, w_post, v, out=io.StringIO())
    except ValueError:
        return
    raise AssertionError("fitted with 7 hits")


def main():
    for f in (test_recovers_constants, test_session_windows_and_truth, test_refuses_few_hits):
        f()
    print("ok")


if __name__ == "__main__":
    main()
