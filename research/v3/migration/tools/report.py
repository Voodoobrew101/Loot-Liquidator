#!/usr/bin/env python3
"""M09: the migration audit. Before/after coverage, confidence bands, dispositions, record usage and the unresolved register.

Read-only: changes no evidence, estimator, manifest or output/ file; writes only the two report files below. Everything it
compares is measured here. Each stage in STAGES is exported from git into a temporary folder and rebuilt with that commit's own
estimator (no build ever touches output/), so "before" is a rebuild of the snapshot and the cause of a band move is the stage it
moved in, not a quote from an older report. PLAN section 1 is only read to check the snapshot rebuild still agrees with it.

The snapshot's estimator has the Windows `_file` bug fixed in M05 (SESSION_LOG MIG-002). The exported copy gets that one-line fix
so that corrections apply on every platform; the line is unchanged on Linux.

Writes, sorted and without timestamps, so a rerun on the same machine is byte-identical:

  reports/M09-audit.md          the report; every figure comes from M09-audit-data.json or from a quoted report or manifest row
  reports/M09-audit-data.json   all the numbers, every band move, every register row

Confidence values depend on SciPy (build_estimates.confidence() has a fallback), so the report states which setting produced them.
Needs the branch's git history (a shallow clone: git fetch --depth=1000 origin migration/v3-historical-research).

Register rows come from four places: the numbered items of the sections in MASTER_SECTIONS (parsed, so a new item fails a test until
it has an entry in ITEMS), manifest/exceptions.jsonl, the validator's errors and manifest/scope-gap.jsonl.
`m10` says what an open row means for M10: blocks (a step of M10 cannot finish without an owner decision), handle (M10 must take it
into account, no decision needed), none.

Usage, from the repository root:
  python3 research/v3/migration/tools/report.py [--check] [--no-tests]
"""
import argparse
import collections
import concurrent.futures
import glob
import hashlib
import importlib
import io
import json
import os
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "..", ".."))
V3 = os.path.join(ROOT, "research", "v3")
MIG = os.path.join(V3, "migration")
REPORTS = os.path.join(MIG, "reports")
MANIFEST = os.path.join(MIG, "manifest")
TESTS = os.path.join(MIG, "tests")
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(V3, "tools"))  # a measuring child puts its own tree's tools in front of this
OUT_MD = os.path.join(REPORTS, "M09-audit.md")
OUT_JSON = os.path.join(REPORTS, "M09-audit-data.json")

BAND_ORDER = ("90%+", "75-89%", "50-74%", "under 50%", "conditional")
SNAPSHOT = "575b2529d02820ca4ad77851624dc7ecd7f8d740"
# (stage, commit, cause of what changed since the previous stage). The commits are the ones the session log names.
STAGES = (
    ("snapshot", SNAPSHOT, None),
    ("M05", "5d99342", "identity (M05)"),
    ("M03", "788598a", "new evidence (M03)"),
    ("M03b", "98893b8", "new evidence (M03)"),
    ("M06", "a8fdc45", "units (M06)"),
    ("M04.1-2", "bbe0516", "new evidence (M04)"),
    ("M04.3-4", "7e0ecba", "new evidence (M04)"),
    ("M07", "d4390b8", "none expected (M07)"),
    ("M08", "0233968", "none expected (M08)"),
    ("M10 merge", "e9a0243", "agent evidence and the S7 page rule (M10 merge)"),
)
FINAL_STAGE = ("working tree", "importer and manifests rerun (M10)")
TREE_PATHS = ("research/v3/tools", "research/v3/evidence", "research/v3/corrections.jsonl", "research/v3/conditions.jsonl",
              "research/v3/rate-changes.jsonl")
BUILD_OUTPUTS = ("estimates.json", "summary.md", "unused.json")

REASON_TEXT = {
    "averageNoBatch": "states an average, but no batch size to convert it to the group's unit",
    "chanceNotConvertible": "a per-cast chance from another batch size, which cannot be converted",
    "condition:incomplete": "a condition record without a method or an output item",
    "conditional:unlockFalse": "a conditional output, and the study says the unlock was absent",
    "conditional:unlockUnstated": "a conditional output, and the study does not state the unlock",
    "copy:pooledStudy": "a study that is the exact sum of a batch family counted on its own",
    "copy:vaguerGroup": "a copy of a row held in a more specific group",
    "duplicateRowInStudy": "a second row of one study in the same group; only the first counts",
    "duplicateStudy": "a copy of a study already counted in the group",
    "hitsWithoutCasts": "states how many casts hit, with no cast count",
    "noNumbers": "a placed row with no usable number",
    "percentNotPerCast": "a percentage that is not stated to be per cast",
    "percentOutOfRange": "a per-cast percentage outside 0 to 100",
    "reference:noUsableValue": "a reference row with neither a chance nor an average",
    "reference:otherUnit": "a reference chance for another batch size",
    "reference:priorSuperseded": "a reference chance dropped because studies measured the average",
    "totalNoBatch": "states a total and casts, but no batch size to convert it",
    "totalWithoutCasts": "states a total with no cast count or input count, so no rate follows (S16)",
    "type:exchange": "a fixed exchange, not a drop; the estimator builds drop estimates only",
    "type:missing": "no record type",
    "type:noDisenchant": "says an item cannot be disenchanted; not a drop",
    "type:rateChange": "a dated rate change; read for the epochs, not a drop",
    "type:recipe": "a recipe fact, not a drop",
    "type:searched": "a record of a search that found nothing",
    "type:token": "a token mapping, not a drop",
    "type:unknown": "a record type the estimator does not know",
    "unplaced:noInput": "no input item or name, so it fits no group",
    "unplaced:noMethod": "no method, so it fits no group",
    "unplaced:noOutput": "no output ID, mostly name-only rows kept by PLAN section 3 rule 4",
}

MASTER_SECTIONS = {  # report -> [(tag, heading pattern)]
    "M03-import.md": [("master", r"^## For the Master")],
    "M03b-import.md": [("master", r"^## For the Master")],
    "M04-extraction.md": [("scope", r"^## Two scope findings"), ("master", r"^## For the Master")],
    "M04-links.md": [("master", r"^## For the Master")],
    "M05-identity.md": [("master", r"^## Proposal for the Master")],
    "M06-units.md": [("master", r"^## For the Master")],
    "M07-dispositions.md": [("master", r"^## For the Master")],
    "M08-estimator.md": [("findings", r"^## 6\. Findings"), ("master", r"^## For the Master")],
    "M10-merge.md": [("master", r"^## For the Master")],
}


