# Stroke classification and speed validation

**Acceptance status, 30 October 2026: the requested 95% across forehand, backhand, serve and volley is not yet demonstrated.**

This directory contains a runnable training/evaluation system, video-assisted labeling, cached SAM 3.1 observations,
and a replay of the production classifier. The application and firmware still use their existing classifier.

## Measured real-racket results

| Evaluation | Result | Meaning |
|---|---:|---|
| Room session A, corrected gyro ×0.5 | 22/22 | Regression only: its labels were already used to tune the rules |
| TennisCamera 1005, visually reviewed forehands | 28/29 (96.55%) | Separate-session forehand result; **no** held-out backhands, serves or volleys |
| Raw-stream replay, detections matched to those 29 contacts | 29/29 detected, 28/29 correctly typed | Motion path on received BLE samples; four additional detections remain unmatched |
| New eight-forehand indoor session, user-labeled | **3/8 live classifications correct (37.5%)** | Phone logs confirm firmware 1.6, overriding the initial version assumption. |
| Ball-speed validation | Unavailable | No measured ball-speed reference accompanies this racket's recordings |

The forehand score is reproduced by the actual Swift `ShotAnalyzer` as well as the Python baseline. The one error
is candidate 16 (reviewed event 14), a forehand labeled as serve by the existing tip-up threshold. No classification
threshold was changed using this recording during this work. The handoff shows that this video was inspected in prior
repository work; this is a retrospective separate-session baseline, not a newly collected untouched certification set.
The 95% Wilson interval for 28/29 is 82.8–99.4%; hits from the same player
and session are correlated, so even that interval does not establish performance across players or sessions.

The old “32 forehands” claim does not match the reviewed footage. This review confirms 29 self-fed forehands,
with setup/synchronization movements before the drill and camera handling afterward. The saved CSV states that
the reviewer was Codex, assisted by SAM; it does not claim human review. A coarse whole-video census and targeted
contact clips were inspected, rather than all 44,421 frames individually. The four unmatched raw detections include
three setup/sync movements and one early motion around the eighth candidate. They must not be counted as correctly
classified forehands.

## Saved evidence

- `evidence/tenniscamera-1005-reviewed-events.csv`: 29 reviewed video frame labels, contact-frame uncertainty,
  reviewer and method. Three contacts were reviewed manually where SAM lost the racket around impact.
- `evidence/tenniscamera-1005-review-metadata.json`: source video/IMU/timestamp hashes and review provenance.
- `evidence/tenniscamera-1005-baseline-summary.json`: measured results and acceptance limitations.
- `artifacts/camera-reviewed-baseline.json`: detailed predictions, timing matches, gaps and extra detections.
- `artifacts/sam-contact-review/`: 62 cached SAM 3.1 video requests, 15,566 frame/prompt pairs
  (approximately 7,783 distinct source frames). No API key or source video is stored in the responses.
- `artifacts/sam-review/`: review sheets and machine proposals. **Proposals are not labels.**
- `artifacts/data-audit.json`: local/SD-card inventory and quality checks. One SD archive,
  `3DTennisDS/tp3_fh.zip`, could not be opened as a ZIP; 631 C3D files were listed in the other archives.

Large local artifacts are ignored by Git. Original recordings and existing work were preserved.

## Eight-forehand recording and USB recovery

`data/indoor-2026-10-30-194536/` contains eight complete 448-sample windows, all passing the internal-gap
policy. The recovered phone shot log records **3 forehands, 4 backhands and 1 serve**, or **3/8 correct**
against the user's eight forehand labels. This is the actual live score, not a model replay.

The phone's matching link log identifies **firmware 1.6**, with the 4000 dps flag, superseding the user's
initial recollection of firmware 1.8 or newer. Corrected features now use a **0.5 gyro scale**. The initial
scale-1 analysis is preserved separately. The phone also has a custom calibrated matrix and no saved taught
forehand sign; the earlier default-mount fixed-sign bound was hypothetical and does not describe the live path.

A local USB copy in `data/phone-usb-2026-10-30/` contains 48 relevant app files: all Documents, preferences,
and application-support data, totaling about 47.8 MB. The copied session database passed its quick integrity
check. Its manifest includes file hashes. The folder is Git-ignored because it contains private app state.
Phone contents were not modified. Large coach-model caches were unnecessary for sensor evaluation.

The recovered live summaries establish the recorded score. Corrected-classifier accuracy still requires
suitable pose state or another valid evaluation method. Internet examples and model predictions cannot become
ground-truth labels. All four stroke types and measured speed references remain unverified as a group.

