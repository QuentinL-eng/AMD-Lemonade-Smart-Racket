"""Integrity/regression tests. Synthetic fixtures are not field accuracy evidence."""
import csv
import json
from pathlib import Path
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

import joblib
import numpy as np
from sklearn.ensemble import ExtraTreesClassifier

from .dataset import FIELDS, HEADER, load_manifest
from .features import VERSION, extract, validate_window
from .orientation import gravity_body
from .predict import infer
from .speed import fit_radius, summarize
from .train import evaluate, run
from .evaluate_camera import pair_detections, match_sensor_contacts
from .import_impact_csv import split_windows, inspect_window, face_sign_diagnostic


def fixture(folder):
    rows = []
    for j, split in enumerate(["train", "validation", "test"]):
        t = np.arange(0, 3.6, .001)
        data = np.zeros((len(t), 10))
        data[:, 0] = t
        data[:, 3] = 1
        for k, label in enumerate(["forehand", "backhand", "serve", "volley"]):
            contact = .5+k*.8
            active = abs(t-contact) < .38
            # Deliberately obvious distinct classes for pipeline smoke testing.
            data[active, 4+k%3] = (k+1)*3+.01*j
            data[active, 1] = k*.5+.001*j
            rows.append({"recording": f"{split}.csv", "player_id": "fixture-player", "session_id": split,
                         "split": split, "shot_type": label, "contact_s": str(contact),
                         "gyro_scale": "1", "mount_id": "fixture-mount", "verified_by": "synthetic-test",
                         "provenance": "real_racket"})  # Emulated schema only; temp fixtures never become evidence.
        np.savetxt(folder/f"{split}.csv", data, delimiter=",", header=",".join(HEADER), comments="")
    manifest = folder/"events.csv"
    write_rows(manifest, rows)
    return manifest, rows


def write_rows(path, rows):
    with path.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=FIELDS)
        w.writeheader(); w.writerows(rows)


class FeatureTests(unittest.TestCase):
    def setUp(self):
        self.t = np.arange(-.4, .101, .001)
        self.a = np.tile([0., 0., 1.], (len(self.t), 1))
        self.w = np.column_stack([self.t, self.t**2, np.ones(len(self.t))*2])

    def test_rotational_invariants_and_finite_output(self):
        q, _ = np.linalg.qr(np.random.default_rng(31).normal(size=(3, 3)))
        if np.linalg.det(q) < 0:
            q[:, 0] *= -1
        np.testing.assert_allclose(extract(self.t, self.a, self.w, True),
                                   extract(self.t, self.a@q, self.w@q, True), atol=1e-5)
        self.assertTrue(np.isfinite(extract(self.t, self.a, self.w)).all())

    def test_large_gaps_rejected_before_interpolation(self):
        keep = ~((self.t > -.1) & (self.t < -.05))
        with self.assertRaisesRegex(ValueError, "gap"):
            extract(self.t[keep], self.a[keep], self.w[keep])

    def test_nonfinite_duplicate_and_short_windows_rejected(self):
        for t in [self.t[::-1], np.zeros(len(self.t)), self.t+10]:
            with self.assertRaises(ValueError):
                extract(t, self.a, self.w)
        a = self.a.copy(); a[10, 0] = np.nan
        with self.assertRaises(ValueError):
            extract(self.t, a, self.w)

    def test_antiparallel_gravity_initialization(self):
        up = gravity_body(self.t, -self.a, self.w*0)
        np.testing.assert_allclose(up, -self.a, atol=1e-6)

    def test_causal_orientation_known_rotation(self):
        a = self.a.copy()
        w = np.tile([4., 0., 0.], (len(self.t), 1))
        up = gravity_body(self.t, a, w)
        angle = 4*(.001+self.t-self.t[0])
        expected = np.column_stack([angle*0, np.sin(angle), np.cos(angle)])
        np.testing.assert_allclose(up, expected, atol=1e-6)

    def test_inference_rejects_mount_mismatch_and_bad_data(self):
        bundle = {"feature_version": VERSION, "mount_id": "correct", "gravity": False}
        self.assertEqual(infer(bundle, self.t, self.a, self.w, "wrong")["shot_type"], "unknown")
        self.assertEqual(infer(bundle, self.t+10, self.a, self.w, "correct")["shot_type"], "unknown")


class DatasetTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.folder = Path(self.temp.name)
        self.manifest, self.rows = fixture(self.folder)

    def tearDown(self):
        self.temp.cleanup()

    def test_valid_manifest_keeps_all_rows(self):
        rows = load_manifest(self.manifest)
        self.assertEqual(len(rows), 12)
        self.assertTrue(all(r["features"] is not None for r in rows))

    def test_session_leakage_rejected(self):
        self.rows[4]["session_id"] = "train"
        write_rows(self.manifest, self.rows)
        with self.assertRaisesRegex(ValueError, "crosses splits"):
            load_manifest(self.manifest)

    def test_copying_recordings_does_not_bypass_split(self):
        (self.folder/"validation.csv").write_bytes((self.folder/"train.csv").read_bytes())
        with self.assertRaisesRegex(ValueError, "Identical recording crosses"):
            load_manifest(self.manifest)

    def test_player_leakage_rejected_in_general_model(self):
        with self.assertRaisesRegex(ValueError, "Player crosses splits"):
            load_manifest(self.manifest, "player-independent")

    def test_external_or_robot_cannot_be_acceptance_data(self):
        self.rows[-1]["provenance"] = "robot"
        write_rows(self.manifest, self.rows)
        with self.assertRaisesRegex(ValueError, "only real_racket"):
            load_manifest(self.manifest)

    def test_unknown_counts_as_error(self):
        rows = [{"shot_type": c, "reject": "gap" if i == 0 else None}
                for i, c in enumerate(["forehand", "backhand", "serve", "volley"])]
        result = evaluate(rows, np.array(["unknown", "backhand", "serve", "volley"]))
        self.assertEqual(result["accuracy"], .75)
        self.assertEqual(result["unknown_count"], 1)
        self.assertEqual(result["per_class"]["forehand"]["recall"], 0)

    def test_end_to_end_train_save_infer(self):
        args = SimpleNamespace(manifest=self.manifest, mode="personalized", output=self.folder/"run")
        with patch("ml.stroke_system.train.candidates", return_value={
                "fixture-tree": ExtraTreesClassifier(n_estimators=20, random_state=3)}):
            result = run(args)
        bundle = joblib.load(args.output/"model.joblib")
        row = load_manifest(self.manifest)[-1]
        w = row["window"]
        prediction = infer(bundle, w[:, 0], w[:, 1:4], w[:, 4:7], "fixture-mount")
        self.assertIn(prediction["shot_type"], bundle["classes"])
        self.assertEqual(json.loads((args.output/"metrics.json").read_text())["test"]["n"], 4)
        self.assertEqual(result["test"]["unknown_count"], 0)


class SpeedTests(unittest.TestCase):
    def test_physical_fit_and_missing_prediction_denominator(self):
        x = np.array([[2., 1.], [4., 2.], [6., 1.]])
        y = .8*(x[:, 0]+1.2*x[:, 1])
        self.assertAlmostEqual(fit_radius(x, y, 1.2), .8)
        score = summarize(np.array([10., 10.]), np.array([10., np.nan]))
        self.assertEqual(score["fraction_of_all_reference_hits_within_5_percent"], .5)


class EventMatchingTests(unittest.TestCase):
    def test_detections_match_one_to_one_and_missing_contacts_remain_missing(self):
        pairs = pair_detections([1., 1.02, 3.], [1.01, np.nan, 3.01])
        self.assertEqual(len(pairs), 2)
        self.assertEqual(len({p[1] for p in pairs}), 2)
        self.assertNotIn(1, {p[1] for p in pairs})

    def test_gap_does_not_masquerade_as_three_millisecond_impact(self):
        t = np.r_[np.arange(0, .1, .001), np.arange(.15, .25, .001)]
        high = np.zeros((len(t), 3)); high[100:, 0] = 30
        self.assertEqual(match_sensor_contacts(t, high, [.15], offset=0, radius=.04), [None])


class ImpactCsvImportTests(unittest.TestCase):
    def make_recording(self):
        windows = []
        for i in range(8):
            w = np.zeros((448, 10))
            w[:, 0] = 1+5*i+np.arange(448)*.001
            w[:, 3] = 1
            w[:, 4] = 10 if i < 4 else -10
            w[387, 7] = 20
            windows.append(w)
        return np.concatenate(windows)

    def test_inter_hit_gaps_are_separate_complete_windows(self):
        windows = split_windows(self.make_recording())
        self.assertEqual(len(windows), 8)
        events = []
        for i, window in enumerate(windows, 1):
            row, features = inspect_window(window, i, 1)
            events.append(row)
            self.assertEqual(features.shape, (410,))
            self.assertLess(row["largest_internal_gap_ms"], 1.01)
            self.assertFalse(row["starting_orientation_available"])
        diagnostic = face_sign_diagnostic(events)
        self.assertEqual(diagnostic["forehand_candidates_by_taught_sign"], {"-1": 4, "1": 4})
        self.assertEqual(diagnostic["best_possible_forehands_with_any_single_taught_sign"], 4)

    def test_incomplete_window_is_not_promoted_to_full_capture(self):
        with self.assertRaisesRegex(ValueError, "448-sample"):
            split_windows(self.make_recording()[:-1])


if __name__ == "__main__":
    unittest.main()
