#!/usr/bin/env python3
"""M04.3: batched extraction of the residual queue (manifest/extraction-queue.jsonl).

There is no model API in the migration workspace, so this tool does everything *around* the reading:

  prompt   build the prompt for one queue source (its files' anchored text with line numbers, the target
           schema, the rules). The reader (a model or a person) answers in the JSON shape the prompt shows.
  submit   validate an answer and write its checkpoint, manifest/extraction/<slug>.json. A rejected answer
           writes nothing.
  status   which queue sources have a current checkpoint (rows / null / pending / stale).
  write    the deterministic writer: checkpoints -> research/v3/evidence/imported/extracted-historical-sources.jsonl
           (rows only for sources v3 does not hold, PLAN section 3 rule 5). Nothing else writes that file.
  verify   revalidate every checkpoint against the files on disk.

What the validator enforces (an answer that fails any of it is rejected whole):
  * shape: known keys only, the source equals the queue entry, every file is one of the entry's files and still
    has the sha256 the queue recorded, a null answer carries a reason code and a reason;
  * quoting: every evidence span is a verbatim substring (whitespace and quote marks normalised) of the line it
    names, and the line is tied to the source (its paragraph's nearest URL names the source) or the answer
    quotes a line that ties it (`linkEvidence`);
  * numbers: every number in a record (counts, totals, percentages, averages, item IDs, ranks, dates) appears in
    the evidence text, or is computed by a `derivations` formula over numbers in the evidence and other fields,
    which the validator evaluates and compares;
  * arithmetic: hits <= casts, percent vs hits/casts, average vs total/casts, total vs casts x max, histogram
    sums, casts vs inputs / batch, declared sums of rank rows, one study = one set of casts and inputs;
  * schema: the finished record passes validate.check_record with no finding at all;
  * names: an item name travels with an item ID only; a name without an ID goes to rawInputName/rawOutputName
    and the row is stored unplaced (nothing is placed by name, nothing is guessed).

`condition` and `rateChange` readings are proposals: checked and kept in the checkpoint, never written to
evidence (the estimator reads `condition` records straight from evidence, and conditions.jsonl and
rate-changes.jsonl belong to the Master).

Usage, from the repository root:
  python3 research/v3/migration/tools/extract_batch.py prompt reddit:k1zd4o [--full]
  python3 research/v3/migration/tools/extract_batch.py submit answer.json
  python3 research/v3/migration/tools/extract_batch.py status
  python3 research/v3/migration/tools/extract_batch.py write [--report FILE] [--check]
"""
import argparse
import ast
import glob
import hashlib
import json
import os
import re
import sys
import unicodedata
from collections import Counter, defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
sys.path.insert(0, os.path.join(HERE, "..", "..", "tools"))
sys.path.insert(0, HERE)
import validate as val  # noqa: E402
from source_keys import normalize_url  # noqa: E402

QUEUE = "research/v3/migration/manifest/extraction-queue.jsonl"
CKPT_DIR = "research/v3/migration/manifest/extraction"
OUT_REL = "research/v3/evidence/imported/extracted-historical-sources.jsonl"
EXTRACT_DATE = "2026-11-01"      # recordedOn of every extracted row (fixed: reruns are byte-identical)
CHECKPOINT_VERSION = 1
CONTEXT_LINES = 2                # lines of context around an anchor in a prompt

# Sibling archive notes for a queue source that the inventory classed `source-links-only`, so the linker never
# queued them (M04.3 found them while checking each extracted source against the repository). They are repository
# text, like the queue's own files; each is listed with the reason. Deleting an entry and resubmitting that source
# returns it to the queue's files only.
EXTRA_FILES = {
    "reddit:nohny2": ["research/evidence/observations/2026-10-28-1340-legacy-batch013-nightshade-source-only.md"],
    "wowhead:item=129034": ["research/evidence/observations/2026-10-28-1242-legacy-batch012-original-source-only.md"],
}

NULL_CODES = {
    "identity-link-only": "the source is cited only to identify an item, spell, guide or recipe; the counts nearby are not its results",
    "no-observational-numbers": "no count, total, percentage or average that this source observed",
    "numbers-not-this-source": "the numbers in the file belong to other sources or to the file's own audit",
    "reference-table": "a published, estimated or modelled table or default (guide, calculator, TSM row), not a measured cohort",
    "qualitative": "the text describes the source in words without outputs",
    "ambiguous-doubt": "the text could be read two ways; null on doubt",
    "needs-original-post": "the numbers need the original post, which is not in the file",
    "held-elsewhere": "the same cohort is already held by v3 under another source",
    "other": "none of the above; the reason says why",
}
DROP_KEYS = {"studyLabel", "method", "inputName", "inputItemID", "inputRank", "outputName", "outputItemID",
             "outputRank", "casts", "inputsPerCast", "totalQuantity", "castsWithDrop", "percentShown",
             "percentMeaning", "averageShown", "averagePer", "minSeen", "maxSeen", "histogram", "skill",
             "specialization", "stats", "inputsProcessed", "inputsPurchased", "inputsRefunded", "castsBasis",
             "derivations", "dataDate", "dataDateText", "observedOn", "patch", "originalSource", "sourceKind",
             "title", "author", "published", "notes", "quote"}
RECIPE_KEYS = {"method", "recipeSpellID", "recipeName", "inputItemID", "inputName", "inputsPerCast",
               "outputItemID", "outputName", "outputCount", "title", "author", "published", "notes", "quote",
               "derivations"}
EXCHANGE_KEYS = {"giveItemID", "giveName", "giveCount", "getItemID", "getName", "getCount", "where",
                 "requirements", "title", "author", "published", "notes", "quote", "derivations"}
PROPOSAL_KEYS = {"method", "outputItemID", "outputName", "inputItemIDs", "inputName", "requires", "requiresSkill",
                 "date", "patch", "affects", "wording", "sizeIfGiven", "notes"}
DROP_NUMERIC = ["inputItemID", "outputItemID", "inputRank", "outputRank", "casts", "inputsPerCast",
                "totalQuantity", "castsWithDrop", "percentShown", "averageShown", "minSeen", "maxSeen",
                "inputsProcessed", "inputsPurchased", "inputsRefunded"]
RECIPE_NUMERIC = ["recipeSpellID", "inputItemID", "inputsPerCast", "outputItemID", "outputCount"]
EXCHANGE_NUMERIC = ["giveItemID", "giveCount", "getItemID", "getCount"]
DATE_FIELDS = ["dataDate", "observedOn", "published"]
RESULT_FIELDS = ["totalQuantity", "castsWithDrop", "percentShown", "averageShown", "minSeen", "maxSeen", "histogram"]
STRUCTURAL = {100.0, 1000.0}     # constants a formula may use without finding them in the text (percent, per-1000)
WORDS = {w: i for i, w in enumerate(
    "zero one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen "
    "seventeen eighteen nineteen twenty".split())}
