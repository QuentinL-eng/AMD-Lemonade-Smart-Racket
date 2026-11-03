#!/usr/bin/env python3
"""Tests for sam_clip_hits.py contact detection (synthetic audio, no API).

Run: python3 -m unittest discover -s tools -p test_sam_clip_hits.py
"""
import os
import sys
import unittest

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
import sam_clip_hits as sc  # noqa: E402

SR = 16000


def synth(hits, dur=20.0, seed=11):
    rng = np.random.RandomState(seed)
    y = 0.02 * rng.randn(int(dur * SR))          # crowd bed
    y += 0.05 * np.sin(2 * np.pi * 220 * np.arange(len(y)) / SR)  # commentary-ish hum
    for t in hits:                                # sharp broadband cracks
        i = int(t * SR)
        y[i:i + 80] += 0.9 * np.exp(-np.arange(80) / 12) * rng.randn(80)
    return y


class Detector(unittest.TestCase):
    def test_finds_synthetic_hits(self):
        truth = [2.0, 5.0, 9.0, 14.0]
        got = sc.find_contacts(synth(truth), SR)
        self.assertEqual(len(got), len(truth))
        for g, t in zip(got, truth):
            self.assertLess(abs(g - t), 0.1)

    def test_slow_swells_ignored(self):
        y = 0.02 * np.random.RandomState(3).randn(20 * SR)
        y += 0.4 * np.sin(2 * np.pi * 0.5 * np.arange(len(y)) / SR) ** 2  # slow crowd swell
        self.assertEqual(sc.find_contacts(y, SR), [])

    def test_windows_merge_overlaps(self):
        wins = sc.windows([10.0, 10.8, 20.0], 30.0)
        self.assertEqual(len(wins), 2)
        self.assertEqual(wins[0][2], [10.0, 10.8])
        self.assertEqual(wins[1][2], [20.0])

    def test_windows_clamped_to_duration(self):
        (s, e, _), = sc.windows([0.3], 30.0)
        self.assertEqual(s, 0.0)
        self.assertGreater(e, 1.0)


if __name__ == "__main__":
    unittest.main()
