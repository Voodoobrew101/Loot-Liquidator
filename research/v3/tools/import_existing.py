#!/usr/bin/env python3
"""Convert records the project already has into the research v3 evidence format.

Deterministic: running it again on the same files gives the same output. It never
invents a value. Every number comes from an existing record; the only arithmetic is
the simple kind the v3 rules allow (for example 5,000 ore / 5 ore per prospect =
1,000 casts), and each such step is written into the record's `derivations` (and, for
the rows that existed before M03, into `notes` as before).

Inputs (all already in this branch):
  1. research/evidence/observations/*.jsonl   old study records (main schema)
  2. research/proposed/itemdb.lua             the research ItemDB rows
  3. GameData.lua                             the old addon database (disenchant,
                                              smelting recipes, gear tokens, and the
                                              gd.mill / gd.prospect / gd.tsmRetail tables)
  4. research/v3/evidence/midnight/2026-10-31-midnight-refining-shattering-decks.jsonl
                                              ten agent records written without `type`
                                              (read only; mapped records `replace` them)
  5. (MIG-004) research/evidence/observations/*.json, research/evidence/v2/*.json,
     research/evidence/leads/*.json, the worker submissions and ledger CSVs listed in
     research/v3/migration/manifest/inventory.jsonl, and the three other-schema JSONL files
     M03.1 left (legacy milling, recipe metadata, cohort reconciliation). Section 4 below:
     a claim is imported only when its source is new to v3 and a mapper copies its numbers.

Output: research/v3/evidence/imported/*.jsonl  (overwritten on each run; a MIG-004 family
with no imported rows writes no file)

Migration session MIG-003 (M03.0, M03.1, M03.5) added, on every row it writes:
  castsBasis      reported | countedFromInputs | nominalEquivalent (null without casts)
  inputsProcessed, inputsPurchased, inputsRefunded   copied from the old raw fields
  dataDateText    the old free-text period when it is not an ISO date (dataDate is then null)
  observedOn      the old record's reportedObservationDate (the old importer put it in source.published)
  rawOutputName   the source's own output label (name-only rows; null on rows with an item ID)
  derivations     [{field, formula, assumption}] for every value this script computes
  migratedFrom    {path, sha256, recordRef} provenance
IDs import-study-00001..00652 keep their old numbers (corrections.jsonl uses them); rows
first written in MIG-003 are numbered after them. cohortKey is never set here (see
research/v3/migration/HANDOFF.md).

Usage, from the repository root:
  python3 research/v3/tools/import_existing.py [--report FILE]
--report writes a JSON account of every skipped record, mapping and comparison.
"""
import argparse
import glob
import hashlib
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from source_keys import normalize_url  # noqa: E402

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
OUT = os.path.join(ROOT, "research", "v3", "evidence", "imported")
TODAY = "2026-10-30"      # recordedOn of the rows written before MIG-003 (kept)
M03_DATE = "2026-10-31"   # recordedOn of rows first written in MIG-003
AGENT = "import"
ISO_DATE = re.compile(r"^\d{4}-\d{2}-\d{2}(/\d{4}-\d{2}-\d{2})?$")

# ---------------------------------------------------------------- Lua literals
def parse_lua(s, i=0):
    """Parse one Lua literal (table, string, number, boolean, nil) starting at s[i]."""
    n = len(s)

    def ws(i):
        while i < n and s[i] in " \n\t\r,;":
            i += 1
        return i

    def val(i):
        i = ws(i)
        c = s[i]
        if c == "{":
            i += 1
            arr, d = [], {}
            while True:
                i = ws(i)
                if s[i] == "}":
                    if d and arr:
                        return {**{k + 1: v for k, v in enumerate(arr)}, **d}, i + 1
                    return (d if d else arr), i + 1
                if s[i] == "[":
                    k, i = val(i + 1)
                    i = ws(i)
                    i = ws(i + 1)  # skip ]
                    v, i = val(i + 1)  # skip =
                    d[k] = v
                else:
                    m = re.match(r"([A-Za-z_]\w*)\s*=(?!=)", s[i:i + 80])
                    if m:
                        v, i = val(i + m.end())
                        d[m.group(1)] = v
                    else:
                        v, i = val(i)
                        arr.append(v)
        if c == '"':
            j, out = i + 1, []
            while s[j] != '"':
                if s[j] == "\\":
                    out.append(s[j + 1])
                    j += 2
                else:
                    out.append(s[j])
                    j += 1
            return "".join(out), j + 1
        m = re.match(r"-?\d+(\.\d+)?([eE][-+]?\d+)?", s[i:i + 40])
        if m:
            t = m.group(0)
            return (float(t) if ("." in t or "e" in t.lower()) else int(t)), i + m.end()
        for word, v in (("true", True), ("false", False), ("nil", None)):
            if s.startswith(word, i):
                return v, i + len(word)
        raise ValueError("Unexpected Lua at: " + s[i:i + 40])

    return val(i)


# ---------------------------------------------------------------- helpers
def base(rec_id, rtype, source, notes, **extra):
    r = {
        "id": rec_id, "type": rtype, "agent": AGENT, "recordedOn": TODAY,
        "source": source, "originalSource": None, "dataDate": None, "patch": None,
        "quote": None, "notes": notes, "replaces": None,
    }
    r.update(extra)
    return r


def drop_fields(**kw):
    keys = ["studyKey", "sourceKind", "method", "inputItemID", "inputName", "inputRank",
            "gearGroup", "outputItemID", "outputName", "outputRank", "casts",
            "inputsPerCast", "totalQuantity", "castsWithDrop", "percentShown",
            "percentMeaning", "averageShown", "averagePer", "minSeen", "maxSeen",
            "histogram", "skill", "specialization", "stats"]
    out = {k: None for k in keys}
    out.update(kw)
    return out


def num(v):
    return v if isinstance(v, (int, float)) and not isinstance(v, bool) else None


def src(url, title=None, author=None, published=None):
    return {"url": url, "title": title, "author": author, "published": published}



def iso_or_none(v):
    return v if isinstance(v, str) and ISO_DATE.match(v) else None


_SHA = {}


def file_sha(rel):
    if rel not in _SHA:
        with open(os.path.join(ROOT, rel), "rb") as fh:
            _SHA[rel] = hashlib.sha256(fh.read()).hexdigest()
    return _SHA[rel]


def migrated(rel, ref):
    return {"path": rel, "sha256": file_sha(rel), "recordRef": ref}


def derivation(field, formula, assumption=None):
    return {"field": field, "formula": formula, "assumption": assumption}


# ---------------------------------------------------------------- 1. old studies
INPUT_QTY_KEYS = ["reportedInputsConsumed", "sourceInputQuantity", "rawReportedOre",
                  "reportedOreInput", "reportedOre", "reportedOreCount",
                  "reportedInputQuantity", "reportedGrossOre", "reportedInitialOre"]
CAST_KEYS = ["fiveOreEquivalentOperations", "fiveHerbEquivalentOperations",
             "nominalFiveOreEquivalents"]
SKIP_STATUS = {"MODEL_ESTIMATE"}       # model outputs, not data
SKIP_SOURCE_TYPE = {"TSM_HISTORICAL"}  # imported once, from the ItemDB rows instead
OBS_DIR = "research/evidence/observations"

# Raw input quantities, by the old field's own name (M03.1 b). First stated value wins.
# "Processed" fields count what went through the process; "purchased" fields count what the
# player started with or bought (refunded ore may have been processed again). Values are copied,
# never computed: derived old fields (derivedInputsConsumedIfNoRefunds, nominalInputsRequired) are not read.
PROCESSED_KEYS = ["reportedInputsConsumed", "sourceInputQuantity", "rawReportedOre", "reportedOreInput",
                  "reportedOre", "reportedOreCount", "reportedInputQuantity", "reportedGrossOre"]
PURCHASED_KEYS = ["reportedInitialOre", "reportedOrePurchasedOrProcessed"]   # in `processing`
PURCHASED_TOP = ["reportedInitialHerbs"]                                    # top level
REFUNDED_KEYS = ["resourcefulnessOreSaved"]                                 # in `processing`
REFUNDED_TOP = ["oreSaved"]                                                 # top level

# unmappedReportedOutputs statuses that name exactly one material (placed by name, S13 family level).
# Every other status is a category, an aggregate of several items or an unnamed index: kept as a
# row with rawOutputName and outputName null, so it is stored but never placed in an estimate.
SINGLE_MATERIAL_STATUSES = {"UNMAPPED_NAMED_QUALITY", "NAME_AND_QUALITY_ONLY_NOT_ID_VERIFIED",
                            "OUTPUT_FAMILY_IDENTIFIED_QUALITY_RANK_UNKNOWN",
                            "NAME_ONLY_OUTSIDE_WORKER_ASSIGNED_KEYS", "FAMILY_ONLY_QUALITY_RANK_UNRESOLVED"}


def first_raw(obj, keys):
    for k in keys:
        v = num(obj.get(k))
        if v is not None:
            return v, k
    return None, None


def raw_inputs(d):
    p = d["processing"]
    processed, pk = first_raw(p, PROCESSED_KEYS)
    purchased, uk = first_raw(p, PURCHASED_KEYS)
    if purchased is None:
        purchased, uk = first_raw(d, PURCHASED_TOP)
    refunded, rk = first_raw(p, REFUNDED_KEYS)
    if refunded is None:
        refunded, rk = first_raw(d, REFUNDED_TOP)
    if refunded is None and isinstance(d.get("originalUnmappedExtra"), dict):
        refunded = num(d["originalUnmappedExtra"].get("oreSaved"))
        rk = "originalUnmappedExtra.oreSaved" if refunded is not None else None
    return {"inputsProcessed": processed, "inputsPurchased": purchased, "inputsRefunded": refunded}, \
        {"inputsProcessed": pk, "inputsPurchased": uk, "inputsRefunded": rk}


def cast_count(p):
    """The old importer's casts, unchanged, plus its basis and derivation (M03.1 a)."""
    batch = num(p.get("batchInputsPerOperation"))
    casts, note = num(p.get("completedOperations")), "completed casts as reported"
    if casts is not None:
        return casts, note, "reported", []
    for k in CAST_KEYS:
        if num(p.get(k)):
            return p[k], f"casts from the old record's {k}", "nominalEquivalent", [derivation(
                "casts", f"processing.{k} = {p[k]:g} (value computed by the old pipeline, copied)",
                "nominal equivalent operations, not completed casts as the source reported them")]
    if batch:
        for k in INPUT_QTY_KEYS:
            q = num(p.get(k))
            if q:
                return q / batch, (f"casts = {q:g} inputs / {batch:g} per cast (old field {k}); "
                                   "resource refunds would make the true count a little higher"), \
                    "countedFromInputs", [derivation(
                        "casts", f"processing.{k} / processing.batchInputsPerOperation = {q:g} / {batch:g}",
                        "every stated input went through one cast; Resourcefulness refunds would make the true count higher")]
    return None, "cast count not reported", None, []


