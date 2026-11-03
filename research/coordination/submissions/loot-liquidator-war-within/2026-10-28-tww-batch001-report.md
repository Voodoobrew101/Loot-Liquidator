# The War Within — prospecting worker batch 001 (2026-10-28)

Assignment: `2026-10-28-init-war_within-001`. Main production addon untouched.

## Actual batch results
- Audited **39 distinct assigned** runtime TWW prospecting input/output/quality rows from main `StatYieldProfiles.lua` and research `runtime-overlay-map.csv`; all source keys present and unique.
- **13 rank-2 rows** (Bismuth 3, Aqirite 5, Ironclaw 5) exactly reproduce the historical Wowhead PeaEsk comment totals / 20 five-ore equivalents. This verifies an apparent provenance of the legacy LOW endpoint, not a present-day measured value.
- **26 rank-1/rank-3 rows** are borrowed rank-2 proxies, not quality-specific observations. All 39 HIGH values are modeled, not observed.
- Five original historical cohort records archived (3 undated Wowhead rank-2 100-ore studies, 2 Reddit Oct 14 2024 Aqirite rank-1/rank-2 11,000/10,000 ore studies). Reddit R1 and R2 source includes Crushed Gemstones 20.4/20.8 units per 1000 ore respectively; item ID not independently verified and intentionally excluded from mapped output IDs.
- All 39 are **EXAMINED_INSUFFICIENT**, with independent field scores: identity 75, P(drop) 0, conditional min 0, conditional max 0, E 48 for the 13 rank-2 source-linked rows / 0 for the 26 borrowed rows; weakest-field record confidence 0. **No records promoted >=90.** Master must independently review before central ledger acceptance.

## Source-backed findings and critical caveats
1. [Method's TWW prospecting guide, Aug 12 2024](https://www.method.gg/guides/the-war-within-ore-prospecting-guide) confirms baseline Bismuth→Amber, Aqirite→Amber/Sapphire/Emerald, Ironclaw→Amber/Ruby/Onyx, and cross-ore gem unlocks through specialization; higher ore rank changes gem frequency.
2. [Wowhead Algari Prospecting spell 434018](https://www.wowhead.com/spell=434018/algari-prospecting) states **five ore per operation** and includes PeaEsk rank-2 totals. The wording “100 [ore] rank2” suggests 100 ore pieces but does not explicitly report 20 completed casts, so `completedOperations=null`; 20 is **only a five-ore equivalent**.
3. [Reddit Oct 14 2024 Aqirite 11k/10k-ore study](https://www.reddit.com/r/woweconomy/comments/1g350pq) reports averages per 1000 ore. E.g. rank-1 Sapphire 35.4/200=**0.1770** per five-ore equivalent; rank-2 Sapphire 42.9/200=**0.2145**. Those differ substantially from the undated Wowhead rank-2 1.0000. No justified interpolation between cohorts because specialization and timing differ. The Reddit study lists all four rare gems, consistent with Method's specialization unlock, but does not establish the character's exact spec. Do not add those as unconditional base outputs.
4. [Blizzard 2024-10-25 prospecting hotfix quoted in Wowhead's weekly economy wrap-up](https://www.wowhead.com/ptr/news/recent-prospecting-changes-wowhead-economy-weekly-wrap-up-351-349956): byproducts became part of every prospecting action, gem drop rates and maximum byproduct yields changed, and Amber 40/40 perk fixed. This makes the Oct 14 Reddit cohort **historical only**. “Byproducts from every action” does NOT prove each specific byproduct has 100% occurrence.
5. [Wowhead Aqirite item 210933](https://www.wowhead.com/item=210933/aqirite) lists the expected baseline gem candidates and Crushed Gemstones as specialization-gated.

## QA
- Static checks passed: 39 unique assignment keys, 39 matching overlay rows, 13/13 rank-2 arithmetic matches (absolute difference <1e-9), 26 borrowed-quality rows marked proxy, five schema-shaped observation objects, all unknown P/drop min/max remain NULL.
- No source reports per-cast hit count or positive conditional min/max; these remain unknown. Historical unconditional E is **total / ore-equivalent operations**, never P(drop) × E or min/max midpoint. No in-game test performed.
- No production Lua, central ledger, or master queue edited. Submitted worker-owned audit CSV and raw JSONL for master QA.

## Next assignment
overlay:TWW mill:210796:222616, overlay:TWW mill:210797:222617, overlay:TWW mill:210798:222618, overlay:TWW mill:210799:222612, overlay:TWW mill:210800:222613, overlay:TWW mill:210801:222614, overlay:TWW mill:210802:224800, overlay:TWW mill:210803:224801 (TWW milling). Highest-priority gap: **post-Oct 25 2024** patch-matched cast-by-cast TWW prospecting with exact skill/spec, ore rank, occurrence histograms and measured output totals. Keep one authoritative future `itemdb.lua` only.
