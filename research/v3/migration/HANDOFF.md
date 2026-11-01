# Handoff

**Updated:** 2026-10-31, end of session MIG-003.

## Status

- Repository `Voodoobrew101/Loot-Liquidator`, working branch **`migration/v3-historical-research`**
  (cut from `implementation/five-agent-completion` at snapshot `575b252`). Hourly agents keep committing to
  `implementation/five-agent-completion`; do not merge it in before M10.
- Complete: **M00**, **M01**, **M02**, **M05** (4 of 11 top-level tasks, 36%).
- In progress: **M03**. Done in MIG-003: M03.0 (typeless records), M03.1 (re-import with castsBasis), M03.5 (GameData
  tables). Open: M03.2, M03.3, M03.4, M03.6.
- Latest verified baseline (SciPy installed): 4,882 effective evidence records → **1,205 estimates** (433 unplaced:
  35 old + 397 stored-but-unplaced name-only rows + 1 typeless deck row); **99** migration tests pass; validator
  5 errors / 175 warnings (TYPE_MISSING 0, DATE_NOT_ISO 0); identity report: 0 groups dropping differing numbers,
  24 partial copies, 1 pooled study; study audit 454 studies, 40 clean.
- Estimates sha256 with SciPy: `1081c316…`. Without SciPy it differs (confidence values only).

## Read before relying on older numbers

- `reports/M03-import.md` explains every change in estimates and in the identity report since M05.
- `castsBasis` now exists on every imported row; **weighting by basis is still M06**. Casts values are unchanged.
- The importer reads agent evidence to decide whether a name-only row may be placed (PLAN §3 rule 4), so its output
  can change when agents add records citing the same source. M10 reruns it on the new head anyway.
- `cohortKey` is still never set. Do not set it unless both sides of a known copy get the same key (M05 warning).
- Open for the Master: R3 Serevite labels, 9 cross-source pairs, single-row subsets (M05); the name-only placement
  rule, the S14 pigment evidence and 9909's ranked input ID (M03 report, last section).

## Environment notes

- Windows: clone with `-c core.longpaths=true -c core.autocrlf=false` to a short path. Use `python`.
- Without `core.autocrlf=false`, a rebuild shows every output file as modified.
- With or without SciPy, run before and after on the same machine; only confidence values depend on it.

## Next task: M03.2, M03.3, M03.4, M03.6 — remaining structured adapters

Why now: M06 should decide cast-basis weighting once, over all structured evidence. Today 11 observation `.json`
archives, `evidence/v2`, `evidence/leads`, structured worker submissions and the ledger CSVs are still unread, and
43 JSONL records in other schemas were found by M03.1 (`legacy-milling-batch01` 30, `warwithin-batch014-q16-recipe-metadata` 8,
`dragonflight-batch012-source-cohort-reconciliation` 5; listed in `reports/M03-import-data.json` → `oldStudies.otherSchema`).

