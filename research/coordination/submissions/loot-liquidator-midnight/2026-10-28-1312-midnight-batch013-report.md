# Loot Liquidator Midnight — Batch 013 research-only report

**Date:** 2026-10-28 · **Queue:** revision 15, 2026-10-28-batch013-midnight · **Branch:** research/processing-confidence

## Assigned P0/P1 coverage
All **35/35 exact assigned stable keys** audited: 16 Midnight Crushing gem-rank input candidates, 1 Dusk-Shrouded Stone Refining recipe, 14 Midnight prospect output source rows, 3 overlapping Midnight condition records and 1 Dragonflight overflow TSM row. **14/14** source-line output IDs independently matched main GameData.lua. Source profiles are not new output records.

**Crushing 1231132:** effect salvage count 3; 3 eligible Midnight gems plus 1 Dusk-Shrouded Stone, candidate reagent ranks 242788/242789. Gemdust output quality IDs 242620/242621; output quality transition, exact per-gem eligibility, stone reagent rank, per-cast P and E remain UNKNOWN. The 16 prior gem input IDs were rechecked as a family; none independently demonstrated as a new exact output row. Secondary guide claims **1–3 Gemdust per operation** without original cast data; this is family-level range guidance only (provisional confidence 45), not per-rank P/min/max/E. One-gem-to-stone claim remains UNCONFIRMED, without a spell ID.

**Refining 1307466:** corroborated fixed recipe **18× 242788 -> 1× 242789**, trainer skill 50, Jeweler's Bench/Tools, patch 12.1.0+. Proposed fixed-recipe P=1, positive min=max=1, unconditional E=1 (four pre-existing provisional field claims, 86/100), **not four newly measured cells**. Recipe-aware compiler and live client confirmation remain blockers.

**Prospecting:** 14 exact GameData source lines validated. 10 exact-context rows including 3 condition aliases have historical JD3K aggregate means, not independently observed per-cast E; count aliases only once. R1 rows retain explicitly low-confidence transferred R2 estimates. All prospect P(hit), positive min/max and current-patch baseline remain UNKNOWN. The assigned Dragonflight TSM 189143->192844 row retains historical source min=1,max=3 (35/100) but matRate/amountOfMats normalization is unresolved; no fabricated P or E.

## P2 decision risk
- For Crushing, value Gemdust by **rank-specific unconditional E** only when supported, subtract all **3 gem + 1 stone** input costs, account for Resourcefulness separately. Do not multiply E by P or price both output ranks at their family aggregate yield.
- Cardinalai's reported **330/480=0.6875 Gemdust per gross gem** and the new July max-spec anecdote **0.83925 per gem** differ ~22% but are unmatched and do not prove a skill coefficient or current neutral baseline.
- Refine cost is **18 lower-rank stones**; treating it as a one-stone conversion could reverse a gold recommendation. No actual live Auction-vs-Crush or Auction-vs-Refine flip was calculated because current item prices and rank-conditioned yields are unavailable.

## Actual contribution / master handoff
- **New exact legitimate output mappings:** 0. **New verified 2026 Retail neutral numeric fields:** 0. **Reconfirmed provisional deterministic refine fields:** 4 (not new). **New independent cast cohorts:** 0. **New original anecdotal source lead:** 1. **Existing original cohorts reused:** 2. **35 exact assigned records audited**, not 35 new coverage entries.
- **Master action:** retain 16 Crushing families as schema-blocked candidates, add full reagent vector and quality/learned-recipe gating; preserve 18-to-1 Refine as deterministic; test all 16 gem IDs/ranks and both stone qualities in-client; collect actual per-cast Gemdust rank histograms with zeros, skill, specialization, gear and patch; inspect TSM source unit semantics for 189143:192844.
- **Master baseline (pre-review):** 976 staged mappings / 159 inputs, 840 four-field source-complete provisional mappings, 294 unknown numeric cells, independent exhaustive Retail audit NOT COMPLETE. No production Lua/TOC, main, shared ledgers, master assignments, registry, source-memory or schedule changed.

**Evidence confidence** measures strength of support (0–100), not the probability a number is correct. Full repository Node/Lua/client suites were not run.
