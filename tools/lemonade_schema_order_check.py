#!/usr/bin/env python3
"""Does your Lemonade server reorder the keys of tool schemas before the model sees them?

  python tools/lemonade_schema_order_check.py [--base http://localhost:8000/api/v1] [--model NAME]

The check is model independent. It sends the same one-line chat request twice with the same tool
schema, once with keys in the application's order and once with keys sorted alphabetically, and
compares the server-reported prompt_tokens. Equal counts mean the server normalised the order
(the model sees the same text either way). Different counts mean the server preserved your order.

Why it matters: a model fine-tuned on one key order can behave differently on another. In this
project a QLoRA-tuned 1.5B model scored 212/243 when served with the training key order and
118/243 through Lemonade, which delivered the keys sorted. See docs/LEMONADE_SCHEMA_ORDER.md.
Needs only the Python standard library. Uses one-token generations; it costs almost nothing.
"""
import argparse
import json
import urllib.request

TOOL = {"type": "function", "function": {
    "name": "simulate_change",
    "description": "Estimate the effect of a change.",
    "parameters": {"type": "object", "properties": {
        "type": {"type": "string", "description": "Stroke", "enum": ["forehand", "backhand"]},
        "swing_percent": {"type": "number", "description": "Swing speed delta"}},
        "required": [], "additionalProperties": False}}}


def sort_keys(v):
    if isinstance(v, dict):
        return {k: sort_keys(v[k]) for k in sorted(v)}
    if isinstance(v, list):
        return [sort_keys(x) for x in v]
    return v


def prompt_tokens(base, model, tool):
    body = {"model": model, "messages": [{"role": "user", "content": "hi"}], "tools": [tool],
            "max_tokens": 1, "temperature": 0}
    req = urllib.request.Request(base + "/chat/completions", data=json.dumps(body).encode(),
                                 headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=120) as r:
        return json.load(r)["usage"]["prompt_tokens"]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", default="http://localhost:8000/api/v1")
    ap.add_argument("--model", default="")
    a = ap.parse_args()
    model = a.model
    if not model:
        with urllib.request.urlopen(a.base + "/models", timeout=10) as r:
            ids = [m["id"] for m in json.load(r)["data"]]
        model = ids[0]
    original, sorted_ = prompt_tokens(a.base, model, TOOL), prompt_tokens(a.base, model, sort_keys(TOOL))
    print(f"model={model}\nprompt_tokens: application order={original}, sorted keys={sorted_}")
    if original == sorted_:
        print("RESULT: the server normalises tool-schema key order (sorted or equivalent).\n"
              "If you fine-tune a model for this server, train on sorted-key schemas.")
    else:
        print("RESULT: the server preserves your key order.")


if __name__ == "__main__":
    main()
