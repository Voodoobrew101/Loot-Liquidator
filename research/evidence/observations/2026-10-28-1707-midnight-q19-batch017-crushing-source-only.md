# Midnight Crushing: source-only original-player observations (queue19 / batch017)

Date indexed: 2026-10-28. **Source-only:** not a schema-valid cast-level observation, no rank-specific input/output IDs, no fabricated cast denominator. Source-memory checked before new fetch: neither original Reddit thread was indexed. These are two distinct first-hand player statements, NOT two measured cast cohorts.

## New original player statement — July 24, 2026 thread
- Original thread: https://www.reddit.com/r/woweconomy/comments/1v5esk0/midnight_jc/; commenter `tired_and_fed_up`.
- Reported context: max prospecting, max dusting, max Resourcefulness; purple tools mentioned in the exchange.
- Author's estimate: **0.83925 Glimmering Gemdust per gem**; ~13,000 gems per 100,000 copper ore. No original count of dust, gem inputs, completed Crushing operations, input gem IDs/ranks, output dust rank, actual observation date or build was provided. Treat 0.83925 as a **player-reported contextual gross-input ratio**, NOT an exact per-cast expectedQuantity. Derived 3-gem equivalent 2.51775 dust per nominal batch; **NOT actual casts**.
- Existing independent Cardinalai mixed-gem historical cohort (already indexed, NOT new): 330 dust / 480 initially reported gems = 0.6875 per gem, or 2.0625 per nominal three-gem batch, at 40.7% Resourcefulness and max knowledge. July estimate is **22.07% higher**. Input mix, ranks, Resourcefulness, patches and actual operation counts are not matched. Cannot infer a profession coefficient or per-gem-ID rate.
- Copper gem figure 13,000/100,000=0.13 gem per nominal ore is separate *prospecting* claim, not Crushing yield; outside this worker's assigned prospect output keys. Do not promote.

## New original player observation — March 12, 2026 thread
- Original thread: https://www.reddit.com/r/woweconomy/comments/1rrn6of/resourcefulness_in_crushingprospecting/; author `OldWolf2`.
- Author reports Resourcefulness display under Crushing and approximately 5% gems returned despite 29% displayed Resourcefulness in a **small unspecified sample**. No number of casts, exact gems, refunded stone count or per-cast outcomes. A different commenter says savings may apply to gem units or stone and discusses R2 dust requiring skill/gear, but that is a qualitative interpretation, not a controlled study.
- **Critical distinction:** saved gems/stone are input savings, never Gemdust outputs. A displayed 29% proc rate cannot be equated to 29% gems returned; no universal salvage/refund coefficient justified.

## Reused game-record and secondary sources
- https://www.wowhead.com/spell=1231132/midnight-crushing: spell 1231132, salvage 3 Midnight gems and 1 Dusk-Shrouded Stone reagent. Explicit salvage list is not visible in the indexed page, so 16 exact item IDs remain candidates rather than approved conversion mappings.
- https://www.method.gg/guides/midnight-jewelcrafting-profession-guide: guide states gem variety/quality does not affect family-level dust count and claims 1–3 dust per operation; not a rank-specific histogram. It separately says a single gem may yield a stone, but does not identify the spell/operation. Do not combine that claim with spell 1231132 or infer a free stone byproduct.
- https://www.wowhead.com/item=242620/glimmering-gemdust : original Cardinalai 480-gem report reused; original independent source, no actual cast count.

## Source independence and limitations
Two newly indexed original **statements** (July, March); zero new controlled samples; no duplicated locale mirrors or forum reposts counted as independent. Exact item rank and salvage eligibility, actual cast counts, output rank histograms, current patch/build and skill/gear remain unresolved. No numeric promotion to itemdb.lua.
