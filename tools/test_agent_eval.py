"""Unit tests for tools/agent_eval.py scoring (no API calls).

Run: python3 -m unittest discover -s tools -p test_agent_eval.py
"""
import json
import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "ml"))
import agent_eval as ev  # noqa: E402
import coach_sim as cs  # noqa: E402


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

    def test_grounded_allows_rounding_like_the_dataset(self):
        self.assertEqual(ev.grounded("1.78 cm toward the handle", [1.8]), [])
        self.assertEqual(ev.grounded("contact -2.364 cm", [-2.4]), [])

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
        s, _ = ev.score(ref(), messages, ["bogus_tool"], [])
        self.assertFalse(s["digest_first"])
        self.assertEqual(s["unknown_tools"], ["bogus_tool"])
        s, _ = ev.score(ref(), messages, list(ev.KNOWN_TOOLS), [])
        self.assertEqual(s["unknown_tools"], [])

    def test_goal_case_without_simulation_fails_target(self):
        r = ref("objective", {"path_deg": 8}, "more_spin")
        messages = [{"role": "user", "content": "More spin?"},
                    {"role": "assistant", "content": "Swing up more."}]
        s, _ = ev.score(r, messages, ["get_session_digest"], [])
        self.assertFalse(s["target"])
        sim = {"before": {"ball_speed": 100, "spin_rpm": 1000},
               "after": {"ball_speed": 100, "spin_rpm": 1500,
                         "applied_parameters": {"contactXcm": 0, "contactYcm": 0}}}
        with_sim = messages + [{"role": "tool", "content": json.dumps(sim)}]
        s, _ = ev.score(r, with_sim, ["get_session_digest", "simulate_change"], [])
        self.assertTrue(s["target"])
        self.assertEqual(s["last_sim"]["after_spin"], 1500)


def fixture():
    s1 = cs.Session("s1", "2026-10-28T19:00:00Z", 3600, [
        cs.Shot("forehand", 100, 150, 2000, "topspin", 0, 20, 1, 2),
        cs.Shot.from_mic(False, 50), cs.Shot("backhand", 90, 140, 1500, "topspin", 1, 18, -1, -1)])
    s2 = cs.Session("s2", "2026-10-29T19:00:00Z", 3600, [
        cs.Shot("forehand", 110, 160, 2100, "topspin", 0, 22, 0, 1)])
    return s2, [s1, s2], cs.Units(), cs.NoteStore()