def backfill(key):
    return lambda c: c["m06"]["backfill"][key]["rows"]


def reason_count(*codes):
    return lambda c: sum(c["usage"]["unusedByReason"].get(k, 0) for k in codes)


def exception_count(*kinds):
    return lambda c: sum(c["exceptionKinds"].get(k, 0) for k in kinds)


# One entry per parsed item. status open: kind, m10, action; status closed: closedBy (a file that shows it was dealt with).
# `see` points at the row that carries the same decision, so that the owner answers it once. `count` is computed.
ITEMS = {
    "M03-import/master#1": dict(kind="policy", m10="none", action="Confirm or change the name-only placement rule.",
                                count=reason_count("unplaced:noOutput")),
    "M03-import/master#2": dict(kind="strategy", m10="none", action="Use these cohorts when closing S14."),
    "M03-import/master#3": dict(kind="data-cleanup", m10="none",
                                action="Give the ranked input ID and keep one record of each refine recipe."),
    "M03b-import/master#1": dict(closedBy="reports/M06-units.md"),
    "M03b-import/master#2": dict(kind="source-check", m10="none", see="exceptions:total-differs-from-source",
                                 action="Check the source, then correct the copy that is wrong.",
                                 count=exception_count("total-differs-from-source")),
    "M03b-import/master#3": dict(kind="source-check", m10="none", see="exceptions:unverified-output-count",
                                 action="Check the post; an agent records the cohort if the counts are there.",
                                 count=exception_count("unverified-output-count")),
    "M03b-import/master#4": dict(closedBy="reports/M04-links.md"),
    "M04-extraction/scope#1": dict(closedBy="reports/M07-dispositions.md"),
    "M04-extraction/scope#2": dict(closedBy="PLAN.md"),
    "M04-extraction/master#1": dict(kind="policy", m10="none", count=lambda c: c["extractedRecipeRows"],
                                    action="Keep the recipe rows written from entity pages, or set their checkpoints to null."),
    "M04-extraction/master#2": dict(kind="policy", m10="none", see="M03-import/master#1",
                                    action="Answered by the name-only placement rule."),
    "M04-extraction/master#3": dict(kind="policy", m10="none", see="exceptions:ambiguous-doubt-source",
                                    action="Say whether any of these becomes a reference row with an unclear meaning.",
                                    count=exception_count("ambiguous-doubt-source")),
    "M04-extraction/master#4": dict(closedBy="reports/M07-dispositions.md"),
    "M04-extraction/master#5": dict(closedBy="reports/M07-dispositions.md"),
    "M04-extraction/master#6": dict(kind="policy", m10="handle",
                                    action="Decide on comment-level source keys for Wowhead item pages.",
                                    m10Why="If agents record another comment on such a page, the writer reports the rows as held."),
    "M04-links/master#1": dict(closedBy="reports/PR-REPAIR-2026-11-02.md"),
    "M04-links/master#2": dict(closedBy="reports/PR-REPAIR-2026-11-02.md"),
    "M04-links/master#3": dict(kind="source-check", m10="none", see="exceptions:unverified-output-count",
                               action="The six Jallfo cooutput gaps are source-linked; verify the remaining original output count.",
                               count=exception_count("imported-vs-agent-totals-differ", "unverified-output-count")),
    "M04-links/master#4": dict(closedBy="reports/M04-extraction.md"),
    "M04-links/master#5": dict(closedBy="reports/M04-links.md"),
    "M05-identity/master#1": dict(kind="policy", m10="none", action="Confirm the numbered-batch and pooled-study rules."),
    "M05-identity/master#2": dict(kind="agent-rule", m10="none", action="Add the proposed line to roles/worker.md, or decline it."),
    "M05-identity/master#3": dict(kind="corrections", m10="none", see="exceptions:cross-source-identity-pair",
                                  action="Decide the listed corrections after reading the posts.",
                                  count=exception_count("single-row-subset", "cross-source-identity-pair",
                                                        "identity-merge-with-conflict")),
    "M05-identity/master#4": dict(kind="constraint", m10="handle", action="Set keys on both sides, or keep fingerprints.",
                                  m10Why="M10 must not set cohortKey on imported rows alone."),
    "M05-identity/master#5": dict(closedBy="PLAN.md"),
    "M06-units/master#1": dict(kind="policy", m10="none", action="Approve the equivalent-cast weight and the unit rule, or set another value."),
    "M06-units/master#2": dict(kind="backfill", m10="none", count=lambda c: backfill("totalsWithInputInNotes")(c) + backfill("castsCountedFromInputs")(c),
                               action="Decide both backfills, including whether the do-not-infer rows should count."),
    "M06-units/master#3": dict(kind="strategy", m10="none", see="M03-import/master#2", action="Use when closing S14."),
    "M06-units/master#4": dict(kind="data-cleanup", m10="none", count=lambda c: c["estimatesNoBatch"],
                               action="Add the one-item-per-cast disenchanting fact to mechanics.md if wanted."),
    "M07-dispositions/master#1": dict(kind="validator", m10="handle", see="exceptions:validator-error",
                                      action="Approve the proposed correction lines, or send the records back to their agents.",
                                      m10Why="The METHODS wording belongs in the evidence-format.md proposal; both options can be proposed.",
                                      count=exception_count("validator-error")),
    "M07-dispositions/master#2": dict(kind="exceptions", m10="none", see="exceptions:held-source-numbers-differ",
                                      action="Work through the groups by source, and say whether closed groups are recorded.",
                                      count=exception_count("held-source-numbers-differ")),
    "M07-dispositions/master#3": dict(kind="source-check", m10="none", see="M04-links/master#3",
                                      action="Read the original posts; these cannot be settled offline."),
    "M07-dispositions/master#4": dict(kind="policy", m10="none", see="M03-import/master#1",
                                      action="Agents record them with IDs, or document an exception for unique names."),
    "M07-dispositions/master#5": dict(kind="policy", m10="none", see="M04-extraction/master#3",
                                      action="Same decision as the ambiguous-doubt sources."),
    "M07-dispositions/master#6": dict(kind="corrections", m10="none", see="M05-identity/master#3",
                                      action="Same decision as the M05 corrections."),
    "M07-dispositions/master#7": dict(kind="backfill", m10="none", see="M06-units/master#2",
                                      action="Same decision as the M06 backfills."),
    "M07-dispositions/master#8": dict(kind="policy", m10="none", see="M04-extraction/master#6",
                                      action="Comment-level source keys would make the label stricter."),
    "M08-estimator/findings#1": dict(kind="statistics", m10="none", see="M08-estimator/master#4",
                                     action="Decide per-rank totals in family groups.", count=reason_count("duplicateRowInStudy")),
    "M08-estimator/findings#2": dict(kind="statistics", m10="none", see="M08-estimator/master#5",
                                     action="Decide whether unused rows may widen an observed range."),
    "M08-estimator/findings#3": dict(closedBy="reports/M08-estimator.md"),
    "M08-estimator/master#1": dict(kind="policy", m10="handle", action="Choose one confidence method, then decide the output/ policy.",
                                   m10Why="Until decided M10 commits no output/ file and compares hashes on one machine only."),
    "M08-estimator/master#2": dict(kind="schema", m10="blocks", action="Choose the unlockState rule for evidence-format.md.",
                                   m10Why="M10 proposes the evidence-format.md changes; this one cannot be written until the null rule is chosen."),
    "M08-estimator/master#3": dict(kind="backfill", m10="none", see="M06-units/master#2",
                                   action="Same decision as the M06 backfills.", count=reason_count("totalWithoutCasts")),
    "M08-estimator/master#4": dict(kind="statistics", m10="none", action="Decide whether per-rank totals are summed in a family group."),
    "M08-estimator/master#5": dict(kind="statistics", m10="none",
                                   action="Confirm that duplicates and no-number rows should not widen an observed range."),
    "M08-estimator/master#6": dict(kind="data-cleanup", m10="none", see="exceptions:validator-error",
                                   action="Fix the two incomplete condition records; the validator errors are covered elsewhere.",
                                   count=reason_count("condition:incomplete")),
}
ITEMS.update({
    "M10-merge/master#1": dict(kind="policy", m10="none", action="Say whether the Wowhead page rule moves into normalize_url (it changes the URL registry, the linker and the importer)."),
    "M10-merge/master#2": dict(kind="tool", m10="none", count=lambda c: c["identityNotQueued"],
                               action="Regenerate dispositions from the current identity lists, or leave the queue on M05's."),
    "M10-merge/master#3": dict(kind="tool", m10="none", see="M08-estimator/master#4", count=lambda c: c["stillDiffering"],
                               action="Compare identity groups per input rank, so a re-recorded study reads as identical."),
    "M10-merge/master#4": dict(kind="agent-rule", m10="none", see="strategy:S18", action="Answered by the S18 decision."),
    "M10-merge/master#5": dict(kind="source-check", m10="none", see="strategy:S19",
                               action="Wait for the reviewer's rank-ID table before touching any Serevite row."),
    "M10-merge/master#6": dict(kind="agent-rule", m10="none", see="M05-identity/master#2", count=reason_count("duplicateStudy"),
                               action="Apply the roles/worker.md line, or decline it."),
})
HANDOFF_ITEMS = (
    dict(id="strategy:S18", source="research/v3/strategy.md", needle="### S18:", kind="agent-rule", m10="none",
         action="Say whether record IDs should start with the file's time (the reviewer's proposed line for evidence-format.md).",
         count=lambda c: c["idReuseWarnings"]),
    dict(id="strategy:S19", source="research/v3/strategy.md", needle="### S19:", kind="source-check", m10="none",
         action="Confirm which item ID is rank 1, 2 and 3 for Serevite and the other ores; no record was changed.",
         count=lambda c: 1),
    dict(id="HANDOFF/unused-json", source="research/v3/migration/HANDOFF.md", needle="Open question to the owner from MIG-009",
         kind="policy", m10="handle", see="M08-estimator/master#1", action="Say whether unused.json should live outside output/.",
         m10Why="It is a one-line change in build_estimates.main(); M10 should not move it undecided."),
)