def unmapped_outputs(d, mapped):
    """Outputs the old record names without an item ID (M03.1 e), as dicts with keys
    name (outputName or None), raw, rank, total, field, reason. An entry whose total equals an unused
    mapped output's total is treated as that output (rawNamedCounts repeats the mapped outputs by name)."""
    found = []
    for i, u in enumerate(d.get("unmappedReportedOutputs") or []):
        label = u.get("materialFamily") or (f"output #{u['reportedIndex']}" if u.get("reportedIndex") else None)
        single = (u.get("mappingStatus") in SINGLE_MATERIAL_STATUSES and u.get("materialFamily")
                  and not re.search(r"\bquality\b|\bgems?\b", u["materialFamily"], re.I))
        found.append({"name": u.get("materialFamily") if single else None, "raw": label,
                      "rank": u.get("outputQualityRankReported"), "total": num(u.get("reportedTotalUnits")),
                      "field": f"unmappedReportedOutputs[{i}]",
                      "reason": f"{u.get('mappingStatus')}: {u.get('reason')}" if u.get("mappingStatus") else u.get("reason")})
    if not d.get("unmappedReportedOutputs") and isinstance(d.get("originalNamedGemTotalsRank2Rank3"), dict):
        for name, pair in d["originalNamedGemTotalsRank2Rank3"].items():
            for rank, total in zip((2, 3), pair or []):
                found.append({"name": name, "raw": name, "rank": rank, "total": num(total),
                              "field": f"originalNamedGemTotalsRank2Rank3.{name}[{rank - 2}]",
                              "reason": "named rank-2/rank-3 total without item ID"})
    for field in ("rawNamedCounts", "originalUnmappedExtra"):
        if isinstance(d.get(field), dict):
            for name, total in d[field].items():
                if name == "oreSaved":
                    continue
                found.append({"name": name, "raw": name, "rank": None, "total": num(total),
                              "field": f"{field}.{name}", "reason": "named total without item ID"})
    unused = [num(o.get("totalUnits")) for o in mapped]
    out = []
    for f in found:
        if f["field"].startswith("rawNamedCounts") and f["total"] in unused:
            unused.remove(f["total"])
            continue
        out.append(f)
    return out


def agent_cited_sources():
    """What v3 agent evidence (everything outside evidence/imported/) already holds: the normalized URLs
    it cites, and (input item, casts, output name, total) of every drop row, so a name-only row the agents
    re-recorded under another URL (S17) is recognised by its numbers."""
    urls, rows = set(), set()
    for path in sorted(glob.glob(os.path.join(ROOT, "research", "v3", "evidence", "**", "*.jsonl"), recursive=True)):
        if os.path.basename(os.path.dirname(path)) == "imported":
            continue
        for line in open(path, encoding="utf-8"):
            try:
                r = json.loads(line)
            except json.JSONDecodeError:
                continue
            if not isinstance(r, dict):
                continue
            for u in ((r.get("source") or {}).get("url") if isinstance(r.get("source"), dict) else None,
                      r.get("originalSource"), r.get("sourceURL")):
                if isinstance(u, str) and u:
                    urls.add(normalize_url(u))
            if r.get("type") == "drop" and r.get("outputName") and num(r.get("totalQuantity")) is not None:
                rows.add(copy_key(r.get("inputItemID"), r.get("casts"), r["outputName"], r["totalQuantity"]))
    return urls, rows


def copy_key(inp, casts, name, total):
    c = num(casts)
    return (str(inp), None if c is None else float(c), str(name).strip().lower(), float(total))


def import_studies():
    cited, agent_rows = agent_cited_sources()
    records, seen, skipped = [], {}, {"model/TSM": 0, "duplicate": 0, "no outputs": 0}
    log = {"skipped": [], "otherSchema": [], "nameOnly": []}
    extra, extra_seen = [], {}    # name-only rows (new in MIG-003), deduped like the old rows
    files = sorted(glob.glob(os.path.join(ROOT, OBS_DIR, "*.jsonl")))
    for path in files:
        fname = os.path.basename(path)
        rel = f"{OBS_DIR}/{fname}"
        for ln, line in enumerate(open(path, encoding="utf-8"), 1):
            if not line.strip():
                continue
            d = json.loads(line)
            ref = f"line {ln}"
            if "outputs" not in d or "processing" not in d:
                log["otherSchema"].append({"path": rel, "line": ln,
                                           "id": d.get("observationID") or d.get("recordKey") or d.get("id"),
                                           "reason": "not the observation schema (no processing/outputs); left for the M03.2-M03.4 adapters"})
                continue
            s = d.get("source") or {}
            if d.get("evidenceStatus") in SKIP_STATUS or s.get("sourceType") in SKIP_SOURCE_TYPE:
                skipped["model/TSM"] += 1
                log["skipped"].append({"path": rel, "line": ln, "id": d.get("observationID") or d.get("studyID"),
                                       "reason": "model estimate (evidenceStatus MODEL_ESTIMATE)"
                                       if d.get("evidenceStatus") in SKIP_STATUS else
                                       "TSM table row (sourceType TSM_HISTORICAL); imported from itemdb.lua instead"})
                continue
            p, g, ctx = d["processing"], d.get("game") or {}, d.get("characterContext") or {}
            batch = num(p.get("batchInputsPerOperation"))
            casts, cast_note, basis, derivs = cast_count(p)
            raw, raw_keys = raw_inputs(d)
            study_key = d.get("observationID") or d.get("studyID") or fname
            specs = ctx.get("specializations")
            spec_text = "; ".join(x.get("description", "") for x in specs if isinstance(x, dict)) if isinstance(specs, list) else None
            hot = g.get("hotfixWindow")
            published = iso_or_none(s.get("publishedDate")) or iso_or_none(s.get("commentPublicationDate"))
            common = dict(
                castsBasis=basis if casts is not None else None, **raw,
                dataDateText=hot if isinstance(hot, str) and not ISO_DATE.match(hot) else None,
                observedOn=iso_or_none(s.get("reportedObservationDate")))
            ctx_fields = dict(skill=ctx.get("effectiveSkill") or ctx.get("baseSkill"),
                              specialization=spec_text or None,
                              stats=json.dumps(ctx.get("stats")) if ctx.get("stats") else None)
            outputs = [o for o in d["outputs"] if o.get("outputItemID")]
            names = unmapped_outputs(d, outputs)
            key = None
            if names and not outputs:
                # Name-only studies (no mapped output at all) get the same keep-the-latest-copy rule.
                key = (s.get("url"), p.get("inputItemID"), p.get("inputQualityRank"), casts,
                       tuple(sorted((str(n["raw"]).lower(), str(n["rank"]), n["total"]) for n in names)))
                if key in extra_seen:
                    for r in extra:
                        if r[1] == key:
                            r[2]["_drop"] = True
                    log["skipped"].append({"path": extra_seen[key][0], "line": extra_seen[key][1],
                                           "id": extra_seen[key][2],
                                           "reason": f"duplicate name-only study: same URL, input, rank, casts and named totals as {rel} {ref} (later copy kept)"})
                extra_seen[key] = (rel, ln, study_key)
            if not outputs:
                skipped["no outputs"] += 1
                if not names:
                    log["skipped"].append({"path": rel, "line": ln, "id": study_key,
                                           "reason": "no outputs at all (neither item IDs nor named totals)"})
            # The same study was sometimes re-recorded by several agents. Keep the latest copy.
            dedupe = (s.get("url"), p.get("inputItemID"), p.get("inputQualityRank"), casts,
                      tuple(sorted((o["outputItemID"], o.get("totalUnits")) for o in outputs)))
            if outputs and dedupe in seen:
                skipped["duplicate"] += 1
                log["skipped"].append({"path": seen[dedupe][0], "line": seen[dedupe][1], "id": seen[dedupe][2],
                                       "reason": f"duplicate study: same URL, input, rank, casts and output totals as {rel} {ref} (later copy kept)"})
                for r in records:
                    if r.get("_dedupe") == dedupe:
                        r["_drop"] = True
                for r in extra:
                    if r[3] == dedupe:
                        r[2]["_drop"] = True
            if outputs:
                seen[dedupe] = (rel, ln, study_key)
            for o in outputs:
                avg, per = None, None
                for k, unit in (("reportedMeanPerCompletedOperation", "cast"),
                                ("unconditionalMeanPerCast", "cast"),
                                ("reportedMeanPerOperation", "cast"),
                                ("reportedUnitsPerOre", "input"),
                                ("reportedUnitsPerHerb", "input"),
                                ("publishedUnitsPer1000Ores", "1000 inputs")):
                    if num(o.get(k)) is not None:
                        avg, per = o[k], unit
                        break
                pct = num(o.get("reportedOccurrenceProbability"))
                hist = o.get("perOperationHistogram") if isinstance(o.get("perOperationHistogram"), dict) else None
                notes = "; ".join(x for x in [
                    f"Imported from research/evidence/observations/{fname}",
                    f"old status {d.get('evidenceStatus')}",
                    cast_note if casts is not None else "cast count not reported",
                    o.get("note") or "",
                ] if x)
                row_derivs = list(derivs)
                if pct is not None and pct <= 1:
                    row_derivs.append(derivation("percentShown", f"outputs.reportedOccurrenceProbability x 100 = {pct:g} x 100",
                                                 "the old field is a 0-1 fraction"))
                rec = base(f"import-study-{len(records) + 1:05d}", "drop",
                           src(s.get("url"), s.get("originalDocumentRef") or s.get("sampleClaim"), None, published),
                           notes,
                           **drop_fields(
                               studyKey=study_key, sourceKind="study", method=p.get("method"),
                               inputItemID=p.get("inputItemID"), inputRank=p.get("inputQualityRank"),
                               outputItemID=o["outputItemID"], outputName=o.get("sourceMaterialName"),
                               outputRank=o.get("outputQualityRank"), casts=casts, inputsPerCast=batch,
                               totalQuantity=num(o.get("totalUnits")), castsWithDrop=num(o.get("hitOperations")),
                               percentShown=round(pct * 100, 4) if pct is not None and pct <= 1 else pct,
                               percentMeaning="perCast" if pct is not None else None,
                               averageShown=avg, averagePer=per,
                               minSeen=num(o.get("observedConditionalMin")),
                               maxSeen=num(o.get("observedConditionalMax")), histogram=hist, **ctx_fields))
                rec["dataDate"] = iso_or_none(hot)
                rec["patch"] = g.get("clientBuild")
                rec.update(common, rawOutputName=None, derivations=row_derivs or None, migratedFrom=migrated(rel, ref))
                rec["_dedupe"] = dedupe
                records.append(rec)
            agent_copy = isinstance(s.get("url"), str) and normalize_url(s["url"]) in cited
            for n in names:
                same_numbers = n["total"] is not None and n["name"] and \
                    copy_key(p.get("inputItemID"), casts, n["name"], n["total"]) in agent_rows
                if n["name"] and (agent_copy or same_numbers):
                    n["why"] = (("not placed: v3 agent evidence already cites this source URL" if agent_copy else
                                 "not placed: a v3 agent row has the same input, casts, output name and total")
                                + ", so placing it could count the same cohort twice (S17); link or place it after a cohort check")
                    n["name"] = None
                elif not n["name"]:
                    n["why"] = "not placed: a category, aggregate or unnamed index, not one material"
                else:
                    n["why"] = None
                notes = "; ".join(x for x in [
                    f"Imported from research/evidence/observations/{fname}",
                    f"old status {d.get('evidenceStatus')}",
                    cast_note if casts is not None else "cast count not reported",
                    f"output without item ID, from old field {n['field']}",
                    n["why"] or "",
                    n["reason"] or "",
                ] if x)
                rec = base(None, "drop", src(s.get("url"), s.get("originalDocumentRef") or s.get("sampleClaim"), None, published),
                           notes,
                           **drop_fields(
                               studyKey=study_key, sourceKind="study", method=p.get("method"),
                               inputItemID=p.get("inputItemID"), inputRank=p.get("inputQualityRank"),
                               outputItemID=None, outputName=n["name"], outputRank=n["rank"], casts=casts,
                               inputsPerCast=batch, totalQuantity=n["total"], **ctx_fields))
                rec["recordedOn"] = M03_DATE
                rec["dataDate"] = iso_or_none(hot)
                rec["patch"] = g.get("clientBuild")
                rec.update(common, rawOutputName=n["raw"], derivations=list(derivs) or None,
                           migratedFrom=migrated(rel, f"{ref}; {n['field']}"))
                rec["_why"] = n["why"]
                extra.append((rel, key, rec, dedupe if outputs else None))
    records = [r for r in records if not r.pop("_drop", False)]
    for r in records:
        r.pop("_dedupe", None)
    for i, r in enumerate(records, 1):
        r["id"] = f"import-study-{i:05d}"
    n_old = len(records)
    for _, _, r, _ in extra:
        why = r.pop("_why", None)
        if r.pop("_drop", None):
            continue
        r["id"] = f"import-study-{len(records) + 1:05d}"
        records.append(r)
        log["nameOnly"].append({"id": r["id"], "path": r["migratedFrom"]["path"], "ref": r["migratedFrom"]["recordRef"],
                                "rawOutputName": r["rawOutputName"], "placedByName": r["outputName"] is not None, "notPlacedBecause": why,
                                "totalQuantity": r["totalQuantity"], "outputRank": r["outputRank"]})
    log["existingRows"] = n_old
    log["skipped"].sort(key=lambda x: (x["path"], x["line"], x["reason"]))
    return records, skipped, log