class Dispatch(unittest.TestCase):
    def test_resolve_current_latest_previous_uuid(self):
        s2, catalog, _, _ = fixture()
        self.assertIs(cs.resolve_session(None, s2, catalog), s2)
        self.assertIs(cs.resolve_session("current", s2, catalog), s2)
        self.assertIs(cs.resolve_session("latest", s2, catalog), s2)
        self.assertEqual(cs.resolve_session("previous", s2, catalog).id, "s1")
        self.assertEqual(cs.resolve_session("S1", s2, catalog).id, "s1")
        with self.assertRaises(cs.ToolError):
            cs.resolve_session("bogus", s2, catalog)

    def test_list_shots_filters_orders_and_limits(self):
        s2, catalog, units, notes = fixture()
        newest = ev.dispatch_tool("list_shots", {}, s2, catalog, units, notes)
        self.assertEqual([s["type"] for s in newest["shots"]], ["forehand"])
        all_old = ev.dispatch_tool("list_shots", {"session": "all", "order": "oldest", "limit": 50},
                                   s2, catalog, units, notes)
        self.assertEqual(all_old["matching"], 4)
        self.assertEqual(all_old["shots"][0]["time"], "2026-10-28T19:00:00Z")
        mic = next(s for s in all_old["shots"] if not s["has_motion"])
        self.assertIsNone(mic["ball_speed"])
        self.assertEqual(ev.dispatch_tool("list_shots", {"type": "backhand"}, s2, catalog, units, notes)
                         ["matching"], 0)
        sweet = ev.dispatch_tool("list_shots", {"session": "all", "contact": "sweet_spot"},
                                 s2, catalog, units, notes)
        self.assertTrue(all(s["sweet_spot"] for s in sweet["shots"]))
        one = ev.dispatch_tool("list_shots", {"session": "all", "limit": 0}, s2, catalog, units, notes)
        self.assertEqual(one["returned"], 1)

    def test_list_shots_date_window(self):
        s2, catalog, units, notes = fixture()
        narrow = ev.dispatch_tool("list_shots", {"session": "all", "from": "2026-10-29T19:00:00Z"},
                                  s2, catalog, units, notes)
        self.assertEqual(narrow["matching"], 1)
        bad = ev.dispatch_tool("list_shots", {"from": "yesterday"}, s2, catalog, units, notes)
        self.assertIn("ISO 8601", bad["error"])
        flipped = ev.dispatch_tool(
            "list_shots", {"from": "2026-10-29T19:00:00Z", "to": "2026-10-28T19:00:00Z"},
            s2, catalog, units, notes)
        self.assertIn("precede", flipped["error"])

    def test_query_shots_aggregates(self):
        s2, catalog, units, notes = fixture()
        q = ev.dispatch_tool("query_shots", {"session": "all"}, s2, catalog, units, notes)
        self.assertEqual((q["count"], q["motion_count"]), (4, 3))
        self.assertEqual(q["metrics"]["ball_speed"]["samples"], 3)
        self.assertAlmostEqual(q["metrics"]["ball_speed"]["mean"], 150.0)
        one = ev.dispatch_tool("query_shots", {"metric": "spin"}, s2, catalog, units, notes)
        self.assertEqual(list(one["metrics"]), ["spin"])
        bad = ev.dispatch_tool("query_shots", {"metric": "bogus"}, s2, catalog, units, notes)
        self.assertIn("Invalid metric", bad["error"])

    def test_compare_sessions_needs_both_and_diffs(self):
        s2, catalog, units, notes = fixture()
        missing = ev.dispatch_tool("compare_sessions", {"a": "previous"}, s2, catalog, units, notes)
        self.assertIn("Missing argument: b", missing["error"])
        c = ev.dispatch_tool("compare_sessions", {"a": "previous", "b": "current"},
                             s2, catalog, units, notes)
        self.assertAlmostEqual(c["b_minus_a"]["ball_speed"]["value"], 15.0)
        self.assertEqual(c["a"]["session_id"], "s1")

    def test_digest_and_simulate_honor_session(self):
        s2, catalog, units, notes = fixture()
        d = ev.dispatch_tool("get_session_digest", {"session": "previous"}, s2, catalog, units, notes)
        self.assertEqual(d["digest"]["session_id"], "s1")
        merged = ev.dispatch_tool("simulate_change", {"session": "all", "path_deg": 5},
                                  s2, catalog, units, notes)
        self.assertEqual(merged["sample_count"], 3)

    def test_notes_round_trip_and_limits(self):
        s2, catalog, units, notes = fixture()
        empty = ev.dispatch_tool("recall_notes", {}, s2, catalog, units, notes)
        self.assertEqual(empty["matching"], 0)
        saved = ev.dispatch_tool("remember_note", {"text": "Rushes the backhand when tired.",
                                                   "category": "technique"}, s2, catalog, units, notes)
        self.assertTrue(saved["saved"])
        dup = ev.dispatch_tool("remember_note", {"text": "rushes the BACKHAND when tired.",
                                                 "category": "technique"}, s2, catalog, units, notes)
        self.assertFalse(dup["saved"])
        found = ev.dispatch_tool("recall_notes", {"query": "backhand tired"}, s2, catalog, units, notes)
        self.assertEqual(found["matching"], 1)
        ev.dispatch_tool("remember_note", {"text": "Second lasting habit here.",
                                           "category": "goal"}, s2, catalog, units, notes)
        capped = ev.dispatch_tool("remember_note", {"text": "Third note is too many.",
                                                    "category": "goal"}, s2, catalog, units, notes)
        self.assertIn("limit", capped["error"])
        short = ev.dispatch_tool("remember_note", {"text": "no", "category": "goal"},
                                 s2, catalog, units, cs.NoteStore())
        self.assertIn("3 to 240", short["error"])

    def test_validation_mirrors_the_app(self):
        s2, catalog, units, notes = fixture()
        self.assertIn("Unknown tool", ev.dispatch_tool("bogus", {}, s2, catalog, units, notes)["error"])
        self.assertIn("Unknown tool", ev.dispatch_tool("list_shots", None, s2, catalog, units, notes)["error"])
        bad_arg = ev.dispatch_tool("list_shots", {"bogus": 1}, s2, catalog, units, notes)
        self.assertIn("Unknown argument", bad_arg["error"])
        bad_enum = ev.dispatch_tool("query_shots", {"type": "bogus"}, s2, catalog, units, notes)
        self.assertIn("Invalid type", bad_enum["error"])
        bad_num = ev.dispatch_tool("simulate_change", {"face_deg": True}, s2, catalog, units, notes)
        self.assertIn("finite number", bad_num["error"])
        bad_str = ev.dispatch_tool("list_shots", {"session": 7}, s2, catalog, units, notes)
        self.assertIn("must be a string", bad_str["error"])
        missing = ev.dispatch_tool("remember_note", {"text": "abc"}, s2, catalog, units, notes)
        self.assertIn("Missing argument: category", missing["error"])

    def test_live_tools_report_no_racket(self):
        s2, catalog, units, notes = fixture()
        for name in ("get_live_state", "read_live_sensors", "get_racket_status"):
            self.assertIn("unavailable", ev.dispatch_tool(name, {}, s2, catalog, units, notes)["error"])


if __name__ == "__main__":
    unittest.main()
