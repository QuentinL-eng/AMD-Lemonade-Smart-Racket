#!/usr/bin/env python3
"""Write a target-conditioned copy of the TRAINING conversations (rejection sampling).

Reads only data/whatif/conversations_train.jsonl. For goal conversations of objectives
cleaner_contact, more_spin and more_pace it keeps a conversation only if its last
simulate_change result reaches the goal under ml/whatif_synth.reaches_target, the same
rule the evaluator applies to a model's answer. Conversations with no simulation are dropped
for those objectives, since the evaluator fails a goal answered without one.

fix_slice is left untouched: only 1 of 61 training conversations reaches its goal under
this rule, so filtering would delete the objective. All other kinds are untouched.
Validation and test files are never read; the original training file is not modified.
"""
import collections
import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "ml"))
from whatif_synth import reaches_target  # noqa: E402

SRC = ROOT / "data" / "whatif" / "conversations_train.jsonl"
DST = ROOT / "data" / "whatif" / "conversations_train_target.jsonl"
FILTERED = {"cleaner_contact", "more_spin", "more_pace"}


def last_sim(messages):
    last = None
    for m in messages:
        if m["role"] == "tool":
            try:
                j = json.loads(m["content"])
            except (TypeError, ValueError):
                continue
            if isinstance(j, dict) and "before" in j and "after" in j:
                last = j
    return last


def keep(item):
    obj = item["metadata"].get("objective")
    if obj not in FILTERED:
        return True
    sim = last_sim(item["messages"])
    return sim is not None and bool(reaches_target(obj, sim["before"], sim["after"]))


def main():
    rows = [json.loads(line) for line in SRC.read_text(encoding="utf-8").splitlines() if line.strip()]
    kept = [r for r in rows if keep(r)]
    DST.write_text("".join(json.dumps(r, ensure_ascii=False) + "\n" for r in kept), encoding="utf-8")
    dropped = collections.Counter(r["metadata"].get("objective") for r in rows if not keep(r))
    report = {"source": str(SRC.relative_to(ROOT)), "source_conversations": len(rows),
              "kept": len(kept), "dropped_by_objective": dict(dropped),
              "output": str(DST.relative_to(ROOT)),
              "output_sha256": hashlib.sha256(DST.read_bytes()).hexdigest()}
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