# ---------------------------------------------------------------- 1b. typeless agent records (M03.0)
TYPELESS_FILE = "research/v3/evidence/midnight/2026-10-31-midnight-refining-shattering-decks.jsonl"
PERCENT_MEANING_TEXT = {"per prospecting craft (author clarified); not per ore": "perCast"}


def import_typeless():
    """The midnight agent wrote ten records with sourceKind/sourceURL/date in place of
    type/source/published. Each is mapped into a valid record that `replaces` the original, so the
    agent file stays untouched. A record whose required field cannot be established is still mapped
    (so nothing is silently lost) but left unplaceable, with the reason in notes and the report."""
    path = os.path.join(ROOT, TYPELESS_FILE)
    out, log = [], []
    if not os.path.exists(path):
        return out, log
    for ln, line in enumerate(open(path, encoding="utf-8"), 1):
        if not line.strip():
            continue
        d = json.loads(line)
        if "type" in d:
            continue
        kind = d.get("sourceKind")
        common = {"source": src(d.get("sourceURL"), d.get("sourceName"), d.get("sourceAuthor"), iso_or_none(d.get("date"))),
                  "replaces": d.get("id")}
        note_tail = (f"Mapped by import_existing.py from {d.get('id')} ({TYPELESS_FILE} line {ln}), which has no `type`; "
                     f"agent fields sourceKind={kind!r}, expansion={d.get('expansion')!r}; agent `date` copied to source.published.")
        rid = f"import-typeless-{len(out) + 1:05d}"
        entry = {"id": rid, "replaces": d.get("id"), "line": ln, "mappedType": None, "placed": None, "reason": None}
        if kind == "exchange":
            r = base(rid, "exchange", common["source"], f"{d.get('notes')} {note_tail}",
                     giveItemID=d.get("giveItemID"), giveName=d.get("giveName"), giveCount=d.get("giveCount"),
                     getItemID=d.get("getItemID"), getName=d.get("getName"), getCount=d.get("getCount"),
                     where=d.get("where"), requirements=d.get("requirements"))
            entry.update(mappedType="exchange", placed=False, reason="exchange records are not estimate input")
        elif kind == "study":
            pm_raw = d.get("percentMeaning")
            pm = PERCENT_MEANING_TEXT.get(pm_raw, pm_raw if pm_raw in ("perCast", "perInput", "unclear", None) else "unclear")
            inp_name = d.get("inputName")
            unplaceable = d.get("inputItemID") is None and inp_name and "unspecified" in inp_name.lower()
            reason = None
            if unplaceable:
                reason = ("input item cannot be established: the source does not say which Darkmoon Deck was "
                          "disenchanted (agent wrote 'suit unspecified'), so inputName is null and the row is unplaced; "
                          "the agent's label is kept in rawInputName and the agent notes forbid generalizing it")
            r = base(rid, "drop", common["source"],
                     f"{d.get('notes')} {note_tail}" + (f" Agent percentMeaning text: {pm_raw!r}." if pm_raw != pm else "")
                     + (f" Not placed: {reason}." if reason else ""),
                     **drop_fields(studyKey=f"typeless-{d.get('id')}", sourceKind="study", method=d.get("method"),
                                   inputItemID=d.get("inputItemID"), inputName=None if unplaceable else inp_name,
                                   outputItemID=d.get("outputItemID"), outputName=d.get("outputName"),
                                   casts=num(d.get("casts")), totalQuantity=num(d.get("outputTotal")),
                                   percentShown=num(d.get("percentShown")), percentMeaning=pm,
                                   averageShown=num(d.get("averageShown")), averagePer=d.get("averagePer"),
                                   histogram=d.get("histogram")))
            r["castsBasis"] = "reported" if num(d.get("casts")) is not None else None
            r["rawInputName"] = inp_name if unplaceable else None
            entry.update(mappedType="drop", placed=not unplaceable, reason=reason or "mapped; placement decided by the estimator")
        else:
            entry.update(reason=f"unknown agent sourceKind {kind!r}; not mapped")
            log.append(entry)
            continue
        r["recordedOn"] = M03_DATE
        r["replaces"] = d.get("id")
        r["migratedFrom"] = migrated(TYPELESS_FILE, f"line {ln}; id {d.get('id')}")
        out.append(r)
        log.append(entry)
    return out, log

# ---------------------------------------------------------------- 2. ItemDB rows
STATUSES = ["unknown", "proxy", "modeled", "measured", "community-reported", "official", "contradictory"]


def import_itemdb():
    s = open(os.path.join(ROOT, "research/proposed/itemdb.lua"), encoding="utf-8").read()
    raw, _ = parse_lua(s, s.index("local raw=") + len("local raw="))
    records = []
    for r in raw:
        rid = r[0]
        kind = "tsm-table" if rid.startswith("tsm:") else "compiled-research"
        method = None
        low = rid.lower()
        for word, m in (("mill", "Mill"), ("prospect", "Prospect"), ("smelt", "Smelt"), ("de:", "Disenchant")):
            if word in low:
                method = m
                break

        def f(x):
            return None if x[0] is False else x[0]
        p, lo, hi, e = (f(r[9 + k]) for k in range(4))
        status = [STATUSES[r[9 + k][1] - 1] for k in range(4)]
        urls = [x for x in (r[16], r[17], r[18]) if isinstance(x, str)]
        url = next((x for x in urls if x.startswith("http")), None)
        notes = (f"Reference value from research/proposed/itemdb.lua row {rid}; "
                 f"old field status (chance/min/max/average): {', '.join(status)}; "
                 f"sources: {' | '.join(urls)}. A starting guess, not a study.")
        records.append(base(
            f"import-ref-{len(records) + 1:05d}", "drop",
            src(url, r[20] if isinstance(r[20], str) else None, None, None), notes,
            **drop_fields(studyKey=rid, sourceKind=kind, method=method, inputItemID=r[3],
                          inputRank=None if r[7] is False else r[7], outputItemID=r[4],
                          outputRank=None if r[8] is False else r[8], inputsPerCast=r[6],
                          percentShown=round(p * 100, 4) if p is not None else None,
                          percentMeaning="perCast" if p is not None else None,
                          averageShown=e, averagePer="cast" if e is not None else None,
                          minSeen=lo, maxSeen=hi)))
        rec = records[-1]
        rec["castsBasis"] = None
        rec["derivations"] = [derivation("percentShown", f"itemdb chance x 100 = {p:g} x 100", "itemdb stores a 0-1 fraction")] \
            if p is not None else None
        rec["migratedFrom"] = migrated("research/proposed/itemdb.lua", f"raw row {rid}")
    return records


# ---------------------------------------------------------------- 3. old GameData.lua
DE_KIND = {"personal-observed-pooled": "personal-pooled",
           "generic-multi-item-empirical": "study",
           "generic-mixed-era-proxy": "reference",
           "borrowed-other-gear-kind": "reference"}


