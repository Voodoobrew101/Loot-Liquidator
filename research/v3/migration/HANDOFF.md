# Handoff

**Updated:** 2026-10-31, end of session MIG-005.

## Status

- Repository `Voodoobrew101/Loot-Liquidator`, working branch **`migration/v3-historical-research`**
  (cut from `implementation/five-agent-completion` at snapshot `575b252`). Hourly agents keep committing to
  `implementation/five-agent-completion`; do not merge it in before M10.
- Complete: **M00**, **M01**, **M02**, **M05**, **M03**, **M06** (6 of 11 top-level tasks, 55%). M06 finished in MIG-005.
- Latest verified baseline (SciPy installed): 4,933 effective evidence records → **1,205 estimates** (447 unplaced);
  **148** migration tests pass; validator 5 errors / 175 warnings; identity report unchanged since M03b (0 groups
  dropping differing numbers, 24 partial copies, 24 near copies, 1 pooled study); study audit 473 studies, 40 clean.
- Estimates sha256 with SciPy: `6976d1bd…` (`summary.md` `c16d76e6…`). Without SciPy it differs (confidence values only).

## Read before relying on older numbers

- `reports/M06-units.md` explains every MIG-005 change. In short: every estimate is per cast of its group's unit
  (`inputsPerCast` in the output; prospecting 5, otherwise the smallest stated batch). Other batch sizes convert per
  input; their per-cast chances are left out. Counted, nominal, derived and converted casts count fully in the average
  and at 0.5 in the chance (`EQUIVALENT_CAST_WEIGHT`). 112 estimates changed; BfA/SL/Legion milling averages fell to
  about a quarter where per-20 mass-mill means had been read as per-5 (Riverbud → Ultramarine 9.04 → 4.02).
- `tools/units_report.py` lists every placed study row that contributes nothing, with a reason code (626 rows). Until
  M08, this is where "unused reason" lives.
- **Holdings rule (PLAN §3 rule 5):** a historical claim whose source v3 already holds is never imported, so an M10
  importer rerun cannot double count but its output can shrink when agents catch up.
- Agents still write counted casts without `castsBasis` (398 rows) and input counts only in notes (434 totals). The
  estimator reads fields only; both lists are in `M06-units-data.json` → `backfill` for the Master.
- `cohortKey` is still never set.
- Open for the Master: the 0.5 weight and the two backfills (M06); R3 Serevite labels, 9 cross-source pairs, single-row
  subsets (M05); the name-only placement rule, S14 pigment evidence, 9909's ranked input ID (M03); s6bfrl uncommon gems
  and the Felslate 2016 101-vs-97 total (M03b).

## Environment notes

- **Pushing from a Claude cloud session:** attach the repo with push access (retry the request once if refused). Use the
  remote URL `https://github.com/Voodoobrew101/Loot-Liquidator.git` and verify with
  `git ls-remote origin refs/heads/migration/v3-historical-research` after pushing.
- Windows: clone with `-c core.longpaths=true -c core.autocrlf=false` to a short path. Use `python`.
- Without `core.autocrlf=false`, a rebuild shows every output file as modified.
- With or without SciPy, run before and after on the same machine; only confidence values depend on it.
- When checking whether v3 holds a source, compare **normalized keys** (`source_keys.normalize_url`), never raw URLs:
  MIG-004 nearly double-imported a held forum post that way (the guard caught it).

## Next task: M04 — Markdown linking (M04.1, M04.2) and the start of residual AI extraction

Why now: all structured evidence is in v3 and the estimator now uses every row that states its denominator (M03, M05,
M06), so the remaining gain is the ~124 Markdown candidates and the uncited URLs. M04.1 is deterministic and decides
how small the AI residue (M04.3) is. Link candidates already known: the 92 agent-held name-only rows (M03), the 14
1smgllg rates and the s6bfrl uncommon gems (M03b).

