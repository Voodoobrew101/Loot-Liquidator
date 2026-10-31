# How processing results change with the character: checked mechanics

Every rule the estimate script or the addon relies on must be listed here first, with a source
and a status. Nothing is built on a mechanic that isn't on this list.

Status: **verified** = stated by a current guide or official note; **likely** = one source or older
expansion; **unverified** = assumed, needs a source; **conflicting** = sources disagree.

Agents: add sources, correct statuses, and add missing mechanics with a `flags.jsonl` line
(prefix the concern with `mechanics:`); the Master updates this file.

## Midnight (current)

| # | Mechanic | Status | Source |
| --- | --- | --- | --- |
| M1 | Prospecting uses 5 ore per cast. | verified | boostmatch.gg Midnight Jewelcrafting guide; wow-professions.com |
| M2 | Every prospect gives Duskshrouded Stone and Crystalline Glass; gems are random on top. | verified | boostmatch.gg Midnight Jewelcrafting guide |
| M3 | Eversong Diamond (242608) drops only after a Proficient Processor specialization unlock; then a small chance from all Midnight ore. | verified | method.gg Midnight Jewelcrafting guide; boostmatch.gg; old addon GameData.lua per-ore unlock flags |
| M4 | Which exact node unlocks the diamond for each ore (old addon names: Copper Consumer, Tin-vestigator, Silver Scrapper, Thorium Thresher). | unverified | old addon settings only; queue task for the midnight agent |
| M5 | Midnight ore and reagents have two quality ranks (silver, gold). Skill decides the output's rank, which changes its price, not the count. | likely | wowcarry.com and dving.net Midnight guides (two ranks); wow-professions.com "Gold Quality" prospecting phase |
| M6 | Milling uses 10 herbs per cast. | verified | method.gg Midnight Inscription guide; Blizzard forum t/2307840 (May 19 2026: game error "Requires 10 Tranquility Blooms") |
| M7 | Herb quality does not change the number of pigments; skill does. | verified | method.gg Midnight Inscription guide |
| M8 | Milling cannot Multicraft. | verified | wow-professions.com Midnight Inscription guide and specialization guide |
| M9 | Resourcefulness applies to milling (saves herbs). | verified | wow-professions.com Midnight Inscription guide ("keep a Resourcefulness tool for milling") |
| M10 | Resourcefulness applies to prospecting (saves ore). | likely | wow-professions.com Midnight Jewelcrafting prospecting build (Phase 2 "Resourcefulness and Skill"); firsthand: Cardinalai Wowhead comment Jun 10 2026, 715 of 4000 Brilliant Silver ore saved at 39.6% Resourcefulness |
| M11 | Multicraft applies to prospecting. | likely | wow-professions.com prospecting build starts with Multicraft points; the owner thinks so too (doesn't prospect personally). Milling explicitly can't. Still needs a direct source; the addon's craft recorder also logs Multicraft procs, which would settle it. |
| M12 | Disenchanting results depend on skill and the Disenchanting Delegate specialization (more and better materials). | verified | wow-professions.com Midnight Enchanting specialization guide; dving.net Midnight Enchanting guide |
| M13 | Resourcefulness, Ingenuity and Multicraft do not change disenchanting. | likely | dving.net Midnight Enchanting guide (single source) |
| M15 | Resourcefulness rolls per reagent and returns 1 to ceil(0.4 x reagent count) of it, modified by specialization nodes. | unverified | single forum claim: Teishoku, Blizzard forum t/2261410 post 2 (Mar 1 2026); no official source |
| M16 | Skill raises gem/dust quality, not amount; only the last Prospecting specialization node adds gems. | unverified | single forum claim: Teishoku, Blizzard forum t/2280780 (Mar 27 2026); contradicts nothing yet, untested |
| M14 | Rate change: gems found more regularly from Midnight ore after March 31, 2026. | verified | Blizzard hotfix list (see rate-changes.jsonl) |

## The War Within

| # | Mechanic | Status | Source |
| --- | --- | --- | --- |
| W1 | Prospecting is more fixed: specific ore gives specific gems, unless knowledge is spent on prospecting. | verified | method.gg The War Within Jewelcrafting leveling guide |
| W2 | Resourcefulness on prospecting saves ore (old Aqirite study notes ore refunds). | likely | old evidence file warwithin-batch004 (1,040-prospect Aqirite study) |

## Dragonflight

| # | Mechanic | Status | Source |
| --- | --- | --- | --- |
| D1 | Prospecting results improve at skill thresholds (around 150 and 250). | likely | Wowhead "Dragonflight Jewelcrafting analysis" (Economy Weekly Wrap-Up 249) |
| D2 | Ore quality adds prospecting skill: 1 star +25, 2 star +56, 3 star +83. | likely | same Wowhead analysis |
| D3 | Inspiration was removed later in the expansion (rate change). | verified | dragonflight agent rateChange record |

## How the model uses these

1. **Baseline:** what a typical player gets, from all studies, with conditional drops (M3) removed.
2. **Unlocks:** conditional drops are added only for characters that have the unlock (M3, M4).
3. **Skill:** used where a mechanic says skill matters (M5 rank, M7 pigments, M12 disenchanting,
   D1 thresholds), but only once there are studies at different skill levels to measure the effect.
   Until then, the baseline is shown and the tooltip says "skill not accounted for yet".
4. **Stats:** Resourcefulness lowers the inputs used per result where it applies (M9, M10, W2),
   using the character's real percentage from the game and the community formula (about 30% of the
   inputs saved per proc), labelled with its own lower confidence. Multicraft only where verified.
5. **Your own results** (recorded casts at your real skill, spec and stats) gradually take over
   from the baseline.
