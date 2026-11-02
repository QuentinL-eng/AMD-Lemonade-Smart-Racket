"""Features that fit the existing 384 ms pre / 64 ms post impact buffer.

Inputs use seconds, g, radians/second, and a consistent sensor mounting frame.
No class labels, player IDs, file names or post-window samples enter features.
"""
import numpy as np

VERSION = "stroke-350pre-60post-v1"
GRID = np.linspace(-.350, .060, 138)


def validate_window(t, accel, gyro, max_gap_s=.012):
    t, accel, gyro = (np.asarray(a, dtype=float) for a in (t, accel, gyro))
    if t.ndim != 1 or accel.shape != (len(t), 3) or gyro.shape != accel.shape:
        raise ValueError("Expected times [n], accelerometer [n,3], gyroscope [n,3]")
    if len(t) < 20 or not all(np.isfinite(a).all() for a in (t, accel, gyro)):
        raise ValueError("Missing or non-finite samples")
    if np.any(np.diff(t) <= 0):
        raise ValueError("Timestamps must strictly increase")
    if t[0] > GRID[0] or t[-1] < GRID[-1]:
        raise ValueError("Need 350 ms before and 60 ms after contact")
    # Only gaps intersecting the inference window matter.
    active = (t[:-1] < GRID[-1]) & (t[1:] > GRID[0])
    gap = float(np.diff(t)[active].max())
    if gap > max_gap_s:
        raise ValueError(f"IMU gap {1000*gap:.1f} ms exceeds {1000*max_gap_s:.1f} ms")
    return t, accel, gyro, gap


def extract(t, accel, gyro, invariant=False, gravity=None):
    t, a, w, _ = validate_window(t, accel, gyro)
    a = np.stack([np.interp(GRID, t, a[:, k]) for k in range(3)], axis=1)
    w = np.stack([np.interp(GRID, t, w[:, k]) for k in range(3)], axis=1)
    # Norms and inter-vector dot products survive a fixed rotation of the mount.
    an, wn = np.linalg.norm(a, axis=1), np.linalg.norm(w, axis=1)
    da, dw = np.diff(a, axis=0, prepend=a[:1]), np.diff(w, axis=0, prepend=w[:1])
    inv = np.column_stack([an, wn, np.sum(a*w, axis=1),
                           np.linalg.norm(da, axis=1), np.linalg.norm(dw, axis=1)])
    signals = inv if invariant else np.column_stack([a, w, inv])
    if gravity is not None:
        gravity = np.asarray(gravity, dtype=float)
        if gravity.shape != (len(t), 3) or not np.isfinite(gravity).all():
            raise ValueError("Expected finite gravity [n,3]")
        up = np.stack([np.interp(GRID, t, gravity[:, k]) for k in range(3)], axis=1)
        up /= np.maximum(np.linalg.norm(up, axis=1, keepdims=True), 1e-8)
        av, wv = np.sum(a*up, axis=1), np.sum(w*up, axis=1)
        signals = np.column_stack([signals, av, wv, wv/np.maximum(wn, 1e-6),
                                    np.sqrt(np.maximum(0, wn*wn-wv*wv))])
    out = []
    for lo, hi in [(-.350, -.180), (-.180, -.060), (-.060, -.006), (-.006, .012), (.012, .061)]:
        x = signals[(GRID >= lo) & (GRID < hi)]
        out.extend([x.mean(0), x.std(0), np.sqrt((x*x).mean(0)),
                    np.quantile(x, .1, axis=0), np.quantile(x, .9, axis=0)])
    # Temporal direction and shape, in addition to pooled energy.
    for x in np.array_split(signals, 12):
        out.append(x.mean(0))
    for lo, hi in [(-.350, -.006), (-.180, -.006), (-.060, -.006)]:
        mask = (GRID >= lo) & (GRID <= hi)
        out.append(np.atleast_1d(np.trapezoid(wn[mask], GRID[mask])))
    result = np.concatenate(out).astype(np.float32)
    if not np.isfinite(result).all():
        raise ValueError("Non-finite features")
    return result
