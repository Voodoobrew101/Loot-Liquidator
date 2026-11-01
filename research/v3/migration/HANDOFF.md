# Handoff

**Updated:** 2026-11-01, end of session MIG-011.

## Status

- Repository `Voodoobrew101/Loot-Liquidator`, working branch **`migration/v3-historical-research`**
  (cut from `implementation/five-agent-completion` at snapshot `575b252`; since MIG-011 it also contains that branch up to `0260584`).
- Complete: **M00**, **M01**, **M02**, **M05**, **M03**, **M06**, **M04**, **M07**, **M08**, **M09** (10 of 11 top-level tasks, 91%).
  **M10 is in progress: everything but the pull request is done**; no PR tool was available in MIG-011 (see "Next task").
- Latest verified baseline (no SciPy on the MIG-011 machine): 5,632 effective evidence records → **1,133 estimates** (451 unplaced);
  **402** migration tests pass; validator 5 errors / 259 warnings; study audit 595 studies, 70 clean; corrections 683 lines (397 record IDs).
- Estimates sha256 (no SciPy): `1089e517…`; `summary.md` `d2b1a1bb…`; `unused.json` `df921753…`. Earlier hashes (`898790d5…`) are for the pre-merge evidence.
  Run before and after on the same machine; only confidence values depend on SciPy.

## What M10 produced (MIG-011)

- Merged `implementation/five-agent-completion` (`0260584`, 40 commits, 38 new agent evidence files with 742 records) into this branch: merge commit
  `e9a0243`. One conflict, in `build_estimates.py`: kept M05's `source_key` and ported the reviewer's S7 page rule into it (`same_page()`,
  `SAME_PAGE_SUFFIXES`: a Wowhead page under a language prefix or `/ptr/` is one page; game flavours are not). Tontons' BfA table now counts once,
  253 / 322 / 555 casts, as the reviewer reports. `normalize_url`, the URL registry, the linker and the importer are unchanged.
- Full pipeline rerun on the merged tree: inventory, importer, linker, extractor check, dispositions, validator, two rebuilds (byte-identical), audit.
  Importer: `import-v2report-00016` dropped by the holdings rule (the dragonflight agent recorded Reddit zzyjzu); two name-only rows no longer placed
  by name; all other `import-*` IDs unchanged; the importer rerun moves no estimate.
- Estimates 1,205 → 1,133: 84 removed (all re-keying: their 150 rows now sit in item-ID groups), 12 added, 138 changed. 61 estimates differ in band
  from the snapshot (27 at this merge). The identity report shows 10 `differing` groups: all one pair of copies (Superbondez Prismatic, S17), pinned
  by a test. Details and the full explanation: `reports/M10-merge.md`, `M10-estimates-diff.md`, `M10-identity-data.json`.
- `reports/M10-evidence-format-proposal.md`: the `evidence-format.md` proposal. **Two choices are undecided and need the owner:** the `unlockState`
  rule (option A omit-unless-stated, recommended, or option B change the code so `null` means absent) and the METHODS wording for the three
  `rateChange` records. `evidence-format.md` was not edited.
- `tests/test_m10_merge.py` (12). Existing tests that pinned corpus numbers the merge moved were updated with a reason beside each
  (`reports/M10-merge.md` section 6).
- `reports/M09-audit.md` regenerated with the merge as a stage; the register has 181 open rows (the M10 report's six items and strategy S18 / S19 are new).
- `reports/M10-pr-description.md` is the drafted PR text.

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

## Next task: open the pull request (the last step of M10)

Why: acceptance for M10 includes an open PR against `implementation/five-agent-completion`. MIG-011 had no way to open one: `gh` is not installed on the
owner's machine and the GitHub plugin failed to connect ("Authorization header is badly formatted"). The branch is pushed, so the owner can open it
by hand: `https://github.com/Voodoobrew101/Loot-Liquidator/compare/implementation/five-agent-completion...migration/v3-historical-research`, with
`reports/M10-pr-description.md` as the description. Do not merge it; do not enable auto-merge.

Owner decisions that are not blockers for the PR (all rows in `reports/M09-audit.md` section 5): the `unlockState` rule and the METHODS wording for
`evidence-format.md` (`reports/M10-evidence-format-proposal.md`); S19 (Serevite rank IDs, wait for the reviewer's table); the M06 weight and
backfills; the exception queue; the output/ and SciPy policy.

**Recommended model:** Claude Sonnet 5.5 · **thinking effort:** Low (only if a session is used; opening the PR by hand takes a minute)
**Reason:** one `gh pr create` or one browser form; the work is done.

## Ready-to-paste prompt for the next session

```text
You are finishing the Loot Liquidator historical-research migration (session MIG-012). Only the pull request is left.

Repository: Voodoobrew101/Loot-Liquidator, branch migration/v3-historical-research (on origin; do NOT work on main, do NOT touch addon .lua files).
Clone to a short path with -c core.longpaths=true -c core.autocrlf=false; use `python` on Windows.

1. Read research/v3/migration/HANDOFF.md first. If it says the PR is open, stop and say so.
2. Verify: git ls-remote origin refs/heads/migration/v3-historical-research equals your HEAD; python -m unittest discover -s research/v3/migration/tests
   (402 expected); python research/v3/migration/tools/report.py --check (identical).
3. Open a pull request, base implementation/five-agent-completion, head migration/v3-historical-research, body from
   research/v3/migration/reports/M10-pr-description.md. Do not merge. Do not enable auto-merge. If no tool can open it, say so and give the compare URL.
4. Tick M10 in CHECKLIST.md only after the PR exists; add the PR link to HANDOFF.md and SESSION_LOG.md (MIG-012). Commit and push.

End with: A. what you did, B. the PR link, C. the owner decisions still open (M09-audit.md section 5), D. nothing else.
```

## Later tasks at a glance

None after the PR. What stays open is the owner's register: `reports/M09-audit.md` section 5.
