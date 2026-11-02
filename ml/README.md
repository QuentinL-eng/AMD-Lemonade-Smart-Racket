# ML: sweet-spot model and Muse what-if data

Two jobs live here:

1. **Sweet-spot model.** The racket's INMP441 mic hears each impact. A model on the ESP32-C3 estimates how far from
   the sweet spot the ball hit, and calls it sweet or not.
2. **What-if dataset for Muse Spark.** Synthetic tool-use conversations that teach Muse to call `simulate_change`
   and report the predicted result. See [`docs/WHATIF_DATASET.md`](../docs/WHATIF_DATASET.md).

## The model on the racket

A ridge regressor (a regularized linear model) on 156 audio features from the first 512 samples (32 ms) of the hit.
It predicts the distance from the sweet spot in cm; 4 cm or less counts as sweet.

| Piece | File |
|---|---|
| Feature spec (Python) | `compare_models.py` (`audio_features`) |
| Feature extractor + model (C++) | [`firmware/src/sweetspot.cpp`](../firmware/src/sweetspot.cpp), [`distance_model.h`](../firmware/src/distance_model.h) |
| Self-test vectors | `firmware/src/distance_selftest.h` |
| Trainer on real sessions | `train_combined.py` |
| Parity check C++ ↔ Python | `test_parity.py` |

Results on 274 reviewed real clips from two sessions, grouped 5-fold: **67.2% accuracy** (always guessing
"off-centre" scores 60.6%), **1.83 cm** mean distance error. Full comparison of six approaches and next steps:
[`runs/SUMMARY-20261028.md`](runs/SUMMARY-20261028.md).

The older 12-feature int8 MLP (`train.py`, `sweetspot_model.h`) was trained on synthetic sound (`synth.py`). It
scored 57.4% on real clips and was not promoted.

## Run

```bash
pip install numpy scipy
python3 ml/test_parity.py                                   # C++ and Python agree on every clip
python3 -m unittest discover -s ml -p test_whatif_synth.py  # what-if simulator mirrors the Swift one
python3 ml/whatif_synth.py generate                         # -> data/whatif/ (400 players)
```

Collect and label new clips with `tools/collect_clips.py` and `tools/label_clips.py`. Raw sessions stay local
(`data/sessions/`, not in git).

## Folder

| Path | What |
|---|---|
| `runs/2026*/` | Saved run reports, metrics and out-of-fold predictions for each experiment |
| `research_*.py`, `classical_models.py`, `multitask_audio.py`, `train_scattering_multitask.py` | Model experiments (not deployed) |
| `coach_sim.py`, `whatif_synth.py`, `whatif_priors.json` | Python mirror of the app's `ShotSimulator` and the dataset generator |
