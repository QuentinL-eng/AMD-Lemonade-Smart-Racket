"""Fit speed only against measured references; evaluate on the held-out sessions.

This does not turn angular speed into measured ball speed. A fitted empirical
ball-speed model still needs reference measurements on independent rally shots.
"""
import argparse
import json
from pathlib import Path

import numpy as np

from .dataset import load_manifest


def angular_features(row, shaft_axis):
    if row["reject"] or row.get("gyro_saturated", False):
        return None
    w = row["window"]
    pre = w[(w[:, 0] >= -.010) & (w[:, 0] < -.002), 4:7]
    post = w[(w[:, 0] >= .012) & (w[:, 0] < .030), 4:7]
    if len(pre) < 3 or len(post) < 3:
        return None
    across = [i for i in range(3) if i != shaft_axis]
    before, after = (float(np.linalg.norm(x.mean(0)[across])) for x in (pre, post))
    return np.array([before, max(0., before-after)])


def fit_radius(x, y, gain):
    z = x[:, 0]+gain*x[:, 1]
    if z@z < 1e-10:
        raise ValueError("No rotational motion in reference hits")
    # Effective arm includes hand/arm translation absorbed into a single scale.
    # Bounds are explicit model constraints, not evidence of physical accuracy.
    return float(np.clip((z@y)/(z@z), .1, 2.))


def summarize(y, pred):
    good = np.isfinite(pred)
    err = pred[good]-y[good]
    relative = abs(err)/y[good]
    if not good.any():
        return {"n": len(y), "predicted": 0, "missing": len(y)}
    return {"n": len(y), "predicted": int(good.sum()), "missing": int((~good).sum()),
            "mae_m_s": float(abs(err).mean()), "rmse_m_s": float(np.sqrt((err*err).mean())),
            "bias_m_s": float(err.mean()), "mean_absolute_percentage_error": float(relative.mean()),
            "p95_absolute_percentage_error": float(np.quantile(relative, .95)),
            "fraction_of_all_reference_hits_within_5_percent": float(np.sum(relative <= .05)/len(y)),
            "error_metric_scope": "Error summaries cover predicted hits; within-5% denominator includes missing hits"}


def run(args):
    rows = load_manifest(args.manifest, args.mode)
    key = f"{args.kind}_speed_reference_ms"
    refs = []
    for row in rows:
        if not row.get(key, "").strip():
            continue
        y = float(row[key])
        if not np.isfinite(y) or y <= 0 or not row.get("reference_source", "").strip():
            raise ValueError("Speed references need a positive m/s value and reference_source")
        refs.append({"row": row, "y": y, "x": angular_features(row, "xyz".index(args.shaft_axis))})
    tr = [r for r in refs if r["row"]["split"] == "train" and r["x"] is not None]
    va = [r for r in refs if r["row"]["split"] == "validation"]
    te = [r for r in refs if r["row"]["split"] == "test"]
    if len(tr) < 8 or not va or not te or not any(r["x"] is not None for r in va):
        raise ValueError("Need at least 8 usable training references, usable validation references and held-out test references")
    tx, ty = np.stack([r["x"] for r in tr]), np.array([r["y"] for r in tr])
    gains = [0.] if args.kind == "racket" else np.linspace(0, 4, 81)
    scored = []
    for gain in gains:
        radius = fit_radius(tx, ty, gain)
        # A missing prediction cannot improve model selection; same fixed missing
        # set for all candidates, and test reports coverage separately.
        error = [abs(radius*(r["x"][0]+gain*r["x"][1])-r["y"]) for r in va if r["x"] is not None]
        scored.append((float(np.mean(error)), float(gain)))
    _, gain = min(scored)
    fit = tr+[r for r in va if r["x"] is not None]
    radius = fit_radius(np.stack([r["x"] for r in fit]), np.array([r["y"] for r in fit]), gain)
    pred = np.array([radius*(r["x"][0]+gain*r["x"][1]) if r["x"] is not None else np.nan for r in te])
    score = summarize(np.array([r["y"] for r in te]), pred)
    result = {"kind": args.kind, "unit": "m/s", "effective_radius_m": radius, "impulse_gain": gain,
              "shaft_axis_in_input_sensor_frame": args.shaft_axis, "test": score,
              "model": "radius * (pre_contact_angular_speed_across_shaft + gain * nonnegative_speed_drop)",
              "test_sessions": sorted({r["row"]["session_id"] for r in te}),
              "scope": "Empirical estimate for the measured protocol; separate validation required when feed/pace/grip changes"}
    if args.output.exists():
        raise ValueError("Choose a new output file to preserve prior results")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(result, indent=2)+"\n")
    print(json.dumps(result, indent=2))


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("manifest", type=Path)
    p.add_argument("--kind", choices=["ball", "racket"], required=True)
    p.add_argument("--shaft-axis", choices=["x", "y", "z"], required=True,
                   help="Racket's long axis in the original sensor frame, from mounting calibration")
    p.add_argument("--mode", choices=["personalized", "player-independent"], default="personalized")
    p.add_argument("--output", type=Path, required=True)
    try:
        run(p.parse_args())
    except (OSError, ValueError) as e:
        p.exit(1, f"Error: {e}\n")


if __name__ == "__main__":
    main()
