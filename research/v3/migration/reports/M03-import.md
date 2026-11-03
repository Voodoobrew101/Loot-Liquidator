# M03.0, M03.1, M03.5: deterministic re-import

Session MIG-003, 2026-10-31. All numbers come from running the code on the migration branch.
Machine-readable lists (every skipped record, every name-only row, every GameData comparison): `M03-import-data.json`
(written by `python3 research/v3/tools/import_existing.py --report …`). Estimates diff: `M03-estimates-diff.md`.
Identity lists: `M03-identity-data.json`. Confidence values were computed with SciPy installed (MIG-002 had none),
and the before and after runs used the same code path.

## Summary

| Measure | Before (HEAD `5d99342`) | After |
| --- | --- | --- |
| Evidence records (effective) | 4,404 | 4,882 |
| Estimates | 1,203 | 1,205 (2 added, 0 removed, 67 changed; largest chance move 0.0053) |
| Unplaced drop records | 35 | 433 (+397 stored but deliberately unplaced, +1 typeless deck row) |
| Validator errors / warnings | 15 / 693 | **5 / 175** |
| `TYPE_MISSING` | 10 | **0** |
| `DATE_NOT_ISO` | 518 | **0** |
| Correction lines matching a record / corrected records | 643 / 333 | 643 / 333 (45 import-study, 52 import-ref): unchanged |
| Identity: groups dropping differing numbers | 0 | **0** |
| Migration tests | 67 | 99 (67 unchanged + 32 new) |

## M03.0: the ten typeless records

`evidence/midnight/2026-10-31-midnight-refining-shattering-decks.jsonl` is untouched. The importer writes
`evidence/imported/typeless-agent-records.jsonl`. Each row `replaces` its original, so the estimator and validator
see only the mapped row. Agent `sourceKind` gave the type (`exchange`, or `study` = drop), `sourceURL/sourceName/
sourceAuthor` became `source`, and the agent's `date` became `source.published`. Every number was checked against the
agent record by `test_typeless_numbers_match_agent_records`.

| Original | Mapped | Content | Placed in estimates |
| --- | --- | --- | --- |
| 9901 | import-typeless-00001, exchange | 18 Dusk-Shrouded Stone R1 → 1 R2 (WoWDB) | no, exchanges are not estimate input. Same numbers as `midnight-20261031-9702` (Wowhead) and recipe `master-20261030-008` |
| 9902 | import-typeless-00002, exchange | 10 Crystalline Glass R1 → 1 R2 (WoWDB) | no. Same as `midnight-20261031-9701` and `master-20261030-007` |
| 9903 | import-typeless-00003, exchange | 1 Dawn Crystal → 3 Radiant Shard | no (new to v3) |
| 9904 | import-typeless-00004, exchange | 1 Radiant Shard → 3 Eversinging Dust | no (new to v3) |
| 9905–9908 | import-typeless-00005..8, exchange | 8 cards (Ace–Eight of one suit) → Darkmoon Deck: Blood / Hunt / Rot / Void | no. `giveItemID` null: a set of 8 different cards |
| 9909 | import-typeless-00009, drop | genobeam: Prospect Dazzling Thorium (237366), Eversong Diamond, 200 casts, 20% per craft | yes, but Eversong Diamond is conditional and unlock state is unstated, so it is skipped like 59 others (S6) |
| 9910 | import-typeless-00010, drop | vinnyi82: 1 Darkmoon Deck disenchanted → 1 Dawn Crystal | **no**: input cannot be established (suit unspecified, no item ID). `inputName` null, the agent's label kept in `rawInputName`. The agent's notes forbid generalizing it |

Notes for the Master: 9909 keeps the agent's `inputItemID` 237366 even though the source states no ore quality
(S13 would leave a ranked ID null). It does not change any estimate (unlock-unstated). The agent's
`percentMeaning` text "per prospecting craft (author clarified)" was mapped to `perCast` and the text kept in notes.
`rawInputName` is a new optional field (added to `SCHEMA-EXTENSION.md`).

## M03.1: the re-import

### IDs

`import-study-00001..00652` are unchanged in every pre-existing field and in `notes`. This is pinned by
`tests/fixtures/pre-m03-study-ids.jsonl` and `test_existing_ids_stable`. The old row order, dedupe and renumbering
code path is kept as it was, and new rows are numbered 00653..01055 after it. `cohortKey` is never set.

### Cast basis (a)

| `castsBasis` | Kept rows (652) | Effective after corrections (620) | All 1,055 rows |
| --- | --- | --- | --- |
| reported (`completedOperations`) | 317 | 310 | 370 |
| nominalEquivalent | 283 (207 `fiveOreEquivalentOperations`, 54 `nominalFiveOreEquivalents`, 22 `fiveHerbEquivalentOperations`) | **258** | 574 |
| countedFromInputs (27 `reportedInputsConsumed`, 6 `sourceInputQuantity`) | 33 | **33** | 79 |
| null (no casts) | 19 | 19 | 32 |

