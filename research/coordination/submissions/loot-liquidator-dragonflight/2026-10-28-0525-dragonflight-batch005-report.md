# Dragonflight worker — Batch 005, 2026-10-28 05:25 PDT

## Assignment and boundaries
- Live master queue revision **7**, assignment **2026-10-28-batch005-dragonflight**, source queue blob `900e39560b02afaea5ed8657d5490df814f7ca2d`.
- **40/40 distinct assigned stable keys** reviewed: 16 Khaz'gorite R3 (input 190314, source lines 1384–1399) and 24 Serevite R3 (input 190394, lines 1402–1425). This is worker first-pass submission, **not master-accepted coverage**.
- Existing source `GameData.lua` blob `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`; source fields read only. No changes to production or central ledgers.

## Evidence and field-level QA
All 40 assigned rows match the exact line and output ID in actual GameData.lua. Historical TSM tuples are normalized once: `E per five ore = 5 × amountOfMats`; `matRate` is treated as a historical occurrence **proxy**, not measured P(at least one). Necessary bounds `0<=p<=1`, `min>=1`, `min<=max`, and `p*min<=E<=p*max` pass **40/40**. This is arithmetic compatibility, NOT probability or Retail validity. Actual cast samples, zero-inclusive histograms, original TSM unit contract, source patch/build, skill/spec, gear and verified output rank selection are unknown. Each row retains four independent provisional scores: P=25, min=30, max=30, E=30; weakest=25, no ≥90 records. Full 40-row audit: `2026-10-28-0525-dragonflight-batch005-40key-audit.csv`.

**Rank duplication:** 12 complete three-rank groups in this assigned slice repeat the same historical p/mean/min/max for all three output quality IDs. They must not be valued as simultaneous independent gem results. Example Serevite 190394 → IDs 192837/192838/192839 each carries E=0.126 per five-ore equivalent; adding all three as guaranteed independent outcomes would count 0.378 with no verified quality selection. No corrected numeric baseline proposed.

**Item ID verification:** 190314 is Khaz'gorite R3 (https://thewowdb.com/item/khaz-gorite-ore-190312/). 190394 is Serevite R3 even though its numeric ID is lower than R1 190395 and R2 190396 (https://github.com/t-mart/wow-auction/blob/master/README.md). Do not infer rank from ID order.

## Parallel mechanics hypothesis (1; separate from 40 item rows)
**ID:** `dragonflight-inspiration-quality-transition`. **Result: BLOCKED for current-Retail numeric application.** Blizzard's official 2024 pre-expansion notes explicitly say Inspiration was removed and Concentration/Ingenuity introduced: https://worldofwarcraft.blizzard.com/en-us/news/24119590/the-war-within-pre-expansion-content-update-notes. The October 2022 beta study (https://www.wowhead.com/news/dragonflight-jewelcrafting-analysis-wowhead-economy-weekly-wrap-up-249-329385, original https://www.reddit.com/r/woweconomy/comments/y3e8ek) reported skill 68/113/228 and 5,000 rank-3 ore per cohort, but lacked exact cast-level Inspiration flags, zeros, output quality histograms, skill/spec/gear matched controls, and known beta build. Its article also states conflicting +63 versus +83 skill for highest-quality ore. Historical beta thresholds/83-skill Inspiration cannot be applied to 2026 Retail.

The official removal is strong qualitative evidence, **not** proof of the exact present-day Dragonflight prospecting rank distribution. Exact recipe-specific current-Retail API probe remains necessary. Proposed candidate is `VERIFIED_QUALITATIVE / BLOCKED`, null formula and zero approved coefficients.

## Independent tests and blockers
- 40 exact-key/line identity checks, 40 necessary probability/mean bounds, 40 source-quality=3 checks where tagged, 12 complete duplicate-rank triplets; static assertions recorded in validation JSON. No external JSON Schema, Node harness, or in-game client tests executed.
- Missing: original TSM conversion source denominators, observed hit counts and conditional integer yields, current patch applicability, full output eligibility and current recipe-specific quality transition.
- **Next exact targets:** live Retail 12.x prospecting of Khaz'gorite R3 190314 and Serevite R3 190394 (five ore per operation), recording build, recipeSpellID, child skillline, skill, spec node ranks, equipped gear, effective stats, exact output rank IDs, per-cast zeros/hits/positive quantities and ore refunds. Independently compare at least two controlled skill contexts; do not assume 2022 beta Inspiration exists. Obtain original TSM historical native rate-unit definition and output-rank conditioning. Follow master's next disjoint queue, not another worker's IDs.

## Master handoff
40 first-pass records submitted; 0 ≥90, 0 verified numeric mechanics, 1 blocked hypothesis. Master review/coverage acceptance pending. No main, GameData.lua, TOC, central progress, assignments or registry changes.
