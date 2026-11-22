# Profession profile source and model coverage — November 19, 2026

Generated from pinned public client tables and existing reviewed output bindings. No new in-game collection was performed.

The compiler maps 591 paths and 2605 processing milestones (2766 client entries) into 2826 typed handlers across 30 profession identities. Gathering-only effects and world-node targets are excluded. Legacy recipe identities and minimum Skill remain separate from modern specialization catalogs.

This is semantic coverage, **not complete empirical calibration**. There are 0 explicit structural, timing, convenience or progression handlers; 97 output/profile terms use declared zero-confidence models; and 24 output terms retain source-backed family names with unresolved item IDs. Those named outcomes carry no invented Auction House valuation.

Primary Item → CraftingQuality joins establish 700 ordered families. Item IDs are never numerically sorted to infer quality. The dataset includes 11485 native recipe identities, 29222 reduced item rows. World gathering spells are excluded unless they also have an item-processing contract.

Only item-value skill, quality, output quantity and input-savings effects are emitted. Native recipe/item identities remain shared; timing, concentration and convenience projections are excluded. Recipe stat capability models retain their evidence/confidence and defer to native operation stat eligibility.

## Named outputs with unresolved item identity

These are known semantic outcome families. Their proc magnitudes may also be provisional. Exact node/entry descriptions, native references, scopes and confidence remain in the machine-readable coverage JSON.

| Source-backed family | Entries | Node names |
| --- | ---: | --- |
| Additional craft outcome | 1 | Scrapper |
| Additional prospect outcome | 1 | Prospecting |
| Additional target-compatible materials | 2 | Rare Resourcing, Shard Supplier |
| Additional target-compatible reagents | 4 | Draconic Disenchantment, Gem Finding |
| Quality-1 EZ-Thro bomb variant | 1 | Creation |
| Raw gems | 4 | Gem Finding, Glassware, Prospecting Pro |
| Recovered Crowd Pummeler components | 1 | Parts |
| Recovered engineering treasures | 1 | Scrapper |
| Recovered experimental flasks | 5 | Arathor's Spear Lore, Blessing Blossom Lore, Luredrop Lore, Mycobloom Lore, Orbinid Lore |
| Recovered low-quality reagent | 1 | Bits |
| Recovered salvageable components | 1 | Short Fuse |
| Transmutagen byproducts | 2 | Thaumaturgy |

## Conditional state without a native aura identity

1 client entries lack a verified native aura spell ID. They retain explicit entry-specific manual state keys; the compiler does not invent spell IDs or assume these buffs are active.

| Entry | Node | Manual state key |
| ---: | --- | ---: |
| 87366 | Primal Extraction | 87366 |

## Primary source routes

- [Pinned Item table](https://wago.tools/db2/Item?build=12.1.5.70961): native class, inventory type, crafting quality and reagent-family identity.
- [Pinned ItemSparse table](https://wago.tools/db2/ItemSparse?build=12.1.5.70961): item names, binding and vendor values.
- [Pinned profession perk nodes](https://wago.tools/db2/ProfTraitPerkNode?build=12.1.5.70961): actual invested-point milestone boundaries.
- [Pinned profession effects](https://wago.tools/db2/ProfessionEffect?build=12.1.5.70961): client effect amounts and types; custom enums are interpreted by their exact definition and label scope.
- [Pinned spell timing](https://wago.tools/db2/SpellCastTimes?build=12.1.5.70961): static cast-time parameters.

Source hashes and exact join IDs are retained in database/research/profession-effect-catalog-70961.json. Typed entry mappings and unresolved identity groups are in database/research/profession-profile-rule-coverage.json. Original studies and their denominators are not changed by this compiler.
