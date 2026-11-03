# F3Tennis stroke model (separate environment)

Scripts that run the F3Tennis `tsm_e2espot` model to find hits and classify strokes in broadcast video. They need
a CUDA PyTorch environment and the authors' weights, so they live apart from the app's Python code and are not
run by CI. Paths at the top of each file point at the machine they were run on (`D:\Projects\Hardware\f3tennis-env`);
change them for yours.

| File | What it does |
|---|---|
| `f3infer.py` | Loads the model (`weights_only=True`), preprocesses frames as the F3Tennis repo does, sums class probabilities into stroke type and near/far hitter. The checkpoint has 1,109 outputs: class 0 is "no event" plus the 1,108 event classes. |
| `eval_ostrava.py` | Checks the model on the 11 labelled Ostrava clips of the F3Tennis **test** split: 58/60 stroke types, 47/48 forehand-vs-backhand, 11/11 serves, 60/60 near/far. Same match (and camera) as its training clips, so optimistic for other broadcasts. |
| `detect_pros.py` | Runs the model over whole videos in overlapping chunks, **resampled to 25 fps** (it was trained on 25 fps; feeding 50/60 fps raw misses ~40% of hits), and writes `<video>.ev25.json`. |

Setup that worked: Python 3.12 venv, `torch`/`torchvision` 2.6 (cu124), `timm==0.5.4` (`--no-deps`), `opencv-python-headless`,
`numpy`, `pandas`, `scipy`, `tqdm`, `tabulate`, `matplotlib`. In a copy of the F3Tennis repo, change `pretrained=True`
to `pretrained=False` in `train_f3tennis_baselines.py` (the checkpoint replaces those weights; this avoids an ImageNet
download). Weights: the authors' Drive folder linked from `data/external/f3set/repo/f3tennis-model/README.md`, subfolder
`tsm_e2espot` (21 MB). Then `tools/sam_model_windows.py` tracks rackets around the detected hits and
`tools/model_events_to_emulator.py` builds the emulator sessions. Source video is downloaded locally and deleted afterwards.
