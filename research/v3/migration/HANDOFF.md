# Handoff

**Updated:** 2026-11-01, end of session MIG-010.

## Status

- Repository `Voodoobrew101/Loot-Liquidator`, working branch **`migration/v3-historical-research`**
  (cut from `implementation/five-agent-completion` at snapshot `575b252`). Hourly agents keep committing to
  `implementation/five-agent-completion`; do not merge it in before M10.
- Complete: **M00**, **M01**, **M02**, **M05**, **M03**, **M06**, **M04**, **M07**, **M08**, **M09** (10 of 11 top-level tasks, 91%). Open: M10.
- Latest verified baseline (no SciPy on the MIG-010 machine): 4,945 effective evidence records → **1,205 estimates** (449 unplaced);
  **390** migration tests pass; validator 5 errors / 175 warnings (each queued in `exceptions.jsonl` with a proposed fix); study audit
  475 studies, 40 clean; corrections 643 lines. **M09 changed no evidence, estimator, manifest or estimate.**
- Estimates sha256: `898790d5…` without SciPy (this machine), `d959496a…` with SciPy. Run before and after on the same machine; only
  confidence values depend on SciPy.

## What M09 produced (MIG-010)

- `tools/report.py` writes `reports/M09-audit.md` and `reports/M09-audit-data.json`. `python research/v3/migration/tools/report.py [--check] [--no-tests]`.
  It exports each stage in `STAGES` from git into a temporary folder and rebuilds it with that commit's own estimator, so before/after and
  the causes are measured, never quoted. It writes nothing to `output/`. Needs history back to `575b252`. About 50 s with tests.
- Snapshot rebuild agrees with all 8 figures in PLAN section 1 (the exported snapshot copy gets the M05 Windows `_file` fix, nothing else).
- Coverage, before → after: records 4,404 → 4,945; study rows 2,364 → 2,817; study keys 426 → 475; estimates 1,238 → 1,205 (35 removed by
  M05, 2 added by M03); unplaced 35 → 449 (almost all M03 name-only rows, kept by design); estimates with measured chance 101 → 101;
  historical URLs mentioned in v3 165 → 184 of 543.
- Bands (no SciPy): 37 estimates moved, 26 down and 11 up: 28 by units (M06), 9 by identity (M05), 0 by new evidence. M03 and M04 added
  records but moved no band. 355 of the 370 estimates in 50-74% are derived chances at exactly 50, the ceiling of the halving rule (S5).
  **These band figures are for no SciPy. A SciPy machine has not run report.py.**
- Register: 175 open rows (37 from reports, 134 exceptions, 2 validator codes, 2 scope-gap groups), 10 report items closed. A new numbered item in
  a report's Master section fails until it has an entry in `ITEMS`.
- **One M10 blocker: `M08-estimator/master#2`**, the `unlockState` wording for `evidence-format.md`. It blocks only that part of the proposal, not the
  pipeline rerun or the PR. Five `handle` rows need care in M10 and no decision (`M05-identity/master#4`, `M04-extraction/master#6`,
  `M07-dispositions/master#1`, `M08-estimator/master#1`, `HANDOFF/unused-json`).
- `tests/test_m09_report.py` (42 tests). `test_markdown_figures_all_come_from_the_data` fails on a figure typed into the prose.

## What M08 produced (MIG-009)

- `build_estimates.py` (changed in this task only): `unlock_state()` reads the structured `unlockState` first (explicit null = not
  stated, no text fallback); `iso_date()` / `dated_by()` read dates ISO-only; `chance_from_percent()` needs `percentMeaning == "perCast"`;
  `analyze()` returns per-record usage next to the estimates (`build()` is unchanged for callers); `unused_report()` writes
  `output/unused.json`; `REASON_CODES` is the closed vocabulary.
- The three guards touch **0 records** today and move **0 estimates** (`estimates_diff.py`: 0 added, 0 removed, 0 changed). 2,597 of 4,945
  records are used; 2,348 carry one reason (largest: `type:*` 836, `unplaced:*` 449, `totalWithoutCasts` 320, `reference:*` 226,
  `duplicateStudy` 148, `duplicateRowInStudy` 134, `copy:*` 83). M06's 626 contribute-nothing rows reconcile exactly.
