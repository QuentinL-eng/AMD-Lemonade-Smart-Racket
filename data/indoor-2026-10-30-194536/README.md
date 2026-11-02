# Eight indoor forehands, 30 October 2026

The phone's recovered shot log records **3/8 correct (37.5%)**: three forehands, four backhands and one serve,
against the user's labels of eight medium-to-low-pace indoor forehands.

The recovered link log identifies **firmware 1.6**, with the 4000 dps flag, superseding the earlier report that
firmware 1.8 or newer was installed. This version has the independently established 2x gyro scaling bug.
The current extracted sensor features therefore use a **0.5 gyro correction**. Live app scores and displayed
speeds remain the original recorded results; applying a correction to data does not retroactively improve them.

All eight 448-sample windows and eight live summaries were received, with zero lost windows reported. The
original binary recording was copied too and matches the CSV within its export rounding. The recovered app
preferences contain a custom calibrated matrix and no saved taught forehand sign. Consequently, the earlier
hypothetical bound for a fixed sign under the default mounting is not an explanation of the actual live path.

Files:

- Original CSV, raw recording, shot log and link log: retained unchanged.
- `labels.csv`: eight user-supplied forehand labels.
- `windows-and-features.npz`: eight complete windows and 410 features per window, corrected gyro scale.
- `report.json`: updated sensor analysis and provenance.
- `live-shot-results.json`: actual recorded classification results.
- `confirmed-firmware-analysis/`: reproducible corrected import.
- `initial-user-firmware-assumption/`: preserved earlier analysis before phone metadata was available.

The original raw samples still omit per-window starting orientation. The live score is established by the
recovered shot log; the score of a corrected classifier is not established. No measured ball-speed references
or 95% four-type accuracy claim are available from this recording.
