# Handoff

**Updated:** 2026-11-01, end of session MIG-006.

## Status

- Repository `Voodoobrew101/Loot-Liquidator`, working branch **`migration/v3-historical-research`**
  (cut from `implementation/five-agent-completion` at snapshot `575b252`). Hourly agents keep committing to
  `implementation/five-agent-completion`; do not merge it in before M10.
- Complete: **M00**, **M01**, **M02**, **M05**, **M03**, **M06** (6 of 11 top-level tasks, 55%). **M04 is in progress**:
  M04.1 (linking) and M04.2 (residual queue) finished in MIG-006; M04.3 (AI extraction) and M04.4 (spot-check) are open.
- Latest verified baseline (SciPy installed): 4,933 effective evidence records → **1,205 estimates** (447 unplaced), unchanged
  by M04 (linking changes no evidence); **197** migration tests pass; validator 5 errors / 175 warnings; identity report
  unchanged since M03b; study audit 473 studies, 40 clean; corrections 643 lines / 333 corrected records.
- Estimates sha256 with SciPy: `6976d1bd…` (`summary.md` `c16d76e6…`). Without SciPy it differs (confidence values only).

## What M04.1 and M04.2 produced (MIG-006)

- `tools/link_sources.py` → `manifest/links.jsonl` (per file, per source, per study ID, per known candidate),
  `manifest/extraction-queue.jsonl` (55 sources) and `manifest/links-summary.json`. Rerun after any evidence change; a test fails
  when the committed files are stale. Rules: PLAN §3 rule 6. Report: `reports/M04-links.md` (counts, For the Master).
- 265 in-scope files: linked 133, exception 44, residue 49, disposed 39, each with a reason. The 124 Markdown candidates:
  linked 58, exception 18, residue 45, disposed 3.
- Known candidates: 86 agent-held name-only rows (not 92) → 58 linked, 6 exception, 22 unlinked (zkay8v's 10,000-ore cohort has
  no agent copy); 1smgllg → 11 of 14 resolve by name (proposals only, the importer is unchanged); s6bfrl uncommon gems → 6 exceptions.
- The queue: one entry per source URL with files (sha256), anchors, `expectedTypes` and `methodHints` (hints, not decisions).
  `proximity: citation` = numbers next to the URL; `proximity: file` = numbers elsewhere in the file (M04.3 must decide whether they
  belong to that source). 23 of the 55 are Wowhead pages (items, spells, guides) cited with counts but no comment ID: expect mostly null.
- 75 of 266 linked groups are weak (one small integer match). M04.4 should sample them.

## Read before relying on older numbers

- `reports/M06-units.md` explains every MIG-005 change. In short: every estimate is per cast of its group's unit
  (`inputsPerCast` in the output; prospecting 5, otherwise the smallest stated batch). Other batch sizes convert per
  input; their per-cast chances are left out. Counted, nominal, derived and converted casts count fully in the average
  and at 0.5 in the chance (`EQUIVALENT_CAST_WEIGHT`).
- `tools/units_report.py` lists every placed study row that contributes nothing, with a reason code (626 rows). Until
  M08, this is where "unused reason" lives.
- **Holdings rule (PLAN §3 rule 5):** a historical claim whose source v3 already holds is never imported, so an M10
  importer rerun cannot double count but its output can shrink when agents catch up.
- Agents still write counted casts without `castsBasis` (398 rows) and input counts only in notes (434 totals). The
  estimator reads fields only; both lists are in `M06-units-data.json` → `backfill` for the Master.
- `cohortKey` is still never set.
- Open for the Master: the 0.5 weight and the two backfills (M06); R3 Serevite labels, 9 cross-source pairs, single-row
  subsets (M05); the name-only placement rule, S14 pigment evidence, 9909's ranked input ID (M03); s6bfrl uncommon gems
  and the Felslate 2016 101-vs-97 total (M03b); zkay8v 10,000-ore placement, 1smgllg placement, the six Jallfo exceptions, whether to skip Wowhead entity pages (M04).

## Environment notes

- **Pushing from a Claude cloud session:** attach the repo with push access (MIG-006: refused once, granted on the retry). The clone lands on `main`; fetch and check out the branch. Use the
  remote URL `https://github.com/Voodoobrew101/Loot-Liquidator.git` and verify with
  `git ls-remote origin refs/heads/migration/v3-historical-research` after pushing.
- Windows: clone with `-c core.longpaths=true -c core.autocrlf=false` to a short path. Use `python`.
- Without `core.autocrlf=false`, a rebuild shows every output file as modified.
- With or without SciPy, run before and after on the same machine; only confidence values depend on it.
- When checking whether v3 holds a source, compare **normalized keys** (`source_keys.normalize_url`), never raw URLs:
  MIG-004 nearly double-imported a held forum post that way (the guard caught it).

## Next task: M04.3 and M04.4 — batched AI extraction of the residual queue, then spot-check

Why now: M04.1 decided what is left. `manifest/extraction-queue.jsonl` holds 55 sources in 49 files; everything else in the
265 in-scope files is linked, listed as an exception or disposed with a reason. M04.3 turns the queue into schema-valid,
arithmetic-checked rows that quote their source text; M04.4 re-checks a 10% sample (plus weak links) and decides M04.
Dependencies: M04.1, M04.2 (done), M03 (done). No network is available in the workspace: the text to read is what the
notes quote, so extraction is limited to numbers present in the queue's files, null on doubt.

