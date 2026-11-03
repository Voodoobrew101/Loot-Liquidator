#!/usr/bin/env python3
"""M06: units, denominators and cast bases of every drop row, before and after the M06 rule.

Read-only. Two readings of the same rows, so one run shows before and after:
  legacy   the pre-M06 estimator: a total counts only with `casts`; an average per input needs the row's
           own inputsPerCast; every cast counts fully, in whatever batch size the row used
  current  build_estimates.row_use() in the group's unit (build_estimates.group_unit)
Reported:
  * drop rows by sourceKind, castsBasis and which unit fields they carry
  * placed study rows that contribute nothing, with a machine-readable reason per row (by agent and study)
  * estimate groups whose contributing rows use different batch sizes (legacy: mixed without conversion;
    current: converted per input, and which per-cast chances were left out)
  * backfill candidates for the Master (S16 asks who backfills; agent files and corrections.jsonl are not
    edited here): agent totals whose input count is stated only in notes, and agent cast counts whose notes
    say they were counted from inputs. The note hints are pattern matches for a human to check, never
    read by the estimator.
Identity dedupe and unlock skips are not applied: they decide which copy counts, not what a row can say.

Usage, from the repository root:
  python3 research/v3/migration/tools/units_report.py [--json OUT.json]
Deterministic: sorted output, no timestamps.
"""
import argparse
import json
import os
import re
import sys
from collections import Counter, defaultdict

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "tools"))
import build_estimates as b  # noqa: E402

N = b.num
IMPORTED = "research/v3/evidence/imported/"
NUMBER = r"(\d{1,3}(?:,\d{3})+|\d+(?:\.\d+)?\s?k\b|\d{2,})"
INPUT_HINT = re.compile(NUMBER + r"\s+(?:(?:rank|quality|r|q)[- ]?\d\s+|[A-Za-z'-]+\s+){0,3}?"
                        r"(ore|herbs?|blooms?|stacks?|flowers?)\b", re.I)
NO_INFERENCE = re.compile(r"do not (?:infer|derive|equate)|no inferred casts|not (?:a )?verified (?:cast|consumed)"
                          r"|casts? (?:left|remain) null|not explicitly completed casts", re.I)
COUNTED_CASTS = re.compile(r"nominal (?:casts|prospects|mills|operations|completed)|nominal five-ore|five-ore-equivalent"
                           r"|assumes? (?:a )?standard 5-ore|(?:ore|herbs|stacks?)\)?\s*(?:/|÷|divided by)\s*\d+"
                           r"|[\d,]+\s*/\s*5\b|divided by (?:the )?(?:documented )?5|counted from (?:ore|herbs|inputs)"
                           r"|(?:casts?|prospects|mills) (?:is arithmetic|(?:are )?(?:inferred|derived|computed|calculated))"
                           r"|derived from (?:the )?stated 5|from 5 ore per cast|giving [\d,]+ five-ore|hence \d+ casts", re.I)


def agent_of(r):
    return "imported" if r["_file"].startswith(IMPORTED) else r["_file"].split("/")[3]


def legacy_use(r):
    """(chance, average) as the pre-M06 estimator read the row."""
    n, hits, pct = N(r.get("casts")), N(r.get("castsWithDrop")), b.chance_from_percent(r)
    chance = (hits is not None and bool(n)) or (pct is not None and pct <= 1)
    average = (N(r.get("totalQuantity")) is not None and bool(n)) or b.per_cast_average(r) is not None
    return chance, average


def fingerprint(r):
    a = N(r.get("averageShown")) is not None
    p = N(r.get("percentShown")) is not None
    return "|".join([r.get("castsBasis") or "none",
                     "casts" if N(r.get("casts")) is not None else "-",
                     "total" if N(r.get("totalQuantity")) is not None else "-",
                     "hits" if N(r.get("castsWithDrop")) is not None else "-",
                     "inputsProcessed" if N(r.get("inputsProcessed")) is not None else "-",
                     f"average/{r.get('averagePer')}" if a else "-",
                     f"percent/{r.get('percentMeaning')}" if p else "-",
                     f"batch{r.get('inputsPerCast')}"])


