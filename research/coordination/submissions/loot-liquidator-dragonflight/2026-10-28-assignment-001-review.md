# Dragonflight worker — assigned batch 001: 36-key independent research audit
Date: 2026-10-28. Branch: `research/processing-confidence`. Assignment: `2026-10-28-init-dragonflight-001`. **Worker-owned evidence, not master-accepted ledger or production itemdb.lua.**

## Work completed
- Examined all **36 distinct master-assigned stable keys**: **24** Rank-2 Draconium Ore (item 188658) historical TSM prospecting output rows and **12** Dragonflight milling runtime-overlay keys (four herb families, three input ranks each). Historical source actually contains **36 milling quality-specific output rows** behind those 12 overlay keys; preserved all 36 in the raw observation archive.
- Parsed exact live `GameData.lua` rows and `StatYieldProfiles.lua` overlay algorithm, tested the **24 prospecting** candidates for `p*min <= 5*amountOfMats <= p*max`, and tested **12 milling** inputs for contradictory quality-rank aggregation.
- No independently verified current-Retail probabilities or output counts were found for these exact patch/skill/rank cohorts. **No field promoted to >=90, no production correction, no fabricated new observation.** All 36 should be treated `EXAMINED_INSUFFICIENT` pending master QA, not counted as accepted until reviewed.

## Findings and source cross-check
1. **Prospecting batch confirmed:** Dragon Isles Prospecting spell 374627 consumes five Dragon Isles ores per operation; Wowhead describes a historical player comment with Draconium Ore sample of 2,000 ore and reported JC 122 skill, 15 Enterprising/25 Prospecting, but the comment's output columns are not reliably aligned to all 24 exact rank-specific IDs here. Do **not** transfer its rates to these rows. Source: https://www.wowhead.com/spell=374627/dragon-isles-prospecting
2. **Input quality:** Draconium Ore 188658 is Rank 2; other ranks include 189143 (Rank 1) and 190311 (Rank 3). Source: https://thewowdb.com/item/draconium-ore-189143/ and https://www.wowhead.com/item=188658/draconium-ore
3. **Historical prospect rows:** all 24 tested inequalities pass when `E_candidate = 5 * amountOfMats`. This is a **dimensional interpretation of legacy TSM-like data, not proof of observed mean**. Original sample count, date, profession stats, quality thresholds and source algorithm are unavailable. TSM `matRate` is not independently confirmed to be P(at least one per cast). Source of raw values: https://github.com/Voodoobrew101/Loot-Liquidator/blob/main/GameData.lua
4. **Milling mappings externally corroborated:** Hochenblume -> Shimmering, Saxifrage -> Blazing, Bubble Poppy -> Serene, Writhebark -> Flourishing. The Dragon Isles Inscription guide describes **2–5 pigments per five herbs**, but not a measured rank-specific distribution. Sources: https://www.wow-professions.com/guides/dragon-isles-inscription-leveling-guide-dragonflight and https://warcraft.wiki.gg/wiki/Pigment and https://www.wowhead.com/item=198422/shimmering-pigment
5. **Twelve critical rank-aggregation traps:** each of the 12 TSM herb inputs contains THREE target-quality output rows, each with `matRate=1.0` and `amountOfMats=0.7`. Treating all three quality ranks as simultaneous independent unconditional yields implies **3*3.5=10.5 pigments per five herbs**, exceeding the cited guide's 2–5 total. This flags **quality-conditional source duplication**, not evidence that the guide or TSM is numerically wrong under its original unstated conditions. Never sum those three rows or price all three as if guaranteed. Source: GameData.lua exact input rows.
6. **Overlay model is not measured:** `StatYieldProfiles.lua` filters to `targetQuality==1`, sets `low=0.7*5=3.5`, `high=3.5*1.24=4.34`, and generates occurrence proxy approximately **0.7** (despite the original TSM `matRate=1.0`). No independent source was found for the universal 1.24 factor or rank-one-only output selection across all skill contexts. Preserve these as legacy provisional behavior, not verified skill scaling. Source: https://github.com/Voodoobrew101/Loot-Liquidator/blob/main/StatYieldProfiles.lua
7. **Skill and patch dependence:** a historical community experiment reports Draconium and Serevite prospecting at different skills and notes strong skill/quality effects. This corroborates the need for condition-specific cohorts, not any universal coefficient. Source: https://www.reddit.com/r/woweconomy/comments/y3e8ek

## Per-field confidence (evidence strength, not statistical accuracy)
- Prospect 24: `P=25, min=30, max=30, E=30`, record weakest **25**. Legacy TSM-like rates and bounds have no primary sample context.
- Mill 12 runtime-overlay selections: `P=10, min=30, max=30, E=30`, record weakest **10**. Probability is inferred, rank1 is selected unconditionally, and high profile is modeled.
- All 36 below 70; zero >=90. Confidence numbers are conservative audit judgments, not empirically measured error probabilities. These scores are **worker proposals only**, pending master independent review.

## Executed deterministic checks
```json
{
  "assignmentKeys": 36,
  "distinctKeys": 36,
  "oreAssigned": 24,
  "oreInvariantPass": 24,
  "millInputs": 12,
  "millTSMRankRows": 36,
  "millRankSumContradictions": 12,
  "oreInputQuality": 2,
  "uniqueInputIDs": 13,
  "allMissingOriginalCohort": true,
  "allScoresUnder90": true
}
```
The numeric inequalities are consistency checks only; passing them is NOT external validation. No WoW client, actual player cast capture, or production regression test was executed.

## Next assigned targets and blockers
- First: master should review this submission and mark the 36 assigned stable keys examined (not verified) in the central coverage ledger; do not update master-owned files from this worker.
- Next: `output-main:tsm:prospect:188658:192862:L1198`, `output-main:tsm:prospect:188658:192863:L1199`, `output-main:tsm:prospect:188658:192865:L1200`, `output-main:tsm:prospect:188658:192866:L1201`, `output-main:tsm:prospect:188658:192867:L1202`, `output-main:tsm:prospect:188658:192868:L1203`, `output-main:tsm:prospect:188658:192872:L1207`, `output-main:tsm:prospect:188658:192880:L1208` (8 previews) and additional unexamined Dragonflight quality-rank outputs. Investigate whether TSM `matRate` and `amountOfMats` are per-resource or per-operation for each source version; capture real quality-conditioned rank probabilities and zero-inclusive histograms from 5-ore/5-herb casts.
- Blockers: original historical TSM source/version/sample denominator; exact character skill/gear/specialization and patch; rank-specific hit operations; empirically validated low-to-high coefficients. Never coerce these unknowns to zero or pretend a historical source is current Retail.
- Source files checked: `GameData.lua` blob `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`, `StatYieldProfiles.lua` blob `1d80df8304acaa75a5b507089ef163696381b2ff`, master queue blob `ce9613d0598642f628cb01d435d7f5d6e8cc3f0f`. No main branch modifications.
