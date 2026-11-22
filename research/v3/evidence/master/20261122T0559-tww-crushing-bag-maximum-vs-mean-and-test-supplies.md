# Manager original-source context review — TWW equipment max vs mean, and PTR supply bags

- Checked UTC: 2026-11-22T05:59:31.807Z
- Owner scope: post-cutoff/newly discovered *unassessed conditional effect*, not a re-catalogue of the 731-source cutoff. Manager-only evidence note; no addon/data generator modification.
- Queue relevance: T0007/T0040 (TWW input/output profile & process accounting), future conditional Algari Crushing valuation. Current gold impact **unquantified**.

## 1. Equipped profession bag: source-stated *maximum*, not expected yield

[WoWhead Retail item 222867, Jeweler's Purse](https://www.wowhead.com/item=222867/jewelers-purse), [Retail spell 454803, Jewelcrafting Bag](https://www.wowhead.com/spell=454803/jewelcrafting-bag) and [Warcraft Wiki item description](https://warcraft.wiki.gg/wiki/Jeweler%27s_Purse) agree that the **equipped** bag increases the **maximum** quantity of **Crushed Gemstones** obtained by **Algari Crushing** by **1**, with **Khaz Algar Jewelcrafting (1)** required. WoWhead's [2024 article on profession bags](https://www.wowhead.com/news/new-crafted-profession-bags-available-in-the-war-within-344470) independently describes this as a profession-bag perk atop other bonuses. Do not infer that each crush yields one additional gemstone, that the expected quantity increases by one, that an occurrence chance changes, or that the perk applies to prospecting, arbitrary expansions, unequipped bags or unspecified output ranks. No observed operations, per-cast outcomes or measured bag-on/bag-off comparison were found in these references.

Identity/context: source item **222867**; aura/effect spell **454803**; processing operation **Algari Crushing**; resulting **Crushed Gemstones** family (rank-specific output identity unresolved in this modifier description). This is source-stated eligibility/upper-bound behavior, *not* an empirical yield/EV coefficient. Retain it in source/review metadata pending scoped ingestion into character profile/equipment context. Do not change gold calculations or tooltip quantities without supported distribution and integrated tests. Item-page and spell-page verification is **not** a live-client confirmation.

Cross-check against current repository: manager queried default-branch GitHub code index for `Jeweler's Purse`, `222867` and `454803`, and searched current research queue, mechanics, coordinator checkpoint and closed 731-source catalogue manifest text. No literal occurrence was located in those inspected surfaces; this proves an uncovered *lookup dimension*, not absence from every data file or build output.

## 2. Do not count PTR testing supply bag openings as processing casts

War Within worker's latest checkpoint [quiet-status/war-within.json](../../../coordination/quiet-status/war-within.json) identifies item **224032** (Khaz Algar Enchanting test supply bag; 17 Wowhead openings) and **224035** (Jewelcrafting test supply bag; 15 openings) as non-processing sources. Independent original-reference check: [Warcraft Wiki enchanting supply bag](https://warcraft.wiki.gg/wiki/Bottomless_Bag_of_Khaz_Algar_Enchanting_Goods) and [Jewelcrafting supply bag](https://warcraft.wiki.gg/wiki/Bottomless_Bag_of_Khaz_Algar_Jewelcrafting_Goods) explicitly mark both testing-only and supplied by Professor Instructaur, with listed 1000-unit material allotments. Those are *opened containers*, not disenchanting/prospecting/crushing measurements. No amounts should enter any Retail yield cohort or confidence count. This finding corroborates the worker's original source classification; **no second independent cohort** is created.

Do not conflate these testing-only containers with equipped item 222867's possible conditional max-yield modifier. The similar English word "bag" does not imply the same source type.

## Disposition and next review gate

- **New verified source-field scope:** TWW bag-specific equipped max-yield bonus, +1 to *maximum* Crushed Gemstones per Algari Crushing only. No newly measured output mean, sample N, event chance, cast histogram, rank distribution or gold decision.
- **Existing worker source exclusion corroborated:** 224032 and 224035 are supply-bag opening cohorts, not valid processing-operation denominators.
- **Next:** Review conditional equipment-identity ingestion independently of Codex catalogue; obtain existing/published paired bag-on/bag-off **completed operations and per-event 0..N** for Algari Crushing (with gem/rank, skill/spec, recipe/build and refunds). If none exists, retain this equipment effect as a stated cap only; no guessed EV multiplier. Route any addon/schema/CI proposal through scoped implementation review, no routine research PR.
