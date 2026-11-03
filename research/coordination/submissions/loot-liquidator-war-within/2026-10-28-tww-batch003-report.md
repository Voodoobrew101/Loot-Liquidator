# TWW worker batch 003 — 2026-10-28

**Assignment:** `2026-10-28-batch003-war_within`, 35/35 distinct assigned first-pass records (23 The War Within + 12 Dragonflight overflow explicitly delegated by master). All were NEVER_EXAMINED in central ledger at read time. **Master acceptance pending.** No production Lua, main branch, master queue, or shared ledger edits.

## Source-backed findings

**Historical denominator error risk:** [PeaEsk's Algari Prospecting comment](https://www.wowhead.com/spell=434018/algari-prospecting) reports **100 rank-2 ORE** each for Bismuth, Aqirite, and Ironclaw, not 100 measured completed casts. The spell requires five ore. The 13 assigned `GameData.lua` means exactly match reported output totals divided by 20 five-ore equivalents; the existing `samples=100` should not be treated as 100 completed operations. Actual casts/refunds are not stated. No numerical mean replacement is justified. No per-cast hits, zeros or positive conditional min/max were published. Existing Poisson-derived `chance` values are **assumptions, not measured P(at least one)**.

| Input rank 2 (100 ore each) | Published totals | Historical E per five-ore equivalent |
|---|---|---|
| Bismuth 210931 | Amber 35, Pebbles 85, Glass 22 | 1.75, 4.25, 1.10 |
| Aqirite 210934 | Sapphire 20, Emerald 15, Amber 35, Glass 13, Pebbles 35 | 1.00, 0.75, 1.75, 0.65, 1.75 |
| Ironclaw 210937 | Onyx 20, Ruby 13, Amber 33, Glass 11, Pebbles 51 | 1.00, 0.65, 1.65, 0.55, 2.55 |

**Conditional eligibility:** Method's [August 12 2024 prospecting guide](https://www.method.gg/guides/the-war-within-ore-prospecting-guide) says Gem Finding specializations change which gems an ore can yield, and ore quality changes gem frequency. A baseline candidate list is not universally exhaustive; unmeasured rank-1/rank-3 yields must not inherit rank-2 numbers as fact. No numeric specialization multiplier verified.

**Arathor's Spear rank 3 (210810):** compiled empty candidate exists, runtime overlay excludes all 210808–210810. [March 2025 player forum report](https://us.forums.blizzard.com/en/wow/t/inscription-arathors-spear-not-on-milling-list/2083666) supports historical ineligibility, not a verified 2026 recipe probe.

**Dragonflight overflow:** 12 assigned supplemental output rows (Draconium R1 189143 ×5; R3 190311 ×7) exist. Their historical TSM-derived low and inferred high values lack matched skill/quality and independently measured output P/min/max. [October 16 2022 Wowhead analysis](https://www.wowhead.com/news/dragonflight-jewelcrafting-analysis-wowhead-economy-weekly-wrap-up-249-329385) explicitly identifies its October 12 beta-build scope, skill and Inspiration effects, and talent-gated Prismatic Ore; do not transfer beta coefficients to 2026 Retail.

**Null Stone regression:** Previous batch identified the original single-cast source transcription mismatch. No extra Null Stone output credited in this batch.

## Coverage, field confidence, and QA

- 35 unique assigned keys; 13 source output rows + 10 compiled profiles + 12 Dragonflight supplemental rows; 35/35 present, 35/35 ledger status NEVER_EXAMINED at read time.
- 13/13 TWW historical expected quantities matched raw 100-ore cohorts; 3 original-source observations, 13 output totals archived. Source E field confidence 48/100; P, yieldMin, yieldMax each 0. Dragonflight supplemental E confidence 20, other material fields 0. All 35 record worst-field confidence 0, **EXAMINED_INSUFFICIENT**; no ≥90 promotions.
- Structural schema required-field checks, source-line/ID matches, arithmetic checks, no fabricated completed operation counts, no midpoint EV or double P multiplier: PASS. Full external JSON Schema validation and in-game tests: NOT RUN.
- Branch head before work: `8aa97572ea14f13d4b908a150018e04e155c595a`. Source blobs: GameData `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`, StatYieldProfiles `1d80df8304acaa75a5b507089ef163696381b2ff`, assignments `e321fee6581b5d12d58eeec18e4e008a8b81fe2d`, coverage ledger `de00b99312ba376b6a8db0b8c4c9c4f28a5fa957`.

## Master handoff and next targets

Review 35 submitted keys independently before updating master-owned coverage. Investigate `samples=100` ambiguity, ensure gem candidates depend on current Gem Finding ranks, and require a current 2026 build/hotfix-matched cast-by-cast five-ore study including actual completed casts, refunds, skill, talents, gear, output ranks, hit/zero histograms and positive integer min/max. Master preview (NOT self-claimed): `output-supp:dragonflight:190311:192859:7`, `output-supp:dragonflight:190311:192862:8`, `output-supp:dragonflight:190311:192866:9`, `output-supp:dragonflight:190311:192869:10`, `output-supp:dragonflight:190311:192872:11`, `output-supp:dragonflight:190311:192880:12`, `output-supp:dragonflight:190311:194545:13`, `output-supp:dragonflight:190312:192837:0`. Global remaining first-pass count must be recalculated by master after concurrent submissions; do not confuse first-pass with all-fields ≥90 completion.