Sessions run in **Claude** (owner's choice).
**Recommended model:** Claude Sonnet 5.5 · **thinking effort:** Medium (M04.1 linking, M04.2 queue)
**Alternative:** Claude Opus 5.5 · High, if linking needs many judgement calls on cohort identity
**Reason:** M04.1 is a deterministic matcher (URL + study ID + numbers) with tests, the kind of mechanical work a
mid-size model has done well in M01/M03; the identity rules it must respect are already written and tested.

## Ready-to-paste prompt for the next session

```text
You are continuing the Loot Liquidator historical-research migration (session MIG-006).

Repository: Voodoobrew101/Loot-Liquidator
Branch: migration/v3-historical-research (already exists on origin; check it out, do NOT work on main or
implementation/five-agent-completion, do NOT touch the addon .lua files).
If your clone is shallow, run: git fetch --depth=1000 origin migration/v3-historical-research
Push access: the owner has granted it. In a Claude cloud session, attach the repo with push access; if that request
is denied, retry it once before falling back. Use the exact remote URL
https://github.com/Voodoobrew101/Loot-Liquidator.git and confirm the push with git ls-remote.
On Windows: clone to a short path with -c core.longpaths=true -c core.autocrlf=false, and use `python`.

READ FIRST, in order:
1. research/v3/migration/HANDOFF.md
2. research/v3/migration/PLAN.md (§1 inventory table, §3 strategy table and "Statistical rules" 1-5)
3. research/v3/migration/CHECKLIST.md (task M04)
4. research/v3/migration/SESSION_LOG.md (MIG-004, MIG-005)
5. research/v3/migration/reports/M03-import.md, M03b-import.md and M06-units.md ("For the Master" sections)
6. research/v3/migration/manifest/inventory-summary.md and the candidate-unmigrated / covered-by-url rows of
   manifest/inventory.jsonl; manifest/url-registry.jsonl
7. research/v3/README.md, research/v3/evidence-format.md, research/v3/migration/SCHEMA-EXTENSION.md
8. research/v3/tools/source_keys.py, research/v3/tools/import_existing.py (Holdings, NEW_SOURCES),
   research/v3/migration/tools/identity_report.py

TASK: M04.1 and M04.2 — deterministic linking of Markdown and irregular notes, then the residual queue. No AI
extraction of numbers yet (M04.3 is a later session). No network.

Steps:
1. Baseline: run python research/v3/tools/build_estimates.py, copy research/v3/output/estimates.json outside the repo
   as before.json, then git checkout -- research/v3/output. Note whether SciPy is installed (expected sha256 with
   SciPy: 6976d1bd...). Run the tests (148 expected).
2. Write research/v3/migration/tools/link_sources.py: for every candidate-unmigrated, candidate-no-url and
   covered-by-url file in manifest/inventory.jsonl, find each cited URL (normalized with source_keys.normalize_url),
   study ID and number, and link it to v3 records: same normalized source and matching numbers → linked; same source
   with other numbers → exception; source not in v3 → residue. Read-only on evidence; deterministic, sorted output to
   manifest/links.jsonl with file hashes; idempotent.
3. Resolve the known link candidates: the 92 agent-held name-only rows (M03-import-data.json), the 14 1smgllg rates
   and the s6bfrl uncommon gems (M03b). Link or list each with a reason; do not edit agent files or corrections.jsonl.
4. M04.2: group the residue by source URL into manifest/extraction-queue.jsonl (one entry per source: files, the text
   anchors that hold numbers, expected record types). This is the input M04.3 will batch.
5. Tests in research/v3/migration/tests/test_link_sources.py: URL normalization cases, numbers matching, exception on
   differing numbers, residue grouping, idempotency, read-only. Keep all 148 existing tests passing.
6. Run the tests, tools/validate.py, rebuild twice (estimates must be byte-identical to before.json: linking changes
   no evidence) and the importer twice (unchanged, idempotent). Corrections stay 643 lines / 333 records.

Rules: never edit agent evidence files, corrections.jsonl or strategy.md; do not commit research/v3/output/.
evidence-format.md is owner-only: propose field changes in SCHEMA-EXTENSION.md.

Acceptance criteria:
- Every in-scope Markdown/irregular file is linked, listed as an exception, or in the residual queue, with a reason.
- The three known link-candidate groups are resolved or listed with reasons.
- links.jsonl and extraction-queue.jsonl rerun byte-identically; estimates unchanged; all tests pass.
- Counts before/after written to reports/M04-links.md, with a "For the Master" section.

Update before ending: CHECKLIST.md (tick only what is met, update the progress table), SESSION_LOG.md (append MIG-006
with commands actually run and measured numbers), HANDOFF.md (status, next task, model/effort, next prompt), PLAN.md if
a rule changed. Commit on migration/v3-historical-research with message "v3 migration M04.1-M04.2: <summary>" and push.

End with the mandatory report: A. Session summary; B. Progress and checklist (totals, %, newly ticked items,
migration metrics); C. Next recommended task (ID, why, dependencies, deliverables, acceptance); D. Next Claude
configuration (model, thinking effort, alternative, reason); E. A complete ready-to-paste prompt for the following session.
Default next task after this: M04.3 — batched AI extraction of the residual queue with schema and arithmetic
validation and checkpoints, then M04.4 spot-check.
```

## Later tasks at a glance

M04.3/M04.4 residual AI extraction and spot-check → M07 dispositions (including the 37 `v2/source-reviews` files and 21 submission audit CSVs, all without study objects)
→ M08 estimator integration → M09 reports → M10 reconcile with the agents' branch (rerun the importer: its MIG-004 output
may shrink as agents catch up) and open the PR.
