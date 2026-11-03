"""Run tsm_e2espot over whole videos in overlapping chunks, find hit events, classify stroke type and hitter."""
import glob, json, math, os, sys, time
import cv2, numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import f3infer as F

THRESH, MIN_SEP = float(os.environ.get("F3_THRESH", "0.35")), 8   # event mass; min separation in sampled frames (0.64 s)
CHUNK, OVERLAP = 2400, 192                                          # source frames


def prep(f):
    h, w = f.shape[:2]
    f = cv2.resize(f, (w * 224 // h, 224))
    x0 = (f.shape[1] - 224) // 2
    return cv2.cvtColor(f[:, x0:x0 + 224], cv2.COLOR_BGR2RGB)


def stream(model, path):
    """Frames are resampled to the model's 25 fps first (it was trained on 25 fps video)."""
    cap = cv2.VideoCapture(path)
    n = int(cap.get(cv2.CAP_PROP_FRAME_COUNT)); src_fps = cap.get(cv2.CAP_PROP_FPS) or 25.0
    nk = int(n * 25.0 / src_fps)
    ns = math.ceil(nk / 2) + 2
    acc = np.zeros((ns, 1109), np.float32); cnt = np.zeros(ns, np.float32)
    buf, start, kept, i = [], 0, 0, 0
    def flush(buf, start):
        if len(buf) < 8:
            return
        P = F.predict(model, np.stack(buf))
        s0 = start // 2
        acc[s0:s0 + len(P)] += P; cnt[s0:s0 + len(P)] += 1
    while True:
        ok, f = cap.read()
        if ok:
            if i >= round(kept * src_fps / 25.0):
                buf.append(prep(f)); kept += 1
            i += 1
        if len(buf) >= CHUNK or (not ok and buf):
            flush(buf, start)
            if not ok:
                break
            start += len(buf) - OVERLAP
            buf = buf[-OVERLAP:]
        if not ok:
            break
    cap.release()
    return acc / np.maximum(cnt, 1)[:, None], 25.0, kept, src_fps


def events(P, T, H, mass):
    out = []
    for i in range(1, len(mass) - 1):
        if mass[i] >= THRESH and mass[i] >= mass[i - 1] and mass[i] > mass[i + 1]:
            if out and i - out[-1]["_i"] < MIN_SEP:
                if mass[i] > out[-1]["peak"]:
                    out.pop()
                else:
                    continue
            out.append({"_i": i, "peak": float(mass[i])})
    res = []
    table = F.class_table()
    for e in out:
        f = e["_i"] * 2
        r = F.classify_at(T, H, f)
        if r:
            res.append({"frame": f, "peak": round(e["peak"], 3), **{k: (round(v, 3) if isinstance(v, float) else v) for k, v in r.items()}})
    return res


if __name__ == "__main__":
    model = F.load_model(); table = F.class_table()
    for v in sorted(glob.glob(r"D:\Projects\Hardware\f3tennis-env\video\pros\*.mp4")):
        out = v[:-4] + ".ev25.json"
        if os.path.exists(out):
            continue
        t0 = time.time()
        P, fps, n, src_fps = stream(model, v)
        T, H, mass = F.marginals(P, table)
        ev = events(P, T, H, mass)
        for e in ev:
            e["t_s"] = round(e["frame"] / fps, 2)
        json.dump({"video": os.path.basename(v), "fps": fps, "source_fps": src_fps, "frames": n, "thresh": THRESH, "events": ev}, open(out, "w"), indent=1)
        by = {}
        for e in ev:
            by[e["type"]] = by.get(e["type"], 0) + 1
        print(f"{os.path.basename(v)}: {n} frames {fps:.0f}fps -> {len(ev)} events {by} in {time.time()-t0:.0f}s", flush=True)
