#!/usr/bin/env python3
"""M04.1 / M04.2: deterministic linking of historical notes to v3 evidence, then the residual queue.

For every file the inventory marks candidate-unmigrated, candidate-no-url or covered-by-url, find each cited
source URL (normalized with source_keys.normalize_url), each v3 study ID and the numbers next to each
citation, and compare them with what v3 holds *now* (agent evidence and imported rows, corrections applied):

  same source, a result number matches      -> linked
  same source, observational count differs   -> exception   (listed, never imported)
  same source, nothing to compare            -> source-held (counts as linked, nothing to extract)
  source not in v3, observational numbers    -> residue     (grouped by source in extraction-queue.jsonl)
  everything else                            -> skipped-decided / reference / lead-only (with a reason)

Read-only on evidence. Writes only manifest/links.jsonl, manifest/extraction-queue.jsonl and
manifest/links-summary.json, sorted and without timestamps, so a rerun is byte-identical.
No AI, no network, nothing is invented: every number in the output is read from a file.

Matching rules (tests in tests/test_link_sources.py):
  * Numbers are read from the citation's window: the line with the URL plus up to two neighbouring lines of the same
    paragraph (never across a blank line, a heading or another source's URL); a table or CSV row is its own window;
    in JSON the window is the claim object (the object holding the URL, as in the M03 importer).
  * Only "telling" numbers count (not 0, 1 or a whole number up to 5), dates and bare years are ignored, 0-1
    fractions also match as percentages. Hyphenated ranges ("1-2") keep only the first number.
  * A link needs a *result* number of a held row from the same source (totalQuantity, castsWithDrop, percentShown,
    averageShown, minSeen, maxSeen, giveCount, getCount, outputCount). Matching only the batch size (casts,
    inputsProcessed) is not a link: many cohorts share 1,000 ore.
  * "Observational" means the window holds a count with a unit (casts, ore, herbs...) in text, or study fields in JSON.
  * Held means a v3 record's own source (source.url, originalSource, sourceURL) has the same normalized key, or the
    same thread (forum post, Reddit comment and Wowhead comment anchors dropped). A URL only mentioned in notes is not held.

Usage, from the repository root:
  python3 research/v3/migration/tools/link_sources.py [--out-dir research/v3/migration/manifest]
"""
import argparse
import collections
import csv
import hashlib
import io
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "research", "v3", "tools"))
sys.path.insert(0, HERE)
from source_keys import normalize_url  # noqa: E402
import import_existing as ie  # noqa: E402
import inventory as inv  # noqa: E402

SCOPE = ("candidate-unmigrated", "candidate-no-url", "covered-by-url")
RESULT_FIELDS = ("totalQuantity", "castsWithDrop", "percentShown", "averageShown", "minSeen", "maxSeen",
                 "giveCount", "getCount", "outputCount")
DENOMINATOR_FIELDS = ("casts", "inputsProcessed")
STATUS_ORDER = ("residue", "exception", "linked", "source-held", "skipped-decided", "reference", "lead-only")
LINKED_STATUSES = ("linked", "source-held")
MAX_RECORDS = 10          # record references listed per link
MAX_ANCHORS = 12          # anchors listed per file and source in the queue
EXTRA_REFERENCE_HOSTS = ("json-schema.org", "wowpedia.fandom.com", "wowpedia.org")   # not cohorts (checked MIG-006)
MAX_LOOSE_SOURCES = 3     # a file with more unheld, number-free sources is a source list: counts cannot be attributed
INDEX_MARKER = "link or place it after a cohort check"   # note text on the agent-held name-only rows (M03.1)

_DATE = re.compile(r"\b\d{4}-\d{2}-\d{2}\b|\b\d{1,2}:\d{2}\b")
_NUM = re.compile(r"(?<![\w.#=/:-])(\d{1,3}(?:,\d{3})+|\d+)(\.\d+)?\s?(%|[kK]\b)?")
_UNIT = re.compile(r"\s*(x\s*)?(casts?|prospects?|mills?|millings?|ore|herbs?|operations?|disenchants?|crafts?|stacks?|clicks?)\b", re.I)
_TOKEN = re.compile(r"[A-Za-z0-9][A-Za-z0-9._-]{7,}")


# ---------------------------------------------------------------- numbers
def text_numbers(text):
    """Every number written in a piece of text (URLs, dates and bare years removed), as floats."""
    text = _DATE.sub(" ", inv.URL_RE.sub(" ", text))
    out = set()
    for m in _NUM.finditer(text):
        value = float((m.group(1).replace(",", "")) + (m.group(2) or ""))
        if m.group(3) in ("k", "K"):
            value *= 1000
        elif 2004 <= value <= 2030 and value == int(value) and "," not in m.group(1) and not m.group(3) \
                and not _UNIT.match(text[m.end():m.end() + 24]):
            continue   # a year
        out.add(round(value, 6))
    return out