## Firmware and recording fixes, 30 October

The app's bundled firmware was still **1.6**, although the source was **1.8**. The bundle was rebuilt as 1.8
with a SHA-256 manifest, and a regression check now compares the source version, bundled version and image hash.
The app warns about the known rotation-scale fault in versions 1.5–1.7.

With the user's authorization, the connected ESP32-C3 racket was backed up in full (4 MiB) and flashed over
USB with the corrected 1.8 image. The upload verified its hash. Live status then reported **±2000 dps**, about
**1000 Hz**, Bluetooth connected, no I²C errors and no IMU resets. The backup, upload log, live status and
verification manifest are local, ignored artifacts in `artifacts/racket-usb-update/`. This verifies installation
and the reported range; it is not a new stroke-accuracy or physical speed-calibration measurement.

Future app recordings now preserve each impact window's starting quaternion, sample offset, impact index,
sequence/boot identifiers, calibration, handedness, taught forehand sign, model and calibration-mode setting
in a companion `.windows.jsonl` file. The signed iOS app build succeeded and was installed and launched on the paired phone. Calibration, profile, model and player settings were preserved, and the original eight-hit raw recording still matches its saved hash. A round-trip test verifies that restoring this state reproduces the same
Swift shot analysis. This does not reconstruct the missing state in older recordings or change the Recorder
screen's existing continuous-stream Replay behavior. The Share button now includes the CSV, original `.tbrec`
and available window, shot and link companions. Link logs also capture the current calibration/settings and
any windows whose context could not be encoded.

The existing classifier thresholds remain unchanged. Firmware 1.8 removes the known doubled-gyro defect;
accuracy after that repair still needs independent labeled real-racket hits. Measured ball-speed references
are still absent.

## Run the checks

Run Python commands from `/Users/quentinlynch/Projects/Hardware/Smart Racket`:

```sh
.venv/bin/pip install -r ml/stroke_system/requirements.txt
.venv/bin/python -m unittest ml.stroke_system.test_system -v
.venv/bin/python tools/shot_type_check.py data/room-2026-10-29 0 0.5
.venv/bin/python -m ml.stroke_system.audit --output ml/stroke_system/artifacts/data-audit.json
.venv/bin/python -m ml.stroke_system.evaluate_camera \
  'data/Tennis Camera/10-29-26-1005' \
  ml/stroke_system/evidence/tenniscamera-1005-reviewed-events.csv \
  --gyro-scale 0.5 \
  --review-metadata ml/stroke_system/evidence/tenniscamera-1005-review-metadata.json \
  --output ml/stroke_system/artifacts/camera-reviewed-recheck.json
```

Evaluation output must be new, preserving previous results. The Swift check uses the generated original-scale
`artifacts/camera-original-scale.csv` and `artifacts/camera-matched-sensor-events.csv`:

```sh
cd apple/RacketKit
LABELED_SESSION=../../data/room-2026-10-29 \
LABELED_GYRO_SCALE=0.5 LABELED_FOREHAND_SIGN=1 \
REVIEWED_SENSOR_CSV=../../ml/stroke_system/artifacts/camera-original-scale.csv \
REVIEWED_SENSOR_EVENTS=../../ml/stroke_system/artifacts/camera-matched-sensor-events.csv \
REVIEWED_GYRO_SCALE=0.5 \
swift test --filter 'LabeledSessionTests|ReviewedVideoSessionTests|ShotParityTests'
```

## Train on reviewed own-racket sessions

The training manifest is CSV with these columns:

```csv
recording,player_id,session_id,split,shot_type,contact_s,gyro_scale,mount_id,verified_by,provenance
```

- `recording`: original ten-column app CSV, relative to the manifest or absolute.
- `contact_s`: contact on that recording's sensor clock, in seconds. Do not use video-clock seconds here.
- `shot_type`: `forehand`, `backhand`, `serve`, `volley`, or `nothing` (a non-stroke event).
- `split`: `train`, `validation`, or `test`. Each split needs all four stroke types.
- `provenance`: `real_racket`. Robot, synthetic and external recordings are refused by this acceptance path.
- `mount_id`: one consistently calibrated sensor mounting. Use a different model after a mounting change.
- `gyro_scale`: explicitly confirmed per recording. The supplied room/camera/phone sessions need `0.5`;
  the club recordings were decoded at the correct scale. New firmware 1.8 uses `1.0`.
- `verified_by`: named reviewer who checked the contact and class, including whether review was performed by AI.

The raw CSV header is:

