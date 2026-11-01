# Handoff

**Updated:** 2026-10-31, end of session MIG-002.

## Status

- Repository `Voodoobrew101/Loot-Liquidator`, working branch **`migration/v3-historical-research`**
  (cut from `implementation/five-agent-completion` at snapshot `575b252`). Hourly agents keep committing to
  `implementation/five-agent-completion`; do not merge it in before M10.
- Complete: **M00** (audit/plan), **M01** (inventory), **M02** (validator, characterization tests, diff tool,
  schema extension), **M05** (study identity). 4 of 11 top-level tasks (36%).
- In progress / blocked: none.
- Latest verified baseline: 4,404 effective evidence records → **1,203 estimates** (35 unplaced); 67 migration
  tests pass; validator 15 errors / 693 warnings; identity report: 0 groups dropping differing numbers,
  23 partial copies, 1 pooled study; 1,244 historical files inventoried, 543 source URLs (165 cited in v3).
- Estimates sha256 with no SciPy installed: `9b9923e7…` (with SciPy, confidence values and so the hash differ).

## Read before relying on older numbers

- The logged 168 / 90 / 78 collision counts and "≈288k casts" are superseded by `reports/M05-identity.md`:
  measured 160 / 77 / 83, of which 29,056 material-level casts were truly independent cohorts.
- `cohortKey` beats the fingerprint, so a keyed study never merges with an unkeyed copy of it.
  **Do not set `cohortKey` in M03 unless both sides of a known copy get the same key.**
- Rows added to an imported study change its numeric vector, so M03.1 can change which studies count as copies.
  Rerun `identity_report.py` after any re-import and compare with `reports/M05-identity-data.json`.
- Open for the Master (`reports/M05-identity.md`): R3 Serevite label conflicts, 9 cross-source pairs needing
  `originalSource`, single-row subsets, and confirmation of the numbered-batch and pooled-study rules.

## Environment notes

- Windows: clone with `-c core.longpaths=true -c core.autocrlf=false` to a short path, or `research/coordination`
  filenames fail. Use `python`; `python3` may be the Store stub. SciPy was not installed in MIG-002.
- Without `core.autocrlf=false`, a rebuild shows every output file as modified.

## Next task: M03.0, M03.1, M03.5 — deterministic re-import

Why now: 291 imported rows carry nominal casts indistinguishable from reported ones, and 518 effective rows
have prose in `dataDate`, which down-weights them to 25%. M06 cannot unify cast bases until `castsBasis` exists.

