#!/usr/bin/env python3
"""Ask Muse Spark for a swing film script and validate it (docs/SWING_FILM.md).

Muse sees the player's forehands through the same tools the app gives it (get_session_digest, simulate_change),
picks one or two changes, tests them, and calls make_swing_film. The script is checked against the film limits;
a rejected script goes back to Muse with the reasons, at most twice. The result is written for the Remotion scene.

    python3 tools/swing_film.py --sample
    python3 tools/swing_film.py --shots data/<session>/<name>.shots.jsonl

The key is MUSE_API_KEY from the environment or the repo's .env (sends shot statistics to Meta).
"""
import argparse
import json
import os
import random
import re
import sys
import urllib.error
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "ml"))
sys.path.insert(0, os.path.join(ROOT, "tools"))
import coach_sim as cs  # noqa: E402
from sam_prefill import api_key  # noqa: E402

BASE = os.environ.get("MUSE_BASE_URL", "https://api.meta.ai/v1")
MODEL = os.environ.get("MUSE_MODEL", "muse-spark-1.3")
OUT = os.path.join(ROOT, "video", "src", "config", "swingFilm.json")
LOG = os.path.join(ROOT, "video", "out", "swing-film-muse.json")

# The film limits. Keep in step with docs/SWING_FILM.md.
LEVERS = {"swing_percent": (15, 3), "face_deg": (6, 2), "path_deg": (10, 2), "contact_x_cm": (3, 1), "contact_y_cm": (3, 1)}
TEXT = {"title": 24, "cue": 60, "why": 90}
BANNED = ["coach", "guarantee", "landing", "depth", "net", "injury", "pain", "always", "never"]

FILM_RULES = (
    "\nYou are directing a short swing film. A fixed renderer draws the player's average forehand, then the same swing "
    "with your change, then the estimated before/after numbers. You only choose the change and three short texts. "
    "Rules for make_swing_film: change one or two levers; swing_percent within -15...15 (at least 3 if used), face_deg "
    "and path_deg within -6...6 and -10...10 (at least 2 if used), contact_x_cm and contact_y_cm within -3...3 (at least 1 "
    "if used); the deltas must be exactly ones you already tested with simulate_change for the same stroke. "
    "title up to 24 characters, cue up to 60, why up to 90; no digits in any text (the renderer shows the numbers). "
    "The cue says what the player should feel, in plain words. Prefer the change with the biggest estimated gain that "
    "a player can feel in one session. Do not mention landing, depth or the net."
)


def tool(name, description, properties, required=()):
    return {"type": "function", "function": {"name": name, "description": description, "parameters": {
        "type": "object", "properties": properties, "required": list(required), "additionalProperties": False}}}


def film_tool():
    num = lambda d: {"type": "number", "description": d}  # noqa: E731
    text = lambda n, d: {"type": "string", "description": f"{d} At most {n} characters, no digits."}  # noqa: E731
    return tool("make_swing_film", "Render the swing film: the player's average swing, then the same swing with this "
                "change, then the simulated effect. Call once, after testing the change with simulate_change.",
                {"stroke": {"type": "string", "enum": ["forehand"]},
                 "swing_percent": num("Swing speed change, percent. 0 if unchanged."),
                 "face_deg": num("Face angle change, degrees (+ opens). 0 if unchanged."),
                 "path_deg": num("Path change, degrees (+ more low-to-high). 0 if unchanged."),
                 "contact_x_cm": num("Contact change across the strings, cm. 0 if unchanged."),
                 "contact_y_cm": num("Contact change toward the tip, cm. 0 if unchanged."),
                 "title": text(TEXT["title"], "Film title, e.g. 'Brush up the back'."),
                 "cue": text(TEXT["cue"], "What to feel on the next swings."),
                 "why": text(TEXT["why"], "Why this helps this player.")},
                ["stroke", "swing_percent", "face_deg", "path_deg", "contact_x_cm", "contact_y_cm", "title", "cue", "why"])


