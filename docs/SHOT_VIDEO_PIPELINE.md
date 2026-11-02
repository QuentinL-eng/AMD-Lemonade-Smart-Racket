# Video and racket sensor research

This is a research pipeline, not a validated shot classifier. SAM 3.1 finds candidate racket boxes in sampled video frames. A reviewer labels contacts and shot types, then the export pairs those events with synchronized sensor windows. SAM boxes are 2-D observations; they do not measure 3-D pose, spin, ball outcome, or ground-truth shot type. The highest-confidence candidate can be the wrong racket when multiple players are visible.

## Setup

From the repository root, install Python packages in a virtual environment:

```sh
python3 -m venv .venv
.venv/bin/pip install numpy opencv-python openai
```

Set `MUSE_API_KEY` or `MODEL_API_KEY` in the environment or the repository's ignored `.env`. SAM requests send frames to Meta and consume API credits. Use only video you are entitled to process. Do not commit source footage, API keys, or private results. `--max-calls` limits each invocation; check current Meta pricing and the account's spend separately. This tool does not enforce an account-wide dollar cap.

## Sample a video

```sh
.venv/bin/python tools/shot_video_pipeline.py track /path/to/video.mov \
  --output /path/to/racket-observations.json --start 0 --end 10 --fps 2 --max-calls 10
```

Each call segments one sampled frame using `sam-3.1`; results are saved after each call and reruns resume. Increase `--max-calls` to process more frames. Use a separate output for every video or configuration. Bounding boxes are in original-frame pixels; `null` means no candidate passed the confidence threshold, not that no racket was present. Inspect the video and predictions before use. The frame time stored here uses nominal frame rate and is approximate for variable-rate video.

## Pair with a phone recording

Follow the phone capture instructions in [DATA_COLLECTION.md](DATA_COLLECTION.md), including the visible sync mark and video. Run `tools/phone_session.py` on that session. Check `sync.json` and synchronization visually; clock alignment is an estimate, and packet loss or inaccurate contact refinement can affect it.

Run `track` on that session's `video.mov`. Review the video and create `events.csv` with **zero-based video frame numbers** and one row per verified contact:

```csv
frame,shot_type,note
240,forehand,reviewed contact
480,backhand,reviewed contact
```

Supported labels are `forehand`, `backhand`, `serve`, `volley`, and `unknown`. Do not label shadow swings or uncertain contacts as confirmed hits. Then:

```sh
.venv/bin/python tools/shot_video_pipeline.py export data/phone/SESSION \
  --events data/phone/SESSION/events.csv \
  --observations data/phone/SESSION/racket-observations.json \
  --output data/phone/SESSION/shot-events.json
```

The JSON records the label, phone-clock contact time, observed box when that exact frame was sampled, and the largest IMU timestamp gap in the window. The adjacent NPZ stores actual samples: `samples` has columns listed in `columns`, and event `i` occupies `samples[offsets[i]:offsets[i+1]]`. Times are relative to contact. The program rejects events outside the video timestamp range or without window coverage; a large internal gap is reported and must be reviewed. Only use these as training labels after checking the video, synchronization, sensor range, and gaps.

## Robot recordings and evaluation

`data/room-2026-10-29/results/manifest.csv` contains tentative run assignments; `alignment.csv` contains robot/IMU alignment diagnostics. Use corrected gyro data and its documented calibration only after checking which runs and alignments are valid. Robot movements are controlled examples, not verified player-shot or ball-outcome labels. To test whether they improve classification, first collect reviewed real-player sessions and split by player and session; compare a model using those sessions alone with one also using robot data. Report per-class results and errors on held-out players. Do not infer ball outcomes without independently observed outcomes.
