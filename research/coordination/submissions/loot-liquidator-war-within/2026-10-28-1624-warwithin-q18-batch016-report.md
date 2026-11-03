# Loot Liquidator TWW — Batch016 / queue18 (2026-10-28)
Research-only worker submission; branch `research/processing-confidence`. Assignment `2026-10-28-batch016-war_within`.

## Verified scope
- 35/35 exact queue18 assigned stable keys; 8 master-admitted conditional Gem Finding candidates, 13 compiled R2 TWW prospect rows, 5 Dragonflight fish-mill overflow and 9 Dragonflight Draconium TSM overflow.
- 27/27 pinned GameData source lines independently matched item IDs; 140 field slots reviewed; 41 **reused provisional numeric** fields (13 historical nominal-five-ore E, 28 TSM positive min/max range proxies), 99 unknown; zero new 2026 cast-based numeric promotions.
- No new approved mapping. Master batch015 had already admitted the eight specialization-conditional mappings. All remain conditional on specific Gem Finding nodes; no character is assumed to have learned them.
- No production files, canonical registry, assignments, master ledger or source-memory cache touched.

## P0: two independently authored original historical cohorts indexed in one source thread
Original thread: https://www.reddit.com/r/woweconomy/comments/1fisfkn (published 2024-09-17). These are **two independent player commenters/cohorts in one discussion**, not two independent source URLs, and are not new current-Retail experiments.

**Ironclaw R1 item 210936:** 10,000 initial ore, 135 effective JC skill, 17% Resourcefulness, 30/30 Shaping, 40/40 Gem Finding, 20/20 Emerald and Sapphire, 0/20 Ruby and Onyx. Author recycled refunded ore; completed casts unreported. Raw totals: Emerald 394, Onyx 298, Ruby 310, Sapphire 382, Pebbles 1130, Glass 336, Crushed Gemstones 192, Amber 0. Nominal five-initial-ore references: Emerald 0.197, Onyx 0.149, Ruby 0.155, Sapphire 0.191, Pebbles 0.565, Glass 0.168, Crushed 0.096. Zero Amber is observed for this historical sample, **not** a current probability of zero.

**Aqirite R1 item 210933:** 10,000 ore reported, 70 total JC skill, zero Shaping, 5% Resourcefulness. Original commenter totals: Emerald 312, Sapphire 297, Pebbles 1045, Glass 332, Amber 593. Nominal five-ore references: Emerald 0.156, Sapphire 0.1485, Pebbles 0.5225, Glass 0.166, Amber 0.2965. No Ruby/Onyx counts were reported; **do not write zero** for unmentioned outputs.

The two independent cohorts report similar nominal byproduct totals: Pebbles 1130 vs 1045 (8.13% difference relative to Aqirite), Glass 336 vs 332 (1.20%). This corroborates the *possibility* of shared byproduct behavior, **not** a universal coefficient or a controlled test: ores, skills, specialization and refund handling differ.

**Crucial denominator distinction:** initial ore / 5 = 2000 *nominal* operations, not observed completed casts. These gross-ore ratios are not unconditional per-cast expectedQuantity. Output ranks are not recorded; no P(hit), positive min/max or 2026 E can be promoted. Both observations are schema-shaped JSONL source-only records with null actual casts.

## P0: Gem Finding and hotfix epoch guard
- The previously reviewed Method 2024-08-12 guide says selecting Emerald can replace an Amber chance on Bismuth with an Emerald; extra conditional gems must **not** be valued as independent additions to an unchanged Amber baseline. Exact unlock threshold for each named gem remains unverified.
- A newly indexed **2024-09-17 original bug report** describes 40/40 Gem Finding and 20/20 all four gem nodes, with no Amber after thousands of ore. It is a historical player report, not proof of P(Amber)=0.
- The official **2024-10-25 hotfix** explicitly repaired the 40/40 Amber byproduct and changed gem/byproduct outcome mechanics. Therefore neither September cohort can establish current-Retail yield, even if the two historical byproduct totals agree.
- Source links: https://www.method.gg/guides/the-war-within-ore-prospecting-guide ; https://us.forums.blizzard.com/en/wow/t/tww-jewelcrafting-shaping-and-prospecting/1958770 ; https://worldofwarcraft.blizzard.com/en-us/news/24148555/hotfixes-october-25-2024

## P1/P2: assigned row safety
- All 13 compiled TWW R2 rows retain earlier PeaEsk historical nominal-five-ore E. The GameData `1-exp(-E)` occurrence values are Poisson proxies, not observed P(hit); no positive yield bounds supported.
- All 8 specialist R2 outputs keep P, positive min/max and unconditional E unknown. Historical R1 cohorts **cannot** be transferred to R2, and September/October 2024 cohorts cannot be used as post-hotfix 2026 rates.
- Five Prismatic Leaper and nine Draconium TSM overflow rows retain only **historical TSM min/max reference ranges**. Their exact-rank P and E are unknown; no rank-duplicated family expected yield was admitted. Fish has no input quality rank.
- Gold-risk: conditional gem outcomes may displace Amber. Correct comparison is `EV_specialist - EV_baseline` with mutually exclusive gem outcomes and source-backed joint distribution, not `EV_baseline + sum(specialist E*price)`. No current AH action flip can be established.

## Source-selection learning and next exact targets
- **NEW** primary thread https://www.reddit.com/r/woweconomy/comments/1fisfkn, two independent original commenters; no new current-Retail cast histograms. **NEW** player bug report, qualitative only.
- **REUSED** Method guide, 2024-10-25 official hotfix, Sept 3 1040-clicks Aqirite source https://www.reddit.com/r/woweconomy/comments/1f83cnd and old PeaEsk/TSM rows. The 1040-clicks source is already indexed in source-memory and was not counted again.
- Avoided repeated fetches of 8 smelting recipe pages, PeaEsk source, old TSM source profiles. New source review events preserve source lineage and blockers; reward points do not change confidence.
- Next exact assigned TWW keys: `candidate:conditional:prospect:210931:212495:gem-finding:20261028`, `candidate:conditional:prospect:210934:212495:gem-finding:20261028`, `compiled:prospect:210934:212498:L428`. Require 2026 zero-inclusive cast histograms stratified by R2 ore, each node state, skill, gear, Resourcefulness and patch; determine actual Amber replacement versus additive effects.
- Master baseline at read: **994 provisional mappings, 801 four-field-complete, 435 unknown numeric cells**. Not changed by worker. No independent exhaustive Retail universe proof.

## Validation
Exact queue revision 18, 35 unique disjoint keys, 27 source-line IDs, four independent fields each, 140 slots, 41 provisional numeric / 99 unknown, positive bounds and P/E invariants, original cohort separation, and source-only null actual casts checked in-memory. Node CLI, Lua interpreter and WoW client not executed.