- `tools/estimator_effects.py` keeps the old rules beside the new and counts differing records; `tests/test_m08_estimator.py` (44 tests)
  includes a corpus test that every record is used or has a reason.
- `reports/M08-estimator.md` has the reason table, the findings and "For the Master": output policy and a SciPy pin; the `unlockState`
  null hazard with `evidence-format.md`; ranked rows sharing a family group; ranges collected before dedupe. PLAN section 3 rule 9 is new.
- `research/v3/.gitignore` ignores `output/unused.json` until the owner decides the `output/` policy. Before committing, run
  `git checkout -- research/v3/output` and delete the untracked `output/unused.json`.
- Open question to the owner from MIG-009: whether `unused.json` should live outside `output/` (the owner asked why it was not placed
  "just outside the guard rails"; the message was not fully clear). Moving it is a one-line change in `build_estimates.main()`.

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
- `tools/units_report.py` lists every placed study row that contributes nothing (M06). Since M08 every record has a reason in
  `output/unused.json`; the two reconcile exactly (`reports/M08-estimator.md`).
- **Holdings rule (PLAN section 3 rule 5):** a historical claim whose source v3 already holds is never imported, so an M10
  importer rerun cannot double count but its output can shrink when agents catch up. Wowhead keys with a language suffix (`@es`,
  `@fr`, ...) are the same page; game flavours (`@cata`, `@wotlk`) are not.
- The queue is a lower bound (`reports/M04-extraction.md`, finding 1): notes the inventory marked `source-links-only` were never in
  scope, and the observational-count pattern needs a unit word after the number. 114 file mentions of the 55 sources lie outside
  their queue entries; 23 unheld source keys with a number of 20 or more beside the citation sit in out-of-scope files (10 of those I could name are queue
  sources; most others are guide URLs in audit-CSV rows).
- Agents still write counted casts without `castsBasis` (398 rows) and input counts only in notes (434 totals). Both lists are in
  `M06-units-data.json` → `backfill` for the Master. `cohortKey` is still never set.
- Open for the Master from M08: the `output/` commit policy and a SciPy pin; the `unlockState` null hazard; ranked rows sharing a
  family group; ranges collected before dedupe (`reports/M08-estimator.md`).
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

## Next task: M10 — final reconciliation and the pull request

Why now: it is the last task. Everything on this branch is measured and reported; what remains is taking in what the hourly agents wrote
since the snapshot and opening the PR. Dependencies: all tasks done. One owner decision is needed for one step (below).

