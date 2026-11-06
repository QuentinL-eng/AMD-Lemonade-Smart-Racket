#!/usr/bin/env python3
"""Head-to-head agent eval on the what-if val set (docs/WHATIF_DATASET.md).

Replays sampled val cases against a live model with REAL tool dispatch
(ml/coach_sim.py over the synthetic sessions in data/whatif/) and scores what
the app cares about: digest-first discipline, grounded numbers, estimate
labels, and whether the chosen change reaches the case's target.

    python3 tools/agent_eval.py --preset meta --sample 243 --seed 7
    python3 tools/agent_eval.py --preset baseten --sample 243 --seed 7
    python3 tools/agent_eval.py --preset lemonade --sample 243 --seed 7
    python3 tools/agent_eval.py --preset ondevice --sample 243 --seed 7

The lemonade and ondevice presets use OpenAI-compatible local endpoints. Set
LEMONADE_BASE_URL/LEMONADE_MODEL and ONDEVICE_BASE_URL/ONDEVICE_MODEL to select
the serving endpoint and model/checkpoint under evaluation.
Report: data/whatif/eval_<preset>_s<sample>.json (git-ignored).
"""
import argparse
import csv
import datetime
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
    "lemonade": {"key": None, "base": "http://localhost:8000/api/v1",
                 "model": "", "effort": None},
    "ondevice": {"key": None, "base": "http://localhost:8001/v1",
                 "model": "", "effort": None},
}
MAX_REQUESTS, MAX_TOOLS = 5, 8  # the app's agent limits: 5 rounds, 8 calls per round
KNOWN_TOOLS = {t["function"]["name"] for t in cs.tool_schemas()}


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
    """Every number in the answer matches a tool number. Same rule as the dataset's own
    answers_only_cite_tool_numbers test: absolute 0.051, rounded match, or 1% relative."""
    bad = []
    for n in answer_numbers(answer):
        def ok(p):
            a = abs(p)
            return (abs(n - a) < 0.051 or n == round(a) or round(p, -1) == n
                    or (a and abs(n - a) / a < 0.01))
        if not any(ok(p) for p in pool):
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
    base = datetime.datetime(2026, 10, 28, 19, tzinfo=datetime.timezone.utc)
    for i, r in enumerate(csv.DictReader(open(os.path.join(ROOT, "data/whatif/sessions.csv")))):
        sl = [s for _, s in sorted(shots.get(r["session_id"], []))]
        start = (base + datetime.timedelta(days=i)).isoformat().replace("+00:00", "Z")
        sessions[r["session_id"]] = cs.Session(
            id=r["session_id"], start=start, duration_s=3600, shots=sl)
        players.setdefault(r["player_id"], []).append(sessions[r["session_id"]])
    return sessions, players


def call(base, key, model, effort, messages, tools, think_off=False):
    body = {"model": model, "messages": messages, "tools": tools or None,
            "tool_choice": "auto" if tools else None,
            "max_completion_tokens": 4096}  # MuseClient.swift
    body = {k: v for k, v in body.items() if v is not None}
    if effort:
        body["reasoning_effort"] = effort
    if think_off:
        body["enable_thinking"] = False
    headers = {"Content-Type": "application/json"}
    if key:
        headers["Authorization"] = f"Bearer {key}"
    req = urllib.request.Request(f"{base}/chat/completions", data=json.dumps(body).encode(), headers=headers)
    with urllib.request.urlopen(req, timeout=90) as r:
        return json.load(r)


FINAL_NUDGE = "Give your final answer now using the tool results already available."  # MuseCoach.generate


