# Loot Liquidator — War Within worker Batch 007 (2026-10-28)

**Live master assignment:** 2026-10-28-batch007-war_within, queue revision 9. Master explicitly redirected this worker from TWW home scope to **35 Legacy / Mists of Pandaria prospecting output keys**. Only the exact 35 assigned stable keys were audited; TWW Resourcefulness numerical hypothesis was researched separately. Branch: `research/processing-confidence`. Original production `GameData.lua` blob `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`; coverage ledger blob `e0dba044f263951be37f7089ad52ad58519aea8e`.

## First-pass audit: 35/35 distinct assigned keys

- 12 Ghost Iron Ore (72092), 12 Kyparite (72093), six Black Trillium Ore (72094) rare gems and five White Trillium Ore (72103) rare gems. All **35/35** exact line/ID pairs match GameData.lua and all **35/35** were `NEVER_EXAMINED` in queue-revision-9 ledger at audit time. All 35 pass necessary **conditional-bound** checks under the *unverified* assumption that TSM `amountOfMats` is per ore: `matRate*minAmount <= 5*amountOfMats <= matRate*maxAmount`. This is not proof that `matRate` is P(at least one), nor proof that the source quantity unit is per ore.
- Historical TSM proxies versus the [MoP Classic guide](https://www.wow-professions.com/mop/prospecting-table-mop-classic): Ghost Iron/Kyparite common 23.35% vs guide 24%; rare 4.5% vs guide 5%; Trillium rare 16% vs guide 17%. **35/35 nominal proxy-rate differences** across assigned rows, but their probability semantics and patch conditions are not established as identical. These are not current-Retail corrections. The guide's classic skill thresholds 500/550/600 cannot be applied as modern Retail expansion skill levels.
- Twelve adjacent Trillium common-gem rows, previously examined in the central anomaly ledger, remain **outside** this assignment and were not credited again. No production data changed.

## Three original historical Kyparite cohorts newly archived

Source: [original WoWHead Kyparite player comments](https://www.wowhead.com/mop-classic/item=72093/kyparite). The source names all 12 gem outputs, independently mapped to item IDs by [guide item links](https://www.wow-professions.com/mop/prospecting-table-mop-classic). Original comments lack exact build, profession stats, per-cast zero histograms and verifiable actual operation counts. Therefore `completedOperations=null` in all JSONL records; five-ore equivalents are denominators for descriptive comparisons **only**, not observed casts.

| Original player claim | Reported ore | Uncommon gem units | Rare gem units | Sparkling Shard units |
|---|---:|---:|---:|---:|
| Comment 555434 | 1,000 | 294 | 53 | 303 |
| Comment 965740 | 690 | 211 | 33 | 219 |
| Comment 463200 | 500 | 156 | 32 | 161 |
| **Pooled (if independent)** | **2,190** | **661** | **118** | **683** |

Descriptive per-five-ore-equivalent output totals: uncommon **1.509132**, rare **0.269406**, Sparkling Shard **1.559361**. Historical TSM six-output aggregate proxies, if source `amountOfMats` is per ore: uncommon **1.482000**, rare **0.273000** per five ore. Agreement at aggregate level is encouraging but **does not establish individual P(drop), conditional yield, exact cast count, independence of comments, or current-Retail rates**. Individual 12-output raw totals and sample-derived means are in the immutable observation JSONL and CSV. No Sparkling Shard mapping was added to the assigned key set.

## Independent field confidence and blockers

For each of 35 assigned rows, current-Retail **P=25, conditional min=30, conditional max=30, unconditional E=25**, except the 12 Kyparite rows with historical independent aggregate support for **E=35** (still not actual cast E). All **35 EXAMINED_INSUFFICIENT**, **zero >=90 all-fields**, **zero verified current-Retail numerical corrections**. Historical identity/method corroboration is stronger than rate confidence. Historical guide's chance proxies and TSM `matRate` are never treated as independently measured P; conditional min/max are only source-reported, not sample extrema. Missing current Retail patch, exact skill and per-cast zero-inclusive observations remain blockers.

## Parallel TWW numerical mechanics

Hypothesis `tww-prospect-resourcefulness-savings` remains **BLOCKED**. The 2024 Aqirite studies do not report exact saved-ore counts; a Dragonflight 0.33125 ore/cast historical result is not a TWW formula. See companion source audit and schema-conforming numeric candidate. **Zero verified numerical rules**, no adjustment to output probabilities or expected quantities. Proposed experiment: exact Algari Prospecting 434018 with Aqirite R2 210934, >=500 actual casts per matched Resourcefulness cohort, per-cast saved ore including zeros, stat/gear/spec/build and inventory reconciliation.

## Tests, throughput and master handoff

Validation script independently checked unique keys, exact GameData lines, central `NEVER_EXAMINED` statuses, numeric bounds, source-vs-guide proxy differences, per-comment integer output totals and no invented casts. Validation JSON contains precise checks. **External JSON Schema validator, Node repository tests and live in-game tests not executed**; do not claim these passed.

**Throughput:** 35 distinct first-pass keys submitted for master acceptance; three historical raw player cohorts (not first-pass keys); one separate blocked numeric hypothesis. Before master acceptance the central ledger remains 928/1737 examined, 809 `NEVER_EXAMINED` (35 assigned now submitted but not credited). If master accepts all 35 without overlap, it can advance to 963 examined and 774 remaining, subject to other worker submissions and master reconciliation. Do not equate first-pass completion with >=90 field confidence.

**Exact next targets:** master independently review the attached 35 stable keys; verify original TSM `amountOfMats` units and `matRate` semantics; collect current-Retail MoP prospecting per-cast zeros/ranges for 72092, 72093, 72094 and 72103; obtain matched TWW Resourcefulness refund histograms. No master queue, central ledger, main, production GameData.lua, TOC or addon source edits.
