"""How close can 1 microphone get to the true contact point? Grouped CV on non-held-out clips only.

Targets: x_cm, y_cm (positions.csv) and radius. Metric: share of hits predicted within R cm of the true contact point.
"""
import csv, json, sys
from pathlib import Path
import numpy as np
sys.path.insert(0, str(Path(__file__).parent))
from research_methods import audio_features

ROOT = Path(__file__).resolve().parents[1]
SESS = ["20261027-224032-long-1", "20261028-155849-long-run2", "20261103-122017-third-session"]
held = {(c["session"], c["file"]) for c in json.load(open(ROOT / "ml/holdout.json"))["clips"]}


def rd(p):
    return list(csv.DictReader(open(p, newline="")))


X, XY, G, S = [], [], [], []
for s in SESS:
    d = ROOT / "data/sessions" / s
    n_of = {r["file"]: int(r["n"]) for r in rd(d / "clips.csv")}
    for r in rd(d / "positions.csv"):
        if (s, r["file"]) in held:
            continue
        clip = np.fromfile(d / r["file"], dtype="<i2")
        X.append(audio_features(clip[:512])[1] if len(clip) >= 512 else None)
        XY.append([float(r["x_cm"]), float(r["y_cm"])])
        G.append((s, (n_of[r["file"]] - 1) // 8)); S.append(s)
X = np.stack(X); XY = np.array(XY); S = np.array(S)
gid = np.array([hash(g) for g in G]); ug = np.unique(gid)
print("clips", len(X), "features", X.shape[1])
R = np.hypot(*XY.T)


def ridge(xtr, ytr, xte, a):
    m, s = xtr.mean(0), xtr.std(0) + 1e-6
    A = (xtr - m) / s; b = ytr.mean(0)
    w = np.linalg.solve(A.T @ A + a * np.eye(A.shape[1]), A.T @ (ytr - b))
    return ((xte - m) / s) @ w + b


rng = np.random.default_rng(0); folds = np.array_split(rng.permutation(ug), 5)
for a in (30, 100, 300, 1000):
    P = np.zeros_like(XY); Pr = np.zeros(len(X))
    for f in folds:
        te = np.isin(gid, f); tr = ~te
        P[te] = ridge(X[tr], XY[tr], X[te], a)
        Pr[te] = ridge(X[tr], R[tr, None], X[te], a)[:, 0]
    e = np.hypot(*(P - XY).T)
    base = np.hypot(*(XY - XY.mean(0)).T)
    print(f"alpha {a:5}: 2-D error mean {e.mean():.2f} cm | within1 {np.mean(e<=1):.0%} within2 {np.mean(e<=2):.0%} within4 {np.mean(e<=4):.0%}"
          f" | radius err mean {np.abs(Pr-R).mean():.2f}, within1 {np.mean(np.abs(Pr-R)<=1):.0%}"
          f" | guess-the-mean: mean {base.mean():.2f}, within1 {np.mean(base<=1):.0%} within2 {np.mean(base<=2):.0%}")
print("true x spread (sd) %.2f y %.2f radius mean %.2f" % (XY[:,0].std(), XY[:,1].std(), R.mean()))