def dispatch_tool(name, args, session, catalog, units, notes):
    """Pure tool dispatch (no API calls): mirrors CoachTools.execute + dispatch."""
    if args is None:
        return {"error": "Unknown tool or invalid argument object."}
    err = cs.validate_call(name, args)
    if err:
        return {"error": err}
    try:
        if name == "get_session_digest":
            sess = cs.resolve_session(args.get("session"), session, catalog)
            return cs.get_session_digest(sess, catalog, units)
        if name == "simulate_change":
            kw = {k: v for k, v in args.items() if k != "session"}
            try:
                return cs.simulate_on(args.get("session"), session, catalog, units, **kw)
            except TypeError as e:
                return {"error": f"bad arguments: {e}"}
        if name == "list_shots":
            return cs.list_shots(session, catalog, units, sid=args.get("session"), type=args.get("type"),
                                 from_=args.get("from"), to_=args.get("to"), contact=args.get("contact"),
                                 order=args.get("order", "newest"), limit=args.get("limit", 20))
        if name == "query_shots":
            return cs.query_shots(session, catalog, units, sid=args.get("session"), type=args.get("type"),
                                  metric=args.get("metric"), from_=args.get("from"), to_=args.get("to"))
        if name == "compare_sessions":
            return cs.compare_sessions(session, catalog, units, args["a"], args["b"])
        if name == "recall_notes":
            return cs.recall_notes(notes, category=args.get("category"), query=args.get("query"),
                                   limit=args.get("limit", 20))
        if name == "remember_note":
            return cs.remember_note(notes, args["text"], args["category"])
        if name in cs.LIVE_ERRORS:
            return {"error": cs.LIVE_ERRORS[name]}
    except cs.ToolError as e:
        return {"error": str(e)}
    return {"error": f"{name} is not available in this eval"}


def run_case(ref, sessions, players, base, key, model, effort, think_off=False):
    """MuseCoach.generate's loop: 5 rounds, last round nudged without tools. Empty finals and
    tool calls on the last round raise, mirroring the app's invalidResponse/roundLimit fallback."""
    meta = ref["metadata"]
    session = sessions[meta["session_id"]]
    catalog = players[meta["player_id"]]
    units = cs.Units(metric=meta["units"] == "km/h")
    messages = [m for m in ref["messages"][:2]]
    tools, seq, pool, usage = ref["tools"], [], [], {"prompt": 0, "completion": 0}
    notes = cs.NoteStore()
    for round in range(MAX_REQUESTS):
        last = round == MAX_REQUESTS - 1
        if last:
            messages.append({"role": "user", "content": FINAL_NUDGE})
        resp = call(base, key, model, effort, messages, None if last else tools, think_off=think_off)
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
            out = dispatch_tool(name, args, session, catalog, units, notes)
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
           "tool_calls": len(seq), "seq": seq,
           "unknown_tools": [t for t in seq if t not in KNOWN_TOOLS],
           "ungrounded_numbers": bad, "has_estimate": has_estimate,
           "simulated": simulated, "estimate_ok": has_estimate or not simulated,
           "words": len(answer.split()), "target": None, "exact_pick": None,
           "last_sim": None, "pool": pool, "answer": answer}
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
            try:
                b, a = last["before"], last["after"]
                out["last_sim"] = {"applied_deltas": last.get("applied_deltas", {}),
                                   "before_ball": b["ball_speed"], "before_spin": b["spin_rpm"],
                                   "after_ball": a["ball_speed"], "after_spin": a["spin_rpm"],
                                   "after_contact": [a["applied_parameters"]["contactXcm"],
                                                   a["applied_parameters"]["contactYcm"]]}
            except (KeyError, TypeError):
                pass
        elif meta.get("objective"):
            out["target"] = False  # a goal case answered without any simulation fails
            ref = meta["chosen"]
            got = last.get("applied_deltas", {})
            out["exact_pick"] = all(abs(got.get(k, 0) - v) < 1e-6 for k, v in ref.items())
    return out, answer


