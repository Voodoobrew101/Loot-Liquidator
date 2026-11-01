# Handoff

**Updated:** 2026-10-31, end of session MIG-004.

## Status

- Repository `Voodoobrew101/Loot-Liquidator`, working branch **`migration/v3-historical-research`**
  (cut from `implementation/five-agent-completion` at snapshot `575b252`). Hourly agents keep committing to
  `implementation/five-agent-completion`; do not merge it in before M10.
- Complete: **M00**, **M01**, **M02**, **M05**, **M03** (5 of 11 top-level tasks, 45%). M03 finished in MIG-004
  (M03.2 archives, M03.3 v2 reports and leads, M03.4 submissions and the 43 other-schema records, M03.6 ledgers).
- Latest verified baseline (SciPy installed): 4,933 effective evidence records → **1,205 estimates** (447 unplaced);
  **125** migration tests pass; validator 5 errors / 175 warnings; identity report: 0 groups dropping differing numbers,
  24 partial copies, 24 near copies, 1 pooled study; study audit 473 studies, 40 clean.
- Estimates sha256 with SciPy: `3861b696…` (`summary.md` `0ed83dd3…`). Without SciPy it differs (confidence values only).

## Read before relying on older numbers

- `reports/M03b-import.md` explains every MIG-004 change. In short: 51 rows imported from 5 new sources; no estimate
  row added, no study casts changed; 8 chances moved ≤ 0.015 (TBC reference rows); 28 rows gained a study without casts.
- **Holdings rule (PLAN §3 rule 5):** a historical claim whose source v3 already holds is never imported. Mappers in
  `NEW_SOURCES` stop importing once agents record their source. So rerunning the importer at M10 cannot double count,
  but its output *can shrink* when agents catch up. The TBC reference table checks presence row by row.
- New totals-without-casts rows wait for M06: 24 legacy mass-milling rows (inputs and `inputsPerCast` 20), zzyjzu
  (~28,000 ore), plus 3 per-herb rates with no batch. The BfA/SL milling estimate groups already mix 20-herb mass-mill
  means (Jiyao) with five-herb equivalents (Baadkitty) under one per-cast figure.
- `castsBasis` exists on every imported row with casts; **weighting by basis is still M06**. `cohortKey` is still never set.
- Open for the Master: R3 Serevite labels, 9 cross-source pairs, single-row subsets (M05); the name-only placement rule,
  S14 pigment evidence, 9909's ranked input ID (M03); s6bfrl uncommon gems and the Felslate 2016 101-vs-97 total (M03b).

## Environment notes

- **Pushing from a Claude cloud session:** attach the repo with push access (retry the request once if refused). Use the
  remote URL `https://github.com/Voodoobrew101/Loot-Liquidator.git` and verify with
  `git ls-remote origin refs/heads/migration/v3-historical-research` after pushing.
- Windows: clone with `-c core.longpaths=true -c core.autocrlf=false` to a short path. Use `python`.
- Without `core.autocrlf=false`, a rebuild shows every output file as modified.
- With or without SciPy, run before and after on the same machine; only confidence values depend on it.
- When checking whether v3 holds a source, compare **normalized keys** (`source_keys.normalize_url`), never raw URLs:
  MIG-004 nearly double-imported a held forum post that way (the guard caught it).

## Next task: M06 — units, denominators and cast-basis weighting (S16)

