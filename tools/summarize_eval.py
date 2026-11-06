#!/usr/bin/env python3
"""Print a markdown summary of one or more agent_eval reports.

  python tools/summarize_eval.py evaluation/adapter-step300-validation.json other.json

Strict all-pass counts every response error as a failure, over all attempted cases.
Also prints the same score over usable answers only, labelled as such, so the two are
never confused.
"""
import json
import sys


def pct(n, d):
    return f"{100 * n / d:.1f}%" if d else "n/a"


def main(paths):
    if not paths:
        sys.exit(__doc__)
    for path in paths:
        d = json.load(open(path, encoding="utf-8"))
        n, ok, err = d["cases"], d["strict_all_pass"], d["errors"]
        usable = n - err
        print(f"## {d['model']}  ({path})\n")
        print(f"- Strict all-pass, errors counted as failures: **{ok}/{n} ({pct(ok, n)})**")
        print(f"- Response errors: {err}/{n}")
        print(f"- Strict all-pass over usable answers only (not the headline): {ok}/{usable} ({pct(ok, usable)})\n")
        print("| Kind | Cases | Strict all-pass | Response errors |\n|---|---:|---:|---:|")
        for kind, k in sorted(d["per_kind"].items()):
            print(f"| {kind} | {k['cases']} | {k['strict_all_pass']}/{k['cases']} ({pct(k['strict_all_pass'], k['cases'])}) | {k['errors']} |")
        print()


if __name__ == "__main__":
    main(sys.argv[1:])
