#!/usr/bin/env python3
"""M02.1: validate every v3 evidence record and correction line against evidence-format.md.

Read-only: reports problems, never fixes them. Fixes go through corrections.jsonl or new records.

Records are checked as the estimator sees them: after corrections.jsonl is applied and records
named in another record's `replaces` are dropped. Findings on corrected records carry
"corrected": true. Records excluded by a correction are not checked.

Severity:
  error    the estimator will ignore or misread the record (bad JSON, no/unknown type, wrong
           value types, impossible numbers, enum values the estimator does not understand,
           duplicate ID inside one file, correction for a missing record or uncorrectable field)
  warning  format drift that does not change estimates today (missing documented keys,
           ID reused across files, non-ISO dates)

Usage, from the repository root:
  python3 research/v3/migration/tools/validate.py [--root DIR] [--out FILE] [--strict]
Writes research/v3/migration/manifest/validation.json (sorted, deterministic).
--strict exits 1 when any error is found.
"""
import argparse
import glob
import json
import os
import re
import sys
from collections import Counter, defaultdict

DEFAULT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", ".."))
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "tools"))
import build_estimates as _b  # noqa: E402  (only apply_corrections and CORRECTABLE are used)

COMMON = ["id", "type", "agent", "recordedOn", "source", "originalSource", "dataDate", "patch",
          "quote", "notes", "replaces"]
TYPE_FIELDS = {
    "drop": ["studyKey", "method", "inputItemID", "inputName", "inputRank", "gearGroup", "outputItemID",
             "outputName", "outputRank", "casts", "inputsPerCast", "totalQuantity", "castsWithDrop",
             "percentShown", "percentMeaning", "minSeen", "maxSeen", "skill", "specialization", "stats",
             "sourceKind", "averageShown", "averagePer", "histogram"],
    "token": ["tokenItemID", "tokenName", "rewards", "howRedeemed", "vendor", "cost", "listComplete"],
    "exchange": ["giveItemID", "giveName", "giveCount", "getItemID", "getName", "getCount", "where",
                 "requirements"],
    "noDisenchant": ["itemID", "itemName"],
    "recipe": ["method", "recipeSpellID", "recipeName", "inputItemID", "inputName", "inputsPerCast",
               "otherReagents", "outputItemID", "outputName", "outputCount"],
    "rateChange": ["date", "patch", "method", "affects", "wording", "sizeIfGiven"],
    "condition": ["method", "outputItemID", "outputName", "inputItemIDs", "inputName", "requires",
                  "requiresSkill"],
    "searched": ["lookingFor", "whereLooked"],
}
METHODS = {"Prospect", "Mill", "Disenchant", "Smelt"}
SOURCE_KINDS = {"study", "personal-pooled", "tsm-table", "compiled-research", "reference"}
PERCENT_MEANINGS = {"perCast", "perInput", "unclear"}
AVERAGE_PER = {"cast", "input", "1000 inputs"}
RANKS = {1, 2, 3}
NUMERIC = ["casts", "inputsPerCast", "totalQuantity", "castsWithDrop", "percentShown", "averageShown",
           "minSeen", "maxSeen"]
ISO_DATE = re.compile(r"^\d{4}-\d{2}-\d{2}(/\d{4}-\d{2}-\d{2})?$")
CORRECTABLE = _b.CORRECTABLE


def is_num(v):
    return isinstance(v, (int, float)) and not isinstance(v, bool)


