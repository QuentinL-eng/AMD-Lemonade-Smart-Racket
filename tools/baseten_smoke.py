#!/usr/bin/env python3
"""Smoke-test the Baseten model behind the `muse` edge function.

Checks that the model slug exists, that a plain reply works, and that a tool call round-trips
(the coach needs this every turn). Reads BASETEN_API_KEY and BASETEN_MODEL from the environment.
Usage: BASETEN_API_KEY=... BASETEN_MODEL=... python3 tools/baseten_smoke.py
"""
import json
import os
import sys
import urllib.request

BASE = os.environ.get("BASETEN_BASE_URL", "https://inference.baseten.co/v1")
KEY = os.environ.get("BASETEN_API_KEY")
MODEL = os.environ.get("BASETEN_MODEL")
if not KEY or not MODEL:
    sys.exit("Set BASETEN_API_KEY and BASETEN_MODEL")

TOOL = {"type": "function", "function": {
    "name": "get_live_state", "description": "Current swing and session numbers for the player.",
    "parameters": {"type": "object", "properties": {}}}}


def call(path, body=None):
    if body and os.environ.get("EFFORT"):
        body = {**body, "reasoning_effort": os.environ["EFFORT"]}
    req = urllib.request.Request(
        f"{BASE}{path}", data=json.dumps(body).encode() if body else None,
        headers={"Authorization": f"Bearer {KEY}", "Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.load(r)


def show(label, resp):
    c = resp["choices"][0]
    m = c["message"]
    print(f"{label}: content={m.get('content')!r} finish={c['finish_reason']} keys={sorted(m)} usage={resp.get('usage')}")
    for k in ("reasoning_content", "reasoning"):
        if m.get(k):
            print(f"  {k}: {str(m[k])[:200]!r}")


ids = [m["id"] for m in call("/models").get("data", [])]
print("model listed:", MODEL in ids, f"({len(ids)} models)")
if MODEL not in ids:
    print("available:", *[i for i in ids if "muse" in i.lower() or "meta" in i.lower()], sep="\n  ")

plain = call("/chat/completions", {"model": MODEL, "max_completion_tokens": int(os.environ.get("MAXTOK", 64)),
                                   "messages": [{"role": "user", "content": "Say hi in five words."}]})
show("plain", plain)

messages = [{"role": "user", "content": "How was my last swing? Check the live state."}]
first = call("/chat/completions", {"model": MODEL, "max_completion_tokens": int(os.environ.get("MAXTOK", 256)), "messages": messages,
                                   "tools": [TOOL], "tool_choice": "auto"})
msg = first["choices"][0]["message"]
calls = msg.get("tool_calls") or []
print("tool call:", [c["function"]["name"] for c in calls] or "NONE", "finish:", first["choices"][0]["finish_reason"])
if calls:
    messages += [msg, {"role": "tool", "tool_call_id": calls[0]["id"], "content": '{"racketSpeed_mph": 61, "contact": "center"}'}]
    final = call("/chat/completions", {"model": MODEL, "max_completion_tokens": int(os.environ.get("MAXTOK", 256)), "messages": messages, "tools": [TOOL]})
    show("final", final)
