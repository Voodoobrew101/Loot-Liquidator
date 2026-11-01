# M10: merge with `implementation/five-agent-completion` and full pipeline rerun (MIG-011)

Machine: Windows, Python 3.15.2, **no SciPy** (confidence values are the fallback's). Before and after ran on the same machine. The estimates
diff is `M10-estimates-diff.md`, the identity lists are `M10-identity-data.json`, the audit is `M09-audit.md` (regenerated, with the merge as
its own stage).

## 1. The merge

`implementation/five-agent-completion` at `0260584` was 40 commits ahead of the snapshot `575b252`: 38 new agent evidence files (742 records:
526 drop, 104 noDisenchant, 41 token, 35 exchange, 32 recipe, 4 condition) and changes to `corrections.jsonl` (+40 lines), `conditions.jsonl`,
`flags.jsonl`, `log.md`, `mechanics.md`, `strategy.md` (S18 and S19 are new), the committed `output/` and `build_estimates.py`. No `.lua` file.

**One conflict**, in `research/v3/tools/build_estimates.py`. The reviewer's `norm_source` (S7, commit `40d9f76`) was written against the old
`study_identity`; M05 had already replaced that function. Kept M05's `source_key` and ported the one rule `norm_source` had that
`normalize_url` does not: a Wowhead page under a language prefix or `/ptr/` is the same page (`SAME_PAGE_SUFFIXES`, `same_page()`). Game
flavours (`@cata`, `@wotlk`, `@tbc`, `@mop-classic`) stay apart. The reviewer's other estimator change (family conditions keep their input IDs
in `load_conditions`) merged cleanly. Everything else merged without conflict; agent evidence and `corrections.jsonl` are the agents' side.

Why the port was needed, measured: under M05's key one Tontons spell page recorded as `/ru/`, `/cn/`, `/ptr/` and plain had four keys, so the
BfA table counted several times (877 casts for Platinum and Storm Silver). With the port the estimator gives 253 / 322 / 555 casts for
Monelite / Platinum / Storm Silver, the numbers the reviewer reports, and the same as the reviewer's own estimator run over the merged evidence.
`normalize_url` itself, the URL registry, the linker and the importer are unchanged.

## 2. Pipeline rerun, from the merged tree

| Tool | Result |
| --- | --- |
| `inventory.py` | 1,244 files; URLs in v3 165 → 187 (22 more historical URLs recorded by agents); no file hash changed; 18 files changed inventory class |
| `import_existing.py` | 1,055 old-study rows (same 652 + 403), 1,018 itemdb, 75 GameData reference rows; **two files change** (below); rerun identical |
| `link_sources.py` | 259 files in scope (was 265): linked 136, exception 44, residue 41, disposed 38; 45 queue sources (was 46) |
| `extract_batch.py write --check` | exit 0 |
| `dispositions.py` | 1,244 files; 132 exceptions (was 134); 46 scope-gap sources (was 47); `--check` identical |
| `validate.py` | 5,789 records (5,632 effective), 5 errors (unchanged), 259 warnings (was 175: `ID_REUSED_ACROSS_FILES` 120 → 204, S18) |
| `build_estimates.py` twice | 5,632 records, 1,133 estimates, 451 unplaced; `estimates.json` `1089e517…`, `summary.md` `d2b1a1bb…`, `unused.json` `df921753…` both times |
| `audit_studies.py` | 595 studies, 70 clean (was 475 / 40) |
| `report.py` | 61 band moves; 175 open register rows |

### What the importer changed (PLAN section 3 rule 5, the holdings rule)

- **`import-v2report-00016` is gone.** It was Reddit zzyjzu's 28,000-ore R3 Serevite study; the dragonflight agent has since recorded that
  thread (`…T1928-diamond-and-hochenblume-comment-cohorts` and `…T2027-magma-thresher-prospecting-cohorts`), so the importer no longer writes
  it. No correction or flag names this ID. Every other `import-*` ID is unchanged (all 652 pinned study IDs, all 51 other M03b IDs).
- **Two name-only rows are no longer placed by name** (`import-study-00964` Eternity Amber, `-00965` Nozdorite): agents now hold their cohort, so
  rule 4 leaves them unplaced with the reason in `notes`. Three more rows (`import-study-00715` to `-00717`) only had their notes reworded.
- Moved estimates: **none.** Estimates built from the merge commit and from the working tree are identical (0 added, 0 removed, 0 changed).
- Corrections: 683 lines (643 + 40, all `exclude`), 397 distinct record IDs (357 before), and every line names an existing record.
  The 40 new lines are the reviewer's: 14 rows of a fourth recording of Reddit 108782r and 26 rows of an old Tontons copy with Platinum and
  Storm Silver swapped. None of the five M07-proposed corrections was written.

## 3. Estimates: 1,205 → 1,133

`M10-estimates-diff.md`: 12 added, 84 removed, 138 changed (of the 1,121 that remain). Largest chance move 0.3312 (Mill 52984 → 61980, a starting
guess replaced by a 496-cast measurement).

