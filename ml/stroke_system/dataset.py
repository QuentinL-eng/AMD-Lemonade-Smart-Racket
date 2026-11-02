"""Strict manifest for reviewed Tennis Buddee recordings, with explicit splits."""
import csv
import hashlib
from pathlib import Path

import numpy as np

from .features import extract

STROKES = ["forehand", "backhand", "serve", "volley"]
LABELS = STROKES + ["nothing"]
FIELDS = ["recording", "player_id", "session_id", "split", "shot_type", "contact_s",
          "gyro_scale", "mount_id", "verified_by", "provenance"]
HEADER = ["time_s", "ax_g", "ay_g", "az_g", "gx_rads", "gy_rads", "gz_rads", "hx_g", "hy_g", "hz_g"]


def load_manifest(path, mode="personalized"):
    """Return all rows, retaining bad windows as rejects, including during scoring.

    Labels must be reviewed before entry. Rows are absolute contact seconds in
    their original recording clock, never sequential auto-matched labels.
    """
    path = Path(path)
    with path.open(newline="") as f:
        reader = csv.DictReader(f)
        if not set(FIELDS).issubset(reader.fieldnames or []):
            raise ValueError(f"Manifest requires {', '.join(FIELDS)}")
        rows = list(reader)
    if not rows:
        raise ValueError("Empty manifest")
    recordings, session_roles, player_roles, fingerprints, event_keys = {}, {}, {}, {}, set()
    output = []
    for row in rows:
        if any(not row[k].strip() for k in FIELDS):
            raise ValueError("Missing manifest metadata; each label needs a named reviewer")
        role, label = row["split"], row["shot_type"]
        if role not in ("train", "validation", "test") or label not in LABELS:
            raise ValueError(f"Unsupported split or label: {role}, {label}")
        if row["provenance"] != "real_racket":
            raise ValueError("Own-racket manifests accept only real_racket recordings; robot, synthetic and external data cannot establish acceptance")
        session, player = row["session_id"], row["player_id"]
        if session in session_roles and session_roles[session] != role:
            raise ValueError(f"Session {session} crosses splits")
        session_roles[session] = role
        player_roles.setdefault(player, set()).add(role)
        p = (path.parent/row["recording"]).resolve()
        if p not in recordings:
            with p.open() as f:
                if f.readline().strip().split(",") != HEADER:
                    raise ValueError(f"Expected app CSV header in {p}")
            d = np.loadtxt(p, delimiter=",", skiprows=1, ndmin=2)
            if len(d) < 2 or d.shape[1] != 10 or not np.isfinite(d).all() or np.any(np.diff(d[:, 0]) <= 0):
                raise ValueError(f"Bad timestamps or sensor data in {p}")
            file_hash = hashlib.sha256(np.ascontiguousarray(d).tobytes()).hexdigest()
            # Identical raw recordings must never acquire a new split by copying/renaming them.
            if file_hash in fingerprints and fingerprints[file_hash][0] != role:
                raise ValueError(f"Identical recording crosses splits: {p}")
            fingerprints[file_hash] = (role, p)
            recordings[p] = (d, file_hash, role, session, player, float(row["gyro_scale"]))
        d, file_hash, old_role, old_session, old_player, old_scale = recordings[p]
        scale = float(row["gyro_scale"])
        if not np.isfinite(scale) or scale <= 0 or scale > 2:
            raise ValueError("Explicit gyro_scale must be positive and at most 2")
        if (role, session, player, scale) != (old_role, old_session, old_player, old_scale):
            raise ValueError(f"Recording metadata is inconsistent: {p}")
        contact = float(row["contact_s"])
        if not np.isfinite(contact):
            raise ValueError("Contact must be finite")
        key = (file_hash, contact)
        if key in event_keys:
            raise ValueError("Duplicate contact in manifest")
        event_keys.add(key)
        lo = max(0, int(np.searchsorted(d[:, 0], contact-.350))-1)
        hi = min(len(d), int(np.searchsorted(d[:, 0], contact+.060))+1)
        # Overlapping windows of one recording cannot masquerade as independent events.
        if any(r["recording_hash"] == file_hash and abs(r["contact_s"]-contact) < .410 for r in output):
            raise ValueError("Duplicate or overlapping contact windows")
        window = d[lo:hi].copy()
        window[:, 0] -= contact
        window[:, 4:7] *= scale
        sample_hash = hashlib.sha256(np.ascontiguousarray(window).tobytes()).hexdigest()
        if any(r["sample_hash"] == sample_hash for r in output):
            raise ValueError("Duplicate sensor window")
        try:
            features = extract(window[:, 0], window[:, 1:4], window[:, 4:7])
            reject = None
        except ValueError as e:
            features, reject = None, str(e)
        output.append({**row, "contact_s": contact, "gyro_scale": scale, "recording": str(p),
                       "recording_hash": file_hash, "sample_hash": sample_hash,
                       "features": features, "reject": reject, "window": window,
                       "gyro_saturated": bool(np.any(abs(window[:, 4:7]) >= 34.8))})
    if len({r["mount_id"] for r in output}) != 1:
        raise ValueError("Train one explicitly calibrated mounting at a time")
    if mode == "personalized" and len(player_roles) != 1:
        raise ValueError("Personalized model requires one player; choose player-independent for multiple players")
    if mode == "player-independent" and any(len(roles) > 1 for roles in player_roles.values()):
        raise ValueError("Player crosses splits in player-independent evaluation")
    for role in ("train", "validation", "test"):
        missing = set(STROKES) - {r["shot_type"] for r in output if r["split"] == role}
        if missing:
            raise ValueError(f"{role} is missing required stroke labels: {sorted(missing)}")
    return output


def public_row(row):
    return {k: v for k, v in row.items() if k not in ("features", "window")}