WORDS.update({"thirty": 30, "forty": 40, "fifty": 50, "hundred": 100})

_QUOTES = str.maketrans({"‘": "'", "’": "'", "“": '"', "”": '"', "–": "-",
                         "—": "-", " ": " "})
_TOK = re.compile(r"\d{1,3}(?:,\d{3})+(?:\.\d+)?|\d+(?:\.\d+)?|\.\d+")
_WORD = re.compile(r"\b(" + "|".join(WORDS) + r")\b", re.I)
_URL = re.compile(r"https?://[^\s<>)\]\"']+")


# ---------------------------------------------------------------- text helpers
def norm(s):
    """Whitespace and quote marks normalised, so a quote survives line wrapping and curly punctuation."""
    return re.sub(r"\s+", " ", unicodedata.normalize("NFKC", s).translate(_QUOTES)).strip()


def numbers_of(text):
    """Every number written in a text: 10,000 / 17.9 / .5 / 11k / one..twenty."""
    out = set()
    for m in _TOK.finditer(text):
        v = float(m.group(0).replace(",", ""))
        out.add(round(v, 9))
        if text[m.end():m.end() + 1] in ("k", "K") and not text[m.end() + 1:m.end() + 2].isalpha():
            out.add(round(v * 1000, 9))
    for m in _WORD.finditer(text):
        out.add(float(WORDS[m.group(1).lower()]))
    return out


def has_number(value, pool):
    return any(abs(value - p) <= 1e-9 * max(1.0, abs(value)) for p in pool)


def is_num(v):
    return isinstance(v, (int, float)) and not isinstance(v, bool)


def sha_of(path):
    with open(path, "rb") as fh:
        return hashlib.sha256(fh.read()).hexdigest()


def slug(key, limit=28):
    return re.sub(r"[^a-z0-9]+", "-", key.lower()).strip("-")[:limit].strip("-")


def ckpt_name(key):
    return f"{slug(key, 40)}-{hashlib.sha1(key.encode()).hexdigest()[:8]}.json"


def entry_sha(entry):
    """Fingerprint of what an extraction reads: the source, its URLs and each file's path and sha256. Anchors and
    hints may change when link_sources.py is rerun; the quoted text cannot change without a new file hash."""
    core = {"source": entry["source"], "rawUrls": sorted(entry["rawUrls"]),
            "files": sorted((f["path"], f["sha256"]) for f in entry["files"])}
    return hashlib.sha256(json.dumps(core, sort_keys=True, ensure_ascii=False).encode("utf-8")).hexdigest()


def read_lines(root, rel):
    with open(os.path.join(root, rel), encoding="utf-8", errors="replace", newline="") as fh:
        return fh.read().splitlines()


def with_extras(root, entry):
    """The queue entry plus the sibling notes listed in EXTRA_FILES for its source (idempotent)."""
    extra = [p for p in EXTRA_FILES.get(entry["source"], []) if p not in {f["path"] for f in entry["files"]}]
    if not extra:
        return entry
    entry = dict(entry, files=list(entry["files"]))
    for rel in extra:
        entry["files"].append({"path": rel, "sha256": sha_of(os.path.join(root, rel)), "category": "observation",
                               "proximity": "citation", "anchorCount": 0, "anchors": []})
    entry["fileCount"] = len(entry["files"])
    return entry


def load_queue(root=ROOT):
    path = os.path.join(root, QUEUE)
    with open(path, encoding="utf-8") as fh:
        return [with_extras(root, json.loads(l)) for l in fh if l.strip()]


def find_entry(root, key):
    """The queue entry for a source: the live queue first, else the entry its checkpoint carries (link_sources.py
    drops a source from the queue once its rows make it held, and it may still be re-extracted)."""
    for e in load_queue(root):
        if e["source"] == key:
            return e
    path = ckpt_path(root, key)
    if os.path.exists(path):
        with open(path, encoding="utf-8") as fh:
            ck = json.load(fh)
        if isinstance(ck.get("entry"), dict):
            return with_extras(root, ck["entry"])
    return None


def source_tokens(entry):
    """Strings whose presence in a line ties it to the queue source: the URLs, the id inside the key, the host."""
    toks = set()
    for u in entry.get("rawUrls", []):
        toks.add(re.sub(r"^https?://", "", u.strip().lower()).rstrip("/"))
    key = entry["source"]
    for part in re.split(r"[:=#@/]", key):
        if len(part) >= 5 and not part.startswith("wowhead") and part not in ("reddit", "blizzforum"):
            toks.add(part.lower())
    toks.add(key.lower())
    return {t for t in toks if t}


def line_has_token(line, toks):
    low = line.lower()
    return any(t in low for t in toks)


def line_urls(line):
    return _URL.findall(line)


def ties_to_source(lines, idx, toks):
    """Is line idx (0-based) part of the source's own citation? Same rule as the linker: a line belongs to the
    nearest URL above it in its paragraph, else the nearest below; a line that has URLs itself needs one of ours."""
    if line_has_token(lines[idx], toks):
        return True
    if line_urls(lines[idx]):
        return False
    j = idx
    while j >= 0 and lines[j].strip() and not lines[j].lstrip().startswith("#"):
        if line_urls(lines[j]):
            return line_has_token(lines[j], toks)
        j -= 1
    j = idx + 1
    while j < len(lines) and lines[j].strip() and not lines[j].lstrip().startswith("#"):
        if line_urls(lines[j]):
            return line_has_token(lines[j], toks)
        j += 1
    return False


# ---------------------------------------------------------------- prompt
def windows(lines, anchors, context=CONTEXT_LINES):
    """Line ranges (1-based, inclusive) around the anchors, merged."""
    spans = []
    for a in anchors:
        n = a.get("line")
        if n:
            spans.append((max(1, n - context), min(len(lines), n + context)))
    spans.sort()
    merged = []
    for lo, hi in spans:
        if merged and lo <= merged[-1][1] + 1:
            merged[-1] = (merged[-1][0], max(hi, merged[-1][1]))
        else:
            merged.append((lo, hi))
    return merged


def citation_lines(lines, entry):
    """1-based lines that name the source itself (a raw URL or the id inside the key)."""
    toks = source_tokens(entry)
    return {n for n, line in enumerate(lines, 1) if line_has_token(line, toks)}


