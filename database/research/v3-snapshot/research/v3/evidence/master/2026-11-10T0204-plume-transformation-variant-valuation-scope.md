# Source identity / valuation scope: reversible Midnight Plume trinket

Checked at 2026-11-10T02:04:49.336Z UTC. This is a **manager source-identity QA note**, not a new observed cast, price experiment, current-character test, or new independent source cohort.

## Original worker evidence and source checks

The existing Midnight worker evidence [two exchange records](../../evidence/midnight/20261110T0114-reversible-plume-exchange.jsonl) contains one reversible item transformation, **not two independently produced material outputs**:

- **Umbral Plume (260235) -> Radiant Plume (249806)** when activated outside combat; five-minute cooldown. Sources: [WoWDB Umbral](https://www.wowdb.com/items/260235-umbral-plume), [Wowhead Umbral](https://www.wowhead.com/item=260235/umbral-plume), [Warcraft Wiki Umbral trinket](https://warcraft.wiki.gg/wiki/Umbral_Plume_(trinket)).
- **Radiant Plume (249806) -> Umbral Plume (260235)** when activated outside combat; five-minute cooldown. Sources: [Wowhead Radiant](https://www.wowhead.com/item=249806/radiant-plume), [Warcraft Wiki Radiant](https://warcraft.wiki.gg/wiki/Radiant_Plume), [Wow4noobs Radiant](https://wow4noobs.com/en/items/249806).

Both are unique-equipped, bind-on-pickup trinket identities. The reversible conversion is a toggle of an owned item (critical-strike versus mastery effect), **not a random disenchant/prospect/mill output, a second independently obtained asset, or an Auction House recipe**. It has no observed 0..N histogram, success probability, economic process cohort or material expectation. Item name alone also is unsafe: the Wiki separates the *Umbral Plume (trinket)* from a namesake quest item.

## Newly checked variant/price caveat

Public item pages display **different item-level and vendor-price previews** for the same base ID. For example, [WoWDB 260235](https://www.wowdb.com/items/260235-umbral-plume) shows item level 197 / sell price 7g 70s 53c, whereas [Wowhead 260235](https://www.wowhead.com/item=260235/umbral-plume) shows item level 44 / sell price 47g 59s 20c. The [Warcraft Wiki's 260235 page](https://warcraft.wiki.gg/wiki/Umbral_Plume_(trinket)) describes item level 256 (Champion 4/6) with price 49g 1s 66c, and lists still other upgrade/raid variants. [Wiki Radiant](https://warcraft.wiki.gg/wiki/Radiant_Plume) gives its Champion 4/6 example as 51g 32s 90c. These are **site/version/bonus-context snapshots**, not same-character before/after vendor tests. They cannot establish a vendor-value spread or repeatable sell-profit loop.

**Disposition:** retain exact 1:1 directional item identities and conditional on-use requirements as an exchange/tooltip reference only. Keep actual transformed itemLink, item level, bonus/upgrade retention and the vendor value for the exact *post-use* item unknown. Do not turn both directions into additive EV, assume two independent drops, infer net arbitrage from cross-version catalog prices, or silently promote the result to live-character gold recommendations. Distinguish this identity/variant gap from missing numerical conversion evidence or AH price data.

## Validation and next action

Actions performed: independently cross-read public item descriptions/variant pages and read back worker's existing two JSONL source records; source-to-identity manual comparison only. **No original cast added; no compiled estimate, Lua, offline engine/tooltip render, CI, or WoW client test executed.** Follow up only if a version-matched original itemLink and observed before/after transformation/vendor price becomes available; meanwhile prioritize new completed-operation zero-inclusive Midnight ore/milling data (T0005/T0039/T0045).
