# Midnight q23 Batch 021 — material-universe expansion and rank/selector audit
**2026-10-28 21:14 PDT · research-only · queue revision 23 · assignment 2026-10-28-batch021-midnight**

## Scope and actual outcomes
- **25/25 assigned exact stable keys** reviewed: eight Midnight milling rows, twelve master-authorized TWW milling overflow rows, three Null Stone prospecting rows, and two recipe-selector audits. No cross-worker keys claimed.
- **23 output candidates x four independent current-Retail fields = 92/92 unknown.** Two selector audits have no output-field denominator. No unsupported zeros, synthetic chance, range midpoints or rank-copied expected quantities.
- **0 newly admitted legitimate conversions, 0 verified current-Retail numeric fields, 0 new independently sampled cohorts.** Four *previously omitted output-rank item identities* were corroborated at family level and are handed to master as candidates, not admitted rows.
- Read live assignments rev23, master batch020 QA, source-memory, research lessons, prior worker source reviews, observation schema, GameData.lua and StatYieldProfiles.lua before external discovery. Source-reuse status and caveats recorded in nine new source-review events.

## P0 — eight Midnight milling rows expose four missing rank-alternative IDs
The live source has eight `gd.mill` candidates (10 herbs each) and four `millGroup` families. Its output mapping uses **one fixed output item ID for BOTH input ranks** in each family. This is a valid provisional family lead, not proof that only that rank can appear. Cross-checking rank identities identifies four *additional* pigment item IDs omitted from those candidate output vectors:

| Herb inputs (R1/R2) | Existing assigned output | Existing output rank | Other verified pigment item ID | Other rank | Claim |
|---|---:|---:|---:|---:|---|
| Tranquility Bloom 236761 / 236767 | 245807 Powder | R1 | **245808** | R2 | family candidate; no skill-conditioned drop evidence |
| Argentleaf 236776 / 236777 | 245804 Argentleaf | R2 | **245803** | R1 | family candidate; no skill-conditioned drop evidence |
| Mana Lily 236778 / 236779 | 245866 Mana Lily | R2 | **245867** | R1 | family candidate; no skill-conditioned drop evidence |
| Sanguithorn 236770 / 236771 | 245864 Sanguithorn | R1 | **245865** | R2 | family candidate; no skill-conditioned drop evidence |

Evidence: [Method's Midnight inscription guide](https://www.method.gg/guides/midnight-inscription-profession-guide) independently lists the four herb-to-pigment families, [Wowhead spell 1269575](https://www.wowhead.com/spell=1269575/midnight-milling) confirms ten herbs, [Powder rank pair](https://thewowdb.com/item/powder-pigment-245807), [Argentleaf rank pair](https://thewowdb.com/item/argentleaf-pigment-245803/), [Mana Lily rank pair](https://thewowdb.com/material/mana-lily-pigment-245867/), [Sanguithorn R1](https://saddlebagexchange.com/wow/item-data/245864) and [R2](https://saddlebagexchange.com/wow/item-data/245865). Item-rank identity confidence ~85/100; exact skill-conditioned eligibility confidence ~30/100. **Do not automatically generate eight input→alternate-output conversions** until the selector and rank behavior are established. No duplicate output-rate assignment or 100% occurrence assumption.

## P0 — twelve authorized TWW milling overflow records
Exact source ID pairs `210796..210798→222616..222618` (Mycobloom), `210799..210801→222612..222614` (Luredrop), `210802..210804→224800..224802` (Orbinid), and `210805..210807→224803..224805` (Blessing Blossom) are present in StatYieldProfiles. [Method's 2024 guide](https://www.method.gg/guides/the-war-within-herb-milling-and-pigment-guide) supports the herb-to-pigment families and three ranks, but explicitly conditions output quality on herb quality, inscription level and knowledge choices. [Khaz Algar Milling spell 444181](https://www.wowhead.com/spell=444181/khaz-algar-milling) uses ten herbs. The current one-input-rank→one-output-rank vector is a **scenario**, not a universal output whitelist. All 48 field values remain null. No fresh ten-herb zero-inclusive histograms were found.

## P0/P1 — Null Stone 210939, three output claims
The original [Genyachris Wowhead comment](https://www.wowhead.com/item=210939/null-stone) says five Null Stones were prospected and reports **2 Handful of Pebbles 213398, 1 Stunning Sapphire 212508, 1 Ostentatious Onyx 212511**. The current StatYieldProfiles already summarizes this **same original author**; this run did not discover a second independent experiment. A new canonical raw observation preserves reported totals 2/1/1, consumed-input count 5, `completedOperations=null`, rank=null, patch=null, and all four per-output fields unknown. One *derived* five-stone equivalent is not an author-verified completed-cast denominator. The profile's `2.3/1.15/1.15` high estimates are modeled scenarios, not observed means. No safe current-Retail gold decision can use these figures as a population expectation.

## Recipe selector audits
- [Midnight Milling 1269575](https://www.wowhead.com/spell=1269575/midnight-milling): ten selected Midnight herbs per operation, no item-ID-level salvage whitelist in public spell text; do not assume Azeroot or any other herb is selectable without confirmation.
- [Midnight Crushing 1231132](https://www.wowhead.com/spell=1231132/midnight-crushing): three selected gems plus **one Dusk-Shrouded Stone**. The public spell page does not enumerate the gem whitelist or Gemdust rank. These are multi-reagent recipes, not ore-style one-input conversions.

## P2 — decision risk and QA
**High:** Missing R1/R2 pigment alternatives and fixed-rank-only output vectors can systematically under/overstate milling value; especially R2 Argentleaf and Mana Lily versus cheap R1 alternatives. **High:** Null Stone's single anecdote must not be extrapolated to expensive five-stone prospecting. **Medium:** TWW rank exclusivity and conditional skill yield can cause rank triple-counting. **High:** Crushing requires stone cost and verified gem eligibility. No verified AH-price-based action flip is asserted.
No new current-Retail cast histograms were found; Method/Icy Veins/WoW-Professions are guides, not independent output datasets. Avoided re-fetching prior JD3K/Cardinalai q22 sources; Genyachris was deliberately revisited only for exact q23 Null Stone keys and schema-safe normalization. No unrequested mechanics study, Node CLI, Lua load or client test.

## Master handoff
1. **Rank-alternative family candidates (not assigned new keys):** 236761/236767→245808; 236776/236777→245803; 236778/236779→245867; 236770/236771→245865. Validate skill/rank before admitting; preserve exact field unknowns.
2. **Current-Retail sample requests:** 236761→245807/245808 and 236776→245803/245804 with recorded cast count, skill, rank, zeros and Resourcefulness; then 210796→222616/222617/222618 at matched skill.
3. **Null Stone:** 210939→213398/212508/212511, obtain exact 5-input cast count, output ranks and modern patch. Do not promote 2/1/1 as current baseline.
4. **Selector captures:** 1269575 eligible herbs and 1231132 eligible gems plus stone rank, with in-client ID proof.
The q23 assignment is examined and ready for master QA/reassignment. Only worker-owned research files were written; main, Lua/TOC, shared master state, canonical registry, source-memory and schedules unchanged.
