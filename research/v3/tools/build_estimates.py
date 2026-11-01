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
  * Each independent cohort counts once: by `cohortKey` when set, otherwise by a fingerprint of
    its source, input rank, casts and every number in the study (see study_identity).
  * Confidence comes from a beta distribution of those counts (the "weighted count with a
    starting guess" model, also called beta-binomial / empirical Bayes).

Agreed with ChatGPT in research/v3/strategy.md S5-S10 (2026-10-30).
Nothing here is tuned to make numbers look better. Change the constants below, not the data.

Usage, from the repository root:
  python3 research/v3/tools/build_estimates.py
Writes research/v3/output/estimates.json and research/v3/output/summary.md
"""
import glob
import json
import os
import re
from collections import defaultdict

from source_keys import normalize_url

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
NUMBER_FIELDS = ("castsWithDrop", "totalQuantity", "percentShown", "averageShown")  # compared for study identity


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
            r["_file"] = os.path.relpath(path, ROOT).replace(os.sep, "/")
            rows.append(r)
    replaced = {r["replaces"] for r in rows if r.get("replaces")}
    rows = [r for r in rows if r.get("id") not in replaced]
    return apply_corrections(rows)


CORRECTABLE = {"inputItemID", "inputName", "inputRank", "outputItemID", "outputName", "outputRank",
               "method", "casts", "castsWithDrop", "totalQuantity", "percentShown", "percentMeaning",
               "averageShown", "averagePer", "minSeen", "maxSeen", "dataDate", "patch", "sourceKind",
               "specialization", "originalSource", "inputsPerCast", "gearGroup", "exclude",
               "sourcePublished",  # sets source.published (post date, not collection date)
               "cohortKey"}


def apply_corrections(rows):
    """Apply research/v3/corrections.jsonl: one line per fix, original records never rewritten.
    Line: {"recordID": "...", "file": "<optional evidence file path, needed when an ID is used twice>",
           "field": "...", "value": ..., "reason": "...", "by": "Claude|ChatGPT", "date": "..."}
    field "exclude" with value true drops a record (e.g. not a real observation). Later lines win."""
    path = os.path.join(ROOT, "research", "v3", "corrections.jsonl")
    if not os.path.exists(path):
        return rows
    fixes = defaultdict(dict)
    for line in open(path, encoding="utf-8"):
        line = line.strip()
        if not line:
            continue
        try:
            c = json.loads(line)
        except json.JSONDecodeError:
            continue
        if c.get("field") in CORRECTABLE and c.get("recordID"):
            fixes[(c["recordID"], c.get("file"))][c["field"]] = c.get("value")
    out = []
    for r in rows:
        f = dict(fixes.get((r.get("id"), None), {}))
        f.update(fixes.get((r.get("id"), r.get("_file")), {}))
        if f:
            if f.get("exclude") is True:
                continue
            r = dict(r)
            if "sourcePublished" in f:
                r["source"] = dict(r.get("source") or {}, published=f.pop("sourcePublished"))
            r.update({k: v for k, v in f.items() if k != "exclude"})
            r["_corrected"] = True
        out.append(r)
    return out


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
        if c.get("outputName"):
            out.setdefault((c["method"], "family:" + c["outputName"].strip()), []).append((None, c.get("requires")))
    return out


def condition_for(conds, method, inp, out, families=None):
    # rank-unknown "family:<ore name>" inputs match a condition if any item ID with that name does
    members = (families or {}).get(inp[7:].lower(), set()) if str(inp).startswith("family:") else set()
    for ids, req in conds.get((method, out), []):
        if ids is None or inp in ids or (ids and members & set(ids)):
            return req or "an unlock (see conditions list)"
    return None


def name_maps(rows):
    """Learn name -> item ID from records that carry both, to place name-only records."""
    names = defaultdict(set)
    ranked = set()   # S13: names of items that come in quality ranks stay at family level
    for r in rows:
        for idk, nk, rk in (("inputItemID", "inputName", "inputRank"), ("outputItemID", "outputName", "outputRank")):
            if r.get(nk) and r.get(rk):
                ranked.add(r[nk].strip().lower())
            if r.get(idk) and r.get(nk):
                names[r[nk].strip().lower()].add(r[idk])
    return {k: next(iter(v)) for k, v in names.items() if len(v) == 1 and k not in ranked}


def key_of(r, names):
    """(method, input, output). Records whose item ID (rank) is unknown are kept at family
    level ("family:<name>") instead of being dropped, so no study goes unused."""
    if r.get("gearGroup"):
        g = r["gearGroup"]
        inp = f"gear:{g.get('expansion')}:{g.get('quality')}:{g.get('kind')}"
    else:
        inp = r.get("inputItemID") or names.get((r.get("inputName") or "").strip().lower())
        if not inp and r.get("inputName"):
            inp = "family:" + r["inputName"].strip()
    out = r.get("outputItemID") or names.get((r.get("outputName") or "").strip().lower())
    if not out and r.get("outputName"):
        out = "family:" + r["outputName"].strip()
    if not inp or not out or not r.get("method"):
        return None
    return (r["method"], str(inp), out if isinstance(out, str) else int(out))


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


OLD_EPOCH_WEIGHT = 0.25   # studies from before a rate change (or with no date) count at a quarter (S6)
UNLOCK_YES = ("unlock: yes", "unlocked", "with unlock", "has unlock", "proficient processor",
              "copper consumer", "tin-vestigator", "silver scrapper", "thorium thresher",
              "diamond unlock", "max knowledge", "max spec")
UNLOCK_NO = ("unlock: no", "no unlock", "not unlocked", "no specialization", "no-specialization",
             "zero-spec", "zero specialization", "0 points")


def expansion_range(text):
    t = (text or "").lower()
    if "midnight" in t:
        return (236000, 10**9)
    if "war within" in t or "khaz algar" in t:
        return (210000, 235999)
    if "dragon" in t:
        return (188000, 209999)
    return None


def load_rate_changes():
    """Single-method rate changes with a known expansion scope, from rate-changes.jsonl."""
    out = []
    path = os.path.join(ROOT, "research", "v3", "rate-changes.jsonl")
    if not os.path.exists(path):
        return out
    for line in open(path, encoding="utf-8"):
        if not line.strip():
            continue
        c = json.loads(line)
        rng = expansion_range(c.get("affects"))
        if c.get("method") in ("Prospect", "Mill", "Disenchant", "Smelt") and rng and c.get("date"):
            out.append((c["method"], rng, c["date"][:10]))
    return out


def study_date(r):
    for v in (r.get("dataDate"), (r.get("source") or {}).get("published")):
        if isinstance(v, str) and len(v) >= 10 and v[:4].isdigit() and v[4] == "-":
            return v[:10]
    return None


def epoch_weight(r, method, inp, changes):
    """1.0 for studies after the latest applicable rate change, OLD_EPOCH_WEIGHT otherwise."""
    if not inp.isdigit():
        return 1.0, None
    applicable = [d for m, (lo, hi), d in changes if m == method and lo <= int(inp) <= hi]
    if not applicable:
        return 1.0, None
    latest = max(applicable)
    d = study_date(r)
    if d and d >= latest:
        if not r.get("dataDate"):
            return 1.0, "dated by post date only, after " + latest
        return 1.0, None
    return OLD_EPOCH_WEIGHT, ("before " if d else "undated vs ") + latest


def unlock_state(r):
    t = " ".join(str(r.get(k) or "") for k in ("specialization", "notes", "stats")).lower()
    if any(x in t for x in UNLOCK_NO):
        return False
    if any(x in t for x in UNLOCK_YES):
        return True
    return None


def is_study_row(r):
    return r.get("type") == "drop" and r.get("sourceKind") not in REFERENCE_KINDS


def study_ref(r):
    """One recorded study: the rows sharing file + studyKey (a row without a studyKey stands alone)."""
    return (str(r.get("_file")), str(r.get("studyKey") or r.get("id")))


def source_key(r):
    src = r.get("originalSource") or (r.get("source") or {}).get("url")
    return normalize_url(src) if isinstance(src, str) and src else str(r.get("studyKey") or r.get("id"))


def row_numbers(r):
    return tuple(None if num(r.get(f)) is None else float(r[f]) for f in NUMBER_FIELDS)


def item_names(rows):
    """Item ID -> lower-case name, so a row that has only an ID compares equal to a copy with only a name."""
    out = {}
    for r in rows:
        for idk, nk in (("inputItemID", "inputName"), ("outputItemID", "outputName")):
            if r.get(idk) and r.get(nk):
                out.setdefault(str(r[idk]), r[nk].strip().lower())
    return out


def item_token(r, idk, nk, ids):
    """Copies often lose item IDs (S17), so compare by name and use the ID only without one."""
    name = (r.get(nk) or "").strip().lower()
    return name or (ids.get(str(r[idk]), str(r[idk])) if r.get(idk) else "")


def study_vector(study, ids):
    """Every number of one study, per input rank and output. Sorted, so row order does not matter."""
    entries = []
    for r in study:
        casts = num(r.get("casts"))
        entries.append((str(r.get("inputRank")), None if casts is None else float(casts),
                        item_token(r, "outputItemID", "outputName", ids), row_numbers(r)))
    return tuple(sorted(entries, key=repr))


def numbers_agree(a, b):
    """Two rows report the same result: they share a stated number and differ in none."""
    shared = [(x, y) for x, y in zip(a, b) if x is not None and y is not None]
    return bool(shared) and all(x == y for x, y in shared)


def rows_covered(copy, original, labelled):
    """Every row of `copy` that has numbers pairs with its own row of `original`."""
    left = list(original)
    for e in copy:
        if any(x is not None for x in e[3]):
            match = next((o for o in left if e[:2] == o[:2] and numbers_agree(e[3], o[3])
                          and (not labelled or e[2] == o[2])), None)
            if match is None:
                return False
            left.remove(match)
    return True


def partial_copy_of(copy, original):
    """True if `copy` repeats `original` without matching it exactly: some rows only, a field left
    null, or an output label missing or respelled. Needs 2+ non-zero rows. A copy of under half the
    original must also match its labels, so a chance match of a few numbers merges nothing."""
    if copy == original or sum(1 for e in copy if any(e[3])) < 2:
        return False
    return rows_covered(copy, original, labelled=len(copy) * 2 < len(original))


def batch_family(s):
    """Numbered batches of one write-up: same file, keys that differ only in their digits."""
    return (s[0], re.sub(r"\d+", "#", s[1]))


def output_totals(vector):
    totals = defaultdict(float)
    for rank, _, output, numbers in vector:
        totals[(rank, output)] += numbers[1] or 0
    return totals


def pooled_studies(members, vectors):
    """Studies in `members` (one source) that are the exact sum of a batch family, with 2+ non-zero
    totals: they repeat the batches, e.g. df-q21-b019 = the ten Reddit 10u5ao8 batches."""
    families = defaultdict(list)
    for s in members:
        families[batch_family(s)].append(s)
    out = {}
    for batches in families.values():
        casts, totals = defaultdict(float), defaultdict(float)
        for s in batches:
            for rank, n in {e[:2] for e in vectors[s]}:
                casts[rank] += n or 0
            for k, v in output_totals(vectors[s]).items():
                totals[k] += v
        for s in members:
            if (len(batches) > 1 and s not in batches and sum(1 for e in vectors[s] if e[3][1]) >= 2
                    and all(e[1] == casts[e[0]] for e in vectors[s])
                    and all(v == totals[k] for k, v in output_totals(vectors[s]).items())):
                out[s] = batches[0]
    return out


def study_vectors(rows):
    """study_ref -> numeric vector used as its identity; the partial copies found, as (copy, original)
    pairs; and the pooled studies, as {pool: first batch}. A partial copy takes the vector of the study
    it was copied from, so both count once. Numbered batches stay apart even with equal numbers: small
    batches can match by chance (Reddit 10u5ao8 batches 1 and 6 both report 7 and 13)."""
    ids = item_names(rows)
    studies = defaultdict(list)
    for r in rows:
        if is_study_row(r):
            studies[study_ref(r)].append(r)
    vectors = {s: study_vector(rs, ids) for s, rs in studies.items()}
    by_source = defaultdict(list)
    for s in sorted(studies):
        by_source[source_key(studies[s][0])].append(s)
    canonical, partial, pooled = dict(vectors), [], {}
    for members in by_source.values():
        members.sort(key=lambda s: -len(vectors[s]))  # stable: ties stay in study_ref order
        pooled.update(pooled_studies(members, vectors))
        for i, s in enumerate(members):
            earlier = members[:i]
            original = next((o for o in earlier if canonical[o] == vectors[o] and batch_family(o) != batch_family(s)
                             and partial_copy_of(vectors[s], vectors[o])), None)
            if original:
                canonical[s] = vectors[original]
                partial.append((s, original))
            elif any(vectors[o] == vectors[s] and batch_family(o) == batch_family(s) for o in earlier):
                canonical[s] = vectors[s] + (("batch", None, s[1], ()),)
    return canonical, partial, pooled


def study_identity(r, vectors):
    """One independent cohort counts once, however many files record it (S7).
    An explicit cohortKey wins. Otherwise a study is its normalized source, input rank, casts and the
    numbers of ALL its rows: same fingerprint = copy; same source with other numbers = another cohort,
    even if a single row (a zero-hit material, say) happens to match."""
    if r.get("cohortKey"):
        return ("cohort", r["cohortKey"])
    return (source_key(r), r.get("inputRank"), num(r.get("casts")), vectors[study_ref(r)])


def group_specificity(key):
    return sum(not str(part).startswith("family:") for part in key[1:])


def same_output(r, o, ids):
    """Same material, or (for a relabeled copy) the same non-zero numbers under another label."""
    return (item_token(r, "outputItemID", "outputName", ids) == item_token(o, "outputItemID", "outputName", ids)
            or any(row_numbers(r)))


def misplaced_copies(rows, names, vectors, pooled):
    """id() of rows to leave out of every group: pooled studies, and rows of a copy that lost item IDs
    so they land in a vaguer estimate group than the original, where the per-group dedupe never sees
    both (S17). A row stating an unlock its original does not state stays, as in the unlock skip."""
    ids = item_names(rows)
    twins = defaultdict(list)
    out = set()
    for r in rows:
        k = key_of(r, names) if is_study_row(r) else None
        if k and study_ref(r) in pooled:
            out.add(id(r))
        elif k:
            twins[(study_identity(r, vectors), item_token(r, "inputItemID", "inputName", ids))].append((r, k))
    for pairs in twins.values():
        for r, k in pairs:
            if any(group_specificity(ok) > group_specificity(k) and study_ref(o) != study_ref(r)
                   and numbers_agree(row_numbers(r), row_numbers(o)) and same_output(r, o, ids)
                   and (unlock_state(o) is True or unlock_state(r) is not True) for o, ok in pairs):
                out.add(id(r))
    return out


def build(rows):
    names = name_maps(rows)
    vectors, _, pooled = study_vectors(rows)
    copies = misplaced_copies(rows, names, vectors, pooled)
    conds = load_conditions(rows)
    changes = load_rate_changes()
    families = defaultdict(set)   # input name -> item IDs, for family-level unlock checks
    for r in rows:
        if r.get("inputName") and r.get("inputItemID"):
            families[r["inputName"].strip().lower()].add(str(r["inputItemID"]))
    groups = defaultdict(lambda: {"studies": [], "refs": [], "lo": None, "hi": None})
    unplaced = 0
    for r in rows:
        if r.get("type") != "drop":
            continue
        k = key_of(r, names)
        if not k:
            unplaced += 1
            continue
        if id(r) in copies:
            continue
        g = groups[k]
        lo, hi = num(r.get("minSeen")), num(r.get("maxSeen"))
        if lo is not None and lo >= 1:
            g["lo"] = lo if g["lo"] is None else min(g["lo"], lo)
        if hi is not None and hi >= 1:
            g["hi"] = hi if g["hi"] is None else max(g["hi"], hi)
        if r.get("sourceKind") not in REFERENCE_KINDS:
            if lo is not None and lo >= 1:
                g["slo"] = lo if g.get("slo") is None else min(g["slo"], lo)
            if hi is not None and hi >= 1:
                g["shi"] = hi if g.get("shi") is None else max(g["shi"], hi)
        (g["refs"] if r.get("sourceKind") in REFERENCE_KINDS else g["studies"]).append(r)

    results = []
    for (method, inp, out), g in sorted(groups.items(), key=lambda kv: (kv[0][0], kv[0][1], str(kv[0][2]))):
        import math
        req = condition_for(conds, method, inp, out, families)
        observed = [g.get("slo"), g.get("shi")] if g.get("slo") is not None or g.get("shi") is not None else None
        has_ref_range = g["lo"] is not None or g["hi"] is not None
        lo = int(g["lo"] or 1)
        hi = int(max(g["hi"] or lo, lo))
        mid = (lo + hi) / 2
        basis = []
        range_estimated = not (observed or has_ref_range)
        # ---- starting guess from reference values (S9: provisional prior, never counted as casts)
        ref_p = [x for x in (chance_from_percent(r) for r in g["refs"]) if x is not None and x <= 1]
        ref_e = [x for x in (per_cast_average(r) for r in g["refs"]) if x is not None]
        prior_p = sum(ref_p) / len(ref_p) if ref_p else None
        prior_e = sum(ref_e) / len(ref_e) if ref_e else None
        # ---- add studies (S6 epochs and unlocks, S7 dedupe)
        casts_p = drops = 0.0
        casts_e = total = 0.0
        seen, skipped_ids, old_epoch, post_dated = set(), set(), None, None
        for r in g["studies"]:
            ident = study_identity(r, vectors)
            if ident in seen:
                continue
            if req is not None and unlock_state(r) is not True:
                # Unknown/locked studies can't measure an unlock-only drop. Don't mark the study as
                # counted: another copy of the same study may state the unlock and must still count.
                skipped_ids.add(ident)
                continue
            seen.add(ident)
            w, why = epoch_weight(r, method, inp, changes)
            if why and w < 1:
                old_epoch = why
            elif why:
                post_dated = why
            n = num(r.get("casts"))
            hits = num(r.get("castsWithDrop"))
            pct = chance_from_percent(r)
            tot = num(r.get("totalQuantity"))
            avg = per_cast_average(r)
            nn = (n if n else SMALL_STUDY_CASTS) * w
            if hits is not None and n:
                casts_p += n * w; drops += hits * w
            elif pct is not None and pct <= 1:
                casts_p += nn; drops += pct * nn
            if tot is not None and n:
                casts_e += n * w; total += tot * w
            elif avg is not None:
                casts_e += nn; total += avg * nn
        if post_dated:
            basis.append(post_dated + " (collection date unknown)")
        if old_epoch:
            basis.append(f"older-period data counted at {int(OLD_EPOCH_WEIGHT*100)}% ({old_epoch} rate change)")
        skipped_unlock = len(skipped_ids - seen)
        if skipped_unlock:
            basis.append(f"{skipped_unlock} studies left out: unlock status not stated")
        # ---- measured fields (studies + starting guess)
        p = e = None
        chance_measured = average_measured = False
        # Studies that measured the average but not the chance are more informative than a
        # 20-cast starting guess for the chance, so the chance is then estimated from them.
        if casts_p == 0 and casts_e > 0:
            prior_p = None
        if casts_p > 0 or prior_p is not None:
            w = PRIOR_CASTS if prior_p is not None else 0
            p = (drops + (prior_p or 0) * w) / (casts_p + w)
            chance_measured = casts_p > 0
        if casts_e > 0 or prior_e is not None:
            w = PRIOR_CASTS if prior_e is not None else 0
            e = (total + (prior_e or 0) * w) / (casts_e + w)
            average_measured = casts_e > 0
        if e is not None and e > hi:
            hi = math.ceil(e); mid = (lo + hi) / 2; range_estimated = True
            basis.append("estimated range widened to fit the average (observed range kept separately)")
        # ---- derived fields (S5 as agreed: allowed, labelled provisional, confidence halved)
        chance_derived = average_derived = False
        if p is None and e is not None:
            p = min(1.0, e / mid); chance_derived = True
            basis.append("chance estimated from average / middle of range")
        if e is None and p is not None:
            e = p * mid; average_derived = True
            basis.append("average estimated from chance x middle of range (provisional valuation)")
        if p is None:
            continue
        conflict = False
        if p and e > p * hi + 1e-9:
            hi = math.ceil(e / p); conflict = True; range_estimated = True
            basis.append("chance and average disagree (conflict flagged); estimated range widened, confidence halved")
        # ---- confidence (S8: only casts that measured the chance)
        guess = GUESS_CONFIDENCE_CASTS if (prior_p is not None or prior_e is not None) else 0
        if chance_derived:
            conf = confidence(min(p, 1.0), casts_e + guess) // 2
        else:
            conf = confidence(min(p, 1.0), casts_p + guess)
        if casts_p == 0 and casts_e == 0:
            conf = min(GUESS_ONLY_MAX_CONFIDENCE, conf)
            basis.insert(0, "starting guess only (reference values)")
        else:
            basis.insert(0, f"{round(max(casts_p, casts_e)):,} effective study casts"
                         + (" + starting guess" if guess else ""))
        if conflict:
            conf //= 2
        # uncertainty for recommendation-confidence simulations (S10)
        n_p = (casts_e if chance_derived else casts_p) + guess
        sim_n = max(n_p, 1.0) / (2 if chance_derived else 1)
        avg_sd = (e * 0.5) if average_derived else math.sqrt(max(e, 1e-6) / max(casts_e + (PRIOR_CASTS if prior_e is not None else 0), 1))
        results.append({
            "method": method, "input": inp, "outputItemID": out,
            "conditional": req is not None, "requires": req,
            "chance": round(min(p, 1.0), 4), "average": round(e, 4), "range": [lo, hi],
            "rangeSource": ("estimated" if range_estimated and not (observed or has_ref_range) or "widened" in "; ".join(basis) or conflict
                            else "observed" if observed else "reference" if has_ref_range else "estimated"),
            "observedRange": observed, "conflict": conflict,
            "confidence": conf,
            "chanceSource": "estimated" if chance_derived else ("measured" if chance_measured else "starting guess"),
            "averageSource": "estimated" if average_derived else ("measured" if average_measured else "starting guess"),
            "provisionalValuation": average_derived,
            "simulation": {"chanceBeta": [round(min(p, 1.0) * sim_n + 0.5, 3), round((1 - min(p, 1.0)) * sim_n + 0.5, 3)],
                           "averageSD": round(avg_sd, 4)},
            "studyCasts": round(max(casts_p, casts_e), 1),
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
