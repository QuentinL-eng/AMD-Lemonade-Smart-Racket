#!/usr/bin/env python3
"""Head-to-head agent eval on the what-if val set (docs/WHATIF_DATASET.md).

Replays sampled val cases against a live model with REAL tool dispatch
(ml/coach_sim.py over the synthetic sessions in data/whatif/) and scores what
the app cares about: digest-first discipline, grounded numbers, estimate
labels, and whether the chosen change reaches the case's target.

    python3 tools/agent_eval.py --preset meta --sample 25 --seed 7
    python3 tools/agent_eval.py --preset baseten --sample 25 --seed 7

Presets: meta (MUSE_API_KEY @ api.meta.ai, muse-spark-1.3) and baseten
(BASETEN_API_KEY @ inference.baseten.co, meta-models/muse-spark-open-1026).
MUSE_API_KEY/MUSE_BASE_URL/MUSE_MODEL/EFFORT env vars override the preset.
Report: data/whatif/eval_<preset>_s<sample>.json (git-ignored).
"""
import argparse
import csv
import json
import math
import os
import random
import re
import sys
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "ml"))
sys.path.insert(0, os.path.join(ROOT, "tools"))
import coach_sim as cs  # noqa: E402
from whatif_synth import reaches_target  # noqa: E402

PRESETS = {
    "meta": {"key": "MUSE_API_KEY", "base": "https://api.meta.ai/v1",
             "model": "muse-spark-1.3", "effort": "low"},
    "baseten": {"key": "BASETEN_API_KEY", "base": "https://inference.baseten.co/v1",
                "model": "meta-models/muse-spark-open-1026", "effort": None},
}
MAX_REQUESTS, MAX_TOOLS = 5, 8  # the app's agent limits: 5 rounds, 8 calls per round


def secret(name):
    if os.environ.get(name):
        return os.environ[name]
    for line in open(os.path.join(ROOT, ".env")):
        m = re.match(rf"\s*{name}\s*=\s*(.*)", line)
        if m and m.group(1).strip().strip("\"'"):
            return m.group(1).strip().strip("\"'")
    return None


def numbers(value):
    """Every number in tool results (mirrors ml/test_whatif_synth.numbers)."""
    if isinstance(value, bool):
        return []
    if isinstance(value, (int, float)):
        return [float(value)]
    if isinstance(value, dict):
        extra = [math.hypot(value["contact_x_cm"], value["contact_y_cm"])] if "contact_x_cm" in value else []
        return extra + [n for v in value.values() for n in numbers(v)]
    if isinstance(value, list):
        return [n for v in value for n in numbers(v)]
    return []


def answer_numbers(text):
    return [float(x.replace(",", "")) for x in re.findall(r"\d[\d,]*(?:\.\d+)?", text)]


def grounded(answer, pool):
    """Every number in the answer matches a tool number (rounded or 1% close)."""
    bad = []
    for n in answer_numbers(answer):
        ok = any(n == round(p) or (p and abs(n - p) / abs(p) < 0.01) for p in pool)
        if not ok:
            bad.append(n)
    return bad


def load_data():
    shots = {}
    for r in csv.DictReader(open(os.path.join(ROOT, "data/whatif/shots.csv"))):
        s = cs.Shot.from_mic(r["spin"] == "sweet", 0) if r["mic_only"] == "1" else cs.Shot(
            type=r["type"], swing_kmh=float(r["swing_kmh"]), ball_kmh=float(r["ball_kmh"]),
            spin_rpm=float(r["spin_rpm"]), spin=r["spin"], face_deg=float(r["face_deg"]),
            path_deg=float(r["path_deg"]), x_cm=float(r["x_cm"]), y_cm=float(r["y_cm"]),
            saturated=r["saturated"] == "1")
        shots.setdefault(r["session_id"], []).append((int(r["index"]), s))
    sessions, players = {}, {}
    for r in csv.DictReader(open(os.path.join(ROOT, "data/whatif/sessions.csv"))):
        sl = [s for _, s in sorted(shots.get(r["session_id"], []))]
        sessions[r["session_id"]] = cs.Session(
            id=r["session_id"], start="2026-10-28T19:00:00Z", duration_s=3600,
            shots=sl)
        players.setdefault(r["player_id"], []).append(sessions[r["session_id"]])
    return sessions, players


