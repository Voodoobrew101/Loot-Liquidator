# Midnight 12.1.0 refining and prospect rank source evidence (SOURCE-ONLY, not a cast observation)

2026-10-28; branch `research/processing-confidence`; worker: loot-liquidator-midnight; queue 16. No source is represented as a measured cast cohort.

## Newly discovered omitted recipe

- **LIVE WoWDB** https://www.wowdb.com/spells/1307462-refine-crystalline-glass-a-professions-chaticon : spell 1307462, *Refine Crystalline Glass*, introduced in patch 12.1.0 build 68209. Trainer Midnight Jewelcrafting 50; Jeweler's Tools and Jeweler's Bench; consumes 10 rank-one Crystalline Glass, produces 1 rank-two Crystalline Glass; crafting effect value 1. Original game-database record (not an original player experiment).
- **Item identities** https://www.wowdb.com/items/242786-crystalline-glass and https://www.wowdb.com/items/242787-crystalline-glass : two distinct Crystalline Glass item IDs. Source recipe says rank 1 to rank 2 but does not expose both numeric IDs unambiguously in its rendered reagent list; `242786 x10 -> 242787 x1` remains an item-rank **candidate** pending client/recipe data decode.
- **Guide corroboration** https://www.wowhead.com/guide/midnight/professions/jewelcrafting-overview-trainer-locations-recipes-tools (updated 2026-08-18) separately names this 10:1 12.1 refining recipe. This repeats underlying game data, **not an independent cast sample**.
- **PTR conflict** https://ptr.wowdb.com/spells/1307462-refine-crystalline-glass-a-professions-chaticon : PTR reagent list renders `Crystalline Glass x5, Crystalline Glass x10` while LIVE renders only `x10`. No basis to add quantities or claim live 15; record build-specific ambiguity for master.
- **Negative source inventory** `main/GameData.lua` SHA `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e` and current research `itemdb.lua` had no 1307462 nor 242787; source-memory cache had no 1307462. These are checked negative inventory claims, not proof no other game conversion exists.

## Related unassigned prospect output-rank gap

- The current staged candidate contains rank-one Crystalline Glass `242786` and rank-one Dusk-Shrouded Stone `242788`, but not rank-two `242787` or `242789`.
- March 25, 2026 firsthand discussion https://www.reddit.com/r/woweconomy/comments/1s3hnzo/thoughts_on_crushing/ says skilled rank-two ore prospecting yields rank-two glass/gems. April 29, 2026 discussion https://www.reddit.com/r/woweconomy/comments/1szcgff/prospecting/ says rank-two ore yields rank-two stone and glass. Both are **qualitative, no cast denominator**, and do not establish exact ore/output pair rates or all ore eligibility. Preserve as **unassigned output-rank candidates**, not six confirmed rows.
- Original JD3K source https://www.wowhead.com/spell=1231127/midnight-prospecting reports 50 gross rank-two ore each for Copper, Tin and Silver, with family material totals, but **no actual cast counts, output item rank IDs, or zero-inclusive histograms**. Existing low source E for assigned 35 keys is not newly measured.

## Unverified one-gem-to-stone statement

https://www.method.gg/guides/midnight-jewelcrafting-profession-guide claims a single gem can be crushed for a stone, but no separate spell ID or observed cast was found. The documented spell 1231132 is 3 gems + 1 stone -> Gemdust; **do not add** an invented 1-gem conversion.

No player-identifying private logs. No production or master-owned files edited.