- **The 84 removed are re-keying, not lost data.** All 84 are `family:` Prospect groups (Tontons' ores, Pandaria ore, three Elethium /
  Laestrite / Solenium families). Their 150 rows still exist and now sit in item-ID groups: the agents' new records pair each name with its
  item ID, so `name_maps()` resolves the name-only rows (the reviewer's log says the same). Study casts follow the rows.
- **The 12 added** are 8 Prospect and 4 Disenchant estimates from new agent evidence, all with an estimated chance.
- **The 138 changed:** study casts up in 105, down in 27, same in 6; 23 went from no casts to measured; chance source `starting guess` →
  `estimated` in 22 and → `measured` in 1; confidence up in 40 and down in 8. Prospect 117, Mill 21.
- Measured-chance estimates 101 → 103; study casts total 1,448,702 → 1,525,002 (the audit's own total).
- **Bands** (no SciPy): 90%+ 49 → 49, 50-74% 370 → 355, under 50% 761 → 704, conditional 25 → 25. 61 estimates now differ in band from
  the snapshot (32 up, 29 down): 27 moved at this merge, 25 by units (M06), 9 by identity (M05).

## 4. Identity (`M10-identity-data.json` against M06's)

Groups where numbers differ inside one merged identity: **0 → 10, all one study pair.** The ten are the `family:` groups of Prospect 194545 (Prismatic
Ore) and both studies are Superbondez's 400-ore cohort (80 casts), recorded twice by the dragonflight agent (`dragonflight-20261031-50026` and
`-20261101-021`, S17). They are not independent cohorts: every numeric row of each has a row in the other with the same numbers, the second
copy only adds two labelled rows with no numbers, and the estimator gives them one canonical vector, so the study counts once (80 casts). The
report flags them because it compares a family group row by row and a family group holds one row per input rank per study (M08 section 6.1),
so it pairs rows of different ranks. `test_m10_merge.py` pins this: another differing group fails the test.

Other lists, all from agent evidence: partial copies 24 → 39, misplaced copy rows 81 → 159, near copies 24 → 25, small subsets 11 → 21,
studies no longer merged 25 → 40, cross-source matches 10 → 10, merges with conflicts 3 → 3, pooled studies 1 → 1. Dropped material casts in
differing groups: 0 → 1,600 (the pair above counted twice over ten groups, not real).

## 5. Dispositions and the queue

18 files changed final disposition: held-sources-only → no-observational-content 7, held-sources-only → reference-only 3, exception-queued →
extracted-null 1, extracted-null → linked 1, imported → held-sources-only 1, process-artifact → linked 1, process-artifact →
no-observational-content 3, reference-only → no-observational-content 1. Two held-source exceptions left (`wowhead:item=46849` in two legacy
reports: an agent now holds the page). Stormvine (`wowhead:item=52984@cata`, one of the 46 null sources) is now held by
`stormvine-wotlk-milling-cohorts`, so its files link to the agent's rows. Final counts: no-observational-content 443, process-artifact 309,
held-sources-only 120, linked 133, exception-queued 64, imported 54, extracted-null 47, reference-only 34, source-links-only 10, derived-model 22,
extracted 4, mechanics-knowledge 4.

Record usage: used 2,597 → 2,695, unused 2,348 → 2,937. Largest changes: `duplicateStudy` 148 → 363 (agents re-record historical studies, S17),
`type:noDisenchant` 124 → 228, `copy:vaguerGroup` 81 → 159, `totalWithoutCasts` 320 → 376, `type:exchange` 315 → 350, `type:token` 244 → 271.

## 6. Tests

390 → 402: 12 new tests in `test_m10_merge.py` (the page rule, the Tontons numbers, the identity pair). Tests that pinned a corpus number the merge moved were updated, each with its reason in a comment: `test_dispositions` (residue 42 → 41,
linker exception files 65 → 64, held-number groups 83 → 81, null source Stormvine now held, corrections file is no longer 643 lines),
`test_link_sources` (in-scope files 265 → 259, name-only candidates 86 → 88), `test_m03b_import` (`import-v2report-00016` dropped by the
holdings rule, `reddit:zzyjzu` held), `test_m08_estimator` (`percent:perInput` maps to `percentNotPerCast`; 23 agent rows use it).
Each still asserts its property with the new measured value. Two changed shape rather than number: the corrections test now checks that none of the five
M07-proposed corrections is in the file (it counted lines before), and the null-source test names the one source an agent now holds and checks the other 45.

## Known gaps, stated

- The exception queue still reads M05's frozen identity lists (9 cross-source pairs, 3 merges, 12 single-row subsets). The current identity
  report has 10 / 3 / 21; the extra subsets and pairs are in `M10-identity-data.json` only. This gap predates M10 (M06 already had 10 and 11).
- `output/` was not committed from this branch; the merge carries the reviewer's `output/` files unchanged.
- The pull request is not open: see the end of the session report.

## For the Master (proposals only)

1. **Wowhead page rule (S7).** The merge kept the reviewer's rule that `/ptr/` and language prefixes are the same page and applied it in the
   estimator's identity key only. If you want the same rule everywhere (URL registry, linker, importer holdings), it belongs in
   `source_keys.normalize_url`; that changes the manifests, so it was not done here.
2. **Exception queue and the current identity lists.** Regenerate `dispositions.py` from `M10-identity-data.json` instead of M05's frozen file, so
   the queue shows the 10 pairs and 21 subsets that agent evidence added. The tool change is small; the queue grows by about 10 rows.
3. **Identity report on family groups.** Compare per input rank, not row by row, so the Superbondez pair reads as identical and the
   `stillDiffering` list means what it says (ties to M08-estimator/master#4).
4. **S18, reused record IDs.** The validator now counts 204 reused IDs across files (120 at M09). The reviewer proposes
   `<agent>-<YYYYMMDD>T<HHMM>-<n>`; it is in the `evidence-format.md` proposal.
5. **S19, Serevite rank IDs.** If the reviewer's two item databases are right, 190394 and 190396 are swapped across the database, which would
   change every Serevite rank estimate and the R3 Serevite labels in the M05 items. Nothing was changed; wait for the reviewer's ID table.
6. **S17 is still open.** `duplicateStudy` records went 148 → 363 since M08 because agents keep re-recording stored studies; the
   `roles/worker.md` line is not applied.
