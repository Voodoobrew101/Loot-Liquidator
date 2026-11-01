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
  * Units (M06, S16): every estimate is per cast of the group's unit (`inputsPerCast`; prospecting 5,
    mechanics G1; otherwise the smallest batch its rows state). Rows of another batch size are
    converted per input for the average; their per-cast chance is not convertible and is left out.
    Casts that are not counted operations in that unit (castsBasis countedFromInputs,
    nominalEquivalent or derived, casts counted here from inputsProcessed, converted batches) count
    fully toward the average but at EQUIVALENT_CAST_WEIGHT toward the chance (see row_use).
  * Confidence comes from a beta distribution of those counts (the "weighted count with a
    starting guess" model, also called beta-binomial / empirical Bayes).

Agreed with ChatGPT in research/v3/strategy.md S5-S10 (2026-10-30).
Nothing here is tuned to make numbers look better. Change the constants below, not the data.

Usage, from the repository root:
  python3 research/v3/tools/build_estimates.py
Writes research/v3/output/estimates.json and research/v3/output/summary.md
"""
import calendar
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
# M06 (S16, PLAN section 3 rule 2). A cast count that is not a count of completed operations in the
# group's unit says how many inputs went in, not how many casts were made: Resourcefulness refunds
# (mechanics M9, M10, W2) may or may not have been processed again, so the true count is blurred by up
# to the refund rate (about 18% in Cardinalai's 715 of 4,000 ore). The average per cast stays
# bounded, so these casts count fully there; in the chance (its estimate and its confidence) they count
# at this weight. A heuristic, like S5's halved confidence for estimated values, not a calibrated one.
EQUIVALENT_CAST_WEIGHT = 0.5
EQUIVALENT_BASES = {"countedFromInputs", "nominalEquivalent", "derived"}
NOMINAL_UNIT = 5        # nominalEquivalent casts are the old pipeline's five-ore/five-herb operations
PROSPECT_UNIT = 5       # mechanics G1: every expansion prospects 5 ore per cast (mass prospecting = 4 casts)


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
               "cohortKey",
               # M03 schema extension (research/v3/migration/SCHEMA-EXTENSION.md)
               "castsBasis", "inputsProcessed", "inputsPurchased", "inputsRefunded", "unlockState",
               "dataDateText", "observedOn"}


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
    """A percentage is a per-cast chance only when the record says so (M08). An unstated meaning is not
    assumed: the evidence format asks for `percentMeaning` whenever a percentage is copied."""
    p = num(r.get("percentShown"))
    if p is None or r.get("percentMeaning") != "perCast":
        return None
    return p / 100  # percentShown is always written as a percentage (18.3 means 18.3%)


def row_unit(r):
    """Inputs behind one of this row's casts: 5 for nominalEquivalent casts (whatever inputsPerCast says;
    58 imported mass-milling rows say 20 while their casts are five-input equivalents), else inputsPerCast."""
    if r.get("castsBasis") == "nominalEquivalent":
        return NOMINAL_UNIT
    b = num(r.get("inputsPerCast"))
    return b if b and b > 0 else None


def group_unit(method, rows):
    """Inputs per cast of one estimate group. Prospecting: 5 (G1). Otherwise the smallest batch any of its
    rows (studies or reference values) states, since mass casts are multiples of the single cast (20 herbs =
    4 five-herb mills; Midnight mills 10, M6). None if no row states one: rows are then used as stated."""
    if method == "Prospect":
        return PROSPECT_UNIT
    units = [u for u in (num(r.get("inputsPerCast")) for r in rows) if u and u > 0]  # stated batches, not nominal units
    return min(units) if units else None


def same_unit(r, unit):
    own = row_unit(r)
    return not (own and unit) or own == unit


def unit_average(r, unit):
    """averageShown per cast of the group's unit (per_cast_average with the conversion per input)."""
    a, per = num(r.get("averageShown")), r.get("averagePer")
    if a is None:
        return None
    own = row_unit(r)
    if per == "cast":
        return a * unit / own if own and unit else a
    if per in ("input", "1000 inputs") and (unit or own):
        return a * (unit or own) / (1000 if per == "1000 inputs" else 1)
    return None


