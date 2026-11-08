# Coordinator source-identity audit — Crate of Battlefield Goods level-80 disenchant material family
Date: 2026-11-08 UTC. Scope: research-only source corroboration, not any new measured cast or current Retail implementation approval.

## What is newly cross-checked

1. Blizzard's CURRENT running hotfix list, under **March 13, 2026 → Items**, explicitly limits this rule to gear from **newly created Crate of Battlefield Goods**. Listed acquisition levels: **10–79 → The War Within** materials; **80–90 → Midnight** materials. The running document's later April header means its current wording is not proof that this was the exact text at first publication. Primary: https://worldofwarcraft.blizzard.com/en-us/news/24266320 ; independent Blizzard-text mirror: https://www.wowhead.com/es/blue-tracker/topic/eu/world-of-warcraft-midnight-hotfixes-17-april-608698
2. Wowhead's **March 13, 2026, 7:37 p.m.** repost instead states **81–90 → Midnight**, leaving level 80 either excluded or unaddressed in that publication. Do not silently rewrite that edition as 80. Source: https://www.wowhead.com/news/midnight-hotfixes-for-march-13th-marl-decor-cost-reduction-class-bugfixes-and-380785
3. **NEW missing identity dimension:** search indexes show at least TWO different same-name Crate of Battlefield Goods item pages, **135539** and **135540**; the page for 135540 is explicitly present on the live site. A separate level-80 quest reward, **quest 95230** ("Midnight (80) E"), labels its reward "Crate of Battlefield Goods" but the readable extract does not supply which crate-item ID or resulting gear item/bonus. Identifiers are **candidates**, not an authorized identification of the hotfix's specific crate/reward variant. Sources: https://www.wowhead.com/item=135539/crate-of-battlefield-goods ; https://www.wowhead.com/item=135540/crate-of-battlefield-goods ; https://www.wowhead.com/quest=95230/midnight-80-e
4. Warcraft Wiki independently describes Crate of Battlefield Goods as a battleground/Training Grounds reward that contains level-scaled gear and reproduces the 80–90 official current-text scope. That corroborates a *source mechanic*, not an output identity, sample, rate or ability to apply it to all leveling gear. Source: https://warcraft.wiki.gg/wiki/Crate_of_Battlefield_Goods

## Field-level disposition

- **Acquisition boundary:** 10–79 → TWW is consistent in primary and contemporary repost; 80 is **source-version conflict** (current Blizzard 80 vs contemporary Wowhead 81); 81–90 → Midnight is common. Preserve both verbatim, prefer official current wording only as scoped *reference*, never silently convert into an item-wide ability/economics rule.
- **Input identity:** name alone is non-unique across 135539/135540. Reward gear identity, itemLink/bonus, creation timestamp and acquisition character level are **absent**. A quest's level and reward name are **not** proof of an actual completed disenchant.
- **Outputs and quantitative fields:** material *expansion family* is described; output item IDs, rank, quantity, chance, conditional range, skill/spec, zero-inclusive histograms and prices are **unknown**. There are **zero new measured casts**; this contributes **zero verified current-Retail gold decisions** and **zero proven tooltip fields**.
- **Version/eligibility:** no basis to apply to pre-hotfix crates, other crates, all world gear, 272246, or MoP Classic sources. The owner's separate MoP Classic illustration is NOT Retail evidence.
- **Implementation:** retain as a conditional, provenance-labeled research mechanics candidate until a concrete reward gear ID/bonus + acquisition level, actual disenchant-time eligibility, and source-to-tooltip test are available. Do not touch implementation/usable-data-tooltips or immutable 4df9ae8 snapshot.

## Next original-source test

For one **level-80, newly created** crate, capture the exact crate item link (resolve 135539/135540/other), quest/reward context, actual reward gear itemLink including bonuses/quality, before/after disenchanting result with material item IDs and quantities, game build and skill. Compare with an independently timestamped **level-81** case. This resolves the level-80 fork without inventing a universal coefficient. Research worker owns further originals; coordinator does not solicit duplicate studies or alter worker files.

## Verification method

Read current main/research/integration branch pointers, Midnight worker's 2026-11-08T0716 JSONL, official Blizzard current entry, same-day Wowhead transcription, Wowhead live item 135540, indexed 135539 and level-80 quest 95230. No Lua, estimator, compiler, synthetic-price, tooltip, actual-client or CI tests performed by this coordinator note. CI on worker commits is not evidence for this source analysis.