Sessions run in **Claude** (owner's choice).
**Recommended model:** Claude Sonnet 5.5 · **thinking effort:** Medium for the extraction batches; **Claude Opus 5.5 · High** for the M04.4 spot-check
**Alternative:** Claude Opus 5.5 · Medium for extraction if Sonnet's nulls look too cautious on a pilot batch of 5 sources
**Reason:** the batches are mechanical (one source per prompt, validator and arithmetic checks do the policing); the spot-check needs the stronger judgement.

## Ready-to-paste prompt for the next session

```text
You are continuing the Loot Liquidator historical-research migration (session MIG-007).

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
2. research/v3/migration/PLAN.md (§3 strategy table, "Statistical rules" 1-6, "Risks and safeguards")
3. research/v3/migration/CHECKLIST.md (task M04)
4. research/v3/migration/SESSION_LOG.md (MIG-005, MIG-006)
5. research/v3/migration/reports/M04-links.md ("For the Master" and the queue section)
6. research/v3/migration/manifest/extraction-queue.jsonl (55 sources) and the residue rows of manifest/links.jsonl
7. research/v3/README.md, research/v3/evidence-format.md, research/v3/migration/SCHEMA-EXTENSION.md
8. research/v3/tools/import_existing.py (base(), drop_fields(), migrated(), derivation(), NEW_SOURCES),
   research/v3/migration/tools/link_sources.py, research/v3/migration/tools/validate.py

TASK: M04.3 and M04.4. No network. Extract numbers ONLY from text present in the queue's files; never from memory.

Steps:
1. Baseline: run python research/v3/tools/build_estimates.py, copy research/v3/output/estimates.json outside the repo as
   before.json, then git checkout -- research/v3/output. Note whether SciPy is installed (expected sha256 with SciPy:
   6976d1bd...). Run the tests (197 expected).
2. Write research/v3/migration/tools/extract_batch.py: for each queue entry build a prompt (one source, its files'
   anchored text with line numbers, the target schema, the rule "quote the text, null on doubt, no invented numbers") and a
   validator for the model's answer: JSON schema check (validate.py rules), every number must appear in the quoted text,
   arithmetic checks (totals vs casts, percent vs counts, sums of ranks), source key must equal the queue entry. Checkpoint
   per source in manifest/extraction/<key>.json so a stopped run resumes. Rows carry migratedFrom {path, sha256, recordRef},
   castsBasis and derivations as in M03, and are written to research/v3/evidence/imported/ by a deterministic writer
   (never by hand), only for sources v3 still does not hold (PLAN §3 rule 5).
3. Pilot 5 sources of mixed type (a Reddit post, a Blizzard forum thread, a wow-professions table, a Wowhead comment, a
   file-level piece), review every row by hand, then run the rest. Wowhead entity pages cited with incidental counts are expected to
   yield null; record the null and the reason.
4. M04.4: sample 10% of the extracted rows plus 10% of the 75 weak links in manifest/links.jsonl, re-check each against its
   source text, write the verdicts to reports/M04-spot-check.md.
5. Tests in research/v3/migration/tests/test_extract_batch.py (prompt contents, validator accept/reject cases, arithmetic
   checks, checkpoint resume, writer determinism). Keep all 197 existing tests passing.
6. Rerun link_sources.py (the extracted sources become held), the tests, tools/validate.py, rebuild twice (record the
   estimate changes with estimates_diff.py; they are expected now), the importer twice (idempotent). Corrections stay 643 lines / 333 records.

Rules: never edit agent evidence files, corrections.jsonl or strategy.md; do not commit research/v3/output/.
evidence-format.md is owner-only: propose field changes in SCHEMA-EXTENSION.md. Extraction never overwrites an existing
v3 record and never guesses an item ID.

Acceptance criteria:
- Every queue entry has a checkpoint: extracted rows, or null with a reason.
- Extracted rows quote their source text, pass validate.py and the arithmetic checks, carry migratedFrom, and are idempotent.
- The 10% sample (and weak-link sample) is re-checked, with verdicts written down.
- Counts before/after in reports/M04-extraction.md with a "For the Master" section; estimate changes explained.

Update before ending: CHECKLIST.md (tick only what is met; M04 completes only when M04.4 is done), SESSION_LOG.md (append MIG-007
with commands actually run and measured numbers), HANDOFF.md (status, next task, model/effort, next prompt), PLAN.md if a rule
changed. Commit on migration/v3-historical-research with message "v3 migration M04.3-M04.4: <summary>" and push.

End with the mandatory report: A. Session summary; B. Progress and checklist (totals, %, newly ticked items,
migration metrics); C. Next recommended task (ID, why, dependencies, deliverables, acceptance); D. Next Claude
configuration (model, thinking effort, alternative, reason); E. A complete ready-to-paste prompt for the following session.
Default next task after this: M07 — final dispositions for all 1,244 files and the exception queue (incl. the 91 exception
groups, the 37 v2/source-reviews files and 21 submission audit CSVs).
```

## Later tasks at a glance

M04.3/M04.4 residual AI extraction and spot-check → M07 dispositions (including the 37 `v2/source-reviews` files and 21 submission audit CSVs, all without study objects)
→ M08 estimator integration → M09 reports → M10 reconcile with the agents' branch (rerun the importer: its MIG-004 output
may shrink as agents catch up) and open the PR.
