#!/usr/bin/env python3
"""Tests for sam_track_to_session.py (offline, uses tools/fixtures/).

Run: python3 -m unittest discover -s tools -p test_sam_track_session.py
"""
import json
import os
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, os.path.dirname(__file__))
import sam_track_to_session as st  # noqa: E402

FIX = os.path.join(os.path.dirname(__file__), "fixtures", "sam_track_sample.json")


class Labels(unittest.TestCase):
    def test_kind_and_side_from_tokens(self):
        self.assertEqual(st.parse_label("shot_near_stroke_forehand_01"), ("stroke", "forehand"))
        self.assertEqual(st.parse_label("x_serve_backhand"), ("serve", "backhand"))

    def test_unknown_format_degrades_to_none(self):
        self.assertEqual(st.parse_label("weird-format"), (None, None))
        self.assertEqual(st.parse_label(""), (None, None))


class Convert(unittest.TestCase):
    def test_intensity_normalized_and_hardest_is_one(self):
        s = st.convert(FIX)
        inten = [sh["intensity"] for sh in s["shots"]]
        self.assertTrue(all(0.0 <= v <= 1.0 for v in inten))
        self.assertEqual(max(inten), 1.0)
        self.assertGreater(len(s["shots"]), 1)

    def test_side_only_from_labels(self):
        s = st.convert(FIX)
        for sh in s["shots"]:
            if sh["side"] == "unknown":
                self.assertEqual(sh["side_source"], "none")
            else:
                self.assertEqual(sh["side_source"], "dataset_label")

    def test_unobservable_quantities_omitted(self):
        s = st.convert(FIX)
        self.assertIn("contact_point", s["omitted"])
        for sh in s["shots"]:
            for k in s["omitted"]:
                self.assertNotIn(k, sh)

    def test_events_without_coverage_are_skipped(self):
        s = st.convert(FIX)
        self.assertEqual(s["skipped_events"], 1)
        self.assertEqual(len(s["shots"]), 2)

    def test_cli_writes_valid_session(self):
        with tempfile.TemporaryDirectory() as tmp:
            out = os.path.join(tmp, "s.json")
            r = subprocess.run([sys.executable, os.path.join(os.path.dirname(__file__),
                               "sam_track_to_session.py"), FIX, "-o", out],
                               capture_output=True, text=True)
            self.assertEqual(r.returncode, 0, r.stderr)
            d = json.load(open(out))
            self.assertEqual(len(d["shots"]), 2)
            self.assertIn("fps_assumed", d["provenance"])


if __name__ == "__main__":
    unittest.main()