def telling_set(values):
    return {v for v in values if ie.telling(v)}


def with_fractions(values):
    """A 0-1 fraction is also read as a percentage (0.125 matches percentShown 12.5)."""
    return values | {round(v * 100, 6) for v in values if 0 < v < 1}


def record_numbers(r):
    def pick(fields):
        return telling_set({round(float(ie.num(r[f])), 6) for f in fields if ie.num(r.get(f)) is not None})
    return pick(RESULT_FIELDS), pick(DENOMINATOR_FIELDS)


# ---------------------------------------------------------------- the v3 index
def source_keys_of(r):
    s = r.get("source") if isinstance(r.get("source"), dict) else {}
    out = set()
    for u in (s.get("url"), r.get("originalSource"), r.get("sourceURL")):
        if isinstance(u, str) and u.startswith("http"):
            out.add(normalize_url(u))
    return out


def compact(name):
    return re.sub(r"[^a-z0-9]", "", str(name).lower())


class V3Index:
    """What v3 holds now, built from effective rows (build_estimates.load(): corrections and replaces applied)."""

    def __init__(self, rows, raw_rows=None):
        """rows: effective records. raw_rows: every agent record as written (before replaces and corrections), used only
        to link imported name-only rows to what agents recorded; each is flagged `effective`."""
        self.raw_by_key = collections.defaultdict(list)
        self.raw_by_thread = collections.defaultdict(list)
        self.by_key = collections.defaultdict(list)
        self.by_thread = collections.defaultdict(list)
        self.mentions = set()
        self.by_study = collections.defaultdict(list)
        self.id_name = {}
        self.names = collections.defaultdict(lambda: collections.defaultdict(set))   # evidence dir -> compact name -> {(id, name)}
        self.rows = rows
        for r in rows:
            f = r.get("_file", "")
            res, den = record_numbers(r)
            rec = {"id": r.get("id"), "studyKey": r.get("studyKey"), "file": f, "type": r.get("type"),
                   "imported": "/evidence/imported/" in f, "res": res, "den": den, "row": r,
                   "from": (r.get("migratedFrom") or {}).get("path") if isinstance(r.get("migratedFrom"), dict) else None}
            for k in source_keys_of(r):
                self.by_key[k].append(rec)
                self.by_thread[ie.thread_of(k)].append(rec)
            for text in (r.get("notes"), r.get("quote")):
                if isinstance(text, str):
                    self.mentions.update(normalize_url(u) for u in inv.URL_RE.findall(text) if not inv.is_self_link(u))
            for v in (r.get("studyKey"), r.get("id")):
                if isinstance(v, str) and len(v) >= 8:
                    self.by_study[v].append(rec)
            self._names(r)
        effective = {(r.get("_file"), r.get("id")) for r in rows}
        for r in (raw_rows if raw_rows is not None else [r for r in rows if "/evidence/imported/" not in r.get("_file", "")]):
            res, den = record_numbers(r)
            rec = {"id": r.get("id"), "studyKey": r.get("studyKey"), "file": r.get("_file", ""), "type": r.get("type"),
                   "imported": False, "res": res, "den": den, "row": r,
                   "effective": (r.get("_file"), r.get("id")) in effective, "from": None}
            for k in source_keys_of(r):
                self.raw_by_key[k].append(rec)
                self.raw_by_thread[ie.thread_of(k)].append(rec)
            self._names(r, pool=False)

    def _names(self, r, pool=True):
        area = r.get("_file", "").split("/evidence/")[-1].split("/")[0] if "/evidence/" in r.get("_file", "") else ""
        for idk, nk in (("inputItemID", "inputName"), ("outputItemID", "outputName")):
            if r.get(idk) and r.get(nk):
                self.id_name.setdefault(r[idk], r[nk])
                if pool:   # label resolution reads effective rows only: corrections fix wrong IDs in the raw ones
                    self.names[area][compact(r[nk])].add((r[idk], r[nk]))
                    self.names[""][compact(r[nk])].add((r[idk], r[nk]))

    def raw_agent(self, key):
        exact = self.raw_by_key.get(key) or []
        thread = self.raw_by_thread.get(ie.thread_of(key)) or []
        return list(exact) + [r for r in thread if not any(r is e for e in exact)]

    def held(self, key):
        """(level, records) for a source this index holds records from, else None."""
        exact = self.by_key.get(key) or []
        thread = self.by_thread.get(ie.thread_of(key)) or []
        recs = list(exact) + [r for r in thread if not any(r is e for e in exact)]
        if not recs:
            return None
        return ("exact" if exact else "thread"), recs


