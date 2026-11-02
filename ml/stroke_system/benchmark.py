"""Nested leave-player-out benchmark; never mixes windows from the same player.

Run from repository root:
  .venv/bin/python -m ml.stroke_system.benchmark --output PATH
"""
import argparse
from collections import Counter
import csv
import hashlib
import json
from pathlib import Path
import platform
import sys

import joblib
import numpy as np
import sklearn
from sklearn.base import clone
from sklearn.ensemble import ExtraTreesClassifier, RandomForestClassifier
from sklearn.metrics import accuracy_score, balanced_accuracy_score, classification_report, confusion_matrix
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.svm import SVC

from .features import VERSION, extract
from .orientation import gravity_body

ROOT = Path(__file__).resolve().parents[2]
CLASSES = ["forehand", "backhand", "serve", "nothing"]


def candidates():
    # This fixed search space is selected inside each outer training fold.
    return {
        "extra_trees_leaf1": ExtraTreesClassifier(n_estimators=400, max_features=.75, min_samples_leaf=1,
                                                   class_weight="balanced", random_state=731, n_jobs=4),
        "extra_trees_leaf3": ExtraTreesClassifier(n_estimators=400, max_features=.75, min_samples_leaf=3,
                                                   class_weight="balanced", random_state=731, n_jobs=4),
        "random_forest": RandomForestClassifier(n_estimators=400, max_features=.6,
                                                  class_weight="balanced", random_state=731, n_jobs=4),
        **{f"svm_C{c}": make_pipeline(StandardScaler(), SVC(C=c, gamma="scale", class_weight="balanced"))
           for c in (1, 10, 100)},
    }


def metrics(y, pred, classes=CLASSES):
    return {"n": len(y), "correct": int(np.sum(y == pred)), "accuracy": float(accuracy_score(y, pred)),
            "balanced_accuracy": float(balanced_accuracy_score(y, pred)),
            "confusion_labels": classes, "confusion_matrix": confusion_matrix(y, pred, labels=classes).tolist(),
            "per_class": classification_report(y, pred, labels=classes, output_dict=True, zero_division=0)}


def load(root, invariant=False, use_gravity=False):
    rows, features, seen = [], [], {}
    for p in sorted(root.glob("person_*/*/*.csv")):
        player, label = p.parent.parent.name, p.parent.name
        if label not in CLASSES:
            raise ValueError(f"Unexpected class {label}")
        data = np.loadtxt(p, delimiter=",", skiprows=1)
        if data.shape != (1000, 6) or not np.isfinite(data).all():
            raise ValueError(f"Malformed window {p}")
        digest = hashlib.sha256(np.ascontiguousarray(data).tobytes()).hexdigest()
        if digest in seen:
            raise ValueError(f"Duplicate data: {p} and {seen[digest]}")
        seen[digest] = str(p)
        # Source acquisition uses an impact trigger with ~1 second prehistory.
        # Locate the largest acceleration near the trigger, without reading label.
        impact = int(np.argmax(np.linalg.norm(data[150:550, :3], axis=1))) + 150
        t = (np.arange(len(data)) - impact)*.003
        gyro = np.deg2rad(data[:, 3:])
        up = gravity_body(t, data[:, :3], gyro) if use_gravity else None
        features.append(extract(t, data[:, :3], gyro, invariant, up))
        rows.append({"path": str(p.relative_to(root)), "sha256_samples": digest, "player": player,
                     "label": label, "impact_index": impact})
    if not rows:
        raise ValueError(f"No raw tennis IMU recordings in {root}")
    return np.stack(features), np.array([r["label"] for r in rows]), np.array([r["player"] for r in rows]), rows


def select(x, y, groups):
    if len(set(groups)) < 2:
        raise ValueError("Model selection requires at least two independent groups")
    scores = {}
    for name, base in candidates().items():
        yy, pp = [], []
        for g in sorted(set(groups)):
            tr, va = groups != g, groups == g
            model = clone(base).fit(x[tr], y[tr])
            yy.extend(y[va]); pp.extend(model.predict(x[va]))
        scores[name] = float(balanced_accuracy_score(yy, pp))
    best = max(scores, key=scores.get)
    return best, scores, clone(candidates()[best]).fit(x, y)


def run(args):
    if args.output.exists() and any(args.output.iterdir()):
        raise ValueError("Output must be new/empty, so prior experiment evidence is preserved")
    args.output.mkdir(parents=True, exist_ok=True)
    x, y, groups, rows = load(args.data, args.invariant, args.gravity)
    if len(set(groups)) < 3:
        raise ValueError("Nested evaluation requires at least three independent players")
    pred = np.empty(y.shape, dtype=y.dtype)
    folds = []
    for g in sorted(set(groups)):
        train, test = groups != g, groups == g
        name, scores, model = select(x[train], y[train], groups[train])
        pred[test] = model.predict(x[test])
        row = {"held_player": g, "train_players": sorted(set(groups[train])), "selected_model": name,
               "inner_selection_scores": scores, **metrics(y[test], pred[test])}
        folds.append(row)
        print(f"Held out {g}: {name}, {row['accuracy']:.2%} ({row['correct']}/{row['n']})", flush=True)
    name, scores, model = select(x, y, groups)
    result = {"feature_version": VERSION, "invariant_features": args.invariant, "gravity_features": args.gravity,
              "evaluation": "nested_leave_one_player_out", "source": str(args.data.resolve()),
              "python": platform.python_version(), "numpy": np.__version__, "sklearn": sklearn.__version__,
              "class_counts": dict(Counter(y.tolist())), "players": sorted(set(groups)),
              "folds": folds, "pooled": metrics(y, pred), "final_model": name,
              "final_selection_scores": scores,
              "acceptance": {"target": .95, "own_racket_95_percent_demonstrated": False,
                             "deployment_approved": False,
                             "reasons": ["External sensor and mounting differ from Tennis Buddee",
                                         "No volley samples in this benchmark",
                                         "No independent Tennis Buddee field evaluation yet",
                                         "Only three players; correlated folds are not a deployment guarantee"]}}
    joblib.dump({"model": model, "feature_version": VERSION, "invariant": args.invariant, "gravity": args.gravity,
                 "classes": model.classes_.tolist(), "sensor_domain": "SmartTennisRacket BMI270",
                 "mount_id": "SmartTennisRacket-original", "report": result}, args.output/"research_model.joblib")
    (args.output/"metrics.json").write_text(json.dumps(result, indent=2)+"\n")
    (args.output/"manifest.json").write_text(json.dumps(rows, indent=2)+"\n")
    with (args.output/"out_of_fold_predictions.csv").open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=["path", "player", "actual", "predicted"])
        w.writeheader()
        for r, p in zip(rows, pred):
            w.writerow({"path": r["path"], "player": r["player"], "actual": r["label"], "predicted": p})
    print(f"Pooled: {result['pooled']['accuracy']:.2%}. Own-racket acceptance: NOT MET.", flush=True)
    return result


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--data", type=Path, default=ROOT/"data/external/smart_tennis_racket/repo/raw_datasets")
    p.add_argument("--output", type=Path, required=True)
    p.add_argument("--invariant", action="store_true")
    p.add_argument("--gravity", action="store_true", help="Causal gravity-relative angular motion")
    args = p.parse_args()
    try:
        run(args)
    except (ValueError, OSError) as e:
        p.exit(1, f"Error: {e}\n")


if __name__ == "__main__":
    main()