def import_gamedata():
    s = open(os.path.join(ROOT, "GameData.lua"), encoding="utf-8").read()
    de, recipes, tokens = [], [], []
    for m in re.finditer(r'^gd\.disenchant\[(\d+)\]\[(\d+)\]\["(armor|weapon)"\]=', s, re.M):
        exp, quality, kind = int(m.group(1)), int(m.group(2)), m.group(3)
        entry, _ = parse_lua(s, m.end())
        samples = num(entry.get("samples"))
        ev = entry.get("evidence")
        sk = DE_KIND.get(ev, "reference")
        for o in entry.get("outputs") or []:
            e, ch = num(o.get("expectedQuantity")), num(o.get("chance"))
            counted = sk in ("personal-pooled", "study") and samples
            de.append(base(
                f"import-de-{len(de) + 1:05d}", "drop", src(None, "Old addon database GameData.lua (v0.9.70)"),
                f"Imported from GameData.lua disenchant[{exp}][{quality}][{kind}]; evidence '{ev}'; "
                f"{samples} sample items; quantity basis '{o.get('quantityBasis')}'"
                + ("; totals = chance or average x samples" if counted else "; reference only, not counted as casts"),
                **drop_fields(studyKey=f"gamedata:de:{exp}:{quality}:{kind}", sourceKind=sk, method="Disenchant",
                              gearGroup={"expansion": exp, "quality": quality, "kind": kind, "itemLevelRange": None},
                              outputItemID=o.get("id"), casts=samples if counted else None, inputsPerCast=1,
                              castsWithDrop=round(ch * samples) if counted and ch is not None else None,
                              totalQuantity=round(e * samples, 3) if counted and e is not None else None,
                              percentShown=round(ch * 100, 4) if ch is not None else None,
                              percentMeaning="perCast" if ch is not None else None,
                              averageShown=e, averagePer="cast" if e is not None else None,
                              minSeen=num(o.get("minQuantity")), maxSeen=num(o.get("maxQuantity")))))
            rec = de[-1]
            rec["castsBasis"] = "reported" if counted else None
            dv = []
            if ch is not None:
                dv.append(derivation("percentShown", f"chance x 100 = {ch:g} x 100", "GameData stores a 0-1 fraction"))
            if counted and ch is not None:
                dv.append(derivation("castsWithDrop", f"round(chance x samples) = round({ch:g} x {samples:g})",
                                     "chance is the pooled share of items that gave the material"))
            if counted and e is not None:
                dv.append(derivation("totalQuantity", f"round(expectedQuantity x samples, 3) = round({e:g} x {samples:g}, 3)",
                                     "expectedQuantity is the pooled mean per item"))
            rec["derivations"] = dv or None
            rec["migratedFrom"] = migrated("GameData.lua", f"line {line_of(s, m.start())}; gd.disenchant[{exp}][{quality}][\"{kind}\"] output {o.get('id')}")
    for m in re.finditer(r"^gd\.smelt\[(\d+)\]=", s, re.M):
        e, _ = parse_lua(s, m.end())
        ins = e.get("inputs") or []
        recipes.append(base(
            f"import-recipe-{len(recipes) + 1:05d}", "recipe", src(e.get("source")),
            "Imported from GameData.lua smelt table",
            method="Smelt", recipeSpellID=e.get("spell"), recipeName=None,
            inputItemID=ins[0]["id"] if ins else None, inputName=None,
            inputsPerCast=ins[0]["amount"] if ins else None,
            otherReagents=[{"itemID": x["id"], "name": None, "count": x["amount"]} for x in ins[1:]] or None,
            outputItemID=e.get("output"), outputName=None, outputCount=e.get("outputCount")))
        recipes[-1]["migratedFrom"] = migrated("GameData.lua", f"line {line_of(s, m.start())}; gd.smelt[{m.group(1)}]")
    by_token, token_lines = {}, {}
    for m in re.finditer(r"^gd\.tokens\[(\d+)\]\[#gd\.tokens\[\d+\]\+1\]=", s, re.M):
        e, _ = parse_lua(s, m.end())
        by_token.setdefault(int(m.group(1)), []).append(e)
        token_lines.setdefault(int(m.group(1)), line_of(s, m.start()))
    for tid, rewards in sorted(by_token.items()):
        tokens.append(base(
            f"import-token-{len(tokens) + 1:05d}", "token", src(None, "Old addon database GameData.lua (v0.9.70)"),
            "Imported from GameData.lua tokens; reward list may be incomplete",
            tokenItemID=tid, tokenName=None,
            rewards=[{"itemID": x.get("rewardID"), "name": None, "classes": None} for x in rewards],
            howRedeemed="unknown", vendor=None, cost=None, listComplete=None))
        tokens[-1]["migratedFrom"] = migrated("GameData.lua", f"line {token_lines[tid]}; gd.tokens[{tid}]")
    return de, recipes, tokens



def line_of(s, pos):
    return s.count("\n", 0, pos) + 1


# ---------------------------------------------------------------- 3b. GameData mill/prospect/tsmRetail (M03.5)
def itemdb_index():
    s = open(os.path.join(ROOT, "research/proposed/itemdb.lua"), encoding="utf-8").read()
    raw, _ = parse_lua(s, s.index("local raw=") + len("local raw="))
    idx = {}
    for r in raw:
        low = r[0].lower()
        method = next((m for word, m in (("mill", "Mill"), ("prospect", "Prospect"), ("smelt", "Smelt"), ("de:", "Disenchant"))
                       if word in low), None)
        idx.setdefault((method, r[3], r[4]), []).append(r)
    return idx


def _close(a, b):
    return a is not None and b is not None and abs(a - b) < 1e-6


def import_gamedata_tables():
    """Compare GameData's gd.tsmRetail, gd.mill and gd.prospect literal rows with the itemdb.lua rows
    already imported. A row is present when itemdb has the same (method, input, output) from the same
    kind of source: a TSM row for gd.tsmRetail; for gd.mill/gd.prospect a non-TSM row, or a TSM row whose
    numbers equal it. Only missing rows are imported, as sourceKind `reference`: a starting guess, never
    study casts. Their chance is a Poisson/proxy model in GameData (probabilityBasis says NOT MEASURED),
    so only the average is carried; the chance stays in notes."""
    s = open(os.path.join(ROOT, "GameData.lua"), encoding="utf-8").read()
    idx = itemdb_index()
    f = lambda x: None if x[0] is False else x[0]  # noqa: E731
    report = {"tsmRetail": {"rows": 0, "present": 0, "presentValuesDiffer": [], "missing": []},
              "millProspect": {"entries": 0, "entriesWithMaterials": 0, "rows": 0, "present": 0,
                               "presentValuesDiffer": [], "missing": []}}
    for m in re.finditer(r"^gd\.tsmRetail\.(prospect|mill)\[(\d+)\]=", s, re.M):
        method, inp = m.group(1).capitalize(), int(m.group(2))
        rows, _ = parse_lua(s, m.end())
        for o in rows:
            report["tsmRetail"]["rows"] += 1
            cand = [r for r in idx.get((method, inp, o["id"]), []) if r[0].startswith("tsm:")]
            if not cand:
                report["tsmRetail"]["missing"].append({"method": method, "input": inp, "output": o["id"]})
                continue
            report["tsmRetail"]["present"] += 1
            r = cand[0]
            want = (o.get("matRate"), o["amountOfMats"] * 5, o.get("minAmount"), o.get("maxAmount"))
            have = (f(r[9]), f(r[12]), f(r[10]), f(r[11]))
            if not all((a is None and b is None) or _close(a, b) for a, b in zip(want, have)):
                report["tsmRetail"]["presentValuesDiffer"].append(
                    {"itemdbRow": r[0], "gameData": [round(x, 6) if isinstance(x, float) else x for x in want],
                     "itemdb": list(have), "fields": "chance, average per cast (amountOfMats x 5), min, max"})
    records = []
    for m in re.finditer(r"^gd\.(mill|prospect)\[(\d+)\]=", s, re.M):
        table, inp = m.group(1), int(m.group(2))
        e, _ = parse_lua(s, m.end())
        report["millProspect"]["entries"] += 1
        mats = e.get("materials") or []
        if mats:
            report["millProspect"]["entriesWithMaterials"] += 1
        method = e.get("method") or table.capitalize()
        for mat in mats:
            report["millProspect"]["rows"] += 1
            cand = idx.get((method, inp, mat["id"]), [])
            non_tsm = [r for r in cand if not r[0].startswith("tsm:")]
            same_tsm = [r for r in cand if r[0].startswith("tsm:") and _close(f(r[12]), mat.get("expectedQuantity"))]
            ref = f"line {line_of(s, m.start())}; gd.{table}[{inp}] material {mat['id']}"
            if non_tsm or same_tsm:
                report["millProspect"]["present"] += 1
                r = (non_tsm or same_tsm)[0]
                if not _close(f(r[12]), mat.get("expectedQuantity")):
                    report["millProspect"]["presentValuesDiffer"].append(
                        {"gameData": ref, "itemdbRow": r[0], "gameDataAverage": mat.get("expectedQuantity"),
                         "itemdbAverage": f(r[12])})
                continue
            tsm_rows = [r[0] for r in cand]
            report["millProspect"]["missing"].append({"gameData": ref, "kind": e.get("kind"), "evidence": e.get("evidence"),
                                                      "itemdbRowsSameKey": tsm_rows})
            url = e.get("source") if isinstance(e.get("source"), str) and e["source"].startswith("http") else None
            notes = (f"Reference value from GameData.lua gd.{table}[{inp}] (kind '{e.get('kind')}', evidence "
                     f"'{e.get('evidence')}', samples {e.get('samples')}, source {e.get('source')!r}); "
                     f"quantity basis '{mat.get('quantityBasis')}'; GameData chance {mat.get('chance')} not carried "
                     f"(probability basis '{mat.get('probabilityBasis')}'); itemdb.lua has "
                     + (f"only the TSM row(s) {', '.join(tsm_rows)} for this pair, with other numbers"
                        if tsm_rows else "no row for this pair")
                     + ". A starting guess, not a study.")
            rec = base(f"import-gdref-{len(records) + 1:05d}", "drop",
                       src(url, None if url else "Old addon database GameData.lua"), notes,
                       **drop_fields(studyKey=f"gamedata:{table}:{inp}", sourceKind="reference", method=method,
                                     inputItemID=inp, outputItemID=mat["id"], inputsPerCast=e.get("batch"),
                                     averageShown=num(mat.get("expectedQuantity")),
                                     averagePer="cast" if num(mat.get("expectedQuantity")) is not None else None,
                                     minSeen=num(mat.get("minQuantity")), maxSeen=num(mat.get("maxQuantity"))))
            rec["recordedOn"] = M03_DATE
            rec["castsBasis"] = None
            rec["derivations"] = None
            rec["migratedFrom"] = migrated("GameData.lua", ref)
            records.append(rec)
    return records, report


