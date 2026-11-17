# Master Enchanter's Surplus Reagents (260537) — original 2026 source quantity and redemption audit

**Captured 2026-11-17 UTC.** Research-only source identity and *bag-opening* quantity audit. The existing v3 `drop` schema permits only Prospect/Mill/Disenchant/Smelt, and an `exchange` record denotes a fixed outcome. This bag is a random **Use/Open** container; **do not encode these observations as Disenchant casts or deterministic exchanges, and do not feed the current processing estimator**. This note deliberately remains Markdown outside the v3 JSONL importer.

## Original source and identity

- Original [live Wowhead item 260537](https://www.wowhead.com/item=260537/master-enchanters-surplus-reagents), named **Master Enchanter's Surplus Reagents**, Binds on pickup, `Right Click to Open`; vendor in Silvermoon City. [Artisan Enchanter's Moxie currency 3258](https://www.wowhead.com/currency=3258/artisan-enchanters-moxie) is NOT gold. [Wowhead current currency/vendor listing](https://www.wowhead.com/pt/currency=3258/marra-do-encantador-art%C3%ADfice) and [Wow-professions vendor listing](https://www.wow-professions.com/midnight/npc/melaris) identify the vendor cost as **600 Artisan Enchanter's Moxie**; confirm exact vendor eligibility, availability and character currency in actual client before any economic action.
- Materials are **Eversinging Dust** (ID alternatives 243599/243600), **Radiant Shard** (243602/243603), **Dawn Crystal** (243605/243606), and rankless **Petrified Root** (251285; [original catalog item](https://www.wowhead.com/item=251285/petrified-root)). The rank-pair IDs are supported by [published Retail addon source mapping](https://www.curseforge.com/wow/addons/disenchantvalue/files/7701600); the specific rank of anonymous bag rows is **not** established by the material name alone.
- All raw opening counts below come from named *first-person comments on that single Wowhead item page*. Locale mirrors and PTR copies reproduce the same English author comments and are **not independent observations**. Original per-comment IDs and publication dates are unavailable. Do not claim live 12.1.5/12.1.7 behavior on this basis.

## Exactly transcribed source-reported individual bag contents

| Reporter / source operation | Epoch | Dust units | Shard units | Crystal units | Root units | Rank and extra information |
| --- | --- | ---: | ---: | ---: | ---: | --- |
| Katahn #1 | explicit beta | 53 | 23 | 8 | 1 | max rank stated |
| Katahn #2 | explicit beta | 62 | 24 | 9 | 1 | max rank stated |
| Footzies #1 | date/build not given | 61 | 22 | 7 | 1 | max/gold star stated |
| Raex #1 | date/build not given | 59 | 20 | 7 | 1 | unreported |
| Grimmella #1 | date/build not given | 64 | 28 | 6 | 3 | unreported |
| kassia1213 #1 | date/build not given | 56 | 20 | 5 | 1 | unreported; explicitly no recipe |
| kassia1213 #2 | date/build not given | 68 | 27 | 9 | 1 | unreported; BS Plans: Murder Row Fishhook reported |

**7 discrete openings across 5 named material-reporting authors.** The first **2 are explicitly beta** (Katahn); the other 5 have **no verifiable post-launch date or build**. Source arithmetic across **all 7**: Dust **423**, Shard **164**, Crystal **51**, Root **9**; source arithmetic across **five date/build-unpinned** events only: Dust **308**, Shard **117**, Crystal **34**, Root **7**. These sums are auditing conveniences, **not inferred true distribution, calibrated rates or current Retail averages**; do not pool beta with postlaunch. Some witnesses explicitly stated max output quality, while others gave no rank. No valid occurrence probability/recipe-loot probability, eligible currency opportunity-cost/gold price, vendor eligibility profile, game patch, or complete outcome distribution is established.

A separate **TomiOmit** comment reports **Design: Stabilizing Gemstone Bandolier** from a bag without material quantities. Preserve that as an additional recipe-identity lead, **not an eighth measured material-yield vector**; a possible class/profession restriction was not verified. **kassia1213** reports one bag without recipes and a second with **BS Plans: Murder Row Fishhook**; a single success/failure pair does not determine a recipe drop chance. Recipe names should be verified against exact item IDs before any token/reward table entry.

## Actual validation and disposition

- Compared the **original live Wowhead comment lines** (Katahn, Footzies, Raex, Grimmella, kassia1213, TomiOmit) against independent item/currency listings; confirmed this item ID was **not found by GitHub repository code search** at this checkpoint (a search-index result, not exhaustive coverage proof).
- **22 bounded JS arithmetic/identity assertions passed; 0 failures** for seven source rows, author dedup, explicit beta segregation, integer totals and source-specific outliers. No programmatic source-file scraper, importer, compiled ItemDB, Lua suite, synthetic-price actual engine/tooltip render, or WoW client was run.
- **Disposition:** This is source-verified identity and reported *bag-opening quantities*, but **not currently-supported v3 method evidence**; keep as **unimported, context/unmodeled**, *not* absent or invalid because no raw casts. It cannot drive a supported gold decision until the owner authorizes a modeled Use/Open method with 600 Moxie opportunity-cost semantics, actual profession/vendor eligibility, rank separation, possible recipe alternatives, epoch and a truthful unknown/provisional display policy. Do not change the protected `implementation/usable-data-tooltips` branch.
- **Next:** Check the original dated witnesses/real Retail build and bag-buy/open tests before any model; continue highest-priority T0005/T0039 Midnight prospect/mill source operation/hit/zero histograms rather than repeating already audited anonymous Looter cohorts.

**Revision boundary:** coordinator research-only note. Original sources preserved; no changes to workers, shared queue, main, addon, immutable `4df9ae8` or PRs.