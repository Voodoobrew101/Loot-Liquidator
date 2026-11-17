# Xenastro R2 Draconium: source refund field retained on only one of each cohort's output rows

Checked 2026-11-15 UTC. **Research-only static integration audit**, not a new source cohort, not a new observed craft count, not a current-Retail yield or priced gold decision. This follows the [already existing Nov 14 original-XLSX audit](20261114T1406-df-xenastro-original-xlsx-refund-units-recovery.md) and examines the **new 08:37 UTC worker append-only replacements**, rather than repeating original-source searches. No change to the worker's records, original XLSX, live addon or owner-owned three-pass branch.

## Concrete new source-to-consumer identity gap

The original [Xenastro Prospecting Calculator V1.xlsx](https://drive.google.com/file/d/1jW-vz25Mha9GzeCe6qX9viuLyFsgDf2m/view), `Prospecting Log`, groups multiple output quantity/quality rows under **one source study key / one workbook row**. Four [2026-11-15T08:37 worker corrections](../dragonflight/2026-11-15T0837-xenastro-original-r2-ore-refunds.jsonl) faithfully retain four source-reported Ore Refund values in `stats`, but replace **only the pooled-green-Q1 output row** of each study. The remaining **31 output rows across those four studies have no source refund metadata**. None of the 35 original rows or four replacements has a structured `inputsRefunded` value. This is a field-propagation/schema gap, **not** evidence of 31 independent missing refund events and **not yet a demonstrated addon defect**.

| Original XLSX Prospecting Log row | Source Quantity (ore units) | Source Ore Refund (ore units) | Refund units ÷ Quantity (descriptive only) | Original output rows / newly annotated replacement |
|---|---:|---:|---:|---:|
| 28 | 8,543 | 126 | 1.475% | 8 / 1 |
| 52 | 15,000 | 893 | 5.953% | 9 / 1 |
| 54 | 13,000 | 883 | 6.792% | 9 / 1 |
| 62 | 13,000 | 735 | 5.654% | 9 / 1 |
| **Four historical R2 studies, not 35 studies** | **49,543** | **2,637** | **5.322% aggregate descriptive ratio** | **35 / 4** |

These are **source-reported input-return units**, not proc occurrences, per-cast output quantities, material drop probabilities, output quality upgrades, or a supported reduction to a modern character's cost basis. Row 28's Quantity 8,543 is not divisible by five, making the danger of treating it as an exact count of five-ore completed prospects particularly concrete. The original log does not establish whether refunds were reprocessed; neither purchased ore, net effectively consumed ore, nor completed operations may be asserted from these columns alone.

## Source provenance, exact affected joins and static evidence

- Original source rows: `research/v3/evidence/dragonflight/2026-10-30T2027-xenastro-draconium-five-log-rows.jsonl`, pinned blob `f1c0720a2d5f804dcbf7c8227033f97d2236097b`. Four `studyKey` suffixes `row-28`, `row-52`, `row-54`, `row-62`; each has input **Draconium Ore 188658, R2**, with **8, 9, 9, 9** separate output quantity/quality rows.
- New worker evidence: `research/v3/evidence/dragonflight/2026-11-15T0837-xenastro-original-r2-ore-refunds.jsonl`, pinned blob `ad862d27dea42a19ade7e1439d5cf492b5f523b3`. New ID `dragonflight-20261115-083701..083704` replaces original IDs `dragonflight-20261030-500, -508, -517, -535` respectively. Each unchanged `totalQuantity` is **5, 7, 7, 7** for one **pooled green Q1** material family; do not call the other output rows copies of this same material.
- Static code: `research/v3/tools/build_estimates.py` `load()` resolves `replaces` per original record ID; `row_use()` reads `casts`, `inputsProcessed`, material quantities, chance fields but **does not parse Ore Refund out of free-text `stats`**. The documented `inputsRefunded` proposed field exists in `research/v3/migration/SCHEMA-EXTENSION.md`, and is in `CORRECTABLE`; the new worker records do not populate it. This means **the refund context is stored as prose on four material rows, not typed for consistent cohort-level attribution**. No fresh compiler or tooltip rendering executed to test behavior beyond this static trace.

## Reviewed engineering acceptance gate (not authorized to edit owner integration branch)

1. Index source-reported input-return facts by a **source-qualified cohort identity**: exact workbook row + `studyKey` + input item ID/rank/epoch, **not output material**. Preserve one report of 126/893/883/735 ore **per source cohort**, never sum a cohort's refund once for each of its 8/9 output alternatives. Preserve original source row/worksheet and all 35 distinct output rows.
2. Add typed `inputsRefunded` and **a separately specified source meaning for Quantity** only when backed by the actual workbook; do not silently force `inputsPurchased` or `inputsProcessed` from an ambiguous column. Confirm whether returned inputs were reprocessed before computing per-completed-cast yields or net economic cost. Source reporting rate is not character-specific Resourcefulness proc probability.
3. A regression fixture should join all **35** output rows into **four** source cohorts, find **four** refund facts rather than 4×8/9 duplicates, retain old original output numeric fields unchanged, and surface `unknown casts/hits/zeros` until independently documented. Different green/blue/epic material pools and quality ranks must not be priced as one identified gem.
4. Keep the historical Jan/Feb **2023 Inspiration-era** evidence distinct from current Retail profession mechanics and patch; do not use an unverified modern Resourcefulness multiplier or a gold recommendation. Owner-controlled source-to-actual-engine/tooltip validation and future source-policy decisions remain outside this research-only branch.

## Actual checks and limits

**Executed:** fetched/read the current worker and original JSONL from branch, independent JavaScript join by original replacement ID and `studyKey`, asserted four unchanged original total quantities, counted 35 cohort output rows and 31 unannotated siblings, parsed and checked four refunded-input/Quantity pairs, verified source `stats`/structured field absence, and inspected `build_estimates.py` / schema. Summed source counts **2,637 refunded / 49,543 source Quantity**. No independent XLSX cell reread today: the original source was separately inspected and documented in the Nov 14 manager audit and by the worker. **Not executed:** Python compiler, full addon/Lua/actual tooltip tests, current WoW client, synthetic-gold valuation or CI on this new note. No main, integration, original-worker, queue, conditions, flags, PR, release or schedule changes. Next: prefer truly new rank/skill/refund/zero-inclusive **current Retail** completed-operation ledgers (Midnight T0039/T0045, TWW T0009/T0010); a reviewed fixture for this source-qualified metadata loss can be scoped separately if integrated.
