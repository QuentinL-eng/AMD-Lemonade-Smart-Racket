"""ME 579-style model selection for contact-point regression (x_cm, y_cm) from one microphone.

Course techniques used: time/frequency/time-frequency features (FFT bands, kurtosis, crest, mel, wavelet packet),
standardisation fitted inside each training fold only (no leakage), PCA, ridge/lasso, kernel ridge and Gaussian-process
regression (RBF), a small MLP, and repeated grouped k-fold CV. Never touches the clips listed in ml/holdout.json.

    python ml/model_selection.py     # writes ml/runs/20261103-model-selection/{features.npz,results.json}
"""
import csv
import json
import sys
import time
from pathlib import Path

import numpy as np
from scipy.stats import kurtosis

sys.path.insert(0, str(Path(__file__).parent))
from research_methods import feature_bank  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "ml/runs/20261103-model-selection"
SESS = ["20261027-224032-long-1", "20261028-155849-long-run2", "20261103-122017-third-session"]


def rd(p):
    return list(csv.DictReader(open(p, newline="")))


def load(include_held=False):
    """Clips, (x,y) cm, block-group ids, names and held-out flags. Control clips are excluded unless asked for."""
    held = {(c["session"], c["file"]) for c in json.load(open(ROOT / "ml/holdout.json"))["clips"]}
    clips, xy, grp, name, is_held = [], [], [], [], []
    for s in SESS:
        d = ROOT / "data/sessions" / s
        n_of = {r["file"]: int(r["n"]) for r in rd(d / "clips.csv")}
        for r in rd(d / "positions.csv"):
            h = (s, r["file"]) in held
            if h and not include_held:
                continue
            clips.append(np.fromfile(d / r["file"], dtype="<i2"))
            xy.append([float(r["x_cm"]), float(r["y_cm"])])
            is_held.append(h)
            grp.append(f"{s}:{(n_of[r['file']] - 1) // 8}")
            name.append(f"{s}/{r['file']}")
    return clips, np.array(xy), np.array(grp), np.array(name), np.array(is_held)


def course_features(c):
    """Lecture 3 features on the 32 ms impact window: 64-bin log power spectrum + RMS/kurtosis/peak of each third."""
    x = c[:512].astype(float)
    x -= x.mean()
    x /= np.sqrt(np.mean(x * x)) + 1e-9
    spec = np.abs(np.fft.rfft(x * np.hanning(512))) ** 2
    spec = spec[:256].reshape(64, 4).sum(1)
    spec /= spec.sum() + 1e-12
    thirds = [x[:170], x[170:340], x[340:]]
    td = ([np.log10(np.mean(t * t) + 1e-6) for t in thirds] + [kurtosis(t) for t in thirds]
          + [np.abs(t).max() for t in thirds])
    return np.r_[np.log10(spec + 1e-8), td].astype(np.float32)


def std_fit(x):
    return x.mean(0), x.std(0) + 1e-6


class Ridge:
    def __init__(self, a):
        self.a = a

    def fit(self, x, y):
        self.m, self.s = std_fit(x)
        A = (x - self.m) / self.s
        self.b = y.mean(0)
        self.w = np.linalg.solve(A.T @ A + self.a * np.eye(A.shape[1]), A.T @ (y - self.b))
        return self

    def predict(self, x):
        return ((x - self.m) / self.s) @ self.w + self.b


class PCARidge:
    def __init__(self, k, a):
        self.k, self.a = k, a

    def fit(self, x, y):
        self.m, self.s = std_fit(x)
        A = (x - self.m) / self.s
        self.v = np.linalg.svd(A, full_matrices=False)[2][: self.k].T
        self.r = Ridge(self.a).fit(A @ self.v, y)
        return self

    def predict(self, x):
        return self.r.predict(((x - self.m) / self.s) @ self.v)


class Lasso:
    def __init__(self, a, it=60):
        self.a, self.it = a, it

    def fit(self, x, y):
        self.m, self.s = std_fit(x)
        A = (x - self.m) / self.s
        n, p = A.shape
        self.b = y.mean(0)
        Y = y - self.b
        self.w = np.zeros((p, Y.shape[1]))
        nrm = (A * A).sum(0) / n + 1e-9
        R = Y.copy()
        for _ in range(self.it):
            for j in range(p):
                R += np.outer(A[:, j], self.w[j])
                rho = A[:, j] @ R / n
                self.w[j] = np.sign(rho) * np.maximum(np.abs(rho) - self.a, 0) / nrm[j]
                R -= np.outer(A[:, j], self.w[j])
        return self

    def predict(self, x):
        return ((x - self.m) / self.s) @ self.w + self.b


class KRR:
    """Kernel ridge = GP posterior mean with an RBF kernel. Length scale = ls * median pairwise distance."""

    def __init__(self, ls, lam):
        self.ls, self.lam = ls, lam

    def _k(self, a, b):
        d = (a * a).sum(1)[:, None] + (b * b).sum(1)[None] - 2 * a @ b.T
        return np.exp(-np.maximum(d, 0) / (2 * self.l2))

    def fit(self, x, y):
        self.m, self.s = std_fit(x)
        self.x = (x - self.m) / self.s
        d = np.sqrt(np.maximum((self.x ** 2).sum(1)[:, None] + (self.x ** 2).sum(1)[None] - 2 * self.x @ self.x.T, 0))
        self.l2 = (self.ls * np.median(d[d > 0])) ** 2
        self.b = y.mean(0)
        self.alpha = np.linalg.solve(self._k(self.x, self.x) + self.lam * np.eye(len(x)), y - self.b)
        return self

    def predict(self, x):
        return self._k((x - self.m) / self.s, self.x) @ self.alpha + self.b


