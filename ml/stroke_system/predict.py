"""Apply a locally trained model to one contact in an original app CSV."""
import argparse
import json
from pathlib import Path

import joblib
import numpy as np

from .features import VERSION, extract
from .orientation import gravity_body


def infer(bundle, t, accel, gyro, mount_id):
    if bundle["feature_version"] != VERSION:
        raise ValueError("Model and feature extractor versions differ")
    if bundle["mount_id"] != mount_id:
        return {"shot_type": "unknown", "reason": "Model belongs to a different sensor mounting"}
    try:
        up = gravity_body(t, accel, gyro) if bundle.get("gravity") else None
        x = extract(t, accel, gyro, bundle.get("invariant", False), up)
    except ValueError as e:
        return {"shot_type": "unknown", "reason": str(e)}
    return {"shot_type": str(bundle["model"].predict(x[None])[0]),
            "classes_supported": bundle["classes"], "sensor_domain": bundle["sensor_domain"],
            "accuracy_claim": "See held-out metrics; no per-prediction accuracy guarantee"}


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("model", type=Path)
    p.add_argument("recording", type=Path)
    p.add_argument("--contact-s", type=float, required=True)
    p.add_argument("--gyro-scale", type=float, required=True, help="Explicit correction, e.g. 0.5 for confirmed 2x bug")
    p.add_argument("--mount-id", required=True)
    args = p.parse_args()
    if not np.isfinite(args.gyro_scale) or args.gyro_scale <= 0:
        p.error("gyro-scale must be finite and positive")
    d = np.loadtxt(args.recording, delimiter=",", skiprows=1, ndmin=2)
    if d.shape[1] != 10:
        p.error("Expected ten-column original app CSV")
    bundle = joblib.load(args.model)
    if bundle.get("gravity"):
        p.error("Gravity research models require continuous orientation state; use benchmark for evaluation")
    lo = max(0, int(np.searchsorted(d[:, 0], args.contact_s-.350))-1)
    hi = min(len(d), int(np.searchsorted(d[:, 0], args.contact_s+.060))+1)
    d = d[lo:hi]
    result = infer(bundle, d[:, 0]-args.contact_s, d[:, 1:4], d[:, 4:7]*args.gyro_scale, args.mount_id)
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