def row_use(r, unit):
    """What one drop row adds to its group, in casts of the group's unit (M06).
    Returns {"chance": (casts, hits) or None, "average": (casts, total) or None, "weight": 1 or
    EQUIVALENT_CAST_WEIGHT, "reasons": [...]}. `weight` applies to the chance only. Reasons are
    machine-readable codes for what was converted, weighted down or left out.
      * casts stated: converted by row_unit/unit; full weight only when castsBasis is reported (or absent)
        and no conversion was needed.
      * no casts but inputsProcessed: casts = inputsProcessed / unit (= / inputsPerCast when the row's batch
        is the unit). Refunds (inputsRefunded) are never added or subtracted: sources do not say whether
        refunded inputs were processed again. inputsPurchased alone is not a count of inputs processed.
      * a chance (castsWithDrop, percent per cast) from a cast of another batch size is not convertible:
        P(at least one) is not linear in inputs. Averages are, per input."""
    reasons = []
    own = row_unit(r)
    scale = own / unit if own and unit else 1.0
    n = num(r.get("casts"))
    equivalent = r.get("castsBasis") in EQUIVALENT_BASES
    if scale != 1:
        equivalent = True
        reasons.append(f"converted:{own:g}->{unit:g}")
    if n:
        n_u = n * scale
        if r.get("castsBasis") in EQUIVALENT_BASES:
            reasons.append("castsBasis:" + r["castsBasis"])
    else:
        n_u = None
        ip = num(r.get("inputsProcessed"))
        if ip and unit:
            n_u, equivalent = ip / unit, True
            reasons.append("castsFromInputs")
        elif ip:
            reasons.append("inputsProcessedNoBatch")
    weight = EQUIVALENT_CAST_WEIGHT if equivalent else 1.0
    chance = average = None
    hits, pct = num(r.get("castsWithDrop")), chance_from_percent(r)
    if hits is not None or (pct is not None and pct <= 1):
        if scale != 1:
            reasons.append(f"chanceNotConvertible:{own:g}->{unit:g}")
        elif hits is not None and n_u:
            chance = (n_u, hits)
        elif pct is not None and pct <= 1:
            nn = n_u or SMALL_STUDY_CASTS
            chance = (nn, pct * nn)
        else:
            reasons.append("hitsWithoutCasts")
    tot = num(r.get("totalQuantity"))
    a, per = num(r.get("averageShown")), r.get("averagePer")
    avg = unit_average(r, unit)
    if tot is not None and n_u:
        average = (n_u, tot)
    elif avg is not None:
        nn = n_u or SMALL_STUDY_CASTS
        average = (nn, avg * nn)
    if chance is None and average is None and not any(x.startswith("chanceNotConvertible") for x in reasons):
        if tot is not None:
            reasons.append("totalWithoutCasts" if not num(r.get("inputsProcessed")) else "totalNoBatch")
        elif a is not None:
            reasons.append(f"averageNoBatch:{per}")
        elif num(r.get("percentShown")) is not None:
            reasons.append(f"percent:{r.get('percentMeaning')}")
        elif hits is None:
            reasons.append("noNumbers")
    return {"chance": chance, "average": average, "weight": weight, "reasons": reasons}


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


ISO_DATE = re.compile(r"^(\d{4})-(0[1-9]|1[0-2])(?:-(\d{2}))?(?=$|/|T)")


def iso_date(v):
    """'YYYY-MM-DD' or 'YYYY-MM' from the start of an ISO date, a range ('2026-04-02/2026-04-10' gives its
    first day) or a timestamp; None for anything else. Free text is never parsed (M08): '2026-04 live
    realms' is prose and says nothing about the day."""
    m = ISO_DATE.match(v) if isinstance(v, str) else None
    if not m:
        return None
    year, month, day = int(m.group(1)), int(m.group(2)), m.group(3)
    if day is None:
        return f"{year:04d}-{month:02d}"
    if not 1 <= int(day) <= calendar.monthrange(year, month)[1]:
        return None
    return f"{year:04d}-{month:02d}-{day}"


