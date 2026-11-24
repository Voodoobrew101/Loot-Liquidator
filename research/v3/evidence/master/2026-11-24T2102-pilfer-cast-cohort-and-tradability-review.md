# TWW Pilfer Through Parts: source-reported operations, profile and output tradability

Reviewed 2026-11-24 UTC. Historical Retail source-review metadata, **not** a new automatic baseline or validated runtime recommendation. Original web comments are unchanged. Source publication dates and original response hashes not available from indexed excerpts. Recipe 447311 is distinct from Midnight Recycling 1229930.

## Candidate 1: Moods, named Thorium Widget cohort

Original author comment: https://www.wowhead.com/spell=447373/crowd-pummeler-2-30 (Moods). Author explicitly reports 2,500 pilfers of Thorium Widget, item 15994 (Retail identity also https://goldcap.gg/retail/us/items/15994). Source reports Scrapper +2 maximum and equipped profession bag +1 overall; scrap observed range 4–7 per operation. Exact skill, patch/date, refund count, equipment details and operation ledger unknown. Recipe nominal batch five; 12,500 nominal input equivalents, not measured net consumption.

| Output item | ID | Total units reported | Units per reported pilfer |
|---|---:|---:|---:|
| Pile of Rusted Scrap | 219150 | 14000 | 5.6 |
| Bountiful Bolts | 227769 | 700 | 0.28 |
| Assorted Whirligigs | 227770 | 19 | 0.0076 |
| Blinker Fluid | 227771 | 20 | 0.008 |
| Cataclysmic Converter | 227772 | 11 | 0.0044 |
| Pummel-Proof Plating | 227773 | 7 | 0.0028 |
| Pummel Permit | 227774 | 1 | 0.0004 |

Each mean = total / 2500 source-reported operations. All castsWithDrop and histograms unknown; not inferred from quantity. The scrap range is profile-specific, not a bound on other profiles. One permit in a historical selected cohort is not a calibrated universal proc probability. Do not include the author's anecdote about another player as an additional study. Historical market-value claims are not baseline material sale prices.

## Candidate 2: Alustriel, Serevite Bolts family (rank unknown)

Original author comment: https://www.wowhead.com/item=219150/pile-of-rusted-scrap (Alustriel). 464 source-reported Pilfer operations, 2,323 crafted bolts available, 470 scrap and 254 Bountiful Bolts; means 470/464 and 254/464 units per reported operation. Source refers to rank 3 *ore*, not verified rank of resulting bolts. Do not assign input itemID or rank from ore quality. Nominal batch five, 2,320 operation-equivalent input units; actual net consumption/refunds unknown. Source also describes 94 Scour Through Scrap operations, a separate stage; do not add any downstream outcomes to direct Pilfer. No hits, histogram, exact dates or specialization profile provided. Other outputs are unreported, not measured zero.

## Additional historical candidate leads (not merged)

* merovegas on https://www.wowhead.com/spell=447311/pilfer-through-parts: approximately 105,000 parts recorded in total, most at reported 18% Resourcefulness. Listed individual approximate input groups and totals (order: permit, plating, converter, fluid, whirligigs): Thorium Widget ~25,000 [0,11,24,51,60]; Shock-Spring Coil ~60,000 [0,17,44,83,123]; Adamantite Frame ~5,000 [0,1,4,7,6]; Overcharged Capacitor ~5,000 [0,2,2,6,7]; Unstable Trigger ~5,000 [0,1,3,5,8]. Listed groups sum ~100k, not complete ~105k total. Permit was purchased separately and must not enter loot counts. Exact ranks, casts, refunds, patch and full totals unknown. Do not assume 21,000 completed operations or use author vendor-price score as liquidation value.
* Zyni on spell 447373: cumulative 185,000 listed bolts, final totals 3313/148/120/59/22/1 in order of item IDs 227769–227774. Earlier 105,000 bolts / 21,000 declared cast equivalents is included, not a separate independent cohort. July 10 2024 update and stopping at permit confound epoch and stopping-rule applicability; exact item rank, Retail launch status and actual completed operation basis unresolved. Preserve as historical lead only; no current numerical admission.

## Identity, eligibility and disposition

* https://www.wowhead.com/spell=447311/pilfer-through-parts and https://www.wowhead.com/ptr-2/spell=447311/pilfer-through-parts: Khaz Algar Engineering trainer skill 5, salvage effect 89, batch 5; Retail-indexed and 12.1.5 PTR database descriptions agree. Not proof that a current character can execute it on all historical inputs.
* https://www.wowhead.com/news/crowd-pummeler-2-30-new-engineering-mount-in-the-war-within-344189 and https://www.wowhead.com/guide/the-war-within/professions/engineering-overview: mount part opportunity is specialization-gated through Parts under Inventing. Exact threshold not assigned: player reports conflict. Do not infer universal mount-part availability for every character.
* Retail item pages https://www.wowhead.com/item=227769/bountiful-bolts, https://www.wowhead.com/item=227770/assorted-whirligigs, https://www.wowhead.com/item=227771/blinker-fluid, https://www.wowhead.com/item=227772/cataclysmic-converter, https://www.wowhead.com/item=227773/pummel-proof-plating, https://www.wowhead.com/item=227774/pummel-permit corroborate all six IDs. https://goldcap.gg/retail/us/items/221967 independently lists all six as market-sourced materials. Unlike bound scrap, these are tradable candidates; vendor purchase cost is not vendor sell value. No snapshot AH prices frozen.
* https://www.wowhead.com/item=219150/pile-of-rusted-scrap confirms binds-on-pickup; no AH liquidation value. Keep its native vendor value and downstream recipe utility separate.
* https://us.forums.blizzard.com/en/wow/t/engineering-auto-craft-pilfer-for-parts/1942181 and https://us.forums.blizzard.com/en/wow/t/engineering-pilfer-through-parts-fail-with-error-message/1934554 report historical stack-selection/auto-repeat failures. Do not equate planned batch sizes with success or assume current behavior.
* https://www.wowhead.com/spell=447311/pilfer-through-parts comment by Bugy claims bolts-only mount output after a nerf; no official date or magnitude recovered. Do not pool older bolt cohorts into a current epoch or declare a verified universal zero.

## Validation and ownership

Checked original author excerpts and output item links, arithmetic, source-profile distinctions and current runtime map at main 2db9929050b8532645149dea5a3c5fa8aa0a035a, LootLiquidator/Professions.lua lines 102–120: only 1229930 and 1280394 present. Prior coordinator review 4dbf5c30d675638d6f194a7ffc6d0a78535446bf did not include these author blocks. Checked cutoff manifest for source identifiers and default-branch code search for Moods, Alustriel, merovegas, Zyni and 447373, with no match; this does not establish branch-wide cohort independence. No generated database, addon code, existing worker evidence, PR, or schedule changed. Hold for exact source deduplication, recipe-specific eligibility/adapter, specialization and epoch review. Two author-reported operation blocks are candidates (2,964 source-reported operations across incompatible profiles, nine total-quantity rows); no claim of combined independent sample or current supported gold decisions. No in-game operations performed.
