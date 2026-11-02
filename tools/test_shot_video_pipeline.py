import csv
import json
import tempfile
import unittest
from argparse import Namespace
from pathlib import Path

import numpy as np

from shot_video_pipeline import export


class ExportTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.folder = Path(self.tmp.name)
        t = np.arange(9., 12., .01)
        np.savez(self.folder / 'imu_aligned.npz', t_phone_s=t, accel_g=np.ones((len(t), 3)),
                 gyro_rad_s=np.ones((len(t), 3)), high_g=np.ones((len(t), 3)))
        (np.array([10., 10.5, 11.]) * 1e9).astype('<u8').tofile(self.folder / 'video_frames.bin')
        self.events = self.folder / 'events.csv'
        self.output = self.folder / 'out.json'
        self.args = Namespace(session=self.folder, events=self.events, observations=None,
                              output=self.output, before=.5, after=.25)

    def tearDown(self):
        self.tmp.cleanup()

    def write_event(self, frame, label):
        with self.events.open('w', newline='') as f:
            w = csv.writer(f)
            w.writerow(['frame', 'shot_type', 'note'])
            w.writerow([frame, label, 'reviewed'])

    def test_exports_correct_window_on_phone_clock(self):
        self.write_event(1, 'forehand')
        export(self.args)
        row = json.loads(self.output.read_text())['events'][0]
        samples = np.load(self.output.with_suffix('.npz'))
        self.assertEqual(row['contact_phone_s'], 10.5)
        self.assertEqual(row['shot_type'], 'forehand')
        self.assertEqual(samples['offsets'][1], row['imu_samples'])
        self.assertGreaterEqual(samples['samples'][0, 0], -.500001)
        self.assertLessEqual(samples['samples'][0, 0], -.489999)
        self.assertLess(row['largest_imu_gap_ms'], 11)

    def test_rejects_invalid_labels_and_missing_frames(self):
        for frame, label in [(1, 'winner'), (10, 'serve')]:
            self.write_event(frame, label)
            with self.assertRaises(ValueError):
                export(self.args)

    def test_rejects_incomplete_imu_window(self):
        self.write_event(0, 'serve')
        self.args.before = 5
        with self.assertRaisesRegex(ValueError, 'coverage'):
            export(self.args)


if __name__ == '__main__':
    unittest.main()
