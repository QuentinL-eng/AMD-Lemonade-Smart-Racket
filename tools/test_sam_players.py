#!/usr/bin/env python3
"""Tests for sam_players_to_emulator.py (fixture cache, no API).

Run: python3 -m unittest discover -s tools -p test_sam_players.py
"""
import json
import os
import shutil
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(__file__))
import sam_players_to_emulator as sp  # noqa: E402

FIX = os.path.join(os.path.dirname(__file__), "fixtures", "sam_track_sample.json")


def make_player(tmp, name="Test Player"):
    d = os.path.join(tmp, "p1")
    os.makedirs(os.path.join(d, "sam_video"))
    shutil.copy(FIX, os.path.join(d, "sam_video", "clip.json"))
    shutil.copy(FIX, os.path.join(d, "sam_video", "clip2.json"))
    json.dump({"player": name, "url": "https://example.invalid/v",
               "title": "Test Final", "uploader": "Test TV"},
              open(os.path.join(d, "source.json"), "w"))
    return d


class Assemble(unittest.TestCase):
    def test_merges_provenance_and_shots(self):
        with tempfile.TemporaryDirectory() as tmp:
            p = sp.assemble(make_player(tmp))
            self.assertEqual(p["name"], "Test Player")
            self.assertEqual(p["video_url"], "https://example.invalid/v")
            self.assertEqual(len(p["session"]["shots"]), 4)
            self.assertIn("time_note", p["session"])
            self.assertIn("contact_point", p["session"]["omitted"])

    def test_windows_concatenated_with_gaps(self):
        with tempfile.TemporaryDirectory() as tmp:
            shots = sp.assemble(make_player(tmp))["session"]["shots"]
            ts = [s["t_s"] for s in shots]
            # fixture windows hold shots 4 s apart; second window starts 3 s after
            self.assertEqual(ts, [0.0, 4.0, 7.0, 11.0])

    def test_intensity_renormalized_across_player(self):
        with tempfile.TemporaryDirectory() as tmp:
            shots = sp.assemble(make_player(tmp))["session"]["shots"]
            inten = [s["intensity"] for s in shots]
            self.assertTrue(all(0.0 <= v <= 1.0 for v in inten))
            self.assertEqual(max(inten), 1.0)
            self.assertEqual([s["index"] for s in shots], [0, 1, 2, 3])


if __name__ == "__main__":
    unittest.main()