```csv
time_s,ax_g,ay_g,az_g,gx_rads,gy_rads,gz_rads,hx_g,hy_g,hz_g
```

Training uses physical-time features from 350 ms before to 60 ms after contact, fitting the existing impact buffer.
The default feature path rejects gaps over 12 ms before interpolation. This is a conservative research setting,
**not a demonstrated boundary between usable and unusable classification data**. All 22 room windows exceed it,
although the existing rules still classify them correctly. Received samples cannot reconstruct what happened inside
those gaps. Quality rejects remain `unknown` and count as errors in evaluation; no confidence filtering inflates accuracy.

```sh
.venv/bin/python -m ml.stroke_system.train /path/to/reviewed-events.csv \
  --mode personalized --output ml/stroke_system/artifacts/own-racket-run-01
```

`personalized` keeps whole sessions separate for one player. `player-independent` also prohibits a player crossing
splits. File and sample hashes catch copied recordings and duplicate windows. Model selection uses validation only;
the selected model is fitted on train + validation and then scored on the untouched test sessions. Models include
SVM, Extra Trees and Random Forest. Outputs include the fitted model, every test prediction, a manifest and per-class
confusion counts. Acceptance requires at least 95% overall and 95% recall for each stroke on that test. It reports
sample counts and uncertainty; a high point estimate from a tiny or single-session test is not a general guarantee.

```sh
.venv/bin/python -m ml.stroke_system.predict /path/to/model.joblib /path/to/session.csv \
  --contact-s 123.456 --gyro-scale 1 --mount-id your-confirmed-mount
```

The external SmartTennisRacket experiments in `artifacts/external-*` are development research: the first nested
player benchmark reached 92.83%, and the gravity-feature variant 92.28%. They provide neither volley examples nor
an own-racket acceptance result. Their fitted research weights are not integrated into the app.

## Video analysis and clock alignment

The existing `.env` loader finds the Meta credential without printing it. The SAM workflow sends bounded video clips
and caches every response. The frame cap includes reserved/failed requests; reruns skip completed or uncertain calls,
so retries cannot silently create duplicate charges. Limits can be increased explicitly when processing another batch.

```sh
.venv/bin/python -m ml.stroke_system.sam_contacts \
  'data/Tennis Camera/10-29-26-1005' \
  --output ml/stroke_system/artifacts/sam-contact-review \
  --max-clips 31 --max-frames 16000 --workers 4
.venv/bin/python -m ml.stroke_system.review_contacts \
  'data/Tennis Camera/10-29-26-1005' \
  ml/stroke_system/artifacts/sam-contact-review \
  --output ml/stroke_system/artifacts/sam-review
```

The legacy aligned IMU times are roughly 0.32–0.41 seconds later than the reviewed video contacts in this recording.
The automatic ball-kink alignment previously left this offset unresolved. Matching uses video only to locate a nearby
complete high-g jump; shot labels do not choose the jump. It flags missing contacts rather than inventing samples.
This does not overwrite `imu_aligned.npz`, `sync.json`, video or any original label file.

SAM provides 2-D observations. Racket/ball box proximity, image speed and a guessed pixels-to-metres scale do not
provide measured 3-D ball speed. No ball-speed accuracy claim is made from these tracks.

## Speed calibration when references become available

Add `ball_speed_reference_ms` and/or `racket_speed_reference_ms`, plus `reference_source`, to the manifest. Use radar,
calibrated video or another independent measurement. Guessed speeds and this app's own outputs are not references.

```sh
.venv/bin/python -m ml.stroke_system.speed /path/to/reviewed-events.csv \
  --kind ball --shaft-axis y --output ml/stroke_system/artifacts/ball-speed-01.json
```

The default mounting's long axis is sensor Y. The fit uses angular motion across the shaft, an effective radius and
a nonnegative impact-speed drop, selecting its gain on validation references. Saturated gyro windows are excluded
from speed fitting. Held-out results report MAE, RMSE, bias, percentage error and coverage; missing predictions remain
in the denominator for the within-5% count. No calibration is fitted when measured references are absent.

## Work required to establish the full target

The missing evidence is independent, video-labeled real-racket backhands, serves and volleys, plus measured speed
references. Internet footage, robot trajectories and simulated IMU cannot supply those measurements for this handle.
When recording becomes possible, use complete impact windows on firmware 1.8 or later and preserve the video. Three
separate short recordings containing 20 contacts per stroke each would provide an initial train/validation/test split;
larger, varied court sessions are needed for a convincing field accuracy claim. Keep mistimed, framed and missed
detections in the review rather than silently excluding them. Test data must remain separate from later tuning.
