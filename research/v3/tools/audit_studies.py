#!/usr/bin/env python3
"""Audit every study in research/v3 for known problem types and write a ranked worklist.

Read-only: it never edits evidence or corrections. Run after build_estimates.py changes.
Output: research/v3/output/study-audit.json and study-audit.md

A "study" is all drop rows that share a studyKey (or a single row with no studyKey). Rows from
TSM tables, references and compiled research are not studies and are skipped.
Checks only use data already in the repo, so every finding is reproducible.
"""
import json
import os
import sys
from collections import defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import build_estimates as b  # noqa: E402

OUT = os.path.join(b.ROOT, "research", "v3", "output")
VALID_RANKS = (None, 1, 2, 3)
NOMINAL_BATCH = {"Prospect": (5, 20)}  # 5 per cast, 20 for mass prospecting; Midnight Mill is 10 (M6)


def issues_for(rows, conds, families, names):
    out = []
    ids_in = {r.get("inputItemID") for r in rows}
    methods = {r.get("method") for r in rows}
    method = next(iter(methods)) if len(methods) == 1 else None

    def add(code, sev, text, ids):
        out.append({"code": code, "severity": sev, "text": text, "records": sorted(ids)})

    bad_rank = [r["id"] for r in rows if r.get("inputRank") not in VALID_RANKS]
    if bad_rank:
        add("RANK_INVALID", 2, "inputRank is not 1, 2, 3 or null (for example 0)", bad_rank)

    no_in = [r["id"] for r in rows if not r.get("inputItemID")]
    if no_in:
        add("INPUT_ID_MISSING", 3, "no inputItemID; study is pooled by name and may mix ranks", no_in)

    no_out = [r["id"] for r in rows if not r.get("outputItemID")]
    if no_out:
        add("OUTPUT_ID_MISSING", 2, "no outputItemID; output is grouped by name family", no_out)

    agg = [r["id"] for r in rows if "aggregate" in str(r.get("outputName") or "").lower()
           or "unspecified" in str(r.get("outputName") or "").lower()]
    if agg:
        add("AGGREGATE_OUTPUT", 3, "output is an aggregate or unspecified item, not one material", agg)

    has_numbers = [r for r in rows if r.get("totalQuantity") is not None or r.get("averageShown") is not None
                   or r.get("percentShown") is not None or r.get("castsWithDrop") is not None]
    no_cast = [r["id"] for r in has_numbers if not r.get("casts")]
    if no_cast:
        add("CASTS_UNKNOWN", 2, "has numbers but no cast count; weighted as a small study (20 casts)", no_cast)

    pct = [r["id"] for r in rows if r.get("percentShown") is not None
           and r.get("percentMeaning") in (None, "unclear")]
    if pct:
        add("PERCENT_MEANING_UNCLEAR", 2, "percentShown present but percentMeaning unknown or unclear", pct)

    avg = [r["id"] for r in rows if r.get("averageShown") is not None and not r.get("averagePer")]
    if avg:
        add("AVERAGE_PER_MISSING", 3, "averageShown present but averagePer missing; unit unknown", avg)

    if method in NOMINAL_BATCH:
        odd = [r["id"] for r in rows if r.get("inputsPerCast") not in (None,) + NOMINAL_BATCH[method]]
        if odd:
            add("BATCH_SIZE_ODD", 3, f"inputsPerCast is not one of {NOMINAL_BATCH[method]} for {method}", odd)
    if method == "Mill" and any(str(r.get("inputItemID") or "").isdigit() and int(r["inputItemID"]) >= 236000
                                for r in rows):
        odd = [r["id"] for r in rows if r.get("inputsPerCast") not in (None, 10)]
        if odd:
            add("BATCH_SIZE_ODD", 3, "Midnight Mill should be 10 herbs per cast (M6)", odd)

    undated = [r["id"] for r in rows if not r.get("dataDate") and not r.get("patch")
               and not (r.get("source") or {}).get("published")]
    if undated and len(undated) == len(rows):
        add("EPOCH_UNKNOWN", 1, "no data date, patch or post date; patch-era effects cannot be judged", undated)

    locked = []
    for r in rows:
        k = b.key_of(r, names)
        if not k:
            continue
        m, inp, o = k
        if b.condition_for(conds, m, inp, o, families) is not None and b.unlock_state(r) is not True:
            locked.append(r["id"])
    if locked:
        add("UNLOCK_UNSTATED", 3, "output is unlock-only but the study does not state unlock status; skipped", locked)

    unplaced = [r["id"] for r in rows if not b.key_of(r, names)]
    if unplaced:
        add("UNPLACED", 3, "cannot be matched to an input/output key", unplaced)

    # internal consistency: totals vs average, and rows that report more than one cast per hit
    incons = []
    for r in rows:
        n, tot, a = b.num(r.get("casts")), b.num(r.get("totalQuantity")), b.per_cast_average(r)
        hits = b.num(r.get("castsWithDrop"))
        if n and hits is not None and hits > n:
            incons.append(r["id"])
        if n and tot is not None and a is not None and abs(tot / n - a) > max(0.05, 0.1 * a):
            incons.append(r["id"])
    if incons:
        add("NUMBERS_DISAGREE", 3, "hits exceed casts, or total/casts disagrees with the stated average", incons)
    implied = []
    for r in rows:
        n, tot, a, ipc = b.num(r.get("casts")), b.num(r.get("totalQuantity")), b.num(r.get("averageShown")), b.num(r.get("inputsPerCast"))
        if n and tot and a and ipc and r.get("averagePer") == "input":
            per_cast_inputs = tot / (a * n)
            if abs(per_cast_inputs - ipc) / ipc > 0.1:
                implied.append(r["id"])
    if implied:
        add("INPUTS_PER_CAST_IMPLIED_DIFFERENT", 4,
            "total, casts and per-input average only fit together at a different inputs-per-cast than stated "
            "(casts or inputsPerCast is off, possibly by 4x)", implied)
    return out


