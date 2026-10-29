# Original workbook formula audit — Midnight prospecting calculator (source-only)

Date of inspection: 2026-10-28; queue 25; worker loot-liquidator-midnight. Workbook: https://docs.google.com/spreadsheets/d/1jBMgICcVpqIezJo_dtBPmIdA7UTq8QToPp1JpVVONn0/edit. Source author's April 15, 2026 post: https://www.reddit.com/r/woweconomy/comments/1smgllg/prospecting_calculator/. Downloaded original 15,356-byte Excel workbook via connected Google Drive and inspected its formulas read-only using artifact_tool. Five worksheets: Copper, Tin, Silver, Thorium, Materials. Author explicitly states values are hardcoded estimates taken from WoW-Professions and do not account for prospecting specialization. This is **one derivative calculator, not an independent observed experiment**. Workbook metadata reported created 2026-01-28, modified 2026-06-02; these timestamps do not date original source experiments.

## Actual formula evidence

- Materials!E2 = 7 (user-supplied Resourcefulness percent in saved workbook).
- Copper!C2:C5: `=SUM(((((Materials!E2*0.3)/100)*G2)/5)+(G2/5)*0.08)` (four uncommon gems).
- Copper!C6 (Eversong Diamond): `=SUM(((((Materials!E2*0.3)/100)*G2)/5)+(G2/5)*0.025)`.
- Copper!C7/C8: identical additive term plus baseline 1.14 stone / 0.8 glass.
- Tin/Silver C2:C5: identical additive term plus 0.12 for each eligible gem; C6 diamond baseline 0.045.
- Thorium C2:C5: identical additive term plus 0.15; C6 diamond baseline 0.22.
- Copper!G2 = 5000 purchased ore; Materials!E2 = 7; Copper!C6 cached output = 46 diamonds; base without resourcefulness addend = (5000/5)*0.025 = 25. Addend = (5000/5)*(7*0.3/100) = 21; the formula inflates expected diamonds by **84%** (46 vs 25) and adds 21 units **to each of seven independent output rows**, including glass and stone. This is a model arithmetic finding, NOT observed output.
- Copper!K2 `=SUM((C2:C5)/3)` estimates crushing output by dividing gem totals by 3; it omits required Dusk-Shrouded Stone cost in this isolated calculation and should not be copied as a full recipe EV.

## P2 finding: source-model error, not a Retail mechanic

Resourcefulness is an input-cost/ore-saving mechanic. A fixed extra 0.021 output units **for every possible output per nominal cast** is not a valid universal yield model: it ignores the output's base rate, actual saved-input distribution and specialization eligibility. Even if saved ore permits more operations, incremental outputs would need a properly modeled operation count and per-output E, not a flat output increment. The workbook also predicts diamond output without checking ore-specific Proficient Processor unlocks. This calculator can help locate family output names and historical assumptions but is **unsuitable as numeric ground truth** and may materially reverse gold-optimal decisions.

No skill or Inspiration selector exists in these five worksheets; only a Resourcefulness percentage input and ore amount/price controls. No raw cast log, zero-output histogram, sample size, source item IDs or original denominator is embedded. The author's explicit no-specialization caveat prevents promoting the model into skill-adjusted Retail values.

## Previously archived source reuse

The official Blizzard March 31, 2026 qualitative increase in gem frequency (https://worldofwarcraft.blizzard.com/en-us/news/24266320) is already in source-memory; it does not provide a numerical coefficient. The HeadtripVee pre-hotfix six-ore-cohort Reddit table (https://www.reddit.com/r/woweconomy/comments/1sfds1u/did_prospecting_change/) was also already indexed as one original author, and is not a current-patch baseline. Neither is a new independent source this run. Do not merge pre/post-hotfix rates or turn gross ore counts into actual completed casts.

## Outcome

New spreadsheet lineage: 1; independently measured new cohorts: 0; new legitimate mappings: 0; new verified current-Retail P/min/max/E: 0; new substantive negative conclusion: 1 (calculator Resourcefulness output-inflation bug). Revisit only if original underlying data, complete cast logs, or updated patch/skill-specific evidence appears.