def file_block(root, f, full=False, entry=None):
    lines = read_lines(root, f["path"])
    anchor_lines = {a["line"] for a in f.get("anchors", []) if a.get("line")}
    cites = citation_lines(lines, entry) if entry else set()
    ext = os.path.splitext(f["path"])[1].lower()
    spans = [(1, len(lines))] if full or ext in (".json", ".jsonl") else windows(
        lines, [{"line": n} for n in sorted(anchor_lines | cites)])
    out = [f"### FILE {f['path']}", f"sha256 {f['sha256']}  category {f['category']}  numbers {f['proximity']} "
           f"({'next to the citation' if f['proximity'] == 'citation' else 'elsewhere in the file: decide whether they belong to this source'})"]
    if lines:
        out.append("first line of the file: " + lines[0][:200])
    last = 0
    for lo, hi in spans:
        if lo > last + 1:
            out.append("   ...")
        for n in range(lo, hi + 1):
            mark = ">>" if n in anchor_lines else ("@@" if n in cites else "  ")
            out.append(f"{mark}{n:4d}| {lines[n - 1]}")
        last = hi
    return "\n".join(out)


SCHEMA_TEXT = """TARGET SCHEMA (answer with one JSON object, nothing else)
{
  "source": "<the queue key, exactly>",
  "result": "rows" | "null",
  "reasonCode": "<null answers only; one of: %(codes)s>",
  "reason": "<why, in your words, at least 20 characters; also allowed on rows to say what you left out>",
  "rows": [
    {
      "path": "<one of the files above>",
      "type": "drop" | "recipe" | "exchange",
      "evidence": [{"line": <file line number>, "text": "<VERBATIM substring of that line>"}],
      "linkEvidence": {"line": <n>, "text": "<verbatim>"},      // only when the numbers' line is not under this source's own URL
      "record": { ...fields below... }
    }
  ],
  "proposals": [ {"type": "condition" | "rateChange", "path": "...", "evidence": [...], "record": {...}} ],
  "checks": [ {"kind": "sum", "field": "totalQuantity", "rows": [<row indexes>], "stated": <number>,
               "evidence": {"line": <n>, "text": "<verbatim line text stating that total>"}} ]
}
drop record fields (all optional except studyLabel and method; unknown values are null, never guessed):
  studyLabel  short label; rows with the same label are one study, one source cohort (e.g. "serevite-r2-10000")
  method      Prospect | Mill | Disenchant | Smelt
  inputName inputItemID inputRank outputName outputItemID outputRank   (an ID only if the ID number is in the quoted text)
  casts inputsPerCast totalQuantity castsWithDrop percentShown percentMeaning(perCast|perInput|unclear)
  averageShown averagePer(cast|input|1000 inputs) minSeen maxSeen histogram({"0": n, "1": n}) skill specialization stats
  inputsProcessed inputsPurchased inputsRefunded     (raw counts exactly as the source states them)
  castsBasis  reported (the source states completed casts) | countedFromInputs (casts = inputsProcessed / inputsPerCast)
              | nominalEquivalent | derived | null when casts is null
  derivations [{"field": "casts", "formula": "inputsProcessed / inputsPerCast", "assumption": "..."}]
              (a formula over numbers in the evidence and other fields of the record; round(x, n) allowed)
  dataDate observedOn published (ISO dates, only if written in the text), dataDateText (free text period), patch
  originalSource (URL of an earlier original of this study, only if the text names it)
  sourceKind  study (counted results someone recorded) | reference (a published table of values, not hit counts)
  title author notes quote(under 25 words, verbatim from an evidence span)
recipe record: method recipeSpellID recipeName inputItemID inputName inputsPerCast outputItemID outputName outputCount
exchange record: giveItemID giveName giveCount getItemID getName getCount where requirements
proposal record (kept for the Master, never written to evidence): method outputItemID outputName inputItemIDs inputName
  requires requiresSkill | date patch affects wording sizeIfGiven"""

RULES_TEXT = """RULES
1. One source only: %(source)s. The files below mention other sources too; ignore their numbers. Numbers that sit in a
   file but not under this source's URL count only if a line you quote (linkEvidence) ties them to this source.
2. Quote the text. Every evidence span is copied exactly from the line you name. Do not paraphrase inside "text".
3. Null on doubt. If the text gives no result this source observed, or you cannot tell whose numbers they are, answer
   "result": "null" with a reasonCode and a reason. A source cited only to identify an item or spell is null.
4. No invented numbers. Every number in a record must be written in the evidence, or computed by a derivations formula
   over numbers in the evidence. Never use memory, never fill a recipe batch size or an item ID the text does not give.
5. Names travel with IDs. Give inputName/outputName only next to an item ID that is in the evidence; otherwise leave the
   ID null and the row is stored unplaced under its raw name. Never guess an item ID.
6. casts: set only what the source states (castsBasis reported) or what inputsProcessed / inputsPerCast gives (a
   derivation). "10,000 ore" with no batch size is inputsProcessed 10000 and casts null. Resourcefulness refunds never
   change a count.
7. Check your arithmetic: hits <= casts, percent = 100 x hits / casts, average = total / casts, histogram sums. The
   validator recomputes all of it and rejects the whole answer on a mismatch.
8. Conditions (specialisation or skill unlocks) and rate changes are proposals, not rows.
9. One row per material per study. A row needs at least one result: total, hits, percent, average, range or histogram.
10. Expected record types and method below are hints from keyword matching, not decisions."""


def build_prompt(entry, root=ROOT, full=False, brief=False):
    head = [
        f"EXTRACTION TASK - source {entry['source']}",
        "raw URLs: " + ", ".join(entry["rawUrls"]),
        f"expected types (hint): {', '.join(entry['expectedTypes'])}   method hints: {', '.join(entry['methodHints']) or '-'}",
        f"v3 already mentions this source in notes: {entry['v3Mentions']} (a mention is not a holding)",
        "",
    ]
    if not brief:   # --brief keeps only the source and the text, for reading many prompts in one go
        head += [RULES_TEXT % {"source": entry["source"]}, "",
                 SCHEMA_TEXT % {"codes": ", ".join(sorted(NULL_CODES))}, ""]
    head += ["TEXT (>> = a line with counts found by the linker; @@ = a line that names this source)"]
    blocks = [file_block(root, f, full, entry) for f in entry["files"]]
    return "\n".join(head + [""] + blocks) + "\n"


