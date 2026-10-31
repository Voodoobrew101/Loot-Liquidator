#!/usr/bin/env python3
"""Turn every v3 evidence record into one estimate per (method, input, material).

For each material it produces:
  chance      how often at least one drops per cast (0-1)
  average     average amount per cast, zeros included (this is what gold uses)
  range       smallest and largest amount seen in one cast (default 1-1)
  confidence  chance (0-100%) that the true drop chance is within +/-5 points
  casts       effective number of casts behind the estimate
  basis       where the numbers came from

Method (see research/v3/README.md and the owner's notes):
  * Studies are added together as casts and drops: a 1,000-cast study weighs 1,000,
    a 10-cast study weighs 10.
  * Reference values (old TSM tables, compiled research, borrowed groups) are only a
    starting guess worth PRIOR_CASTS casts, never added to study counts.
  * A percentage with no cast count counts as a small study of SMALL_STUDY_CASTS casts.
  * Missing average = chance x middle of the range; missing chance = average / middle of the range.
  * Conditional drops (need a specialization unlock or skill level; listed in
    research/v3/conditions.jsonl or recorded as `condition` records) are tagged
    `conditional` and kept out of the normal baseline counts. The addon should add them
    only for characters that meet the condition.
  * Confidence comes from a beta distribution of those counts (the "weighted count with a
    starting guess" model, also called beta-binomial / empirical Bayes).

Nothing here is tuned to make numbers look better. Change the constants below, not the data.

Usage, from the repository root:
  python3 research/v3/tools/build_estimates.py
Writes research/v3/output/estimates.json and research/v3/output/summary.md
"""
import glob
import json
import os
from collections import defaultdict

try:
    from scipy.stats import beta as _beta
except ImportError:  # pragma: no cover
    _beta = None

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
EVIDENCE = os.path.join(ROOT, "research", "v3", "evidence")
OUT = os.path.join(ROOT, "research", "v3", "output")

PRIOR_CASTS = 20        # weight of a starting guess
SMALL_STUDY_CASTS = 20  # weight of a percentage with no cast count
WITHIN = 0.05           # owner's accuracy target: +/-5 percentage points
GUESS_ONLY_MAX_CONFIDENCE = 30  # a starting guess alone is never shown as trustworthy
GUESS_CONFIDENCE_CASTS = 5      # how much a starting guess adds to confidence (not to the estimate)
REFERENCE_KINDS = {"tsm-table", "compiled-research", "reference"}


def num(v):
    return v if isinstance(v, (int, float)) and not isinstance(v, bool) else None


def load():
    rows = []
    for path in sorted(glob.glob(os.path.join(EVIDENCE, "**", "*.jsonl"), recursive=True)):
        for line in open(path, encoding="utf-8"):
            line = line.strip()
            if not line:
                continue
            try:
                r = json.loads(line)
            except json.JSONDecodeError:
                continue
            r["_file"] = os.path.relpath(path, ROOT)
            rows.append(r)
    replaced = {r["replaces"] for r in rows if r.get("replaces")}
    return [r for r in rows if r.get("id") not in replaced]


def load_conditions(rows):
    """(method, outputItemID) -> list of (set of input IDs or None for all, requires text)."""
    found = []
    path = os.path.join(ROOT, "research", "v3", "conditions.jsonl")
    if os.path.exists(path):
        for line in open(path, encoding="utf-8"):
            if line.strip():
                found.append(json.loads(line))
    found += [r for r in rows if r.get("type") == "condition"]
    out = {}
    for c in found:
        if not c.get("method") or not c.get("outputItemID"):
            continue
        ids = set(str(i) for i in c["inputItemIDs"]) if c.get("inputItemIDs") else None
        out.setdefault((c["method"], int(c["outputItemID"])), []).append((ids, c.get("requires")))
    return out


def condition_for(conds, method, inp, out):
    for ids, req in conds.get((method, out), []):
        if ids is None or inp in ids:
            return req or "an unlock (see conditions list)"
    return None


def name_maps(rows):
    """Learn name -> item ID from records that carry both, to place name-only records."""
    names = defaultdict(set)
    for r in rows:
        for idk, nk in (("inputItemID", "inputName"), ("outputItemID", "outputName")):
            if r.get(idk) and r.get(nk):
                names[r[nk].strip().lower()].add(r[idk])
    return {k: next(iter(v)) for k, v in names.items() if len(v) == 1}


