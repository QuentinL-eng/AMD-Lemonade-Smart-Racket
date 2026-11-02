"""Train on reviewed own-racket sessions, select on validation, then test once.

Invalid/missing windows count as errors in evaluation. A classifier never earns
95% by silently omitting difficult impacts or by filtering its confidence.
"""
import argparse
from collections import Counter
import json
from pathlib import Path

import joblib
import numpy as np
from sklearn.base import clone
from sklearn.metrics import accuracy_score, confusion_matrix

from .benchmark import candidates
from .dataset import LABELS, STROKES, load_manifest, public_row
from .features import VERSION


def wilson(correct, n, z=1.96):
    if not n:
        return [0., 1.]
    p = correct/n
    a = p+z*z/(2*n)
    b = z*np.sqrt(p*(1-p)/n+z*z/(4*n*n))
    return [float((a-b)/(1+z*z/n)), float((a+b)/(1+z*z/n))]


def predict_rows(model, rows):
    pred = np.full(len(rows), "unknown", dtype="<U16")
    good = [i for i, r in enumerate(rows) if r["features"] is not None]
    if good:
        pred[good] = model.predict(np.stack([rows[i]["features"] for i in good]))
    return pred


def evaluate(rows, pred):
    y = np.array([r["shot_type"] for r in rows])
    per_class = {}
    for c in LABELS:
        mask = y == c
        n, right = int(mask.sum()), int(np.sum((pred == c) & mask))
        per_class[c] = {"n": n, "correct": right, "recall": right/n if n else None,
                        "wilson95": wilson(right, n)}
    right = int(np.sum(y == pred))
    counts = Counter(r["reject"] for r in rows if r["reject"])
    return {"n": len(y), "correct": right, "accuracy": float(accuracy_score(y, pred)),
            "balanced_accuracy": float(np.mean([v["recall"] for v in per_class.values() if v["n"]])),
            "wilson95": wilson(right, len(y)), "per_class": per_class,
            "unknown_count": int(np.sum(pred == "unknown")), "quality_rejects": dict(counts),
            "confusion_labels": LABELS+["unknown"],
            "confusion_matrix": confusion_matrix(y, pred, labels=LABELS+["unknown"]).tolist(),
            "interval_note": "Binomial intervals assume independent hits; same-session hits are correlated."}


def fit_rows(base, rows):
    good = [r for r in rows if r["features"] is not None]
    missing = set(STROKES)-{r["shot_type"] for r in good}
    if missing:
        raise ValueError(f"No usable training windows for {sorted(missing)}")
    return clone(base).fit(np.stack([r["features"] for r in good]), [r["shot_type"] for r in good])


def run(args):
    rows = load_manifest(args.manifest, args.mode)
    train = [r for r in rows if r["split"] == "train"]
    val = [r for r in rows if r["split"] == "validation"]
    test = [r for r in rows if r["split"] == "test"]
    if args.output.exists() and any(args.output.iterdir()):
        raise ValueError("Choose a new empty output directory to preserve experiment history")
    scores = {}
    for name, base in candidates().items():
        model = fit_rows(base, train)
        scores[name] = evaluate(val, predict_rows(model, val))
        print(f"Validation {name}: {scores[name]['accuracy']:.2%}", flush=True)
    best = max(scores, key=lambda k: (scores[k]["balanced_accuracy"], scores[k]["accuracy"]))
    # Test influences neither the model choice nor the fit.
    model = fit_rows(candidates()[best], train+val)
    pred = predict_rows(model, test)
    score = evaluate(test, pred)
    every_stroke = all(score["per_class"][c]["recall"] >= .95 for c in STROKES)
    target = score["accuracy"] >= .95 and every_stroke
    result = {"feature_version": VERSION, "selected_model": best, "mode": args.mode,
              "mount_id": rows[0]["mount_id"], "validation": scores, "test": score,
              "acceptance": {"target_accuracy": .95, "target_met_on_this_test": bool(target),
                             "every_stroke_recall_at_least_95": bool(every_stroke),
                             "independent_test_sessions": sorted({r["session_id"] for r in test}),
                             "test_players": sorted({r["player_id"] for r in test}),
                             "scope": "Reviewed contacts in the supplied field test; detection misses require a full video census",
                             "stronger_binomial_lower_bound_at_least_95": score["wilson95"][0] >= .95,
                             "speed_accuracy_validated": False}}
    args.output.mkdir(parents=True, exist_ok=True)
    joblib.dump({"model": model, "feature_version": VERSION, "invariant": False, "gravity": False,
                 "classes": model.classes_.tolist(), "sensor_domain": "Tennis Buddee",
                 "mount_id": rows[0]["mount_id"], "mode": args.mode, "report": result}, args.output/"model.joblib")
    (args.output/"metrics.json").write_text(json.dumps(result, indent=2)+"\n")
    (args.output/"manifest.json").write_text(json.dumps([public_row(r) for r in rows], indent=2)+"\n")
    predictions = [{**public_row(r), "predicted": str(p)} for r, p in zip(test, pred)]
    (args.output/"test_predictions.json").write_text(json.dumps(predictions, indent=2)+"\n")
    print(f"Test {score['correct']}/{score['n']} = {score['accuracy']:.2%}; target {'MET' if target else 'NOT MET'}", flush=True)
    return result


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("manifest", type=Path)
    p.add_argument("--output", type=Path, required=True)
    p.add_argument("--mode", choices=["personalized", "player-independent"], default="personalized")
    args = p.parse_args()
    try:
        run(args)
    except (ValueError, OSError) as e:
        p.exit(1, f"Error: {e}\n")


if __name__ == "__main__":
    main()
