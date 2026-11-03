import glob, json, os, re, sys, time, collections
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import f3infer as F
sys.path.insert(0, r"D:\Projects\Hardware\Smart Racket\tools")
import f3set_to_emulator as fe

table = F.class_table()
model = F.load_model()
SAM = r"D:\Projects\Hardware\Smart Racket\data\external\f3set\sam_video"
rows, offs = [], []
t_all = time.time()
for v in sorted(glob.glob(r"D:\Projects\Hardware\f3tennis-env\video\ostrava\*.mp4")):
    base = os.path.basename(v)
    m = re.search(r"(.+?)_(\d+)_(\d+)__t0_([\d.]+)\.mp4$", base)
    a, t0 = int(m.group(2)), float(m.group(4))
    frames, fps = F.load_frames(v)
    P = F.predict(model, frames)
    T, H, mass = F.marginals(P, table)
    d = json.load(open(os.path.join(SAM, base.split("__")[0] + ".json")))
    evs = [e for e in d["events"] if fe.parse_label(e["label"])["hitter"]]
    base_off = round(a - t0 * 25)
    # sanity: which small shift of the label timeline best matches the model's own event mass?
    best = max(range(-8, 9), key=lambda s: sum(mass[max(0, (base_off + e["frame"] + s) // 2 - 1):(base_off + e["frame"] + s) // 2 + 2].sum() for e in evs))
    offs.append(best)
    for e in evs:
        lab = fe.parse_label(e["label"])
        truth = fe.app_type(lab)
        f = base_off + e["frame"] + best
        r = F.classify_at(T, H, f)
        rows.append({"clip": base[-30:], "truth": truth, "hitter": lab["hitter"], "outcome": lab["outcome"], "pred": r and r["type"], "pred_hitter": r and r["hitter"], "conf": r and r["conf"], "mass": r and r["mass"]})
    print(f"{base[-34:-4]}: {len(frames)} frames {fps:.0f}fps, {len(evs)} events, shift {best:+d}", flush=True)
print("video seconds per wall second:", round(sum(len(F.load_frames(v)[0]) for v in []) or 0, 1), "| total wall", round(time.time() - t_all, 1), "s")
json.dump(rows, open("eval_ostrava.json", "w"), indent=1)

n = len(rows)
ok = sum(r["pred"] == r["truth"] for r in rows)
print(f"\nstroke type (serve/fh/bh/volley): {ok}/{n} = {100*ok/n:.0f}%")
non_serve = [r for r in rows if r["truth"] in ("forehand", "backhand")]
fb = sum(r["pred"] == r["truth"] for r in non_serve)
print(f"forehand vs backhand only (true fh/bh hits): {fb}/{len(non_serve)} = {100*fb/len(non_serve):.0f}%")
sv = [r for r in rows if r["truth"] == "serve"]
print(f"serves found as serve: {sum(r['pred']=='serve' for r in sv)}/{len(sv)}")
hit = sum(r["pred_hitter"] == r["hitter"] for r in rows)
print(f"near/far hitter: {hit}/{n} = {100*hit/n:.0f}%")
maj = collections.Counter(r["truth"] for r in rows).most_common(1)[0]
print(f"majority-class baseline: {maj[0]} {100*maj[1]/n:.0f}%")
cm = collections.Counter((r["truth"], r["pred"]) for r in rows)
print("confusion (truth -> pred):")
for (t, p), c in sorted(cm.items()):
    print(f"  {t:9s} -> {str(p):9s} {c}")
print("mean model event mass at labelled hits:", round(float(np.mean([r["mass"] for r in rows if r["mass"] is not None])), 2), "| shifts used:", offs)