def key_of(r, names):
    if r.get("gearGroup"):
        g = r["gearGroup"]
        inp = f"gear:{g.get('expansion')}:{g.get('quality')}:{g.get('kind')}"
    else:
        inp = r.get("inputItemID") or names.get((r.get("inputName") or "").strip().lower())
    out = r.get("outputItemID") or names.get((r.get("outputName") or "").strip().lower())
    if not inp or not out or not r.get("method"):
        return None
    return (r["method"], str(inp), int(out))


def per_cast_average(r):
    a = num(r.get("averageShown"))
    if a is None:
        return None
    per, batch = r.get("averagePer"), num(r.get("inputsPerCast"))
    if per == "cast":
        return a
    if per == "input" and batch:
        return a * batch
    if per == "1000 inputs" and batch:
        return a * batch / 1000
    return None


def chance_from_percent(r):
    p = num(r.get("percentShown"))
    if p is None or r.get("percentMeaning") not in ("perCast", None):
        return None
    return p / 100  # percentShown is always written as a percentage (18.3 means 18.3%)


def confidence(p, n):
    """Chance (0-100) that the true rate is within +/-WITHIN of p, given n effective casts."""
    if n <= 0 or p is None:
        return 0
    a, b = p * n + 0.5, (1 - p) * n + 0.5
    if _beta is None:  # normal approximation fallback
        import math
        sd = math.sqrt(max(p * (1 - p), 1e-6) / (n + 1))
        z = WITHIN / sd
        return round(100 * math.erf(z / math.sqrt(2)))
    m = a / (a + b)
    return round(100 * (_beta.cdf(min(1, m + WITHIN), a, b) - _beta.cdf(max(0, m - WITHIN), a, b)))


def build(rows):
    names = name_maps(rows)
    conds = load_conditions(rows)
    groups = defaultdict(lambda: {"studies": [], "refs": [], "lo": None, "hi": None, "unplaced": 0})
    unplaced = 0
    for r in rows:
        if r.get("type") != "drop":
            continue
        k = key_of(r, names)
        if not k:
            unplaced += 1
            continue
        g = groups[k]
        lo, hi = num(r.get("minSeen")), num(r.get("maxSeen"))
        if lo is not None and lo >= 1:
            g["lo"] = lo if g["lo"] is None else min(g["lo"], lo)
        if hi is not None and hi >= 1:
            g["hi"] = hi if g["hi"] is None else max(g["hi"], hi)
        (g["refs"] if r.get("sourceKind") in REFERENCE_KINDS else g["studies"]).append(r)

    results = []
    for (method, inp, out), g in sorted(groups.items(), key=lambda kv: (kv[0][0], kv[0][1], kv[0][2])):
        lo = int(g["lo"] or 1)
        hi = int(max(g["hi"] or lo, lo))
        mid = (lo + hi) / 2
        # ---- starting guess from reference values (averaged, weight PRIOR_CASTS in total)
        ref_p = [x for x in (chance_from_percent(r) for r in g["refs"]) if x is not None and x <= 1]
        ref_e = [x for x in (per_cast_average(r) for r in g["refs"]) if x is not None]
        prior_p = sum(ref_p) / len(ref_p) if ref_p else None
        prior_e = sum(ref_e) / len(ref_e) if ref_e else None
        if prior_p is None and prior_e is not None:
            prior_p = min(1.0, prior_e / mid)
        if prior_e is None and prior_p is not None:
            prior_e = prior_p * mid
        # ---- add studies
        casts_p = drops = 0.0
        casts_e = total = 0.0
        seen = set()
        for r in g["studies"]:
            sk = (r.get("studyKey"), r.get("_file"))
            if sk in seen:
                continue  # one study, one count per material
            seen.add(sk)
            n = num(r.get("casts"))
            hits = num(r.get("castsWithDrop"))
            pct = chance_from_percent(r)
            tot = num(r.get("totalQuantity"))
            avg = per_cast_average(r)
            if n:
                if hits is not None:
                    casts_p += n; drops += hits
                elif pct is not None and pct <= 1:
                    casts_p += n; drops += pct * n
                if tot is not None:
                    casts_e += n; total += tot
                elif avg is not None:
                    casts_e += n; total += avg * n
            else:
                if pct is not None and pct <= 1:
                    casts_p += SMALL_STUDY_CASTS; drops += pct * SMALL_STUDY_CASTS
                if avg is not None:
                    casts_e += SMALL_STUDY_CASTS; total += avg * SMALL_STUDY_CASTS
        w = PRIOR_CASTS if prior_p is not None else 0
        we = PRIOR_CASTS if prior_e is not None else 0
        p = e = None
        basis = []
        if casts_p + w > 0:
            p = (drops + (prior_p or 0) * w) / (casts_p + w)
        if casts_e + we > 0:
            e = (total + (prior_e or 0) * we) / (casts_e + we)
        # An average above the top of the range means the range was too small.
        if e is not None and e > hi:
            import math
            hi = math.ceil(e)
            mid = (lo + hi) / 2
            basis.append("range widened to fit the average")
        if p is None and e is not None:
            p = min(1.0, e / mid); basis.append("chance from average / middle of range")
        if e is None and p is not None:
            e = p * mid; basis.append("average from chance x middle of range")
        if p is None:
            continue
        conflict = False
        if p and e is not None and e > p * hi + 1e-9:
            # Chance and average can't both be right with this range: sources disagree.
            import math
            hi = math.ceil(e / p)
            conflict = True
            basis.append("chance and average from different sources disagree; range widened, confidence halved")
        n_eff = max(casts_p, casts_e)
        n_conf = n_eff + (GUESS_CONFIDENCE_CASTS if (prior_p is not None or prior_e is not None) else 0)
        if casts_p == 0 and casts_e == 0:
            basis.insert(0, "starting guess only (reference values)")
        else:
            basis.insert(0, f"{round(n_eff):,} study casts" + (" + starting guess" if w or we else ""))
        req = condition_for(conds, method, inp, out)
        results.append({
            "method": method, "input": inp, "outputItemID": out,
            "conditional": req is not None, "requires": req,
            "chance": round(min(p, 1.0), 4), "average": round(e, 4), "range": [lo, hi],
            "confidence": (min(GUESS_ONLY_MAX_CONFIDENCE, confidence(min(p, 1.0), n_conf)) if n_eff == 0
                           else confidence(min(p, 1.0), n_conf)) // (2 if conflict else 1),
            "studyCasts": round(n_eff, 1),
            "basis": "; ".join(basis),
            "studies": len(seen), "referenceValues": len(g["refs"]),
        })
    return results, unplaced


