# Loot Liquidator — War Within Batch013 research submission

**2026-10-28; queue revision 15; research/processing-confidence; starting SHA `f3c658ff832885762a8485832446c620be87895e`.** Exact **35/35** assigned keys independently source-matched: 8 smelt recipes, 13 TWW R2 ore outputs, 14 Dragonflight overflow outputs. 0 newly confirmed mappings inside assignment, 0 new current Retail unskilled measurements, 0 fabricated numeric cells. The companion JSONL reports all four fields per key and provenance.

## P0 mapping and eligibility
Eight already-known smelts have full reagent vectors and fixed outputs; all are blocked by recipe-aware compiler/eligibility representation. Fel Iron spell 29356 consumes only 23424×2 (one reagent type); Bronze 2659 produces two bars; the other seven produce one. These 32 fixed numeric field claims are existing conditional recipe data (80/100 evidence support), NOT new measurements. Never value a multi-reagent craft as though one reagent pays its entire cost. New unassigned discovery lead: Null Stone 210939 has a prospecting recipe and an empty candidate-only GameData profile; Handful of Pebbles 213398 is prospectable. Request master assignment, no unassigned credit.

## P1 four-field audit
- 13 TWW R2 rows: retain PeaEsk historical per-five-gross-ore references (48/100), but all 13 P, 13 min and 13 max unknown; 100 ore != 100 casts; Poisson P unmeasured.
- 12 Dragonflight rank-specific rows: recommend 12 P and 12 E UNKNOWN rather than triple-valuing alternative quality ranks; keep historical family values only in provenance, 24 source positive-range claims at 32/100. This is a separate prospecting instance of master-approved batch012 rank-exclusivity correction.
- 2 Dragonflight unranked rows: historical TSM P/E and positive bounds retained as low-confidence source proxies (34/32), not current patch, not unskilled.
- 8 smelt recipes: fixed per-successful-cast P=1, min=max=E=1 (except Bronze=2); 2026 live recipe skill/forge/learned availability not tested.

## P2 decision-risk calculation
For R2 Aqirite, PeaEsk minus Oct14 2024 is **0.5125 glass + 1.3875 pebbles per nominal five ore**. With AH cut 5% and unit prices G (glass), P (pebbles), the difference in estimated gross sales is **0.95 × (0.5125G + 1.3875P)**, before deposits/time. This could reverse Auction vs Prospect but is NOT a verified current-price flip. Source conditions and patch are unmatched; no universal hotfix multiplier.

## Source memory, QA, and next targets
Reused PeaEsk (one original study/three cohorts), Oct14 Aqirite (one original cohort), 8 previously reviewed smelt recipe sources and TSM archive; avoided 8 redundant spell fetches. One newly identified primary lead (Adreymar mixed 50k ore), not promoted to rank-specific output. 35 unique stable keys and source identities; 8 smelt fixed arithmetic checks, 13 PeaEsk total/20 checks, 12 rank-quarantine checks and 2 unranked TSM necessary-bound checks passed. No full Node/Lua/WoW client testing. No main/production, master queue/ledger, source-memory or schedule edits.

**Next master targets:** 210931/210934/210937 → 213398,213399,212498,212505,212508,212511,212495 with posthotfix cast histograms; 188658→192865–192869 and 189143→192837–192843 exact rank probabilities; 188658→192872,194545 source units; eight smelt spell learned/forge eligibility. Assign 210939 and 213398 prospecting output inventories to a worker explicitly. Master baseline **976 provisional mappings, 840 four-field complete, 294 unknown cells** remains unchanged pending QA; independent exhaustive Retail-universe coverage NOT COMPLETE. Evidence confidence is support strength, not a measured probability of correctness.