def check_record(r):
    """Return a list of (severity, code, message) for one parsed record."""
    out = []
    add = lambda sev, code, msg: out.append((sev, code, msg))  # noqa: E731
    if not isinstance(r, dict):
        return [("error", "NOT_OBJECT", "line is not a JSON object")]
    t = r.get("type")
    if not r.get("id"):
        add("error", "ID_MISSING", "record has no id")
    if t is None:
        add("error", "TYPE_MISSING", "record has no type; the estimator ignores it")
        return out
    if t not in TYPE_FIELDS:
        add("error", "TYPE_UNKNOWN", f"type {t!r} is not in evidence-format.md")
        return out
    missing = [k for k in COMMON + TYPE_FIELDS[t] if k not in r]
    if missing:
        add("warning", "FIELDS_MISSING", "missing documented keys: " + ", ".join(missing))
    src = r.get("source")
    if src is not None and not isinstance(src, dict):
        add("error", "SOURCE_NOT_OBJECT", "source must be an object")
    for k in ("dataDate",):
        v = r.get(k)
        if isinstance(v, str) and not ISO_DATE.match(v):
            add("warning", "DATE_NOT_ISO", f"{k} is free text, treated as undated: {v[:60]!r}")
    if t in ("drop", "recipe", "condition", "rateChange") and r.get("method") is not None \
            and r.get("method") not in METHODS:
        add("error", "METHOD_UNKNOWN", f"method {r.get('method')!r} is not one of {sorted(METHODS)}")
    if t == "drop":
        if r.get("method") is None:
            add("error", "METHOD_MISSING", "drop record without method cannot be placed")
        sk = r.get("sourceKind")
        if sk is not None and sk not in SOURCE_KINDS:
            add("error", "SOURCE_KIND_UNKNOWN", f"sourceKind {sk!r} is not recognised; counted as a study")
        pm = r.get("percentMeaning")
        if pm is not None and pm not in PERCENT_MEANINGS:
            add("error", "PERCENT_MEANING_UNKNOWN", f"percentMeaning {str(pm)[:60]!r} is not an allowed value")
        ap = r.get("averagePer")
        if ap is not None and ap not in AVERAGE_PER:
            add("error", "AVERAGE_PER_UNKNOWN", f"averagePer {ap!r} is not an allowed value")
        for k in ("inputRank", "outputRank"):
            v = r.get(k)
            if v is not None and v not in RANKS:
                add("error", "RANK_INVALID", f"{k} {v!r} is not 1, 2, 3 or null")
        for k in NUMERIC:
            v = r.get(k)
            if v is None:
                continue
            if not is_num(v):
                add("error", "NOT_A_NUMBER", f"{k} must be a number or null, got {v!r}")
            elif v < 0:
                add("error", "NEGATIVE", f"{k} is negative")
        n, h = r.get("casts"), r.get("castsWithDrop")
        if is_num(n) and is_num(h) and h > n:
            add("error", "HITS_EXCEED_CASTS", f"castsWithDrop {h} > casts {n}")
        lo, hi = r.get("minSeen"), r.get("maxSeen")
        if is_num(lo) and is_num(hi) and lo > hi:
            add("error", "RANGE_INVERTED", f"minSeen {lo} > maxSeen {hi}")
        p = r.get("percentShown")
        if is_num(p) and p > 100 and r.get("percentMeaning") == "perCast":
            add("error", "PERCENT_OVER_100", f"per-cast percentage {p} > 100")
        if r.get("averageShown") is not None and r.get("averagePer") is None:
            add("warning", "AVERAGE_UNIT_MISSING", "averageShown without averagePer is not used")
        hist = r.get("histogram")
        if hist is not None and not (isinstance(hist, dict) and all(is_num(v) for v in hist.values())):
            add("error", "HISTOGRAM_INVALID", "histogram must map amounts to counts")
    return out


