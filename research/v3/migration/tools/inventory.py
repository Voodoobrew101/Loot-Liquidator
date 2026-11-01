#!/usr/bin/env python3
"""M01: deterministic inventory of every historical research file.

Read-only with respect to evidence: it never edits any research file. It writes only to
research/v3/migration/manifest/ (or --out).

For every historical file (everything under research/ except research/v3/, plus the addon
data files that earlier research was compiled into) it records:
  path, category, format, size, sha256, record counts, how many study-shaped objects or
  numeric-claim lines it holds, the source URLs it cites (normalized), the study IDs it
  names, whether those URLs / IDs already appear in research/v3/evidence/, and a
  PRELIMINARY disposition. Final dispositions are assigned by later tasks (M03-M07).

Outputs (all sorted, no timestamps except the snapshot commit, so reruns are byte-identical):
  inventory.jsonl       one line per historical file
  url-registry.jsonl    one line per normalized source URL (the shared source registry)
  snapshot.json         repository commit + headline counts
  inventory-summary.md  human summary

Usage, from the repository root:
  python3 research/v3/migration/tools/inventory.py [--root DIR] [--out DIR] [--commit SHA]
"""
import argparse
import glob
import hashlib
import json
import os
import re
import subprocess
import sys
from collections import Counter, defaultdict

DEFAULT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "..", ".."))

# Addon files that earlier research pipelines compiled data into (read as sources only).
ADDON_DATA_FILES = ["GameData.lua", "StatYieldProfiles.lua", "ResearchDB.lua"]

# Category by path prefix; first match wins. Order matters (more specific first).
CATEGORIES = [
    ("research/evidence/observations/", "observation"),
    ("research/evidence/v2/source-reviews/", "v2-source-review"),
    ("research/evidence/v2/", "v2-evidence"),
    ("research/evidence/leads/", "lead"),
    ("research/evidence/", "evidence-meta"),
    ("research/coordination/v2/submissions/", "v2-submission"),
    ("research/coordination/v2/", "v2-coordination"),
    ("research/coordination/submissions/", "worker-submission"),
    ("research/coordination/source-reviews/", "source-review"),
    ("research/coordination/qa-feedback/", "qa-feedback"),
    ("research/coordination/confidence-snapshots/", "confidence-snapshot"),
    ("research/coordination/reviews/", "review"),
    ("research/coordination/", "coordination-doc"),
    ("research/ledger/", "ledger"),
    ("research/proposed/", "proposed"),
    ("research/models/", "model"),
    ("research/mechanics/", "mechanics"),
    ("research/reviews/", "review"),
    ("research/tests/", "test"),
    ("research/tools/", "tool"),
    ("research/prompts/", "prompt"),
    ("research/", "research-doc"),
]
# Categories that hold process/tooling/derived material, not raw observations.
PROCESS_CATEGORIES = {"test", "tool", "prompt", "confidence-snapshot", "qa-feedback",
                      "v2-coordination", "coordination-doc", "evidence-meta"}

# Keys that mark a JSON object as carrying observational numbers.
STUDY_KEYS = {
    "outputs", "totalUnits", "completedOperations", "actualCompletedOperations", "hitOperations",
    "perOperationHistogram", "castsWithDrop", "totalQuantity", "reportedInputsConsumed",
    "fiveOreEquivalentOperations", "fiveHerbEquivalentOperations", "rawNamedCounts",
    "originalRawOre", "originalActualCompletedCasts", "cohorts", "sampleOperations",
    "reportedOccurrenceProbability", "rawReportedOre", "reportedOre", "sourceInputQuantity",
}
ID_KEYS = {"studyID", "observationID", "studyKey", "originalStudyID"}
MD_NUMERIC = re.compile(
    r"\d[\d,]*(\.\d+)?\s*(x\s*)?(casts?|prospects?|mills?|millings?|ore|herbs?|operations?|"
    r"disenchants?|crafts?|stacks?|clicks?)\b", re.I)
URL_RE = re.compile(r"https?://[^\s\"'<>)\]\|`]+")
SELF_HOSTS = ("github.com/voodoobrew101", "raw.githubusercontent.com/voodoobrew101")
TEXT_EXT = {".md", ".txt", ".csv", ".json", ".jsonl", ".lua", ".js", ".py", ".xml", ".toc"}