# ---------------------------------------------------------------- 4. remaining structured sources (MIG-004)
# M03.2 observation .json archives, M03.3 evidence/v2 reports and evidence/leads, M03.4 worker submissions,
# the 43 other-schema JSONL records left by M03.1, and M03.6 ledger CSVs. These files are research notes,
# not one schema: each holds "claims" (any object citing a source URL). A claim is imported only when its
# source is new to v3 and a mapper below copies its numbers; every other claim gets a reason in the report:
# its source is already held (agent evidence or rows this run wrote: a copy, or a cohort to link in M04.1),
# it is a reference/identity/news link, or it holds no cohort numbers. Nothing is AI-extracted.
M03B_DATE = "2026-10-31"
INVENTORY = "research/v3/migration/manifest/inventory.jsonl"
ARCHIVE_GLOB = "research/evidence/observations/*.json"
V2_GLOB = "research/evidence/v2/*.json"
LEADS_GLOB = "research/evidence/leads/*.json"
LEGACY_MILLING = "research/evidence/observations/2026-10-28-legacy-milling-batch01.jsonl"
RECIPE_METADATA = "research/evidence/observations/2026-10-28-2116-warwithin-batch014-q16-recipe-metadata.jsonl"
COHORT_RECONCILIATION = "research/evidence/observations/2026-10-28-1231-dragonflight-batch012-source-cohort-reconciliation.jsonl"
TBC_GUIDE = "research/evidence/observations/2026-10-28-0535-legacy-batch005-tbc-guide-source-only.json"

# Hosts these files cite only for item/spell identity, prices, patch notes, guides' recipe facts or news:
# never a player's cohort in any in-scope file (checked in MIG-004; `wow-professions.com` is not here
# because its TBC table is imported as reference rows).
REFERENCE_HOSTS = ("warcraft.wiki.gg", "saddlebagexchange.com", "wowpricehub.com", "goldcap.gg",
                   "tradeskillmaster.com", "thewowdb.com", "github.com", "worldofwarcraft.blizzard.com",
                   "news.blizzard.com", "bluetracker.gg", "mmo-champion.com", "method.gg", "icy-veins.com",
                   "blizzardwatch.com", "wowdb.com", "ptr.wowdb.com", "warcraftable.com", "warcrafttavern.com",
                   "scribd.com")

# Every source key cited by an in-scope file that v3 does not hold yet and that is not a reference host.
# "import" keys have a mapper below; the others are skipped for the reason given. A test fails when a new
# source appears without an entry, so nothing new is ever dropped silently.
NEW_SOURCES = {
    # imported
    "reddit:zzyjzu": ("import", "Jan 2 2023 comment: ~28,000 R3 Serevite, 24 R3 Illimited Diamonds (the Jan 9 comment in the "
                                "same thread is a copy of agent-held reddit 108782r and is skipped)"),
    "reddit:1fb0vv5": ("import", "Luredrop milling: 11 to 17 pigment from each milling, as the author saw it"),
    "reddit:1smgllg": ("import", "calculator-thread commenter's approximate per-prospect rates (under 5,000 ore in all)"),
    "wow-professions.com/tbc/prospecting": ("import", "published TBC prospecting chance table: reference rows not already in v3"),
    "wowhead:spell=190385": ("import", "Wowhead comment 516803: six WoD herbs, 2,000 each, mass-milled, Cerulean Pigment totals"),
    # skipped: same cohort already held under another URL
    "wowhead:item=192870": ("skip", "Bugy's two 2,000-ore Draconium cohorts (3 and 8 Illimited Diamonds): the same author's table is "
                                    "held by the dragonflight agent under wowhead spell=374627 (S17 copy)"),
    # skipped: qualitative, mechanics, UI or economics claims without output quantities
    "reddit:1fdvkmy": ("skip", "a commenter's proposed 30% Resourcefulness return, no measured outputs"),
    "reddit:1g8kbaq": ("skip", "Prospect All queue behaviour (1,000-ore stack queues 200 casts); mechanics, no outputs"),
    "reddit:y3e8ek": ("skip", "2022 original discussion of the Dragonflight beta, qualitative"),
    "wowhead:news=recent-prospecting-changes-wowhead-economy-weekly-wrap-up-351-349956@ptr":
        ("skip", "news coverage of the Oct 2024 prospecting hotfix; rate-change context"),
    "reddit:10s9ol9": ("skip", "Resourcefulness saved-ore rate (mechanics), no outputs"),
    "reddit:1fvhzy0": ("skip", "pigment multipliers (x1.52, x1.49) and a multi-stage cipher count; no base yield or outputs per mill"),
    "reddit:1jc2ya5": ("skip", "qualitative rank-versus-yield discussion"),
    "reddit:1v5esk0": ("skip", "crushing rate forecast (dust per gem); the author's 100,000 ore and 13,000 gems are not a processed batch"),
    "reddit:1vknxyy": ("skip", "same author repeats the crushing rate; no cohort"),
    "reddit:1rrn6of": ("skip", "Resourcefulness UI observation while crushing; no outputs"),
    "reddit:1gcai5k": ("skip", "quotes the Oct 25 2024 prospecting hotfix; rate-change context, no cohort"),
    "reddit:1s66wrz": ("skip", "community comments on R2 output without concentration; no outputs"),
    "reddit:1sgvqjt": ("skip", "effective-skill display before and after relog; no outputs"),
    "reddit:zox4i7": ("skip", "Draconium diamond ranges per ~15,000-ore run of mixed R1/R2 ore; ranges, not totals of one cohort"),
    "blizzforum:1927887": ("skip", "bulk-milling failure report; no outputs"),
    "blizzforum:1944679": ("skip", "bulk-milling failure report; no outputs"),
    "blizzforum:2278388": ("skip", "Resourcefulness explanation for crushing; qualitative"),
    "blizzforum:2362528": ("skip", "milling UI and skill-threshold discussion; no outputs"),
    "blizzforum:2287404": ("skip", "milling selector report (17 displayed crafts, not completed casts); no outputs"),
    "blizzforum:2316717": ("skip", "posts 2, 6 and 7: gear re-equip changed displayed skill, output quality and gemdust "
                                   "rate compared in words; no casts or totals"),
    "blizzforum:611648": ("skip", "skill shortfall after reset; no outputs"),
    "blizzforum:1935257": ("skip", "Arathor's Spear missing from the milling selector; no outputs"),
    "blizzforum:2083666": ("skip", "Arathor's Spear missing from the milling selector; no outputs"),
    "blizzforum:1652762": ("skip", "Draggoth on output quality and skill; qualitative"),
    "blizzforum:1484679": ("skip", "forum reproduction of ar_rules' reddit 109bytz study, which agents hold"),
    "blizzforum:1901868": ("skip", "concentration and prospecting, two casts without output IDs"),
    "blizzforum:2260898": ("skip", "hotfix thread: 'gems found more regularly', no rate"),
    "gdoc:e": ("skip", "ar_rules' published spreadsheet for reddit 109bytz (agent-held); rows not readable offline"),
    "wowhead:news=dragonflight-jewelcrafting-analysis-wowhead-economy-weekly-wrap-up-249-329385":
        ("skip", "Wowhead article on Jallfo's 2022 beta sheet; the sheet's cohorts are held (agents cite it, M03.1)"),
    "wowhead:news=i-bet-you-re-dyeing-to-hear-about-this-decor-dye-updates-in-patch-12-1-381939":
        ("skip", "patch 12.1 dye news; recipe identity, no cohort"),
}
# Mappers that check presence row by row themselves, so they still run when v3 already cites the source.
# Every other "import" source is imported only while v3 does not hold it: once agents record it, the claim
# becomes "held" and the importer stops writing it (no double count when M10 reruns the importer).
ROW_CHECKED_SOURCES = {"wow-professions.com/tbc/prospecting"}
# Wowhead entity pages cited only for an item, spell, trait or recipe identity in these files.
WOWHEAD_IDENTITY = re.compile(r"^wowhead:(spell|item|npc|object|guide|/profession-trait|/profession-tree-calc)")


def source_key(url):
    return normalize_url(url) if isinstance(url, str) and url.startswith("http") else None


def thread_of(key):
    """The thread a key belongs to: forum post numbers, reddit comment IDs and Wowhead comment anchors dropped."""
    if key is None:
        return None
    if key.startswith(("blizzforum:", "reddit:")):
        return ":".join(key.split(":")[:2])
    return key.split("#c")[0]


def is_reference_link(key):
    host = key.split("/")[0]
    return any(host == h or host.endswith("." + h) for h in REFERENCE_HOSTS)


def claims_in(obj, path="$"):
    """(json path, source key, object) for every object that cites a source URL in a field of its own
    (any field: these files use url, sourceURL, originalPost, contemporaneousReport, additionalCoverage...)."""
    out = []
    if isinstance(obj, dict):
        for k, v in obj.items():
            if isinstance(v, str) and v.startswith("http"):
                out.append((f"{path}.{k}", source_key(v), obj))
            elif k == "source" and isinstance(v, dict) and any(isinstance(x, str) and x.startswith("http") for x in v.values()):
                # {"source": {"url": ...}, "processing": ..., "outputs": ...}: the claim is the whole object
                out.extend((f"{path}.source.{sk}", source_key(sv), obj) for sk, sv in v.items()
                           if isinstance(sv, str) and sv.startswith("http"))
            elif isinstance(v, (dict, list)):
                out.extend(claims_in(v, f"{path}.{k}"))
    elif isinstance(obj, list):
        for i, v in enumerate(obj):
            out.extend(claims_in(v, f"{path}[{i}]"))
    return out


def numbers_in(obj):
    """Every number in an object (deep), for comparing a claim with held rows. Item/spell IDs, ranks and dates
    are numbers too, so a match needs a value that is also a held row's count or total (see held_numbers)."""
    out = set()
    if isinstance(obj, bool):
        return out
    if isinstance(obj, (int, float)):
        out.add(round(float(obj), 6))
    elif isinstance(obj, dict):
        for v in obj.values():
            out |= numbers_in(v)
    elif isinstance(obj, list):
        for v in obj:
            out |= numbers_in(v)
    return out


