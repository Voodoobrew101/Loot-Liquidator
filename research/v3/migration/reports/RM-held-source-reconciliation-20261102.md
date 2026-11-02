# Research Manager — held-source decision reconciliation (2026-11-02)

Scope: research-only M03b importer/test correction on the existing draft PR #23 branch. No original evidence, worker files, runtime ItemDB, main, immutable `4df9ae8` import pin, or other PR branch was modified.

## Exact source check

The current v3 source `research/v3/evidence/midnight/2026-11-01T1910-prospecting-approx-rates-and-thorium-200crafts.jsonl` already holds **17 rows** attributed to Reddit thread `1smgllg`: 15 approximate per-prospect output percentages across copper/tin/silver families and two pooled stone/glass averages. All 17 have `sourceKind=reference`, `casts=null` and `castsWithDrop=null`. Source [Prospecting Calculator discussion](https://www.reddit.com/r/woweconomy/comments/1smgllg/prospecting_calculator/). The original commenter reports fewer than 5,000 ore across all ores, not a per-family observed denominator. This does **not** support inventing hit counts or treating each approximation as a measured study.

The older `import_existing.py` M03b mapper for `1smgllg` still exists for historical unit fixtures, but its `NEW_SOURCES` decision was dead: the Holdings index already identifies that thread as held. Its 14 mapped v2 shorthand rows, if allowed to import alongside the 17 v3 reference rows, would duplicate a single source and label the shorthand `sourceKind=study`. The decision was retired; the mapper and original v2 file were not deleted.

Two other `NEW_SOURCES` entries were already held: `reddit:1fvhzy0` (pigment multipliers without a base output-per-mill) and `reddit:y3e8ek` (qualitative Dragonflight beta discussion). They were skip decisions, not measured conversions; retiring them does not discard an importable numerical cohort. The existing M03b held-source test independently detected all three stale entries before this change.

## Changes and regression

- `research/v3/tools/import_existing.py`: retire only those three held-source registry decisions; document the reason. Preserve `map_1smgllg` and the TBC row-checked exception.
- `research/v3/migration/tests/test_m03b_import.py`: verify all three are held and no longer registered, plus source-kind and unknown-denominator assertions for two exact v3 reference rows. Existing `test_no_decision_for_a_held_source` remains unchanged.
- Source read-back: Midnight `midnight-20261101-19001` is copper/Amani Lapis approximate 10% per prospect; `midnight-20261101-19017` is pooled Crystalline Glass average 0.75 per prospect. Neither has observed casts/hits. No probabilities, yields, ranks, confidence or gold values were recalculated.

## Validation and remaining gates

At time of writing, commits `ab26f6e7` and `aa0cebb2` were pushed/read back. GitHub CI was triggered for `aa0cebb2`; final result must be checked at its exact head. The parent PR #23's earlier migration run [41441958144](https://github.com/Voodoobrew101/Loot-Liquidator/actions/runs/41441958144) had **6/410 failures**: stale dispositions, links, old-studies, v2 import artifacts, M09 report and the held-source assertion. This change targets only the last category; do not claim the other five resolved.

Next: after the exact-head test, inspect current research head and regenerate the remaining derived migration artifacts under the existing guarded reconciliation helper on an isolated checkout, verify the original cohort and source-basis decisions, then rerun full migration and five-agent CI. Do not overwrite workers, silently promote post-pin evidence, or bypass byte-identity tests. PR Director alone merges/closes.