def summary(results, unplaced, total_records):
    by_conf = [0, 0, 0, 0]
    cond = [r for r in results if r["conditional"]]
    for r in results:
        if r["conditional"]:
            continue
        c = r["confidence"]
        by_conf[0 if c < 50 else 1 if c < 75 else 2 if c < 90 else 3] += 1
    lines = [
        "# ItemDB estimates (first draft, generated)",
        "",
        f"Built by `research/v3/tools/build_estimates.py` from {total_records:,} evidence records.",
        f"{len(results):,} input/material estimates; {unplaced} records could not be placed yet (no item ID or name match).",
        f"{len(cond)} of them are conditional drops (need an unlock or skill level); they are left out of the confidence counts below and marked with what unlocks them.",
        "",
        "| Confidence | Estimates |", "| --- | --- |",
        f"| 90% or more | {by_conf[3]} |", f"| 75-89% | {by_conf[2]} |",
        f"| 50-74% | {by_conf[1]} |", f"| under 50% | {by_conf[0]} |",
        "",
        "Confidence = chance the true drop chance is within +/-5 points of the number shown.",
        "",
    ]
    mid = [r for r in results if r["input"].isdigit() and int(r["input"]) >= 236000]
    if mid:
        lines += ["## Midnight", "", "| Method | Input | Material | Chance | Average per cast | Range | Confidence | Needs unlock | Basis |",
                  "| --- | --- | --- | --- | --- | --- | --- | --- | --- |"]
        for r in sorted(mid, key=lambda r: (r["conditional"], r["method"], r["input"], -r["average"])):
            lines.append(f"| {r['method']} | {r['input']} | {r['outputItemID']} | {r['chance']*100:.1f}% | "
                         f"{r['average']:.3f} | {r['range'][0]}-{r['range'][1]} | {r['confidence']}% | "
                         f"{r['requires'] or ''} | {r['basis']} |")
    return "\n".join(lines) + "\n"


def main():
    rows = load()
    results, unplaced = build(rows)
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, "estimates.json"), "w", encoding="utf-8", newline="\n") as fh:
        json.dump({"withinTarget": WITHIN, "priorCasts": PRIOR_CASTS, "estimates": results}, fh, indent=1)
    with open(os.path.join(OUT, "summary.md"), "w", encoding="utf-8", newline="\n") as fh:
        fh.write(summary(results, unplaced, len(rows)))
    print(f"{len(rows)} records -> {len(results)} estimates ({unplaced} unplaced)")


if __name__ == "__main__":
    main()
