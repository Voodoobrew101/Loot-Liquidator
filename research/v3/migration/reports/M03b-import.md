# M03.2, M03.3, M03.4, M03.6: remaining structured sources

Session MIG-004, 2026-10-31. All numbers come from running the code on the migration branch, with SciPy installed
(as in MIG-003, so the before/after hashes compare). Machine-readable account of every file, claim, decision and
comparison: `M03b-import-data.json` (`python3 research/v3/tools/import_existing.py --report …`, key `historical`).
Estimates diff: `M03b-estimates-diff.md`. Identity lists: `M03b-identity-data.json`.

## Summary

| Measure | Before (HEAD `c868709`) | After |
| --- | --- | --- |
| Evidence records (effective) | 4,882 | 4,933 (+51 imported rows) |
| Estimates | 1,205 | 1,205 (0 added, 0 removed, 36 changed; largest chance move 0.0150) |
| Study casts of any estimate | — | **unchanged in every row** |
| Unplaced drop records | 433 | 447 (+14 stored, deliberately unplaced) |
| Validator errors / warnings | 5 / 175 | 5 / 175 |
| Corrections matching a record / corrected records | 643 / 333 (45 import-study, 52 import-ref) | 643 / 333 (45 / 52): unchanged |
| Identity: groups dropping differing numbers | 0 | **0** |
| Study audit | 454 studies, 40 clean | 473 studies, 40 clean |
| Migration tests | 99 | 125 (99 unchanged + 26 new) |
| Estimates sha256 (SciPy) | `1081c316…` | `3861b696…` (`summary.md` `0ed83dd3…`) |

**Result in one line:** the 11 archives, 38 v2 reports, the lead, 38 submissions, 43 other-schema records and 8 ledgers
hold 700 source citations ("claims"). Almost all of them repeat cohorts v3 already holds, are reference or identity
links, or carry no cohort numbers. 51 rows from 5 sources are new to v3 and are imported. None of them adds study
casts today. Their totals wait for M06, like the agents' "ore, not casts" rows (S16).

## Scope (from `manifest/inventory.jsonl`)

| Family (adapter) | Files | Selection | Output file | Rows |
| --- | --- | --- | --- | --- |
| M03.2 observation `.json` archives | 11 | `research/evidence/observations/*.json` | `historical-archive-cohorts.jsonl` | 8 |
| M03.3 `evidence/v2` reports | 38 | `research/evidence/v2/*.json` (the 37 files under `v2/source-reviews/` are a separate category, `v2-source-review`, with no study objects except one covered-by-url review, left for M04/M07) | `v2-report-cohorts.jsonl` | 16 |
| M03.3 leads | 1 | `research/evidence/leads/*.json` | none (0 rows) | 0 |
| M03.4 worker submissions | 38 | worker/v2 submission JSON/JSONL with study objects or a candidate/covered-by-url disposition | none (0 rows) | 0 |
| Other-schema JSONL left by M03.1 (43 records) | 3 | `oldStudies.otherSchema` in `M03-import-data.json` | `legacy-milling-cohorts.jsonl` | 27 |
| M03.6 ledger CSVs with numbers | 8 | `category: ledger`, CSV, `numericClaimLines > 0` (the 5 `candidate-no-url` plus 3 with URLs) | none | 0 |

A family whose claims are all skipped writes no file; the report lists it. The 21 worker-submission audit CSVs
(field scores) are not ledgers and not in M03.6; they stay for M07 dispositions.

## Method

These files are research notes, not one schema. Each adapter reads one family. Inside it, any object that cites a
source URL in a field of its own (`url`, `sourceURL`, `originalPost`, `additionalCoverage`, …) is a **claim**. When
the URL sits in a nested `source` object, the parent object is the claim. Each claim is classified deterministically:

1. **Held:** v3 already cites the source, through agent evidence outside `evidence/imported/` or rows this same run
   wrote (old studies, typeless, itemdb, GameData). Forum post numbers, reddit comment IDs and Wowhead comment anchors
   are matched by thread. The claim's telling numbers are compared with the held rows' counts, totals and averages,
   and the matches are listed. **A held claim is never imported.** The importer's own MIG-004 output is never read
   as a holding, so a rerun sees the same holdings.
2. **New source, decided:** `NEW_SOURCES` in `import_existing.py` has one entry for each of the 36 sources v3 does not
   hold, other than reference hosts. Five say "import" and have a mapper that copies the file's own numbers. 31 say
   "skip" and give the reason. A mapper stops importing as soon as v3 holds its source, so an M10 rerun after agents
   record it cannot double count. The TBC table is the exception: it checks presence row by row. Tests fail if an
   in-scope file cites a new source without an entry, if an entry is no longer cited, or if an entry covers a held
   source.
3. **Reference or identity link:** wiki, price, patch-note, news, catalog and recipe pages (`REFERENCE_HOSTS`), and
   Wowhead entity pages cited for an item, spell or trait.
4. No URL at all: the file-level reason (hypothesis card, field audit, validation, run summary, protocol).

Across the four claim families: 700 claims; 375 held (173 with matching numbers), 274 reference links, 44 new sources
skipped with a reason, 7 imported (4 sources; the TBC table counts once per file, the fifth source is the legacy
milling file, assessed by its own adapter).

**The guard caught one error in this session's first pass.** noriiju's 40-prospect copper post (Blizzard forum
2280780) had been mapped as new because a lookup used the raw URL rather than its normalized key. The midnight agent
already holds it (`us-wowforum-noriiju-20260326-copper-40prospects`; 8 and 40 match). The row was stored and unplaced,
so no estimate saw it, and it is now skipped as held.

## Imported rows (51)