Sessions run in **Claude** (owner's choice).
**Recommended model:** Claude Sonnet 5.5 · **thinking effort:** High
**Alternative:** Claude Opus 5.5 · Medium
**Reason:** several schema families, each mechanical, but every one needs the same care M03.1 needed: agent copies
(S17), placement of name-only outputs, raw-vs-derived fields and stable IDs. The rules are now written down and
tested, so a careful mid-size model suffices. Use Opus if the files turn out to be irregular.

## Ready-to-paste prompt for the next session

```text
You are continuing the Loot Liquidator historical-research migration (session MIG-004).

Repository: Voodoobrew101/Loot-Liquidator
Branch: migration/v3-historical-research (already exists on origin; check it out, do NOT work on main or
implementation/five-agent-completion, do NOT touch the addon .lua files).
If your clone is shallow, run: git fetch --depth=1000 origin migration/v3-historical-research
On Windows: clone to a short path with -c core.longpaths=true -c core.autocrlf=false, and use `python`.

READ FIRST, in order:
1. research/v3/migration/HANDOFF.md
2. research/v3/migration/PLAN.md (§2 point 2, §3 table and "Statistical rules" 1-4)
3. research/v3/migration/CHECKLIST.md (task M03)
4. research/v3/migration/SESSION_LOG.md (MIG-002, MIG-003)
5. research/v3/migration/SCHEMA-EXTENSION.md
6. research/v3/migration/reports/M03-import.md (and M05-identity.md "M03 warning")
7. research/v3/README.md, research/v3/evidence-format.md, research/v3/strategy.md threads S13 to S17
8. research/v3/tools/import_existing.py, research/v3/migration/tests/test_m03_import.py,
   research/v3/migration/manifest/inventory.jsonl (dispositions)

TASK: M03.2, M03.3, M03.4, M03.6 — remaining structured adapters. No AI extraction. No network.

Steps:
1. Baseline: run python research/v3/tools/build_estimates.py, copy research/v3/output/estimates.json outside the
   repo as before.json, copy research/v3/migration/reports/M03-identity-data.json the same way, then
   git checkout -- research/v3/output. Note whether SciPy is installed and use the same machine for after.
2. From manifest/inventory.jsonl list the files in scope: observation .json archives (11), research/evidence/v2/
   (count by format), research/evidence/leads (1), worker-submission JSON/JSONL that carry cohorts, ledger CSVs
   with disposition candidate-no-url, and the 43 other-schema JSONL records in reports/M03-import-data.json
   (oldStudies.otherSchema). Group them by schema family before writing code.
3. Add one adapter per schema family to research/v3/tools/import_existing.py (the only writer of
   research/v3/evidence/imported/), one output file per family. Same rules as M03.1: castsBasis plus derivations
   for every computed value, raw inputs copied never computed, ISO dataDate only (dataDateText, observedOn),
   migratedFrom on every row, name-only outputs placed only under PLAN §3 rule 4, no cohortKey, existing IDs
   (import-*) unchanged, new IDs after them. A record that duplicates an already imported or agent-held cohort is
   skipped with a reason. Model outputs, TSM tables and process artifacts are skipped with a reason. Reference
   tables become sourceKind reference only for rows not already present.
4. M03.6: classify each ledger CSV with numbers: import, or dispose with a reason (owner's personal ledgers may
   already be in GameData personal-pooled rows; check before importing).
5. Tests in research/v3/migration/tests/: one per adapter and rule, plus IDs stable, rerun byte-identical, and
   no reference row reaching study counts. Keep all 99 existing tests passing unless a test documents behaviour
   this task changes on purpose; say so in SESSION_LOG.md.
6. Rebuild, run tools/estimates_diff.py against before.json with --md reports/M03b-estimates-diff.md, rerun
   tools/identity_report.py --json reports/M03b-identity-data.json and compare it with M03-identity-data.json:
   any change in partial copies, pooled studies or differing groups must be explained. Check every new estimate
   row and every studyCasts increase for agent copies (the M03 Sparkling Shard double count is the model case).
   Then git checkout -- research/v3/output.
7. Run python -m unittest discover -s research/v3/migration/tests -v, tools/validate.py,
   research/v3/tools/audit_studies.py (then restore research/v3/output), and rebuild twice to confirm
   byte-identical output. Run import twice to confirm idempotence.

Rules: never edit agent evidence files, corrections.jsonl or strategy.md; do not commit research/v3/output/.
Do not change casts weighting: that is M06. The estimator should change only if a new field requires it.

Acceptance criteria:
- Every file in scope imported or given a reasoned skip, listed in reports/M03b-import.md with counts.
- Every imported row with casts has castsBasis; every computed value has a derivations entry; migratedFrom on all.
- All existing import-* IDs unchanged; corrections applied count unchanged (643 lines / 333 records).
- No new double counting: every new or increased estimate row checked against agent copies, findings listed.
- Estimates diff and identity comparison written and explained; 0 groups dropping differing numbers.
- All tests pass; importer and rebuild deterministic.

Update before ending: CHECKLIST.md (tick only subtasks met, update progress table; tick M03 itself only when all
seven subtasks are met), SESSION_LOG.md (append MIG-004 with commands actually run and measured numbers),
HANDOFF.md (status, next task, model/effort, next prompt), PLAN.md if a rule changed. Commit on
migration/v3-historical-research with message "v3 migration M03: <summary>" and push.

End with the mandatory report: A. Session summary; B. Progress and checklist (totals, %, newly ticked items,
migration metrics); C. Next recommended task (ID, why, dependencies, deliverables, acceptance); D. Next Claude
configuration (model, thinking effort, alternative, reason); E. A complete ready-to-paste prompt for the following session.
Default next task after this: M06 — units, denominators and cast-basis weighting (S16).
```

## Later tasks at a glance

M06 denominators and cast-basis weighting (S16) → M04 Markdown linking (the 92 agent-held name-only rows are link
candidates) and residual AI extraction → M07 dispositions → M08 estimator integration → M09 reports → M10 reconcile
with agents' branch and open the PR.
