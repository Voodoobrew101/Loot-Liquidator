# Master QA batch012 — provisional compiler v0.2.0, material-first review
2026-10-28 · research/processing-confidence ONLY · production unchanged · queue revision 15

## Independent acceptance and source lineage
All four worker submissions were read and their **150 distinct exact assigned keys** matched queue revision 14 (Midnight 35, TWW 35, Dragonflight 40, Legacy 40). **148/148 records with a GameData source line** independently matched the exact output ID on the pinned main GameData blob `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`; two TWW Crumbled Stone records have no source line and remain identity/quality unresolved. These are **material audits, not 150 new output mappings or 150 new first-pass keys**. No current 2026 unskilled per-cast measurement was verified.

**ACCEPT** Legacy's new `Prospect:36910:46849` Titanium Ore → Titanium Powder mapping, confirmed on original Retail Wowhead item page https://www.wowhead.com/item=46849/titanium-powder . Globalmenace's original **Retail 12.0.5** report gives 143 powder / 1000 gross ore = **0.715 per nominal five-ore equivalent**. This is a provisional aggregate E reference (62/100), not observed per-cast E; actual completed operations, P(hit), positive bounds, patch 12.1, skill and spec remain unknown. A separate historical 2022 study and older Wowhead authors are **independent historical cohorts**, not current-patch replications. Original 12.0.5 price example with 5% AH cut changes historical gem-only net **-47,502.25g** to powder-inclusive **+19,732.63g** (assumes sell-through, excludes deposits/time); not a live quote.

**ACCEPT / CORRECT** Dragonflight's 31 quality-specific milling rows: historical TSM P=1 and E=3.5 are **family proxies**, not independent measured values for each of R1/R2/R3. The compiler now retains the 31 legitimate output IDs and positive historical range proxies but sets their **31 rank-specific P and 31 rank-specific E cells UNKNOWN**, preserving original source claims and independent worker audit IDs. This prevents a false 10.5 total pigment per five-herb cast from three simultaneous 3.5 rank values. No 2026 rank/skill coefficients approved. Original historical sources: https://www.reddit.com/r/woweconomy/comments/10me1e7 and https://www.wowhead.com/news/crafting-work-orders-are-here-wowhead-economy-weekly-wrap-up-251-329620 .

**ACCEPT CONDITIONAL ELIGIBILITY** for seven Midnight Eversong Diamond source mappings: Proficient Processor ore-specific nodes are required. No fake P=0 or E=0 for an unspecced character. Current output remains provisional and must be gated by actual character specialization in a future approved runtime migration. Independent corroboration: https://www.wowhead.com/guide/midnight/professions/jewelcrafting-specializations and https://www.wow-professions.com/midnight/jewelcrafting-guide .

**ACCEPT AS GAPS, NOT COMPILED OUTPUT ROWS** Midnight Crushing spell 1231132 with 16 gem-rank input-family candidates and one Dusk-Shrouded Stone additional reagent; exact gemdust rank distribution is unknown. Refine Dusk-Shrouded Stone spell 1307466 is documented as 18 rank-1 stones to one rank-2 stone with Midnight Jewelcrafting skill 50, but the current candidate schema cannot represent explicit recipe learned/bench/tool conditions. Keep the 17 candidate recipe entries in the mapping-gap ledger rather than fabricate single-input valuations. Original recipe records: https://www.wowhead.com/spell=1231132/midnight-crushing and https://www.wowhead.com/spell=1307466/refine-dusk-shrouded-stone .

**CORRECT** TWW worker's Fel Iron recipe 29356: one reagent type (23424 ×2), not multi-reagent; still requires recipe-aware schema. Seven other documented smelts are multi-reagent or otherwise recipe-gated. **REJECT** treating 100 TWW ore as 100 completed casts, Poisson P=1-exp(-E) as observed, Dragonflight quality alternatives as simultaneous, or Crumbled Stone aggregate output as a specific quality rank. Source-specific historical values stay archived.

## Actual compiler rebuild and readback
Compiler `research/tools/compile_itemdb.js` v0.2.0 executed in an isolated JavaScript V8 environment using exact live GitHub file contents; no Node CLI runtime available. Staged `research/proposed/itemdb.lua` byte-for-byte matched a second deterministic rebuild after GitHub write and readback. Compiler checks **1194** GameData source-line identities; field bounds, duplicates and rank guards were validated. No Lua interpreter load test, repository Node CLI suite, or live WoW client test was executed.

- **976** provisional input/output mappings, **159** distinct input IDs; known source compiler-admitted mapping set represented. Independent exhaustive Retail-universe audit: **NOT COMPLETE**.
- **840 / 976** complete four-field numeric tuples (**86.07%**), all provisional; **938 / 976** expectedQuantity present. **294** unknown cells among **3904** field slots: P **120**, min **68**, max **68**, E **38**.
- **1** new legitimate output mapping accepted; **62** unsupported rank-specific numeric cells intentionally quarantined; **7** explicit specialization eligibility gates; **0** current Retail neutral-baseline verified records; **0** independently established ≥90 complete records.
- **62** older excluded source candidates remain: 52 generic DE inputs, 8 smelt recipes, 1 self-return/refund, 1 token choice. Separate 17 new recipe-family/skill gap entries; do not count these as compiled mappings.
- Source fields preserve status/confidence, original source claim IDs, blockers, patch context and unverified eligibility in the generated Lua. Gold valuations must use only unconditional E and never P×E or range midpoints.

## Worker QA and next assignments
- Midnight: 35/35 exact field audits; 7 diamond eligibility gates; 10 original rank-2 aggregate E corroborations but no per-cast histograms; 17 missing recipe candidates. Next **35**: 17 recipe candidates, 17 other Midnight source rows, 1 Dragonflight overflow.
- War Within: 35/35 exact keys; 8 smelt recipe vectors, 13 TWW source rows and 14 other modern outputs. Next **35**: 8 smelts, 13 unresolved TWW source rows (explicit repeat, **not new coverage**), 14 Dragonflight overflow.
- Dragonflight: 40/40 exact output keys; 31 rank-specific proxy pairs rejected as measured, 2 historical Serevite E cohorts independently reported but not same patch/rank. Next **40** distinct modern material rows.
- Legacy: 40/40 exact keys; 30 TSM contradictions, 7 BfA proxies, 6 historical Titanium uncommon means; one **new** omitted powder mapping independently accepted. Next **40**: powder current-context verification plus 39 distinct Legacy rows.

Queue revision 15 assigns 150 disjoint exact keys. Old first-pass **1643/1737** and 94 remaining source profiles remain unchanged; this is not an exhaustive Retail-universe denominator. No reward scores were used as confidence. Source-memory Node rebuild is still outstanding; new source-review events and feedback are preserved in GitHub and must be replayed before declaring the cache current.

## Gold-impact priorities and test blockers
1. Titanium Powder omission historically reversed an Auction/Prospect decision; obtain current price and actual 2026 cast/skill sample.
2. Dragonflight three-rank pigment E could triple count outputs; require zero-inclusive rank-specific cast outcomes and matched skill.
3. Midnight Diamond eligibility can reverse the recommendation; check actual specialization nodes per ore.
4. Midnight Crushing and Refining require full reagent-vector cost, skill and output-rank model; no one-input shortcut.
5. TWW post-hotfix prospect byproducts need real completed casts and character/patch context; historical gross-ore ratios are not current coefficients.

No production addon, main, TOC, releases, PR #3 or automation schedules changed.