def main():
    rows = b.load()
    names = b.name_maps(rows)
    conds = b.load_conditions(rows)
    families = defaultdict(set)
    for r in rows:
        if r.get("inputName") and r.get("inputItemID"):
            families[r["inputName"].strip().lower()].add(str(r["inputItemID"]))
    studies = defaultdict(list)
    for r in rows:
        if r.get("type") != "drop" or r.get("sourceKind") in b.REFERENCE_KINDS:
            continue
        studies[r.get("studyKey") or r["id"]].append(r)
    report = []
    for key, rs in studies.items():
        iss = issues_for(rs, conds, families, names)
        casts = sum(b.num(r.get("casts")) or 0 for r in rs)
        weight = max((b.num(r.get("casts")) or 0) for r in rs) if rs else 0
        score = sum(i["severity"] * len(i["records"]) for i in iss) * (1 + min(weight, 5000) / 1000)
        report.append({
            "studyKey": key, "agent": rs[0].get("agent"), "method": rs[0].get("method"),
            "records": len(rs), "maxCasts": weight, "inputs": sorted({str(r.get("inputItemID") or r.get("inputName"))
                                                                      for r in rs}),
            "source": (rs[0].get("source") or {}).get("url"), "issues": iss, "score": round(score, 1),
        })
    report.sort(key=lambda s: -s["score"])
    clean = sum(1 for s in report if not s["issues"])
    counts = defaultdict(int)
    for s in report:
        for i in s["issues"]:
            counts[i["code"]] += len(i["records"])
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, "study-audit.json"), "w", encoding="utf-8", newline="\n") as fh:
        json.dump({"studies": len(report), "clean": clean, "issueRecordCounts": dict(counts), "worklist": report},
                  fh, indent=1)
    lines = [f"# Study audit", "", f"{len(report)} studies; {clean} with no findings. Records per finding type:", ""]
    lines += [f"- {k}: {v}" for k, v in sorted(counts.items(), key=lambda kv: -kv[1])]
    lines += ["", "## Worklist (highest score first, first 60)", "",
              "| Score | Study | Agent | Method | Records | Casts | Findings |", "| --- | --- | --- | --- | --- | --- | --- |"]
    for s in report[:60]:
        if not s["issues"]:
            break
        lines.append(f"| {s['score']} | {s['studyKey']} | {s['agent']} | {s['method']} | {s['records']} | "
                     f"{s['maxCasts']:.0f} | {', '.join(i['code'] for i in s['issues'])} |")
    with open(os.path.join(OUT, "study-audit.md"), "w", encoding="utf-8", newline="\n") as fh:
        fh.write("\n".join(lines) + "\n")
    print(f"{len(report)} studies, {clean} clean; findings: {dict(counts)}")


if __name__ == "__main__":
    main()
