#!/usr/bin/env python3
"""Convert records the project already has into the research v3 evidence format.

Deterministic: running it again on the same files gives the same output. It never
invents a value. Every number comes from an existing record; the only arithmetic is
the simple kind the v3 rules allow (for example 5,000 ore / 5 ore per prospect =
1,000 casts), and each such step is written into the record's `notes`.

Inputs (all already in this branch):
  1. research/evidence/observations/*.jsonl   old study records (main schema)
  2. research/proposed/itemdb.lua             the research ItemDB rows
  3. GameData.lua                             the old addon database (disenchant,
                                              smelting recipes, gear tokens)

Output: research/v3/evidence/imported/*.jsonl  (overwritten on each run)

Usage, from the repository root:
  python3 research/v3/tools/import_existing.py
"""
import glob
import json
import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
OUT = os.path.join(ROOT, "research", "v3", "evidence", "imported")
TODAY = "2026-10-30"
AGENT = "import"


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


# ---------------------------------------------------------------- 1. old studies
INPUT_QTY_KEYS = ["reportedInputsConsumed", "sourceInputQuantity", "rawReportedOre",
                  "reportedOreInput", "reportedOre", "reportedOreCount",
                  "reportedInputQuantity", "reportedGrossOre", "reportedInitialOre"]
CAST_KEYS = ["fiveOreEquivalentOperations", "fiveHerbEquivalentOperations",
             "nominalFiveOreEquivalents"]
SKIP_STATUS = {"MODEL_ESTIMATE"}       # model outputs, not data
SKIP_SOURCE_TYPE = {"TSM_HISTORICAL"}  # imported once, from the ItemDB rows instead


def import_studies():
    records, seen, skipped = [], {}, {"model/TSM": 0, "duplicate": 0, "no outputs": 0}
    files = sorted(glob.glob(os.path.join(ROOT, "research/evidence/observations/*.jsonl")))
    for path in files:
        fname = os.path.basename(path)
        for line in open(path, encoding="utf-8"):
            if not line.strip():
                continue
            d = json.loads(line)
            if "outputs" not in d or "processing" not in d:
                continue
            s = d.get("source") or {}
            if d.get("evidenceStatus") in SKIP_STATUS or s.get("sourceType") in SKIP_SOURCE_TYPE:
                skipped["model/TSM"] += 1
                continue
            p, g, ctx = d["processing"], d.get("game") or {}, d.get("characterContext") or {}
            batch = num(p.get("batchInputsPerOperation"))
            casts, cast_note = num(p.get("completedOperations")), "completed casts as reported"
            if casts is None:
                for k in CAST_KEYS:
                    if num(p.get(k)):
                        casts, cast_note = p[k], f"casts from the old record's {k}"
                        break
            if casts is None and batch:
                for k in INPUT_QTY_KEYS:
                    q = num(p.get(k))
                    if q:
                        casts = q / batch
                        cast_note = f"casts = {q:g} inputs / {batch:g} per cast (old field {k}); resource refunds would make the true count a little higher"
                        break
            outputs = [o for o in d["outputs"] if o.get("outputItemID")]
            if not outputs:
                skipped["no outputs"] += 1
                continue
            # The same study was sometimes re-recorded by several agents. Keep the latest copy.
            dedupe = (s.get("url"), p.get("inputItemID"), p.get("inputQualityRank"), casts,
                      tuple(sorted((o["outputItemID"], o.get("totalUnits")) for o in outputs)))
            if dedupe in seen:
                skipped["duplicate"] += 1
                for r in records:
                    if r.get("_dedupe") == dedupe:
                        r["_drop"] = True
            seen[dedupe] = fname
            study_key = d.get("observationID") or d.get("studyID") or fname
            specs = ctx.get("specializations")
            spec_text = "; ".join(x.get("description", "") for x in specs if isinstance(x, dict)) if isinstance(specs, list) else None
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
                rec = base(f"import-study-{len(records) + 1:05d}", "drop",
                           src(s.get("url"), s.get("originalDocumentRef") or s.get("sampleClaim"),
                               None, s.get("reportedObservationDate")),
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
                               maxSeen=num(o.get("observedConditionalMax")), histogram=hist,
                               skill=ctx.get("effectiveSkill") or ctx.get("baseSkill"),
                               specialization=spec_text or None,
                               stats=json.dumps(ctx.get("stats")) if ctx.get("stats") else None))
                rec["dataDate"] = g.get("hotfixWindow")
                rec["patch"] = g.get("clientBuild")
                rec["_dedupe"] = dedupe
                records.append(rec)
    records = [r for r in records if not r.pop("_drop", False)]
    for r in records:
        r.pop("_dedupe", None)
    for i, r in enumerate(records, 1):
        r["id"] = f"import-study-{i:05d}"
    return records, skipped


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
    by_token = {}
    for m in re.finditer(r"^gd\.tokens\[(\d+)\]\[#gd\.tokens\[\d+\]\+1\]=", s, re.M):
        e, _ = parse_lua(s, m.end())
        by_token.setdefault(int(m.group(1)), []).append(e)
    for tid, rewards in sorted(by_token.items()):
        tokens.append(base(
            f"import-token-{len(tokens) + 1:05d}", "token", src(None, "Old addon database GameData.lua (v0.9.70)"),
            "Imported from GameData.lua tokens; reward list may be incomplete",
            tokenItemID=tid, tokenName=None,
            rewards=[{"itemID": x.get("rewardID"), "name": None, "classes": None} for x in rewards],
            howRedeemed="unknown", vendor=None, cost=None, listComplete=None))
    return de, recipes, tokens


def write(name, rows):
    path = os.path.join(OUT, name)
    with open(path, "w", encoding="utf-8", newline="\n") as fh:
        for r in rows:
            fh.write(json.dumps(r, ensure_ascii=False, sort_keys=False) + "\n")
    return path


def main():
    os.makedirs(OUT, exist_ok=True)
    studies, skipped = import_studies()
    refs = import_itemdb()
    de, recipes, tokens = import_gamedata()
    write("old-studies.jsonl", studies)
    write("itemdb-reference-values.jsonl", refs)
    write("gamedata-disenchant.jsonl", de)
    write("gamedata-smelting-recipes.jsonl", recipes)
    write("gamedata-tokens.jsonl", tokens)
    print(f"old studies: {len(studies)} records ({skipped})")
    print(f"ItemDB reference values: {len(refs)}")
    print(f"GameData disenchant: {len(de)}, smelting recipes: {len(recipes)}, tokens: {len(tokens)}")


if __name__ == "__main__":
    sys.exit(main())
