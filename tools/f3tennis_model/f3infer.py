"""F3Tennis tsm_e2espot inference + stroke-type marginals.

Preprocessing matches the F3Tennis repo: frames resized to 224 px high, centre-cropped to 224x224, ImageNet
normalisation, every 2nd frame, 96-sample windows. Windows overlap by half and probabilities are averaged.
Each of the 1,108 event classes encodes hitter / court / serve|return|stroke / fh|bh / technique / ..., so the
probability of a stroke type is the sum over the classes that share it.
"""
import json
import os
import sys

import cv2
import numpy as np
import torch

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "f3repo"))
from train_f3tennis_baselines import F3Tennis  # noqa: E402

W = os.path.join(HERE, "weights", "tsm_e2espot")
EVENTS = os.path.join(r"D:\Projects\Hardware\Smart Racket\data\external\f3set\repo\data\f3tennis", "events.txt")
MEAN = torch.tensor([0.485, 0.456, 0.406]).view(1, 1, 3, 1, 1)
STD = torch.tensor([0.229, 0.224, 0.225]).view(1, 1, 3, 1, 1)
CLIP, STRIDE, HOP = 96, 2, 48
TYPES = ["serve", "forehand", "backhand", "volley"]


def class_table():
    """Per class (index 1..1108): app stroke type and hitter. Index 0 is 'no event'."""
    rows = [None]
    for line in open(EVENTS, encoding="utf-8").read().splitlines():
        t = line.strip().lower().split("_")
        if len(t) < 5:
            rows.append(None)
            continue
        kind, hand, tech = t[2], t[3], t[4]
        typ = "serve" if kind == "serve" else "volley" if tech == "volley" else {"fh": "forehand", "bh": "backhand"}.get(hand)
        rows.append({"type": typ, "hitter": t[0], "tech": tech, "kind": kind})
    return rows


def load_model():
    cfg = json.load(open(os.path.join(W, "config.json")))
    m = F3Tennis(cfg["num_classes"] + 1, cfg["feature_arch"], cfg["temporal_arch"], cfg["clip_len"], step=cfg["stride"])
    m.load(torch.load(os.path.join(W, "checkpoint_049.pt"), map_location="cuda", weights_only=True))
    m._model.eval()
    return m


def load_frames(path):
    """(T, 224, 224, 3) uint8 RGB; also returns the source fps."""
    cap = cv2.VideoCapture(path)
    fps = cap.get(cv2.CAP_PROP_FPS)
    out = []
    while True:
        ok, f = cap.read()
        if not ok:
            break
        h, w = f.shape[:2]
        f = cv2.resize(f, (w * 224 // h, 224))
        x0 = (f.shape[1] - 224) // 2
        out.append(cv2.cvtColor(f[:, x0:x0 + 224], cv2.COLOR_BGR2RGB))
    cap.release()
    return np.stack(out), fps


@torch.no_grad()
def predict(model, frames):
    """Per-sampled-frame class probabilities, shape (N, 1109); sampled frame i is source frame i * STRIDE."""
    idx = np.arange(0, len(frames), STRIDE)
    X = torch.from_numpy(frames[idx])                      # (N, H, W, 3)
    n = len(idx)
    acc = np.zeros((n, 1109), np.float32)
    cnt = np.zeros(n, np.float32)
    starts = list(range(0, max(1, n - CLIP + HOP), HOP))
    for s in starts:
        clip = X[s:s + CLIP]
        L = clip.shape[0]
        x = clip.permute(0, 3, 1, 2).float().div(255).unsqueeze(0)
        x = ((x - MEAN) / STD).cuda()
        with torch.autocast("cuda"):
            y = model._model(x)
        p = torch.softmax(y.float(), dim=-1)[0, :L].cpu().numpy()
        acc[s:s + L] += p
        cnt[s:s + L] += 1
    return acc / np.maximum(cnt, 1)[:, None]


def marginals(probs, table):
    """(N, len(TYPES)) stroke-type mass, (N, 2) near/far mass, (N,) total event mass."""
    T = np.zeros((probs.shape[0], len(TYPES)), np.float32)
    H = np.zeros((probs.shape[0], 2), np.float32)
    for c, row in enumerate(table):
        if row is None or c == 0:
            continue
        if row["type"] in TYPES:
            T[:, TYPES.index(row["type"])] += probs[:, c]
        if row["hitter"] in ("near", "far"):
            H[:, 0 if row["hitter"] == "near" else 1] += probs[:, c]
    return T, H, 1.0 - probs[:, 0]


def classify_at(T, H, frame, half_window=6):
    """Stroke type and hitter around a source frame: mass summed over +-half_window source frames."""
    lo = max(0, (frame - half_window) // STRIDE)
    hi = min(T.shape[0], (frame + half_window) // STRIDE + 1)
    if hi <= lo:
        return None
    t, h = T[lo:hi].sum(0), H[lo:hi].sum(0)
    return {"type": TYPES[int(t.argmax())], "conf": float(t.max() / max(t.sum(), 1e-9)),
            "hitter": "near" if h[0] >= h[1] else "far", "mass": float(t.sum())}