def ref(r):
    return {"id": r["id"], "file": r["_file"], "studyKey": r.get("studyKey"), "agent": agent_of(r)}


def report(rows):
    names = b.name_maps(rows)
    drops = [r for r in rows if r.get("type") == "drop"]
    groups = defaultdict(list)
    for r in drops:
        k = b.key_of(r, names)
        if k:
            groups[k].append(r)
    units = {k: b.group_unit(k[0], rs) for k, rs in groups.items()}
    keyed = {id(r): k for k, rs in groups.items() for r in rs}

    rows_by = Counter()
    for r in drops:
        rows_by["|".join(["study" if b.is_study_row(r) else "reference",
                          "imported" if agent_of(r) == "imported" else "agent",
                          r.get("castsBasis") or "none",
                          "casts" if N(r.get("casts")) is not None else "noCasts"])] += 1
    shapes = Counter(fingerprint(r) for r in drops if b.is_study_row(r))

    unused = {"legacy": [], "current": []}
    weighted, chance_left_out = Counter(), []
    for r in drops:
        if not b.is_study_row(r) or id(r) not in keyed:
            continue
        unit = units[keyed[id(r)]]
        use = b.row_use(r, unit)
        if not any(legacy_use(r)):
            unused["legacy"].append(r)
        if not (use["chance"] or use["average"]):
            unused["current"].append((r, use["reasons"] or ["chanceNotConvertibleOnly"]))
        elif use["weight"] < 1:
            weighted["|".join(sorted({x.split(":")[0] for x in use["reasons"]}))] += 1
        if any(x.startswith("chanceNotConvertible") for x in use["reasons"]):
            chance_left_out.append(dict(ref(r), group=list(map(str, keyed[id(r)])), reasons=use["reasons"]))

    def tally(entries, why):
        by_reason, by_agent, studies = Counter(), Counter(), defaultdict(set)
        for e in entries:
            r, reason = why(e)
            by_reason[reason] += 1
            by_agent[f"{agent_of(r)}|{reason}"] += 1
            studies[f"{agent_of(r)}|{reason}"].add(b.study_ref(r))
        return {"rows": len(entries), "byReason": dict(sorted(by_reason.items())),
                "byAgent": dict(sorted(by_agent.items())),
                "studiesByAgent": {k: len(v) for k, v in sorted(studies.items())}}

    legacy_reason = lambda r: (r, "totalWithoutCasts" if N(r.get("totalQuantity")) is not None else "other")  # noqa: E731
    totals_legacy = [r for r in unused["legacy"] if N(r.get("totalQuantity")) is not None and N(r.get("casts")) is None]
    totals_current = [(r, why) for r, why in unused["current"] if N(r.get("totalQuantity")) is not None]

    mixed_legacy, converted = [], []
    for k in sorted(groups, key=lambda k: (k[0], k[1], str(k[2]))):
        contributing = [r for r in groups[k] if any(legacy_use(r))]
        stated = {b.row_unit(r) for r in contributing} - {None}
        if len(stated) > 1:
            mixed_legacy.append({"group": list(map(str, k)), "batches": sorted(stated)})
        conv = sorted({r["id"] for r in groups[k] if any(x.startswith("converted") for x in b.row_use(r, units[k])["reasons"])})
        if conv:
            converted.append({"group": list(map(str, k)), "unit": units[k], "convertedRows": conv})
    mixed_current = []
    for k in sorted(groups, key=lambda k: (k[0], k[1], str(k[2]))):
        unit, seen = units[k], set()
        for r in groups[k]:
            use = b.row_use(r, unit)
            in_unit = any(x.startswith(("converted", "castsFromInputs")) for x in use["reasons"])
            if (use["chance"] or use["average"]) and not in_unit:
                seen.add(b.row_unit(r) if unit else None)
        if len(seen - {None, unit}) > 0:
            mixed_current.append({"group": list(map(str, k)), "unit": unit, "batches": sorted(seen - {None})})

    backfill_totals = []
    for r, why in unused["current"]:
        if agent_of(r) == "imported" or "totalWithoutCasts" not in why:
            continue
        text = " ".join(str(r.get(f) or "") for f in ("notes", "quote"))
        hint = INPUT_HINT.search(text)
        if hint:
            backfill_totals.append(dict(ref(r), hint=hint.group(0), agentAdvisesNoInference=bool(NO_INFERENCE.search(text))))
    backfill_basis = [dict(ref(r), casts=r.get("casts"), hint=COUNTED_CASTS.search(r.get("notes") or "").group(0))
                      for r in drops
                      if b.is_study_row(r) and agent_of(r) != "imported" and N(r.get("casts")) is not None
                      and not r.get("castsBasis") and COUNTED_CASTS.search(r.get("notes") or "")]

    def studies_of(entries):
        return len({(e["file"], e["studyKey"]) for e in entries})

    return {
        "dropRows": len(drops),
        "rowsByKindOriginBasisCasts": dict(sorted(rows_by.items())),
        "studyRowShapes": dict(sorted(shapes.items(), key=lambda kv: (-kv[1], kv[0]))),
        "groupUnits": dict(sorted(Counter(f"{k[0]}|{u}" for k, u in units.items()).items())),
        "contributeNothing": {
            "legacy": tally(unused["legacy"], legacy_reason),
            "current": tally(unused["current"], lambda e: (e[0], e[1][-1])),
        },
        "totalsWithoutCasts": {
            "legacy": {"rows": len(totals_legacy), "studies": len({b.study_ref(r) for r in totals_legacy})},
            "current": {"rows": len(totals_current), "studies": len({b.study_ref(r) for r, _ in totals_current})},
        },
        "weightedDown": dict(sorted(weighted.items())),
        "mixedBatchGroups": {"legacy": mixed_legacy, "currentUnconverted": mixed_current, "converted": converted},
        "chanceLeftOut": sorted(chance_left_out, key=lambda e: (e["file"], e["id"])),
        "backfill": {
            "totalsWithInputInNotes": {"rows": len(backfill_totals), "studies": studies_of(backfill_totals),
                                       "agentAdvisesNoInference": sum(e["agentAdvisesNoInference"] for e in backfill_totals),
                                       "list": sorted(backfill_totals, key=lambda e: (e["file"], e["id"]))},
            "castsCountedFromInputs": {"rows": len(backfill_basis), "studies": studies_of(backfill_basis),
                                       "list": sorted(backfill_basis, key=lambda e: (e["file"], e["id"]))},
        },
        "unusedRows": sorted([dict(ref(r), reasons=why) for r, why in unused["current"]],
                             key=lambda e: (e["file"], e["id"])),
    }


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--json", help="write the full report here")
    a = ap.parse_args()
    d = report(b.load())
    if a.json:
        with open(a.json, "w", encoding="utf-8", newline="\n") as fh:
            json.dump(d, fh, indent=1, sort_keys=False)
            fh.write("\n")
    c = d["contributeNothing"]
    print(f"{d['dropRows']} drop rows; placed study rows contributing nothing: legacy {c['legacy']['rows']}, "
          f"current {c['current']['rows']}")
    print(f"totals without casts unused: legacy {d['totalsWithoutCasts']['legacy']}, current {d['totalsWithoutCasts']['current']}")
    print(f"mixed-batch groups: legacy {len(d['mixedBatchGroups']['legacy'])}, current unconverted "
          f"{len(d['mixedBatchGroups']['currentUnconverted'])}, converted {len(d['mixedBatchGroups']['converted'])}")
    bf = d["backfill"]
    print(f"backfill: totals with input in notes {bf['totalsWithInputInNotes']['rows']} rows / "
          f"{bf['totalsWithInputInNotes']['studies']} studies; counted casts {bf['castsCountedFromInputs']['rows']} rows / "
          f"{bf['castsCountedFromInputs']['studies']} studies")


if __name__ == "__main__":
    main()
