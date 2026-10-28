# Northrend Cobalt and Titanium prospecting source audit — 2026-10-28

## Sources and exact scope
- Main GameData.lua SHA `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`, source rows `gd.tsmRetail.prospect[36909]` and `[36910]` around lines 886–919.
- `research/ledger/tsm-invariant-anomalies.csv` 40 previously flagged rows; `research/ledger/titanium-observed-yields.csv` holds 12 historical observations. No changes to either original ledger.
- Community/encyclopedic: https://warcraft.wiki.gg/wiki/Cobalt_Ore — 5-ore Northrend Prospecting; 24–25% of each uncommon gem, 1–2 conditional items; last retrieved 2026-10-28 (wiki does not establish 2026 Retail matched conditions).
- https://warcraft.wiki.gg/wiki/Titanium_Ore — each uncommon ~25%; each rare ~4%; each epic ~5%, class-specific/current-patch eligibility still unverified.
- https://warcraft.wiki.gg/wiki/Prospecting — generic five-ore operation; histories and exceptions.
- Historical observed Titanium source reports: https://www.reddit.com/r/woweconomy/comments/s6bfrl/ (2022 Retail; 200 operations) and https://www.wowhead.com/wotlk/item=36910/titanium-ore (2023 Classic PTR; 1,000 operations); condition mismatch means do not promote to 2026 Retail rates.
- Additional read-only TSM code lead: https://github.com/Xurkon/TradeSkillMaster/blob/main/TradeSkillMaster.lua uses conversion `rate` times output price, which suggests expected unit conversion fields matter; repository is not proved to match the precise historical raw `matRate`/`amountOfMats` original export. Denominator/meaning remains unresolved.

## Independent original-line math
Six uncommon output IDs `36917,36920,36923,36926,36929,36932` each appear for both inputs, 12 conflicting source rows.
Original data for EACH: `matRate = 0.235`, `minAmount=1`, `maxAmount=2`, `amountOfMats=0.5` per original ore. Under five-ore cast and interpreting matRate as P(at least one) per operation:
- Unconditional E implied by amountOfMats = `0.5*5 = 2.5` output units per operation.
- Maximum E permitted by 23.5% occurrence and conditional max=2 is `0.235*2=0.47`, minimum `0.235*1=0.235`.
- Derived E / mathematical upper bound `2.5/0.47 = 5.319148936` for each; sum six 15 units per operation against sum individual upper bounds 2.82. This is a source-semantics contradiction, NOT evidence of a second multiplication in ConversionEngine.lua.

Historical Titanium 2022 Retail 200-cast observed uncommon means are `0.265,0.220,0.245,0.265,0.235,0.295`; aggregate 1.525 per cast; separate 2023 WotLK Classic PTR means `0.250,0.263,0.253,0.255,0.227,0.250`; aggregate 1.498. Those cohorts DO NOT measure 2026 Retail cast occurrence probabilities, per-hit distribution or precise quality/skill conditions. Their independent agreement supports blocking the anomalous 2.5-per-item estimate, not writing a current-patch factual replacement.

## Research proposal (NOT an addon edit)
- Preserve original TSM source tuple and every output ID, in separate source evidence fields. Never silently rewrite `amountOfMats` to `matRate` or make up a new expected quantity.
- Tag twelve risky rows `BLOCK_UNVERIFIED_TSM_E_FOR_ECONOMIC_RECOMMENDATIONS` in separate research ledger `research/ledger/tsm-northrend-quarantine-proposal-2026-10-28.csv`. The word “block” is an **integration proposal** only; current production runtime is NOT yet gated and can use these values.
- Keep actual 2022 Retail and 2023 Classic PTR sample means as version-stratified historical evidence. Match patch, skill, recipe, gear, and input conditions before adoption. If no current-patch data, display source-labelled provisional estimate only, with separate inferred chances/ranges, and do not represent invented 90+ evidence.
- A conservative one-baseline future `itemdb.lua` must rank verified contextual samples above unverified TSM and return one coherent model to tooltip and pricing. Unknown coefficients must not silently equal 1.0.

## QA and confidence
- Static source test: `research/tests/test_northrend_tsm_anomalies.js`, run on fetched main/GameData.lua; nine checks passed, zero failed; 12/12 target rows flagged.
- Source-based cross-check: 6 output IDs x 2 inputs; alternate historical cohorts not patched together. Valuation expected units and probability kept independent.
- Original 1,256-row source output ledger scores unchanged (>=90 0, 70–89 0, <70 1,256, lowest 0); twelve risky rows corrected in *proposed disposition only*, not upgraded scores or production data. Source semantics confidence below 70; no new chance/range/expected value can honestly earn 90.
- In-client testing not performed. No Lua addon files or main branch changed.

## Next test prioritization
1. Locate original TSM conversion data exporter meaning of `amountOfMats` vs `matRate`; establish denominator from actual implementation, not a copy of comments.
2. Current Retail observed per-cast zero-inclusive records for Cobalt and Titanium at matched skill and exact 5 ore; verify output quality eligibility.
3. Audit other 28 historical TSM anomalies, particularly milling input 200061, ore 123919 and 0.0002 precision discrepancies; do not automatically assign the five-ore batch to Dragonflight milling.
4. Repeat no-silent-overwrite static migration checks; maintain separate evidence/confidence for chance, min, max, unconditional E and conditions.