class MLP:
    """One hidden ReLU layer, Adam, L2 weight decay, mean of several seeds."""

    def __init__(self, h=32, wd=1e-2, ep=150, seeds=3):
        self.h, self.wd, self.ep, self.seeds = h, wd, ep, seeds

    def fit(self, x, y):
        self.m, self.s = std_fit(x)
        A = ((x - self.m) / self.s).astype(np.float64)
        self.ym, self.ys = y.mean(0), y.std(0)
        Y = (y - self.ym) / self.ys
        self.nets = []
        for sd in range(self.seeds):
            r = np.random.default_rng(sd)
            P = [r.normal(0, 1 / np.sqrt(A.shape[1]), (A.shape[1], self.h)), np.zeros(self.h),
                 r.normal(0, 1 / np.sqrt(self.h), (self.h, Y.shape[1])), np.zeros(Y.shape[1])]
            M = [np.zeros_like(p) for p in P]
            V = [np.zeros_like(p) for p in P]
            t = 0
            for _ in range(self.ep):
                for idx in np.array_split(r.permutation(len(A)), max(1, len(A) // 64)):
                    xb, yb = A[idx], Y[idx]
                    z = xb @ P[0] + P[1]
                    hh = np.maximum(z, 0)
                    go = 2 * (hh @ P[2] + P[3] - yb) / len(idx)
                    gh = (go @ P[2].T) * (z > 0)
                    G = [xb.T @ gh + self.wd * P[0], gh.sum(0), hh.T @ go + self.wd * P[2], go.sum(0)]
                    t += 1
                    for i in range(4):
                        M[i] = .9 * M[i] + .1 * G[i]
                        V[i] = .999 * V[i] + .001 * G[i] ** 2
                        P[i] -= 3e-3 * (M[i] / (1 - .9 ** t)) / (np.sqrt(V[i] / (1 - .999 ** t)) + 1e-8)
            self.nets.append(P)
        return self

    def predict(self, x):
        A = (x - self.m) / self.s
        return np.mean([np.maximum(A @ P[0] + P[1], 0) @ P[2] + P[3] for P in self.nets], 0) * self.ys + self.ym


def score(p, y):
    e = np.hypot(*(p - y).T)
    return {"mean_cm": float(e.mean()), "w1": float(np.mean(e <= 1)), "w2": float(np.mean(e <= 2)),
            "w4": float(np.mean(e <= 4))}


def cv(make, X, Y, G, reps=3, k=5):
    """Repeated k-fold over whole 8-throw blocks (no neighbouring throws on both sides of a split)."""
    ug = np.unique(G)
    res = []
    for rep in range(reps):
        folds = np.array_split(np.random.default_rng(100 + rep).permutation(ug), k)
        P = np.zeros_like(Y)
        for f in folds:
            te = np.isin(G, f)
            P[te] = make().fit(X[~te], Y[~te]).predict(X[te])
        res.append(score(P, Y))
    return {k_: float(np.mean([r[k_] for r in res])) for k_ in res[0]} | {"w1_sd": float(np.std([r["w1"] for r in res]))}


def zoo():
    z = []
    for f in ("current156", "course_fft_td", "mfcc_time", "mfcc_wavelet_modal"):
        z += [(f, f"ridge a={a}", lambda a=a: Ridge(a)) for a in (100, 300, 1000, 3000)]
    for f in ("current156", "course_fft_td"):
        z += [(f, f"lasso a={a}", lambda a=a: Lasso(a)) for a in (0.03, 0.1, 0.2)]
        z += [(f, f"pca{k}+ridge", lambda k=k: PCARidge(k, 30)) for k in (5, 10, 20)]
        z += [(f, f"gp ls={ls} lam={lam}", lambda ls=ls, lam=lam: KRR(ls, lam))
              for ls in (0.5, 1.0, 2.0) for lam in (0.3, 1.0, 3.0)]
        z += [(f, f"mlp h32 wd={wd}", lambda wd=wd: MLP(32, wd)) for wd in (1e-2, 1e-1)]
    return z


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    clips, Y, G, _, _ = load()
    fp = OUT / "features.npz"
    if fp.exists():
        F = dict(np.load(fp))
    else:
        t = time.time()
        F = dict(feature_bank([c[:512] for c in clips]))
        F["course_fft_td"] = np.stack([course_features(c) for c in clips])
        np.savez(fp, **F)
        print(f"features in {time.time() - t:.0f}s")
    print("clips", len(Y), {k: v.shape[1] for k, v in F.items()})
    results = {"guess_mean": score(np.tile(Y.mean(0), (len(Y), 1)), Y)}
    print("guess-the-mean", results["guess_mean"], flush=True)
    for fname, mname, make in zoo():
        t = time.time()
        r = cv(make, F[fname], Y, G)
        results[f"{fname} | {mname}"] = r
        print(f"{fname:20} {mname:22} mean {r['mean_cm']:.2f}  w1 {r['w1']:.1%}+-{r['w1_sd']:.1%}  "
              f"w2 {r['w2']:.1%}  w4 {r['w4']:.1%}  ({time.time() - t:.0f}s)", flush=True)
    json.dump(results, open(OUT / "results.json", "w"), indent=1)


if __name__ == "__main__":
    main()