def ref(rec):
    out = {"id": rec["id"], "studyKey": rec["studyKey"], "file": rec["file"], "imported": rec["imported"]}
    if "effective" in rec:
        out["effective"] = rec["effective"]
    return out


def refs(recs):
    out = sorted((ref(r) for r in recs), key=lambda x: (str(x["file"]), str(x["id"])))
    return out[:MAX_RECORDS]


# ---------------------------------------------------------------- citations
def has_study_fields(obj):
    if isinstance(obj, dict):
        if any(obj.get(k) not in (None, "", [], {}) for k in inv.STUDY_KEYS & obj.keys()):
            return True
        return any(has_study_fields(v) for v in obj.values())
    if isinstance(obj, list):
        return any(has_study_fields(v) for v in obj)
    return False


def _urls_in(line):
    return [(u, normalize_url(u)) for u in inv.URL_RE.findall(line) if not inv.is_self_link(u)]


def text_citations(text, fmt):
    """One citation per (line, source key). Window rule in the module docstring."""
    lines = text.splitlines()
    out = []
    # carry[j]: the source key of the nearest URL at or above line j in its paragraph (a number line under a list item
    # belongs to that item's source, not to the next item's)
    carry, last = [], None
    for line in lines:
        if not line.strip() or line.lstrip().startswith("#"):
            last = None
        else:
            keys = [k for _, k in _urls_in(line)]
            if keys:
                last = keys[-1]
        carry.append(last)
    for i, line in enumerate(lines):
        seen = set()
        for raw, key in _urls_in(line):
            if key in seen:
                continue
            seen.add(key)
            lo = hi = i
            if fmt != "csv" and not line.lstrip().startswith("|"):
                def usable(j):
                    s = lines[j]
                    return (s.strip() and not s.lstrip().startswith("#") and not s.lstrip().startswith("|")
                            and all(k == key for _, k in _urls_in(s)) and carry[j] in (None, key))
                while lo > i - 2 and lo - 1 >= 0 and usable(lo - 1):
                    lo -= 1
                while hi < i + 2 and hi + 1 < len(lines) and usable(hi + 1):
                    hi += 1
            window = lines[lo:hi + 1]
            obs = [j for j in range(lo, hi + 1) if inv.MD_NUMERIC.search(lines[j])]
            nums = telling_set(text_numbers("\n".join(window)))
            anchor_lines = obs or [j for j in range(lo, hi + 1) if telling_set(text_numbers(lines[j]))]
            out.append({
                "key": key, "raw": raw, "where": i + 1, "observational": bool(obs), "numbers": nums,
                "text": "\n".join(window),
                "anchors": [{"line": j + 1, "text": lines[j].strip()[:240],
                             "numbers": sorted(telling_set(text_numbers(lines[j])))[:8]} for j in anchor_lines][:MAX_ANCHORS],
            })
    return out


def jsonl_citations(text):
    out = []
    for n, line in enumerate(text.splitlines(), 1):
        if not line.strip():
            continue
        try:
            obj = json.loads(line)
        except json.JSONDecodeError:
            continue
        for c in json_citations_of(obj, f"line {n}"):
            out.append(c)
    return out


def json_citations_of(obj, base):
    out = []
    for jpath, key, claim in ie.claims_in(obj, base):
        if key is None:
            continue
        fields = sorted(inv.STUDY_KEYS & claim.keys()) if isinstance(claim, dict) else []
        out.append({
            "key": key, "raw": None, "where": jpath, "observational": has_study_fields(claim),
            "numbers": telling_set(ie.numbers_in(claim)),
            "text": json.dumps(claim, sort_keys=True, ensure_ascii=False)[:2000],
            "anchors": [{"path": jpath, "studyFields": fields}],
        })
    return out


def file_level_anchors(text, ext):
    """Lines of a Markdown/CSV/text file that state an observational count (number plus unit), wherever they are."""
    if ext in (".json", ".jsonl"):
        return []
    return [{"line": n, "text": line.strip()[:240], "numbers": sorted(telling_set(text_numbers(line)))[:8]}
            for n, line in enumerate(text.splitlines(), 1) if inv.MD_NUMERIC.search(line)]


def raw_urls_of(text):
    return sorted({u for u, _ in _urls_in(text)})


def study_ids_in(text, index):
    """v3 study keys and record IDs written anywhere in the file (whole tokens of 8+ characters)."""
    found = set()
    for tok in _TOKEN.findall(inv.URL_RE.sub(" ", text)):
        tok = tok.rstrip("._-")
        if tok in index.by_study:
            found.add(tok)
    return sorted(found)