def summarize(rows):
    """Compute one strict all-pass table without dropping failed requests."""
    kinds = {}
    for kind in sorted({r.get("kind", "unknown") for r in rows}):
        subset = [r for r in rows if r.get("kind") == kind]
        ok = [r for r in subset if not r.get("error")]
        simulated = [r for r in ok if r.get("simulated")]
        strict = [r for r in subset if not r.get("error") and r.get("strict_all_pass")]
        kinds[kind] = {
            "cases": len(subset), "strict_all_pass": len(strict),
            "digest_first": sum(bool(r.get("digest_first")) for r in ok),
            "grounded": sum(not r.get("ungrounded_numbers", []) for r in ok),
            "estimate_label": sum(bool(r.get("has_estimate")) for r in simulated),
            "estimate_label_cases": len(simulated),
            "errors": sum(bool(r.get("error")) for r in subset),
        }
    return kinds


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--preset", choices=PRESETS, required=True)
    ap.add_argument("--sample", type=int, default=25)
    ap.add_argument("--seed", type=int, default=7)
    a = ap.parse_args()
    p = PRESETS[a.preset]
    key_name = p["key"]
    key = secret(key_name) if key_name else os.environ.get("LEMONADE_API_KEY" if a.preset == "lemonade" else "ONDEVICE_API_KEY", "")
    prefix = {"meta": "MUSE", "baseten": "BASETEN", "lemonade": "LEMONADE", "ondevice": "ONDEVICE"}[a.preset]
    base = os.environ.get(f"{prefix}_BASE_URL", p["base"])
    model = os.environ.get(f"{prefix}_MODEL", p["model"])
    effort = os.environ.get("EFFORT", p["effort"] or "")
    if key_name and not key:
        sys.exit(f"No {key_name}")
    if not model:
        sys.exit(f"Set {prefix}_MODEL to the model id loaded by this endpoint")
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
            messages, seq, pool, u = run_case(ref, sessions, players, base, key, model, effort or None,
                                              think_off=a.preset == "lemonade")
            usage["prompt"] += u["prompt"]
            usage["completion"] += u["completion"]
            s, answer = score(ref, messages, seq, pool)
            s.update(kind=m["kind"], objective=m.get("objective"), flaw_found=m.get("flaw_found"),
                     session=m["session_id"][:8], error=None)
            s["strict_all_pass"] = (s["digest_first"] and not s["ungrounded_numbers"] and s["estimate_ok"]
                                    and not s["unknown_tools"] and s["target"] is not False)
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
    per_kind = summarize(rows)
    simulated = [r for r in ok if r.get("simulated")]
    agg = {"preset": a.preset, "model": model, "cases": len(rows), "errors": len(rows) - len(ok),
           "strict_all_pass": sum(bool(r.get("strict_all_pass")) for r in rows),
           "digest_first": sum(r["digest_first"] for r in ok),
           "grounded": sum(not r["ungrounded_numbers"] for r in ok),
           "estimate_label": sum(r["has_estimate"] for r in simulated),
           "estimate_label_cases": len(simulated),
           "simulated_cases": sum(r["simulated"] for r in ok),
           "target": [r["target"] for r in ok if r["target"] is not None],
           "per_kind": per_kind, "usage": usage, "rows": rows}
    out = os.path.join(ROOT, "data/whatif", f"eval_{a.preset}_s{a.sample}.json")
    json.dump(agg, open(out, "w"), indent=1)
    t = agg["target"]
    print("kind              strict  digest  grounded  estimate  errors")
    for kind, values in per_kind.items():
        print(f"{kind:17s} {values['strict_all_pass']:>3}/{values['cases']:<3}"
              f" {values['digest_first']:>3}/{values['cases']:<3}"
              f" {values['grounded']:>3}/{values['cases']:<3}"
              f" {values['estimate_label']:>3}/{values['estimate_label_cases']:<3}"
              f" {values['errors']:>3}")
    print(f"strict {agg['strict_all_pass']}/{len(rows)}, digest-first {agg['digest_first']}/{len(ok)}, "
          f"grounded {agg['grounded']}/{len(ok)}, estimate-label {agg['estimate_label']}/{agg['estimate_label_cases']}, "
          f"target {sum(t)}/{len(t)}, errors {agg['errors']}, tokens {usage['prompt']}+{usage['completion']}\nwrote {out}")


if __name__ == "__main__":
    main()