# ---------------------------------------------------------------- formulas
def eval_formula(expr, env, allowed_consts):
    """Safe arithmetic over named record fields and literal numbers. Returns (value, error)."""
    try:
        tree = ast.parse(expr, mode="eval")
    except SyntaxError:
        return None, f"formula {expr!r} does not parse"

    def ev(n, in_round_digits=False):
        if isinstance(n, ast.Expression):
            return ev(n.body)
        if isinstance(n, ast.Constant) and is_num(n.value):
            if not in_round_digits and not has_number(float(n.value), allowed_consts) and float(n.value) not in STRUCTURAL:
                raise ValueError(f"constant {n.value} is not in the evidence")
            return n.value
        if isinstance(n, ast.Name):
            if n.id not in env:
                raise ValueError(f"{n.id} is not a supported number of this record")
            return env[n.id]
        if isinstance(n, ast.UnaryOp) and isinstance(n.op, (ast.USub, ast.UAdd)):
            v = ev(n.operand)
            return -v if isinstance(n.op, ast.USub) else v
        if isinstance(n, ast.BinOp) and isinstance(n.op, (ast.Add, ast.Sub, ast.Mult, ast.Div)):
            a, b = ev(n.left), ev(n.right)
            if isinstance(n.op, ast.Add):
                return a + b
            if isinstance(n.op, ast.Sub):
                return a - b
            if isinstance(n.op, ast.Mult):
                return a * b
            if b == 0:
                raise ValueError("division by zero")
            return a / b
        if isinstance(n, ast.Call) and isinstance(n.func, ast.Name) and n.func.id == "round" \
                and 1 <= len(n.args) <= 2 and not n.keywords:
            v = ev(n.args[0])
            return round(v, int(ev(n.args[1], True))) if len(n.args) == 2 else round(v)
        raise ValueError("only + - * / round() over numbers and field names are allowed")

    try:
        return ev(tree), None
    except ValueError as e:
        return None, str(e)


def formula_names(expr):
    try:
        return {n.id for n in ast.walk(ast.parse(expr, mode="eval")) if isinstance(n, ast.Name)}
    except SyntaxError:
        return set()


# ---------------------------------------------------------------- validation
class Problems(list):
    def add(self, where, msg):
        self.append(f"{where}: {msg}")


def check_number_support(rec, numeric_fields, pool, p, where):
    """Every number is in the evidence or computed by a derivation that checks out. Returns the derivations kept."""
    derivs = rec.get("derivations") or []
    if not isinstance(derivs, list) or not all(isinstance(d, dict) and {"field", "formula"} <= d.keys() for d in derivs):
        p.add(where, "derivations must be a list of {field, formula, assumption}")
        return []
    by_field = {}
    for d in derivs:
        if d["field"] in by_field:
            p.add(where, f"two derivations for {d['field']}")
        by_field[d["field"]] = d
    present = {f: rec[f] for f in numeric_fields if is_num(rec.get(f))}
    backed = {f for f, v in present.items() if f not in by_field and has_number(float(v), pool)}
    for f in sorted(present):
        if f not in by_field and f not in backed:
            p.add(where, f"{f} {present[f]} is not written in the evidence and has no derivation")
    pending = dict(by_field)
    progress = True
    while pending and progress:
        progress = False
        for f, d in sorted(pending.items()):
            if f not in present:
                p.add(where, f"derivation for {f} but the record has no {f}")
                del pending[f]
                progress = True
                continue
            names = formula_names(d["formula"])
            if names - backed:
                continue
            env = {k: float(present[k]) for k in backed}
            got, err = eval_formula(d["formula"], env, pool)
            if err:
                p.add(where, f"derivation for {f}: {err}")
            elif abs(got - present[f]) > 1e-9 * max(1.0, abs(got)):
                p.add(where, f"derivation for {f}: {d['formula']} = {got:g}, record says {present[f]:g}")
            else:
                backed.add(f)
            del pending[f]
            progress = True
    for f in sorted(pending):
        p.add(where, f"derivation for {f} uses fields that are neither in the evidence nor derived: "
                     f"{sorted(formula_names(pending[f]['formula']) - backed)}")
    return derivs


def arithmetic_problems(rec, p, where):
    """Cross-checks inside one drop record."""
    n, h = rec.get("casts"), rec.get("castsWithDrop")
    tot, pct, avg = rec.get("totalQuantity"), rec.get("percentShown"), rec.get("averageShown")
    lo, hi = rec.get("minSeen"), rec.get("maxSeen")
    if is_num(n) and is_num(h) and h > n:
        p.add(where, f"castsWithDrop {h} exceeds casts {n}")
    if is_num(pct) and rec.get("percentMeaning") == "perCast" and is_num(n) and is_num(h) and n > 0:
        want = 100.0 * h / n
        if abs(want - pct) > 0.51:
            p.add(where, f"percent {pct} does not match castsWithDrop/casts = {want:.2f}")
    if is_num(tot) and is_num(h) and tot < h:
        p.add(where, f"total {tot} is less than castsWithDrop {h}; every hit gives at least one")
    if is_num(tot) and is_num(n) and is_num(hi) and hi >= 1 and tot > n * hi:
        p.add(where, f"total {tot} exceeds casts x maxSeen = {n * hi:g}")
    if is_num(tot) and is_num(h) and is_num(lo) and lo >= 1 and tot < h * lo:
        p.add(where, f"total {tot} is below castsWithDrop x minSeen = {h * lo:g}")
    if is_num(avg) and is_num(tot):
        per = rec.get("averagePer")
        denom = {"cast": n, "input": rec.get("inputsProcessed"), "1000 inputs": rec.get("inputsProcessed")}.get(per)
        if is_num(denom) and denom > 0:
            want = tot / denom * (1000 if per == "1000 inputs" else 1)
            if abs(want - avg) > max(0.0051, 0.01 * abs(want)):
                p.add(where, f"average {avg} per {per} does not match total/denominator = {want:.4f}")
    hist = rec.get("histogram")
    if isinstance(hist, dict):
        try:
            buckets = {float(k): float(v) for k, v in hist.items()}
        except (TypeError, ValueError):
            p.add(where, "histogram keys must be amounts and values counts")
            buckets = {}
        if buckets:
            s = sum(buckets.values())
            if is_num(n) and abs(s - n) > 1e-9:
                p.add(where, f"histogram counts add to {s:g}, casts is {n}")
            amount = sum(k * v for k, v in buckets.items())
            if is_num(tot) and abs(amount - tot) > 1e-9:
                p.add(where, f"histogram amounts add to {amount:g}, total is {tot}")
            if is_num(n) and is_num(h) and abs((n - buckets.get(0.0, 0.0)) - h) > 1e-9:
                p.add(where, "castsWithDrop does not equal casts minus the histogram's zero bucket")
    ipc, ip, basis = rec.get("inputsPerCast"), rec.get("inputsProcessed"), rec.get("castsBasis")
    if is_num(n) and is_num(ipc) and is_num(ip):
        if basis == "countedFromInputs" and ipc > 0 and abs(n - ip / ipc) > 1e-9:
            p.add(where, f"casts {n} is not inputsProcessed/inputsPerCast = {ip / ipc:g}")
        elif n * ipc > ip + 1e-9:
            p.add(where, f"casts x inputsPerCast = {n * ipc:g} exceeds inputsProcessed {ip}")
    if is_num(rec.get("inputsRefunded")) and is_num(ip) and rec["inputsRefunded"] > ip:
        p.add(where, "inputsRefunded exceeds inputsProcessed")
    if rec.get("percentShown") is not None and rec.get("percentMeaning") is None:
        p.add(where, "percentShown needs an explicit percentMeaning")
    if (is_num(n) or rec.get("castsBasis")) and (rec.get("castsBasis") is None or not is_num(n)):
        p.add(where, "casts and castsBasis go together")