Sessions run in **Claude** (owner's choice).
**Recommended model:** Claude Sonnet 5.5 · **thinking effort:** High
**Alternative:** Claude Opus 5.5 · High if the merge moves many estimates or the importer's holdings rule shrinks imported rows
**Reason:** a long mechanical pipeline where the risk is misreading a diff, not writing new logic; High keeps it reading each diff.

## Ready-to-paste prompt for the next session

```text
You are continuing the Loot Liquidator historical-research migration (session MIG-011).

Repository: Voodoobrew101/Loot-Liquidator
Branch: migration/v3-historical-research (already exists on origin; check it out, do NOT work on main, do NOT touch the addon .lua files).
If your clone is shallow, run: git fetch --depth=1000 origin migration/v3-historical-research
The research corpus (research/, including research/v3/ and research/v3/migration/) exists ONLY on this branch and on
implementation/five-agent-completion; main holds just the addon. If your copy is on main, run:
  git fetch --depth=1000 origin migration/v3-historical-research
  git checkout -b migration/v3-historical-research FETCH_HEAD
Push access: the owner has granted it. In a Claude cloud session, attach the repo with push access; if that request
is denied, retry it once before falling back. Use the exact remote URL
https://github.com/Voodoobrew101/Loot-Liquidator.git and confirm the push with git ls-remote.
On Windows: clone to a short path with -c core.longpaths=true -c core.autocrlf=false, and use `python`.
report.py needs the branch's history back to 575b252; a shallow clone must reach it.

BEFORE ANYTHING ELSE: compare this prompt with research/v3/migration/HANDOFF.md. If HANDOFF says M10 is done, stop and say so.

READ FIRST, in order:
1. research/v3/migration/HANDOFF.md
2. research/v3/migration/reports/M09-audit.md (section 5: the register; the blocker and the five "handle" rows)
3. research/v3/migration/PLAN.md (section 3 rules 1-9, "Definition of project completion")
4. research/v3/migration/CHECKLIST.md (task M10)
5. research/v3/migration/SCHEMA-EXTENSION.md
6. research/v3/migration/reports/M08-estimator.md (the unlockState hazard and the output/ policy)

TASK: M10 - take in the agents' work since the snapshot, rerun the whole pipeline, propose the evidence-format.md changes, open the PR.

Steps:
1. Baseline: run tools/report.py --no-tests and copy reports/M09-audit-data.json, plus a rebuilt output/estimates.json, outside the repo.
   Note the SciPy setting; before and after must use the same one.
2. git fetch origin implementation/five-agent-completion. Merge it into migration/v3-historical-research (never force, never rebase).
   Agent evidence files and corrections.jsonl take the agents' side; a conflict in anything else is stopped and reported, not guessed.
3. Rerun from scratch, in order, each one read before the next: tools/inventory.py, research/v3/tools/import_existing.py, tools/link_sources.py,
   tools/extract_batch.py write --check, tools/dispositions.py, tools/validate.py, research/v3/tools/build_estimates.py twice.
   Explain every change: the holdings rule (PLAN section 3 rule 5) lets imported rows shrink when agents catch up, and a source an agent
   now holds is reported as held. All existing import-* IDs stay; corrections still apply (report the counts).
   A new scope-gap source fails test_scope_gap_is_fully_decided until it has a decision.
4. Do NOT set cohortKey on imported rows alone (M05-identity/master#4). Do not move unused.json or commit output/ (M08-estimator/master#1).
5. Regenerate the audit: tools/report.py (add the merge as a stage in STAGES only if that makes the causes clearer) and
   tools/estimates_diff.py <baseline> research/v3/output/estimates.json --md reports/M10-estimates-diff.md.
6. Write reports/M10-evidence-format-proposal.md: the changes from SCHEMA-EXTENSION.md as a proposal; evidence-format.md is owner-only, do not edit it.
   BLOCKER (M08-estimator/master#2): the unlockState wording needs the owner's rule. Ask the owner before writing that part; if there is no
   answer, write both options and mark it undecided, and keep unlockState out of any recommended text. Include the METHODS option from
   M07-dispositions/master#1 the same way.
7. Run all tests, tools/validate.py, research/v3/tools/audit_studies.py (then restore output), rebuild twice for byte identity, importer twice.
8. Open a pull request against implementation/five-agent-completion. Do not merge it. Do not enable auto-merge.

Rules: never edit agent evidence files, corrections.jsonl, strategy.md, evidence-format.md or committed output/; do not commit research/v3/output/
(restore it with git checkout -- research/v3/output and delete output/unused.json).

Acceptance criteria:
- Branch contains the latest implementation/five-agent-completion, with no conflict resolved by guessing.
- Full pipeline rerun: every tool reproduces its files; rebuild and importer byte-identical; all tests pass (390 expected, plus any added).
- Every change from the merge is explained in reports/M10-*.md: records, estimates, band moves, dispositions, exceptions, unplaced.
- evidence-format.md change proposed, with the blocker either answered or marked undecided.
- PR open against implementation/five-agent-completion, not merged.

Update before ending: CHECKLIST.md (tick only what is met), SESSION_LOG.md (append MIG-011 with commands actually run and measured numbers),
HANDOFF.md (status, what the owner must decide next). Commit on migration/v3-historical-research with message
"v3 migration M10: <summary>" and push.

End with the mandatory report: A. Session summary; B. Progress and checklist (totals, %, newly ticked items, migration metrics);
C. What the owner must do next; D. PR link. If anything is left, E. A complete ready-to-paste prompt for the following session, shown in full
as the last thing in your final reply.
```

## Later tasks at a glance

None after M10. What stays open after the PR is the owner's register: `reports/M09-audit.md` section 5.
