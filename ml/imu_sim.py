"""Would the handle IMU help locate the contact point? A physics simulation, not a measurement.

For each real labelled hit (x_cm across the face, y_cm toward the tip) this builds the 1 kHz gyro + high-g accelerometer
window a rigid racket would produce, using the real sensor specs and noise floor from the 29 Oct robot runs
(gyro 0.0035 rad/s, high-g 0.05 g, 1 kHz) and the real fitted IMU-from-tool matrix (data/room-2026-10-29/gyro_calibration.json).

Physics: free rigid body struck by a half-sine normal impulse J at (a, x) from the centre of mass.
  d_omega = (x J / Ix, -a J / Iy), a = 0.17 m + y;   v_imu = J/M + 0.33 m * d_omega_y     (IMU at the butt)
J varies a lot hit to hit (ball speed 3-9 m/s), so the useful signal is in ratios (as the audio features are level
invariant). Everything the robot validation could not give is an ASSUMPTION and is stress-tested below:
racket inertias, COM position, hand damping, frame vibration, trigger jitter, mount error, label noise.

    python ml/imu_sim.py        # writes ml/runs/20261103-imu-sim/results.json
"""
import json
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).parent))
from model_selection import KRR, MLP, Ridge, course_features, cv, load, score  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "ml/runs/20261103-imu-sim"
M_IMU_FROM_TOOL = np.array(json.load(open(ROOT / "data/room-2026-10-29/gyro_calibration.json"))["M_imu_from_tool"])

BASE = dict(noise_gyro=0.0035, noise_hg=0.05, jitter_ms=1.0, mount_deg=3.0, label_sd_cm=0.0, vib=0.3, tau_ms=(15, 40),
            inertia_err=0.0, tremor=0.2, hand_scale=1.0)
DT = 5e-5            # 20 kHz internal grid, decimated to the 1 kHz sensor rate


def rot(v):
    a = np.linalg.norm(v)
    if a < 1e-12:
        return np.eye(3)
    k = v / a
    K = np.array([[0, -k[2], k[1]], [k[2], 0, -k[0]], [-k[1], k[0], 0]])
    return np.eye(3) + np.sin(a) * K + (1 - np.cos(a)) * K @ K


def simulate(xy_cm, rng, scn, R_mount):
    """One hit -> feature vector from the IMU window. Tool frame: x toward the tip, y across the face, z face normal."""
    p = {**BASE, **scn}
    M, Ix, Iy, d, r_imu = 0.30, 0.0016, 0.0145, 0.17, -0.33          # kg, kg m^2, kg m^2, m, m
    kx, ky = 1 + p["inertia_err"] * rng.normal(), 1 + p["inertia_err"] * rng.normal()
    Ix_t, Iy_t = Ix * kx, Iy * ky                                   # truth differs from what the model could assume
    x, y = (xy_cm + p["label_sd_cm"] * rng.normal(size=2)) / 100.0   # true contact (label noise = label is not exact)
    a, b = d + y, x
    v_in, e, mb = rng.uniform(3, 9), rng.uniform(0.35, 0.55), 0.057
    Me = 1 / (1 / M + b * b / Ix_t + a * a / Iy_t)
    J = (1 + e) * v_in / (1 / mb + 1 / Me)
    dw = np.array([b * J / Ix_t, -a * J / Iy_t, 0.0])                # tool frame (x = long axis)
    T = rng.uniform(0.004, 0.006)
    tau = rng.uniform(*p["tau_ms"]) / 1000 * p["hand_scale"]
    t0 = rng.normal(0, p["jitter_ms"]) / 1000                        # trigger error vs true contact
    t = np.arange(-0.06, 0.08, DT)
    s = t - 0.0                                                      # contact starts at 0 in this frame
    pulse = np.where((s >= 0) & (s <= T), np.pi / (2 * T) * np.sin(np.pi * s / T), 0.0)
    step = np.where(s < 0, 0.0, np.where(s <= T, (1 - np.cos(np.pi * s / T)) / 2, 1.0))
    decay = np.exp(-np.maximum(s - T, 0) / tau)
    vib_f, vib_z = rng.uniform(110, 170), 0.03
    vib_env = np.where(s > T / 2, np.exp(-(s - T / 2) * vib_z * 2 * np.pi * vib_f), 0.0) * np.sin(2 * np.pi * vib_f * (s - T / 2))
    vib_amp = p["vib"] * rng.normal() * (0.5 + abs(x) / 0.05 + abs(y) / 0.05)
    g_n = 1 / M + (-r_imu) * (-a / Iy_t)                             # IMU accel per unit force: 1/M - 0.33 a / Iy
    acc_n = J * pulse * g_n + vib_amp * J * g_n * 0.5 * vib_env       # m/s^2, tool z
    gyro = np.stack([dw[0] * step * decay, dw[1] * step * decay, np.zeros_like(t)], 1)
    gyro[:, 1] += vib_amp * dw[1] * 0.3 * vib_env
    # hand: slow tremor + offset, gravity along the face normal
    ph = rng.uniform(0, 6.28, size=(3, 3)); fr = rng.uniform(3, 10, size=(3, 3)); am = p["tremor"] * rng.uniform(0.2, 1, size=(3, 3))
    trem = np.stack([(am[i] * np.sin(2 * np.pi * fr[i] * t[:, None] + ph[i])).sum(1) for i in range(3)], 1)
    gyro += trem
    acc = np.zeros((len(t), 3))
    acc[:, 2] = acc_n + 9.81
    acc += 0.1 * trem
    acc[:, 0] += rng.normal(0, 0.3)
    # tool -> IMU frame (real calibration), then the per-session mount error the model cannot know
    A = M_IMU_FROM_TOOL @ R_mount
    gyro, acc = gyro @ A.T, acc @ A.T
    # sample at 1 kHz with a random sub-ms phase and a 1 ms box average (sensor decimation)
    n = int(round(1e-3 / DT)); ph0 = int(rng.integers(0, n)) + int(round(t0 / DT))
    k = (len(t) - ph0 - n) // n
    idx = ph0 + np.arange(k)[:, None] * n + np.arange(n)[None, :]
    g1, a1 = gyro[idx].mean(1), acc[idx].mean(1)
    ts = t[ph0 + np.arange(k) * n]
    g1 = np.clip(g1 + rng.normal(0, p["noise_gyro"], g1.shape), -34.9, 34.9)
    a1 = np.clip(a1 + 9.81 * rng.normal(0, p["noise_hg"], a1.shape), -3924, 3924)
    pre = (ts > -0.045) & (ts < -0.01); post = (ts > T + 0.003) & (ts < T + 0.012); win = (ts > -0.002) & (ts < T + 0.008)
    dwm = g1[post].mean(0) - g1[pre].mean(0)
    dvm = (a1[win] - a1[pre].mean(0)).sum(0) * 1e-3
    apk = np.abs(a1[win] - a1[pre].mean(0)).max(0)
    ring = (a1[(ts > T + 0.01) & (ts < T + 0.05)] - a1[pre].mean(0)).std(0).mean()
    nrm = np.linalg.norm(dwm) + 1e-6
    return np.r_[dwm, dvm, np.log10(apk + 1e-3), np.log10(ring + 1e-6), dwm / nrm, dvm / nrm]