def finish_drop(rec, entry, url, rid_hint="x"):
    """The record exactly as the writer will emit it (validated here, written by `write`)."""
    return build_drop(rec, entry, url, rid_hint, {"path": "?", "sha256": "?", "recordRef": "?"}, check=True)


def validate_answer(ans, entry, root=ROOT, check_holdings=True):
    """Return (problems, info). `problems` empty means the answer is accepted. A checkpoint that is revalidated later
    skips the holdings test: a source v3 holds by then is reported as held by the writer, not as an invalid answer."""
    p = Problems()
    info = {"rows": 0, "proposals": 0}
    if not isinstance(ans, dict):
        p.add("answer", "must be a JSON object")
        return p, info
    allowed = {"source", "result", "reasonCode", "reason", "rows", "proposals", "checks"}
    for k in sorted(set(ans) - allowed):
        p.add("answer", f"unknown key {k!r}")
    if ans.get("source") != entry["source"]:
        p.add("source", f"{ans.get('source')!r} is not the queue entry {entry['source']!r}")
        return p, info
    result = ans.get("result")
    reason = ans.get("reason")
    if result == "null":
        if ans.get("rows"):
            p.add("answer", "a null answer has no rows")
        if ans.get("reasonCode") not in NULL_CODES:
            p.add("answer", f"reasonCode must be one of {sorted(NULL_CODES)}")
        if not isinstance(reason, str) or len(reason.strip()) < 20:
            p.add("answer", "a null answer needs a reason of at least 20 characters")
        return p, info
    if result != "rows":
        p.add("answer", "result must be 'rows' or 'null'")
        return p, info
    rows = ans.get("rows")
    if not isinstance(rows, list) or not rows:
        p.add("answer", "result 'rows' needs at least one row")
        return p, info
    if check_holdings:
        by_key, by_thread, thread = held_keys(root)
        if strip_lang(entry["source"]) in by_key or thread(entry["source"]) in by_thread:
            p.add("source", "v3 holds this source already (PLAN section 3 rule 5): answer null with reasonCode held-elsewhere")
            return p, info
    files = {f["path"]: f for f in entry["files"]}
    toks = source_tokens(entry)
    cache = {}

    def lines_of(path):
        if path not in cache:
            cache[path] = read_lines(root, path)
        return cache[path]

    def check_span(span, path, where, require_tie):
        """Verbatim quote of a named line. Returns the normalised text or None."""
        if not isinstance(span, dict) or not is_num(span.get("line")) or not isinstance(span.get("text"), str):
            p.add(where, "evidence span needs {line, text}")
            return None
        ls = lines_of(path)
        n = int(span["line"])
        if not 1 <= n <= len(ls):
            p.add(where, f"line {n} is outside {path} ({len(ls)} lines)")
            return None
        text = norm(span["text"])
        if len(text) < 3:
            p.add(where, "evidence text is empty")
            return None
        if text not in norm(ls[n - 1]):
            p.add(where, f"line {n}: the text is not a verbatim part of the line")
            return None
        if require_tie and not ties_to_source(ls, n - 1, toks):
            return False
        return text

    for path_check in {r.get("path") for r in rows if isinstance(r, dict)}:
        if path_check not in files:
            p.add("rows", f"path {path_check!r} is not one of the entry's files")
        elif sha_of(os.path.join(root, path_check)) != files[path_check]["sha256"]:
            p.add("rows", f"{path_check} no longer has the sha256 the queue recorded")
    if p:
        return p, info

    records, studies = [], defaultdict(list)
    for i, row in enumerate(rows):
        where = f"rows[{i}]"
        if not isinstance(row, dict):
            p.add(where, "must be an object")
            continue
        for k in sorted(set(row) - {"path", "type", "evidence", "linkEvidence", "record"}):
            p.add(where, f"unknown key {k!r}")
        path, rtype, rec = row.get("path"), row.get("type"), row.get("record")
        if rtype not in ("drop", "recipe", "exchange"):
            p.add(where, "type must be drop, recipe or exchange (conditions and rate changes are proposals)")
            continue
        if not isinstance(rec, dict):
            p.add(where, "record must be an object")
            continue
        keyset = {"drop": DROP_KEYS, "recipe": RECIPE_KEYS, "exchange": EXCHANGE_KEYS}[rtype]
        for k in sorted(set(rec) - keyset):
            p.add(where, f"unknown {rtype} field {k!r}")
        ev = row.get("evidence")
        if not isinstance(ev, list) or not ev:
            p.add(where, "evidence needs at least one span")
            continue
        texts, tied = [], False
        for j, span in enumerate(ev):
            t = check_span(span, path, f"{where}.evidence[{j}]", True)
            if t is False:
                t = check_span(span, path, f"{where}.evidence[{j}]", False)
            else:
                tied = tied or t is not None
            if t:
                texts.append(t)
        if row.get("linkEvidence") is not None:
            le = row["linkEvidence"]
            t = check_span(le, path, f"{where}.linkEvidence", False)
            if t and not line_has_token(t, toks):
                p.add(where, "linkEvidence must name the source (its URL, id or thread)")
            elif t:
                near = min(abs(int(le["line"]) - int(s["line"])) for s in ev if is_num(s.get("line")))
                if near > 3:
                    p.add(where, "linkEvidence must be within 3 lines of the evidence")
                else:
                    tied = True
        if not tied:
            p.add(where, "the evidence is not under this source's own URL; quote a line that names the source in linkEvidence")
        if p and any(m.startswith(where) for m in p):
            continue
        pool = set()
        for t in texts:
            pool |= numbers_of(t)
        # dates and patch must be written in the evidence
        for f in DATE_FIELDS + ["dataDateText", "patch"]:
            v = rec.get(f)
            if v is not None and (not isinstance(v, str) or norm(v) not in " ".join(texts)):
                p.add(where, f"{f} {v!r} is not written in the evidence")
        if rec.get("quote") is not None:
            q = norm(str(rec["quote"]))
            if len(q.split()) >= 25 or not any(q in t for t in texts):
                p.add(where, "quote must be under 25 words and verbatim from an evidence span")
        if rtype == "drop":
            if not rec.get("studyLabel") or not isinstance(rec.get("studyLabel"), str):
                p.add(where, "studyLabel is required")
            if rec.get("method") not in val.METHODS:
                p.add(where, f"method must be one of {sorted(val.METHODS)}")
            if rec.get("sourceKind") not in (None, "study", "reference"):
                p.add(where, "sourceKind must be study or reference")
            if not any(rec.get(f) not in (None, {}) for f in RESULT_FIELDS):
                p.add(where, "a drop row needs at least one result (total, hits, percent, average, range, histogram)")
            numeric = DROP_NUMERIC
        elif rtype == "recipe":
            numeric = RECIPE_NUMERIC
        else:
            numeric = EXCHANGE_NUMERIC
        derivs = check_number_support(rec, numeric, pool, p, where)
        if isinstance(rec.get("histogram"), dict):
            for k, v in rec["histogram"].items():
                try:
                    amount = float(k)
                except (TypeError, ValueError):
                    amount = -1.0
                if not is_num(v) or not has_number(float(v), pool) or (amount != 0 and not has_number(amount, pool)):
                    p.add(where, f"histogram entry {k!r}: {v!r} is not written in the evidence")
        if rtype == "drop":
            arithmetic_problems(rec, p, where)
            basis = rec.get("castsBasis")
            if basis == "reported" and any(d.get("field") == "casts" for d in derivs):
                p.add(where, "reported casts cannot carry a casts derivation")
            if basis == "countedFromInputs":
                cd = next((d for d in derivs if d.get("field") == "casts"), None)
                if not cd or not {"inputsProcessed", "inputsPerCast"} <= formula_names(cd["formula"]):
                    p.add(where, "countedFromInputs needs a casts derivation over inputsProcessed and inputsPerCast")
            if not (p and any(m.startswith(where) for m in p)):
                try:
                    finished = finish_drop(rec, entry, entry["rawUrls"][0])
                except KeyError as e:
                    p.add(where, f"cannot build the record: {e}")
                    continue
                for sev, code, msg in val.check_record(finished):
                    p.add(where, f"validate.py {sev} {code}: {msg}")
            studies[rec.get("studyLabel")].append((i, rec))
        if rtype != "drop" and not (p and any(m.startswith(where) for m in p)):
            if rec.get("method") not in val.METHODS and rtype == "recipe":
                p.add(where, f"method must be one of {sorted(val.METHODS)}")
            else:
                finished = build_other(rtype, rec, entry, entry["rawUrls"][0], "x",
                                       {"path": "?", "sha256": "?", "recordRef": "?"})
                for sev, code, msg in val.check_record(finished):
                    p.add(where, f"validate.py {sev} {code}: {msg}")
        records.append((i, rtype, rec))
        info["rows"] += 1
    # one study = one set of casts and inputs, one row per material and rank
    for label, members in studies.items():
        for f in ("method", "inputItemID", "inputName", "inputRank", "casts", "inputsProcessed", "inputsPerCast",
                  "castsBasis", "sourceKind"):
            vals = {json.dumps(m.get(f)) for _, m in members}
            if len(vals) > 1:
                p.add(f"study {label!r}", f"rows disagree on {f}: {sorted(vals)}")
        seen = Counter((m.get("outputItemID"), (m.get("outputName") or "").lower(), m.get("outputRank")) for _, m in members)
        for k, c in seen.items():
            if c > 1:
                p.add(f"study {label!r}", f"output {k} appears {c} times")
    # declared sums over rank rows
    for j, chk in enumerate(ans.get("checks") or []):
        where = f"checks[{j}]"
        if not isinstance(chk, dict) or chk.get("kind") != "sum" or not is_num(chk.get("stated")):
            p.add(where, "a check is {kind: 'sum', field, rows, stated, evidence}")
            continue
        idx = chk.get("rows") or []
        if not idx or not all(isinstance(i, int) and 0 <= i < len(rows) for i in idx):
            p.add(where, "rows must be row indexes")
            continue
        path = rows[idx[0]].get("path")
        t = check_span(chk.get("evidence"), path, f"{where}.evidence", False)
        if t and not has_number(float(chk["stated"]), numbers_of(t)):
            p.add(where, f"stated {chk['stated']} is not written in the quoted line")
        field = chk.get("field")
        vals = [rows[i]["record"].get(field) for i in idx if isinstance(rows[i].get("record"), dict)]
        if not all(is_num(v) for v in vals) or abs(sum(vals) - chk["stated"]) > 1e-9:
            p.add(where, f"{field} of rows {idx} adds to {sum(v for v in vals if is_num(v)):g}, stated {chk['stated']}")
    # proposals: evidence and numbers only
    for j, pr in enumerate(ans.get("proposals") or []):
        where = f"proposals[{j}]"
        if not isinstance(pr, dict) or pr.get("type") not in ("condition", "rateChange") or pr.get("path") not in files \
                or not isinstance(pr.get("record"), dict):
            p.add(where, "a proposal is {type: condition|rateChange, path, evidence, record}")
            continue
        for k in sorted(set(pr["record"]) - PROPOSAL_KEYS):
            p.add(where, f"unknown proposal field {k!r}")
        texts = [check_span(s, pr["path"], f"{where}.evidence", False) for s in (pr.get("evidence") or [])]
        if not texts or not all(texts):
            p.add(where, "evidence needs verbatim spans")
            continue
        pool = set().union(*(numbers_of(t) for t in texts))
        for k in ("outputItemID", "requiresSkill"):
            v = pr["record"].get(k)
            if is_num(v) and not has_number(float(v), pool):
                p.add(where, f"{k} {v} is not written in the evidence")
        info["proposals"] += 1
    if not info["rows"] and not p:
        p.add("answer", "no usable row")
    return p, info