# ---------------------------------------------------------------- URL normalization
def normalize_url(url):
    """Stable key for a source URL so copies of one link compare equal.
    Keeps what distinguishes a source (Reddit post ID, Wowhead entity + comment ID, forum
    thread ID); drops slugs, query strings, tracking and trailing punctuation."""
    u = url.strip().rstrip(".,;:'\"*)")
    u = re.sub(r"^https?://", "", u, flags=re.I)
    host, _, rest = u.partition("/")
    host = host.lower()
    for pre in ("www.", "old.", "new.", "np."):
        if host.startswith(pre):
            host = host[len(pre):]
    frag = ""
    if "#" in rest:
        rest, frag = rest.split("#", 1)
    rest = rest.split("?", 1)[0].rstrip("/")
    if host.endswith("reddit.com") or host == "redd.it":
        m = re.search(r"comments/([a-z0-9]+)(?:/[^/]*/([a-z0-9]+))?", rest, re.I)
        if m:
            return "reddit:" + m.group(1).lower() + (":" + m.group(2).lower() if m.group(2) else "")
        return "reddit:/" + rest.lower()
    if host.endswith("wowhead.com"):
        sub = host[: -len("wowhead.com")].rstrip(".")
        m = re.search(r"^(?:([\w-]+)/)?(item|spell|npc|object|quest|guide|news|guides)[=/]([\w-]+)", rest)
        key = f"wowhead:{m.group(2)}={m.group(3)}" if m else "wowhead:/" + rest.lower()
        if m and m.group(1):  # game flavour path such as wotlk/, classic/, ptr/
            key += "@" + m.group(1).lower()
        if sub and sub not in ("www",):
            key += "@" + sub
        c = re.search(r"comments:id=(\d+)", frag)
        if c:
            key += "#c" + c.group(1)
        return key
    if "forums.blizzard.com" in host:
        m = re.search(r"/t/(?:[^/]+/)?(\d+)(?:/(\d+))?", "/" + rest)
        if m:
            return "blizzforum:" + m.group(1) + (":" + m.group(2) if m.group(2) else "")
    if host == "docs.google.com":
        m = re.search(r"/d/([\w-]+)", rest)
        if m:
            return "gdoc:" + m.group(1)
    return host + "/" + rest.lower()


def is_self_link(url):
    low = url.lower()
    return any(h in low for h in SELF_HOSTS)


# ---------------------------------------------------------------- v3 index
def load_v3_index(root):
    urls = defaultdict(int)
    keys, ids, notes_files = set(), set(), set()
    for path in sorted(glob.glob(os.path.join(root, "research", "v3", "evidence", "**", "*.jsonl"),
                                 recursive=True)):
        for line in open(path, encoding="utf-8"):
            line = line.strip()
            if not line:
                continue
            try:
                r = json.loads(line)
            except json.JSONDecodeError:
                continue
            for u in ((r.get("source") or {}).get("url"), r.get("originalSource")):
                if isinstance(u, str) and u.startswith("http"):
                    urls[normalize_url(u)] += 1
            for u in URL_RE.findall(r.get("notes") or ""):
                urls[normalize_url(u)] += 0  # mentioned, not the record's own source
            if r.get("studyKey"):
                keys.add(str(r["studyKey"]))
            if r.get("id"):
                ids.add(str(r["id"]))
            m = re.search(r"Imported from (research/evidence/observations/\S+?)(;|$)", r.get("notes") or "")
            if m:
                notes_files.add(m.group(1))
    return {"urls": dict(urls), "studyKeys": keys, "ids": ids, "importedFiles": notes_files}


# ---------------------------------------------------------------- per-file scan
def category_of(rel):
    if "/" not in rel:
        return "addon-data"
    for prefix, cat in CATEGORIES:
        if rel.startswith(prefix):
            return cat
    return "other"


def walk_json(obj, acc):
    if isinstance(obj, dict):
        # A key only counts when it carries a value: TSM field audits list e.g. "sampleOperations": null.
        if any(obj.get(k) not in (None, "", [], {}) for k in STUDY_KEYS & obj.keys()):
            acc["study"] += 1
        for k, v in obj.items():
            if k in ID_KEYS and isinstance(v, (str, int)) and v != "":
                acc["ids"].add(str(v))
            walk_json(v, acc)
    elif isinstance(obj, list):
        for v in obj:
            walk_json(v, acc)