def sample_session():
    """A demo forehand session: realistic swing speeds and reviewed contacts, a flat path (little spin)."""
    priors = json.load(open(os.path.join(ROOT, "ml", "whatif_priors.json")))
    rng = random.Random(7)
    contacts = rng.sample([c for c in priors["contacts_cm"] if abs(c[0]) < 6 and abs(c[1]) < 8], 14)
    shots = []
    for x, y in contacts:
        swing = rng.gauss(108, 108 * priors["phone_swing_cv"] / 2)
        path, face = 6 + rng.gauss(0, 3), 3 + rng.gauss(0, 1.5)
        _, ball, rpm, spin = cs.simulate(swing, path, face, x, y)
        shots.append(cs.Shot(type="forehand", swing_kmh=swing, ball_kmh=ball, spin_rpm=rpm, spin=spin,
                             face_deg=face, path_deg=path, x_cm=x, y_cm=y))
    return cs.Session(id="9D7B2C1E-5F0A-4E1B-8C3D-2A6F4B8E1C90", start="2026-11-02T17:00:00Z", duration_s=1500, shots=shots)


def recorded_session(path):
    shots = []
    for line in open(path):
        d = json.loads(line)
        if d.get("type") != "forehand" or d.get("gyroSaturated"):
            continue
        shots.append(cs.Shot(type="forehand", swing_kmh=d["swingSpeedKmh"], ball_kmh=d["ballSpeedKmh"],
                             spin_rpm=d["spinRPM"], spin=d["spin"], face_deg=d["faceAngleDeg"],
                             path_deg=d["swingPathDeg"], x_cm=d["impactXcm"], y_cm=d["impactYcm"]))
    if not shots:
        sys.exit("No usable forehands in " + path)
    return cs.Session(id="5C0FFEE0-0000-4000-8000-000000000001", start="2026-11-02T17:00:00Z", duration_s=600, shots=shots)


def validate(args, tested):
    errors = []
    if args.get("stroke") != "forehand":
        errors.append("stroke must be forehand")
    deltas = {}
    for k, (limit, least) in LEVERS.items():
        v = args.get(k, 0)
        if not isinstance(v, (int, float)):
            errors.append(f"{k} must be a number")
            continue
        if v != 0 and not (least <= abs(v) <= limit):
            errors.append(f"{k}={v} must be 0 or between {least} and {limit} in size")
        deltas[k] = float(v)
    used = [k for k, v in deltas.items() if v != 0]
    if not 1 <= len(used) <= 2:
        errors.append(f"change one or two levers, not {len(used)}")
    key = tuple(round(deltas.get(k, 0), 3) for k in LEVERS)
    if key not in tested:
        errors.append("these exact deltas were not tested with simulate_change for the forehand")
    for k, n in TEXT.items():
        s = args.get(k)
        if not isinstance(s, str) or not s.strip():
            errors.append(f"{k} is required")
            continue
        if len(s) > n:
            errors.append(f"{k} is {len(s)} characters; the limit is {n}")
        if re.search(r"\d", s):
            errors.append(f"{k} must not contain digits")
        hits = [w for w in BANNED if re.search(rf"\b{w}\w*", s, re.I)]
        if hits:
            errors.append(f"{k} must not use: {', '.join(hits)}")
    return errors, key