# ---------------------------------------------------------------- classification
def classify(cite, index):
    """Status of one citation against the index. Returns a dict with status, reason and evidence."""
    key, obs = cite["key"], cite["observational"]
    nums = with_fractions(cite["numbers"])
    held = index.held(key)
    if held:
        level, recs = held
        results = set().union(*(r["res"] for r in recs))
        denominators = set().union(*(r["den"] for r in recs))
        hit = sorted(nums & results)
        den_hit = sorted(nums & denominators)
        if hit:
            matched_recs = [r for r in recs if r["res"] & nums]
            strong = len(hit) >= 2 or hit[0] >= 100 or hit[0] != int(hit[0])
            return {"status": "linked", "level": level, "matched": hit, "denominatorMatched": den_hit,
                    "strength": "strong" if strong else "weak", "records": refs(matched_recs),
                    "recordCount": len(matched_recs),
                    "reason": f"v3 holds this source ({level} match) and {len(hit)} result number(s) match a held row"}
        others = sorted(nums - denominators)
        if obs and others:
            return {"status": "exception", "level": level, "matched": [], "denominatorMatched": den_hit,
                    "records": refs(recs), "recordCount": len(recs),
                    "reason": "v3 holds this source but none of the citation's numbers is a held result"
                              + (" (the batch size matches)" if den_hit else "")}
        return {"status": "source-held", "level": level, "matched": [], "denominatorMatched": den_hit,
                "records": refs(recs), "recordCount": len(recs),
                "reason": "v3 holds this source; the citation carries no observational count to compare"
                          + (" (only the batch size)" if den_hit and obs else "")}
    mention = key in index.mentions
    decision = ie.NEW_SOURCES.get(key) or ie.NEW_SOURCES.get(ie.thread_of(key))
    base = {"level": None, "matched": [], "v3Mentions": mention}
    if decision and decision[0] == "skip":
        return dict(base, status="skipped-decided", reason="M03 decision: " + decision[1])
    if ie.is_reference_link(key) or key.split("/")[0] in EXTRA_REFERENCE_HOSTS:
        return dict(base, status="reference", reason="reference host (identity, prices, patch notes, API or schema docs), never a cohort")
    if key.startswith("wowhead:/"):
        return dict(base, status="reference", reason="URL template or path without an entity ID, not a source")
    if ie.WOWHEAD_IDENTITY.match(key) and "#c" not in key and not obs:
        return dict(base, status="reference", reason="Wowhead entity page cited for identity, no observational count nearby")
    if obs:
        why = "source not in v3; observational numbers next to the citation"
        if decision and decision[0] == "import":
            why = "M03 mapper listed this source but v3 holds no row from it"
        if mention:
            why += " (v3 notes mention it without recording it)"
        return dict(base, status="residue", reason=why)
    return dict(base, status="lead-only", reason="source not in v3; no observational count next to the citation (a lead, not a cohort)")


# ---------------------------------------------------------------- one file
def read_file(root, rel):
    with open(os.path.join(root, rel), "rb") as f:
        data = f.read()
    return data, hashlib.sha256(data).hexdigest()


def citations_for(rel, text):
    ext = os.path.splitext(rel)[1].lower()
    if ext == ".jsonl":
        return jsonl_citations(text)
    if ext == ".json":
        try:
            return json_citations_of(json.loads(text), "$")
        except json.JSONDecodeError:
            return text_citations(text, "txt")
    return text_citations(text, "csv" if ext == ".csv" else "md")