def validate(root):
    files = sorted(glob.glob(os.path.join(root, "research", "v3", "evidence", "**", "*.jsonl"), recursive=True))
    findings, ids_where = [], defaultdict(set)
    records = 0
    raw = []
    for path in files:
        rel = os.path.relpath(path, root).replace(os.sep, "/")
        seen = Counter()
        for ln, line in enumerate(open(path, encoding="utf-8"), 1):
            if not line.strip():
                continue
            try:
                r = json.loads(line)
            except json.JSONDecodeError as e:
                findings.append({"file": rel, "line": ln, "id": None, "severity": "error",
                                 "code": "BAD_JSON", "message": str(e)[:120], "corrected": False})
                continue
            records += 1
            if not isinstance(r, dict):
                findings.append({"file": rel, "line": ln, "id": None, "severity": "error",
                                 "code": "NOT_OBJECT", "message": "line is not a JSON object", "corrected": False})
                continue
            rid = r.get("id")
            if rid:
                seen[rid] += 1
                ids_where[rid].add(rel)
                if seen[rid] == 2:
                    findings.append({"file": rel, "line": ln, "id": rid, "severity": "error",
                                     "code": "ID_DUPLICATE_IN_FILE", "message": "id used twice in one file",
                                     "corrected": False})
            r = dict(r, _file=rel, _line=ln)
            raw.append(r)
    replaced = {r["replaces"] for r in raw if r.get("replaces")}
    effective = [r for r in raw if r.get("id") not in replaced]
    old_root = _b.ROOT
    _b.ROOT = root
    try:
        effective = _b.apply_corrections(effective)
    finally:
        _b.ROOT = old_root
    for r in effective:
        for sev, code, msg in check_record({k: v for k, v in r.items() if not k.startswith("_")}):
            findings.append({"file": r["_file"], "line": r["_line"], "id": r.get("id"), "severity": sev,
                             "code": code, "message": msg, "corrected": bool(r.get("_corrected"))})
    for rid, where in sorted(ids_where.items()):
        if len(where) > 1:
            findings.append({"file": sorted(where)[0], "line": None, "id": rid, "severity": "warning",
                             "code": "ID_REUSED_ACROSS_FILES",
                             "message": "id also in " + ", ".join(sorted(where)[1:]) + "; corrections need `file`",
                             "corrected": False})
    corr = os.path.join(root, "research", "v3", "corrections.jsonl")
    if os.path.exists(corr):
        rel = os.path.relpath(corr, root).replace(os.sep, "/")
        for ln, line in enumerate(open(corr, encoding="utf-8"), 1):
            if not line.strip():
                continue
            try:
                c = json.loads(line)
            except json.JSONDecodeError as e:
                findings.append({"file": rel, "line": ln, "id": None, "severity": "error",
                                 "code": "BAD_JSON", "message": str(e)[:120], "corrected": False})
                continue
            rid = c.get("recordID")
            if c.get("field") not in CORRECTABLE:
                findings.append({"file": rel, "line": ln, "id": rid, "severity": "error",
                                 "code": "CORRECTION_FIELD_NOT_CORRECTABLE",
                                 "message": f"field {c.get('field')!r} is ignored by build_estimates.py", "corrected": False})
            if rid not in ids_where:
                findings.append({"file": rel, "line": ln, "id": rid, "severity": "error",
                                 "code": "CORRECTION_TARGET_MISSING", "message": "recordID not found in evidence", "corrected": False})
            elif c.get("file") and c["file"] not in ids_where[rid]:
                findings.append({"file": rel, "line": ln, "id": rid, "severity": "error",
                                 "code": "CORRECTION_FILE_MISMATCH", "message": f"{rid} is not in {c['file']}", "corrected": False})
    findings.sort(key=lambda f: (f["severity"] != "error", f["file"], f["line"] or 0, f["code"], str(f["id"])))
    counts = Counter((f["severity"], f["code"]) for f in findings)
    return {
        "evidenceFiles": len(files), "records": records, "effectiveRecords": len(effective),
        "errors": sum(v for (s, _), v in counts.items() if s == "error"),
        "warnings": sum(v for (s, _), v in counts.items() if s == "warning"),
        "byCode": {f"{s}:{c}": v for (s, c), v in sorted(counts.items())},
        "findings": findings,
    }


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--root", default=DEFAULT_ROOT)
    ap.add_argument("--out", default=None)
    ap.add_argument("--strict", action="store_true")
    a = ap.parse_args(argv)
    res = validate(a.root)
    out = a.out or os.path.join(a.root, "research", "v3", "migration", "manifest", "validation.json")
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, "w", encoding="utf-8", newline="\n") as fh:
        json.dump(res, fh, indent=1, sort_keys=True)
        fh.write("\n")
    print(f"{res['records']} records in {res['evidenceFiles']} files ({res['effectiveRecords']} after corrections): "
          f"{res['errors']} errors, "
          f"{res['warnings']} warnings")
    for k, v in res["byCode"].items():
        print(f"  {k}: {v}")
    return 1 if a.strict and res["errors"] else 0


if __name__ == "__main__":
    sys.exit(main())
