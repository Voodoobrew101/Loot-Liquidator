# Loot Liquidator — Master QA, batch004 (2026-10-28)

**Reviewed live head:** `0438d8858d376dcf69360a50a95195f73cfac573`. **Production GameData.lua blob:** `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`. Research branch only; no main, addon Lua, or TOC writes.

## First-pass acceptance and evidence gate

**150 distinct assigned records accepted for first-pass examination only**, not numerical approval: Midnight 35 Dragonflight overflow; War Within 6 disenchant + 29 Dragonflight; Dragonflight 40; Legacy 40. Source identities, 150 stable keys, assignment disjointness, independent four-field scores, and applicable original GameData line/output IDs cross-checked; **864 in-memory structural assertions passed**, 0 failed.

Scoped universe **1737**, cumulative examined **628**, never examined **1109**, insufficient **615**, blocked **13**, corrected current-Retail outputs **0**, independently substantiated >=90 **0**. New 150 material outputs / 600 field scores: 0 >=90, 0 at 70–89, 600 <70. Cumulative independently scored modern **544 material outputs / 2176 fields**: 0 >=90, **17 at 70–89**, **2159 <70**. Potential source/overlay slots **5392**; complete nonprocessing census remains unfinished. Older five-dimension 6280-slot scorecard cannot substitute for the four independent material fields.

## Source and quantitative findings

- **Midnight worker (35 Dragonflight overflow):** 32/35 overlay lows equal TSM per-ore amount ×5; three Prismatic Ore 194545 low=0 entries are *talent-gating proxies*, not measured impossibility. **190311→192869** historical TSM P proxy **0.0142**, E proxy **0.014** per five ore, min 1 violates E>=P×min by **0.0002**. Preserve original contradiction (rounding/semantics unresolved). Original Bugy Khaz'gorite table labels 100; some rates imply fractional output counts if that means 100 ore, whereas 500 ore yields integral totals. Do **not** assert 100 casts without source confirmation. [Original Wowhead recipe and comment](https://www.wowhead.com/spell=374627/dragon-isles-prospecting).
- **TWW worker (35):** six DE brackets rely on small pooled/borrowed samples (12,4,3,3,1,1); 14 R3 Khaz'gorite anchors and 15 R1 Draconium TSM rows lack current patch/rank/skill. Five-ore E=5×raw TSM per-ore amount passes 15 necessary bounds; raw amount alone would falsely fail. TSM matRate is not independently proven P(at least one).
- **Dragonflight worker (40):** 40 historical TSM bounds pass under five-ore normalization; 12 output-rank triplets share family rates and cannot be added as simultaneously awarded qualities. Six original 2022 beta 5000-ore cohorts lack confirmed completed casts, refunds and per-cast Inspiration joint outcomes; no current Retail formula. [Contemporaneous Wowhead analysis](https://www.wowhead.com/news/dragonflight-jewelcrafting-analysis-wowhead-economy-weekly-wrap-up-249-329385).
- **Legacy worker (40):** 16 original historical PTR milling cohorts, including 14 assigned inputs and two context-only; 26 assigned records have directly related original measurements. Independent histogram checks: Peacebloom 193/78=2.474359, Mageroyal 118/46=2.565217, Khadgar's Whisker 78/22=3.545455. Earthroot source enumerates 29 casts but claims 12 stacks (=48 five-herb equivalents), contradiction unresolved. 11 independent 2015 range-vs-TSM and 9 PTR-extrema-vs-TSM differences are historical, not 2026 corrections. [Alabaster](https://www.wowhead.com/mop-classic/item=39151/alabaster-pigment), [Dusky](https://www.wowhead.com/mop-classic/item=39334/dusky-pigment), [Emerald](https://www.wowhead.com/mop-classic/item=39339/emerald-pigment).

## Parallel numeric mechanics QA

Four disjoint submitted hypotheses independently inspected: **0 VERIFIED_NUMERIC**, **0 approved EMPIRICAL_ESTIMATE**, **4 BLOCKED for compile**. Midnight March 31 2026 hotfix has no matched pre/post cohort or numerical multiplier; TWW Resourcefulness is saved *inputs*, not extra gems; Dragonflight Inspiration needs exact proc-to-quality transitions; Felslate 5-ore standard vs 20-ore mass recipe is qualitatively distinct, not a proven output coefficient. Every candidate has applyPolicy BLOCKED and no executable formula.

**Quarantine:** Midnight numeric candidate assigns `sampleOperations=10` to JD3K's reported **50 ore**, inferred by 50/5. This is *not verified actual casts* and is rejected for numerical scoring; original worker file preserved. Legacy Earthroot cast-denominator conflict also blocks promotion.

Independent static evidence review: 16 Legacy original PTR histogram objects, 3 DF beta observations, four numeric candidate objects and proposed itemdb schema/fixture checked for required fields, integer histograms, denominator conservation and fail-closed policy (**372 independent checks passed, 0 failed**). The repository's Node `test_numeric_rules.js` and full Node suite were **not executed** in this connector-only run. No WoW client tests. No compile or release approval.

## Next work and ETA

Queue revision 7 assigns **150 disjoint never-examined stable keys** (35/35/40 Dragonflight overflow; 40 Legacy prospecting), exact IDs in assignments.json. Last three worker cycles **134, 150, 150** unique records (mean 144.67). Remaining known first pass 1109/144.67≈7.7, or **8 hourly cycles / ~0.33 days** at sustained pace. This excludes incomplete whole-GameData inventory and the much harder all-verifiable-fields >=90 gate, for which ETA is unknown. Gate **NOT MET**. Existing schedules unchanged.
