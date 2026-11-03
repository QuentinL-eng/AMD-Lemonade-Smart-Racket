#!/usr/bin/env python3
"""Tests for sam_model_windows.py planning and model_events_to_emulator.py (synthetic cache, no API).

Run: python3 -m unittest discover -s tools -p test_model_events.py
"""
import json
import os
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(__file__))
import model_events_to_emulator as me  # noqa: E402
import sam_model_windows as sw  # noqa: E402


def ev(t, typ="forehand", hitter="near", conf=0.95):
    return {"t_s": t, "type": typ, "hitter": hitter, "conf": conf, "peak": 0.9}


class Planning(unittest.TestCase):
    def test_close_hits_merge_into_one_window(self):
        w = sw.windows([ev(10.0), ev(11.5), ev(30.0)], dur=100)
        self.assertEqual(len(w), 2)
        self.assertEqual(len(w[0][2]), 2)

    def test_plan_stays_inside_budget_and_spreads_out(self):
        wins = sw.windows([ev(5.0 * i) for i in range(1, 40)], dur=300)
        pick = sw.plan(wins, frame_budget=1000)
        self.assertLessEqual(sum(sw.cost_frames(wins[i]) for i in pick), 1000)
        self.assertGreater(pick[-1] - pick[0], len(wins) // 2)      # spans the match, not just the start

    def test_plan_takes_everything_when_it_fits(self):
        wins = sw.windows([ev(5.0 * i) for i in range(1, 5)], dur=100)
        self.assertEqual(sw.plan(wins, frame_budget=10 ** 6), list(range(len(wins))))

    def test_minimum_billing_is_50_frames(self):
        self.assertGreaterEqual(sw.cost_frames((0.0, 0.5, [])), 50)


def cache(tmp, slug="nadal", events=None, near=True):
    """100-frame window, near racket accelerating up-right through frame 50."""
    d = os.path.join(tmp, slug, "sam_video")
    os.makedirs(d, exist_ok=True)
    frames = {}
    for f in range(100):
        x = 600 + 6 * (f - 50) + (f - 50) ** 2 * 0.05
        frames[str(f)] = [[0, x - 10, 475 - 3 * (f - 50), x + 10, 525 - 3 * (f - 50), 0.9]] if near else []
    evs = events if events is not None else [{"frame": 50, "label": "hit", "type": "backhand", "hitter": "near", "conf": 0.91, "peak": 0.9}]
    with open(os.path.join(d, f"{slug}_0000.json"), "w") as fh:
        json.dump({"clip": f"{slug}_0000", "start": 0, "events": evs, "width": 1280, "height": 720,
                   "n_frames": 100, "billed": 100, "frames": frames}, fh)
    return os.path.join(tmp, slug)


class Convert(unittest.TestCase):
    def test_hit_is_flagged_predicted_with_model_fields(self):
        with tempfile.TemporaryDirectory() as tmp:
            pl = me.convert_dir("rafael_nadal", cache(tmp, "rafael_nadal"))
        s = pl["session"]["shots"][0]
        self.assertTrue(pl["predicted"] and s["predicted"] and pl["session"]["provenance"]["predicted"])
        self.assertEqual((s["stroke"], s["hitter"], s["side_source"]), ("backhand", "near", "model_prediction"))
        self.assertEqual(s["conf"], 0.91)
        self.assertIsNone(s["outcome"])                           # the model predicts no outcomes
        self.assertEqual(len(s["prog"]), 25)
        self.assertEqual(pl["name"], me.MATCHES["rafael_nadal"][0])   # named by match, not by one player

    def test_unknown_type_or_hitter_is_skipped(self):
        evs = [{"frame": 50, "label": "hit", "type": "smash", "hitter": "near", "conf": 0.9, "peak": 0.9},
               {"frame": 60, "label": "hit", "type": "forehand", "hitter": None, "conf": 0.9, "peak": 0.9}]
        with tempfile.TemporaryDirectory() as tmp:
            pl = me.convert_dir("x", cache(tmp, "x", events=evs))
        self.assertEqual(pl["session"]["shots"], [])

    def test_untracked_hit_keeps_its_type_without_a_profile(self):
        with tempfile.TemporaryDirectory() as tmp:
            pl = me.convert_dir("x", cache(tmp, "x", near=False))
        s = pl["session"]["shots"][0]
        self.assertEqual(s["stroke"], "backhand")
        self.assertNotIn("prog", s)
        self.assertEqual(pl["session"]["untracked_events"], 1)


if __name__ == "__main__":
    unittest.main()