def rel(path):
    return os.path.relpath(path, ROOT).replace(os.sep, "/")


def jl(path):
    with open(path, encoding="utf-8") as f:
        return [json.loads(line) for line in f if line.strip()]


def read_json(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def sha256(path):
    with open(path, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()


# ---------------------------------------------------------------- measuring one tree (runs in a child process)
def measure(tree):
    """What one tree's own estimator says about its own evidence. Uses build(), which writes nothing."""
    sys.path.insert(0, os.path.join(tree, "research", "v3", "tools"))
    b = importlib.import_module("build_estimates")
    rows = b.load()
    results, unplaced = b.build(rows)
    drops = [r for r in rows if r.get("type") == "drop"]
    study = [r for r in drops if r.get("sourceKind") not in b.REFERENCE_KINDS]
    out = {
        "records": len(rows), "unplaced": unplaced, "dropRows": len(drops), "studyRows": len(study),
        "referenceRows": len(drops) - len(study), "studyKeys": len({r.get("studyKey") for r in study if r.get("studyKey")}),
        "byType": dict(sorted(collections.Counter(str(r.get("type")) for r in rows).items())),
        "estimates": [{k: e.get(k) for k in ("method", "input", "outputItemID", "confidence", "conditional", "chanceSource",
                                             "studyCasts", "inputsPerCast")} for e in results],
    }
    if hasattr(b, "analyze"):
        _, _, usage = b.analyze(rows)
        report = b.unused_report(rows, usage)
        out["usage"] = {k: report[k] for k in ("records", "used", "unused", "unusedByReason", "usedByRole")}
    return out


def run_measure(tree):
    p = subprocess.run([sys.executable, os.path.abspath(__file__), "--measure", tree], capture_output=True, encoding="utf-8")
    if p.returncode:
        raise RuntimeError(f"measuring {tree} failed: {p.stderr}")
    return json.loads(p.stdout)


def export_tree(commit, dest):
    p = subprocess.run(["git", "-C", ROOT, "archive", "--format=tar", commit, *TREE_PATHS], capture_output=True)
    if p.returncode:
        raise RuntimeError(f"git archive {commit}: {p.stderr.decode()} (shallow clone? see the header of this file)")
    with tarfile.open(fileobj=io.BytesIO(p.stdout)) as tar:
        tar.extractall(dest, filter="data")


def copy_working_tree(dest):
    for path in TREE_PATHS:
        src, to = os.path.join(ROOT, path), os.path.join(dest, path)
        if os.path.isdir(src):
            shutil.copytree(src, to, ignore=shutil.ignore_patterns("__pycache__"))
        else:
            os.makedirs(os.path.dirname(to), exist_ok=True)
            shutil.copy2(src, to)


def fix_snapshot_estimator(tree):
    """The M05 Windows fix, in the exported copy only (see the file header)."""
    path = os.path.join(tree, "research", "v3", "tools", "build_estimates.py")
    with open(path, encoding="utf-8", newline="") as f:
        text = f.read()
    old = 'r["_file"] = os.path.relpath(path, ROOT)'
    fixed = 'r["_file"] = os.path.relpath(path, ROOT).replace(os.sep, "/")'
    # git archive can apply core.autocrlf to the exported source. Match the
    # statement independently of its line ending and preserve every other byte.
    if old + "\n" not in text.replace("\r\n", "\n"):
        raise RuntimeError("the snapshot estimator no longer has the line to fix")
    with open(path, "w", encoding="utf-8", newline="") as f:
        f.write(text.replace(old, fixed))


def rebuild_hashes(tree):
    """Run the tree's build_estimates.py as a program (it writes to the tree's own output/) and hash what it wrote."""
    script = os.path.join(tree, "research", "v3", "tools", "build_estimates.py")
    subprocess.run([sys.executable, script], check=True, capture_output=True)
    return {n: sha256(os.path.join(tree, "research", "v3", "output", n)) for n in BUILD_OUTPUTS}


def measure_stages(tmp):
    def one(stage):
        name, commit, _ = stage
        tree = os.path.join(tmp, name)
        export_tree(commit, tree)
        if commit == SNAPSHOT:
            fix_snapshot_estimator(tree)
        return run_measure(tree)

    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        measured = list(pool.map(one, STAGES))
    return {s[0]: m for s, m in zip(STAGES, measured)}


# ---------------------------------------------------------------- pure computations (unit tested)
def band(e):
    if e.get("conditional"):
        return "conditional"
    c = e["confidence"]
    return "under 50%" if c < 50 else "50-74%" if c < 75 else "75-89%" if c < 90 else "90%+"


def est_key(e):
    return (e["method"], str(e["input"]), str(e["outputItemID"]))


def band_counts(estimates):
    counts = collections.Counter(band(e) for e in estimates)
    return {b: counts.get(b, 0) for b in BAND_ORDER}


def coverage(m):
    methods = collections.Counter(e["method"] for e in m["estimates"])
    return {"records": m["records"], "dropRows": m["dropRows"], "studyRows": m["studyRows"], "referenceRows": m["referenceRows"],
            "studyKeys": m["studyKeys"], "estimates": len(m["estimates"]), "unplaced": m["unplaced"],
            "studyCastsTotal": round(sum(e["studyCasts"] or 0 for e in m["estimates"]), 1),
            "estimatesWithMeasuredChance": sum(1 for e in m["estimates"] if e["chanceSource"] == "measured"),
            "estimatesByMethod": dict(sorted(methods.items()))}


def band_moves(sequence):
    """sequence: [(stage, cause, estimates)] in order. Every estimate in both the first and the last whose band differs, with the
    stages it moved in. An estimate absent from a stage is band None there, so it can leave and come back."""
    per_stage = [(name, cause, {est_key(e): e for e in rows}) for name, cause, rows in sequence]
    first, last = per_stage[0][2], per_stage[-1][2]
    moves = []
    for k in sorted(first.keys() & last.keys()):
        if band(first[k]) == band(last[k]):
            continue
        steps = []
        for (_, _, prev), (name, cause, cur) in zip(per_stage, per_stage[1:]):
            a, b = prev.get(k), cur.get(k)
            if (band(a) if a else None) != (band(b) if b else None):
                steps.append({"stage": name, "cause": cause, "from": band(a) if a else None, "to": band(b) if b else None})
        moves.append({"method": k[0], "input": k[1], "outputItemID": k[2], "confidenceBefore": first[k]["confidence"],
                      "confidenceAfter": last[k]["confidence"], "bandBefore": band(first[k]), "bandAfter": band(last[k]),
                      "direction": "up" if confidence_rank(band(last[k])) > confidence_rank(band(first[k])) else "down",
                      "causes": sorted({s["cause"] for s in steps}), "steps": steps})
    return moves


def confidence_rank(name):
    """Higher is better; conditional sits apart, below the rest, so that a move into it reads as down."""
    return -1 if name == "conditional" else len(BAND_ORDER) - BAND_ORDER.index(name)


def stage_changes(sequence):
    """Estimates added, removed and moved band at each stage."""
    out = []
    for (_, _, prev), (name, cause, cur) in zip(sequence, sequence[1:]):
        a, b = {est_key(e): e for e in prev}, {est_key(e): e for e in cur}
        out.append({"stage": name, "cause": cause, "added": len(b.keys() - a.keys()), "removed": len(a.keys() - b.keys()),
                    "movedBand": sum(1 for k in a.keys() & b.keys() if band(a[k]) != band(b[k]))})
    return out


def parse_numbered_items(text, heading):
    """The numbered items under a heading, with their line. An item runs until the next number, a blank line followed by anything
    that is not an indented continuation, or the next heading."""
    lines = text.split("\n")
    start = next((i for i, line in enumerate(lines) if re.match(heading, line)), None)
    if start is None:
        raise ValueError(f"heading not found: {heading}")
    items, cur = [], None
    for i in range(start + 1, len(lines)):
        line = lines[i]
        if line.startswith("#"):
            break
        m = re.match(r"(\d+)\. (.*)", line)
        if m:
            cur = {"number": int(m[1]), "line": i + 1, "text": m[2].strip()}
            items.append(cur)
        elif line.startswith((" ", "\t")) and cur and line.strip():
            cur["text"] += " " + line.strip()
        elif not line.strip():
            continue
        else:
            cur = None
    return items


def title_of(text):
    """The first sentence of an item, without markdown emphasis."""
    plain = text.replace("**", "")
    m = re.match(r"(.+?[.?])(\s|$)", plain)
    title = m[1] if m and len(m[1]) >= 12 else plain
    return title if len(title) <= 160 else title[:157].rstrip() + "..."


def master_items():
    items = []
    for name, sections in sorted(MASTER_SECTIONS.items()):
        with open(os.path.join(REPORTS, name), encoding="utf-8") as f:
            text = f.read()
        for tag, heading in sections:
            for it in parse_numbered_items(text, heading):
                items.append({"id": f"{name[:-3]}/{tag}#{it['number']}", "source": rel(os.path.join(REPORTS, name)),
                              "line": it["line"], "title": title_of(it["text"])})
    return items


def register(context):
    """(open rows, rows reviewed and closed). Raises when a parsed item has no entry, or an entry no item: a new report item
    must be decided here, never dropped."""
    parsed = master_items()
    missing = {i["id"] for i in parsed} ^ set(ITEMS)
    if missing:
        raise ValueError("report items and ITEMS differ: " + ", ".join(sorted(missing)))
    rows, closed = [], []
    for it in parsed:
        entry = ITEMS[it["id"]]
        if "closedBy" in entry:
            closed.append({**it, "closedBy": entry["closedBy"]})
            continue
        rows.append({**it, "origin": "report", "kind": entry["kind"], "count": entry["count"](context) if "count" in entry else 1,
                     "pointer": f"{it['source']}:{it['line']}", "action": entry["action"], "m10": entry["m10"],
                     "m10Why": entry.get("m10Why"), "see": entry.get("see"), "blocksM10": entry["m10"] == "blocks"})
    for h in HANDOFF_ITEMS:
        with open(os.path.join(ROOT, h["source"]), encoding="utf-8") as f:
            line = next(i for i, text in enumerate(f, 1) if h["needle"] in text)
            f.seek(0)
            heading = f.read().splitlines()[line - 1].lstrip("# ").strip()
        rows.append({"id": h["id"], "source": h["source"], "line": line, "title": heading if h["needle"].startswith("#") else h["needle"],
                     "origin": "report", "kind": h["kind"], "count": h["count"](context) if "count" in h else 1,
                     "pointer": f"{h['source']}:{line}", "action": h["action"], "m10": h["m10"], "m10Why": h.get("m10Why"),
                     "see": h.get("see"), "blocksM10": h["m10"] == "blocks"})
    for e in context["exceptions"]:
        ids = e["recordIDs"]
        rows.append({"id": e["id"], "source": "research/v3/migration/manifest/exceptions.jsonl", "origin": "exception", "kind": e["kind"],
                     "title": e["subject"], "count": max(1, len(ids)), "recordIDs": ids, "pointer": "; ".join(e["refs"] or e["files"][:1]),
                     "action": e["action"], "m10": "none", "m10Why": None, "see": None, "blocksM10": False})
    for code, group in sorted(context["validatorErrors"].items()):
        rows.append({"id": f"validator:{code}", "source": "research/v3/migration/manifest/validation.json", "origin": "validator",
                     "kind": "validator-error", "title": code, "count": len(group), "recordIDs": sorted(group),
                     "pointer": "research/v3/migration/manifest/validation.json", "action": "See the validator-error exception rows.",
                     "m10": "none", "m10Why": None, "see": "exceptions:validator-error", "blocksM10": False})
    for decision, group in sorted(context["scopeGap"].items()):
        rows.append({"id": f"scope-gap:{decision}", "source": "research/v3/migration/manifest/scope-gap.jsonl", "origin": "scope-gap",
                     "kind": "scope-gap", "title": f"sources decided as {decision}", "count": len(group),
                     "sources": sorted(group), "pointer": "research/v3/migration/manifest/scope-gap.jsonl",
                     "action": "None; each source already carries its decision. Reread one only if its reason looks wrong.",
                     "m10": "none", "m10Why": None, "see": None, "blocksM10": False})
    return sorted(rows, key=lambda r: r["id"]), closed


# ---------------------------------------------------------------- collecting everything
def source_counts(tree, registry):
    """Registry URLs the tree's evidence mentions (inventory.py's own rule, 'inV3'), and those that are a record's own source."""
    import inventory
    urls = inventory.load_v3_index(tree)["urls"]
    keys = [r["key"] for r in registry]
    return {"registry": len(keys), "mentioned": sum(1 for k in keys if k in urls), "citedAsSource": sum(1 for k in keys if urls.get(k, 0) > 0)}


def plan_baseline():
    """The figures PLAN section 1 records for the snapshot, read from the text."""
    with open(os.path.join(MIG, "PLAN.md"), encoding="utf-8") as f:
        text = f.read()

    def num(pattern):
        return int(re.search(pattern, text)[1].replace(",", ""))
    return {"records": num(r"([\d,]+) records after corrections"), "estimates": num(r"\| Estimates \| ([\d,]+) \("),
            "unplaced": num(r"\| Estimates \| [\d,]+ \(([\d,]+) records unplaced"), "studyRows": num(r"([\d,]+) study rows in"),
            "studyKeys": num(r"study rows in ([\d,]+) study keys"), "referenceRows": num(r"([\d,]+) reference rows"),
            "dropRows": num(r"drop ([\d,]+) ·"), "sourcesMentioned": num(r"of which \*\*([\d,]+)\*\* are already cited")}


def disposition_check():
    rows = jl(os.path.join(MANIFEST, "dispositions.jsonl"))
    summary = read_json(os.path.join(MANIFEST, "dispositions-summary.json"))
    counts = dict(sorted(collections.Counter(r["disposition"] for r in rows).items()))
    return {"kinds": len(counts), "files": len(rows), "inventoryFiles": len(jl(os.path.join(MANIFEST, "inventory.jsonl"))), "byDisposition": counts,
            "summaryFiles": summary["files"], "equalsSummary": counts == summary["byDisposition"] and len(rows) == summary["files"]}


def context_for(usage, after):
    exceptions = jl(os.path.join(MANIFEST, "exceptions.jsonl"))
    errors = collections.defaultdict(set)
    for f in read_json(os.path.join(MANIFEST, "validation.json"))["findings"]:
        if f["severity"] == "error":
            errors[f["code"]].add(f["id"])
    gap = collections.defaultdict(set)
    for r in jl(os.path.join(MANIFEST, "scope-gap.jsonl")):
        gap[r["decision"]].add(r["source"])
    extracted = jl(os.path.join(V3, "evidence", "imported", "extracted-historical-sources.jsonl"))
    validation = read_json(os.path.join(MANIFEST, "validation.json"))
    ident = read_json(os.path.join(REPORTS, "M10-identity-data.json"))
    queued = {"cross-source-identity-pair", "identity-merge-with-conflict", "single-row-subset"}
    return {"identityNotQueued": len(ident["crossSourceMatches"]) + len(ident["mergedWithConflicts"]) + len(ident["smallSubsets"])
            - sum(1 for e in exceptions if e["kind"] in queued),
            "stillDiffering": len(ident["stillDiffering"]),
            "usage": usage, "idReuseWarnings": validation["byCode"].get("warning:ID_REUSED_ACROSS_FILES", 0), "m06": read_json(os.path.join(REPORTS, "M06-units-data.json")), "exceptions": exceptions,
            "exceptionKinds": collections.Counter(e["kind"] for e in exceptions), "validatorErrors": errors, "scopeGap": gap,
            "extractedRecipeRows": sum(1 for r in extracted if r.get("type") == "recipe"),
            "estimatesNoBatch": sum(1 for e in after["estimates"] if e.get("inputsPerCast") is None)}


def scipy_setting():
    code = "import scipy; print(scipy.__version__)"
    p = subprocess.run([sys.executable, "-c", code], capture_output=True, encoding="utf-8")
    return p.stdout.strip() if p.returncode == 0 else None


def run_tests():
    # The committed report is what this run replaces, so the test comparing against it is skipped here.
    env = {**os.environ, "M09_REPORT_RUNNING": "1"}
    p = subprocess.run([sys.executable, "-m", "unittest", "discover", "-s", TESTS], cwd=ROOT, capture_output=True, encoding="utf-8", env=env)
    ran = re.search(r"^Ran (\d+) tests?", p.stderr, re.M)
    return {"ran": int(ran[1]) if ran else None, "ok": p.returncode == 0}


def reproducibility(tmp, with_tests):
    work = os.path.join(tmp, "rebuild")
    copy_working_tree(work)
    first, second = rebuild_hashes(work), rebuild_hashes(work)
    import validate
    v = validate.validate(ROOT)
    committed = read_json(os.path.join(MANIFEST, "validation.json"))
    p = subprocess.run([sys.executable, os.path.join(HERE, "dispositions.py"), "--check"], cwd=ROOT, capture_output=True, encoding="utf-8")
    return {"rebuild": {"first": first, "second": second, "identical": first == second},
            "dispositionsCheck": {"exit": p.returncode, "output": p.stdout.strip()},
            "validate": {k: v[k] for k in ("records", "effectiveRecords", "evidenceFiles", "errors", "warnings", "byCode")},
            "validateEqualsManifest": all(v[k] == committed[k] for k in ("records", "errors", "warnings", "byCode")),
            "tests": run_tests() if with_tests else None}


def collect(with_tests=True):
    with tempfile.TemporaryDirectory() as tmp:
        stages = measure_stages(tmp)
        after_tree = os.path.join(tmp, "after")
        copy_working_tree(after_tree)
        after = run_measure(after_tree)
        registry = jl(os.path.join(MANIFEST, "url-registry.jsonl"))
        sources = {"before": source_counts(os.path.join(tmp, "snapshot"), registry), "after": source_counts(after_tree, registry)}
        # PLAN's 165 cited URLs used the M01 registry. Main's consolidated
        # research layout adds historical files/URLs; use that original registry
        # for the baseline assertion while comparing coverage over today's scope.
        original_registry = [json.loads(line) for line in subprocess.check_output(
            ["git", "-C", ROOT, "show", "f7ca506:research/v3/migration/manifest/url-registry.jsonl"],
            encoding="utf-8").splitlines() if line.strip()]
        original_mentions = source_counts(os.path.join(tmp, "snapshot"), original_registry)["mentioned"]
        repro = reproducibility(tmp, with_tests)
    before = stages["snapshot"]
    sequence = [(name, cause, stages[name]["estimates"]) for name, _, cause in STAGES]
    sequence.append((FINAL_STAGE[0], FINAL_STAGE[1], after["estimates"]))
    usage = after["usage"]
    top = sorted(usage["unusedByReason"].items(), key=lambda kv: (-kv[1], kv[0]))[:5]
    moves = band_moves(sequence)
    open_rows, closed = register(context_for(usage, after))
    baseline = plan_baseline()
    measured = {**coverage(before), "sourcesMentioned": original_mentions}
    stage_rows = [{"stage": name, "commit": commit[:7], "cause": cause, "records": stages[name]["records"],
                   "estimates": len(stages[name]["estimates"]), "unplaced": stages[name]["unplaced"],
                   "bands": band_counts(stages[name]["estimates"])} for name, commit, cause in STAGES]
    stage_rows.append({"stage": FINAL_STAGE[0], "commit": "-", "cause": sequence[-1][1], "records": after["records"],
                       "estimates": len(after["estimates"]), "unplaced": after["unplaced"], "bands": band_counts(after["estimates"])})
    kinds = collections.Counter(r["kind"] for r in open_rows if r["origin"] == "exception")
    return {
        "scipy": scipy_setting(),
        "coverage": {"before": coverage(before), "after": coverage(after), "sources": sources, "typesBefore": before["byType"],
                     "typesAfter": after["byType"]},
        "baselineCheck": {"planFigures": len(baseline), "plan": baseline, "differs": {k: [v, measured[k]] for k, v in sorted(baseline.items()) if v != measured[k]}},
        "bands": {"before": band_counts(before["estimates"]), "after": band_counts(after["estimates"]),
                  "afterCappedAt50": sum(1 for e in after["estimates"] if not e["conditional"] and e["chanceSource"] == "estimated"
                                         and e["confidence"] == 50),
                  "moved": len(moves), "up": sum(1 for m in moves if m["direction"] == "up"),
                  "down": sum(1 for m in moves if m["direction"] == "down"),
                  "byCauses": dict(sorted(collections.Counter(" + ".join(m["causes"]) for m in moves).items())),
                  "stages": stage_rows, "stageChanges": stage_changes(sequence), "moves": moves},
        "dispositions": disposition_check(),
        "usage": {**usage, "topReasons": [{"reason": k, "records": v, "meaning": REASON_TEXT[k]} for k, v in top]},
        "register": {"rows": open_rows, "closed": closed, "open": len(open_rows), "closedCount": len(closed),
                     "reportRows": sum(1 for r in open_rows if r["origin"] == "report"),
                     "validatorCodes": sum(1 for r in open_rows if r["origin"] == "validator"),
                     "scopeGapGroups": sum(1 for r in open_rows if r["origin"] == "scope-gap"),
                     "blockerIDs": [r["id"] for r in open_rows if r["blocksM10"]], "blocksM10": sum(1 for r in open_rows if r["blocksM10"]),
                     "handleInM10": sum(1 for r in open_rows if r["m10"] == "handle"), "exceptionsByKind": dict(sorted(kinds.items())),
                     "exceptionRows": sum(kinds.values()), "recordIDsNamed": sum(len(r.get("recordIDs", ())) for r in open_rows if r["origin"] == "exception")},
        "reproducibility": repro,
    }


# ---------------------------------------------------------------- rendering
def n(v):
    return f"{v:,}" if isinstance(v, int) else f"{v:,.1f}" if isinstance(v, float) else str(v)


def table(header, rows):
    lines = ["| " + " | ".join(header) + " |", "| " + " | ".join("---" for _ in header) + " |"]
    return lines + ["| " + " | ".join(str(c) for c in row) + " |" for row in rows]


def render(d):
    cov = d["coverage"]
    b, a = cov["before"], cov["after"]
    bands = d["bands"]
    reg = d["register"]
    rep = d["reproducibility"]
    use = d["usage"]
    src = cov["sources"]
    scipy = f"SciPy {d['scipy']}" if d["scipy"] else "no SciPy (normal-approximation fallback in `confidence()`)"
    lines = ["# M09: migration audit (MIG-010)", "",
             "Generated by `tools/report.py` (tests: `tests/test_m09_report.py`). Every figure is measured by that tool or quoted from the "
             "report or manifest row it cites; numbers are in `M09-audit-data.json`. Before is a rebuild of the snapshot "
             f"`{SNAPSHOT[:7]}` with its own estimator, after is a rebuild of the working tree.",
             "", f"**Confidence values were produced with {scipy}.** Only confidence depends on this; compare hashes and bands on one machine.",
             "", "## 1. Before and after coverage", ""]
    rows = [("Records (after corrections)", b["records"], a["records"]), ("Drop rows", b["dropRows"], a["dropRows"]),
            ("Study rows", b["studyRows"], a["studyRows"]), ("Reference rows", b["referenceRows"], a["referenceRows"]),
            ("Study keys", b["studyKeys"], a["studyKeys"]), ("Estimates", b["estimates"], a["estimates"]),
            ("Unplaced records", b["unplaced"], a["unplaced"]), ("Study casts total", b["studyCastsTotal"], a["studyCastsTotal"]),
            ("Estimates with measured chance", b["estimatesWithMeasuredChance"], a["estimatesWithMeasuredChance"])]
    methods = sorted(set(b["estimatesByMethod"]) | set(a["estimatesByMethod"]))
    rows += [(f"Estimates: {m}", b["estimatesByMethod"].get(m, 0), a["estimatesByMethod"].get(m, 0)) for m in methods]
    rows += [(f"Historical URLs mentioned in v3 (of {src['before']['registry']})", src["before"]["mentioned"], src["after"]["mentioned"]),
             ("of those, a record's own source", src["before"]["citedAsSource"], src["after"]["citedAsSource"])]
    lines += table(("Metric", "Before", "After"), [(k, n(x), n(y)) for k, x, y in rows]) + [""]
    lines += ["Study casts sum `studyCasts` over the estimates, so the before and after figures also differ by what M05 and M06 did to "
              "double counts and units. URL counts use the normalized keys of `tools/inventory.py`, as `manifest/url-registry.jsonl` does; "
              "they are a proxy at page level, and a language-suffixed Wowhead key counts apart here.", ""]
    differs = d["baselineCheck"]["differs"]
    if differs:
        lines += ["**The snapshot rebuild differs from PLAN section 1:** " +
                  "; ".join(f"{k}: PLAN {n(v[0])}, rebuilt {n(v[1])}" for k, v in differs.items()) + ".", ""]
    else:
        lines += [f"The snapshot rebuild agrees with all {d['baselineCheck']['planFigures']} figures PLAN section 1 records for it.", ""]
    lines += ["## 2. Confidence bands", ""]
    lines += table(("Band", "Before", "After"), [(x, n(bands["before"][x]), n(bands["after"][x])) for x in BAND_ORDER]) + [""]
    lines += [f"{n(bands['afterCappedAt50'])} of the {n(bands['after']['50-74%'])} estimates in 50-74% have a chance derived from the average "
              "and sit at exactly 50: such a chance has its confidence halved, so 50 is its ceiling however many casts it has (S5).", ""]
    lines += [f"Estimates in both builds that changed band: **{n(bands['moved'])}** ({n(bands['up'])} up, {n(bands['down'])} down). "
              "The cause is the stage where the band changed, from a rebuild of each stage's commit.", ""]
    lines += table(("Cause of the moves", "Estimates"), [(k, n(v)) for k, v in bands["byCauses"].items()]) + [""]
    lines += ["By stage:", ""]
    lines += table(("Stage", "Commit", "Records", "Estimates", "Unplaced", "Added", "Removed", "Moved band"),
                   [(s["stage"], f"`{s['commit']}`", n(s["records"]), n(s["estimates"]), n(s["unplaced"]), *changes)
                    for s, changes in zip(bands["stages"], [("", "", "")] + [(n(c["added"]), n(c["removed"]), n(c["movedBand"]))
                                                                             for c in bands["stageChanges"]])]) + [""]
    lines += ["Every move, with its stages, is in `M09-audit-data.json` under `bands.moves`.", "", "Largest confidence moves:", ""]
    largest = sorted(bands["moves"], key=lambda m: (-abs(m["confidenceAfter"] - m["confidenceBefore"]), m["method"], m["input"], m["outputItemID"]))[:15]
    lines += table(("Method", "Input", "Output", "Confidence", "Band", "Cause"),
                   [(m["method"], m["input"], m["outputItemID"], f"{m['confidenceBefore']} → {m['confidenceAfter']}",
                     f"{m['bandBefore']} → {m['bandAfter']}", " + ".join(m["causes"])) for m in largest]) + [""]
    disp = d["dispositions"]
    lines += ["## 3. Dispositions", "",
              f"{n(disp['files'])} files of {n(disp['inventoryFiles'])} in the inventory, in {disp['kinds']} dispositions. "
              f"Counts recomputed from `manifest/dispositions.jsonl` {'equal' if disp['equalsSummary'] else '**differ from**'} "
              "`manifest/dispositions-summary.json`.", ""]
    lines += table(("Disposition", "Files"), [(k, n(v)) for k, v in sorted(disp["byDisposition"].items(), key=lambda kv: (-kv[1], kv[0]))]) + [""]
    lines += ["## 4. Record usage", "", f"{n(use['used'])} of {n(use['records'])} records feed an estimate; "
              f"{n(use['unused'])} each carry one reason code.", ""]
    lines += table(("Used as", "Records"), [(k, n(v)) for k, v in sorted(use["usedByRole"].items())]) + [""]
    lines += ["A used record can have several roles, so the rows above can add up to more than the records used.", "", "Top five reasons:", ""]
    lines += table(("Reason", "Records", "Meaning"), [(f"`{t['reason']}`", n(t["records"]), t["meaning"]) for t in use["topReasons"]]) + [""]
    lines += ["All reasons:", ""]
    lines += table(("Reason", "Records"), [(f"`{k}`", n(v)) for k, v in sorted(use["unusedByReason"].items(), key=lambda kv: (-kv[1], kv[0]))]) + [""]
    report_rows = [r for r in reg["rows"] if r["origin"] == "report"]
    blockers = [r for r in reg["rows"] if r["blocksM10"]]
    lines += ["## 5. Unresolved issues", "",
              f"{n(reg['open'])} open rows: {reg['reportRows']} from reports and strategy.md, {n(reg['exceptionRows'])} exceptions, "
              f"{reg['validatorCodes']} validator codes, {reg['scopeGapGroups']} scope-gap groups. "
              f"{reg['closedCount']} further report items were reviewed and are closed. Each row cites its file; `see` names the row that "
              "carries the same decision, so one answer settles both. The full list, with record IDs, is `register.rows` in the data file.", ""]
    lines += [f"**M10 blockers: {reg['blocksM10']}.** {reg['handleInM10']} more need care in M10 but no decision. "
              "Nothing here stops the pipeline rerun or the pull request.", ""]
    for r in blockers:
        lines += [f"- **{r['id']}** ({r['pointer']}): {r['m10Why']}"]
    lines += ["", "### From the reports", ""]
    lines += table(("ID", "Kind", "Count", "Item", "Proposed owner action", "M10", "See"),
                   [(r["id"], r["kind"], n(r["count"]), r["title"].replace("|", "/"), r["action"], "**blocks**" if r["blocksM10"] else r["m10"],
                     r["see"] or "") for r in report_rows]) + [""]
    lines += ["### Exception queue, by kind (`manifest/exceptions.jsonl`)", ""]
    kind_rows = []
    for kind, count in sorted(reg["exceptionsByKind"].items(), key=lambda kv: (-kv[1], kv[0])):
        rows_k = [r for r in reg["rows"] if r["origin"] == "exception" and r["kind"] == kind]
        actions = sorted({r["action"] for r in rows_k})
        kind_rows.append((kind, n(count), n(sum(len(r["recordIDs"]) for r in rows_k)),
                          actions[0].replace("|", "/") + (" (varies by row)" if len(actions) > 1 else "")))
    lines += table(("Kind", "Rows", "Record IDs", "Proposed owner action"), kind_rows) + [""]
    lines += ["### Validator and scope gap", ""]
    lines += table(("ID", "Count", "Source", "Proposed owner action"),
                   [(r["id"], n(r["count"]), r["source"], r["action"]) for r in reg["rows"] if r["origin"] in ("validator", "scope-gap")]) + [""]
    lines += ["### Reviewed and closed", ""]
    lines += table(("ID", "Item", "Closed by"), [(r["id"], r["title"].replace("|", "/"), r["closedBy"]) for r in reg["closed"]]) + [""]
    reb = rep["rebuild"]
    val = rep["validate"]
    tests = rep["tests"]
    lines += ["## 6. Reproducibility", ""]
    lines += table(("Check", "Result"), [
        ("Rebuild twice (copy of the working tree)", "byte-identical" if reb["identical"] else "**DIFFERS**"),
        ("`estimates.json`", f"`{reb['first']['estimates.json'][:8]}…`"), ("`summary.md`", f"`{reb['first']['summary.md'][:8]}…`"),
        ("`unused.json`", f"`{reb['first']['unused.json'][:8]}…`"),
        ("`dispositions.py --check`", f"exit {rep['dispositionsCheck']['exit']}: {rep['dispositionsCheck']['output']}"),
        ("`validate.py` counts", f"{n(val['records'])} records in {val['evidenceFiles']} files ({n(val['effectiveRecords'])} after corrections), "
         f"{val['errors']} errors, {val['warnings']} warnings; "
         f"{'equal to' if rep['validateEqualsManifest'] else '**differ from**'} `manifest/validation.json`"),
        ("Migration tests", (f"{n(tests['ran'])} tests, {'all pass' if tests['ok'] else '**FAILED**'}" if tests else "not run (`--no-tests`)")),
    ]) + [""]
    return "\n".join(lines)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--check", action="store_true", help="compare with the committed report instead of writing")
    ap.add_argument("--no-tests", action="store_true", help="skip the test run (the tests section then says so)")
    ap.add_argument("--measure", help=argparse.SUPPRESS)
    args = ap.parse_args(argv)
    if args.measure:
        json.dump(measure(args.measure), sys.stdout)
        return 0
    data = collect(with_tests=not args.no_tests)
    text = json.dumps(data, indent=1, sort_keys=True, ensure_ascii=False) + "\n"
    md = render(data)
    if args.check:
        with open(OUT_JSON, encoding="utf-8", newline="") as a, open(OUT_MD, encoding="utf-8", newline="") as b:
            same = a.read() == text and b.read() == md
        print("identical to the committed report" if same else "DIFFERS from the committed report")
        return 0 if same else 1
    for path, content in ((OUT_JSON, text), (OUT_MD, md)):
        with open(path, "w", encoding="utf-8", newline="\n") as fh:
            fh.write(content)
    print(f"{data['coverage']['after']['records']} records, {data['coverage']['after']['estimates']} estimates; "
          f"{data['bands']['moved']} band moves; {data['register']['open']} open rows, {data['register']['blocksM10']} blocking M10")
    return 0


if __name__ == "__main__":
    sys.exit(main())
