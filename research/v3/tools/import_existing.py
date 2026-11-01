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

Output: research/v3/evidence/imported/*.jsonl  (overwritten on each run)

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
    write("old-studies.jsonl", studies)
    write("typeless-agent-records.jsonl", typeless)
    write("itemdb-reference-values.jsonl", refs)
    write("gamedata-disenchant.jsonl", de)
    write("gamedata-smelting-recipes.jsonl", recipes)
    write("gamedata-tokens.jsonl", tokens)
    write("gamedata-mill-prospect-reference.jsonl", gdrefs)
    print(f"old studies: {len(studies)} records ({study_log['existingRows']} kept IDs, "
          f"{len(studies) - study_log['existingRows']} name-only rows added; {skipped})")
    print(f"typeless agent records mapped: {len(typeless)}")
    print(f"ItemDB reference values: {len(refs)}")
    print(f"GameData disenchant: {len(de)}, smelting recipes: {len(recipes)}, tokens: {len(tokens)}")
    print(f"GameData mill/prospect rows missing from itemdb, imported as reference: {len(gdrefs)}")
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
        }
        os.makedirs(os.path.dirname(os.path.abspath(a.report)), exist_ok=True)
        with open(a.report, "w", encoding="utf-8", newline="\n") as fh:
            json.dump(report, fh, indent=1, sort_keys=True, ensure_ascii=False)
            fh.write("\n")


if __name__ == "__main__":
    sys.exit(main())
