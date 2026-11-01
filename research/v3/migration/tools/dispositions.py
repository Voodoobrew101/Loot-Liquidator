#!/usr/bin/env python3
"""M07: a final disposition for every historical file, and the exception queue.

Reads (never writes anything but its own outputs): manifest/inventory.jsonl, manifest/links.jsonl, manifest/extraction/*.json,
manifest/validation.json, manifest/url-registry.jsonl, reports/M03b-import-data.json, reports/M05-identity-data.json, the
`migratedFrom` pointer of every row in research/v3/evidence/imported/*.jsonl, and what v3 holds now (build_estimates.load()).
Writes, sorted and without timestamps, so a rerun is byte-identical:

  manifest/dispositions.jsonl       one row per inventory file: final disposition, machine-readable reason, pointers
  manifest/exceptions.jsonl         every contradiction or suspicious transformation a person has to decide, with record IDs
  manifest/scope-gap.jsonl          unheld sources with counts that the residual queue never saw (M04.3 finding 1), each decided
  manifest/dispositions-summary.json  counts for the report

Final dispositions (a closed vocabulary; the inventory's preliminary names never survive):

  imported                 the importer wrote rows from this file (migratedFrom); includes the partial reference imports
  extracted                extract_batch.py wrote rows from a source in this file
  linked                   every cited cohort matches rows v3 holds, or the cited source is held; nothing to import
  extracted-null           a source cited here was read in M04.3 and holds no usable cohort (checkpoint code in the reason)
  exception-queued         a held source's numbers differ from v3's rows, or a candidate stays unverified: exceptions.jsonl
  reference-only           cites only reference hosts or sources M03 decided to skip; no cohort
  held-sources-only        no observational numbers of its own; every source it cites is held by v3 (page or thread level) or is
                           reference: the agents' own review of sources v3 already has
  source-links-only        cites sources v3 does not hold, with no count beside them: leads in url-registry.jsonl
  process-artifact         tests, tools, prompts, QA feedback, audits, coverage and score tables, reports without a source
  derived-model            statistical model outputs (not observations)
  mechanics-knowledge      mechanics registries (feed mechanics.md, not estimates)
  no-observational-content no numbers and no new URLs

Precedence for a file (first match): exception-queued, imported, extracted, extracted-null, linked, then the rules for files
the linker never read (by inventory disposition and, for source reviews, by what their citations are). A file with an exception
that was also imported keeps `exception-queued`; its pointers say what was imported.

No network, no AI, nothing invented: every number comes from a file or from counting.

Usage, from the repository root:
  python3 research/v3/migration/tools/dispositions.py [--out-dir research/v3/migration/manifest] [--check]
"""
import argparse
import collections
import glob
import hashlib
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
sys.path.insert(0, os.path.join(HERE, "..", "..", "tools"))
sys.path.insert(0, HERE)
import link_sources as ls  # noqa: E402

MANIFEST = os.path.join("research", "v3", "migration", "manifest")
REPORTS = os.path.join("research", "v3", "migration", "reports")
IMPORTED_DIR = os.path.join("research", "v3", "evidence", "imported")
EXTRACTED_FILE = "extracted-historical-sources.jsonl"

VOCAB = ("imported", "extracted", "linked", "extracted-null", "exception-queued", "reference-only",
         "held-sources-only", "source-links-only", "process-artifact", "derived-model", "mechanics-knowledge",
         "no-observational-content")
AUDIT_NAME = re.compile(r"audit|validation|four-?field|confidence-chart", re.I)   # field audits and validation tables
AUDIT_CATEGORIES = ("worker-submission", "v2-submission", "ledger", "proposed")
FORBIDDEN = ("preliminary", "candidate-unmigrated", "candidate-no-url", "covered-by-url", "reference-imported-partial")
CITED_FORMATS = ("md", "csv", "json", "jsonl")      # formats whose citations the linker's readers understand
BIG = 20                                             # a count worth a look beside a citation (the M04.3 scan used 20)
MAX_IDS = 12                                         # record IDs listed per disposition row (the count is exact)
MAX_SOURCES = 8
KEY_ORDER = ("lead-only", "residue", "exception", "linked", "source-held", "skipped-decided", "reference")   # worst first

REPORT_OF_EVIDENCE_FILE = {
    "old-studies.jsonl": "reports/M03-import.md", "gamedata-disenchant.jsonl": "reports/M03-import.md",
    "gamedata-mill-prospect-reference.jsonl": "reports/M03-import.md", "gamedata-smelting-recipes.jsonl": "reports/M03-import.md",
    "gamedata-tokens.jsonl": "reports/M03-import.md", "itemdb-reference-values.jsonl": "reports/M03-import.md",
    "typeless-agent-records.jsonl": "reports/M03-import.md",
    "historical-archive-cohorts.jsonl": "reports/M03b-import.md", "legacy-milling-cohorts.jsonl": "reports/M03b-import.md",
    "v2-report-cohorts.jsonl": "reports/M03b-import.md", EXTRACTED_FILE: "reports/M04-extraction.md",
}

