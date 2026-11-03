# Loot Liquidator — Midnight worker Batch 005: Dragonflight overflow

**Date:** 2026-10-28. **Queue:** 2026-10-28-batch005-midnight revision 7. **Read branch head:** `16306b5cb4a6238115b7ae98d300b788f6f20209`. **Actual production GameData.lua blob:** `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`. Read latest assignments, PROGRESS, itemdb creation contract, both mechanics registries, numeric protocol and schema, observation schema and earlier evidence, Issue #2, actual GameData.lua, StatYieldProfiles.lua and ConversionEngine.lua. No production or master-owned changes.

## Assigned 35 distinct first-pass keys

- **35/35** audited: Khaz'gorite Ore rank 1 (190312) **14** rows; rank 2 (190313) **21** rows. Exactly 32 rank-labelled gem rows, 3 unranked byproducts. 10 complete rank-1/2/3 output-family groups and 1 partial group in this assignment. Every original stable key appears in the accompanying CSV.
- **35/35** exact GameData line and output-ID matches, **32/32** explicit sourceQuality checks (the three byproducts omit sourceQuality), **35/35** matches to pre-existing TSM research-ledger expected units, **35/35** necessary `P_proxy*min <= E <= P_proxy*max` arithmetic checks.
- Five-ore spell 374627 verified by [Dragon Isles Prospecting](https://www.wowhead.com/spell=374627/dragon-isles-prospecting). Each raw `amountOfMats` was multiplied once by five to reproduce historical `E` per nominal cast. `matRate` is an **unverified TSM occurrence proxy**, not an observed probability; conditional min/max are historical TSM bounds, not measured extrema. No chance re-multiplication or midpoint estimation.
- **35 EXAMINED_INSUFFICIENT**, **0 all-fields ≥90**, **0 approved corrections**. All records have unknown actual samples, historical patch/build, specialization, gear and gem-rank transition conditions. This is worker-submitted first-pass, not master acceptance.

## Independent source and critical quality issue

Original [Bugy Dragon Isles prospecting comment](https://www.wowhead.com/spell=374627/dragon-isles-prospecting) gives two Khaz'gorite rows labelled 100, per-ore family rates. The label does not unambiguously distinguish 100 ore from 100 casts; 100 ore implies fractional total output for 11 of 14 columns in cohort A and 12 of 14 in B, while 500 ore yields integers. Do **not** convert this arithmetic inference into an asserted 100 completed casts. Ore input rank, output rank and exact date remain unknown. Family-level rates are archived as **unmatched** comparators in the audit, not assigned to individual rank IDs.

| Family | TSM E per 5 ore per listed rank | Bugy A family E per 5 ore | Bugy B family E per 5 ore |
|---|---:|---:|---:|
| Nozdorite, R1 ore | 0.3625 | 0.0800 | 0.0900 |
| Illimited Diamond, R1 ore | 0.0300 | 0 | 0 |
| Queen's Ruby, R2 ore | 0.1300 | 0.0400 | 0.0200 |
| Crumbled Stone, R1 ore | 1.4240 | 0.2900 | 0.3300 |

**Not comparable conditions.** Source output-rank distribution, input rank, skill, gear, specialization, and denominator are unknown. The TSM rows repeat family rates for rank-1/2/3 outputs. Treating every quality row as simultaneously available risks triple-counting; no quality transition model is verified.

**New independent context-only observation:** [another historical Illimited Diamond player comment](https://www.wowhead.com/item=192869/illimited-diamond) reports 100 Khaz'gorite ore and two **rank-2** Illimited Diamonds. It does not identify the Khaz'gorite input quality, exact actual casts, patch or output histogram. It supports an historical family-level possible outcome but **cannot substantiate any of the 35 rank-specific keys** or a current Retail drop probability. Four original ore cohorts preserved in a new source-only JSON archive, zero additional first-pass credit.

## Four independent confidence fields

For all 35 historical TSM rows: item ID 65/100, **P(drop) 25/100**, **conditional minimum 35/100**, **conditional maximum 35/100**, **unconditional E 45/100**, patch/context 20/100; conservative record confidence **20/100**. These are evidence-quality judgments, not numerical accuracy probabilities. Sample counts are **null**, not zero. No measured cast-level hits, conditional distributions or independently verified rank assignment.

## Parallel numeric mechanics, separate from item coverage

Investigated `midnight-gem-hotfix-2026-03-31-quantification`: **1 hypothesis examined, 0 verified, 1 BLOCKED**. [Blizzard March 31, 2026 notes](https://us.forums.blizzard.com/en/wow/t/world-of-warcraft-midnight-hotfixes-april-17/2260898) establish a qualitative increase in Midnight gem frequency without any numeric multiplier. An [April 8, 2026 discussion](https://www.reddit.com/r/woweconomy/comments/1sfds1u/did_prospecting_change/) contains informal estimates of 12.5% before and ~15% after for unspecified gems, plus ~5% diamonds. The tempting **1.2x ratio is explicitly REJECTED**: no matched input IDs/ranks, gem output IDs/ranks, skill, nodes, equipment, build, exact operations or zero-inclusive histograms. An additional 200-craft Thorium anecdote is a different uncontrolled context. Source-only evidence and schema-shaped blocked candidate saved; prior master-rejected inferred 50-ore/5=10 casts not reused.

Required study: original timestamped pre-March-31 logs and matched post-hotfix logs, same five-ore recipe and exact ore ID/rank, gem IDs/ranks, client build, skill, spec, equipment, per-cast zeros, actual consumed/saved ore, enough casts for rare outcomes and independent replication. If old server conditions cannot be reproduced, archived contemporaneous original logs are required. No invented formula, coefficient, unlock, or rank transformation.

## Validation, blockers and next targets

Worker JS checked all 35 identities, 32 rank labels, 35 ledger means, 35 necessary bounds, 35 unique keys, and source-only evidence integrity. External JSON Schema/Ajv, repository Node suite and WoW client tests **not run**. Source-only JSON is intentionally not an observation.schema.json JSONL because exact input rank/actual casts are unavailable; do not fabricate those to satisfy schema.

**Master review pending.** Queue baseline: 1109 never-examined keys before this worker submission; if only these 35 are accepted, theoretical 1074 remain, but actual live remaining is master-owned and changes with other workers. Do not self-claim preview IDs; wait for explicit assignment. Current preview begins `output-main:tsm:prospect:23425:23438:L881` and `...36909:36918:L888`.

**Production main, GameData.lua, TOC, addon files, master assignments, central ledgers and PROGRESS unchanged.** Future shipped database remains exactly `itemdb.lua` after separate reviewed migration.