def link_file(root, row, index):
    """(source link entries, study link entries, file entry, residue pieces) for one inventory row."""
    rel = row["path"]
    data, sha = read_file(root, rel)
    text = data.decode("utf-8", errors="replace")
    cites = citations_for(rel, text)
    groups = collections.OrderedDict()
    for c in cites:
        verdict = classify(c, index)
        gkey = (c["key"], verdict["status"])
        g = groups.setdefault(gkey, {"verdict": verdict, "cites": []})
        g["cites"].append(c)
    file_obs = file_level_anchors(text, os.path.splitext(rel)[1].lower())
    lead_sources = {k for (k, st) in groups if st == "lead-only"}
    loose = bool(file_obs) and 0 < len(lead_sources) <= MAX_LOOSE_SOURCES
    sources, residue = [], []
    for (key, status), g in sorted(groups.items()):
        v, cs = g["verdict"], g["cites"]
        if status == "lead-only" and loose:
            status = "residue"
            v = dict(v, reason="source not in v3; the file holds observational counts, but not next to this citation "
                              "(file-level anchors, M04.3 decides whether they belong to it)")
        entry = {"kind": "source", "path": rel, "sha256": sha, "source": key, "status": status, "reason": v["reason"],
                 "lines": [c["where"] for c in cs], "matchLevel": v.get("level"),
                 "matched": v.get("matched", []), "denominatorMatched": v.get("denominatorMatched", []),
                 "claimNumbers": sorted(set().union(*(c["numbers"] for c in cs)))[:40],
                 "records": v.get("records", []), "recordCount": v.get("recordCount", 0),
                 "rawUrls": sorted({c["raw"] for c in cs if c["raw"]}), "v3Mentions": bool(v.get("v3Mentions"))}
        if "strength" in v:
            entry["strength"] = v["strength"]
        if status == "residue":
            near = g["verdict"]["status"] == "residue"
            anchors = [a for c in cs for a in c["anchors"]] if near else file_obs
            entry["proximity"] = "citation" if near else "file"
            residue.append({"source": key, "path": rel, "sha256": sha, "rawUrls": entry["rawUrls"],
                            "anchors": anchors[:MAX_ANCHORS], "anchorCount": len(anchors),
                            "proximity": entry["proximity"], "v3Mentions": entry["v3Mentions"],
                            "text": "\n".join(c["text"] for c in cs) if near else "\n".join(a["text"] for a in file_obs)})
        sources.append(entry)
    studies = []
    for sid in study_ids_in(text, index):
        recs = index.by_study[sid]
        studies.append({"kind": "study", "path": rel, "sha256": sha, "studyId": sid, "status": "linked",
                        "reason": "v3 study key or record ID named in the file", "records": refs(recs),
                        "recordCount": len(recs)})
    counts = collections.Counter(e["status"] for e in sources)
    counts.update(e["status"] for e in studies)
    outcome, reason = file_outcome(counts, row)
    file_entry = {"kind": "file", "path": rel, "sha256": sha, "sha256InInventory": row.get("sha256") == sha,
                  "category": row["category"], "format": row["format"], "inventoryDisposition": row["disposition"],
                  "outcome": outcome, "reason": reason,
                  "statusCounts": {k: counts[k] for k in STATUS_ORDER if counts.get(k)},
                  "sources": len({e["source"] for e in sources}), "studyIds": len(studies)}
    return sources, studies, file_entry, residue


def file_outcome(counts, row):
    if counts.get("residue"):
        return "residue", f"{counts['residue']} citation group(s) of sources v3 does not hold, with observational numbers"
    if counts.get("exception"):
        return "exception", f"{counts['exception']} citation group(s) of held sources whose numbers differ from v3's rows"
    if counts.get("linked") or counts.get("source-held"):
        n = counts.get("linked", 0)
        return "linked", (f"{n} citation(s) matched held numbers" if n else "every cited source is held by v3; nothing to compare")
    if not sum(counts.values()):
        if row["disposition"] == "candidate-no-url":
            return "disposed", "no source URL and no v3 study ID in the file: coverage, audit or report table, nothing to link (final disposition in M07)"
        return "disposed", "no usable citation found"
    parts = [f"{counts[k]} {k}" for k in ("skipped-decided", "reference", "lead-only") if counts.get(k)]
    return "disposed", "only " + ", ".join(parts) + " citations"


# ---------------------------------------------------------------- residual queue (M04.2)
TYPE_HINTS = (
    ("rateChange", re.compile(r"hotfix|nerf|buff|patch note|changed from|used to be|rate change", re.I)),
    ("recipe", re.compile(r"recipe|reagent|requires \d|needs \d", re.I)),
    ("condition", re.compile(r"unlock|specializ|knowledge|requires?\b", re.I)),
    ("noDisenchant", re.compile(r"cannot be disenchanted|not disenchantable|no disenchant", re.I)),
    ("token", re.compile(r"wow token|gear token|\btokens?\b", re.I)),
    ("exchange", re.compile(r"vendor|trade-in|exchange|convert|shatter", re.I)),
)
METHOD_HINTS = (
    ("Prospect", re.compile(r"prospect|\bore\b|gem", re.I)),
    ("Mill", re.compile(r"\bmill|herb|pigment|\bink\b", re.I)),
    ("Disenchant", re.compile(r"disenchant", re.I)),
    ("Smelt", re.compile(r"smelt|\bbar\b|ingot", re.I)),
)


def expected_types(text):
    found = {"drop"}
    found.update(t for t, rx in TYPE_HINTS if rx.search(text))
    return sorted(found)


def method_hints(text):
    return [m for m, rx in METHOD_HINTS if rx.search(text)]


def build_queue(residue_pieces, categories):
    by_source = collections.defaultdict(list)
    for p in residue_pieces:
        by_source[p["source"]].append(p)
    queue = []
    for source in sorted(by_source):
        pieces = sorted(by_source[source], key=lambda p: p["path"])
        blob = "\n".join(p["text"] for p in pieces)
        queue.append({
            "source": source,
            "rawUrls": sorted({u for p in pieces for u in p["rawUrls"]}),
            "fileCount": len(pieces),
            "files": [{"path": p["path"], "sha256": p["sha256"], "category": categories.get(p["path"]),
                       "proximity": p["proximity"], "anchorCount": p["anchorCount"], "anchors": p["anchors"]} for p in pieces],
            "expectedTypes": expected_types(blob),
            "methodHints": method_hints(blob),
            "v3Mentions": any(p["v3Mentions"] for p in pieces),
            "note": "hints for M04.3 only; extract numbers present in the quoted text, null on doubt",
        })
    return queue


