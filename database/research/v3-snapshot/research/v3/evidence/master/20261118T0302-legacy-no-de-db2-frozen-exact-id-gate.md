# Legacy 11 no-disenchant records: exact-ID game-file coverage vs frozen integration

Date of manager static audit: 2026-11-18T03:03:23.096Z. This is a research-only identity / eligibility-source gap check. It does **not** certify a live Retail disenchant attempt or a new gold valuation.

## Source and scope

- Worker original: [`2026-11-18T0251-classic-wands-twilight-recruit-no-de.jsonl`](../legacy/2026-11-18T0251-classic-wands-twilight-recruit-no-de.jsonl), 11 exact-ID source records committed by the Legacy worker at `94e9360bbe9c6e5d5add21df77fcc45343b9d09b`. Manager did not modify them.
- Owner implementation head examined: `3d667d053db587c91401cfed7ecc56862b8340c9`; main head at audit startup `888c5ba0582de3f802cbff08fece88a448ac22db`; research head at startup `94e9360bbe9c6e5d5add21df77fcc45343b9d09b`.
- Source [`DB2Restrictions.lua`](https://github.com/Voodoobrew101/Loot-Liquidator/blob/implementation/usable-data-tooltips/database/sources/DB2Restrictions.lua), exact `for _,itemID in ipairs({...})` numeric set (**21,061 distinct IDs**, DB2 export build `12.1.7.70493`), **not substring searches**. Owner frozen [`research-v3-baselines.lua`](https://github.com/Voodoobrew101/Loot-Liquidator/blob/implementation/usable-data-tooltips/database/research-v3-baselines.lua), and current main baseline checked separately. `LootLiquidator/Database.lua` loads both game-file restrictions and supplementary research-only restrictions, if compiled.

## Exact result and significance

| Exact item ID | Source identity | DB2 NO_DISENCHANT | Frozen main / owner baseline exact ID | Source applicability |
| --- | --- | --- | --- | --- |
| 20406, 20407, 20408 | Three Twilight Cultist set pieces | Yes / Yes / Yes | Not needed for this gate | Historical catalog/comments, Retail current test not asserted |
| 11287, 11288, 11289, 11290 | Four enchanting-crafted wand variants | Yes / Yes / Yes / Yes | Not needed for this gate | Old Classic/WotLK, DB2 rule already present |
| **23321** | **Recruit's Robe, Old Hillsbrad vendor** | **No** | **Absent / absent** | [Current Retail item page explicitly says cannot disenchant](https://www.wowhead.com/item=23321/recruits-robe); in-game attempt not made |
| **5347** | **Pestilent Wand** | **No** | **Absent / absent** | [Current Retail page explicitly says cannot disenchant](https://www.wowhead.com/item=5347/pestilent-wand); in-game attempt not made |
| **23479** | **Draenei starting Recruit's Robe** | **No** | **Absent / absent** | [WotLK Classic page flag](https://www.wowhead.com/wotlk/item=23479/recruits-robe), not current Retail proof |
| **52729** | **Doomsday Recruit's Robe** | **No** | **Absent / absent** | [Retail PTR catalog says removed/not currently obtainable](https://www.wowhead.com/ptr/item=52729/recruits-robe); not a presently eligible player action |

Seven of eleven worker-recorded IDs already exist in the compiled-game-file restriction source and **must not be counted as seven new runtime coverage wins**. Four genuinely differ from the frozen exact-ID source lists; of those, **two** have matching *current Retail catalog* no-DE flags, while the other two are historical / removed-context. This is a source-to-compiled static gap, **not proof of an incorrect in-game recommendation**, because other runtime eligibility rules may already suppress disenchant actions.

The three Recruit's Robe IDs are different items and cannot be deduplicated by displayed name. An incomplete output/item identity or a Classic-only/removed item flag must never be promoted to a current character-eligible action.

## Validation and next gate

- Executed **58/58 in-memory JavaScript source assertions**: unique worker IDs/types/HTTPS sources, exact numeric DB2 set membership, main and owner frozen baseline gaps, data-loader restriction consumption, DB2 build ID, and three same-name robe variants. Zero assertion failures.
- No Lua/addon build, source migration, tooltip renderer, synthetic-price engine, CI rerun or live WoW-client execution was performed by this manager audit. Historical non-DE records do not constitute observed disenchant casts.
- Source records should remain append-only on the worker branch. Future owner-reviewed compilation can consider the two current-catalog flags as **research-only additive restrictions**, separately inspect 23479/52729 version and obtainable status, then prove actual live-character item eligibility and tooltip fallback in a later controlled pass; **no edits to the owner's `implementation/usable-data-tooltips` branch** are authorized here.
- Continue top-priority current-build Midnight T0005/T0039 Umbral Tin 237362 0-N/refund/rank/skill and T0045 Tranquility Bloom 236761 input-linked completed mills; no numeric probabilities, quantities or gold EV are newly inferred by this check.