def scan_file(root, rel, v3):
    path = os.path.join(root, rel)
    data = open(path, "rb").read()
    ext = os.path.splitext(rel)[1].lower()
    info = {
        "path": rel, "category": category_of(rel), "format": ext.lstrip(".") or "none",
        "bytes": len(data), "sha256": hashlib.sha256(data).hexdigest(),
        "records": None, "parseErrors": 0, "studyObjects": 0, "numericClaimLines": 0,
    }
    text = data.decode("utf-8", errors="replace") if ext in TEXT_EXT or not ext else ""
    acc = {"study": 0, "ids": set()}
    if ext == ".jsonl":
        n = 0
        for line in text.splitlines():
            if not line.strip():
                continue
            n += 1
            try:
                walk_json(json.loads(line), acc)
            except json.JSONDecodeError:
                info["parseErrors"] += 1
        info["records"] = n
    elif ext == ".json":
        try:
            d = json.loads(text)
            info["records"] = len(d) if isinstance(d, list) else 1
            walk_json(d, acc)
        except json.JSONDecodeError:
            info["parseErrors"] = 1
    elif ext in (".md", ".txt", ".csv"):
        info["numericClaimLines"] = sum(1 for ln in text.splitlines() if MD_NUMERIC.search(ln))
        if ext == ".csv":
            info["records"] = max(0, len([ln for ln in text.splitlines() if ln.strip()]) - 1)
    info["studyObjects"] = acc["study"]

    raw_urls = [u for u in URL_RE.findall(text) if not is_self_link(u)]
    keys = sorted({normalize_url(u) for u in raw_urls})
    in_v3 = [k for k in keys if k in v3["urls"]]
    info["urls"] = len(keys)
    info["urlsInV3"] = len(in_v3)
    info["urlsNotInV3"] = [k for k in keys if k not in v3["urls"]]
    ids = sorted(acc["ids"])
    info["studyIDs"] = len(ids)
    info["studyIDsInV3"] = sum(1 for i in ids if i in v3["studyKeys"] or i in v3["ids"])
    info["importedByV3Importer"] = rel in v3["importedFiles"]
    info["disposition"] = preliminary_disposition(info)
    return info, keys, raw_urls


def preliminary_disposition(i):
    cat = i["category"]
    has_data = i["studyObjects"] > 0 or i["numericClaimLines"] > 0
    if i["path"] in ("research/proposed/itemdb.lua",) or cat == "addon-data" and i["path"] == "GameData.lua":
        return "reference-imported-partial"
    if i["importedByV3Importer"]:
        return "imported"
    if cat in PROCESS_CATEGORIES:
        return "process-artifact"
    if cat in ("model",):
        return "derived-model"
    if cat in ("mechanics",):
        return "mechanics-knowledge"
    if not has_data:
        return "no-observational-content" if not i["urlsNotInV3"] else "source-links-only"
    if i["urls"] == 0:
        return "candidate-no-url"
    if not i["urlsNotInV3"]:
        return "covered-by-url"
    return "candidate-unmigrated"


# ---------------------------------------------------------------- main
def list_files(root):
    out = []
    for dirpath, dirnames, filenames in os.walk(os.path.join(root, "research")):
        dirnames[:] = sorted(d for d in dirnames if d not in ("__pycache__", ".git"))
        rel_dir = os.path.relpath(dirpath, root).replace(os.sep, "/")
        if rel_dir == "research/v3" or rel_dir.startswith("research/v3/"):
            continue
        for f in sorted(filenames):
            out.append(f"{rel_dir}/{f}")
    for f in ADDON_DATA_FILES:
        if os.path.exists(os.path.join(root, f)):
            out.append(f)
    return sorted(out)


def git_commit(root):
    try:
        return subprocess.check_output(["git", "-C", root, "rev-parse", "HEAD"], text=True,
                                       stderr=subprocess.DEVNULL).strip()
    except Exception:
        return None


def run(root, out, commit=None):
    v3 = load_v3_index(root)
    files = list_files(root)
    inventory, registry = [], defaultdict(lambda: {"files": set(), "example": None})
    for rel in files:
        info, keys, raw = scan_file(root, rel, v3)
        inventory.append(info)
        for u in raw:
            k = normalize_url(u)
            reg = registry[k]
            reg["files"].add(rel)
            if reg["example"] is None or len(u) < len(reg["example"]):
                reg["example"] = u
    os.makedirs(out, exist_ok=True)
    with open(os.path.join(out, "inventory.jsonl"), "w", encoding="utf-8", newline="\n") as fh:
        for i in inventory:
            fh.write(json.dumps(i, ensure_ascii=False, sort_keys=True) + "\n")
    reg_rows = []
    for k in sorted(registry):
        r = registry[k]
        reg_rows.append({"key": k, "example": r["example"], "historicalFiles": len(r["files"]),
                         "inV3": k in v3["urls"], "v3SourceRecords": v3["urls"].get(k, 0),
                         "files": sorted(r["files"])[:20]})
    with open(os.path.join(out, "url-registry.jsonl"), "w", encoding="utf-8", newline="\n") as fh:
        for r in reg_rows:
            fh.write(json.dumps(r, ensure_ascii=False, sort_keys=True) + "\n")
    snap = summarize(inventory, reg_rows, commit if commit is not None else git_commit(root))
    with open(os.path.join(out, "snapshot.json"), "w", encoding="utf-8", newline="\n") as fh:
        json.dump(snap, fh, indent=1, sort_keys=True)
        fh.write("\n")
    with open(os.path.join(out, "inventory-summary.md"), "w", encoding="utf-8", newline="\n") as fh:
        fh.write(render_md(snap, inventory))
    return snap