class Holdings:
    """What v3 already holds: agent evidence (outside evidence/imported/) plus the rows this run has already
    written (old studies, typeless, itemdb, GameData). The importer's own MIG-004 output is never read, so a
    rerun sees the same holdings and writes the same rows."""

    COUNT_FIELDS = ("casts", "totalQuantity", "inputsProcessed", "castsWithDrop", "averageShown", "percentShown",
                    "minSeen", "maxSeen", "giveCount", "getCount", "outputCount")

    def __init__(self, prior_rows):
        self.by_key, self.by_thread, self.text, self.recipes = {}, {}, [], {}
        rows = []
        for path in sorted(glob.glob(os.path.join(ROOT, "research", "v3", "evidence", "**", "*.jsonl"), recursive=True)):
            if os.path.basename(os.path.dirname(path)) == "imported":
                continue
            rel = os.path.relpath(path, ROOT).replace(os.sep, "/")
            for line in open(path, encoding="utf-8"):
                try:
                    r = json.loads(line)
                except json.JSONDecodeError:
                    continue
                if isinstance(r, dict) and r.get("type") != "searched":
                    rows.append((rel, r))
                    self.text.append(line.lower())
        rows += [("evidence/imported (this run)", r) for r in prior_rows]
        for rel, r in rows:
            # A search log only records a lead/failed search. It is not a held
            # observation and must not suppress an import from that source.
            if r.get("type") == "searched":
                continue
            if r.get("type") == "recipe":
                self.recipes.setdefault(r.get("recipeSpellID"), []).append(r)
            s = r.get("source") if isinstance(r.get("source"), dict) else {}
            for u in (s.get("url"), r.get("originalSource"), r.get("sourceURL")):
                k = source_key(u)
                if k:
                    self.by_key.setdefault(k, []).append((rel, r))
                    self.by_thread.setdefault(thread_of(k), []).append((rel, r))

    def held(self, key):
        return self.by_key.get(key) or self.by_thread.get(thread_of(key)) or []

    def author_known(self, author):
        a = str(author).strip().lower()
        return bool(a) and any(a in t for t in self.text)

    @classmethod
    def row_numbers(cls, r):
        return {x for x in (round(float(r[f]), 6) for f in cls.COUNT_FIELDS if num(r.get(f)) is not None) if telling(x)}


def telling(x):
    """A number worth comparing: not 0/1 and not a small whole number (batch sizes, ranks and counts like 2 or 5
    match by chance). Averages such as 0.2675 per ore do count."""
    return x > 0 and x != 1 and (x != int(x) or x > 5)


def compare_with_held(claim, rows):
    """Which of a claim's telling numbers appear as a count, total or average of a held row from the same source
    (drop and exchange rows). Only labels the report: a held claim is never imported either way."""
    held = set()
    for _, r in rows:
        held |= Holdings.row_numbers(r)
    mine = {x for x in numbers_in(claim) if telling(x)}
    hit = sorted(mine & held)
    keys = sorted({str(r.get("studyKey") or r.get("id")) for _, r in rows})
    return hit, keys


def assess_file(rel, data, hold, mappers, file_reason=None):
    """Classify every claim in one file. Returns (rows, entry): rows from mappers, entry for the report."""
    entry = {"path": rel, "claims": 0, "imported": 0, "outcomes": {}, "held": [], "skippedNew": [], "reason": file_reason}
    rows, seen, to_import = [], set(), set()
    objs = data if isinstance(data, list) else [data]
    for n, obj in enumerate(objs):
        base_path = f"line {n + 1}" if isinstance(data, list) else "$"
        for jpath, key, claim in claims_in(obj, base_path):
            if key is None or (key, id(claim)) in seen:
                continue
            seen.add((key, id(claim)))
            entry["claims"] += 1
            held = hold.held(key)
            decision = NEW_SOURCES.get(key) or NEW_SOURCES.get(thread_of(key))
            if decision and decision[0] == "import" and key in mappers and (not held or key in ROW_CHECKED_SOURCES):
                outcome = "imported"
                to_import.add(key)
            elif held:
                hit, keys = compare_with_held(claim, held)
                outcome = "held: numbers match" if hit else "held: no number compared"
                entry["held"].append({"at": jpath, "source": key, "matched": hit[:12], "heldStudies": keys[:6]})
            elif decision:
                outcome = "new source skipped"
                entry["skippedNew"].append({"at": jpath, "source": key, "reason": decision[1]})
            elif is_reference_link(key) or WOWHEAD_IDENTITY.match(key):
                outcome = "reference or identity link"
            else:
                outcome = "UNDECIDED new source"
                entry["skippedNew"].append({"at": jpath, "source": key, "reason": "UNDECIDED: add to NEW_SOURCES"})
            entry["outcomes"][outcome] = entry["outcomes"].get(outcome, 0) + 1
    for key in sorted(to_import):
        rows.extend(mappers[key](rel, data))
    entry["imported"] = len(rows)
    if not entry["claims"] and not file_reason:
        entry["reason"] = "cites no source URL"
    return rows, entry


def hist_drop(rel, ref, url, title, author, published, notes, **kw):
    r = base(None, "drop", src(url, title, author, published), notes, **drop_fields(**kw))
    r["recordedOn"] = M03B_DATE
    r.update(castsBasis=None, inputsProcessed=None, inputsPurchased=None, inputsRefunded=None, dataDateText=None,
             observedOn=None, rawOutputName=None, rawInputName=None, derivations=None, migratedFrom=migrated(rel, ref))
    return r


def pct_derivation(x, what):
    return derivation("percentShown", f"{what} x 100 = {x:g} x 100", "the source field is a 0-1 fraction")


# ---- M03.2 mappers: observation .json archives
def map_tbc_guide(rel, data, present):
    """Published chance claims as `reference` rows, only for pairs v3 does not already hold (same URL, a
    non-TSM reference row, or a TSM row with the same chance)."""
    out = []
    url = (data.get("source") or {}).get("url")
    for i, x in enumerate(data.get("records") or []):
        p = num(x.get("publishedChanceClaim"))
        if p is None or present(x["inputItemID"], x["outputItemID"], p, x.get("outputName")):
            continue
        r = hist_drop(rel, f"$.records[{i}] ({x.get('stableKey')})", url, "TBC Prospecting guide (published chance table)",
                      None, None, f"Reference value from {rel} record {x.get('sourceClaimID')}: published approximate chance "
                      f"{p:g}, not hit counts ({data.get('notes')}). A starting guess, not a study.",
                      studyKey=f"wow-professions-tbc-prospecting:{x['inputItemID']}", sourceKind="reference", method="Prospect",
                      inputItemID=x["inputItemID"], outputItemID=x["outputItemID"], outputName=x.get("outputName"),
                      inputsPerCast=5, percentShown=round(p * 100, 4), percentMeaning="perCast")
        r["derivations"] = [pct_derivation(p, "publishedChanceClaim")]
        out.append(r)
    return out


# ---- M03.3 mappers: evidence/v2 reports
def map_zzyjzu(rel, data):
    out = []
    for i, o in enumerate(data.get("observations") or []):
        if o.get("id") != "DF-20230102-SEREVITE-R3-28000-24R3DIAMONDS":
            continue
        r = hist_drop(rel, f"$.observations[{i}] ({o['id']})", o["source"], None, None, iso_or_none(o.get("publicationDate")),
                      f"Imported from {rel} observation {o['id']}; skill {o.get('skillReported')}; the ore count is approximate "
                      f"('{o.get('uncertainty')}'), so casts are not counted from it (S16/M06)",
                      studyKey="reddit-zzyjzu-20230102-r3-serevite-28000", sourceKind="study", method="Prospect",
                      inputItemID=o.get("inputItemID"), inputName=o.get("inputFamily"), inputRank=o.get("inputRank"),
                      outputItemID=o.get("outputItemID"), outputName=o.get("outputFamily"), outputRank=o.get("outputRank"),
                      inputsPerCast=num(o.get("nominalInputPerCast")), totalQuantity=num(o.get("reportedR3DiamondUnits")),
                      skill=str(o["skillReported"]) if o.get("skillReported") is not None else None)
        r["inputsProcessed"] = num(o.get("reportedOreUnitsApprox"))
        out.append(r)
    return out


def map_luredrop(rel, data):
    s, c = data.get("source") or {}, (data.get("source") or {}).get("claim") or {}
    ctx = s.get("context") or {}
    if source_key(s.get("url")) != "reddit:1fb0vv5":
        return []
    r = hist_drop(rel, "$.source.claim", s["url"], None, None, iso_or_none(s.get("publishedDate")),
                  f"Imported from {rel}: the author's own range per milling ('{s.get('verbatimExcerpt')}'); "
                  f"{c.get('interpretation')}; no casts or totals",
                  studyKey="reddit-1fb0vv5-luredrop-range", sourceKind="study", method="Mill",
                  inputName=ctx.get("inputName"), outputName=ctx.get("outputName"),
                  minSeen=num(c.get("minObservedClaim")), maxSeen=num(c.get("maxObservedClaim")))
    r["quote"] = s.get("verbatimExcerpt")
    return [r]


