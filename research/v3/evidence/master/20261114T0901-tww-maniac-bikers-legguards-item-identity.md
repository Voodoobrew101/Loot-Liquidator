# TWW T0048 — Original-name-to-ID correction: Maniac Biker's Legguards

Verified 2026-11-14 09:01 UTC. Research-only, new **exact input item identity**, not a new disenchant study or current-character eligibility result.

## Original worker record being reconciled
- Preserve unchanged: `research/v3/evidence/war-within/202611140828-six-r2-storm-dust-looter-gear-cohorts.jsonl`, record `war-within-20261114-0828-005`, studyKey `wowhead-looter-stormdust-r2-input-maniac-bikers-legguards`.
- Its named input `Maniac Biker's Legguards` had `inputItemID=null`. Its original [PTR 12.1.7 Storm Dust rank-2 output-side Looter page](https://www.wowhead.com/ptr/item=219947/storm-dust) displays **34 out of 95** source cumulative item disenchants. These are **material occurrence hits** among reported operations, NOT 34 units, a per-cast histogram, 34 newly tested events, or new independent observations.
- The current corrected exact **inputItemID is 235148**. This is an identity correction against the same cohort, not a second cohort and not an instruction to import or value the held data.

## Exact independently cross-checked identity
1. [AllTheThings quest database at pinned commit b258754f](https://github.com/ATTWoWAddon/AllTheThings/blob/b258754f5ce03f0827552ccb39ee2d30135fd0fb/.contrib/.db/standard/02%20-%20Outdoor%20Zones/15%20Khaz%20Algar/Undermine/Quests.lua): under **Renegotiations / quest 84381** lists `i(235148), -- Maniac Biker's Legguards`, distinct from Wristguards **235146**, Shoulderguards **235147**, Boots **235149**.
2. [SimulationCraft character input at pinned commit c78b13c4](https://github.com/tcarlton2000/simc/blob/c78b13c41583adede47aecb75a01e730dc341644/the_war_within/s2/ninjanda/week2/ninjanda.mw.week2.simc): independently names `Maniac Biker's Legguards` and `legs=,id=235148,bonus_id=11942/6652/11968/1469`. These bonus IDs are **specific to that unrelated character loadout** and are not attributable to the Wowhead Looter cohort.
3. [Live Wowhead item=235148](https://www.wowhead.com/item=235148/maniac-bikers-legguards) independently resolves the exact name **Maniac Biker's Legguards**, leather leg armor, **binds when picked up**. Live displayed item level/scaled stats differ from PTR source and old SimulationCraft output, so do not transfer a displayed level or bonus.
4. [Wowhead Renegotiations quest=84381](https://www.wowhead.com/quest=84381/renegotiations) verifies the named quest-reward family. Source identity is consistent across a pinned quest table, gear export and live item page.

## Disposition and gold impact
- **Resolved:** prior `null` **input identity** in the new TWW worker row, with exact ID **235148**. Existing source metric stays `casts=95`, `castsWithDrop=34`, `outputItemID=219947`, `outputRank=2`, **as source-reported, not independently reproduced**.
- **Still blocked:** original retail-at-cast itemLink and bonus/level, patch, eligibility, Enchanting skill/spec, per-hit yield quantities, true zero-inclusive 0..N histogram and whether PTR Looter duplicates live/item-side snapshots. Do not infer output total, P(hit) on a modern character, conditional amount, or valuation; no synthetic-price or live-game tests performed.
- **Newly relevant exclusion:** the input is **BoP** at the live item template, so the addon must not offer an auction path for this item. This does not establish that its disenchant method is currently legal or profitable.
- **Worker-owned next action:** append an exact-ID replacement/correction record in TWW's own authorized evidence area, referencing `war-within-20261114-0828-005` (same original study), preserving original null-ID row. Master does not edit worker data or compile Held PTR yields.
- **Tests:** original-source item identity checked from three independent repositories/item pages; **zero** addon, compiler, tooltip, synthetic-price, Lua or live-WoW tests run.

No changes to main, protected integration, immutable snapshot, PRs, schedules, original evidence or other workers.
