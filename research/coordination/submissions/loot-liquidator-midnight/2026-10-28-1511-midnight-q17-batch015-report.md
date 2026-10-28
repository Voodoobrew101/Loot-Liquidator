# Loot Liquidator Midnight — queue 17 / batch 015 research handoff

**Date:** 2026-10-28 · **Branch:** `research/processing-confidence` · **Assignment:** `2026-10-28-batch015-midnight` · **Queue revision:** 17 · **Research only**.

## Exact work and QA
Audited **35/35 disjoint assigned keys**: 16 Midnight Crushing input-item candidates, 2 rank-refining recipe candidates, 17 existing prospect output numeric gaps (7 Eversong Diamond and 10 historical-reference output rows). Source ID check: **17/17** pinned main `GameData.lua` lines, SHA `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`. 16/16 assigned raw gem IDs have independently read item pages with matching names. Unique assignment keys 35/35; zero duplicate keys; all numeric invariants pass. No new current-Retail cast-level dataset, no newly approved exact conversion mapping, and no new master-approved numeric fields. Eight modeled deterministic fields for two refining recipes are **conditional provisional recipe descriptions**, not empirical current-client measurements. Ten existing historical prospect E references were preserved with context, not counted as ten new discoveries. The seven diamond E values stay **UNKNOWN** (not zero).

## P0: exact ID/name identity corroboration, but crushing eligibility still unresolved
The assigned 16 raw-gem IDs form **eight distinct same-name pairs** on Wowhead item pages. Do not collapse IDs by name or infer quality rank from numeric order. Each pair is two distinct item records, and the item page's plain text does not unambiguously expose the quality rank.

| Gem family | First ID | Same-name second ID |
|---|---:|---:|
| Sanguine Garnet | 242553 | 242723 |
| Amani Lapis | 242554 | 242722 |
| Tenebrous Amethyst | 242606 | 242721 |
| Harandar Peridot | 242607 | 242720 |
| Flawless Harandar Peridot | 242610 | 242726 |
| Flawless Tenebrous Amethyst | 242611 | 242725 |
| Flawless Amani Lapis | 242612 | 242727 |
| Flawless Sanguine Garnet | 242613 | 242724 |

Sources: https://www.wowhead.com/item=242553 and each `https://www.wowhead.com/item=<ID>` from the 16 assigned keys; independently fetched item pages on 2026-10-28. These are item identity confirmations, **not 16 verified crushing conversions**. The direct [Midnight Crushing spell](https://www.wowhead.com/spell=1231132/midnight-crushing) explicitly lists one Dusk-Shrouded Stone reagent plus salvage of three Midnight gems; the [WoWDB spell](https://www.wowdb.com/spells/1231132-midnight-crushing) states three gems but omits the additional reagent from its rendered listing. Treat this as a **source rendering discrepancy**, not evidence that stone cost is zero. Candidate vector is 3 of a single eligible gem ID + 1 Dusk-Shrouded Stone (rank-one item 242788 is a provisional numeric link). Spell 1231132 is Midnight Jewelcrafting skill 5, not generic all-expansion prospecting. Both Gemdust item IDs [242620](https://www.wowhead.com/item=242620/glimmering-gemdust) and [242621](https://www.wowhead.com/item=242621/glimmering-gemdust) exist and have the same name; exact rank-specific P and E are **unknown**, not two simultaneous guaranteed outputs.

