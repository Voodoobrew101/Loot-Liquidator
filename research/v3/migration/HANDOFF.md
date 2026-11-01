# Handoff

**Updated:** 2026-11-01, end of session MIG-007.

## Status

- Repository `Voodoobrew101/Loot-Liquidator`, working branch **`migration/v3-historical-research`**
  (cut from `implementation/five-agent-completion` at snapshot `575b252`). Hourly agents keep committing to
  `implementation/five-agent-completion`; do not merge it in before M10.
- Complete: **M00**, **M01**, **M02**, **M05**, **M03**, **M06**, **M04** (7 of 11 top-level tasks, 64%). Open: M07, M08, M09, M10.
- Latest verified baseline (SciPy installed): 4,945 effective evidence records → **1,205 estimates** (449 unplaced), 3 of them changed
  by M04.3; **267** migration tests pass; validator 5 errors / 175 warnings (unchanged); identity report unchanged since M03b; study
  audit 475 studies, 40 clean; corrections 643 lines / 333 corrected records.
- Estimates sha256 with SciPy: `d959496a…` (`summary.md` `fbf8e3b2…`). It was `6976d1bd…` / `c16d76e6…` through MIG-006. Without
  SciPy it differs (confidence values only).

## What M04.3 and M04.4 produced (MIG-007)

- `tools/extract_batch.py`: `prompt`, `submit`, `status`, `verify`, `write`. No model API exists in the workspace; the reader is the
  session. The validator checks quotes, numbers, arithmetic and the finished record (PLAN section 3 rule 7). Report:
  `reports/M04-extraction.md` (counts, estimate changes, For the Master); spot-check: `reports/M04-spot-check.md`.
- 55 of 55 queue sources have a checkpoint in `manifest/extraction/`: **9 with rows (12 rows)**, **46 null with a reason code**. Rows
  are in `evidence/imported/extracted-historical-sources.jsonl`, written only by `extract_batch.py write`. Checkpoints carry their
  queue entry and the writer reads checkpoints, so rows survive `link_sources.py` dropping a source from the live queue. Rerun
  `extract_batch.py write` whenever the evidence changes; a source v3 holds by then is skipped and reported as `held` (M10).
- The 12 rows: 3 Nightshade totals (placed, the only estimate change), 2 Felwort totals (unplaced), 7 recipe batch sizes (no
  estimator effect). 46 nulls: ambiguous-doubt 12, qualitative 9, reference-table 8, numbers-not-this-source 8, identity-link-only 4,
  needs-original-post 2, held-elsewhere 2, no-observational-numbers 1.
- Spot-check: 12 of 12 rows correct; 5 of 5 sampled nulls confirmed; 10 weak links (8 true, 1 right source with a coincidental number,
  1 false link on a held source).
- `link_sources.py` amended: a source held only by `recipe` records is `source-held`, not an exception. After the rerun: 265 files →
  linked 140, exception 44, residue 42, disposed 39; the live queue is the 46 null sources. **The 46 stay residue to the linker**; M07
  disposes their files using the checkpoint reasons.
- `EXTRA_FILES` in `extract_batch.py` adds two sibling notes the queue never held (the inventory marked them `source-links-only`).

## Read before relying on older numbers

- `reports/M06-units.md` explains every MIG-005 change. In short: every estimate is per cast of its group's unit
  (`inputsPerCast` in the output; prospecting 5, otherwise the smallest stated batch). Other batch sizes convert per
  input; their per-cast chances are left out. Counted, nominal, derived and converted casts count fully in the average
  and at 0.5 in the chance (`EQUIVALENT_CAST_WEIGHT`). A row with `inputsProcessed` and no casts counts inputs / unit casts at that weight
  (the Nightshade rows).
- `tools/units_report.py` lists every placed study row that contributes nothing, with a reason code. Until M08, this is where
  "unused reason" lives.
- **Holdings rule (PLAN section 3 rule 5):** a historical claim whose source v3 already holds is never imported, so an M10
  importer rerun cannot double count but its output can shrink when agents catch up. Wowhead keys with a language suffix (`@es`,
  `@fr`, ...) are the same page; game flavours (`@cata`, `@wotlk`) are not.
- The queue is a lower bound (`reports/M04-extraction.md`, finding 1): notes the inventory marked `source-links-only` were never in
  scope, and the observational-count pattern needs a unit word after the number. 114 file mentions of the 55 sources lie outside
  their queue entries; 23 unheld source keys with a number of 20 or more beside the citation sit in out-of-scope files (10 of those I could name are queue
  sources; most others are guide URLs in audit-CSV rows).
