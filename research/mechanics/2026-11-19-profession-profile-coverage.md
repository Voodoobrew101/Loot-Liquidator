# Profession profile source and model coverage — November 19, 2026

Generated from pinned public client tables and existing reviewed output bindings. No new in-game collection was performed.

The compiler maps 727 paths and 4821 actual milestones (6275 client entries) into 7350 typed handlers across 39 modern profession profiles. Cooking and Fishing have stat profiles without invented specialization trees. Legacy recipe identities and minimum Skill remain separate from modern specialization catalogs.

This is semantic coverage, **not complete empirical calibration**. There are 1588 explicit structural, timing, convenience or progression handlers; 254 output/profile terms use declared zero-confidence models; and 84 output terms retain source-backed family names with unresolved item IDs. Those named outcomes carry no invented Auction House valuation.

Primary Item → CraftingQuality joins establish 700 ordered families. Item IDs are never numerically sorted to infer quality. The dataset includes 11791 native recipe identities, 29222 reduced item rows and 173 material-named native gathering targets.

Gathering targets use an explicit canonical one-unit rank-1 minimum-profile prior at confidence zero, without a fabricated sample count. Gathering Effect302 base points are retained as a difficulty-like parameter, never interpreted as material quantity. Evenly spaced quality thresholds are declared models unless a live native operation supplies exact thresholds.

Recipe timing comes from SpellMisc.CastingTimeIndex → SpellCastTimes.Base, converted from milliseconds to seconds. Equipment and conditional profession speed are applied afterward. Recipe stat capability models retain their evidence/confidence and defer to native operation stat eligibility.

## Named outputs with unresolved item identity

These are known semantic outcome families. Their proc magnitudes may also be provisional. Exact node/entry descriptions, native references, scopes and confidence remain in the machine-readable coverage JSON.

| Source-backed family | Entries | Node names |
| --- | ---: | --- |
| Additional craft outcome | 1 | Scrapper |
| Additional gather outcome | 4 | Component Collector, Conversance, Mastery |
| Additional prospect outcome | 1 | Prospecting |
| Additional target-compatible materials | 2 | Rare Resourcing, Shard Supplier |
| Additional target-compatible reagents | 6 | Draconic Disenchantment, Gem Finding, Impressive Infuser, Wild |
| Captured Spindlespiders | 1 | Webbed |
| Darkmoon Cards | 12 | Air, Darkmoon Sigil: Ascension, Darkmoon Sigil: Radiance, Darkmoon Sigil: Symbiosis, Darkmoon Sigil: Vivacity, Earth, Fire, Frost |
| Mystic disenchantable items | 4 | Insight of the Blue |
| Native creature meat | 7 | Careful Carving, Gainful Gathering, Meat Carver |
| Native humanoid cloth | 26 | Cloth Collection, Eastern Kingdoms Cloth, Fabric Specialist, Otherworldly Cloth, Quality Fabric, Textile Treasures |
| Quality-1 EZ-Thro bomb variant | 1 | Creation |
| Raw gems | 6 | Gem Finding, Glassware, Industrialization, Prospecting Pro, Serevite |
| Recovered Crowd Pummeler components | 1 | Parts |
| Recovered empty vial | 2 | Fantastic Flasks, Potent Potions |
| Recovered engineering treasures | 1 | Scrapper |
| Recovered experimental flasks | 5 | Arathor's Spear Lore, Blessing Blossom Lore, Luredrop Lore, Mycobloom Lore, Orbinid Lore |
| Recovered low-quality reagent | 1 | Bits |
| Recovered salvageable components | 1 | Short Fuse |
| Transmutagen byproducts | 2 | Thaumaturgy |

## Conditional state without a native aura identity

16 client entries lack a verified native aura spell ID. They retain explicit entry-specific manual state keys; the compiler does not invent spell IDs or assume these buffs are active.

| Entry | Node | Manual state key |
| ---: | --- | ---: |
| 24465 | Potion Experimentation | 24465 |
| 28023 | Phial Experimentation | 28023 |
| 87366 | Primal Extraction | 87366 |
| 122676 | Everburning Forge | 122676 |
| 125480 | Improved Inks | 125480 |
| 125488 | Improved Milling | 125488 |
| 125496 | Improved Ciphers | 125496 |
| 125725 | Vantus Runes | 125725 |
| 125733 | Missives | 125733 |
| 125741 | Contracts | 125741 |
| 135831 | Perfect Ciphers | 135831 |
| 135839 | Perfect Milling | 135839 |
| 135847 | Perfect Inks | 135847 |
| 135863 | Perfect Vantus Runes | 135863 |
| 135871 | Perfect Contracts | 135871 |
| 135879 | Perfect Missives | 135879 |

## Primary source routes

- [Pinned Item table](https://wago.tools/db2/Item?build=12.1.5.70961): native class, inventory type, crafting quality and reagent-family identity.
- [Pinned ItemSparse table](https://wago.tools/db2/ItemSparse?build=12.1.5.70961): item names, binding and vendor values.
- [Pinned profession perk nodes](https://wago.tools/db2/ProfTraitPerkNode?build=12.1.5.70961): actual invested-point milestone boundaries.
- [Pinned profession effects](https://wago.tools/db2/ProfessionEffect?build=12.1.5.70961): client effect amounts and types; custom enums are interpreted by their exact definition and label scope.
- [Pinned spell timing](https://wago.tools/db2/SpellCastTimes?build=12.1.5.70961): static cast-time parameters.

Source hashes and exact join IDs are retained in database/research/profession-effect-catalog-70961.json. Typed entry mappings and unresolved identity groups are in database/research/profession-profile-rule-coverage.json. Original studies and their denominators are not changed by this compiler.