| Rows | Output file | Source (file) | What | Placement |
| --- | --- | --- | --- | --- |
| 8 | archive | wow-professions TBC prospecting table (`…0535-legacy-batch005-tbc-guide-source-only.json`) | published chances, `sourceKind: reference`, percent ×100 with derivation | reference prior only; 32 of the 40 records are already in v3 (below) |
| 1 | v2 | reddit zzyjzu, Jan 2 2023 (`…2334Z-…-crosspost.json`) | ~28,000 R3 Serevite (190394), 24 R3 Illimited Diamonds (192871), skill 274 | placed, but `casts: null`: the ore count is approximate; `inputsProcessed` 28000 (S16/M06) |
| 1 | v2 | reddit 1fb0vv5 (`…1626Z-…-luredrop-per-operation-range.json`) | Luredrop milling: 11 to 17 pigment from each milling | names only; no chance or average, so no estimate row (only a range) |
| 14 | v2 | reddit 1smgllg (`…0228Z-…-post-hotfix-prospecting-rate-context.json`) | one commenter's approximate per-prospect rates (percent ×100 with derivation) and two co-output averages | **unplaced**: ore families ("Copper") and short gem names ("Lapis") kept raw; studyKeys numbered by claim (`claim1..4`) so equal rounded rates for Tin and Silver read as a batch family, not a copy |
| 27 | legacy milling | `2026-10-28-legacy-milling-batch01.jsonl` | Wowhead comments: 516803 (6 WoD herbs × 2,000, Cerulean Pigment), Kidneph (6 BfA herbs × 1,000, 3 pigments), Melch1337 (Widowbloom, pigment per 100 herbs) | placed, but `casts: null` (see below); Melch1337 `averageShown` per input with derivation and `inputsPerCast` null |

