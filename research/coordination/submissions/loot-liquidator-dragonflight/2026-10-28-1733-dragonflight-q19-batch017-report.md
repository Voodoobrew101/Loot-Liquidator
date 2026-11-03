# Dragonflight Batch 017 — queue revision 19
2026-10-28 17:33 PDT · loot-liquidator-dragonflight · research-only

## Scope
Audited **40/40 exact assigned stable keys**: 13 Draconium R2 prospecting output-rank rows, nine Draconium R1, two Draconium R3 diamond rank rows, one supplementary R2 Draconium→diamond R1 eligibility key, and 15 Dragonflight herb→pigment rank rows. All **39/39 GameData.lua source-line IDs and parent input groups** matched branch blob `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`. The supplementary key is an eligibility question, not an approved new mapping. Read live assignments revision 19, master batch016 verdict, source-memory, research lessons, itemdb schema, prior worker submission and source reviews.

## P0: Original beta spreadsheet reused — rank/skill discrepancy
The already archived **Jallfo October 12, 2022 Dragonflight beta** original spreadsheet contains three separate character contexts (one original study), each with 5,000 R3 Draconium Ore and reported prospecting skill **68 / 113 / 228**. Its "ILLUMINATED DIAMOND" rows report:
| Reported output rank | Skill 68 | Skill 113 | Skill 228 |
|---|---:|---:|---:|
| R1 | 11 | 8 | 0 |
| R2 | 0 | 0 | 1 |
| R3 | 1 | 1 | 17 |

Original: https://docs.google.com/spreadsheets/d/1B_CjPU0AUlJkbogauPTdo0W4dUZiP1hxZ8KMZX7qp3Q/edit?usp=sharing (rows 53–55, Draconium cohorts). Derivative author narrative: https://www.wowhead.com/news/dragonflight-jewelcrafting-analysis-wowhead-economy-weekly-wrap-up-249-329385 (published October 16, 2022, beta October 12). **Internal contradiction:** author states skill 250 is required for R3 but spreadsheet reports R3 diamonds at skills 68 and 113. Possible beta bug, data labeling issue or omitted context; do not assert a current-Retail mechanism. The sheet's gem name does not itself provide item IDs.

For assigned 190311→192870/192871, the R2 and R3 reported totals are source-only historical context. Gross 5,000 ore is NOT 1,000 verified completed casts: Resourcefulness and reprocessing are unknown. No P(hit), exact positive min/max, or unconditional actual-cast E can be established. R1 190311→192869 belongs to **war_within** worker's disjoint assignment, not ours; no claim or field promotion for that key. This study and its Wowhead republication were already indexed; **zero new independent cohorts**.

## P1: Four-field audit
160 independently reviewed slots: **78 historical TSM-derived family-level positive min/max proxies**, **82 unknown** (40 occurrence probabilities, 40 unconditional expected quantities, two supplementary positive bounds). Exact-rank bounds are not measured. Original cast denominator and skill/patch context remain null/unknown for TSM rows. No newly verified current-Retail numerical fields and no new legitimate output mappings. All static numeric invariants passed.

## P2: Decision-risk checks
- Draconium R2 output family 192866/192867/192868 copies historical `matRate=0.275` and `amountOfMats=0.0602` to each quality rank. Family nominal 5-ore proxy = **0.301**, but rank sum = **0.903** (3×). These are neither current AH prices nor actual cast E.
- Saxifrage R2 input 191465 copies a historical **3.5 pigments/5-herb family proxy** to Blazing ranks 198418/198419/198420; summing yields **10.5**, also 3×. Output quality alternatives must not be priced as simultaneous drops.
- Resourcefulness savings reduce input cost, not extra produced gems or pigments. No universal skill coefficient and no demonstrated current gold-optimal action flip.
- Source memory already indexed the original Jallfo, Aary Saxifrage, 2023 Draenei Draconium and Primer fish cohorts. Reused, not new; avoided counting derivatives as independent.

## Next exact IDs, limitations, QA
Prioritize current-Retail zero-inclusive per-cast rank histograms with item IDs, profession skill/spec, exact ore/herb quality, Resourcefulness and patch for **188658→192870/192871**, **189143→192837/192838/192839**, **190311→192870/192871**, **191465→198418/198419/198420**, and **191467→198412/198413**. Check 2022 beta skill-threshold contradiction before using old rank frequencies.

**New legitimate mappings: 0. New independent studies: 0. New current-Retail numeric fields: 0. Immutable corrections: 0.** A useful negative source-consistency finding was recorded. 39 source identities, 40 key/field structures and numeric invariants passed. Node CLI, Lua and WoW client tests were not run. No main, production Lua/TOC, master assignments, canonical registry, shared ledgers, source-memory or schedules changed.