# ---------------------------------------------------------------- record builders
def record_id(entry, n):
    return f"import-extract-{slug(entry['source'])}-{hashlib.sha1(entry['source'].encode()).hexdigest()[:6]}-{n:02d}"


def common_base(rid, rtype, url, rec, notes):
    return {"id": rid, "type": rtype, "agent": "import", "recordedOn": EXTRACT_DATE,
            "source": {"url": url, "title": rec.get("title"), "author": rec.get("author"),
                       "published": rec.get("published")},
            "originalSource": rec.get("originalSource"), "dataDate": rec.get("dataDate"), "patch": rec.get("patch"),
            "quote": rec.get("quote"), "notes": notes, "replaces": None}


def place_names(rec, prefix, id_key, name_key, raw_key):
    """A name stays an item name only next to an item ID; otherwise it moves to the raw field."""
    name, raw = rec.get(name_key), rec.get(raw_key)
    if rec.get(id_key) is None:
        return None, raw or name
    return name, raw


def build_drop(rec, entry, url, rid, migrated, check=False):
    in_name, raw_in = place_names(rec, "input", "inputItemID", "inputName", "rawInputName")
    out_name, raw_out = place_names(rec, "output", "outputItemID", "outputName", "rawOutputName")
    study = f"extract-{slug(entry['source'], 40)}-{slug(rec.get('studyLabel') or 'x', 40)}"
    notes = rec.get("notes")
    pre = f"Extracted from {migrated['path']}, {migrated['recordRef']}, by extract_batch.py (M04.3); quoted text only."
    if raw_in or raw_out:
        pre += " Item named without an ID in the text, so the row is stored but unplaced."
    notes = pre if not notes else f"{pre} {notes}"
    r = common_base(rid, "drop", url, rec, notes)
    fields = {"studyKey": study, "sourceKind": rec.get("sourceKind") or "study", "method": rec.get("method"),
              "inputItemID": rec.get("inputItemID"), "inputName": in_name, "inputRank": rec.get("inputRank"),
              "gearGroup": None, "outputItemID": rec.get("outputItemID"), "outputName": out_name,
              "outputRank": rec.get("outputRank"), "casts": rec.get("casts"), "inputsPerCast": rec.get("inputsPerCast"),
              "totalQuantity": rec.get("totalQuantity"), "castsWithDrop": rec.get("castsWithDrop"),
              "percentShown": rec.get("percentShown"), "percentMeaning": rec.get("percentMeaning"),
              "averageShown": rec.get("averageShown"), "averagePer": rec.get("averagePer"),
              "minSeen": rec.get("minSeen"), "maxSeen": rec.get("maxSeen"), "histogram": rec.get("histogram"),
              "skill": rec.get("skill"), "specialization": rec.get("specialization"), "stats": rec.get("stats")}
    r.update(fields)
    r.update(castsBasis=rec.get("castsBasis"), inputsProcessed=rec.get("inputsProcessed"),
             inputsPurchased=rec.get("inputsPurchased"), inputsRefunded=rec.get("inputsRefunded"),
             dataDateText=rec.get("dataDateText"), observedOn=rec.get("observedOn"),
             rawOutputName=raw_out, rawInputName=raw_in, derivations=rec.get("derivations") or None,
             migratedFrom=migrated)
    return r