def dated_by(r):
    """(date, field) of the first usable date: dataDate, then observedOn (both collection dates), then the
    post date `source.published`. (None, None) when none is ISO."""
    for field, v in (("dataDate", r.get("dataDate")), ("observedOn", r.get("observedOn")),
                     ("published", (r.get("source") or {}).get("published"))):
        d = iso_date(v)
        if d:
            return d, field
    return None, None


def study_date(r):
    """Collection date (dataDate, then observedOn), else the post date; ISO only."""
    return dated_by(r)[0]


def epoch_side(d, latest):
    """'after', 'before' or None (cannot tell) for a date against a rate-change day. A month-only date is
    placed only if the whole month is on one side of the change."""
    if len(d) == 10:
        return "after" if d >= latest else "before"
    if d + "-01" >= latest:
        return "after"
    if d + "-31" < latest:
        return "before"
    return None


def epoch_weight(r, method, inp, changes):
    """1.0 for studies after the latest applicable rate change, OLD_EPOCH_WEIGHT otherwise."""
    if not inp.isdigit():
        return 1.0, None
    applicable = [d for m, (lo, hi), d in changes if m == method and lo <= int(inp) <= hi]
    if not applicable:
        return 1.0, None
    latest = max(applicable)
    d, field = dated_by(r)
    side = epoch_side(d, latest) if d else None
    if side == "after":
        if field == "published":
            return 1.0, "dated by post date only, after " + latest
        return 1.0, None
    return OLD_EPOCH_WEIGHT, ("before " if side == "before" else "undated vs ") + latest


def unlock_state(r):
    """True / False / None (not stated). The structured `unlockState` decides when the record has the field,
    including an explicit null, which means the source does not say (M08). Only a record without the field
    (every agent record today) falls back to phrases in specialization, notes and stats: fragile, since any
    note that mentions 'max knowledge' reads as unlocked."""
    if "unlockState" in r and (r["unlockState"] is None or isinstance(r["unlockState"], bool)):
        return r["unlockState"]
    return unlock_state_from_text(r)


def unlock_state_from_text(r):
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


# M08: why a record adds nothing to any estimate. One code per record; `detail` names the group or the
# row_use reasons. Closed vocabulary, pinned by tests.
USE_REASONS = (
    ("totalWithoutCasts", "totalWithoutCasts"), ("totalNoBatch", "totalNoBatch"), ("noNumbers", "noNumbers"),
    ("hitsWithoutCasts", "hitsWithoutCasts"), ("averageNoBatch", "averageNoBatch"),
    ("chanceNotConvertible", "chanceNotConvertible"), ("percent:perCast", "percentOutOfRange"),
    ("percent:", "percentNotPerCast"))
NON_DROP_TYPES = ("exchange", "token", "recipe", "noDisenchant", "rateChange", "searched")
REASON_CODES = frozenset(
    {code for _, code in USE_REASONS}
    | {"condition:incomplete", "conditional:unlockFalse", "conditional:unlockUnstated", "copy:pooledStudy",
       "copy:vaguerGroup", "duplicateRowInStudy", "duplicateStudy", "reference:noUsableValue",
       "reference:otherUnit", "reference:priorSuperseded", "type:missing", "type:unknown",
       "unplaced:noInput", "unplaced:noMethod", "unplaced:noOutput"}
    | {"type:" + t for t in NON_DROP_TYPES})


def unused_code(reasons):
    """The first row_use reason that explains why a row added nothing, as a closed-vocabulary code."""
    for prefix, code in USE_REASONS:
        if any(x.startswith(prefix) for x in reasons):
            return code
    return "noNumbers"


def unplaced_code(r, names):
    if not r.get("method"):
        return "unplaced:noMethod"
    has_input = r.get("gearGroup") or r.get("inputItemID") or r.get("inputName")
    return "unplaced:noInput" if not has_input else "unplaced:noOutput"


