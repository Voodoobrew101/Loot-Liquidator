#!/usr/bin/env python3
"""M08: what the estimator changes did to the committed evidence, measured against the pre-M08 rules.

Read-only. For each behavioural change it keeps the OLD function beside the NEW one in build_estimates and
counts the records whose result differs:
  unlock   old: phrases in specialization / notes / stats   new: structured `unlockState` first, else the same phrases
  dates    old: first ten characters of any dataDate / observedOn / published that starts 'YYYY-'
           new: ISO dates only (YYYY-MM-DD, YYYY-MM, ranges, timestamps); month-only placed only when unambiguous
  percent  old: percentMeaning 'perCast' or null is a per-cast chance   new: only 'perCast'
It also summarizes the per-record usage (build_estimates.analyze): records used by role and unused by reason.

Usage, from the repository root:
  python3 research/v3/migration/tools/estimator_effects.py [--json OUT.json]
Deterministic: sorted output, no timestamps.
"""
import argparse
import json
import os
import sys
from collections import Counter

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "tools"))
import build_estimates as b  # noqa: E402


def old_unlock_state(r):
    return b.unlock_state_from_text(r)


def old_study_date(r):
    for v in (r.get("dataDate"), r.get("observedOn"), (r.get("source") or {}).get("published")):
        if isinstance(v, str) and len(v) >= 10 and v[:4].isdigit() and v[4] == "-":
            return v[:10]
    return None


def old_epoch_weight(r, method, inp, changes):
    if not inp.isdigit():
        return 1.0, None
    applicable = [d for m, (lo, hi), d in changes if m == method and lo <= int(inp) <= hi]
    if not applicable:
        return 1.0, None
    latest = max(applicable)
    d = old_study_date(r)
    if d and d >= latest:
        if not r.get("dataDate") and not r.get("observedOn"):
            return 1.0, "dated by post date only, after " + latest
        return 1.0, None
    return b.OLD_EPOCH_WEIGHT, ("before " if d else "undated vs ") + latest


def old_chance_from_percent(r):
    p = b.num(r.get("percentShown"))
    if p is None or r.get("percentMeaning") not in ("perCast", None):
        return None
    return p / 100


def report(rows):
    changes = b.load_rate_changes()
    names = b.name_maps(rows)
    drops = [r for r in rows if r.get("type") == "drop"]

    unlock_changed = [r["id"] for r in rows if old_unlock_state(r) != b.unlock_state(r)]
    unlock_fields = Counter(
        {"structured": sum(1 for r in rows if "unlockState" in r)} |
        {"textTrue": sum(1 for r in drops if b.is_study_row(r) and b.unlock_state_from_text(r) is True),
         "textFalse": sum(1 for r in drops if b.is_study_row(r) and b.unlock_state_from_text(r) is False)})
    # where the text answer comes from: the specialization field alone, or only from notes / stats
    only_notes = [r["id"] for r in drops if b.is_study_row(r) and b.unlock_state_from_text(r) is not None
                  and b.unlock_state_from_text({"specialization": r.get("specialization")}) is None]

    date_changed, epoch_changed = [], []
    for r in rows:
        if old_study_date(r) != b.study_date(r):
            date_changed.append(r["id"])
    for r in drops:
        k = b.key_of(r, names)
        if k and k[1].isdigit():
            if old_epoch_weight(r, k[0], k[1], changes) != b.epoch_weight(r, k[0], k[1], changes):
                epoch_changed.append(r["id"])
    prose = Counter(f for r in rows for f in ("dataDate", "observedOn")
                    if isinstance(r.get(f), str) and b.iso_date(r[f]) is None)
    month_only = sum(1 for r in rows for f in ("dataDate", "observedOn") if b.iso_date(r.get(f)) and len(b.iso_date(r[f])) == 7)

    percent_changed = [r["id"] for r in drops if old_chance_from_percent(r) != b.chance_from_percent(r)]
    meanings = Counter(str(r.get("percentMeaning")) for r in drops if r.get("percentShown") is not None)

    results, unplaced, usage = b.analyze(rows)
    unused = b.unused_report(rows, usage)
    dup_rows = [r for r in rows if usage[id(r)].get("reason") == "duplicateRowInStudy"]
    return {
        "records": len(rows), "dropRows": len(drops), "estimates": len(results), "unplaced": unplaced,
        "unlock": {"recordsWithStructuredField": unlock_fields["structured"], "recordsChanged": sorted(unlock_changed),
                   "studyRowsReadTrueFromText": unlock_fields["textTrue"], "studyRowsReadFalseFromText": unlock_fields["textFalse"],
                   "textAnswerOnlyFromNotesOrStats": len(only_notes)},
        "dates": {"proseDateFields": dict(sorted(prose.items())), "monthOnlyDateFields": month_only,
                  "studyDateChanged": sorted(date_changed), "epochWeightChanged": sorted(epoch_changed)},
        "percent": {"meaningOfRowsWithAPercentage": dict(sorted(meanings.items())), "rowsChanged": sorted(percent_changed)},
        "usage": {"used": unused["used"], "unused": unused["unused"], "usedByRole": unused["usedByRole"],
                  "unusedByReason": unused["unusedByReason"],
                  "unusedRowsThatWidenedARange": dict(sorted(Counter(e["reason"] for e in unused["unusedRecords"] if e.get("range")).items())),
                  "duplicateRowsInStudy": {"rows": len(dup_rows), "studies": len({b.study_ref(r) for r in dup_rows})}},
    }


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--json")
    a = ap.parse_args(argv)
    d = report(b.load())
    print(f"unlockState: {d['unlock']['recordsWithStructuredField']} records carry it; {len(d['unlock']['recordsChanged'])} results change")
    print(f"dates: {sum(d['dates']['proseDateFields'].values())} prose date fields; {len(d['dates']['studyDateChanged'])} study dates and "
          f"{len(d['dates']['epochWeightChanged'])} epoch weights change")
    print(f"percentMeaning: {len(d['percent']['rowsChanged'])} rows change; meanings {d['percent']['meaningOfRowsWithAPercentage']}")
    print(f"usage: {d['usage']['used']} records used, {d['usage']['unused']} unused with a reason")
    if a.json:
        with open(a.json, "w", encoding="utf-8", newline="\n") as fh:
            json.dump(d, fh, indent=1, sort_keys=True)
            fh.write("\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