def map_1smgllg(rel, data):
    """Rough per-prospect rates. The source names ore families ('Copper') and short gem names ('Lapis'),
    so input and output stay in rawInputName/rawOutputName and the rows are stored but unplaced (M04.1)."""
    out = []
    lin = data.get("sourceLineage") or {}
    url = lin.get("canonicalURL")
    pub = iso_or_none(lin.get("publicationDate"))
    note = (f"Imported from {rel}; one commenter in a calculator thread, about {(data.get('commentContext') or {}).get('totalOreReported')}; "
            "rates are the author's approximations, not counted outcomes; input and output names are the source's short "
            "names, so the row is stored but unplaced")
    for i, c in enumerate(data.get("claimedRates") or []):
        fam = c.get("inputFamily")
        items = [(n, "eachGemPerProspectApprox", "pct") for n in (c.get("outputNames") or [])
                 if c.get("eachGemPerProspectApprox") is not None and "Stone" not in n and "Glass" not in n]
        if c.get("diamondPerProspectApprox") is not None:
            items.append(("Diamond", "diamondPerProspectApprox", "pct"))
        if c.get("stoneUnitsPerProspectApprox") is not None:
            items.append(("Duskshrouded Stone", "stoneUnitsPerProspectApprox", "avg"))
        if c.get("glassUnitsPerProspectApprox") is not None:
            items.append(("Crystalline Glass", "glassUnitsPerProspectApprox", "avg"))
        if c.get("outputNames") is None and c.get("eachGemPerProspectApprox") is not None:
            items.insert(0, ("each of 'the others' (gems unnamed)", "eachGemPerProspectApprox", "pct"))
        for name, field, kind in items:
            v = c[field]
            r = hist_drop(rel, f"$.claimedRates[{i}].{field} ({name})", url, None, None, pub, note + f"; ore family: {fam}",
                          # numbered by the claim's position, so the per-ore-family claims of this one comment are
                          # a batch family (M05): equal rounded rates for Tin and Silver must not read as a copy
                          studyKey=f"reddit-1smgllg-claim{i + 1}", sourceKind="study",
                          method="Prospect", inputsPerCast=5,
                          percentShown=round(v * 100, 4) if kind == "pct" else None,
                          percentMeaning="perCast" if kind == "pct" else None,
                          averageShown=v if kind == "avg" else None, averagePer="cast" if kind == "avg" else None,
                          specialization="author describes a max-spec prospector")
            r["rawInputName"], r["rawOutputName"] = fam, name
            r["derivations"] = [pct_derivation(v, field)] if kind == "pct" else None
            out.append(r)
    return out


# ---- other-schema JSONL left by M03.1
def import_legacy_milling(hold):
    """legacy-milling-batch01: Wowhead mass-milling comments (20 herbs per cast). A cohort is imported when
    no v3 row holds the same input, output and total and its author is not already in v3 evidence.
    Raw facts only: herbs consumed (inputsProcessed), the mass-mill batch (inputsPerCast 20) and the total.
    casts stay null: the source counts herbs, and the estimate groups for these items already mix 20-herb
    mass-mill casts (Jiyao) with five-herb equivalents (Baadkitty), so counting casts either way would set
    the unit before M06 does (S16). The record's own per-five-herb normalization is derived and not copied."""
    rel = LEGACY_MILLING
    path = os.path.join(ROOT, rel)
    rows, log = [], []
    if not os.path.exists(path):
        return rows, log
    held_totals = {}
    for k, lst in hold.by_key.items():
        for _, r in lst:
            if r.get("type") == "drop" and num(r.get("totalQuantity")) is not None:
                held_totals.setdefault((r.get("inputItemID"), r.get("outputItemID"), float(r["totalQuantity"])), []).append(
                    r.get("studyKey") or r.get("id"))
    for ln, line in enumerate(open(path, encoding="utf-8"), 1):
        if not line.strip():
            continue
        d = json.loads(line)
        s = d.get("source") or {}
        author, herbs, total = s.get("commentAuthor"), num(s.get("originalHerbsConsumed")), num(s.get("reportedOutputTotal"))
        batch = num(s.get("observedMassMillReagentCount"))
        entry = {"line": ln, "recordKey": d.get("recordKey"), "author": author, "outcome": None, "reason": None}
        copy = held_totals.get((d.get("inputItemId"), d.get("outputItemId"), float(total))) if total is not None else None
        if copy:
            entry.update(outcome="skipped", reason=f"copy: v3 already holds input, output and total {total:g} ({copy[0]})")
        elif hold.author_known(author):
            entry.update(outcome="skipped", reason=f"author {author!r} already appears in v3 agent evidence; link in M04.1")
        else:
            entry["outcome"] = "imported"
        log.append(entry)
        if entry["outcome"] != "imported":
            continue
        ref = f"line {ln} ({d.get('recordKey')})"
        notes = (f"Imported from {rel}; Wowhead comment by {author}: {s.get('sampleContext')}; mass milling, "
                 f"{batch:g} herbs per cast")
        if herbs is not None:
            r = hist_drop(rel, ref, s.get("url"), None, author, None,
                          notes + f"; {herbs:g} herbs consumed; casts left null because the source counts herbs, not casts "
                          "(S16, decided in M06)",
                          studyKey=f"wowhead-{author}-{d.get('inputItemId')}-{herbs:g}herbs".lower(), sourceKind="study",
                          method="Mill", inputItemID=d.get("inputItemId"), inputName=d.get("inputName"),
                          outputItemID=d.get("outputItemId"), outputName=d.get("outputName"),
                          inputsPerCast=batch, totalQuantity=total)
            r["inputsProcessed"] = herbs
        else:
            # Melch1337: a published rate per 100 herbs from a pooled study, no herb count per species.
            r = hist_drop(rel, ref, s.get("url"), None, author, None,
                          notes + "; the source gives pigment per 100 herbs from a pooled study (herb count per species not "
                          "given); inputsPerCast is left null so the per-herb rate is not converted to a per-cast "
                          "figure before M06 settles the unit (S15/S16)",
                          studyKey=f"wowhead-{author}-{d.get('inputItemId')}-rate".lower(), sourceKind="study",
                          method="Mill", inputItemID=d.get("inputItemId"), inputName=d.get("inputName"),
                          outputItemID=d.get("outputItemId"), outputName=d.get("outputName"),
                          averageShown=round(total / 100, 6), averagePer="input")
            r["derivations"] = [derivation("averageShown", f"source.reportedOutputTotal / 100 = {total:g} / 100",
                                           "the source's figure is pigment per 100 herbs")]
        rows.append(r)
    return rows, log


def assess_recipe_metadata(hold):
    rel, out = RECIPE_METADATA, []
    if not os.path.exists(os.path.join(ROOT, rel)):
        return out
    for ln, line in enumerate(open(os.path.join(ROOT, rel), encoding="utf-8"), 1):
        if not line.strip():
            continue
        d = json.loads(line)
        rc = d.get("recipe") or {}
        reag = rc.get("exactDirectReagents") or []
        match = [r for r in hold.recipes.get(rc.get("spellID"), [])
                 if r.get("outputItemID") == rc.get("outputItemID") and num(r.get("outputCount")) == num(rc.get("outputCount"))
                 and reag and r.get("inputItemID") == reag[0]["itemID"] and num(r.get("inputsPerCast")) == num(reag[0]["quantity"])]
        out.append({"line": ln, "id": d.get("observationID"), "spell": rc.get("spellID"),
                    "outcome": "skipped" if match else "NOT PRESENT",
                    "reason": f"recipe already in v3 ({', '.join(sorted(r['id'] for r in match))})" if match else
                    "no v3 recipe with the same spell, first reagent, count and output"})
    return out


def assess_cohort_reconciliation(hold):
    """Records the dragonflight agent marked REUSED_*: compared with the held rows of their source."""
    rel, out = COHORT_RECONCILIATION, []
    if not os.path.exists(os.path.join(ROOT, rel)):
        return out
    for ln, line in enumerate(open(os.path.join(ROOT, rel), encoding="utf-8"), 1):
        if not line.strip():
            continue
        d = json.loads(line)
        key = source_key(d.get("sourceURL"))
        held = hold.held(key) if key else []
        hit, keys = compare_with_held(d, held) if held else ([], [])
        out.append({"line": ln, "id": d.get("id"), "source": key, "sourceStatus": d.get("sourceStatus"),
                    "outcome": "skipped", "matched": hit[:8], "heldStudies": keys[:6],
                    "reason": ("copy: the agent marked it " + str(d.get("sourceStatus")) + "; v3 holds the source"
                               + (f" and the numbers {', '.join(f'{x:g}' for x in hit[:4])}" if hit else "")
                               if held else "source not held: CHECK")})
    return out


# ---- M03.6 ledger CSVs
LEDGER_KINDS = {
    "first-pass-coverage-2026-10-28.csv": "coverage tracker (status per stable key, blocker text); numbers are file/line references",
    "first-pass-coverage-v1.csv": "coverage scores per GameData/TSM key; the GameData personal-pooled sample counts it quotes "
                                  "(e.g. samples=12) are the rows already imported in gamedata-disenchant.jsonl",
    "master-worker-batch002-four-field-scores-2026-10-28.csv": "four-field confidence scores per stable key (process): scores and notes, no raw counts",
    "master-worker-batch008-four-field-scores-2026-10-28.csv": "four-field confidence scores per stable key (process): scores and notes, no raw counts",
    "master-worker-batch010-four-field-scores-2026-10-28.csv": "four-field confidence scores per stable key (process): scores and notes, no raw counts",
    "supplemental-output-fields.csv": "GameData/TSM-derived field table (TSM Prospect.lua, GameData personal pools, recipes); the same "
                                      "rows are imported from GameData.lua and itemdb.lua",
    "first-pass-tsm-other-28-field-evidence-2026-10-28.csv": "TSM field review; its six Legion worksheet rows restate the 3,200-ore "
                                                             "Deckven/Felslate cohort held in old-studies.jsonl",
    "titanium-observed-yields.csv": "Titanium totals from two sources; each row compared with held rows (rowChecks)",
}


def assess_ledgers(hold):
    import csv
    out = []
    try:
        inv = [json.loads(l) for l in open(os.path.join(ROOT, INVENTORY), encoding="utf-8")]
    except OSError:
        inv = []
    for i in inv:
        if i.get("category") != "ledger" or i.get("format") != "csv" or not i.get("numericClaimLines"):
            continue
        rel, name = i["path"], os.path.basename(i["path"])
        entry = {"path": rel, "rows": i.get("records"), "disposition": i.get("disposition"), "outcome": "skipped",
                 "reason": LEDGER_KINDS.get(name, "UNDECIDED ledger"), "rowChecks": []}
        if name == "titanium-observed-yields.csv":
            for n, row in enumerate(csv.DictReader(open(os.path.join(ROOT, rel), encoding="utf-8")), 2):
                key = source_key(row.get("source_url"))
                held = hold.held(key)
                total = num(float(row["observed_output_units"])) if row.get("observed_output_units") else None
                same = [r.get("studyKey") for _, r in held if r.get("type") == "drop" and num(r.get("totalQuantity")) == total
                        and str(r.get("inputItemID")) == row["input_id"]]
                entry["rowChecks"].append({"line": n, "output": row.get("output_name"), "source": key, "total": total,
                                           "outcome": "copy" if same else ("held source, output not held: M04.1 source check"
                                                                           if held else "source not held"),
                                           "heldStudy": same[0] if same else None})
        out.append(entry)
    return out