- Agents still write counted casts without `castsBasis` (398 rows) and input counts only in notes (434 totals). Both lists are in
  `M06-units-data.json` → `backfill` for the Master. `cohortKey` is still never set.
- Open for the Master: the 0.5 weight and the two backfills (M06); R3 Serevite labels, 9 cross-source pairs, single-row subsets (M05);
  the name-only placement rule, S14 pigment evidence, 9909's ranked input ID (M03); s6bfrl uncommon gems and the Felslate 2016
  101-vs-97 total (M03b); zkay8v 10,000-ore placement, 1smgllg placement, the six Jallfo exceptions (M04.1); and from M04.3: recipe
  rows from entity pages yes or no, the 12 `ambiguous-doubt` sources (Stormvine first), widening the count pattern, comment-level
  source keys for Wowhead item pages.

## Environment notes

- **Pushing from a Claude cloud session:** attach the repo with push access (MIG-006: refused once, granted on the retry; MIG-007:
  granted at once). The clone lands on `main`; fetch and check out the branch. Use the remote URL
  `https://github.com/Voodoobrew101/Loot-Liquidator.git` and verify with
  `git ls-remote origin refs/heads/migration/v3-historical-research` after pushing.
- Windows: clone with `-c core.longpaths=true -c core.autocrlf=false` to a short path. Use `python`.
- Without `core.autocrlf=false`, a rebuild shows every output file as modified. Restore it with `git checkout -- research/v3/output`
  before committing (never commit `output/`).
- With or without SciPy, run before and after on the same machine; only confidence values depend on it.
- When checking whether v3 holds a source, compare **normalized keys** (`source_keys.normalize_url`), never raw URLs, and treat a
  language-suffixed Wowhead key as its base page (`extract_batch.strip_lang`).

## Next task: M07 — final dispositions and the exception queue

Why now: M03 and M04 are done, so every historical file is either imported, linked, extracted (rows or a reasoned null), an
exception, or still unclassified. M07 turns that into one final disposition per file and one queue of what a person must decide.
Dependencies: M03, M04 (done). No network.