**Legacy milling, why no casts.** The source mills in 20-herb mass-mill casts. The estimate groups for these BfA and
SL items already mix Jiyao's per-20-herb mass-mill means with Baadkitty's five-herb equivalents. A first pass counted
Kidneph as 1,000/5 = 200 five-herb casts (the old record's own normalization) and moved 15 BfA chances by up to 0.335
and averages by a third. Counting 1,000/20 = 50 mass-mill casts would instead have put the WoD groups four times above
their per-five-herb reference values. Either choice sets the unit before M06 does. So the rows keep the raw facts
(`inputsProcessed`, `inputsPerCast` 20, `totalQuantity`) and leave `casts` null, as agents record "herbs, not casts".
The old record's derived per-five-herb figures are not copied.

Every imported row has `migratedFrom {path, sha256, recordRef}` (JSON path plus the source's own record ID),
`recordedOn` 2026-10-31, ISO dates only, no `cohortKey`, and a `derivations` entry for each computed value: 20 percent
conversions (8 TBC, 12 calculator-thread rates) and 3 per-100-herb conversions. IDs use new prefixes (`import-archive-`, `import-v2report-`,
`import-legmill-`) in file and record order, pinned by `tests/fixtures/m03b-ids.jsonl`. Existing `import-*` IDs are
untouched.

## Skipped, by family

**M03.2 archives (11 files, 22 claims, 1 file imported).** Held: Reddit 1f83cnd and 1g350pq Aqirite (war-within
agent and old studies), Felslate 2016 51ovfk (old studies, 560 matches), Neoslayyer's four Illimited Diamond cohorts
(dragonflight agent), Bugy's Draconium and Khaz'gorite tables on spell 374627 (dragonflight agent, averages per ore
match), Honeybone 616811 (old studies and midnight agent), the April 8 Thorium 200-craft claim (old studies and the
typeless import), Jacara 2284616, noriiju 2280780 and 10h6ccx (agents). New, skipped: 1fdvkmy (proposed 30% Resourcefulness return),
1g8kbaq (queue mechanics), the Jallfo beta article (the sheet's cohorts are held).

**M03.3 v2 reports (38 files, 176 claims, 3 files imported) and the lead.** The F004 reports reconcile cohorts that v3
holds (Bugy, Neoslayyer, JD3K, Cardinalai, zkay8v, 108782r, 10i63zb, 109bytz, Draggoth and others). Their 28 new sources
are qualitative: UI and selector reports, Resourcefulness explanations, multipliers without a base, failure reports,
ranges of mixed-rank runs, hotfix context. The lead is Bugy's same 2,000-ore table on the item page (3 and 8
diamonds), held by the dragonflight agent under spell 374627, so it is an S17 copy.

**M03.4 submissions (38 files, 501 claims, none imported).** 19 are mechanics hypothesis cards (status BLOCKED,
reference/target contexts restating held cohorts). 15 are field audits, validations or confidence charts (scores and
derived values). One is the run summary of a v2 report. The other 3 (beta source-only, study synthesis, Silver
800-cast) cite only held cohorts. 12 new sources, all qualitative or mechanics.

**Other-schema JSONL (43 records).**
- `legacy-milling-batch01` (30): 27 imported. 3 skipped as copies: Baadkitty Anchor Weed 157/71/64 = `midnight-b010-bfa-baadkitty-152510-200herbs`.
- `warwithin-batch014-q16-recipe-metadata` (8): all 8 smelting recipes are already in v3 (`import-recipe-00001..00008`; 4 also as legacy agent recipes). Skipped.
- `dragonflight-batch012-source-cohort-reconciliation` (5): all marked `REUSED_*` by the agent; each matches held rows (zkay8v 1000/1427, 108782r 8000/11472, 10me1e7 1418/6050, Aary Saxifrage 16/64, the beta derivative 3.5). Skipped.

**TBC guide, the 32 rows not imported.** 20 Fel Iron and Adamantite rows are already recorded from the same URL by the
legacy agent (rare gems by name), 5 Thorium rows are in old studies from the same URL, and 7 copper/tin/iron rows equal
their TSM row. The 8 imported rows differ from TSM (3.33% vs 3.25%, 35% vs 34/36/38%). This is M03.5's rule.

## M03.6 ledger CSVs

| Ledger | Rows | Outcome |
| --- | --- | --- |
| `first-pass-coverage-2026-10-28.csv` | 1,737 | process: coverage status per key; its numbers are file/line references |
| `first-pass-coverage-v1.csv` | 1,171 | process: coverage scores per GameData/TSM key. The owner's personal-pooled sample counts it quotes (e.g. `samples=12`) are the GameData rows already imported as `personal-pooled` in `gamedata-disenchant.jsonl` (checked: all 52 disenchant keys it quotes match the imported group and sample count) |
| `master-worker-batch002/008/010-four-field-scores-2026-10-28.csv` | 90 / 115 / 50 | process: four-field confidence scores per stable key; scores and notes, no raw counts |
| `supplemental-output-fields.csv` | 255 | derived: TSM `Prospect.lua`, GameData personal pools and recipe links, the same rows imported from `GameData.lua` and `itemdb.lua` |
| `first-pass-tsm-other-28-field-evidence-2026-10-28.csv` | 28 | TSM field review; its 6 Legion worksheet rows restate the 3,200-ore Deckven Felslate cohort (e.g. 0.0265625 × 640 = 17 = `import-study-00378`) |
| `titanium-observed-yields.csv` | 12 | 6 rows = Strath's 5,000-ore WotLK PTR cohort (legacy agent, totals equal). **6 rows exception**: reddit s6bfrl uncommon gems (Bloodstone 53, Sun Crystal 44, Chalcedony 49, Shadow Crystal 53, Huge Citrine 47, Dark Jade 59 of 1,000 ore). The agent and old-studies copies of s6bfrl hold its powder and rare gems but not these. Not imported: their provenance can't be checked offline and the agents left them out; M04.1 source check |

None of the ledgers is imported. No owner personal ledger with raw counts exists among them: the personal data is
already the GameData personal-pooled rows.

## Estimates diff (`M03b-estimates-diff.md`)

36 rows changed, 0 added, 0 removed:
- **8 chance changes, all from the TBC reference rows** joining a starting guess that had only TSM values (tin 2771 ×3, iron 2772 ×3, mithril 3858 ×2). Largest 0.38 → 0.365. No average or study-cast change.
- **28 `studies` counts +1, with no change to casts, chance, average or confidence:** WoD 109124..109129 → Cerulean (6), BfA 152505..152511 → 3 pigments (18), Widowbloom → 3 pigments (3), R3 Serevite → R3 Illimited Diamond (1). These rows have `casts: null` and no per-cast average. The estimator already counts such rows as studies without casts, as it does for agent "ore, not casts" rows. This is unchanged behaviour.

### Double-counting check

No estimate row was added and no `studyCasts` value rose, so no row can double count today. Each new cohort was also
checked for agent copies, so M06 does not inherit a double count (the Sparkling Shard case):
- Kidneph, 516803, Melch1337: no v3 record mentions these authors; no v3 row has the same input, output and total. Baadkitty's three rows match and are skipped.
- zzyjzu 28,000 R3 Serevite / 24: no v3 row with these numbers. The thread's other comment (54,137 R2 Serevite, 38 + 23) is the agent-held reddit 108782r copy and is skipped.
- 1fb0vv5, 1smgllg: sources not cited anywhere in v3 (the mapper guard confirms it on every run); no matching numbers.
- TBC rows: reference only (`test_reference_rows_never_reach_study_counts`: 8 rows, 8 groups, never study rows).

## Identity comparison (`M03b-identity-data.json` vs `M03-identity-data.json`)

| Measure | M03 | M03b |
| --- | --- | --- |
| Differing groups (dropped numbers) | 0 | **0** |
| Merging groups / identical / partial | 128 / 125 / 3 | 128 / 125 / 3 |
| Partial copies | 24 | 24 |
| Near copies (listed, not merged) | 23 | 24: +1 `reddit-1smgllg-claim2` (Tin) / `claim3` (Silver), the same commenter's equal rounded rates (12.5%, 1%). Stored, unplaced, not merged |
| Pooled studies, small subsets, cross-source, misplaced rows, merged with conflicts | 1, 11, 10, 81, 3 | unchanged |

A first run named the 1smgllg studies by ore family. Identity then read Silver (2 rows) as a partial copy of Tin
(5 rows), taking partial copies to 25. Numbering the claims as one batch family removed it.

## Determinism

`import_existing.py` run twice: `evidence/imported/` identical (`diff -r`) and the report identical (`cmp`).
`build_estimates.py` run twice: `estimates.json` `3861b696…`, `summary.md` `edad025f…` both times.
`test_m03_import.Committed.test_rerun_byte_identical` now covers the three new files.

## For the Master (proposals only)

1. **M06 inherits 25 more totals-without-casts rows** (WoD/BfA mass milling, zzyjzu) and 3 per-herb rates. The BfA and SL milling groups already mix 20-herb mass-mill means (Jiyao, `inputsPerCast` 20) with five-herb equivalents (Baadkitty, 5) under one per-cast estimate. M06 should normalize per input before deciding cast weights.
2. **Felslate 2016 (51ovfk) after-hotfix total:** the archive lists ten batch totals that add up to 101 rare gems. Both v3 copies (`import-study-00967`, `-01041`) say 97. All three are unplaced category rows, so no estimate is affected. Worth one source check.
3. **s6bfrl uncommon gems** (6 rows above): check the post; if the numbers are there, they add a 1,000-ore Retail 2022 cohort to six uncommon-gem estimates.
4. The 1smgllg rates are stored, unplaced and waiting for M04.1 name linking.

## Per-file outcomes

### M03.2 observation .json archives (11 files)

| File | Claims | Rows | Outcome |
| --- | --- | --- | --- |
| `evidence/observations/2026-10-28-0418-warwithin-batch004-resourcefulness-source-only.json` | 3 | 0 | 2 held (2 with matching numbers); 1 new source skipped: reddit:1fdvkmy (a commenter's proposed 30% Resourcefulness return, no measured outputs) |
| `evidence/observations/2026-10-28-0516-warwithin-batch005-resourcefulness-queue-source-only.json` | 2 | 0 | 1 held (1 with matching numbers); 1 new source skipped: reddit:1g8kbaq (Prospect All queue behaviour (1,000-ore stack queues 200 casts)) |
| `evidence/observations/2026-10-28-0525-dragonflight-batch005-inspiration-removal-source-only.json` | 3 | 0 | 1 held (0 with matching numbers); 1 new source skipped: wowhead:news=dragonflight-jewelcrafting-analysis-wowhead-economy-weekly-wrap-up-249-329385 (Wowhead article on Jallfo's 2022 beta sheet); 1 reference/identity links |
| `evidence/observations/2026-10-28-0535-legacy-batch005-felslate-2016-source-only.json` | 1 | 0 | 1 held (1 with matching numbers) |
| `evidence/observations/2026-10-28-0535-legacy-batch005-tbc-guide-source-only.json` | 1 | 8 | **imported 8** |
| `evidence/observations/2026-10-28-0605-midnight-batch006-original-source-only.json` | 4 | 0 | 3 held (3 with matching numbers); 1 reference/identity links |
| `evidence/observations/2026-10-28-1205-midnight-batch005-dragonflight-independent-khazgorite-context-source-only.json` | 1 | 0 | 1 held (1 with matching numbers) |
| `evidence/observations/2026-10-28-1205-midnight-batch005-midnight-april08-informal-prepost-source-only.json` | 1 | 0 | 1 held (1 with matching numbers) |
| `evidence/observations/2026-10-28-draconium-bugy-2x2000ore-unassigned-quality.json` | 4 | 0 | 4 held (2 with matching numbers) |
| `evidence/observations/2026-10-28-midnight-worker004-khazgorite-bugy-source-only.json` | 1 | 0 | 1 held (1 with matching numbers) |
| `evidence/observations/2026-10-28-midnight-worker004-posthotfix-copper-source-only.json` | 1 | 0 | 1 held (1 with matching numbers) |

### M03.3 evidence/v2 reports (38 files)

| File | Claims | Rows | Outcome |
| --- | --- | --- | --- |
| `evidence/v2/2026-10-29T1228Z-F004-diamond-cast-capture-protocol.json` | 0 | 0 | cites no source URL |
| `evidence/v2/2026-10-29T1228Z-F004-diamond-rank-reconciliation.json` | 2 | 0 | 1 held (0 with matching numbers); 1 reference/identity links |
| `evidence/v2/2026-10-29T1328Z-F004-historical-diamond-comment-cohorts.json` | 2 | 0 | 2 held (2 with matching numbers) |
| `evidence/v2/2026-10-29T1433Z-F004-two-ore-diamond-original-comment.json` | 1 | 0 | 1 held (1 with matching numbers) |
| `evidence/v2/2026-10-29T1527Z-F004-tww-mycobloom-bulk-abort-denominator.json` | 2 | 0 | 2 new source skipped: blizzforum:1927887 (bulk-milling failure report); blizzforum:1944679 (bulk-milling failure report) |
| `evidence/v2/2026-10-29T1626Z-F004-crushing-unit-reconciliation.json` | 4 | 0 | 3 held (1 with matching numbers); 1 reference/identity links |
| `evidence/v2/2026-10-29T1730Z-F004-housing-dye-patch121.json` | 7 | 0 | 1 new source skipped: wowhead:news=i-bet-you-re-dyeing-to-hear-about-this-decor-dye-updates-in-patch-12-1-381939 (patch 12.1 dye news); 6 reference/identity links |
| `evidence/v2/2026-10-29T1830Z-F004-patch121-nine-dye-spell-universe.json` | 22 | 0 | 11 held (9 with matching numbers); 11 reference/identity links |
| `evidence/v2/2026-10-29T1929Z-F004-tww-milling-multiplier-denominator.json` | 1 | 0 | 1 new source skipped: reddit:1fvhzy0 (pigment multipliers (x1.52, x1.49) and a multi-stage cipher count) |
| `evidence/v2/2026-10-29T2026Z-F004-tww-prospecting-epoch-and-ironclaw.json` | 7 | 0 | 5 held (1 with matching numbers); 2 reference/identity links |
| `evidence/v2/2026-10-29T2131Z-F004-tww-milling-two-axis-context.json` | 3 | 0 | 3 held (2 with matching numbers) |
| `evidence/v2/2026-10-29T2230Z-F004-midnight-crushing-gross-vs-casts.json` | 3 | 0 | 3 held (1 with matching numbers) |
| `evidence/v2/2026-10-29T2332Z-F004-midnight-crushing-net-gem-context.json` | 5 | 0 | 1 held (0 with matching numbers); 3 new source skipped: blizzforum:2278388 (Resourcefulness explanation for crushing); reddit:1v5esk0 (crushing rate forecast (dust per gem)); reddit:1vknxyy (same author repeats the crushing rate); 1 reference/identity links |
| `evidence/v2/2026-10-30T0030Z-F004-midnight-milling-batch-and-mixed-rank.json` | 7 | 0 | 1 held (0 with matching numbers); 1 new source skipped: blizzforum:2362528 (milling UI and skill-threshold discussion); 5 reference/identity links |
| `evidence/v2/2026-10-30T0132Z-F004-tww-milling-live-batch-epoch-reconciliation.json` | 4 | 0 | 1 held (0 with matching numbers); 1 new source skipped: reddit:1jc2ya5 (qualitative rank-versus-yield discussion); 2 reference/identity links |
| `evidence/v2/2026-10-30T0228Z-F004-midnight-post-hotfix-prospecting-rate-context.json` | 2 | 14 | **imported 14** |
| `evidence/v2/2026-10-30T0333Z-F004-midnight-r2-prospecting-JD3K-totals.json` | 5 | 0 | 2 held (1 with matching numbers); 3 reference/identity links |
| `evidence/v2/2026-10-30T0432Z-F004-crushing-rank-identity-and-reagent-variant.json` | 10 | 0 | 1 held (0 with matching numbers); 1 new source skipped: reddit:1rrn6of (Resourcefulness UI observation while crushing); 8 reference/identity links |
| `evidence/v2/2026-10-30T0529Z-F004-crushing-selector-matrix-and-refining-identity.json` | 13 | 0 | 5 held (2 with matching numbers); 1 new source skipped: reddit:1rrn6of (Resourcefulness UI observation while crushing); 7 reference/identity links |
| `evidence/v2/2026-10-30T0629Z-F004-df-prospecting-bugy-denominator-and-rank-contradiction.json` | 2 | 0 | 2 held (1 with matching numbers) |
| `evidence/v2/2026-10-30T0734Z-F004-df-draconium-racial-rank-split.json` | 3 | 0 | 1 held (1 with matching numbers); 2 new source skipped: blizzforum:1484679 (forum reproduction of ar_rules' reddit 109bytz study, which agents hol); gdoc:e (ar_rules' published spreadsheet for reddit 109bytz (agent-held)) |
| `evidence/v2/2026-10-30T0826Z-F004-midnight-diamond-ore-trait-gates.json` | 8 | 0 | 3 held (0 with matching numbers); 5 reference/identity links |
| `evidence/v2/2026-10-30T0928Z-F004-df-r3-ore-591-diamond-cohort.json` | 2 | 0 | 2 held (2 with matching numbers) |
| `evidence/v2/2026-10-30T1032Z-F004-tww-milling-skill-rank.json` | 1 | 0 | 1 reference/identity links |
| `evidence/v2/2026-10-30T1131Z-F004-midnight-prospecting-effective-skill-refresh.json` | 3 | 0 | 3 new source skipped: blizzforum:611648 (skill shortfall after reset); reddit:1s66wrz (community comments on R2 output without concentration); reddit:1sgvqjt (effective-skill display before and after relog) |
| `evidence/v2/2026-10-30T1233Z-F004-midnight-milling-batch-selector-yield-conflict.json` | 5 | 0 | 3 held (0 with matching numbers); 1 new source skipped: blizzforum:2287404 (milling selector report (17 displayed crafts, not completed casts)); 1 reference/identity links |
| `evidence/v2/2026-10-30T1331Z-F004-midnight-powder-yield-rank-context.json` | 7 | 0 | 2 held (2 with matching numbers); 5 reference/identity links |
| `evidence/v2/2026-10-30T1428Z-F004-tww-prospecting-amber-substitution-epoch.json` | 11 | 0 | 5 held (4 with matching numbers); 2 new source skipped: reddit:1gcai5k (quotes the Oct 25 2024 prospecting hotfix); wowhead:news=recent-prospecting-changes-wowhead-economy-weekly-wrap-up-351-349956@ptr (news coverage of the Oct 2024 prospecting hotfix); 4 reference/identity links |
| `evidence/v2/2026-10-30T1529Z-F004-tww-arathor-milling-selector-exclusion.json` | 4 | 0 | 2 held (0 with matching numbers); 2 new source skipped: blizzforum:1935257 (Arathor's Spear missing from the milling selector); blizzforum:2083666 (Arathor's Spear missing from the milling selector) |
| `evidence/v2/2026-10-30T1626Z-F004-tww-luredrop-per-operation-range.json` | 2 | 1 | **imported 1** |
| `evidence/v2/2026-10-30T1733Z-F004-midnight-prospecting-gear-refresh-rank-gate.json` | 4 | 0 | 4 new source skipped: blizzforum:2316717 (posts 2, 6 and 7: gear re-equip changed displayed skill, output qualit); blizzforum:2316717:2 (posts 2, 6 and 7: gear re-equip changed displayed skill, output qualit); blizzforum:2316717:6 (posts 2, 6 and 7: gear re-equip changed displayed skill, output qualit); blizzforum:231671 |
| `evidence/v2/2026-10-30T1825Z-F004-df-serevite-rank-id-and-diamond-cross-quality.json` | 3 | 0 | 2 held (2 with matching numbers); 1 new source skipped: blizzforum:1652762 (Draggoth on output quality and skill) |
| `evidence/v2/2026-10-30T1930Z-F004-df-4000-prospects-rank-split.json` | 1 | 0 | 1 held (1 with matching numbers) |
| `evidence/v2/2026-10-30T2028Z-F004-df-two-stage-diamond-denominators.json` | 2 | 0 | 1 held (1 with matching numbers); 1 reference/identity links |
| `evidence/v2/2026-10-30T2130Z-F004-df-prismatic-identity-and-primary-ore-cohorts.json` | 3 | 0 | 3 held (2 with matching numbers) |
| `evidence/v2/2026-10-30T2230Z-F004-df-duplicate-cohort-ancestry.json` | 1 | 0 | 1 held (1 with matching numbers) |
| `evidence/v2/2026-10-30T2334Z-F004-df-diamond-mixed-rank-denominator-crosspost.json` | 8 | 1 | **imported 1** |
| `evidence/v2/2026-10-31T0034Z-F004-df-ranked-ore-prismatic-diamond-cohorts.json` | 6 | 0 | 6 held (2 with matching numbers) |

### M03.3 leads (1 files)

| File | Claims | Rows | Outcome |
| --- | --- | --- | --- |
| `evidence/leads/dragonflight-draconium-illimited-diamond-two-2000ore-cohorts.json` | 1 | 0 | 1 new source skipped: wowhead:item=192870 (Bugy's two 2,000-ore Draconium cohorts (3 and 8 Illimited Diamonds): t) |

### M03.4 worker submissions (38 files)

| File | Claims | Rows | Outcome |
| --- | --- | --- | --- |
| `coordination/submissions/loot-liquidator-dragonflight/2026-10-28-0434-dragonflight-batch004-beta-source-only.json` | 3 | 0 | 1 held (1 with matching numbers); 2 new source skipped: reddit:y3e8ek (2022 original discussion of the Dragonflight beta, qualitative); wowhead:news=dragonflight-jewelcrafting-analysis-wowhead-economy-weekly-wrap-up-249-329385 (Wowhead article on Jallfo's 2022 beta sheet) |
| `coordination/submissions/loot-liquidator-dragonflight/2026-10-28-0434-dragonflight-batch004-numeric-candidate.json` | 3 | 0 | mechanics hypothesis card (reference/target contexts restate held cohorts; BLOCKED, no new measurement) |
| `coordination/submissions/loot-liquidator-dragonflight/2026-10-28-0630-dragonflight-batch006-numeric-candidate.json` | 3 | 0 | mechanics hypothesis card (reference/target contexts restate held cohorts; BLOCKED, no new measurement) |
| `coordination/submissions/loot-liquidator-dragonflight/2026-10-28-0728-dragonflight-batch007-numeric-candidate.json` | 6 | 0 | mechanics hypothesis card (reference/target contexts restate held cohorts; BLOCKED, no new measurement) |
| `coordination/submissions/loot-liquidator-dragonflight/2026-10-28-0830-dragonflight-batch008-study-synthesis.json` | 5 | 0 | 5 held (0 with matching numbers) |
| `coordination/submissions/loot-liquidator-dragonflight/2026-10-28-1126-dragonflight-batch011-numeric-candidate.json` | 5 | 0 | mechanics hypothesis card (reference/target contexts restate held cohorts; BLOCKED, no new measurement) |
| `coordination/submissions/loot-liquidator-dragonflight/2026-10-28-1231-dragonflight-batch012-40key-field-audit.jsonl` | 202 | 0 | process artifact: field audit, validation or confidence chart (scores and derived values, not observations) |
| `coordination/submissions/loot-liquidator-dragonflight/2026-10-28-1328-dragonflight-batch013-40key-field-audit.jsonl` | 43 | 0 | process artifact: field audit, validation or confidence chart (scores and derived values, not observations) |
| `coordination/submissions/loot-liquidator-dragonflight/2026-10-28-1627-dragonflight-q18-batch016-40key-fourfield-audit.jsonl` | 2 | 0 | process artifact: field audit, validation or confidence chart (scores and derived values, not observations) |
| `coordination/submissions/loot-liquidator-dragonflight/2026-10-28-1830-dragonflight-q20-batch018-40key-fourfield-audit.jsonl` | 0 | 0 | process artifact: field audit, validation or confidence chart (scores and derived values, not observations) |
| `coordination/submissions/loot-liquidator-dragonflight/2026-10-28-1931-dragonflight-q21-batch019-validation.json` | 0 | 0 | process artifact: field audit, validation or confidence chart (scores and derived values, not observations) |
| `coordination/submissions/loot-liquidator-legacy/2026-10-28-0436-legacy-batch004-felslate-numeric-candidate.json` | 2 | 0 | mechanics hypothesis card (reference/target contexts restate held cohorts; BLOCKED, no new measurement) |
| `coordination/submissions/loot-liquidator-legacy/2026-10-28-0535-legacy-batch005-felslate-numeric-candidate.json` | 3 | 0 | mechanics hypothesis card (reference/target contexts restate held cohorts; BLOCKED, no new measurement) |
| `coordination/submissions/loot-liquidator-legacy/2026-10-28-0640-legacy-batch006-felslate-numeric-candidate.json` | 4 | 0 | mechanics hypothesis card (reference/target contexts restate held cohorts; BLOCKED, no new measurement) |
| `coordination/submissions/loot-liquidator-legacy/2026-10-28-0740-legacy-batch007-felslate-numeric-candidate.json` | 3 | 0 | mechanics hypothesis card (reference/target contexts restate held cohorts; BLOCKED, no new measurement) |
| `coordination/submissions/loot-liquidator-legacy/2026-10-28-0837-legacy-batch008-felslate-numeric-candidate.json` | 3 | 0 | mechanics hypothesis card (reference/target contexts restate held cohorts; BLOCKED, no new measurement) |
| `coordination/submissions/loot-liquidator-legacy/2026-10-28-0937-legacy-batch009-felslate-numeric-candidate.json` | 3 | 0 | mechanics hypothesis card (reference/target contexts restate held cohorts; BLOCKED, no new measurement) |
| `coordination/submissions/loot-liquidator-legacy/2026-10-28-0937-legacy-batch009-validation.json` | 0 | 0 | process artifact: field audit, validation or confidence chart (scores and derived values, not observations) |
| `coordination/submissions/loot-liquidator-legacy/2026-10-28-1440-legacy-q16-batch014-40key-fourfield-audit.jsonl` | 40 | 0 | process artifact: field audit, validation or confidence chart (scores and derived values, not observations) |
| `coordination/submissions/loot-liquidator-legacy/2026-10-28-1540-legacy-q17-batch015-40key-fourfield-audit.jsonl` | 41 | 0 | process artifact: field audit, validation or confidence chart (scores and derived values, not observations) |
| `coordination/submissions/loot-liquidator-legacy/2026-10-28-1742-legacy-q19-batch017-40key-fourfield-audit.jsonl` | 58 | 0 | process artifact: field audit, validation or confidence chart (scores and derived values, not observations) |
| `coordination/submissions/loot-liquidator-legacy/2026-10-29-0041-legacy-q26-batch024-14key-fourfield-audit-corrected-v2.jsonl` | 3 | 0 | process artifact: field audit, validation or confidence chart (scores and derived values, not observations) |
| `coordination/submissions/loot-liquidator-legacy/2026-10-29-0041-legacy-q26-batch024-14key-fourfield-audit.jsonl` | 3 | 0 | process artifact: field audit, validation or confidence chart (scores and derived values, not observations) |
| `coordination/submissions/loot-liquidator-midnight/2026-10-28-0605-midnight-batch006-numeric-candidate.json` | 3 | 0 | mechanics hypothesis card (reference/target contexts restate held cohorts; BLOCKED, no new measurement) |
| `coordination/submissions/loot-liquidator-midnight/2026-10-28-0711-midnight-batch007-numeric-candidate.json` | 2 | 0 | mechanics hypothesis card (reference/target contexts restate held cohorts; BLOCKED, no new measurement) |
| `coordination/submissions/loot-liquidator-midnight/2026-10-28-0912-midnight-batch009-numeric-candidate.json` | 5 | 0 | mechanics hypothesis card (reference/target contexts restate held cohorts; BLOCKED, no new measurement) |
| `coordination/submissions/loot-liquidator-midnight/2026-10-28-1105-midnight-batch011-numeric-candidate.json` | 4 | 0 | mechanics hypothesis card (reference/target contexts restate held cohorts; BLOCKED, no new measurement) |
| `coordination/submissions/loot-liquidator-midnight/2026-10-28-1611-midnight-q18-batch016-35key-fourfield-audit.jsonl` | 29 | 0 | process artifact: field audit, validation or confidence chart (scores and derived values, not observations) |
| `coordination/submissions/loot-liquidator-midnight/2026-10-28-batch002-silver-800cast-source-only.json` | 1 | 0 | 1 held (1 with matching numbers) |
| `coordination/submissions/loot-liquidator-midnight/2026-10-28-batch004-0413-mechanics-candidate.json` | 4 | 0 | mechanics hypothesis card (reference/target contexts restate held cohorts; BLOCKED, no new measurement) |
| `coordination/submissions/loot-liquidator-war-within/2026-10-28-0418-warwithin-batch004-numeric-candidate.json` | 4 | 0 | mechanics hypothesis card (reference/target contexts restate held cohorts; BLOCKED, no new measurement) |
| `coordination/submissions/loot-liquidator-war-within/2026-10-28-0625-warwithin-batch006-numeric-candidate.json` | 3 | 0 | mechanics hypothesis card (reference/target contexts restate held cohorts; BLOCKED, no new measurement) |
| `coordination/submissions/loot-liquidator-war-within/2026-10-28-0724-warwithin-batch007-numeric-candidate.json` | 4 | 0 | mechanics hypothesis card (reference/target contexts restate held cohorts; BLOCKED, no new measurement) |
| `coordination/submissions/loot-liquidator-war-within/2026-10-28-0724-warwithin-batch007-validation.json` | 0 | 0 | process artifact: field audit, validation or confidence chart (scores and derived values, not observations) |
| `coordination/submissions/loot-liquidator-war-within/2026-10-28-0818-warwithin-batch008-tww-resourcefulness-numeric-candidate.json` | 6 | 0 | mechanics hypothesis card (reference/target contexts restate held cohorts; BLOCKED, no new measurement) |
| `coordination/submissions/loot-liquidator-war-within/2026-10-28-1020-warwithin-batch010-confidence-chart-data.json` | 0 | 0 | process artifact: field audit, validation or confidence chart (scores and derived values, not observations) |
| `coordination/v2/submissions/evidence-researcher/2026-10-30T2130Z-F004-df-prismatic-identity-and-primary-ore-cohorts-submission.json` | 0 | 0 | run summary of a v2 evidence report; its cohorts are assessed with research/evidence/v2/2026-10-30T2130Z-F004-df-prismatic-identity-and-primary-ore-cohorts.json (M03.3) |
| `coordination/v2/submissions/independent-validator/20261030T0349Z-F005-DF-RAW-RECIPE-ID-NATIVE-GATE.json` | 1 | 0 | process artifact: field audit, validation or confidence chart (scores and derived values, not observations) |

### Other-schema JSONL (43 records)

| File | Line | Record | Outcome |
| --- | --- | --- | --- |
| `evidence/observations/2026-10-28-legacy-milling-batch01.jsonl` | 1 | `output-main:compiled:mill:109124:114931:L124` | imported |
| `evidence/observations/2026-10-28-legacy-milling-batch01.jsonl` | 2 | `output-main:compiled:mill:109125:114931:L127` | imported |
| `evidence/observations/2026-10-28-legacy-milling-batch01.jsonl` | 3 | `output-main:compiled:mill:109126:114931:L130` | imported |
| `evidence/observations/2026-10-28-legacy-milling-batch01.jsonl` | 4 | `output-main:compiled:mill:109127:114931:L133` | imported |
| `evidence/observations/2026-10-28-legacy-milling-batch01.jsonl` | 5 | `output-main:compiled:mill:109128:114931:L136` | imported |
| `evidence/observations/2026-10-28-legacy-milling-batch01.jsonl` | 6 | `output-main:compiled:mill:109129:114931:L139` | imported |
| `evidence/observations/2026-10-28-legacy-milling-batch01.jsonl` | 7 | `output-main:compiled:mill:152505:153635:L158` | imported |
| `evidence/observations/2026-10-28-legacy-milling-batch01.jsonl` | 8 | `output-main:compiled:mill:152505:153636:L159` | imported |
| `evidence/observations/2026-10-28-legacy-milling-batch01.jsonl` | 9 | `output-main:compiled:mill:152505:153669:L160` | imported |
| `evidence/observations/2026-10-28-legacy-milling-batch01.jsonl` | 10 | `output-main:compiled:mill:152506:153635:L163` | imported |
| `evidence/observations/2026-10-28-legacy-milling-batch01.jsonl` | 11 | `output-main:compiled:mill:152506:153636:L164` | imported |
| `evidence/observations/2026-10-28-legacy-milling-batch01.jsonl` | 12 | `output-main:compiled:mill:152506:153669:L165` | imported |
| `evidence/observations/2026-10-28-legacy-milling-batch01.jsonl` | 13 | `output-main:compiled:mill:152507:153635:L168` | imported |
| `evidence/observations/2026-10-28-legacy-milling-batch01.jsonl` | 14 | `output-main:compiled:mill:152507:153636:L169` | imported |
| `evidence/observations/2026-10-28-legacy-milling-batch01.jsonl` | 15 | `output-main:compiled:mill:152507:153669:L170` | imported |
| `evidence/observations/2026-10-28-legacy-milling-batch01.jsonl` | 16 | `output-main:compiled:mill:152508:153635:L173` | imported |
| `evidence/observations/2026-10-28-legacy-milling-batch01.jsonl` | 17 | `output-main:compiled:mill:152508:153636:L174` | imported |
| `evidence/observations/2026-10-28-legacy-milling-batch01.jsonl` | 18 | `output-main:compiled:mill:152508:153669:L175` | imported |
| `evidence/observations/2026-10-28-legacy-milling-batch01.jsonl` | 19 | `output-main:compiled:mill:152509:153635:L178` | imported |
| `evidence/observations/2026-10-28-legacy-milling-batch01.jsonl` | 20 | `output-main:compiled:mill:152509:153636:L179` | imported |
| `evidence/observations/2026-10-28-legacy-milling-batch01.jsonl` | 21 | `output-main:compiled:mill:152509:153669:L180` | imported |
| `evidence/observations/2026-10-28-legacy-milling-batch01.jsonl` | 22 | `output-main:compiled:mill:152510:153635:L183` | skipped: copy: v3 already holds input, output and total 157 (midnight-b010-bfa-baadkitty-152510-200herbs) |
| `evidence/observations/2026-10-28-legacy-milling-batch01.jsonl` | 23 | `output-main:compiled:mill:152510:153636:L184` | skipped: copy: v3 already holds input, output and total 71 (midnight-b010-bfa-baadkitty-152510-200herbs) |
| `evidence/observations/2026-10-28-legacy-milling-batch01.jsonl` | 24 | `output-main:compiled:mill:152510:153669:L185` | skipped: copy: v3 already holds input, output and total 64 (midnight-b010-bfa-baadkitty-152510-200herbs) |
| `evidence/observations/2026-10-28-legacy-milling-batch01.jsonl` | 25 | `output-main:compiled:mill:152511:153635:L188` | imported |
| `evidence/observations/2026-10-28-legacy-milling-batch01.jsonl` | 26 | `output-main:compiled:mill:152511:153636:L189` | imported |
| `evidence/observations/2026-10-28-legacy-milling-batch01.jsonl` | 27 | `output-main:compiled:mill:152511:153669:L190` | imported |
| `evidence/observations/2026-10-28-legacy-milling-batch01.jsonl` | 28 | `output-main:compiled:mill:168583:173056:L195` | imported |
| `evidence/observations/2026-10-28-legacy-milling-batch01.jsonl` | 29 | `output-main:compiled:mill:168583:173057:L196` | imported |
| `evidence/observations/2026-10-28-legacy-milling-batch01.jsonl` | 30 | `output-main:compiled:mill:168583:175788:L197` | imported |
| `evidence/observations/2026-10-28-2116-warwithin-batch014-q16-recipe-metadata.jsonl` | 1 | `tww-q16-20261028-recipe-102167` | skipped: recipe already in v3 (import-recipe-00008, legacy-20261031-912) |
| `evidence/observations/2026-10-28-2116-warwithin-batch014-q16-recipe-metadata.jsonl` | 2 | `tww-q16-20261028-recipe-2659` | skipped: recipe already in v3 (import-recipe-00001) |
| `evidence/observations/2026-10-28-2116-warwithin-batch014-q16-recipe-metadata.jsonl` | 3 | `tww-q16-20261028-recipe-29356` | skipped: recipe already in v3 (import-recipe-00003) |
| `evidence/observations/2026-10-28-2116-warwithin-batch014-q16-recipe-metadata.jsonl` | 4 | `tww-q16-20261028-recipe-29360` | skipped: recipe already in v3 (import-recipe-00004) |
| `evidence/observations/2026-10-28-2116-warwithin-batch014-q16-recipe-metadata.jsonl` | 5 | `tww-q16-20261028-recipe-3569` | skipped: recipe already in v3 (import-recipe-00002) |
| `evidence/observations/2026-10-28-2116-warwithin-batch014-q16-recipe-metadata.jsonl` | 6 | `tww-q16-20261028-recipe-46353` | skipped: recipe already in v3 (import-recipe-00005, legacy-20261031-902) |
| `evidence/observations/2026-10-28-2116-warwithin-batch014-q16-recipe-metadata.jsonl` | 7 | `tww-q16-20261028-recipe-55208` | skipped: recipe already in v3 (import-recipe-00006, legacy-20261031-906) |
| `evidence/observations/2026-10-28-2116-warwithin-batch014-q16-recipe-metadata.jsonl` | 8 | `tww-q16-20261028-recipe-74537` | skipped: recipe already in v3 (import-recipe-00007, legacy-20261031-909) |
| `evidence/observations/2026-10-28-1231-dragonflight-batch012-source-cohort-reconciliation.jsonl` | 1 | `df-b012-reuse-serevite-r2-1000` | skipped: copy: the agent marked it REUSED_ORIGINAL_NOT_NEW; v3 holds the source and the numbers 1.427, 1000, 1427, 5000 |
| `evidence/observations/2026-10-28-1231-dragonflight-batch012-source-cohort-reconciliation.jsonl` | 2 | `df-b012-reuse-serevite-r3-8000` | skipped: copy: the agent marked it REUSED_ORIGINAL_NOT_NEW; v3 holds the source and the numbers 1.434, 8000, 11472, 40000 |
| `evidence/observations/2026-10-28-1231-dragonflight-batch012-source-cohort-reconciliation.jsonl` | 3 | `df-b012-reuse-hochen-r2-9000-herbs` | skipped: copy: the agent marked it REUSED_ORIGINAL_NOT_NEW; v3 holds the source and the numbers 1418, 6050 |
| `evidence/observations/2026-10-28-1231-dragonflight-batch012-source-cohort-reconciliation.jsonl` | 4 | `df-b012-reuse-saxifrage-r2-100-herbs` | skipped: copy: the agent marked it REUSED_ORIGINAL_NOT_NEW; v3 holds the source and the numbers 16, 64 |
| `evidence/observations/2026-10-28-1231-dragonflight-batch012-source-cohort-reconciliation.jsonl` | 5 | `df-b012-reuse-beta-derivative` | skipped: copy: the agent marked it REUSED_DERIVATIVE_NOT_NEW_INDEPENDENT; v3 holds the source and the numbers 3.5 |

### M03.6 ledgers (8 files)

| File | Rows | Outcome |
| --- | --- | --- |
| `ledger/first-pass-coverage-2026-10-28.csv` | 1737 | skipped: coverage tracker (status per stable key, blocker text); numbers are file/line references |
| `ledger/first-pass-coverage-v1.csv` | 1171 | skipped: coverage scores per GameData/TSM key; the GameData personal-pooled sample counts it quotes (e.g. samples=12) are the rows already imported in gamedata-disenchant.jsonl |
| `ledger/first-pass-tsm-other-28-field-evidence-2026-10-28.csv` | 28 | skipped: TSM field review; its six Legion worksheet rows restate the 3,200-ore Deckven/Felslate cohort held in old-studies.jsonl |
| `ledger/master-worker-batch002-four-field-scores-2026-10-28.csv` | 90 | skipped: four-field confidence scores per stable key (process): scores and notes, no raw counts |
| `ledger/master-worker-batch008-four-field-scores-2026-10-28.csv` | 115 | skipped: four-field confidence scores per stable key (process): scores and notes, no raw counts |
| `ledger/master-worker-batch010-four-field-scores-2026-10-28.csv` | 50 | skipped: four-field confidence scores per stable key (process): scores and notes, no raw counts |
| `ledger/supplemental-output-fields.csv` | 255 | skipped: GameData/TSM-derived field table (TSM Prospect.lua, GameData personal pools, recipes); the same rows are imported from GameData.lua and itemdb.lua |
| `ledger/titanium-observed-yields.csv` | 12 | skipped: Titanium totals from two sources; each row compared with held rows (rowChecks) |