def build(xy, groups, scn, seed=0):
    rng = np.random.default_rng(seed)
    sessions = sorted({g.split(":")[0] for g in groups})
    R = {s: rot(np.deg2rad(scn.get("mount_deg", BASE["mount_deg"])) * rng.normal(size=3)) for s in sessions}
    return np.stack([simulate(xy[i], rng, scn, R[groups[i].split(":")[0]]) for i in range(len(xy))])


def gp_pick(X, Y, G):
    best = None
    for ls in (0.5, 1.0, 2.0):
        for lam in (0.03, 0.1, 0.3, 1.0):
            r = cv(lambda ls=ls, lam=lam: KRR(ls, lam), X, Y, G, reps=2)
            if best is None or r["w1"] > best[0]["w1"]:
                best = (r, f"gp ls={ls} lam={lam}", (ls, lam))
    return best


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    clips, Y, G, _, _ = load()
    audio = np.load(ROOT / "ml/runs/20261103-model-selection/features.npz")["current156"]
    res = {}
    sw = {
        "ideal physics (stated assumptions)": {},
        "noise x5": dict(noise_gyro=0.0175, noise_hg=0.25),
        "trigger jitter 3 ms": dict(jitter_ms=3.0),
        "mount error 10 deg per session": dict(mount_deg=10.0),
        "inertia off by 20%": dict(inertia_err=0.2),
        "frame vibration x3": dict(vib=0.9),
        "hand clamps fast (5 ms)": dict(tau_ms=(4, 6)),
        "label noise 0.7 cm": dict(label_sd_cm=0.7),
        "pessimistic: all of the above, milder": dict(noise_gyro=0.0105, noise_hg=0.15, jitter_ms=2.0, mount_deg=6.0,
                                                         inertia_err=0.1, vib=0.6, tau_ms=(8, 25), label_sd_cm=0.5),
    }
    for name, scn in sw.items():
        X = build(Y, G, scn)
        r_imu = gp_pick(X, Y, G)
        Xc = np.hstack([X, audio[:, :]])
        r_both = cv(lambda: KRR(1.0, 0.3), Xc, Y, G, reps=2)
        res[name] = {"imu_only": r_imu[0] | {"model": r_imu[1]}, "imu+audio": r_both}
        print(f"{name:40} IMU only: mean {r_imu[0]['mean_cm']:.2f} cm  within1 {r_imu[0]['w1']:.0%} within2 {r_imu[0]['w2']:.0%}"
              f" ({r_imu[1]}) | IMU+audio: within1 {r_both['w1']:.0%}", flush=True)
    json.dump(res, open(OUT / "results.json", "w"), indent=1)


if __name__ == "__main__":
    main()
