# Dragonflight Batch 023 — queue revision 25 — original workbook evidence

**2026-10-28 23:27 PDT · worker loot-liquidator-dragonflight · research-only.**

## Scope and QA
Read live assignments.json queue revision **25**, exact assignment `2026-10-28-batch023-dragonflight`; master batch022 verdict, source-memory, research-lessons and q24 source reviews. Independently matched **45/45** disjoint assigned stable keys to GameData.lua source lines and parent input IDs, pinned blob `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`. 31 prospecting (Draconium R2 `188658` 23 rows, Draconium R1 `189143` eight rows) and 14 milling rows. No new first-pass credit: these are missing-field revisits.

## New original author lineage: Xenastro / Different_Dig2687
Original author [Reddit post](https://www.reddit.com/r/woweconomy/comments/10vz6jh/prospecting_calculator_not_for_squids/) published 2023-02-07 explicitly identifies an original >700,000-ore historical log, its [Office 365 workbook](https://docs.google.com/spreadsheets/d/1jW-vz25Mha9GzeCe6qX9viuLyFsgDf2m/edit), and method: Resourcefulness tool for ore, Inspiration tool for prismatic intermediates. The author says logged cohorts vary by skill/Inspiration/Resourcefulness; do not conflate filtered rows with causal specialization scaling. Directly read `Prospecting Log` rows 28, 52, 54, 55, 62 (all Draconium Ore Q2 = item `188658` by independently corroborated rank identity [client-derived item record](https://thewowdb.com/item/draconium-ore-189143/)).

| Workbook row | 2023 date | Q2 ore Quantity | Skill | Inspiration | Resourcefulness | Green Q2 | Green Q3 | Blue Q2 | Blue Q3 | Epic Q2 | Epic Q3 |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 28 | 2023-01-03 | 8543 | 237 | 33.9% | 5.1% | 2036 | 866 | 929 | 562 | 15 | 9 |
| 52 | 2023-01-22 | 15000 | 248 | 34.8% | 13.3% | 3596 | 1701 | 1675 | 1111 | 39 | 10 |
| 54 | 2023-01-22 | 13000 | 248 | 36.8% | 13.3% | 3138 | 1531 | 1408 | 984 | 21 | 20 |
| 55 | 2023-01-23 | 21000 | 249 | 34.8% | 13.3% | 5206 | 2363 | 2268 | 1507 | 37 | 22 |
| 62 | 2023-02-01 | 13000 | 250 | 36.8% | 13.3% | 3074 | 1522 | 1354 | 1030 | 26 | 19 |
| **Same-author totals** | | **70543** | mixed | mixed | mixed | **17050** | **7983** | **7634** | **5194** | **138** | **80** |

Raw green/blue/epic Q1 counts are preserved in observations; **row 28 Epic Q1 is blank, NOT zero**. These are category totals, not individual gem item-ID totals; `Quantity` is the workbook's reported ore quantity, not a verified actual-consumed denominator. Resourcefulness/ore refunds and second-stage prismatic ore processing complicate any conversion to per-cast expectations. Do not compute observed completed casts as Quantity/5. Do not pool different skill contexts to claim a skill coefficient. Source observation confidence **52/100** applies to historical category evidence, not to item-specific numeric fields.

## P0 / P1 mapping and numeric results
New legitimate item-ID mappings: **0**. All 45 existing TSM-derived output IDs/parent inputs match source lines. The five original workbook rows contain no individual gem IDs and therefore cannot promote any of the 23 assigned `188658` output rows. **180/180 current-context P, positive min/max and unconditional E fields remain unverified** for these 45 assigned rows; existing TSM `minAmount/maxAmount` are unverified reference bounds, not observed exact-context positive bounds. No fabricated zeros, inferred probabilities, midpoint EV or source-rank transfers.

## P2 liquidation risk and source ancestry
- Draconium R2 input `188658`: 23 assigned output/rank rows use repeated TSM family values across different gem qualities. These are not independent simultaneous drops. Assigning the workbook's green/blue/epic totals to each individual gem would overvalue prospecting.
- Draconium R1 `189143`: eight assigned rows have no matching original Q1 workbook cohort in the inspected log. Do not transplant Q2 rates to Q1.
- Milling `191461/191462/191464/191465/191466/191467`: 14 assigned rows lack an original same-context histogram in this workbook. TSM `matRate=1` repeated over quality ranks does not prove guaranteed occurrence of every rank.
- A per-ore quantity and per-five-ore operation must not be mixed; Resourcefulness changes consumed inputs, not gem output. No current AH decision flip verified.
- This is **one original author** and five logged cohorts, not five independent author confirmations. No duplicate web fetch for previously archived TSM/GameData evidence.

## Next exact IDs / master handoff
First prioritize in-game rank-specific five-ore completed-cast logs for `188658 → 192846/192847/192848` (green family), `188658 → 192870/192871` (epic), then `189143 → 192837/192838/192839` and `191462 → 198421/198422/198423`. Capture zero outcomes, actual completed casts, per-item IDs, effective skill, specialization, Inspiration and Resourcefulness separately. Check whether `Prospecting Log` source raw category outputs can be mapped by original author documentation; do not guess.

**Actual run outcome:** 45 exact source-line identities; five newly indexed same-author historical category cohorts; zero new valid item mappings; zero verified current-Retail numeric fields; one new original author lineage relative to indexed source-memory. No production, canonical registry, master ledger, source-memory or schedule edits.