def summarize(inv, reg, commit):
    by_cat = defaultdict(Counter)
    for i in inv:
        by_cat[i["category"]]["files"] += 1
        by_cat[i["category"]][i["disposition"]] += 1
    data_urls = [r for r in reg if r["key"].split(":")[0] in ("reddit", "wowhead", "blizzforum", "gdoc")
                 or "." in r["key"].split("/")[0]]
    return {
        "snapshotCommit": commit,
        "historicalFiles": len(inv),
        "bytes": sum(i["bytes"] for i in inv),
        "parseErrorFiles": sum(1 for i in inv if i["parseErrors"]),
        "dispositions": dict(sorted(Counter(i["disposition"] for i in inv).items())),
        "categories": {k: dict(sorted(v.items())) for k, v in sorted(by_cat.items())},
        "sourceURLs": len(data_urls),
        "sourceURLsInV3": sum(1 for r in data_urls if r["inV3"]),
        "sourceURLsNotInV3": sum(1 for r in data_urls if not r["inV3"]),
        "studyObjects": sum(i["studyObjects"] for i in inv),
        "numericClaimLines": sum(i["numericClaimLines"] for i in inv),
    }


def render_md(s, inv):
    lines = ["# Historical research inventory (generated)", "",
             f"Generated by `research/v3/migration/tools/inventory.py` at commit `{s['snapshotCommit']}`.",
             "Dispositions are PRELIMINARY (rule-based); later tasks assign final ones.", "",
             f"- Historical files: {s['historicalFiles']:,} ({s['bytes']/1e6:.1f} MB); unparseable JSON files: {s['parseErrorFiles']}",
             f"- JSON objects carrying observational numbers: {s['studyObjects']:,}; Markdown/CSV numeric-claim lines: {s['numericClaimLines']:,}",
             f"- Distinct source URLs cited: {s['sourceURLs']:,}; already cited by v3 evidence: {s['sourceURLsInV3']:,}; not yet in v3: {s['sourceURLsNotInV3']:,}",
             "", "## Preliminary dispositions", "", "| Disposition | Files |", "| --- | --- |"]
    lines += [f"| {k} | {v} |" for k, v in s["dispositions"].items()]
    lines += ["", "## By category", "", "| Category | Files | Dispositions |", "| --- | --- | --- |"]
    for cat, c in s["categories"].items():
        d = ", ".join(f"{k} {v}" for k, v in c.items() if k != "files")
        lines.append(f"| {cat} | {c['files']} | {d} |")
    cands = sorted((i for i in inv if i["disposition"] == "candidate-unmigrated"),
                   key=lambda i: (-len(i["urlsNotInV3"]), i["path"]))
    lines += ["", "## Unmigrated candidates with the most uncited source URLs (first 40)", "",
              "| File | Study objects | Numeric lines | URLs not in v3 |", "| --- | --- | --- | --- |"]
    for i in cands[:40]:
        lines.append(f"| `{i['path']}` | {i['studyObjects']} | {i['numericClaimLines']} | {len(i['urlsNotInV3'])} |")
    return "\n".join(lines) + "\n"


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--root", default=DEFAULT_ROOT)
    ap.add_argument("--out", default=None)
    ap.add_argument("--commit", default=None, help="override snapshot commit (tests)")
    a = ap.parse_args(argv)
    out = a.out or os.path.join(a.root, "research", "v3", "migration", "manifest")
    s = run(a.root, out, a.commit)
    print(f"{s['historicalFiles']} historical files; dispositions {s['dispositions']}; "
          f"source URLs {s['sourceURLs']} ({s['sourceURLsInV3']} in v3)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
