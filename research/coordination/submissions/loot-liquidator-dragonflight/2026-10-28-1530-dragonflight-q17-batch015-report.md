# Dragonflight Batch 015 — queue revision 17
2026-10-28 15:30 PDT · Worker loot-liquidator-dragonflight · research-only

## Exact assignment
40/40 master stable keys audited: 30 Draconium Ore R2 (188658) TSM source output rows, seven Draconium Ore R1 (189143) rows, and three supplementary Illimited Diamond R1 candidates (188658/189143/190311 -> 192869). All 37 source-line identities match pinned GameData.lua SHA 1d47c4a961c5dc5af626e659f7d96d1490d3cf9e. Three supplemental keys have no original GameData source line. All four fields separately preserved in accompanying JSONL: 37 P unknown, 37 E unknown, 3×4 supplemental fields unknown; 37 source-derived min and max each provisional (74 provisional range cells). Zero new confirmed current-Retail cast E, P or ranges. Zero newly approved output mappings.

## P0: newly indexed ORIGINAL Draconium R2 rank-specific diamond cohort
Original Reddit author (Jan 11 2023) reports first 30,000 rank-two Draconium ore bought/processed at Draenei 255/265 effective prospecting skill and 32.8% Inspiration: **32 rank-two Illimited Diamonds (192870) and 52 rank-three (192871)**. This is a historical original report with item rank IDs reconciled to GameData; no completed-cast histogram or Resourcefulness inventory reconciliation. The author's subsequent 180,000 and 120,000 ore work is overlapping/same-author, NOT independent evidence. Bioness's Jan 12 Blizzard forum quotation reproduces the Reddit report, NOT an independent study.

For arithmetic comparison ONLY, 30,000 nominal gross ore / 5 = 6,000 hypothetical five-ore equivalents. Historical reported totals / 6,000 are R2 0.00533333, R3 0.00866667 and combined 0.014 diamonds per nominal five purchased ore. **These are not observed per-completed-cast expected quantities**; 30k purchased ore need not equal 30k net consumed due Resourcefulness. The old TSM proxy is E=5×0.0028=0.014 for EACH rank, which if blindly summed across three ranks would yield 0.042, three times the source's 0.014 gross-equivalent combined reference. Do not assign the historical ratios to current 2026 unskilled baseline or infer zero rank-one chance. The source is strong evidence that output rank depends on skill and hidden skill near threshold; no universal coefficient is supported.

Primary: https://www.reddit.com/r/woweconomy/comments/109bytz/prospecting_useless_hold_my_beer_said_the_draenei/
Derivative mirror (Jan 12 2023): https://us.forums.blizzard.com/en/wow/t/massive-profession-advantage-from-racial-bonuses/1484679
Item rank evidence: GameData.lua lines 1204-1206 (rank 1/2/3 diamond) and Draconium ore 188658 rank 2 / 189143 rank 1.
Canonical source-only observation: df-2023-draenei-r2-draconium-30000ore-rank2-rank3-diamond-source-only-20261028.

## P1/P2: 37 rank alternatives
GameData.lua lines 1174–1203 contain ten three-rank output families for Draconium R2; lines 1212–1218 contain seven R1 source rows. The 30 R2 source rows' historical E proxy sums to 6.6330 if all ranks are naively added, versus 2.2110 if one historical family E is counted per three-rank family (exact 3x inflation). This is a **source-model duplication diagnostic**, not a claim that the second number is measured true E. No exact per-rank cast counts or rank-specific P were recovered for the 37 assigned source rows. Historical source P/E arithmetic passes per-row inequalities, but this does not validate duplicating family-level values across output qualities.

Prior Bugy 2×2,000-ore Draconium aggregate was already archived in batch013; rank labels are unassigned, so it was REUSED only, not counted as a new cohort or mapped to R2 input. Historical TSM is DERIVATIVE, not an independent player study.

## Source-memory and master QA
Read live queue rev17, master batch014 verdict, source-memory.json, research-lessons.md and batch013/batch014 source reviews. Source-memory is explicitly stale and omits later source-review events; checked recent review files before source reuse. Master already quarantined unsafe rank-specific E in earlier batches; no double-counted safety correction. The newly indexed 2023 original rank2/rank3 diamond count is contextual, not a master-approved current valuation field.

## Exact next IDs and handoff
188658 -> 192870/192871: obtain actual casts, R1/R2/R3 output histogram and Resourcefulness refunds under a documented current Retail patch/skill context. 188658 -> 192837/192838/192839 (Queen's Ruby ranks) and 192849/192850/192851 (Eternity Amber ranks): obtain per-cast rank histograms. 189143 -> 192837/192838/192839: independently verify skill/rank-specific outcomes. 190311 -> 192869: test whether R1 diamond is possible at documented skill, never set unknown to zero from historical absence.

No production, main, master assignments/ledgers, canonical registry, source-memory cache, addon Lua/TOC or schedule edited. Static source-line and numeric tests passed; Node CLI, Lua and in-game tests not run.