#!/usr/bin/env python3
"""M02.3: compare two estimates.json files and summarize what changed.

Used to review every estimator or data change: run build_estimates.py before and after, keep both
files, then:
  python3 research/v3/migration/tools/estimates_diff.py BEFORE.json AFTER.json [--md OUT.md] [--json OUT.json]

Rows are keyed by (method, input, outputItemID). Reports added, removed and changed rows; for changed
rows the chance, average, confidence and studyCasts deltas, and which fields changed.
Deterministic: sorted output, no timestamps.
"""
import argparse
import json
import sys

FIELDS = ["chance", "average", "confidence", "studyCasts", "studies", "range", "chanceSource",
          "averageSource", "rangeSource", "conditional", "provisionalValuation", "conflict"]


def key(e):
    return (e["method"], str(e["input"]), str(e["outputItemID"]))


def load(path):
    d = json.load(open(path, encoding="utf-8"))
    rows = d["estimates"] if isinstance(d, dict) else d
    return {key(e): e for e in rows}


def diff(before, after):
    added = sorted(set(after) - set(before))
    removed = sorted(set(before) - set(after))
    changed = []
    for k in sorted(set(before) & set(after)):
        b, a = before[k], after[k]
        fields = [f for f in FIELDS if b.get(f) != a.get(f)]
        if fields:
            changed.append({
                "key": list(k), "fields": fields,
                "chance": [b.get("chance"), a.get("chance")],
                "average": [b.get("average"), a.get("average")],
                "confidence": [b.get("confidence"), a.get("confidence")],
                "studyCasts": [b.get("studyCasts"), a.get("studyCasts")],
                "dChance": round((a.get("chance") or 0) - (b.get("chance") or 0), 4),
            })
    field_counts = {}
    for c in changed:
        for f in c["fields"]:
            field_counts[f] = field_counts.get(f, 0) + 1
    return {
        "before": len(before), "after": len(after),
        "added": [list(k) for k in added], "removed": [list(k) for k in removed],
        "changed": changed, "fieldChangeCounts": dict(sorted(field_counts.items())),
        "maxAbsChanceDelta": max((abs(c["dChance"]) for c in changed), default=0),
    }


def render_md(d, limit=40):
    lines = ["# Estimates diff", "",
             f"- Rows: {d['before']:,} → {d['after']:,} (added {len(d['added'])}, removed {len(d['removed'])}, "
             f"changed {len(d['changed'])})",
             f"- Largest absolute chance change: {d['maxAbsChanceDelta']:.4f}",
             "- Fields changed: " + (", ".join(f"{k} {v}" for k, v in d["fieldChangeCounts"].items()) or "none"),
             ""]
    if d["changed"]:
        lines += ["## Largest chance changes", "",
                  "| Method | Input | Output | Chance | Average | Confidence | Study casts |",
                  "| --- | --- | --- | --- | --- | --- | --- |"]
        for c in sorted(d["changed"], key=lambda c: (-abs(c["dChance"]), c["key"]))[:limit]:
            m, i, o = c["key"]
            fmt = lambda p: " → ".join("—" if v is None else str(v) for v in p)  # noqa: E731
            lines.append(f"| {m} | {i} | {o} | {fmt(c['chance'])} | {fmt(c['average'])} | "
                         f"{fmt(c['confidence'])} | {fmt(c['studyCasts'])} |")
    for title, rows in (("Added", d["added"]), ("Removed", d["removed"])):
        if rows:
            lines += ["", f"## {title} (first {limit})", ""] + [f"- {' / '.join(r)}" for r in rows[:limit]]
    return "\n".join(lines) + "\n"


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("before")
    ap.add_argument("after")
    ap.add_argument("--md")
    ap.add_argument("--json")
    a = ap.parse_args(argv)
    d = diff(load(a.before), load(a.after))
    md = render_md(d)
    if a.md:
        open(a.md, "w", encoding="utf-8", newline="\n").write(md)
    if a.json:
        with open(a.json, "w", encoding="utf-8", newline="\n") as fh:
            json.dump(d, fh, indent=1, sort_keys=True)
            fh.write("\n")
    sys.stdout.write(md if not (a.md or a.json) else md.split("\n## ")[0])
    return 0


if __name__ == "__main__":
    sys.exit(main())
