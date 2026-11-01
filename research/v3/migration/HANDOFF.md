# Handoff

**Updated:** 2026-11-01, end of session MIG-009.

## Status

- Repository `Voodoobrew101/Loot-Liquidator`, working branch **`migration/v3-historical-research`**
  (cut from `implementation/five-agent-completion` at snapshot `575b252`). Hourly agents keep committing to
  `implementation/five-agent-completion`; do not merge it in before M10.
- Complete: **M00**, **M01**, **M02**, **M05**, **M03**, **M06**, **M04**, **M07**, **M08** (9 of 11 top-level tasks, 82%). Open: M09, M10.
- Latest verified baseline (no SciPy on the MIG-009 machine): 4,945 effective evidence records → **1,205 estimates** (449 unplaced);
  **348** migration tests pass; validator 5 errors / 175 warnings (each queued in `exceptions.jsonl` with a proposed fix); study audit
  475 studies, 40 clean; corrections 643 lines / 333 corrected records. **M08 changed no estimate.**
- Estimates sha256: `898790d5…` without SciPy (this machine), `d959496a…` with SciPy. `summary.md` differs from MIG-008 either way: it now
  carries the unused-reason table. Run before and after on the same machine; only confidence values depend on SciPy.

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

## Next task: M09 — migration audit and reporting

Why now: every estimator and data change is in; M09 only reads. It turns the per-task reports into one reproducible before/after
picture and an unresolved-issues register the owner can act on. Dependencies: M07, M08 (done). No network.

Sessions run in **Claude** (owner's choice).
**Recommended model:** Claude Sonnet 5.5 · **thinking effort:** Low
**Alternative:** Claude Sonnet 5.5 · Medium if the register needs more judgment than the manifests give
**Reason:** a read-only report generator over files that already hold the numbers; the work is joining and counting, with tests.

## Ready-to-paste prompt for the next session

```text
You are continuing the Loot Liquidator historical-research migration (session MIG-010).

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
2. research/v3/migration/PLAN.md (section 1 baseline, section 3 rules 1-9, "Definition of project completion")
3. research/v3/migration/CHECKLIST.md (task M09)
4. research/v3/migration/SESSION_LOG.md (MIG-001 baseline numbers, then each task's measured results)
5. research/v3/migration/reports/*.md and the *-data.json files (the numbers M09 must reproduce, not copy)
6. research/v3/migration/manifest/ (inventory, dispositions, exceptions, scope-gap, validation, url-registry)
7. research/v3/tools/build_estimates.py (analyze(), unused_report(), summary()) and research/v3/output after a rebuild

TASK: M09 - migration audit and reporting. Read-only: it changes no evidence, no estimator, no manifest. No network. No AI.

Deliverable: research/v3/migration/tools/report.py (+ tests) that writes, deterministically (sorted, no timestamps),
research/v3/migration/reports/M09-audit.md and M09-audit-data.json:
1. Before/after coverage. Before = the snapshot 575b252 (use the MIG-001 numbers in SESSION_LOG/PLAN and, where a number can be
   recomputed from git history, recompute it from `git show 575b252:...`); after = a rebuild now. Records, drop rows, study keys,
   estimates, unplaced, study casts total, estimates by method, estimates with measured chance, and sources (URLs) cited in v3 vs the
   543 historical URLs.
2. Confidence bands (90%+, 75-89, 50-74, under 50, conditional apart), before and after, and the estimates that moved bands, with the
   cause (identity M05, units M06, new evidence M03/M04) taken from the per-task diffs. State which SciPy setting produced them.
3. Disposition counts from manifest/dispositions.jsonl (all 1,244 files, 12 dispositions) and a check that the counts equal
   manifest/dispositions-summary.json.
4. Record usage from build_estimates.analyze(): used by role and unused by reason code (output/unused.json), with the top five
   reasons explained in one line each.
5. Unresolved-issues register: one row per open item from reports/M0*-*.md "For the Master" sections, manifest/exceptions.jsonl
   (134 rows, by kind), validator errors, scope-gap sources and the M08 findings. Each row: id, source report, kind, count, record IDs
   or a pointer, proposed owner action, whether it blocks M10. Do not invent items; every row must trace to a file.
6. A reproducibility check section: rebuild twice (byte-identical), dispositions.py --check, validate.py counts, test count.

Rules: never edit agent evidence files, corrections.jsonl, strategy.md or committed output/; do not commit research/v3/output/ (restore it
with git checkout -- research/v3/output and delete output/unused.json). report.py may import build_estimates read-only.

Acceptance criteria:
- Every number in M09-audit.md is produced by report.py (no hand-typed figures) and a test recomputes a sample.
- Register rows each cite a file; counts match the manifests; M10 blockers are marked.
- Two runs of report.py are byte-identical; all existing tests pass (348 expected).

Update before ending: CHECKLIST.md (tick only what is met), SESSION_LOG.md (append MIG-010 with commands actually run and measured
numbers), HANDOFF.md (status, next task M10, model/effort, next prompt). Commit on migration/v3-historical-research with message
"v3 migration M09: <summary>" and push.

End with the mandatory report: A. Session summary; B. Progress and checklist (totals, %, newly ticked items, migration metrics);
C. Next recommended task (ID, why, dependencies, deliverables, acceptance); D. Next Claude configuration (model, thinking effort,
alternative, reason); E. A complete ready-to-paste prompt for the following session, shown in full as the last thing in your final reply
(after the report, not only in HANDOFF.md).
Default next task after this: M10 - final reconciliation with implementation/five-agent-completion and the pull request.
```

## Later tasks at a glance

M09 audit and reporting → M10 reconcile with the agents' branch (fetch `implementation/five-agent-completion`, rerun the pipeline on the new
head, byte-identical rebuild, propose the `evidence-format.md` changes from SCHEMA-EXTENSION.md, open the PR).
