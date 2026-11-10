# Elementium 52185 original-cohort duplicate guard — 2026-11-10T13:01:16.377Z

**Scope:** Manager-only source lineage / numerical integrity QA, research branch. No player testing, estimator execution or addon integration. This corrects the November 10 12:49 Legacy status assertion that three Elementium commenter cohorts were previously unarchived. The original human authors and their source measurements are genuine historical observations; the *new repository transcriptions* are copies of records already archived. Do not erase any original file.

## Source-original identity check

Original historical comment page: [Elementium Ore 52185, Cataclysm flavor](https://www.wowhead.com/cata/item=52185/elementium-ore). Its comments by users **724811**, **846144**, and **299691** are also rendered by alternate Wowhead locale/flavor URLs, including [MoP Classic mirror](https://www.wowhead.com/mop-classic/item=52185/elementium-ore). A mirror is not an independent material-processing experiment and does not prove current Retail conditions. All comparisons below use the **complete 12-output vector keyed by exact outputItemID and totalQuantity**, not just repeated source names.

| Human source | New November 10 records | Prior original records (same 12 IDs and exact quantities) | Original-reported input | Same total material units |
| --- | --- | --- | --- | ---: |
| 724811 (Doc) | `legacy-20261110-124901..124912` | `legacy-20261106-9101..` in `2026-11-06T1351-elementium-originals-and-bfa-kraken-patch-cohorts.jsonl`; also `legacy-20261109-2901..2912` in `2026-11-09T0251-elementium-doc-original-20stacks.jsonl` | 20 stacks, exact consumed ore and completed clicks not stated | 107 |
| 846144 | `legacy-20261110-124913..124924` | `legacy-20261106-846144-01..12` in `2026-11-06T1955-elementium-846144-original-10000ore.jsonl` | 10,000 ore = 500 reported stacks; actual completed casts/refunds not logged | 2,730 |
| 299691 | `legacy-20261110-124925..124936` | `legacy-20261107-0654001..0654012` in `2026-11-07T0654-elementium-original-quantity-and-pooled-histograms.jsonl` | 92 stacks; completed clicks and net consumed ore not stated | 452 |

New file: `research/v3/evidence/legacy/2026-11-10T1249-elementium-three-original-quantity-cohorts.jsonl` (36 `sourceKind=study` rows, distinct *studyKey* aliases). Prior files retain the same material output IDs and all individual output quantities. Total **36 newly submitted rows / 3 purported new cohorts / 3,289 units** are restatements of already filed primary studies: **0 newly independent original cohorts, 0 independently new material-count observations, 0 newly observed casts/hits/zeros**. The author's original values remain useful only **once** under applicable version/profile safeguards.

### Evidence of output vector identity

- 724811: `52177:20,52178:3,52179:18,52180:18,52181:15,52182:14;52190:3,52191:5,52192:3,52193:2,52194:2,52195:4` in both old and new.
- 846144: `52177:367,52178:360,52179:371,52180:369,52181:361,52182:355;52190:83,52191:82,52192:99,52193:99,52194:87,52195:97` in both.
- 299691: `52177:56,52178:76,52179:52,52180:47,52181:65,52182:56;52190:17,52191:19,52192:13,52193:19,52194:21,52195:11` in both.

### Compiler risk and disposition

`research/v3/tools/build_estimates.py`, lines 471–483 and 608–615, normalizes Wowhead locale/PTR aliases but intentionally retains **game-flavor** aliases (`@cata` vs `@mop-classic`) in source identities; absent explicit `cohortKey` rows use normalized source, rank, casts and whole-study output vector. Therefore the **846144** and **724811** cross-flavor recopy is a plausible duplicate-counting risk even when full vectors match; the same-`@cata` **299691** copy is expected to be suppressed if its groups are otherwise compatible. The actual v3 estimator was **not run here**; this does **not** assert that compiled valuation currently double-counts any specific cohort.

**Safe next action:** Legacy worker owns append-only provenance/correction aliases for all 36 records; keep exact source commenter identity, input 52185, output vector, version and unit basis, and do not use aliases as new studies. Review a narrowly scoped dedupe regression that distinguishes *cross-flavor source mirrors of the same named author's historical comment* from genuinely independent game builds. Do not discard differences in observed epoch, ranks or measured context merely because output vectors match. Rebuild and test only through authorized research integration review; protect the three-pass addon branch.

**Measured-versus-priced:** 10,000 stated ore and 2,730 gem units are usable original *aggregate per-reported-input quantities* under declared source assumptions, not 2,000 independently counted casts, material hit probabilities, current Retail yields or current character gold decisions. Do not multiply a source-normalized expected quantity by occurrence chance again. No new probabilities, skill coefficients, Multicraft effects, prices, live-WoW tests, or economic recommendation assertions.