def build_other(rtype, rec, entry, url, rid, migrated):
    keys = val.TYPE_FIELDS[rtype]
    notes = f"Extracted from {migrated['path']}, {migrated['recordRef']}, by extract_batch.py (M04.3); quoted text only."
    if rec.get("notes"):
        notes += " " + rec["notes"]
    r = common_base(rid, rtype, url, rec, notes)
    for k in keys:
        r[k] = rec.get(k)
    if rtype == "recipe":
        r["otherReagents"] = None
    r.update(derivations=rec.get("derivations") or None, migratedFrom=migrated)
    return r


def build_records(entry, ans, root=ROOT):
    """Final records for one accepted answer (deterministic: depends only on the entry and the answer)."""
    out = []
    shas = {f["path"]: f["sha256"] for f in entry["files"]}
    url = entry["rawUrls"][0]
    for n, row in enumerate(ans.get("rows") or [], 1):
        rec = row["record"]
        first = min(int(s["line"]) for s in row["evidence"])
        last = max(int(s["line"]) for s in row["evidence"])
        ref = f"line {first}" if first == last else f"lines {first}-{last}"
        migrated = {"path": row["path"], "sha256": shas[row["path"]], "recordRef": f"{ref}, source {entry['source']}"}
        rid = record_id(entry, n)
        if row["type"] == "drop":
            out.append(build_drop(rec, entry, url, rid, migrated))
        else:
            out.append(build_other(row["type"], rec, entry, url, rid, migrated))
    return out


# ---------------------------------------------------------------- checkpoints
def ckpt_path(root, key):
    return os.path.join(root, CKPT_DIR, ckpt_name(key))


def make_checkpoint(entry, ans, info):
    return {"version": CHECKPOINT_VERSION, "source": entry["source"], "entrySha": entry_sha(entry), "entry": entry,
            "status": "null" if ans["result"] == "null" else "rows", "rows": info["rows"],
            "proposals": info["proposals"], "answer": ans}


def dump_json(path, obj):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as fh:
        json.dump(obj, fh, indent=1, sort_keys=True, ensure_ascii=False)
        fh.write("\n")


def check_checkpoint(root, ck):
    """current / stale / invalid for a checkpoint already read. It is validated against the queue entry it carries,
    so it stays usable after link_sources.py drops the source from the live queue (its rows made it held)."""
    if not isinstance(ck, dict) or ck.get("version") != CHECKPOINT_VERSION or not isinstance(ck.get("entry"), dict) \
            or ck.get("entrySha") != entry_sha(ck["entry"]):
        return "stale"
    problems, _ = validate_answer(ck.get("answer"), ck["entry"], root, check_holdings=False)
    return "invalid" if problems else "current"


def load_checkpoint(root, entry):
    """(checkpoint or None, state) for a live queue entry: current / stale / missing / invalid. Stale means the live
    entry reads other files or URLs than the checkpoint did."""
    path = ckpt_path(root, entry["source"])
    if not os.path.exists(path):
        return None, "missing"
    try:
        with open(path, encoding="utf-8") as fh:
            ck = json.load(fh)
    except json.JSONDecodeError:
        return None, "invalid"
    if not isinstance(ck, dict) or ck.get("entrySha") != entry_sha(entry):
        return ck, "stale"
    return ck, check_checkpoint(root, ck)


def all_checkpoints(root=ROOT):
    """Every checkpoint on disk, sorted by source key."""
    out = []
    for path in sorted(glob.glob(os.path.join(root, CKPT_DIR, "*.json"))):
        with open(path, encoding="utf-8") as fh:
            try:
                out.append(json.load(fh))
            except json.JSONDecodeError:
                out.append({"source": os.path.basename(path), "version": None})
    return sorted(out, key=lambda c: str(c.get("source")))


def submit(answer, root=ROOT, dry_run=False):
    key = answer.get("source") if isinstance(answer, dict) else None
    entry = find_entry(root, key) if isinstance(key, str) else None
    if entry is None:
        return [f"source {key!r} is not in the queue"], None
    problems, info = validate_answer(answer, entry, root)
    if problems:
        return list(problems), None
    ck = make_checkpoint(entry, answer, info)
    if not dry_run:
        dump_json(ckpt_path(root, key), ck)
    return [], ck