The plan's 258 and 33 are the effective counts. Every computed basis has a `derivations` entry for `casts`. The
casts values themselves are unchanged: weighting by basis is M06. The one percentage converted from a 0–1 fraction,
and GameData disenchant's `castsWithDrop`/`totalQuantity` (chance or mean × samples), also carry derivations.

### Raw inputs (b)

Copied by the old field's name, never computed. Kept rows: `inputsProcessed` 533, `inputsPurchased` 19, `inputsRefunded` 41.

- processed: `reportedInputsConsumed`, `sourceInputQuantity`, `rawReportedOre`, `reportedOreInput`, `reportedOre`, `reportedOreCount`, `reportedInputQuantity`, `reportedGrossOre`
- purchased: `reportedInitialOre`, `reportedOrePurchasedOrProcessed` (ambiguous name, so it is not used as processed), `reportedInitialHerbs`
- refunded: `resourcefulnessOreSaved`, `oreSaved`, `originalUnmappedExtra.oreSaved`
- not read (derived in the old data): `derivedInputsConsumedIfNoRefunds`, `nominalInputsRequired`

### Dates (c)

| Kept rows | Before | After |
| --- | --- | --- |
| `dataDate` ISO | 30 | 30 |
| `dataDate` free text | 550 (518 effective) | **0**, moved to `dataDateText` |
| `source.published` | 78 (all were `reportedObservationDate`) | 58: real post dates from the old `publishedDate` / `commentPublicationDate` |
| `observedOn` | — | 78 |

Prose that merely starts with a date ("2020-12-04 Shadowlands") is text, not ISO. Estimator change required by the
new field: `study_date()` reads `dataDate`, then `observedOn`, then `source.published`, and a row with `observedOn`
is no longer "dated by post date only". Result: **no estimate's epoch weight or basis text changed**.

### Provenance (d)

`migratedFrom {path, sha256, recordRef}` is on every row the importer writes, in all seven files: old studies (file
line, plus the old field for name-only rows), itemdb rows, GameData rows (line and table key), and the typeless rows.

### Unmapped outputs (e)

