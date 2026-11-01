# Handoff

**Updated:** 2026-10-31, end of session MIG-001.

## Status

- Repository `Voodoobrew101/Loot-Liquidator`, working branch **`migration/v3-historical-research`**
  (cut from `implementation/five-agent-completion` at snapshot `575b252`). Hourly agents keep committing to
  `implementation/five-agent-completion`; do not merge it in before M10.
- Complete: **M00** (audit/plan), **M01** (inventory), **M02** (validator, characterization tests, diff tool,
  schema extension). 3 of 11 top-level tasks (27%).
- In progress / blocked: none.
- Latest verified baseline: 4,404 effective evidence records → 1,238 estimates (35 unplaced); 41 migration
  tests pass; validator 15 errors / 693 warnings; 1,244 historical files inventoried, 543 source URLs (165 cited in v3).

## Next task: M05 — study identity and deduplication

Why now: it is the largest measured correctness defect (168 collision groups; 90 drop independent cohorts,
≈288k material-level casts), it touches only `study_identity()` in the estimator, and the tests that guard it
now exist.

Sessions run in **Claude** (owner's choice).
**Recommended model:** Claude Opus 5.5 · **thinking effort:** High
**Alternative:** Claude Sonnet 5.5 · High
**Reason:** statistical-identity logic where a wrong rule either double-counts copies or discards real cohorts;
needs careful reasoning over edge cases, but the scope is one function plus tests, so Extra High is unnecessary.

## Ready-to-paste prompt for the next session

```text
You are continuing the Loot Liquidator historical-research migration (session MIG-002).

Repository: Voodoobrew101/Loot-Liquidator
Branch: migration/v3-historical-research (already exists on origin; check it out, do NOT work on main or
implementation/five-agent-completion, do NOT touch the addon .lua files).
If your clone is shallow, run: git fetch --depth=1000 origin migration/v3-historical-research

READ FIRST, in order:
1. research/v3/migration/HANDOFF.md
2. research/v3/migration/PLAN.md (especially §2 point 6 and §3 "Statistical rules", rule 1)
3. research/v3/migration/CHECKLIST.md (task M05)
4. research/v3/migration/SESSION_LOG.md (MIG-001)
5. research/v3/README.md, research/v3/evidence-format.md, research/v3/strategy.md threads S7 and S17
6. research/v3/tools/build_estimates.py (study_identity() and its use in build())
7. research/v3/migration/SCHEMA-EXTENSION.md (cohortKey)

TASK: M05 — Study identity and deduplication. Count each independent cohort exactly once.

Problem (measured in MIG-001): study_identity() = (originalSource or source.url or studyKey, inputRank, casts,
studyKey-if-no-casts). Different batches from one source with equal cast counts collapse: 168 estimate groups
have distinct studyKeys sharing an identity; in 90 the numbers differ (independent cohorts dropped, e.g. ten
2,000-cast Draconium R2 batches from reddit 10u5ao8 "reddit-10u5ao8-20230206-draconium-r2-batch01..10", and
Bugy's "wowhead-bugy-374627-serevite-ore-1"/"-2"); in 78 the numbers are identical (true copies, correctly
merged). Copies whose ranked IDs are null still slip through (S17: dragonflight-20261031-50001..025 copy
import-study-00483..507; war-within-20261031-823001..007 copy war-within-20261030-701..707).

Steps:
1. Baseline: `python3 research/v3/tools/build_estimates.py`, copy research/v3/output/estimates.json to
   /tmp/before.json, then `git checkout -- research/v3/output`.
2. Write research/v3/migration/tools/identity_report.py: for every estimate group, list studyKeys that share a
   study identity and classify identical-numbers vs differing-numbers. Reproduce 168 / 90 / 78 first.
3. Change study identity in build_estimates.py (smallest change that works):
   a. If a record has `cohortKey`, identity = ("cohort", cohortKey). Add cohortKey to CORRECTABLE.
   b. Otherwise identity is the STUDY-LEVEL fingerprint: normalized source (originalSource or source.url;
      reuse the normalization rules in research/v3/migration/tools/inventory.py normalize_url — move it to a
      small shared module under research/v3/tools/ if you import it from the estimator), inputRank, casts, and
      the full numeric vector of all rows of that study (rows sharing file+studyKey): per output, keyed by
      outputItemID or lower-cased outputName, the tuple (castsWithDrop, totalQuantity, percentShown, averageShown).
      Same fingerprint = copy (count once). Same source but different vector = independent cohort (count both).
   c. A zero-hit material must NOT merge two independent batches: the fingerprint is per study, not per row.
   d. Partial copies (one study's vector is a strict subset of another's with ≥2 equal non-zero outputs): treat
      as a copy and list them in the report for review.
   e. Keep the existing unlock-skip semantics (a study is marked counted only when used).
   f. Do not use network access, do not edit any evidence file or corrections.jsonl, do not commit
      research/v3/output/.
4. Tests (research/v3/migration/tests/): flip test_known_defect_identity_collapses_independent_batches into a
   test that both batches count; add tests for: copy across files with different studyKeys; copy with null ranked
   output IDs vs ranked IDs by name; zero-hit material in two independent batches; partial copy; cohortKey
   overriding the fingerprint. Keep every other existing test passing.
5. Rebuild, run `python3 research/v3/migration/tools/estimates_diff.py /tmp/before.json
   research/v3/output/estimates.json --md research/v3/migration/reports/M05-estimates-diff.md`, rerun the
   identity report, then `git checkout -- research/v3/output`.
6. Write research/v3/migration/reports/M05-identity.md: rule, before/after collision counts, top estimate
   changes, partial-copy list, and a short proposal note for the Master (do NOT edit strategy.md).
7. Run: `python3 -m unittest discover -s research/v3/migration/tests -v`,
   `python3 research/v3/migration/tools/validate.py`, `python3 research/v3/tools/audit_studies.py`
   (then restore research/v3/output), and rebuild twice to confirm byte-identical output.

Acceptance criteria:
- All 10 reddit 10u5ao8 batches and both Bugy Serevite cohorts contribute (show studyCasts in the report).
- Known copy pairs count once (fixture tests; the zkay8v copy is already excluded by correction).
- Identity report: 0 groups where differing numbers are dropped; remaining merges are identical or listed partial copies.
- Estimates diff written and summarized; all tests pass; rebuild deterministic.

Update before ending: CHECKLIST.md (tick M05 subtasks only if met, update progress table), SESSION_LOG.md
(append MIG-002 with commands actually run and measured numbers), HANDOFF.md (status, next task, model/effort,
next prompt), PLAN.md if the rule changed. Commit on migration/v3-historical-research with message
"v3 migration M05: <summary>" and push.

End with the mandatory report: A. Session summary; B. Progress and checklist (totals, %, newly ticked items,
migration metrics); C. Next recommended task (ID, why, dependencies, deliverables, acceptance); D. Next Claude
configuration (model, thinking effort, alternative, reason); E. A complete ready-to-paste prompt for the following session.
Default next task after M05: M03 (M03.0, M03.1, M03.5) — deterministic re-import with castsBasis.
```

## Later tasks at a glance

M03 importer (castsBasis, raw quantities, structured dates, v2/json adapters, GameData tables) → M06
denominators (S16) → M04 Markdown linking and residual AI extraction → M07 dispositions → M08 estimator
integration → M09 reports → M10 reconcile with agents' branch and open the PR.