# Decisions for unheld sources with counts that the residual queue never saw (key: cleaned source key). Anything the scan finds
# that is neither held, nor checkpointed, nor listed here is UNDECIDED and fails the tests.
SCOPE_GAP_DECISIONS = {
    "blizzforum:1499506": (
        "PATCH_THREAD_DATE_SUPPORT",
        "Blizzard patch 10.0.5 known-issues thread, cited as date support (sourceDateSupport) in an F004 source review. The numbers "
        "near it (400, 2300, 3500, 8000, 11500) belong to the Reddit 10bngi7 and Wowhead 194545 / 192869 cohorts in the same file; "
        "the thread itself has no cohort."),
    "blizzforum:2277117": (
        "QUALITATIVE_NO_DENOMINATOR",
        "Commenter Reikah: rare blue gems can give one dust from three gems. The note itself says no cast denominator, item IDs or "
        "skill; the 21 beside the citation is a date (March 21)."),
    "reddit:1s1dtuh": (
        "QUALITATIVE_NO_DENOMINATOR",
        "Different commenters report one, two and three Gemdust from Crushing, without per-item input IDs or a denominator; the note "
        "says not to multiply independent cohorts. The 23 beside the citation is a date (March 23)."),
    "gdoc:1jBMgICcVpqIezJo_dtBPmIdA7UTq8QToPp1JpVVONn0": (
        "DERIVATIVE_CALCULATOR",
        "The 1smgllg author's workbook: hardcoded estimates taken from WoW-Professions, 'one derivative calculator, not an "
        "independent observed experiment' (its own audit note). The 15,356 beside it is the file size in bytes. The thread's own "
        "per-prospect rates are the 1smgllg `placement-proposal` exception."),
    "wowdayday.com/wiki/entry/profession:jewelcrafting:recipe:1230462": (
        "IDS_ONLY",
        "Recipe page cited for identity; the numbers beside it are item and spell IDs (242553, 242620, 1230462, 1231132), not counts."),
    "wowwiki-archive.fandom.com/wiki/breastplate_of_the_wayward_vanquisher": (
        "IDS_ONLY",
        "Token reference page; the numbers beside it are item IDs 45634 and 46123 (a token and its Rogue chest), not counts."),
    "wow-professions.com/the-war-within/khaz-algar-inscription-leveling-guide": (
        "PUBLISHED_TABLE_NOT_IN_TEXT",
        "Published leveling guide cited in source-inventory.csv rows next to item IDs and GameData line numbers; no cohort."),
}


# ------------------------------------------------------------------ small helpers
def jl(path):
    with open(path, encoding="utf-8") as f:
        return [json.loads(l) for l in f if l.strip()]