Original [Cardinalai report](https://www.wowhead.com/item=242620/glimmering-gemdust) already in archive: 480 mixed quality gems, 160 stone, 330 Gemdust, 40.7% Resourcefulness, max knowledge. Derived 330/480=**0.6875 dust per nominal gem**, or 330/(480/3)=**2.0625 dust per nominal three-gem batch**. This is **not** an actual cast denominator, not a per-gem-ID E, and not a rank-specific dust output rate. Source reuse: 1 old original mixed-input cohort, 0 new independent studies. Resourcefulness returns are saved inputs, not produced Gemdust.

## P0: two assigned refining recipes — complete direct reagent vectors
- **Spell 1307466**: [live Refine Duskshrouded Stone](https://www.wowdb.com/spells/1307466-refine-duskshrouded-stone-a-professions-chaticon), **18** R1 stone → **1** R2 stone; provisional item links `242788→242789`; trainer Midnight Jewelcrafting 50, tools and bench. Modeled P=1, min=max=1, E=1 per successful eligible craft; confidence 86 support-strength, 0 casts.
- **Spell 1307462**: [live Refine Crystalline Glass](https://www.wowdb.com/spells/1307462-refine-crystalline-glass-a-professions-chaticon), **10** R1 glass → **1** R2 glass; provisional item links `242786→242787`; same trainer skill 50/tools/bench. Modeled P=1, min=max=1, E=1, confidence 82 support-strength, 0 casts. The [PTR listing](https://ptr.wowdb.com/spells/1307462-refine-crystalline-glass-a-professions-chaticon) shows 5+10 reagent display; do **not** add them to 15 in live valuation without client proof.

Recipe output is fixed *conditional on a successful legal craft*, not unconditional availability to every character. Exact reagent/output item rank links still require client verification, and neither recipe should be admitted as an exact input→output mapping until the master resolves that gate.

## P1: 17 prospect rows
The 17 assigned source-line rows comprise **7 Eversong Diamond `242608`** records and **10** existing R1/R2 byproduct/gem rows. All 17 P(hit), positive min and positive max remain UNKNOWN. Diamond E remains UNKNOWN due to ore-specific Proficient Processor specialization eligibility, with no measured zero. The other ten have historical `GameData.low` references (not measured exact-current per-cast values). Rank-one ore references transfer rank-two cohorts without an independently verified bridge. JD3K's 50 gross ore per ore type are not verified completed operations; no source-proven output rank histogram, skill context or patch bridge. Do not multiply occurrence probability by E or derive it from family totals. Raw source values and their lineage are preserved in the audit JSONL.

## P2: gold-optimal decision risks
- **Crushing:** 3× exact gem input market opportunity cost + 1× stone + processing time; expected dust output cannot be priced until output rank mix and eligible input are known. Do not apply 0.6875 to all 16 IDs as verified per-ID E.
- **Refining:** compare one R2 material against 18× R1 stone or 10× R1 glass plus transaction costs, skill/recipe/bench eligibility and opportunity cost. No live AH price queried; no actual gold-decision flip asserted.
- **Prospecting:** 7 diamond mappings require explicit ore-specific specialization gate; unknown E must not be priced as zero. No R1-to-R2 output-quality substitution.
- **Same-name ID pairs:** name-based deduplication could erase quality variants and produce wrong gold valuation. Use numeric IDs and rank-verified eligibility.

## Continuous improvement and next exact research targets
Read live queue revision 17, master batch014 verdict, master lessons and source-memory; source-memory is stale per master and not an authoritative freshness claim. Reused JD3K, Cardinalai, live/PTR spell descriptions without treating their derivative guides as new independent cohorts. 16 item-page identity fetches resolved exact names and avoided repeated unstructured searches; source-review events preserve remaining gaps and re-fetch triggers. No new empirical cohort. Source strategy: next fetch only in-game salvage whitelist / spell `1231132` eligibility and gemdust rank output histogram; rank-specific gem IDs need client UI/DB2 verification. Next exact IDs: `242553,242723,242554,242722,242606,242721,242607,242720,242610,242726,242611,242725,242612,242727,242613,242724`; `242620,242621`; `242786,242787,242788,242789`; spells `1231132,1307462,1307466`; prospect ore IDs `237359,237361,237362,237363,237364,237365,237366`. No other worker's keys claimed.

**Master baseline (pre-review):** candidate v0.4.0 984 provisional mappings, 165 input IDs, 799 four-field numeric-complete, 403 unknown cells, 0 verified unskilled current Retail baselines; exhaustive Retail universe remains unverified. Master owns compilation and acceptance. No production Lua/TOC, main, shared ledgers, assignments, canonical registry, source-memory or schedules changed.