def call(messages, tools):
    body = {"model": MODEL, "messages": messages, "tools": tools, "tool_choice": "auto",
            "max_completion_tokens": 4096, "reasoning_effort": os.environ.get("EFFORT", "low")}
    req = urllib.request.Request(f"{BASE}/chat/completions", data=json.dumps(body).encode(),
                                 headers={"Authorization": f"Bearer {api_key()}", "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=90) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:
        sys.exit(f"Meta API error {e.code}: {e.read()[:300]!r}")


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    src = ap.add_mutually_exclusive_group(required=True)
    src.add_argument("--sample", action="store_true", help="demo forehand session")
    src.add_argument("--shots", help="a recorded *.shots.jsonl")
    ap.add_argument("--rounds", type=int, default=8)
    args = ap.parse_args()
    if not api_key():
        sys.exit("Set MUSE_API_KEY in the environment or .env")

    session = sample_session() if args.sample else recorded_session(args.shots)
    units = cs.Units(metric=True)
    schemas = {t["function"]["name"]: t for t in cs.tool_schemas()}
    tools = [schemas["get_session_digest"], schemas["simulate_change"], film_tool()]
    messages = [{"role": "system", "content": cs.SYSTEM + FILM_RULES},
                {"role": "user", "content": "Make my swing film for my forehand: find the change that would help it "
                                            "most, test it, then call make_swing_film."}]
    tested, results, film, rejections = set(), {}, None, 0
    for _ in range(args.rounds):
        msg = call(messages, tools)["choices"][0]["message"]
        messages.append({k: v for k, v in msg.items() if k in ("role", "content", "tool_calls")})
        calls = msg.get("tool_calls") or []
        if not calls:
            messages.append({"role": "user", "content": "Call make_swing_film now with a change you tested."})
            continue
        for c in calls:
            name, fargs = c["function"]["name"], json.loads(c["function"]["arguments"] or "{}")
            print(f"Muse → {name}({json.dumps(fargs)})", flush=True)
            if name == "get_session_digest":
                out = cs.get_session_digest(session, [session], units)
            elif name == "simulate_change":
                out = cs.simulate_change(session, units, **{k: v for k, v in fargs.items() if k != "session"})
                if "error" not in out and fargs.get("type") in (None, "forehand"):
                    key = tuple(round(out["applied_deltas"][k], 3) for k in LEVERS)
                    tested.add(key)
                    results[key] = out
            elif name == "make_swing_film":
                errors, key = validate(fargs, tested)
                if errors:
                    rejections += 1
                    print("  rejected: " + "; ".join(errors))
                    out = {"error": "Film rejected: " + "; ".join(errors) + ". Fix these and call make_swing_film again."}
                    if rejections > 2:
                        sys.exit("Muse's script failed the limits three times; no film made.")
                else:
                    film = (fargs, results[key])
                    out = {"ok": True}
            else:
                out = {"error": f"unknown tool {name}"}
            messages.append({"role": "tool", "tool_call_id": c["id"], "content": cs.tool_json(out)})
        if film:
            break
    if not film:
        sys.exit("Muse did not make a film within the round limit.")

    fargs, sim = film

    def side(s):
        p = s["applied_parameters"]
        return {"swingKmh": p["swingSpeedKmh"], "pathDeg": p["pathAngleDeg"], "faceDeg": p["faceAngleDeg"],
                "contactXcm": p["contactXcm"], "contactYcm": p["contactYcm"], "ballKmh": s["ball_speed"],
                "spinRpm": s["spin_rpm"], "spinType": s["spin_type"]}

    spec = {"model": MODEL, "stroke": "forehand", "sampleCount": sim["sample_count"], "estimated": True,
            "source": "sample" if args.sample else os.path.relpath(args.shots, ROOT),
            "deltas": {k: fargs[k] for k in LEVERS}, "title": fargs["title"].strip(), "cue": fargs["cue"].strip(),
            "why": fargs["why"].strip(), "before": side(sim["before"]), "after": side(sim["after"])}
    os.makedirs(os.path.dirname(LOG), exist_ok=True)
    json.dump(spec, open(OUT, "w"), indent=2)
    json.dump(messages, open(LOG, "w"), indent=1)
    print(json.dumps(spec, indent=2))
    print(f"\nWrote {os.path.relpath(OUT, ROOT)}; Muse's conversation in {os.path.relpath(LOG, ROOT)}")


if __name__ == "__main__":
    main()