Sessions run in **Claude** (owner's choice).
**Recommended model:** Claude Sonnet 5.5 · **thinking effort:** High
**Alternative:** Claude Opus 5.5 · Medium
**Reason:** careful, mostly mechanical importer work where stable IDs and provenance matter more than
statistical judgment; M03.0 and M03.1 need attention, but the rules are already written down.

## Ready-to-paste prompt for the next session

```text
You are continuing the Loot Liquidator historical-research migration (session MIG-003).

Repository: Voodoobrew101/Loot-Liquidator
Branch: migration/v3-historical-research (already exists on origin; check it out, do NOT work on main or
implementation/five-agent-completion, do NOT touch the addon .lua files).
If your clone is shallow, run: git fetch --depth=1000 origin migration/v3-historical-research
On Windows: clone to a short path with -c core.longpaths=true -c core.autocrlf=false, and use `python`.

READ FIRST, in order:
1. research/v3/migration/HANDOFF.md
2. research/v3/migration/PLAN.md (§2 point 3 and point 7, §3 "Schema extension")
3. research/v3/migration/CHECKLIST.md (task M03)
4. research/v3/migration/SESSION_LOG.md (MIG-002)
5. research/v3/migration/SCHEMA-EXTENSION.md
6. research/v3/migration/reports/M05-identity.md
7. research/v3/README.md, research/v3/evidence-format.md, research/v3/strategy.md threads S13 to S17
8. research/v3/tools/import_existing.py, research/v3/tools/build_estimates.py

TASK: M03.0, M03.1, M03.5 — deterministic re-import with castsBasis. No AI extraction. No network.

Steps:
1. Baseline: run python research/v3/tools/build_estimates.py, copy research/v3/output/estimates.json outside
   the repo as before.json, copy research/v3/migration/reports/M05-identity-data.json the same way, then
   git checkout -- research/v3/output.
2. M03.0: the 10 typeless records in evidence/midnight/2026-10-31-midnight-refining-shattering-decks.jsonl hold
   real observations in another field layout (sourceURL etc). Map them to valid records through importer output
   under research/v3/evidence/imported/, never by editing the agent file. Check each mapped number against the
   record itself. Keep them out of the estimates if a required field cannot be established; say why.
3. M03.1: re-import the 42 old observation JSONL files with these changes, keeping every existing import-* ID
   stable because corrections.jsonl references them:
   a. castsBasis: reported when the source states completed operations; nominalEquivalent for the 258 rows from
      fiveOreEquivalentOperations; countedFromInputs for the 33 from inputs / batch. Add a matching
      derivations entry for every computed casts value.
   b. inputsProcessed, inputsPurchased, inputsRefunded from the old raw fields, never computed.
   c. dataDate only when ISO; otherwise null with the text in dataDateText. Observation dates that the old
      importer put in source.published go to observedOn.
   d. migratedFrom {path, sha256, recordRef} on every row.
   e. Unmapped outputs kept as name-only rows with rawOutputName. New rows get new IDs after the existing
      ones, and the 14 duplicates and 22 model/TSM rows stay skipped with a reason in a report.
   f. Do NOT set cohortKey (see HANDOFF).
4. M03.5: compare GameData gd.mill, gd.prospect and gd.tsmRetail with the itemdb.lua rows. Import only missing
   rows, as sourceKind reference, so they never count as study casts. Do not edit GameData.lua.
5. Tests in research/v3/migration/tests/: one per adapter and rule, plus IDs stable, rerun byte-identical,
   and no reference row reaching study counts. Keep all 67 existing tests passing unless a test documents
   behaviour this task changes on purpose; say so in SESSION_LOG.md.
6. Rebuild, run tools/estimates_diff.py against before.json with --md reports/M03-estimates-diff.md, rerun
   tools/identity_report.py --json reports/M03-identity-data.json and compare it with the M05 file: any change
   in partial copies, pooled studies or differing groups must be explained. Then
   git checkout -- research/v3/output.
7. Run python -m unittest discover -s research/v3/migration/tests -v, tools/validate.py,
   research/v3/tools/audit_studies.py (then restore research/v3/output), and rebuild twice to confirm
   byte-identical output. Run import twice to confirm idempotence.

Rules: never edit agent evidence files, corrections.jsonl or strategy.md; do not commit research/v3/output/.
Do not change casts weighting: that is M06. The estimator should change only if a new field requires it.

Acceptance criteria:
- 10 typeless records mapped or individually explained; validator TYPE_MISSING errors at 0 or each one listed.
- Every imported row with casts has castsBasis; every computed value has a derivations entry.
- All existing import-* IDs unchanged; corrections still apply (corrections applied count unchanged).
- Free-text dataDate gone from imported rows; reported in numbers.
- GameData comparison reported; only missing rows imported, all as reference.
- Estimates diff and identity comparison written and explained; 0 groups dropping differing numbers.
- All tests pass; importer and rebuild deterministic.

Update before ending: CHECKLIST.md (tick only subtasks met, update progress table), SESSION_LOG.md (append
MIG-003 with commands actually run and measured numbers), HANDOFF.md (status, next task, model/effort, next
prompt), PLAN.md if a rule changed. Commit on migration/v3-historical-research with message
"v3 migration M03: <summary>" and push.

End with the mandatory report: A. Session summary; B. Progress and checklist (totals, %, newly ticked items,
migration metrics); C. Next recommended task (ID, why, dependencies, deliverables, acceptance); D. Next Claude
configuration (model, thinking effort, alternative, reason); E. A complete ready-to-paste prompt for the following session.
Default next task after this: M03.2 to M03.4 and M03.6 — remaining structured adapters.
```

## Later tasks at a glance

M03 remaining adapters (`.json` archives, v2, leads, submissions, ledger CSVs) → M06 denominators (S16) → M04
Markdown linking and residual AI extraction → M07 dispositions → M08 estimator integration → M09 reports → M10
reconcile with agents' branch and open the PR.