def call(base, key, model, effort, messages, tools):
    body = {"model": model, "messages": messages, "tools": tools or None,
            "tool_choice": "auto" if tools else None,
            "max_completion_tokens": 4096}  # MuseClient.swift
    body = {k: v for k, v in body.items() if v is not None}
    if effort:
        body["reasoning_effort"] = effort
    req = urllib.request.Request(
        f"{base}/chat/completions", data=json.dumps(body).encode(),
        headers={"Authorization": f"Bearer {key}", "Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=90) as r:
        return json.load(r)


FINAL_NUDGE = "Give your final answer now using the tool results already available."  # MuseCoach.generate


def run_case(ref, sessions, players, base, key, model, effort):
    """MuseCoach.generate's loop: 5 rounds, last round nudged without tools. Empty finals and
    tool calls on the last round raise, mirroring the app's invalidResponse/roundLimit fallback."""
    meta = ref["metadata"]
    session = sessions[meta["session_id"]]
    catalog = players[meta["player_id"]]
    units = cs.Units(metric=meta["units"] == "km/h")
    messages = [m for m in ref["messages"][:2]]
    tools, seq, pool, usage = ref["tools"], [], [], {"prompt": 0, "completion": 0}
    for round in range(MAX_REQUESTS):
        last = round == MAX_REQUESTS - 1
        if last:
            messages.append({"role": "user", "content": FINAL_NUDGE})
        resp = call(base, key, model, effort, messages, None if last else tools)
        u = resp.get("usage", {})
        usage["prompt"] += u.get("prompt_tokens", 0)
        usage["completion"] += u.get("completion_tokens", 0)
        msg = resp["choices"][0]["message"]
        messages.append({k: v for k, v in msg.items() if k in ("role", "content", "tool_calls")})
        tcs = msg.get("tool_calls") or []
        if not tcs:
            if not (msg.get("content") or "").strip():
                e = RuntimeError("empty final answer (app falls back to built-in engine)")
                e.usage = usage
                raise e
            break
        if last:
            e = RuntimeError("tool calls on final round (app reports round limit)")
            e.usage = usage
            raise e
        if len(tcs) > MAX_TOOLS:
            e = RuntimeError(f"{len(tcs)} parallel tool calls (app allows 8)")
            e.usage = usage
            raise e
        for tc in tcs:
            name = tc["function"]["name"]
            try:
                args = json.loads(tc["function"]["arguments"] or "{}")
            except json.JSONDecodeError:
                args = None
            seq.append(name)
            if args is None:
                out = {"error": "arguments were not valid JSON"}
            elif name == "get_session_digest":
                out = cs.get_session_digest(session, catalog, units)
            elif name == "simulate_change":
                kw = {k: v for k, v in args.items() if k != "session"}
                try:
                    out = cs.simulate_change(session, units, **kw)
                except TypeError as e:
                    out = {"error": f"bad arguments: {e}"}
            else:
                out = {"error": f"{name} is not available in this eval"}
            pool += numbers(out)
            messages.append({"role": "tool", "tool_call_id": tc["id"],
                             "content": cs.tool_json(out)})
    return messages, seq, pool, usage


def score(ref, messages, seq, pool):
    meta = ref["metadata"]
    answer = next((m.get("content") or "" for m in reversed(messages)
                   if m.get("role") == "assistant" and m.get("content")), "")
    question = next((m.get("content") or "" for m in messages if m.get("role") == "user"), "")
    pool = pool + answer_numbers(question)  # repeating the request's numbers is legitimate
    bad = grounded(answer, pool)
    simulated = False
    for m in messages:
        if m.get("role") == "tool":
            try:
                c = json.loads(m["content"])
            except (json.JSONDecodeError, KeyError, TypeError):
                continue
            simulated = simulated or (isinstance(c, dict) and "before" in c and "after" in c)
    has_estimate = "estimat" in answer.lower()
    out = {"digest_first": bool(seq) and seq[0] == "get_session_digest",
           "tool_calls": len(seq), "unknown_tools": [t for t in seq if t not in
                        ("get_session_digest", "simulate_change")],
           "ungrounded_numbers": bad, "has_estimate": has_estimate,
           "simulated": simulated, "estimate_ok": has_estimate or not simulated,
           "words": len(answer.split()), "target": None, "exact_pick": None,
           "answer": answer}
    if meta["kind"] in ("objective", "player_whatif", "player_whatif_extreme") and meta.get("chosen"):
        sims = [m for m in messages if m.get("role") == "tool"]
        last = {}
        for m in reversed(sims):  # last simulate_change result, not just last tool call
            try:
                cand = json.loads(m["content"])
            except (json.JSONDecodeError, KeyError):
                continue
            if isinstance(cand, dict) and "after" in cand and "before" in cand:
                last = cand
                break
        if isinstance(last, dict) and "after" in last and "before" in last:
            try:
                out["target"] = bool(reaches_target(meta["objective"], last["before"], last["after"]))
            except (KeyError, ValueError):
                pass
            ref = meta["chosen"]
            got = last.get("applied_deltas", {})
            out["exact_pick"] = all(abs(got.get(k, 0) - v) < 1e-6 for k, v in ref.items())
    return out, answer


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--preset", choices=PRESETS, required=True)
    ap.add_argument("--sample", type=int, default=25)
    ap.add_argument("--seed", type=int, default=7)
    a = ap.parse_args()
    p = PRESETS[a.preset]
    key = secret("MUSE_API_KEY" if a.preset == "meta" else "BASETEN_API_KEY")
    base = os.environ.get("MUSE_BASE_URL", p["base"])
    model = os.environ.get("MUSE_MODEL", p["model"])
    effort = os.environ.get("EFFORT", p["effort"] or "")
    if not key:
        sys.exit(f"No {'MUSE_API_KEY' if a.preset == 'meta' else 'BASETEN_API_KEY'}")
    sessions, players = load_data()
    refs = [json.loads(l) for l in open(os.path.join(ROOT, "data/whatif/conversations_val.jsonl"))]
    rng = random.Random(a.seed)
    by_kind, sample = {}, []
    for r in refs:
        by_kind.setdefault(r["metadata"]["kind"], []).append(r)
    # Stratified: weighted toward the common kinds, at least 1 of each rare kind.
    while len(sample) < min(a.sample, len(refs)):
        for k in sorted(by_kind, key=lambda k: -len(by_kind[k])):
            pool = [r for r in by_kind[k] if r not in sample]
            if pool and len(sample) < a.sample and rng.random() < len(pool) / len(refs) + 0.15:
                sample.append(rng.choice(pool))
        if all(r in sample for rs in by_kind.values() for r in rs):
            break
    print(f"{a.preset}: {len(sample)} cases on {model}", flush=True)
    rows, usage = [], {"prompt": 0, "completion": 0}
    for i, ref in enumerate(sample):
        m = ref["metadata"]
        try:
            messages, seq, pool, u = run_case(ref, sessions, players, base, key, model, effort or None)
            usage["prompt"] += u["prompt"]
            usage["completion"] += u["completion"]
            s, answer = score(ref, messages, seq, pool)
            s.update(kind=m["kind"], objective=m.get("objective"), flaw_found=m.get("flaw_found"),
                     session=m["session_id"][:8], error=None)
        except Exception as e:  # noqa: BLE001 - one bad case must not kill the run
            u = getattr(e, "usage", None) or {}
            usage["prompt"] += u.get("prompt", 0)
            usage["completion"] += u.get("completion", 0)
            s = {"kind": m["kind"], "error": f"{type(e).__name__}: {str(e)[:160]}"}
            answer = ""
        rows.append(s)
        flag = "ERR" if s.get("error") else (
            "ok" if s["digest_first"] and not s["ungrounded_numbers"] and s["estimate_ok"] else "CHECK")
        print(f"[{i + 1}/{len(sample)}] {s['kind']:16s} {flag:5s} tools={s.get('tool_calls', '-')}"
              f" ungrounded={s.get('ungrounded_numbers', '-')}"
              f" target={s.get('target')} err={s.get('error')}", flush=True)
    ok = [r for r in rows if not r.get("error")]
    agg = {"preset": a.preset, "model": model, "cases": len(rows), "errors": len(rows) - len(ok),
           "digest_first": sum(r["digest_first"] for r in ok),
           "grounded": sum(not r["ungrounded_numbers"] for r in ok),
           "estimate_label": sum(r["estimate_ok"] for r in ok),
           "simulated_cases": sum(r["simulated"] for r in ok),
           "target": [r["target"] for r in ok if r["target"] is not None],
           "usage": usage, "rows": rows}
    out = os.path.join(ROOT, "data/whatif", f"eval_{a.preset}_s{a.sample}.json")
    json.dump(agg, open(out, "w"), indent=1)
    t = agg["target"]
    print(f"digest-first {agg['digest_first']}/{len(ok)}, grounded {agg['grounded']}/{len(ok)}, "
          f"estimate {agg['estimate_label']}/{len(ok)}, target {sum(t)}/{len(t)}, "
          f"errors {agg['errors']}, tokens {usage['prompt']}+{usage['completion']}\nwrote {out}")


if __name__ == "__main__":
    main()