403 name-only rows (`outputItemID` null, `rawOutputName` = the source's label), from `unmappedReportedOutputs`,
`originalNamedGemTotalsRank2Rank3`, `rawNamedCounts` (names whose total equals an unused mapped output are the same
output and are skipped) and `originalUnmappedExtra`. **A name-only row is placed (`outputName` set) only when** it
names one material and no v3 agent record already holds the cohort, either by citing the same source URL or by an agent
row with the same input, casts, output name and total. Otherwise it is stored with `outputName` null and the reason in
`notes`. This rule exists because a first pass placed by name and double-counted (below).

| Outcome | Rows | Sources |
| --- | --- | --- |
| placed | 6 | Kyzenbka four Midnight pigment totals (2 with casts), Laving's Eternity Amber and Nozdorite |
| agent evidence cites the URL | 83 | Reddit zez5sj (15), zkay8v (45), Jallfo 2022 beta sheet (12), Almar (11) |
| agent row with the same numbers | 3 | Kyparite Sparkling Shard ×3 (legacy agent re-recorded them under `item=72093` without `mop-classic`) |
| category, aggregate or unnamed index | 311 | Jallfo labels like "MYSTIC SAPPHIRE quality 1" (210), Xenastro "green gems Q2" (44), Felslate worksheet categories and index-only comments, "rare gems", "epic diamonds" |

**Problem found and fixed:** the first run placed the Sparkling Shard rows. `family:Sparkling Shard` for Kyparite went
from 438 to 876 study casts, the same three cohorts counted twice, because the agents' URL normalizes differently.
The numeric copy check was added. A first draft would also have placed 222 Jallfo rows under raw labels; the agents
recorded that sheet with `casts: null`, so placing them would have added 6,000 nominal casts of data the agents chose
not to count.

The 14 duplicates and 22 model/TSM rows stay skipped, each listed with its reason in `M03-import-data.json`
(`oldStudies.skipped`). The kept copy is the later file, as before. One more duplicate is new: the name-only
50,000-ore zkay8v record exists in both `…serevite-2022-SCHEMA-CORRECTED` and `…source-only`, so the later one is kept.
One record has no outputs at all (`…batch006-historical-cohorts` line 6) and is listed. 43 records in three of the 56
JSONL files use other schemas (`legacy-milling-batch01` 30, `warwithin-batch014-q16-recipe-metadata` 8,
`dragonflight-batch012-source-cohort-reconciliation` 5) and are listed for the M03.2–M03.4 adapters.

## M03.5: GameData tables vs itemdb.lua

| Table | Rows | Present in itemdb | Present, numbers differ | Missing → imported |
| --- | --- | --- | --- | --- |
| `gd.tsmRetail` (prospect 42 inputs, mill 98) | 903 | 903 | 120 (itemdb chance null where TSM has `matRate`: itemdb marked it unknown) | 0 |
| `gd.mill` (122 entries) + `gd.prospect` (57) | 98 material rows in 30 entries (149 entries have empty literal `materials`) | 23 (13 TWW compiled rows equal; 9 BfA jiyao rows: GameData per-5 means vs itemdb per mass-mill, listed; 1 equal to its TSM row) | 9 | **75** |

The 75 rows are written to `evidence/imported/gamedata-mill-prospect-reference.jsonl` as `sourceKind: reference`
(starting guesses, never study casts: `test_gamedata_rows_are_reference`). They come from 35 `mean`/reported-batch-means,
33 `candidates`/documented-candidate and 7 `mean`/published-measured-ore-batch rows, each with only a TSM row for the
same pair in itemdb. Only the average per cast is carried. GameData's chance for these rows is a Poisson/proxy
model ("NOT MEASURED"; every `candidates` row has the same 0.5654), so it stays in notes. `GameData.lua` is not edited.
The runtime-built profiles (`gd.midnightProspectingProfiles`, `gd.dragonflightProspectingProfiles`) are separate
tables, outside the three named here.

## Estimates diff (`M03-estimates-diff.md`)

- **+2 rows:** Mill 236761 → `family:Powder Pigment` and 236770 → `family:Sanguithorn Pigment` (Kyzenbka, 100 casts
  each counted from 1,000 herbs; 13.05 and 12.86 pigment per 10-herb mill). This supports S14: the 4.5 starting guess is
  about a third of the observed figure. The Mana Lily and Argentleaf totals state no casts, so they stay unused (S16/M06).
- **Prospect 192880 → 192880: 745 → 685 study casts, 3 → 2 studies.** Laving's corrected copy
  (`…QUALITY-UNMAPPED-CORRECTED`) gained its two named rows and is now recognized as a relabeled copy of the original.
  Before, it was a single-row subset and the same 60 casts counted twice (M05 listed it for review).
- **63 average and 45 chance changes, all ≤ 0.0053:** the 75 GameData reference rows join the starting guess (prior
  weight 20) of Shadowlands and BfA mill/prospect groups that already had studies.
- No change from dates, cast basis or provenance.

## Identity comparison (`M03-identity-data.json` vs `M05-identity-data.json`)

| Measure | M05 | M03 | Why |
| --- | --- | --- | --- |
| Differing groups (dropped numbers) | 0 | **0** | |
| Merging groups / identical | 127 / 124 | 128 / 125 | Laving 192880 group now merges (the fix above) |
| Partial copies | 23 | 24 | +1 Laving. Three pairs swapped copy/original direction because the smaller study gained name-only rows and both are now the same size (`relabeled`): zkay8v 1,000-cast pair, Deckven/Felslate 3,200, Almar Titanium. Each still counts once (no studies change in the diff) |
| Small subsets | 12 | 11 | Laving moved to partial copies |
| Near copies (listed, not merged) | 8 | 23 | +14 Jallfo cohort pairs and +1 Felslate worksheet pair. These studies now exist as stored, unplaced name-only rows, so no estimate is affected |
| Cross-source matches | 9 | 10 | +1 Felslate 113 mass comment on `spell=225904` vs `@de`, all rows unplaced |
| Misplaced copy rows | 79 | 81 | +2: Laving's named rows leave the vaguer family group, where the ID rows already count |
| Pooled studies / merged with conflicts | 1 / 3 | 1 / 3 | |

## Study audit

454 studies (426 + 28 new name-only or typeless studies). 34 → **40** clean after `audit_studies.py` also accepted
`observedOn` as a date (one-line change, same reason as the estimator). 140 were clean before: 98 imported studies
lost "clean" only to `EPOCH_UNKNOWN`, because the prose they had in `dataDate` was never a date (the estimator already
treated them as undated). The rest are the expected `OUTPUT_ID_MISSING` / `UNPLACED` for stored name-only rows.

## For the Master (proposals only)

1. Confirm the name-only placement rule (single material, no agent copy by URL or numbers). The 92 rows not placed
   because agents hold the cohort are link candidates for M04.1.
2. S14: Kyzenbka's two pigment cohorts and Draggoth both say about 12.5–13 per 10-herb mill.
3. 9909's ranked input ID (S13), and the Dusk-Shrouded Stone and Crystalline Glass refine recipes, are recorded three
   times each (two exchanges and one recipe).
