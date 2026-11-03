"""Unit tests for tools/agent_eval.py scoring (no API calls).

Run: python3 -m unittest discover -s tools -p test_agent_eval.py
"""
import json
import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import agent_eval as ev  # noqa: E402


def ref(kind="no_motion", chosen=None, objective=None):
    return {"metadata": {"kind": kind, "chosen": chosen, "objective": objective}}


def sim_result():
    return {"before": {"ball_speed": 150}, "after": {"ball_speed": 151}}


class Scorer(unittest.TestCase):
    def test_grounded_matches_rounded_and_close(self):
        self.assertEqual(ev.grounded("goes to about 151 km/h", [150.0, 151.3]), [])
        self.assertEqual(ev.grounded("holds at 1,070 rpm", [1066.0]), [])
        self.assertEqual(ev.grounded("capped at 30 percent", [30.0]), [])

    def test_grounded_flags_foreign_numbers(self):
        self.assertEqual(ev.grounded("try 45 degrees", [30.0, 15.0]), [45.0])

    def test_question_numbers_are_legitimate(self):
        q = "What if I open the face 45 degrees?"
        messages = [{"role": "user", "content": q},
                    {"role": "assistant", "content": "Opening 45 degrees is beyond the tool."}]
        s, _ = ev.score(ref(), messages, [], [])
        self.assertEqual(s["ungrounded_numbers"], [])

    def test_estimate_required_only_when_simulated(self):
        digest = {"role": "tool", "content": json.dumps({"digest": {}})}
        no_sim = [{"role": "user", "content": "Why no data?"},
                  {"role": "assistant", "content": "No usable motion shots."}, digest]
        s, _ = ev.score(ref(), no_sim, ["get_session_digest"], [])
        self.assertTrue(s["estimate_ok"])
        yes_sim = [{"role": "user", "content": "More spin?"},
                   {"role": "assistant", "content": "Ball speed goes to 151 km/h."},
                   {"role": "tool", "content": json.dumps(sim_result())}]
        s, _ = ev.score(ref(), yes_sim, ["get_session_digest", "simulate_change"], [151.0])
        self.assertTrue(s["simulated"])
        self.assertFalse(s["estimate_ok"])
        yes_sim[1]["content"] = "Estimated: ball speed goes to 151 km/h."
        s, _ = ev.score(ref(), yes_sim, ["get_session_digest", "simulate_change"], [151.0])
        self.assertTrue(s["estimate_ok"])

    def test_digest_first_and_unknown_tools(self):
        messages = [{"role": "user", "content": "Hi"},
                    {"role": "assistant", "content": "Estimated fine."}]
        s, _ = ev.score(ref(), messages, ["get_session_digest"], [])
        self.assertTrue(s["digest_first"])
        self.assertEqual(s["unknown_tools"], [])
        s, _ = ev.score(ref(), messages, ["read_live_sensors"], [])
        self.assertFalse(s["digest_first"])
        self.assertEqual(s["unknown_tools"], ["read_live_sensors"])


if __name__ == "__main__":
    unittest.main()