# ---- the families
def import_historical(prior_rows):
    """M03.2, M03.3, M03.4 and the rest of M03 (MIG-004). Returns {output file: rows} and the report."""
    hold = Holdings(prior_rows)
    # Prospect rows by (input, output), from every held row: TSM rows have no URL, so the URL index misses them.
    by_pair, seen_ids = {}, set()
    for r in list(prior_rows) + [r for lst in hold.by_key.values() for _, r in lst]:
        if r.get("type") == "drop" and r.get("method") == "Prospect" and id(r) not in seen_ids:
            seen_ids.add(id(r))
            by_pair.setdefault((r.get("inputItemID"), r.get("outputItemID")), []).append(r)

    guide_named = {(r.get("inputItemID"), str(r.get("outputName")).strip().lower())
                   for _, r in hold.held("wow-professions.com/tbc/prospecting") if r.get("type") == "drop"}

    def tbc_present(inp, out, p, name=None):
        """M03.5's rule: present = same URL (by output ID, or by name: the legacy agent recorded the guide's
        Fel Iron gems by name), a non-TSM reference row, or a TSM row with the same chance."""
        if name and (inp, str(name).strip().lower()) in guide_named:
            return True
        for r in by_pair.get((inp, out), []):
            if source_key((r.get("source") or {}).get("url")) == "wow-professions.com/tbc/prospecting":
                return True
            if r.get("sourceKind") in ("compiled-research", "reference") and num(r.get("percentShown")) is not None:
                return True
            if r.get("sourceKind") == "tsm-table" and num(r.get("percentShown")) is not None and abs(r["percentShown"] - p * 100) < 1e-6:
                return True
        return False

    families = {}
    report = {}

    def run(family, out_name, paths, mappers, reason_for=lambda rel, d: None):
        """A mapper is keyed by the source it maps and runs only on files that cite that source."""
        rows, entries = [], []
        for rel in paths:
            with open(os.path.join(ROOT, rel), encoding="utf-8") as fh:
                txt = fh.read()
            data = [json.loads(l) for l in txt.splitlines() if l.strip()] if rel.endswith(".jsonl") else json.loads(txt)
            cited = {key for obj in (data if isinstance(data, list) else [data]) for _, key, _ in claims_in(obj)}
            r, e = assess_file(rel, data, hold, {k: m for k, m in mappers.items() if k in cited}, reason_for(rel, data))
            rows += r
            entries.append(e)
        families[out_name] = rows
        report[family] = entries

    def rels(pattern):
        return sorted(os.path.relpath(p, ROOT).replace(os.sep, "/") for p in glob.glob(os.path.join(ROOT, pattern)))

    archive_mappers = {"wow-professions.com/tbc/prospecting": lambda rel, d: map_tbc_guide(rel, d, tbc_present)}
    run("archives", "historical-archive-cohorts.jsonl", rels(ARCHIVE_GLOB), archive_mappers)
    v2_mappers = {"reddit:zzyjzu": map_zzyjzu, "reddit:1fb0vv5": map_luredrop, "reddit:1smgllg": map_1smgllg}
    run("v2Reports", "v2-report-cohorts.jsonl", rels(V2_GLOB), v2_mappers)
    run("leads", "leads-cohorts.jsonl", rels(LEADS_GLOB), {})
    try:
        inv = [json.loads(l) for l in open(os.path.join(ROOT, INVENTORY), encoding="utf-8")]
    except OSError:
        inv = []
    subs = sorted(i["path"] for i in inv if i.get("category") in ("worker-submission", "v2-submission")
                  and i.get("format") in ("json", "jsonl")
                  and (i.get("studyObjects") or str(i.get("disposition")).startswith("candidate")
                       or i.get("disposition") == "covered-by-url"))

    def submission_kind(rel, data):
        first = data[0] if isinstance(data, list) and data else data
        name = os.path.basename(rel)
        added = [f for f in (first.get("exactFilesAdded") or []) if "research/evidence/v2/" in f] if isinstance(first, dict) else []
        if added:
            return f"run summary of a v2 evidence report; its cohorts are assessed with {added[0]} (M03.3)"
        if isinstance(first, dict) and "hypothesisID" in first:
            return "mechanics hypothesis card (reference/target contexts restate held cohorts; BLOCKED, no new measurement)"
        if re.search(r"(key|fourfield|field)-audit|confidence-chart|validation|GATE", name):
            return "process artifact: field audit, validation or confidence chart (scores and derived values, not observations)"
        return None
    run("submissions", "submission-cohorts.jsonl", subs, {}, submission_kind)

    mill_rows, mill_log = import_legacy_milling(hold)
    families["legacy-milling-cohorts.jsonl"] = mill_rows
    report["otherSchema"] = {"legacyMilling": mill_log, "recipeMetadata": assess_recipe_metadata(hold),
                             "cohortReconciliation": assess_cohort_reconciliation(hold)}
    report["ledgers"] = assess_ledgers(hold)
    prefixes = {"historical-archive-cohorts.jsonl": "import-archive", "v2-report-cohorts.jsonl": "import-v2report",
                "leads-cohorts.jsonl": "import-lead", "submission-cohorts.jsonl": "import-submission",
                "legacy-milling-cohorts.jsonl": "import-legmill"}
    registry = os.path.join(ROOT, "research", "v3", "migration", "manifest", "historical-import-ids.jsonl")
    pins = []
    if os.path.exists(registry):
        with open(registry, encoding="utf-8") as fh:
            pins = [json.loads(line) for line in fh if line.strip()]
    assign_historical_ids(families, prefixes, pins)
    return families, report


def assign_historical_ids(families, prefixes, pins):
    """Historical IDs belong to source records, not their current list position.

    A held-source supersession can remove earlier rows. Never renumber surviving
    rows into those IDs (corrections and lineage may still refer to them).
    The frozen migration registry is copied from the existing pinned-ID fixture.
    A new mapping requires a reviewed registry entry; tiny fixture repos without
    a registry retain sequential IDs.
    """
    def key(name, path, ref, study):
        return name, path, ref, study
    registered = {key(p["file"], p["path"], p["recordRef"], p["studyKey"]): p["id"] for p in pins}
    if len(registered) != len(pins) or len(set(registered.values())) != len(pins):
        raise ValueError("Duplicate historical ID registry entry")
    seen = set()
    for name, rows in families.items():
        for i, row in enumerate(rows, 1):
            origin = row["migratedFrom"]
            record = key(name, origin["path"], origin["recordRef"], row["studyKey"])
            if pins and record not in registered:
                raise ValueError("Unregistered historical source record: " + repr(record))
            rid = registered.get(record, f"{prefixes[name]}-{i:05d}")
            if rid in seen:
                raise ValueError("Repeated historical source record: " + rid)
            seen.add(rid)
            row["id"] = rid


def write(name, rows):
    path = os.path.join(OUT, name)
    with open(path, "w", encoding="utf-8", newline="\n") as fh:
        for r in rows:
            fh.write(json.dumps(r, ensure_ascii=False, sort_keys=False) + "\n")
    return path


def main(argv=None):
    ap = argparse.ArgumentParser(description="Convert old project records into v3 evidence.")
    ap.add_argument("--report", default=None, help="write a JSON report of skips, mappings and comparisons")
    a = ap.parse_args(argv)
    os.makedirs(OUT, exist_ok=True)
    studies, skipped, study_log = import_studies()
    typeless, typeless_log = import_typeless()
    refs = import_itemdb()
    de, recipes, tokens = import_gamedata()
    gdrefs, gd_report = import_gamedata_tables()
    hist, hist_report = import_historical(studies + typeless + refs + de + recipes + tokens + gdrefs)
    write("old-studies.jsonl", studies)
    write("typeless-agent-records.jsonl", typeless)
    write("itemdb-reference-values.jsonl", refs)
    write("gamedata-disenchant.jsonl", de)
    write("gamedata-smelting-recipes.jsonl", recipes)
    write("gamedata-tokens.jsonl", tokens)
    write("gamedata-mill-prospect-reference.jsonl", gdrefs)
    for name, rows in sorted(hist.items()):
        if rows:  # a family whose every claim is skipped writes no file; the report lists it
            write(name, rows)
    print(f"old studies: {len(studies)} records ({study_log['existingRows']} kept IDs, "
          f"{len(studies) - study_log['existingRows']} name-only rows added; {skipped})")
    print(f"typeless agent records mapped: {len(typeless)}")
    print(f"ItemDB reference values: {len(refs)}")
    print(f"GameData disenchant: {len(de)}, smelting recipes: {len(recipes)}, tokens: {len(tokens)}")
    print(f"GameData mill/prospect rows missing from itemdb, imported as reference: {len(gdrefs)}")
    print("historical sources (MIG-004): " + ", ".join(f"{n} {len(r)}" for n, r in sorted(hist.items())))
    if a.report:
        basis = {}
        for r in studies:
            basis[str(r.get("castsBasis"))] = basis.get(str(r.get("castsBasis")), 0) + 1
        report = {
            "oldStudies": {"rows": len(studies), "existingRows": study_log["existingRows"],
                           "nameOnlyRows": len(studies) - study_log["existingRows"],
                           "skippedCounts": skipped, "castsBasis": basis,
                           "dataDateIso": sum(1 for r in studies if r["dataDate"]),
                           "dataDateText": sum(1 for r in studies if r["dataDateText"]),
                           "observedOn": sum(1 for r in studies if r["observedOn"]),
                           "sourcePublished": sum(1 for r in studies if r["source"]["published"]),
                           "inputsProcessed": sum(1 for r in studies if r["inputsProcessed"] is not None),
                           "inputsPurchased": sum(1 for r in studies if r["inputsPurchased"] is not None),
                           "inputsRefunded": sum(1 for r in studies if r["inputsRefunded"] is not None),
                           "skipped": study_log["skipped"], "otherSchema": study_log["otherSchema"],
                           "nameOnly": study_log["nameOnly"]},
            "typeless": typeless_log,
            "gameData": dict(gd_report, imported=len(gdrefs)),
            "historical": dict(hist_report, rows={n: len(r) for n, r in sorted(hist.items())}),
        }
        os.makedirs(os.path.dirname(os.path.abspath(a.report)), exist_ok=True)
        with open(a.report, "w", encoding="utf-8", newline="\n") as fh:
            json.dump(report, fh, indent=1, sort_keys=True, ensure_ascii=False)
            fh.write("\n")


if __name__ == "__main__":
    sys.exit(main())