# ---------------------------------------------------------------- known link candidates (step 3)
def agent_rows(index, key):
    """Every agent record from the source as written, including those corrections.jsonl excludes as duplicates."""
    return index.raw_agent(key) if key else []


def agent_name(rec, index):
    r = rec["row"]
    return r.get("outputName") or index.id_name.get(r.get("outputItemID")) or ""


def name_only_candidates(index):
    """The imported name-only rows an agent already holds (by URL or by numbers): link each to the agent rows."""
    out = []
    pool = [r for r in index.rows if r.get("rawOutputName") and not r.get("outputItemID")
            and INDEX_MARKER in (r.get("notes") or "") and "/evidence/imported/" in r.get("_file", "")]
    agent_all = [rec for recs in index.raw_by_key.values() for rec in recs]
    for r in sorted(pool, key=lambda x: str(x["id"])):
        key = next(iter(sorted(source_keys_of(r))), None)
        total = ie.num(r.get("totalQuantity"))
        name = compact(r["rawOutputName"])
        via_url = bool(agent_rows(index, key))
        rows = agent_rows(index, key) if via_url else [
            rec for rec in agent_all if ie.num(rec["row"].get("totalQuantity")) == total
            and compact(agent_name(rec, index)) == name]
        same = [rec for rec in rows if compact(agent_name(rec, index)) == name]
        exact = [rec for rec in same if ie.num(rec["row"].get("totalQuantity")) == total]
        sums = None
        if not exact and len(same) >= 2 and total is not None:
            tot = [ie.num(rec["row"].get("totalQuantity")) for rec in same]
            if None not in tot and sum(tot) == total:
                sums = same
        casts = ie.num(r.get("casts"))
        same_cohort = [rec for rec in same if casts is None or ie.num(rec["row"].get("casts")) in (None, casts)]
        weak = [rec for rec in rows if ie.num(rec["row"].get("totalQuantity")) == total and rec not in same]
        if exact:
            status, why, linked = "linked", "an agent row has the same output and total (S17 copy)", exact
        elif sums:
            status, why, linked = "linked", "the total equals the sum of the agent's rows for this output (ranks)", sums
        elif same_cohort:
            status, why, linked = "exception", "an agent row names this output with the same cast count and other totals: " + \
                ", ".join(sorted({f"{ie.num(rec['row'].get('totalQuantity')):g}" for rec in same_cohort
                                  if ie.num(rec['row'].get("totalQuantity")) is not None})), same_cohort
        elif weak and (ie.num(r.get("casts")) in (None, ie.num(weak[0]["row"].get("casts")))):
            status, why, linked = "linked", "an agent row has the same total under another output label: " + \
                ", ".join(sorted({agent_name(rec, index) or "(no name)" for rec in weak})), weak
        elif same:
            status, why, linked = "unlinked", "agents record this output only for other cohort sizes (casts " + \
                ", ".join(sorted({f"{ie.num(rec['row'].get('casts')):g}" for rec in same if ie.num(rec['row'].get('casts')) is not None})) + \
                "), not this one", []
        else:
            status, why, linked = "unlinked", "agents recorded this source but no row with this output name or total (a cohort or output they did not record)", []
        if linked and status == "linked" and not any(rec["effective"] for rec in linked):
            why += "; the agent rows are excluded by corrections.jsonl as duplicates of the import"
        out.append({"kind": "candidate", "group": "nameOnlyRow", "id": r["id"], "studyKey": r.get("studyKey"),
                    "source": key, "output": r["rawOutputName"], "total": total, "casts": ie.num(r.get("casts")),
                    "heldBy": "url" if via_url else "numbers", "status": status, "reason": why,
                    "agentRecords": refs(linked), "agentRecordCount": len(linked)})
    return out


AREA_WORDS = (("midnight", "midnight"), ("war-within", "war-within"), ("warwithin", "war-within"),
              ("dragonflight", "dragonflight"), ("legacy", "legacy"))


def area_hint(path):
    p = (path or "").lower()
    return next((a for w, a in AREA_WORDS if w in p), "")


def resolve_label(label, index, area, ore=False):
    """Item IDs a short source label can mean among v3's names for that expansion: the label as the end of a name."""
    want = compact(label)
    if not want:
        return []
    flawless = want.startswith("flawless")
    base = want[len("flawless"):] if flawless else want
    pool = index.names.get(area) or index.names[""]
    hits = set()
    for cname, items in pool.items():
        if cname.endswith(base) and cname.startswith("flawless") == flawless and cname != base:
            hits.update(items)
        elif cname == base and not flawless:
            hits.update(items)
    return sorted(hits)


