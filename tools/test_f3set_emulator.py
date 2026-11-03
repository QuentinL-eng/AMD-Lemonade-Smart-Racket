#!/usr/bin/env python3
"""Tests for f3set_to_emulator.py (synthetic cache, no dataset needed).

Run: python3 -m unittest discover -s tools -p test_f3set_emulator.py
"""
import json
import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(__file__))
import f3set_to_emulator as fe  # noqa: E402


def clip(tmp, name="c", events=None, near_box=True, far_box=False, start=1000):
    """A 100-frame clip whose near racket sweeps right-and-up through frame 50."""
    frames = {}
    for f in range(100):
        recs = []
        if near_box:
            x = 600 + 6 * (f - 50) + (f - 50) ** 2 * 0.05     # accelerating
            y = 500 - 3 * (f - 50)
            recs.append([0, x - 10, y - 25, x + 10, y + 25, 0.9])
        if far_box:
            recs.append([3, 300, 100, 312, 128, 0.8])
        frames[str(f)] = recs
    d = {"clip": name, "start": start, "width": 1280, "height": 720, "n_frames": 100, "frames": frames,
         "events": events if events is not None else [{"frame": 50, "label": "near_deuce_stroke_fh_gs_CC_non-approach_in", "outcome": "in"}]}
    p = os.path.join(tmp, name + ".json")
    json.dump(d, open(p, "w"))
    return p


class Labels(unittest.TestCase):
    def test_parse_f3set_label(self):
        lab = fe.parse_label("far_ad_return_bh_slice_DM_non-approach_forced-err")
        self.assertEqual((lab["hitter"], lab["kind"], lab["hand"], lab["tech"], lab["outcome"]),
                         ("far", "return", "backhand", "slice", "forced-err"))

    def test_unknown_label_degrades(self):
        lab = fe.parse_label("garbage")
        self.assertIsNone(lab["hand"])
        self.assertEqual(fe.app_type(lab), "hit")

    def test_app_type(self):
        self.assertEqual(fe.app_type(fe.parse_label("near_deuce_serve_fh_gs_W_non-approach_in")), "serve")
        self.assertEqual(fe.app_type(fe.parse_label("near_middle_stroke_bh_volley_DM_non-approach_in")), "volley")
        self.assertEqual(fe.app_type(fe.parse_label("near_middle_stroke_bh_gs_CC_non-approach_in")), "backhand")


class Convert(unittest.TestCase):
    def test_profile_shape(self):
        with tempfile.TemporaryDirectory() as tmp:
            s = fe.convert([clip(tmp)])["session"]["shots"][0]
        self.assertEqual(s["stroke"], "forehand")
        self.assertEqual(s["video_t"], 42.0)                 # (clip start 1000 + frame 50) / 25 fps
        self.assertEqual(len(s["prog"]), 25)
        self.assertEqual(s["prog"][fe.HALF], 0.0)           # contact
        self.assertEqual((s["prog"][0], s["prog"][-1]), (-1.0, 1.0))
        self.assertTrue(all(b >= a for a, b in zip(s["prog"], s["prog"][1:])))
        self.assertGreater(s["path_deg"], 0)                  # moving up in the image = low-to-high
        self.assertLessEqual(s["path_deg"], fe.PATH_MAX)

    def test_far_hitter_uses_far_racket_only(self):
        ev = [{"frame": 50, "label": "far_ad_stroke_fh_gs_CC_non-approach_in"}]
        with tempfile.TemporaryDirectory() as tmp:
            s = fe.convert([clip(tmp, events=ev, near_box=True, far_box=False)])["session"]
            self.assertNotIn("prog", s["shots"][0])           # only the near racket was tracked: no profile
            self.assertEqual(s["untracked_events"], 1)
            s = fe.convert([clip(tmp, name="d", events=ev, near_box=True, far_box=True)])["session"]
            self.assertEqual(s["untracked_events"], 1)         # the far racket never moves: still no profile

    def test_clips_are_concatenated_with_gap(self):
        with tempfile.TemporaryDirectory() as tmp:
            a, b = clip(tmp, "a"), clip(tmp, "b")
            sh = fe.convert([a, b])["session"]["shots"]
        self.assertAlmostEqual(sh[1]["t_s"] - sh[0]["t_s"], fe.GAP_S, places=2)
        self.assertEqual([s["index"] for s in sh], [0, 1])

    def test_clips_replay_in_match_order_not_name_order(self):
        with tempfile.TemporaryDirectory() as tmp:
            early = clip(tmp, "m_900_999", start=900)      # starts at frame 900
            late = clip(tmp, "m_10000_10099", start=10000)   # sorts BEFORE it by name, but is later in the match
            sh = fe.convert([late, early])["session"]["shots"]
        self.assertLess(sh[0]["video_t"], sh[1]["video_t"])

    def test_intensity_is_clipped(self):
        with tempfile.TemporaryDirectory() as tmp:
            sh = fe.convert([clip(tmp, "a"), clip(tmp, "b")])["session"]["shots"]
        self.assertTrue(all(0.0 <= s["intensity"] <= 1.0 for s in sh))


if __name__ == "__main__":
    unittest.main()
