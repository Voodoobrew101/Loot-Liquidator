# Handoff

**Updated:** 2026-11-01, end of session MIG-008.

## Status

- Repository `Voodoobrew101/Loot-Liquidator`, working branch **`migration/v3-historical-research`**
  (cut from `implementation/five-agent-completion` at snapshot `575b252`). Hourly agents keep committing to
  `implementation/five-agent-completion`; do not merge it in before M10.
- Complete: **M00**, **M01**, **M02**, **M05**, **M03**, **M06**, **M04**, **M07** (8 of 11 top-level tasks, 73%). Open: M08, M09, M10.
- Latest verified baseline (SciPy installed): 4,945 effective evidence records → **1,205 estimates** (449 unplaced); **304** migration
  tests pass; validator 5 errors / 175 warnings (each queued in `exceptions.jsonl` with a proposed fix); study audit 475 studies,
  40 clean; corrections 643 lines / 333 corrected records. M07 changed no estimate.
- Estimates sha256 with SciPy: `d959496a…` (`summary.md` `fbf8e3b2…`). Without SciPy it differs (confidence values only).

## What M07 produced (MIG-008)

- `tools/dispositions.py` builds, deterministically, `manifest/dispositions.jsonl` (1,244 rows: path, sha256, final disposition from a
  closed vocabulary of 12, `reason {code, text}`, `pointers`), `manifest/exceptions.jsonl` (134 rows), `manifest/scope-gap.jsonl`
  (47 sources) and `manifest/dispositions-summary.json`. `python3 research/v3/migration/tools/dispositions.py [--check]`. Report:
  `reports/M07-dispositions.md` (counts, rules, scope gap, the 5 validator fixes, For the Master). PLAN section 3 rule 8 is new.
- Counts: no-observational-content 432, process-artifact 313, linked 131, held-sources-only 129, exception-queued 65, imported 55,
  extracted-null 47, reference-only 32, derived-model 22, source-links-only 10, extracted 4, mechanics-knowledge 4. Nothing is left
  `preliminary`, `candidate-*` or `covered-by-url`.
- The 46 null sources: their 42 residue files are 21 `extracted-null` + 21 `exception-queued`; 26 further files cite a null source;
  every null source is named with its code in some reason. The linker still reports them as residue (unchanged).
- Exception queue: 83 link groups (65 files), 6 Jallfo, s6bfrl (6 outputs), zkay8v (22 rows), 1smgllg (14), Felslate 101-vs-97, 12
  ambiguous-doubt, 9 cross-source pairs, 3 merges with conflicts, 12 single-row subsets, 5 validator errors. 1,070 record IDs named.
  The 12 ambiguous-doubt rows point at their checkpoint (nothing was written for them).
- Validator fixes are *proposed*, each as a correction line in the exception row: 3 `method: null` for rateChange records
  (`dragonflight-20261030-041`, `dragonflight-20261031-7010`, `war-within-20261031-18028`) and 2 `exclude` for quarantined ItemDB rows
  (`import-ref-00697`, `-00698`). Checked in memory: estimates unchanged, unplaced 449 → 447. `corrections.jsonl` is the Master's and was not touched.
- Scope gap: the 23 unheld sources with counts reproduce exactly; cutting CSV rows from the keys leaves 16, of which 9 are queue sources
  and 7 are decided (qualitative, IDs only, derivative calculator, a patch thread, a published table). No new checkpoint was needed and
  the linker pattern was not widened. A new such source fails a test until decided.
- `held-sources-only` (129) means every cited source is held at page or thread level and the file has no observational numbers of
  its own. It is not a claim that a cohort is covered.

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

## Next task: M08 — estimator integration

Why now: M03 to M07 settled what is in v3 and what each historical file became; M08 is the only task that changes
`build_estimates.py`, so it runs on a clean, fully classified corpus with golden before/after diffs available.
Dependencies: M05, M06 (done). No network.