Sessions run in **Claude** (owner's choice).
**Recommended model:** Claude Sonnet 5.5 · **thinking effort:** Medium
**Alternative:** Claude Opus 5.5 · Medium if the exception triage needs judgement rather than rules
**Reason:** the dispositions are rule-driven from manifests already built (inventory, links, checkpoints, import reports); the
exception queue is mostly listing with record IDs. Use the stronger model only if the 83 exception groups need real adjudication.

## Ready-to-paste prompt for the next session

```text
You are continuing the Loot Liquidator historical-research migration (session MIG-008).

Repository: Voodoobrew101/Loot-Liquidator
Branch: migration/v3-historical-research (already exists on origin; check it out, do NOT work on main or
implementation/five-agent-completion, do NOT touch the addon .lua files).
If your clone is shallow, run: git fetch --depth=1000 origin migration/v3-historical-research
The research corpus (research/, including research/v3/ and research/v3/migration/) exists ONLY on this branch;
main holds just the addon. If your copy is on main, run:
  git fetch --depth=1000 origin migration/v3-historical-research
  git checkout -b migration/v3-historical-research FETCH_HEAD
Push access: the owner has granted it. In a Claude cloud session, attach the repo with push access; if that request
is denied, retry it once before falling back. Use the exact remote URL
https://github.com/Voodoobrew101/Loot-Liquidator.git and confirm the push with git ls-remote.
On Windows: clone to a short path with -c core.longpaths=true -c core.autocrlf=false, and use `python`.

READ FIRST, in order:
1. research/v3/migration/HANDOFF.md
2. research/v3/migration/PLAN.md (section 3 strategy table, "Statistical rules" 1-7, "Risks and safeguards")
3. research/v3/migration/CHECKLIST.md (task M07)
4. research/v3/migration/SESSION_LOG.md (MIG-006, MIG-007)
5. research/v3/migration/reports/M04-extraction.md and M04-spot-check.md ("For the Master" and the two scope findings)
6. research/v3/migration/manifest/inventory.jsonl (1,244 files, preliminary dispositions), manifest/inventory-summary.md,
   manifest/links.jsonl (265 in-scope files with outcomes and reasons), manifest/extraction/*.json (55 checkpoints; the 46 nulls
   carry reason codes), manifest/validation.json
7. research/v3/migration/reports/M03-import.md, M03b-import.md, M05-identity.md, M06-units.md (what each importer skipped and why)
8. research/v3/migration/tools/inventory.py, link_sources.py, extract_batch.py, validate.py, and the importer
   research/v3/tools/import_existing.py (NEW_SOURCES)

TASK: M07 — a final disposition for every one of the 1,244 files, and the exception queue. No network. No AI extraction.

Steps:
1. Baseline: run python research/v3/tools/build_estimates.py, copy research/v3/output/estimates.json outside the repo as before.json,
   then git checkout -- research/v3/output. Note whether SciPy is installed (expected estimates sha256 with SciPy: d959496a...). Run
   the tests (267 expected).
2. Write research/v3/migration/tools/dispositions.py that builds manifest/dispositions.jsonl deterministically from the inventory,
   the link outcomes, the extraction checkpoints and the import reports. One row per file: path, sha256, final disposition from a
   closed vocabulary (for example imported, linked, extracted, extracted-null, exception-queued, reference-only, process-artifact,
   derived-model, mechanics-knowledge, no-observational-content, source-links-only), a machine-readable reason, and pointers
   (record IDs, checkpoint, report). No file may be left "preliminary", "candidate-*" or "covered-by-url".
3. The 46 null extraction sources keep their 42 files "residue" in the linker. Dispose those files from their checkpoint reasons,
   and say in the reason which source and which code.
4. Exception queue: write manifest/exceptions.jsonl with every contradiction or suspicious transformation, each with record IDs and
   a kind: the 44 exception files (83 source groups), the six Jallfo exceptions, s6bfrl uncommon gems, the 22 zkay8v 10,000-ore rows,
   the 1smgllg placements, the 37 v2/source-reviews files and 21 submission audit CSVs (all without study objects, so
   dispose or queue each), the Felslate 2016 101-vs-97 total, the 12 ambiguous-doubt extraction sources, and the validator's 5
   errors (3 METHOD_UNKNOWN, 2 METHOD_MISSING: list each with a fix path through corrections.jsonl or an agent flag).
5. Scope gap from M04.3: the queue missed notes the inventory marked source-links-only, and the linker's count pattern needs a
   unit word. Measure how many unheld sources with counts sit in out-of-scope files (M04-extraction.md says 23). Decide per source
   whether it needs an extraction checkpoint (use extract_batch.py and EXTRA_FILES) or a reasoned disposition; widen the linker
   pattern only if a test pins it and the rerun is explained.
6. Tests in research/v3/migration/tests/test_dispositions.py (vocabulary closed, every inventory file has one row, no preliminary
   value left, idempotency, reasons present, exception rows carry IDs, committed files match a fresh run). Keep all 267 existing
   tests passing.
7. Rerun link_sources.py and extract_batch.py write --check if anything they read changed, the tests, tools/validate.py, rebuild
   twice (estimates should not change; if they do, explain with estimates_diff.py), the importer twice (idempotent). Corrections
   stay 643 lines / 333 records.

Rules: never edit agent evidence files, corrections.jsonl or strategy.md; do not commit research/v3/output/. evidence-format.md is
owner-only: propose field changes in SCHEMA-EXTENSION.md. Never place an item by name and never guess an item ID.

Acceptance criteria:
- manifest/dispositions.jsonl gives all 1,244 files a final disposition and a reason; counts by disposition in reports/M07-dispositions.md.
- manifest/exceptions.jsonl queues every contradiction and suspicious transformation with record IDs; the validator's findings are
  clean or each is listed.
- Counts before/after, estimate check, and a "For the Master" section.

Update before ending: CHECKLIST.md (tick only what is met), SESSION_LOG.md (append MIG-008 with commands actually run and measured
numbers), HANDOFF.md (status, next task M08, model/effort, next prompt), PLAN.md if a rule changed. Commit on
migration/v3-historical-research with message "v3 migration M07: <summary>" and push.

End with the mandatory report: A. Session summary; B. Progress and checklist (totals, %, newly ticked items, migration metrics);
C. Next recommended task (ID, why, dependencies, deliverables, acceptance); D. Next Claude configuration (model, thinking effort,
alternative, reason); E. A complete ready-to-paste prompt for the following session.
Default next task after this: M08 — estimator integration (structured unlockState, ISO-only dates, percentMeaning guard,
per-record unusedReason, regression tests, decision on committing output/).
```

## Later tasks at a glance

M07 dispositions and exception queue → M08 estimator integration → M09 reports → M10 reconcile with the agents' branch (rerun the
importer and `extract_batch.py write`: their output may shrink as agents catch up) and open the PR.