def onesmgllg_candidates(index):
    out = []
    pool = [r for r in index.rows if "reddit:1smgllg" in source_keys_of(r) and "/evidence/imported/" in r.get("_file", "")]
    for r in sorted(pool, key=lambda x: str(x["id"])):
        label = r.get("rawOutputName") or ""
        area = area_hint((r.get("migratedFrom") or {}).get("path"))
        family = re.search(r"ore family: ([^;]+)", r.get("notes") or "")
        aggregate = bool(re.search(r"\b(each of|others|all mentioned)\b", label, re.I))
        outs = [] if aggregate else resolve_label(label, index, area)
        ins = []
        if family and not re.search(r"\ball\b", family.group(1), re.I):
            ins = [c for c in resolve_label(family.group(1).strip() + " Ore", index, area)]
        if aggregate:
            status, why = "listed", "an aggregate label (gems unnamed), no single material"
        elif len(outs) == 1 and (ins or not family):
            status, why = "linked", "the label names one v3 item" + (
                "; the ore family names " + ("two ranks of one ore (family-level input)" if len(ins) > 1 else "one ore") if ins else "")
        elif len(outs) == 1:
            status, why = "listed", "output resolves to one item; the ore family does not name a v3 ore"
        elif outs:
            status, why = "listed", f"{len(outs)} v3 items fit the label"
        else:
            status, why = "listed", "no v3 item name ends with this label"
        out.append({"kind": "candidate", "group": "1smgllg", "id": r["id"], "studyKey": r.get("studyKey"),
                    "source": "reddit:1smgllg", "output": label, "oreFamily": family.group(1).strip() if family else None,
                    "percentShown": ie.num(r.get("percentShown")), "averageShown": ie.num(r.get("averageShown")),
                    "outputCandidates": [{"itemID": i, "name": n} for i, n in outs],
                    "inputCandidates": [{"itemID": i, "name": n} for i, n in ins],
                    "status": status, "reason": why + " (proposal only: the importer places nothing from this source)"})
    return out


def s6bfrl_candidates(root, index, ledger="research/ledger/titanium-observed-yields.csv"):
    path = os.path.join(root, ledger)
    if not os.path.exists(path):
        return []
    held = index.held("reddit:s6bfrl")
    recs = held[1] if held else []
    names = {compact(agent_name(r, index)) for r in recs} - {""}
    ids = {r["row"].get("outputItemID") for r in recs} - {None}
    totals = set().union(*(r["res"] for r in recs)) if recs else set()
    out = []
    with open(path, encoding="utf-8") as f:
        ledger_text = f.read()
    for n, row in enumerate(csv.DictReader(io.StringIO(ledger_text)), 2):
        if normalize_url(row.get("source_url") or "") != "reddit:s6bfrl":
            continue
        units = ie.num(row.get("observed_output_units"))
        in_v3 = compact(row.get("output_name")) in names or ie.num(row.get("output_id")) in ids
        same_total = units in totals if units is not None else False
        out.append({"kind": "candidate", "group": "s6bfrl-uncommon-gems", "path": ledger, "line": n, "source": "reddit:s6bfrl",
                    "output": row.get("output_name"), "outputItemID": ie.num(row.get("output_id")),
                    "observedUnits": units, "inputOre": ie.num(row.get("input_ore_count")),
                    "status": "linked" if in_v3 and same_total else "exception",
                    "reason": ("v3 holds this output with this total" if in_v3 and same_total else
                               "v3 holds this source (powder and other gems) but no row for this output; "
                               "the post is not readable offline, so the count stays unverified"),
                    "heldRecordCount": len(recs)})
    return out


# ---------------------------------------------------------------- run
def sort_key(e):
    return (e["kind"], str(e.get("path") or e.get("group") or ""), str(e.get("source") or e.get("studyId") or e.get("id") or ""),
            str(e.get("status") or e.get("outcome") or ""), json.dumps(e.get("lines") or e.get("line") or "", sort_keys=True))


def dump(path, rows):
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        for r in rows:
            f.write(json.dumps(r, sort_keys=True, ensure_ascii=False) + "\n")