Sessions run in **Claude** (owner's choice).
**Recommended model:** Claude Opus 5.5 · **thinking effort:** Medium
**Alternative:** Claude Sonnet 5.5 · High if the owner prefers it for cost; the changes are small but each needs a fixture test and a diff
**Reason:** this is the one task that changes estimator behaviour; a wrong default silently moves estimates, so the stronger model's care
with edge cases (structured `unlockState` against note text, ISO-only dates, `percentMeaning: null`) is worth it. Dispositions and reports are done.

## Ready-to-paste prompt for the next session

```text
You are continuing the Loot Liquidator historical-research migration (session MIG-009).

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
2. research/v3/migration/PLAN.md (section 2 items 4 and 7 and "Other design flaws", section 3 "Statistical rules" 1-8)
3. research/v3/migration/CHECKLIST.md (task M08)
4. research/v3/migration/SESSION_LOG.md (MIG-005 for the units work, MIG-008)
5. research/v3/migration/reports/M06-units.md and M06-units-data.json (unusedRows, contributeNothing, backfill), and
   research/v3/tools/units_report.py output: today's "unused reason" lives there
6. research/v3/migration/reports/M07-dispositions.md ("For the Master", the validator fixes)
7. research/v3/migration/SCHEMA-EXTENSION.md (unlockState, castsBasis, observedOn)
8. research/v3/tools/build_estimates.py (unlock_state(), chance_from_percent(), the date/epoch logic, study identity from M05/M06)
   and research/v3/migration/tests/test_build_estimates.py and test_m06_units.py (characterization tests)

TASK: M08 — the estimator consumes all usable evidence, and every record it does not use says why. No network. No AI extraction.

Steps:
1. Baseline: python research/v3/tools/build_estimates.py, copy research/v3/output/estimates.json outside the repo as before.json, then
   git checkout -- research/v3/output. Note whether SciPy is installed (expected estimates sha256 with SciPy: d959496a...).
   Run the tests (304 expected: python3 -m unittest discover -s research/v3/migration/tests).
2. Structured unlockState: build_estimates.unlock_state() must read the structured field (true / false / null) first and fall back to
   the note text only when the field is absent. List every record whose result changes (expect few: say how many) and why.
3. ISO-only dates: the epoch logic reads dataDate / observedOn only when ISO (YYYY-MM-DD or YYYY-MM); free text is never parsed.
   Count the records affected before and after.
4. percentMeaning guard: chance_from_percent() must not accept percentMeaning null as per-cast. Measure affected rows (expected 0)
   and pin it with a test either way.
5. Per-record unusedReason: output (a new file, for example output/unused.json, or a field in estimates.json: decide and explain)
   with one machine-readable reason code for every effective record the estimator does not use (unplaced, no numbers, totals without
   casts, conditional output with unlock unstated, excluded duplicate, reference prior only, and so on). The M06 contributeNothing
   list is the starting point. Every effective record is either used in an estimate or has a reason; a test enforces that.
6. Regression tests (research/v3/migration/tests/) for observed, derived, provisional, conditional and duplicate records, with small
   fixtures. Keep all 304 existing tests passing.
7. Decision on committing research/v3/output/: it is stale in git. Recommend commit-in-the-same-commit or never-commit and say why;
   do not commit it unless the owner's rule allows (current rule: do not commit research/v3/output/). Put the recommendation in the
   report and PLAN.md.
8. Golden diff: estimates_diff.py before.json vs after for every behavioural change, separately if possible, with the reason of each
   moved estimate. Rebuild twice (byte-identical), run the importer twice (idempotent), tools/validate.py, link_sources.py and
   dispositions.py --check (dispositions must still match; if build_estimates changes make them differ, explain). Corrections stay
   643 lines / 333 records.

Rules: never edit agent evidence files, corrections.jsonl or strategy.md; do not commit research/v3/output/. evidence-format.md is
owner-only: propose field changes in SCHEMA-EXTENSION.md. Never place an item by name and never guess an item ID. build_estimates.py
may change in this task only, behind tests.

Acceptance criteria:
- The three code changes (unlockState, ISO dates, percentMeaning guard) each have a test and a measured before/after.
- Every effective record is used or carries an unusedReason; counts by reason in reports/M08-estimator.md.
- Estimate diff for each change with reasons; unchanged where no change is expected; two rebuilds byte-identical.
- A "For the Master" section and the output/ decision.

Update before ending: CHECKLIST.md (tick only what is met), SESSION_LOG.md (append MIG-009 with commands actually run and measured
numbers), HANDOFF.md (status, next task M09, model/effort, next prompt), PLAN.md if a rule changed. Commit on
migration/v3-historical-research with message "v3 migration M08: <summary>" and push.

End with the mandatory report: A. Session summary; B. Progress and checklist (totals, %, newly ticked items, migration metrics);
C. Next recommended task (ID, why, dependencies, deliverables, acceptance); D. Next Claude configuration (model, thinking effort,
alternative, reason); E. A complete ready-to-paste prompt for the following session.
Default next task after this: M09 — migration audit and reporting (tools/report.py: before/after coverage, confidence bands,
disposition counts, unresolved-issues register).
```

## Later tasks at a glance

M08 estimator integration → M09 reports (`tools/report.py` from the manifests and outputs) → M10 reconcile with the agents' branch
(rerun the importer, `extract_batch.py write` and `dispositions.py`: their output may shrink as agents catch up) and open the PR.