def jload(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def dump(path, rows):
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        for r in rows:
            f.write(json.dumps(r, sort_keys=True, ensure_ascii=False) + "\n")


def sha256_of(path):
    with open(path, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()


def short(text, n=170):
    text = " ".join(str(text).split())
    return text if len(text) <= n else text[:n - 1].rstrip() + "…"


def ex_id(prefix, *parts):
    return f"EX-{prefix}-" + hashlib.sha1("|".join(map(str, parts)).encode()).hexdigest()[:8]


def clean_key(key):
    """CSV rows put the rest of the row into the URL match ('...table-inscription,55,12,0'): keep the URL."""
    return key.split(",")[0]


# ------------------------------------------------------------------ inputs
class Inputs:
    def __init__(self, root):
        m = os.path.join(root, MANIFEST)
        self.root = root
        self.inventory = jl(os.path.join(m, "inventory.jsonl"))
        self.links = jl(os.path.join(m, "links.jsonl"))
        self.validation = jload(os.path.join(m, "validation.json"))
        self.m03b = jload(os.path.join(root, REPORTS, "M03b-import-data.json"))
        self.m05 = jload(os.path.join(root, REPORTS, "M05-identity-data.json"))
        self.importer_reason = {}     # M03.2-M03.4 per-file reasons (archives, leads, submissions, v2 reports)
        for fam in ("archives", "leads", "submissions", "v2Reports"):
            for e in self.m03b["historical"].get(fam, []):
                if e.get("reason"):
                    self.importer_reason[e["path"]] = e["reason"]
        self.file_rows = {r["path"]: r for r in self.links if r["kind"] == "file"}
        self.src_rows = collections.defaultdict(list)
        self.candidates = [r for r in self.links if r["kind"] == "candidate"]
        for r in self.links:
            if r["kind"] == "source":
                self.src_rows[r["path"]].append(r)
        self.checkpoints = {}
        for p in sorted(glob.glob(os.path.join(m, "extraction", "*.json"))):
            ck = jload(p)
            self.checkpoints[ck["source"]] = (os.path.relpath(p, root).replace(os.sep, "/"), ck)
        # what the importers and the extractor wrote, by the historical file each row came from
        self.imported = collections.defaultdict(lambda: collections.defaultdict(list))
        self.row_file = {}        # record id -> migratedFrom path
        self.row_evidence = {}    # record id -> evidence file name
        for p in sorted(glob.glob(os.path.join(root, IMPORTED_DIR, "*.jsonl"))):
            name = os.path.basename(p)
            for r in jl(p):
                mf = r.get("migratedFrom")
                if isinstance(mf, dict) and mf.get("path"):
                    self.imported[mf["path"]][name].append(r.get("id"))
                    self.row_file[r.get("id")] = mf["path"]
                    self.row_evidence[r.get("id")] = name


# ------------------------------------------------------------------ citations (out-of-scope files and the scope gap)
def scan_citations(root, inventory, index):
    """path -> list of {key, status, big, where}: the linker's reading of every citation, CSV keys cleaned."""
    out = {}
    for row in inventory:
        if row["format"] not in CITED_FORMATS:
            continue
        rel = row["path"]
        with open(os.path.join(root, rel), "rb") as f:
            text = f.read().decode("utf-8", errors="replace")
        items = []
        for c in ls.citations_for(rel, text):
            if row["format"] == "csv":
                c = dict(c, key=clean_key(c["key"]))
            v = ls.classify(c, index)
            items.append({"key": c["key"], "status": v["status"], "reason": v["reason"], "where": c["where"],
                          "big": sorted(n for n in c["numbers"] if n >= BIG)[:6]})
        out[rel] = items
    return out


def scope_gap(inputs, scans, index):
    """Unheld sources with a count of 20 or more beside the citation, anywhere in the inventory, each decided."""
    in_scope = set(inputs.file_rows)
    disp = {r["path"]: r["disposition"] for r in inputs.inventory}
    seen = collections.defaultdict(lambda: {"files": set(), "scope": set(), "big": set()})
    for path, items in scans.items():
        for it in items:
            if it["status"] not in ("lead-only", "residue") or not it["big"]:
                continue
            g = seen[it["key"]]
            g["files"].add(path)
            g["scope"].add("in-scope" if path in in_scope else "out-of-scope")
            g["big"].update(it["big"])
    rows = []
    for key, g in sorted(seen.items()):
        held = index.held(key)
        if key in inputs.checkpoints:
            slug, ck = inputs.checkpoints[key]
            decision, code = "queue-source", "HAS_CHECKPOINT"
            reason = f"source is in the residual queue; checkpoint {os.path.basename(slug)} is {ck['status']}"
            if ck["status"] == "null":
                reason += f" ({ck['answer'].get('reasonCode')})"
            pointer = slug
        elif held:
            decision, code, reason, pointer = "held", "HELD_AFTER_CLEANING", "v3 holds this source once the CSV row is cut from the URL", None
        elif key in SCOPE_GAP_DECISIONS:
            code, reason = SCOPE_GAP_DECISIONS[key]
            decision, pointer = "reasoned-disposition", None
        else:
            decision, code, reason, pointer = "UNDECIDED", "UNDECIDED", "add a checkpoint (extract_batch.py, EXTRA_FILES) or a reasoned decision", None
        rows.append({"source": key, "decision": decision, "code": code, "reason": reason, "checkpoint": pointer,
                     "scope": sorted(g["scope"]), "numbers": sorted(g["big"])[:10], "fileCount": len(g["files"]),
                     "files": sorted(g["files"])[:6],
                     "inventoryDispositions": sorted({disp[p] for p in g["files"]})})
    return rows


# ------------------------------------------------------------------ exceptions
def held_ids(index, key):
    h = index.held(key)
    if not h:
        return []
    return sorted({str(r["id"]) for r in h[1] if r.get("id")})


def study_ids(index, study):
    return sorted({str(r["id"]) for r in index.by_study.get(study, []) if r.get("id")})


def build_exceptions(inputs, index):
    ex = []

    def add(kind, prefix, key_parts, subject, detail, record_ids, refs, files, sources, action, **extra):
        row = {"id": ex_id(prefix, *key_parts), "kind": kind, "subject": subject, "detail": detail,
               "recordIDs": sorted(set(str(i) for i in record_ids if i)), "refs": sorted(set(refs)),
               "files": sorted(set(files)), "sources": sorted(set(sources)), "action": action}
        row.update(extra)
        ex.append(row)

    # 1. held sources whose numbers differ (the 83 citation groups)
    for path in sorted(inputs.src_rows):
        for s in inputs.src_rows[path]:
            if s["status"] != "exception":
                continue
            ids = held_ids(index, s["source"]) or [r["id"] for r in s["records"]]
            nums = ", ".join(f"{n:g}" for n in s["claimNumbers"][:8])
            add("held-source-numbers-differ", "LINK", (path, s["source"]),
                f"{s['source']} cited in {os.path.basename(path)}",
                f"v3 holds this source ({s['recordCount']} record(s)) but none of the citation's numbers is a held result"
                + (" (the batch size matches)" if s["denominatorMatched"] else "") + f"; numbers beside the citation: {nums}; "
                f"lines {', '.join(str(x) for x in s['lines'][:6])}",
                ids, [f"{path}:{s['lines'][0]}"] if s["lines"] else [path], [path], [s["source"]],
                "Read the note's counts against the held rows; if the note records a different cohort, an agent records it with its "
                "own studyKey, if it restates a ratio or audit figure, close this entry as not a cohort.")

    cands = collections.defaultdict(list)
    for c in inputs.candidates:
        cands[(c["group"], c["status"])].append(c)

    # 2. the six Jallfo exceptions (imported totals against agent totals, 1,000 casts each)
    for c in sorted(cands[("nameOnlyRow", "exception")], key=lambda c: c["id"]):
        agent = [a["id"] for a in c["agentRecords"]]
        add("imported-vs-agent-totals-differ", "JALLFO", (c["id"],),
            f"{c['source']} {c['output']} ({c['casts']} casts), imported row against agent rows",
            c["reason"], [c["id"]] + agent, [c["studyKey"]] + [f"{a['file']}#{a['id']}" for a in c["agentRecords"]],
            [inputs.row_file[c["id"]]] if c["id"] in inputs.row_file else [], [c["source"]],
            "Different cohorts or different transcriptions of one sheet: needs the original post (not readable offline). Decide which "
            "side to exclude through corrections.jsonl, or ask the owning agent to flag.")

    # 3. s6bfrl uncommon gems (six outputs, no v3 row)
    s6 = sorted(cands[("s6bfrl-uncommon-gems", "exception")], key=lambda c: c["line"])
    if s6:
        add("unverified-output-count", "S6BFRL", ("s6bfrl",), "reddit:s6bfrl uncommon gems (six outputs, 1,000 ore each)",
            "The ledger lists " + ", ".join(c["output"] for c in s6) + ". v3 holds this source's powder and rare gems "
            f"({s6[0]['heldRecordCount']} records) but no row for these outputs; the post is not readable offline, so nothing is imported.",
            held_ids(index, "reddit:s6bfrl"), sorted({f"{c['path']}:{c['line']}" for c in s6}), [c["path"] for c in s6],
            ["reddit:s6bfrl"],
            "Check the post; if the counts are there, an agent records a 1,000-ore Retail 2022 cohort for the six uncommon gems.")

    # 4. the 22 zkay8v 10,000-ore rows (stored, unplaced)
    z = sorted(cands[("nameOnlyRow", "unlinked")], key=lambda c: c["id"])
    if z:
        add("unplaced-name-only-cohort", "ZKAY8V", ("zkay8v-10000",),
            f"reddit:zkay8v 10,000-ore cohort: {len(z)} rows stored with a name and no item ID",
            "Agents recorded only the 1,000-prospect cohort, so these rows have no agent copy. The importer places nothing by name; "
            "the output names (R2/R3 ores and gems) are unambiguous in the 1,000-cast study.",
            [c["id"] for c in z], [c["studyKey"] for c in z], [inputs.row_file[c["id"]] for c in z if c["id"] in inputs.row_file],
            ["reddit:zkay8v"],
            "Decide whether to place them by name, or ask the dragonflight agent to record the cohort with item IDs.")

    # 5. 1smgllg rates (proposals only; the importer places nothing from this source)
    sm = sorted(cands[("1smgllg", "linked")] + cands[("1smgllg", "listed")], key=lambda c: c["id"])
    if sm:
        add("placement-proposal", "PLACE", ("1smgllg",),
            f"reddit:1smgllg per-prospect rates: {len(cands[('1smgllg', 'linked')])} with unambiguous output IDs, "
            f"{len(cands[('1smgllg', 'listed')])} aggregate labels",
            "One commenter's approximate rates (under 5,000 ore in all). The output names resolve to one v3 item each; the input is a "
            "rank pair (family-level). The importer places nothing from this source.",
            [c["id"] for c in sm], [c["studyKey"] for c in sm], [inputs.row_file[c["id"]] for c in sm if c["id"] in inputs.row_file],
            ["reddit:1smgllg"],
            "Placing the 11 needs an importer change with family-level inputs (M10 or later); weight them as reference, not a study.")

    # 6. Felslate 2016: ten batch totals add up to 101, both v3 copies say 97
    fel = ["import-study-00967", "import-study-01041"]
    rec = {r["id"]: r for r in index.rows if r.get("id") in fel}
    if len(rec) == 2:
        totals = sorted({r.get("totalQuantity") for r in rec.values()})
        add("total-differs-from-source", "FELSLATE", ("51ovfk",),
            "Felslate 2016 (reddit:51ovfk) after-hotfix rare-gem total",
            f"The archive lists ten batch totals that add up to 101 rare gems (M03b report); both v3 copies say {totals[0]:g}. All three "
            "are unplaced category rows, so no estimate is affected.",
            fel, [rec[i]["studyKey"] for i in fel], [inputs.row_file[i] for i in fel if i in inputs.row_file],
            ["reddit:51ovfk"], "One source check; then a correction to totalQuantity on whichever copy is wrong.")

    # 7. the 12 ambiguous-doubt extraction sources
    for source in sorted(inputs.checkpoints):
        slug, ck = inputs.checkpoints[source]
        if ck["status"] != "null" or ck["answer"].get("reasonCode") != "ambiguous-doubt":
            continue
        files = [f["path"] for f in ck["entry"]["files"]]
        add("ambiguous-doubt-source", "DOUBT", (source,), f"{source}: real numbers the extraction rules refuse",
            short(ck["answer"]["reason"], 400), [], [slug], files, [source],
            "Say whether to store it as a `reference` row with an `unclear` meaning, or leave it as a null; nothing was written.")

    # 8. the validator's errors, each with a fix path that does not edit agent evidence
    for f in sorted((f for f in inputs.validation["findings"] if f["severity"] == "error"), key=lambda f: (f["file"], f["line"])):
        if f["code"] == "METHOD_UNKNOWN":
            action = ("Agent flag: the record is a rateChange, so a method outside Prospect/Mill/Disenchant/Smelt carries no estimate. "
                      "Ask the owning agent for a correcting record (replaces this id) with method null and the method in notes, or "
                      "the owner adds the value to METHODS in evidence-format.md (SCHEMA-EXTENSION.md).")
            proposal = {"recordID": f["id"], "file": f["file"], "field": "method", "value": None,
                        "reason": "rateChange without an estimator method; the method is in notes (proposed in M07, not applied)"}
        else:
            action = ("Importer-owned row with every field unknown (quarantined ItemDB value): excluding it loses nothing. Same "
                      "precedent as import-ref-01009 in corrections.jsonl. Never guess a method.")
            proposal = {"recordID": f["id"], "file": f["file"], "field": "exclude", "value": True,
                        "reason": "quarantined ItemDB reference row with no method and no values (proposed in M07, not applied)"}
        add("validator-error", "VALID", (f["id"], f["code"]), f"{f['code']} on {f['id']}", f["message"], [f["id"]],
            [f"{f['file']}:{f['line']}"], [], [], action, code=f["code"], proposedCorrection=proposal)

    # 9. M05: identity decisions that were proposed, never applied
    for p in sorted(inputs.m05["crossSourceMatches"], key=lambda p: p["studies"]):
        add("cross-source-identity-pair", "XSRC", tuple(p["studies"]),
            f"two studies merged across {p['sources'][0]} and {p['sources'][1]}",
            "The estimator counts these once because their numbers are identical; the sources differ (a Wowhead flavour or a mirror).",
            [i for s in p["studies"] for i in study_ids(index, s)], list(p["studies"]), [], p["sources"],
            "Set originalSource on the copy through corrections.jsonl if they are one cohort, or leave them if the sources are independent.")
    for p in sorted(inputs.m05["mergedWithConflicts"], key=lambda p: p["studies"]):
        add("identity-merge-with-conflict", "MERGE", tuple(p["studies"]) + (p["input"], p["output"], p["method"]),
            f"{p['kind']} merge of {len(p['studies'])} studies ({p['input']} -> {p['output']}, {p['method']}), {p['lostCasts']} casts not counted",
            "Studies with conflicting numbers were counted once under one identity. The R3 Serevite labels need the original posts "
            "(Reddit zh53dd and 108782r).",
            [i for s in p["studies"] for i in study_ids(index, s)], list(p["studies"]), [], [],
            "Read the posts; then separate the cohorts with cohortKey or exclude the copy through corrections.jsonl.")
    for p in sorted(inputs.m05["smallSubsets"], key=lambda p: (p["file"], p["study"])):
        add("single-row-subset", "SUBSET", (p["file"], p["study"], p["within"]),
            f"single-row subset {p['study']} inside {p['within']}",
            "One row of a larger study counted once (judged independent in M05); a copy would double count.",
            study_ids(index, p["study"]) + study_ids(index, p["within"]), [p["study"], p["within"]], [], [p["source"]],
            "Exclude the single row through corrections.jsonl if it restates the larger study.")

    ex.sort(key=lambda r: (r["kind"], r["id"]))
    return ex


# ------------------------------------------------------------------ one file
def pointers_for(inputs, path, extra=None):
    p = {}
    imp = {n: ids for n, ids in inputs.imported.get(path, {}).items()}
    ids = sorted(str(i) for v in imp.values() for i in v if i)
    if ids:
        p["recordIDs"] = ids[:MAX_IDS]
        p["recordCount"] = len(ids)
        p["evidenceFiles"] = {n: len(v) for n, v in sorted(imp.items())}
        p["reports"] = sorted({REPORT_OF_EVIDENCE_FILE.get(n, "reports/M03-import.md") for n in imp})
    if extra:
        p.update(extra)
    return p


def decide(row, inputs, scans, exc_by_file, index):
    """(disposition, code, text, pointers) for one inventory row."""
    path = row["path"]
    srcs = inputs.src_rows.get(path, [])
    fr = inputs.file_rows.get(path)
    imported = {n: v for n, v in inputs.imported.get(path, {}).items() if n != EXTRACTED_FILE}
    extracted = inputs.imported.get(path, {}).get(EXTRACTED_FILE, [])
    exc_groups = [s for s in srcs if s["status"] == "exception"]
    residue = [s for s in srcs if s["status"] == "residue"]
    s6 = [c for c in inputs.candidates if c["group"] == "s6bfrl-uncommon-gems" and c.get("path") == path]
    own_ex = sorted(exc_by_file.get(path, []))
    notes = []
    if imported:
        notes.append(f"{sum(len(v) for v in imported.values())} row(s) also written by the importer")
    if extracted:
        notes.append(f"{len(extracted)} row(s) also extracted")

    def null_text(sources):
        parts = []
        for s in sorted({x["source"] for x in sources}):
            ck = inputs.checkpoints[s][1]
            parts.append(f"{s} ({ck['answer'].get('reasonCode')})")
        return "; ".join(parts)

    def checkpoints_of(sources):
        return sorted({inputs.checkpoints[s["source"]][0] for s in sources})

    # 1. exception
    if exc_groups or s6:
        n = len(exc_groups) + (1 if s6 else 0)
        names = sorted({s["source"] for s in exc_groups} | ({"reddit:s6bfrl"} if s6 else set()))
        text = f"{len(exc_groups)} citation group(s) of held sources whose numbers differ from v3's rows" if exc_groups else ""
        if s6:
            text += ("; " if text else "") + "6 uncommon-gem outputs v3 holds no row for (unverified)"
        text += ": " + ", ".join(names[:MAX_SOURCES])
        if residue:
            notes.append("also cites null-extracted source(s) " + null_text(residue))
        ptr = pointers_for(inputs, path, {"exceptions": own_ex, "sources": names[:MAX_SOURCES], "reports": ["reports/M04-links.md", "reports/M07-dispositions.md"]})
        if residue:
            ptr["checkpoints"] = checkpoints_of(residue)
        return "exception-queued", "HELD_SOURCE_NUMBERS_DIFFER", text + ("; " + "; ".join(notes) if notes else ""), ptr
    # 2. imported
    if imported:
        code = "IMPORTED_REFERENCE_PARTIAL" if row["disposition"] == "reference-imported-partial" else "IMPORTED_ROWS"
        n = sum(len(v) for v in imported.values())
        text = f"{n} row(s) written by the importer to " + ", ".join(sorted(imported))
        if code == "IMPORTED_REFERENCE_PARTIAL":
            text += " (reference tables only; the rest of the file is not observational)"
        return "imported", code, text, pointers_for(inputs, path, {"exceptions": own_ex} if own_ex else None)
    # 3. extracted
    if extracted:
        srcs_ex = sorted({s for s, (slug, ck) in inputs.checkpoints.items() if ck["status"] == "rows"
                          and any(f["path"] == path for f in ck["entry"]["files"])})
        text = f"{len(extracted)} row(s) written by extract_batch.py from " + (", ".join(srcs_ex) or "a queue source")
        ptr = pointers_for(inputs, path)
        ptr["checkpoints"] = sorted(inputs.checkpoints[s][0] for s in srcs_ex)
        if own_ex:
            ptr["exceptions"] = own_ex
        if residue:
            text += "; also cites null-extracted source(s) " + null_text(residue)
        return "extracted", "EXTRACTED_ROWS", text, ptr
    # 4. null extraction
    if residue:
        text = "source(s) read in M04.3 with no usable cohort: " + null_text(residue)
        return "extracted-null", "EXTRACTED_NULL", text, {"checkpoints": checkpoints_of(residue),
                                                          "sources": sorted({s["source"] for s in residue}),
                                                          "reports": ["reports/M04-extraction.md"]}
    # 5. linked / disposed by the linker
    if fr and fr["outcome"] == "linked":
        counts = fr["statusCounts"]
        code = "LINKED_NUMBERS_MATCH" if counts.get("linked") else ("LINKED_SOURCES_HELD" if counts.get("source-held") else "LINKED_STUDY_IDS")
        recs = sorted({r["id"] for s in srcs if s["status"] in ("linked", "source-held") for r in s["records"] if r.get("id")})
        ptr = {"reports": ["reports/M04-links.md"], "sources": sorted({s["source"] for s in srcs if s["status"] in ("linked", "source-held")})[:MAX_SOURCES]}
        if recs:
            ptr["recordIDs"], ptr["recordCount"] = recs[:MAX_IDS], len(recs)
        st = sorted({s["studyId"] for s in inputs_study_rows(inputs, path)})
        if st:
            ptr["studyIDs"] = st[:MAX_IDS]
        return "linked", code, fr["reason"], ptr
    if fr and fr["outcome"] == "disposed":
        if not sum(fr["statusCounts"].values()) and not fr["studyIds"]:
            return "process-artifact", "NO_SOURCE_AUDIT_OR_REPORT", \
                "no source URL and no v3 study ID: an audit, coverage, score or report table (or a note) that cites nothing to link", \
                {"reports": ["reports/M04-links.md"]}
        reasons = sorted({s["reason"] for s in srcs})
        return "reference-only", "ONLY_REFERENCE_OR_DECIDED_SKIPS", fr["reason"] + (": " + short(reasons[0], 200) if reasons else ""), \
            {"reports": ["reports/M04-links.md"], "sources": sorted({s["source"] for s in srcs})[:MAX_SOURCES]}
    # 6. files the linker never read
    d = row["disposition"]
    if d == "process-artifact":
        return "process-artifact", "PROCESS_ARTIFACT", f"{row['category']}: tests, tools, prompts, QA feedback or coordination", {}
    if d == "derived-model":
        return "derived-model", "DERIVED_MODEL", "statistical model output (derived, not an observation)", {}
    if d == "mechanics-knowledge":
        return "mechanics-knowledge", "MECHANICS_KNOWLEDGE", "mechanics registry: feeds mechanics.md (Master-owned), not estimates", {}
    why = inputs.importer_reason.get(path, "")
    if why.startswith("process artifact"):
        return "process-artifact", "PROCESS_ARTIFACT_IMPORTER_REASON", "M03b: " + why, {"reports": ["reports/M03b-import.md"]}
    if row["category"] in AUDIT_CATEGORIES and AUDIT_NAME.search(os.path.basename(path)) and d != "no-observational-content":
        return "process-artifact", "FIELD_AUDIT_BY_NAME", \
            "field audit, validation or score table (by file name): scores and derived values about TSM/GameData keys, not observations", {}
    cites = scans.get(path)
    if d == "no-observational-content" and row["category"] != "v2-source-review":
        return "no-observational-content", "NO_OBSERVATIONAL_CONTENT", "no numbers and no URL v3 lacks", {}
    if cites is not None and d in ("source-links-only", "no-observational-content"):
        status = {}
        for c in cites:
            status[c["key"]] = c["status"] if status.get(c["key"]) in (None, c["status"]) else \
                min(status[c["key"]], c["status"], key=KEY_ORDER.index)
        for k in (clean_key(k) for k in row.get("urlsNotInV3") or []):   # shorthand keys (reddit:abc) the citation reader does not see
            if k not in status:
                status[k] = ls.classify({"key": k, "observational": False, "numbers": set()}, index)["status"]
        unheld = sorted(k for k, v in status.items() if v in ("lead-only", "residue"))
        held = sorted(k for k, v in status.items() if v in ("source-held", "linked"))
        nulls = [k for k in unheld if k in inputs.checkpoints and inputs.checkpoints[k][1]["status"] == "null"]
        if nulls:
            rest = len(unheld) - len(nulls)
            codes = "; ".join(f"{k} ({inputs.checkpoints[k][1]['answer'].get('reasonCode')})" for k in nulls)
            return "extracted-null", "EXTRACTED_NULL", "source(s) read in M04.3 with no usable cohort: " + codes + \
                (f"; also cites {rest} other lead(s)" if rest else ""), \
                {"checkpoints": sorted(inputs.checkpoints[k][0] for k in nulls), "sources": nulls[:MAX_SOURCES],
                 "reports": ["reports/M04-extraction.md"]}
        if unheld:
            return "source-links-only", "SOURCE_LINKS_ONLY", \
                f"cites {len(unheld)} source(s) v3 does not hold, with no count beside them (leads in url-registry.jsonl)", \
                dict({"sources": unheld[:MAX_SOURCES], "registry": "manifest/url-registry.jsonl"},
                     **({"scopeGap": [k for k in unheld if k in SCOPE_GAP_DECISIONS]} if any(k in SCOPE_GAP_DECISIONS for k in unheld) else {}))
        if held:
            return "held-sources-only", "ALL_CITED_SOURCES_HELD", \
                f"no observational numbers; all {len(held)} non-reference source(s) it cites are held by v3 (the agents' own review)", \
                {"sources": held[:MAX_SOURCES]}
        if status:
            return "reference-only", "ONLY_REFERENCE_OR_DECIDED_SKIPS", "cites only reference hosts or sources M03 decided to skip", {}
        return "no-observational-content", "NO_OBSERVATIONAL_CONTENT", "no citations and no numbers", {}
    if d == "source-links-only":
        return "source-links-only", "SOURCE_LINKS_ONLY", "cites URLs v3 lacks, no observational numbers (format not read by the linker)", \
            {"registry": "manifest/url-registry.jsonl"}
    raise ValueError(f"no rule for {path} ({d})")


def inputs_study_rows(inputs, path):
    return [r for r in inputs.links if r["kind"] == "study" and r["path"] == path]


# ------------------------------------------------------------------ build
def build(root, rows, raw_rows=None):
    inputs = Inputs(root)
    index = ls.V3Index(rows, raw_rows)
    scans = scan_citations(root, inputs.inventory, index)
    exceptions = build_exceptions(inputs, index)
    exc_by_file = collections.defaultdict(list)
    for e in exceptions:
        for f in e["files"]:
            exc_by_file[f].append(e["id"])
    gap = scope_gap(inputs, scans, index)
    dispositions = []
    for row in sorted(inputs.inventory, key=lambda r: r["path"]):
        sha = sha256_of(os.path.join(root, row["path"]))
        disposition, code, text, ptr = decide(row, inputs, scans, exc_by_file, index)
        gaps = sorted({g["source"] for g in gap if row["path"] in g["files"] and g["decision"] == "reasoned-disposition"})
        if gaps:
            ptr = dict(ptr, scopeGap=gaps)
        own_ex = sorted(exc_by_file.get(row["path"], []))
        if own_ex and "exceptions" not in ptr:
            ptr = dict(ptr, exceptions=own_ex)
        dispositions.append({"path": row["path"], "sha256": sha, "sha256InInventory": sha == row["sha256"],
                             "category": row["category"], "format": row["format"], "inventoryDisposition": row["disposition"],
                             "disposition": disposition, "reason": {"code": code, "text": text}, "pointers": ptr})
    return dispositions, exceptions, gap, summarize(dispositions, exceptions, gap, inputs)


def summarize(dispositions, exceptions, gap, inputs):
    by = collections.Counter(d["disposition"] for d in dispositions)
    by_code = collections.Counter((d["disposition"], d["reason"]["code"]) for d in dispositions)
    cross = collections.defaultdict(collections.Counter)
    for d in dispositions:
        cross[d["inventoryDisposition"]][d["disposition"]] += 1
    cat = collections.defaultdict(collections.Counter)
    for d in dispositions:
        cat[d["category"]][d["disposition"]] += 1
    return {
        "files": len(dispositions),
        "byDisposition": dict(sorted(by.items())),
        "byDispositionAndCode": {f"{k[0]} / {k[1]}": v for k, v in sorted(by_code.items())},
        "byInventoryDisposition": {k: dict(sorted(v.items())) for k, v in sorted(cross.items())},
        "byCategory": {k: dict(sorted(v.items())) for k, v in sorted(cat.items())},
        "sha256Mismatches": [d["path"] for d in dispositions if not d["sha256InInventory"]],
        "exceptions": {"total": len(exceptions), "byKind": dict(sorted(collections.Counter(e["kind"] for e in exceptions).items())),
                       "recordsNamed": len({i for e in exceptions for i in e["recordIDs"]})},
        "scopeGap": {"sources": len(gap), "byDecision": dict(sorted(collections.Counter(g["decision"] for g in gap).items())),
                     "outOfScopeSources": sum(1 for g in gap if "out-of-scope" in g["scope"]),
                     "inScopeSources": sum(1 for g in gap if "in-scope" in g["scope"]),
                     "undecided": [g["source"] for g in gap if g["decision"] == "UNDECIDED"]},
        "nullExtractionFiles": sum(1 for d in dispositions if d["disposition"] == "extracted-null"),
    }


def outputs(dispositions, exceptions, gap, summary):
    return {"dispositions.jsonl": dispositions, "exceptions.jsonl": exceptions, "scope-gap.jsonl": gap,
            "dispositions-summary.json": summary}


def write(out_dir, dispositions, exceptions, gap, summary):
    os.makedirs(out_dir, exist_ok=True)
    dump(os.path.join(out_dir, "dispositions.jsonl"), dispositions)
    dump(os.path.join(out_dir, "exceptions.jsonl"), exceptions)
    dump(os.path.join(out_dir, "scope-gap.jsonl"), gap)
    with open(os.path.join(out_dir, "dispositions-summary.json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump(summary, f, indent=1, sort_keys=True, ensure_ascii=False)
        f.write("\n")


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--out-dir", default=os.path.join(ROOT, MANIFEST))
    ap.add_argument("--check", action="store_true", help="compare with the committed files instead of writing")
    args = ap.parse_args(argv)
    import build_estimates as be
    rows = be.load()
    dispositions, exceptions, gap, summary = build(ROOT, rows, ls.load_raw_agent_rows(ROOT))
    if summary["scopeGap"]["undecided"]:
        print("UNDECIDED scope-gap sources:", ", ".join(summary["scopeGap"]["undecided"]), file=sys.stderr)
        return 1
    if args.check:
        bad = []
        tmp = os.path.join(args.out_dir, ".check")
        write(tmp, dispositions, exceptions, gap, summary)
        for name in outputs(dispositions, exceptions, gap, summary):
            with open(os.path.join(tmp, name), "rb") as a, open(os.path.join(args.out_dir, name), "rb") as b:
                if a.read() != b.read():
                    bad.append(name)
            os.remove(os.path.join(tmp, name))
        os.rmdir(tmp)
        print("identical to the committed files" if not bad else "DIFFERS: " + ", ".join(bad))
        return 1 if bad else 0
    write(args.out_dir, dispositions, exceptions, gap, summary)
    print(f"{summary['files']} files: {summary['byDisposition']}; {summary['exceptions']['total']} exceptions; "
          f"{summary['scopeGap']['sources']} scope-gap sources")
    return 0


if __name__ == "__main__":
    sys.exit(main())