Why now: all structured evidence is in v3 (M03 done), so one rule can be decided and tested over imported and agent
rows alike. Today 258 nominal-equivalent and 33 counted-from-inputs imported casts count at full weight, while agents'
"ore, not casts" totals (529 rows in 92 studies at MIG-001, plus MIG-004's 25 rows) count nothing. The milling groups
also mix per-cast units.

Sessions run in **Claude** (owner's choice).
**Recommended model:** Claude Opus 5.5 · **thinking effort:** High
**Alternative:** Claude Opus 5.5 · Extra High, if the unit audit turns up many mixed groups
**Reason:** this is the first estimator change since M05 that moves many estimates. It needs a statistical rule
(chance versus average weights by basis), a unit audit across groups and careful diff review. A mid-size model has
handled the mechanical importer work; this one is judgement-heavy.

## Ready-to-paste prompt for the next session

```text
You are continuing the Loot Liquidator historical-research migration (session MIG-005).

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
2. research/v3/migration/PLAN.md (§2 points 3-4, §3 "Statistical rules" 1-5)
3. research/v3/migration/CHECKLIST.md (task M06)
4. research/v3/migration/SESSION_LOG.md (MIG-003, MIG-004)
5. research/v3/migration/SCHEMA-EXTENSION.md
6. research/v3/migration/reports/M03-import.md and M03b-import.md ("For the Master")
7. research/v3/README.md, research/v3/evidence-format.md, research/v3/mechanics.md (G1, M6, M9, M10, W2),
   research/v3/strategy.md threads S5 to S17 (S15, S16 in particular)
8. research/v3/tools/build_estimates.py, research/v3/migration/tests/test_build_estimates.py

TASK: M06 — units, denominators and cast-basis weighting (S16). No AI extraction. No network.

Steps:
1. Baseline: run python research/v3/tools/build_estimates.py, copy research/v3/output/estimates.json outside the
   repo as before.json, copy research/v3/migration/reports/M03b-identity-data.json the same way, then
   git checkout -- research/v3/output. Note whether SciPy is installed and use the same machine for after.
2. Measure before changing code: every drop row by castsBasis and by whether it has casts, totalQuantity,
   inputsProcessed, averageShown/averagePer and inputsPerCast; the totals-only rows that contribute nothing today
   (by study and agent); and every estimate group whose study rows use different inputsPerCast (e.g. 20-herb mass
   milling next to 5- or 10-herb casts). Write the counts into reports/M06-units.md first.
3. Decide and document one rule (PLAN §3 rule 2): reported casts count fully; countedFromInputs and
   nominalEquivalent casts count toward the average but enter the chance confidence at a reduced, documented weight;
   rows with inputsProcessed and inputsPerCast but no casts get casts = inputsProcessed / inputsPerCast with that
   reduced weight (Resourcefulness per mechanics M9/M10/W2 only blurs it). The same rule for imported and agent rows.
   Normalize per input before mixing rows with different batch sizes in one group, or keep them in separate groups;
   say which and why. Agent rows that state the input count only in notes: list them as backfill candidates for
   the Master (S16 asks who backfills); do not edit agent files or corrections.jsonl.
4. Implement in research/v3/tools/build_estimates.py behind tests in research/v3/migration/tests/: one test per
   basis, per-input normalization, mixed batch groups, refunds, and that reference rows never reach study counts.
   Keep all 125 existing tests passing unless a test documents behaviour this task changes on purpose; say so in
   SESSION_LOG.md (characterization tests in test_build_estimates.py say which defects they pin).
5. Rebuild, run tools/estimates_diff.py against before.json with --md reports/M06-estimates-diff.md, rerun
   tools/identity_report.py --json reports/M06-identity-data.json and compare it with M03b-identity-data.json: any
   change in partial copies, pooled studies or differing groups must be explained. Review every row whose chance
   moves 5+ points or whose studyCasts rises, checking for copies (the M03 Sparkling Shard double count is the model case).
   Then git checkout -- research/v3/output.
6. Run python -m unittest discover -s research/v3/migration/tests -v, tools/validate.py,
   research/v3/tools/audit_studies.py (then restore research/v3/output), and rebuild twice to confirm byte-identical
   output. Run the importer twice to confirm it is unchanged and idempotent.

Rules: never edit agent evidence files, corrections.jsonl or strategy.md; do not commit research/v3/output/.
evidence-format.md is owner-only: propose field changes in SCHEMA-EXTENSION.md.

Acceptance criteria:
- One rule for reported vs countedFromInputs/nominalEquivalent casts, applied to imported and new rows alike, with a test per basis.
- The totals-only rows either contribute under the rule or carry a machine-readable reason; counts before and after.
- Per-input/per-cast/per-hit/aggregate units checked; no estimate group mixes batch sizes without normalization.
- Estimates diff and identity comparison written and explained; 0 groups dropping differing numbers; no new double counting.
- Corrections applied count unchanged (643 lines / 333 records); all tests pass; rebuild and importer deterministic.

Update before ending: CHECKLIST.md (tick only what is met, update the progress table), SESSION_LOG.md (append MIG-005
with commands actually run and measured numbers), HANDOFF.md (status, next task, model/effort, next prompt), PLAN.md if
a rule changed. Commit on migration/v3-historical-research with message "v3 migration M06: <summary>" and push.

End with the mandatory report: A. Session summary; B. Progress and checklist (totals, %, newly ticked items,
migration metrics); C. Next recommended task (ID, why, dependencies, deliverables, acceptance); D. Next Claude
configuration (model, thinking effort, alternative, reason); E. A complete ready-to-paste prompt for the following session.
Default next task after this: M04 — Markdown linking (M04.1 link_sources.py; the 92 agent-held name-only rows, the
1smgllg rates and the s6bfrl uncommon gems are link candidates) and residual AI extraction.
```

## Later tasks at a glance

M04 Markdown linking (link candidates listed in `reports/M03-import.md` and `M03b-import.md`) and residual AI extraction
→ M07 dispositions (including the 37 `v2/source-reviews` files and 21 submission audit CSVs, all without study objects)
→ M08 estimator integration → M09 reports → M10 reconcile with the agents' branch (rerun the importer: its MIG-004 output
may shrink as agents catch up) and open the PR.