# ---------------------------------------------------------------- holdings and the writer
LANG_SUFFIXES = {"es", "fr", "de", "ru", "tw", "cn", "ko", "pt", "it", "mx", "br"}


def strip_lang(key):
    """wowhead:news=...@es -> wowhead:news=... (a translated copy of the same page; game flavours such as @cata stay)."""
    parts = key.split("@")
    return "@".join([parts[0]] + [x for x in parts[1:] if x not in LANG_SUFFIXES])


def held_keys(root=ROOT):
    """Normalised source keys (and threads) of every evidence row except this tool's own output."""
    by_key, by_thread = set(), set()

    def thread(k):
        k = strip_lang(k)
        if k.startswith(("blizzforum:", "reddit:")):
            return ":".join(k.split(":")[:2])
        return k.split("#c")[0]

    for path in sorted(glob.glob(os.path.join(root, "research", "v3", "evidence", "**", "*.jsonl"), recursive=True)):
        if os.path.relpath(path, root).replace(os.sep, "/") == OUT_REL:
            continue
        with open(path, encoding="utf-8") as fh:
            for line in fh:
                try:
                    r = json.loads(line)
                except json.JSONDecodeError:
                    continue
                if not isinstance(r, dict):
                    continue
                s = r.get("source") if isinstance(r.get("source"), dict) else {}
                for u in (s.get("url"), r.get("originalSource"), r.get("sourceURL")):
                    if isinstance(u, str) and u.startswith("http"):
                        k = strip_lang(normalize_url(u))
                        by_key.add(k)
                        by_thread.add(thread(k))
    return by_key, by_thread, thread


def run_writer(root=ROOT):
    """Returns (rows, report). Rows come only from current checkpoints of sources v3 does not hold. The writer
    reads the checkpoints, not the live queue: link_sources.py drops a source from the queue once its rows make it
    held, and the rows must survive that."""
    by_key, by_thread, thread = held_keys(root)
    rows, report = [], []
    for ck in all_checkpoints(root):
        state = check_checkpoint(root, ck)
        item = {"source": ck.get("source"), "state": state}
        if state != "current":
            report.append(item)
            continue
        entry, ans = ck["entry"], ck["answer"]
        item.update(status=ck["status"], reasonCode=ans.get("reasonCode"), reason=ans.get("reason"))
        if ans["result"] == "rows":
            if strip_lang(entry["source"]) in by_key or thread(entry["source"]) in by_thread:
                item.update(status="held", written=0, note="v3 holds this source now; rows not written (PLAN section 3 rule 5)")
            else:
                recs = build_records(entry, ans, root)
                rows.extend(recs)
                item.update(written=len(recs), proposals=len(ans.get("proposals") or []))
        report.append(item)
    return rows, report


def write_output(rows, root=ROOT):
    path = os.path.join(root, OUT_REL)
    if not rows:
        if os.path.exists(path):
            os.remove(path)
        return None
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as fh:
        for r in rows:
            fh.write(json.dumps(r, ensure_ascii=False, sort_keys=False) + "\n")
    return path


def render(rows):
    return "".join(json.dumps(r, ensure_ascii=False, sort_keys=False) + "\n" for r in rows)


# ---------------------------------------------------------------- CLI
def cmd_status(root):
    queue = load_queue(root)
    counts, lines, live = Counter(), [], set()
    for e in queue:
        live.add(e["source"])
        ck, state = load_checkpoint(root, e)
        label = ck["status"] if state == "current" else state
        counts[label] += 1
        lines.append(f"{label:8s} {e['source']}")
    away = [c for c in all_checkpoints(root) if c.get("source") not in live]
    for c in away:
        state = check_checkpoint(root, c)
        lines.append(f"{(c.get('status') if state == 'current' else state):8s} {c.get('source')}  (not in the live queue)")
    print("\n".join(lines))
    print(f"{len(queue)} queued sources: " + ", ".join(f"{k} {v}" for k, v in sorted(counts.items()))
          + f"; {len(away)} checkpoints outside the live queue")
    return counts


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--root", default=ROOT)
    sub = ap.add_subparsers(dest="cmd", required=True)
    sp = sub.add_parser("prompt")
    sp.add_argument("source")
    sp.add_argument("--full", action="store_true", help="whole files instead of anchor windows")
    sp.add_argument("--brief", action="store_true", help="source and text only, without the rules and schema")
    sp.add_argument("--out")
    sp = sub.add_parser("submit")
    sp.add_argument("answer")
    sp.add_argument("--dry-run", action="store_true")
    sub.add_parser("status")
    sub.add_parser("verify")
    sp = sub.add_parser("write")
    sp.add_argument("--report")
    sp.add_argument("--check", action="store_true", help="exit 1 if the output file would change")
    a = ap.parse_args(argv)
    root = a.root
    if a.cmd == "prompt":
        entry = find_entry(root, a.source)
        if not entry:
            print(f"{a.source} is not in the queue", file=sys.stderr)
            return 2
        text = build_prompt(entry, root, a.full, a.brief)
        if a.out:
            with open(a.out, "w", encoding="utf-8", newline="\n") as fh:
                fh.write(text)
        else:
            sys.stdout.write(text)
        return 0
    if a.cmd == "submit":
        with open(a.answer, encoding="utf-8") as fh:
            answer = json.load(fh)
        problems, ck = submit(answer, root, a.dry_run)
        if problems:
            print("REJECTED:\n  " + "\n  ".join(problems))
            return 1
        print(f"accepted {ck['source']}: {ck['status']}, {ck['rows']} rows, {ck['proposals']} proposals"
              + (" (dry run)" if a.dry_run else ""))
        return 0
    if a.cmd == "status":
        cmd_status(root)
        return 0
    if a.cmd == "verify":
        counts = cmd_status(root)
        return 0 if set(counts) <= {"rows", "null"} else 1
    rows, report = run_writer(root)
    text = render(rows)
    path = os.path.join(root, OUT_REL)
    if a.check:
        have = open(path, encoding="utf-8").read() if os.path.exists(path) else ""
        return 0 if have == text else 1
    write_output(rows, root)
    states = Counter(r.get("status") or r["state"] for r in report)
    print(f"{len(rows)} rows from {sum(1 for r in report if r.get('written'))} sources -> {OUT_REL}; "
          + ", ".join(f"{k} {v}" for k, v in sorted(states.items())))
    if a.report:
        dump_json(a.report if os.path.isabs(a.report) else os.path.join(root, a.report),
                  {"rows": len(rows), "sources": report})
    return 0


if __name__ == "__main__":
    sys.exit(main())