def non_drop_usage(r):
    """Usage of a record that is not a drop row. The estimator builds drop estimates only; condition
    records are read to tag conditional outputs (load_conditions)."""
    t = r.get("type")
    if t == "condition":
        if r.get("method") and r.get("outputItemID"):
            return {"used": True, "roles": ["condition"]}
        return {"used": False, "reason": "condition:incomplete"}
    if t in NON_DROP_TYPES:
        return {"used": False, "reason": "type:" + t}
    return {"used": False, "reason": "type:missing" if t is None else "type:unknown"}


def build(rows):
    """(estimates, number of unplaced drop rows). See analyze() for the per-record usage."""
    results, unplaced, _ = analyze(rows)
    return results, unplaced


def analyze(rows):
    """Build the estimates and say what became of every record. Returns (estimates, unplaced, usage) where
    usage maps id(row) to {"used": bool, "roles": [...], "reason": code, "detail": ..., "range": bool}.
    Every row has an entry: used (roles chance, average, prior, range, condition) or a reason code."""
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
    usage = {}
    for r in rows:
        if r.get("type") != "drop":
            usage[id(r)] = non_drop_usage(r)
            continue
        k = key_of(r, names)
        if not k:
            unplaced += 1
            usage[id(r)] = {"used": False, "reason": unplaced_code(r, names)}
            continue
        if id(r) in copies:
            usage[id(r)] = {"used": False, "reason": "copy:pooledStudy" if study_ref(r) in pooled else "copy:vaguerGroup"}
            continue
        g = groups[k]
        lo, hi = num(r.get("minSeen")), num(r.get("maxSeen"))
        widens = (lo is not None and lo >= 1) or (hi is not None and hi >= 1)
        if lo is not None and lo >= 1:
            g["lo"] = lo if g["lo"] is None else min(g["lo"], lo)
        if hi is not None and hi >= 1:
            g["hi"] = hi if g["hi"] is None else max(g["hi"], hi)
        if r.get("sourceKind") not in REFERENCE_KINDS:
            if lo is not None and lo >= 1:
                g["slo"] = lo if g.get("slo") is None else min(g["slo"], lo)
            if hi is not None and hi >= 1:
                g["shi"] = hi if g.get("shi") is None else max(g["shi"], hi)
        usage[id(r)] = {"used": False, "reason": "pending", "range": widens, "group": k}
        (g["refs"] if r.get("sourceKind") in REFERENCE_KINDS else g["studies"]).append(r)

    def settle(r, roles=(), reason=None, detail=None):
        """Record the outcome of a placed row. Used means it added casts, hits, a total, an average or a
        prior; widening a min-max range alone does not count, so such a row is unused and flagged `range`."""
        u = usage[id(r)]
        u.pop("group", None)
        if roles:
            u.update(used=True, roles=sorted(roles), reason=None)
            u.pop("range", None)
        else:
            u.update(used=False, reason=reason)
            if detail:
                u["detail"] = detail
            if not u.get("range"):
                u.pop("range", None)

    results = []
    for (method, inp, out), g in sorted(groups.items(), key=lambda kv: (kv[0][0], kv[0][1], str(kv[0][2]))):
        import math
        outcome = {}   # id(row) -> (roles, reason, detail) for this group; committed only if it yields an estimate
        req = condition_for(conds, method, inp, out, families)
        observed = [g.get("slo"), g.get("shi")] if g.get("slo") is not None or g.get("shi") is not None else None
        has_ref_range = g["lo"] is not None or g["hi"] is not None
        lo = int(g["lo"] or 1)
        hi = int(max(g["hi"] or lo, lo))
        mid = (lo + hi) / 2
        basis = []
        range_estimated = not (observed or has_ref_range)
        unit = group_unit(method, g["studies"] + g["refs"])
        # ---- starting guess from reference values (S9: provisional prior, never counted as casts)
        ref_p_rows = [(r, x) for r in g["refs"] if same_unit(r, unit) for x in [chance_from_percent(r)]
                      if x is not None and x <= 1]
        ref_e_rows = [(r, x) for r in g["refs"] for x in [unit_average(r, unit)] if x is not None]
        ref_p = [x for _, x in ref_p_rows]
        ref_e = [x for _, x in ref_e_rows]
        prior_p = sum(ref_p) / len(ref_p) if ref_p else None
        prior_e = sum(ref_e) / len(ref_e) if ref_e else None
        # ---- add studies (S6 epochs and unlocks, S7 dedupe)
        casts_p = drops = 0.0
        casts_e = total = 0.0
        casts_e_chance = 0.0       # casts_e as the chance counts them (M06 weights), for a chance derived from the average
        equivalent_casts, converted, chance_dropped = 0.0, False, 0
        seen, skipped_ids, old_epoch, post_dated = set(), set(), None, None
        counted_ref, skipped_rows = {}, []
        for r in g["studies"]:
            ident = study_identity(r, vectors)
            if ident in seen:
                outcome[id(r)] = (set(), "duplicateRowInStudy" if counted_ref[ident] == study_ref(r) else "duplicateStudy", None)
                continue
            if req is not None and unlock_state(r) is not True:
                # Unknown/locked studies can't measure an unlock-only drop. Don't mark the study as
                # counted: another copy of the same study may state the unlock and must still count.
                skipped_ids.add(ident)
                skipped_rows.append((r, ident))
                continue
            seen.add(ident)
            counted_ref[ident] = study_ref(r)
            w, why = epoch_weight(r, method, inp, changes)
            if why and w < 1:
                old_epoch = why
            elif why:
                post_dated = why
            use = row_use(r, unit)
            k = use["weight"]
            roles = set()
            if use["chance"]:
                n, hits = use["chance"]
                casts_p += n * w * k; drops += hits * w * k
                roles.add("chance")
            if use["average"]:
                n, tot = use["average"]
                casts_e += n * w; total += tot * w; casts_e_chance += n * w * k
                if k < 1:
                    equivalent_casts += n * w
                roles.add("average")
            outcome[id(r)] = (roles, None if roles else unused_code(use["reasons"]), ",".join(use["reasons"]) or None)
            converted = converted or any(x.startswith("converted") for x in use["reasons"])
            chance_dropped += any(x.startswith("chanceNotConvertible") for x in use["reasons"])
        for r, ident in skipped_rows:
            if ident in seen:   # another copy of this cohort states the unlock and was counted
                outcome[id(r)] = (set(), "duplicateStudy", None)
            else:
                state = unlock_state(r)
                outcome[id(r)] = (set(), "conditional:unlockFalse" if state is False else "conditional:unlockUnstated", req)
        if post_dated:
            basis.append(post_dated + " (collection date unknown)")
        if equivalent_casts:
            basis.append(f"{round(equivalent_casts):,} casts counted from inputs or equivalents "
                         f"(full weight in the average, {int(EQUIVALENT_CAST_WEIGHT * 100)}% in the chance)")
        if converted:
            basis.append(f"other batch sizes converted to {unit:g}-input casts")
        if chance_dropped:
            basis.append(f"{chance_dropped} chance values from other batch sizes left out (not convertible)")
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
        # reference rows: used when their value reaches a prior that survives
        for r in g["refs"]:
            roles = set()
            if prior_p is not None and any(r is x for x, _ in ref_p_rows):
                roles.add("prior")
            if any(r is x for x, _ in ref_e_rows):
                roles.add("prior")
            if roles:
                outcome[id(r)] = (roles, None, None)
            elif any(r is x for x, _ in ref_p_rows):
                outcome[id(r)] = (set(), "reference:priorSuperseded", "studies measured the average only")
            elif chance_from_percent(r) is not None and not same_unit(r, unit):
                outcome[id(r)] = (set(), "reference:otherUnit", f"{row_unit(r):g} vs {unit:g} inputs per cast")
            else:
                outcome[id(r)] = (set(), "reference:noUsableValue", None)

        def commit():
            # A group with no estimate has no row that added a number (a number gives a chance or an
            # average, and either gives an estimate), so every row there already carries a reason.
            for row in g["refs"] + g["studies"]:
                roles, reason, detail = outcome[id(row)]
                if roles and usage[id(row)].get("range"):
                    roles = roles | {"range"}
                settle(row, roles, reason, detail)
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
        commit()
        if p is None:
            continue
        conflict = False
        if p and e > p * hi + 1e-9:
            hi = math.ceil(e / p); conflict = True; range_estimated = True
            basis.append("chance and average disagree (conflict flagged); estimated range widened, confidence halved")
        # ---- confidence (S8: only casts that measured the chance)
        guess = GUESS_CONFIDENCE_CASTS if (prior_p is not None or prior_e is not None) else 0
        if chance_derived:
            conf = confidence(min(p, 1.0), casts_e_chance + guess) // 2
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
        n_p = (casts_e_chance if chance_derived else casts_p) + guess
        sim_n = max(n_p, 1.0) / (2 if chance_derived else 1)
        avg_sd = (e * 0.5) if average_derived else math.sqrt(max(e, 1e-6) / max(casts_e + (PRIOR_CASTS if prior_e is not None else 0), 1))
        results.append({
            "method": method, "input": inp, "outputItemID": out, "inputsPerCast": unit,
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
    return results, unplaced, usage


def unused_report(rows, usage):
    """output/unused.json: every effective record is either used by an estimate (roles) or listed here with
    one reason code. `range: true` marks an unused row that still widened a min-max range: a reference row (its
    range is the reference range, by design) or a study row left out for another reason (the estimator has
    always collected ranges before dedupe, so a duplicate or a left-out study can widen the observed range)."""
    unused, by_reason, by_role = [], defaultdict(int), defaultdict(int)
    for r in rows:
        u = usage[id(r)]
        if u["used"]:
            for role in u["roles"]:
                by_role[role] += 1
            continue
        by_reason[u["reason"]] += 1
        entry = {"id": r.get("id"), "file": r.get("_file"), "type": r.get("type"), "reason": u["reason"]}
        for key in ("detail", "range"):
            if u.get(key):
                entry[key] = u[key]
        unused.append(entry)
    unused.sort(key=lambda e: (e["file"] or "", str(e["id"]), e["reason"]))
    return {"records": len(rows), "used": len(rows) - len(unused), "unused": len(unused),
            "unusedByReason": dict(sorted(by_reason.items())), "usedByRole": dict(sorted(by_role.items())),
            "unusedRecords": unused}


def summary(results, unplaced, total_records, unused=None):
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
    if unused:
        lines += [f"{unused['used']:,} of {unused['records']:,} records feed an estimate; the other {unused['unused']:,} each "
                  "have a reason in `unused.json`:", "", "| Reason | Records |", "| --- | --- |"]
        lines += [f"| {k} | {v} |" for k, v in unused["unusedByReason"].items()] + [""]
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
    results, unplaced, usage = analyze(rows)
    unused = unused_report(rows, usage)
    os.makedirs(OUT, exist_ok=True)
    with open(os.path.join(OUT, "estimates.json"), "w", encoding="utf-8", newline="\n") as fh:
        json.dump({"withinTarget": WITHIN, "priorCasts": PRIOR_CASTS, "estimates": results}, fh, indent=1)
    with open(os.path.join(OUT, "unused.json"), "w", encoding="utf-8", newline="\n") as fh:
        json.dump(unused, fh, indent=1)
    with open(os.path.join(OUT, "summary.md"), "w", encoding="utf-8", newline="\n") as fh:
        fh.write(summary(results, unplaced, len(rows), unused))
    print(f"{len(rows)} records -> {len(results)} estimates ({unplaced} unplaced); "
          f"{unused['used']} records used, {unused['unused']} unused with a reason (output/unused.json)")


if __name__ == "__main__":
    main()