def run(root, rows, out_dir, inventory=None, raw_rows=None):
    if inventory is None:
        with open(os.path.join(root, "research", "v3", "migration", "manifest", "inventory.jsonl"), encoding="utf-8") as f:
            inventory = [json.loads(l) for l in f]
    index = V3Index(rows, raw_rows)
    scope = sorted((r for r in inventory if r["disposition"] in SCOPE), key=lambda r: r["path"])
    links, residue, categories = [], [], {}
    for row in scope:
        categories[row["path"]] = row["category"]
        s, st, f, res = link_file(root, row, index)
        links += s + st + [f]
        residue += res
    candidates = name_only_candidates(index) + onesmgllg_candidates(index) + s6bfrl_candidates(root, index)
    links += candidates
    links.sort(key=sort_key)
    queue = build_queue(residue, categories)
    summary = summarize(scope, links, queue, index, root)
    os.makedirs(out_dir, exist_ok=True)
    dump(os.path.join(out_dir, "links.jsonl"), links)
    dump(os.path.join(out_dir, "extraction-queue.jsonl"), queue)
    with open(os.path.join(out_dir, "links-summary.json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump(summary, f, indent=1, sort_keys=True, ensure_ascii=False)
        f.write("\n")
    return links, queue, summary


def summarize(scope, links, queue, index, root):
    files = [e for e in links if e["kind"] == "file"]
    sources = [e for e in links if e["kind"] == "source"]
    reg_path = os.path.join(root, "research", "v3", "migration", "manifest", "url-registry.jsonl")
    reg = []
    if os.path.exists(reg_path):
        with open(reg_path, encoding="utf-8") as f:
            reg = [json.loads(l) for l in f]
    held_now = sum(1 for r in reg if index.held(r["key"]))
    mentioned_only = sum(1 for r in reg if not index.held(r["key"]) and r["key"] in index.mentions)
    def by(field, items):
        return dict(sorted(collections.Counter(e[field] for e in items).items()))
    cand = collections.defaultdict(collections.Counter)
    for e in links:
        if e["kind"] == "candidate":
            cand[e["group"]][e["status"]] += 1
    return {
        "inScopeFiles": len(files),
        "inventoryDispositions": by("inventoryDisposition", files),
        "fileOutcomes": by("outcome", files),
        "fileOutcomesByDisposition": {d: dict(sorted(collections.Counter(
            e["outcome"] for e in files if e["inventoryDisposition"] == d).items())) for d in sorted({e["inventoryDisposition"] for e in files})},
        "fileOutcomesByFormat": {d: dict(sorted(collections.Counter(
            e["outcome"] for e in files if e["format"] == d).items())) for d in sorted({e["format"] for e in files})},
        "sourceLinkGroups": by("status", sources),
        "citationsByStatus": dict(sorted(collections.Counter(
            {s: sum(len(e["lines"]) for e in sources if e["status"] == s) for s in STATUS_ORDER}).items())),
        "linkStrength": dict(sorted(collections.Counter(e.get("strength") for e in sources if e["status"] == "linked").items())),
        "linkedOnlyToImportedRows": sum(1 for e in sources if e["status"] == "linked" and e["records"]
                                       and all(r["imported"] for r in e["records"]) and e["recordCount"] <= MAX_RECORDS),
        "studyIdLinks": sum(1 for e in links if e["kind"] == "study"),
        "filesWithStudyIdLinks": len({e["path"] for e in links if e["kind"] == "study"}),
        "distinctSourcesCited": len({e["source"] for e in sources}),
        "distinctResidueSources": len(queue),
        "queueFiles": len({f["path"] for q in queue for f in q["files"]}),
        "queueAnchors": sum(f["anchorCount"] for q in queue for f in q["files"]),
        "registry": {"urls": len(reg), "heldByRecordSourceNow": held_now, "mentionedInNotesOnly": mentioned_only,
                     "notInV3": len(reg) - held_now - mentioned_only},
        "candidates": {g: dict(sorted(c.items())) for g, c in sorted(cand.items())},
        "sha256Mismatches": [e["path"] for e in files if not e["sha256InInventory"]],
    }


def load_raw_agent_rows(root):
    """Agent evidence as written: every record of every file outside evidence/imported/, no replaces, no corrections."""
    import glob
    rows = []
    for path in sorted(glob.glob(os.path.join(root, "research", "v3", "evidence", "**", "*.jsonl"), recursive=True)):
        if os.path.basename(os.path.dirname(path)) == "imported":
            continue
        rel = os.path.relpath(path, root).replace(os.sep, "/")
        with open(path, encoding="utf-8") as f:
            for line in f:
                try:
                    r = json.loads(line)
                except json.JSONDecodeError:
                    continue
                if isinstance(r, dict):
                    r["_file"] = rel
                    rows.append(r)
    return rows


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--out-dir", default=os.path.join(ROOT, "research", "v3", "migration", "manifest"))
    args = ap.parse_args(argv)
    import build_estimates as be
    rows = be.load()
    links, queue, summary = run(ROOT, rows, args.out_dir, raw_rows=load_raw_agent_rows(ROOT))
    print(f"{summary['inScopeFiles']} files: {summary['fileOutcomes']}; {len(queue)} residue sources -> extraction-queue.jsonl")


if __name__ == "__main__":
    main()
