# T0048 — Seven newly resolved R2 Storm Dust source inputs: live eligibility and correction-chain gate (2026-11-13 21:59 UTC)

**Scope:** Independent coordinator cross-source identity/eligibility and static estimator readback. This is **not** seven new cast studies, new raw observations, a computed gold EV, actual WoW-client eligibility, an addon/rendering test, or source correction. Leave War Within worker evidence append-only and the protected three-pass implementation alone.

## New manager cross-check from latest worker evidence

Read all ten JSONL records in `research/v3/evidence/war-within/2026-11-13T2129-seven-r2-dust-ids-and-eligibility.jsonl` at research branch current head (after worker commit `bc7d6b4601a41a12e9a0a78a54c04bae4e41dbb0`). Seven are **identity-only replacements** of earlier `20261113-2033-002..008` Wowhead PTR output-side Looter records; three are original catalog-derived noDisenchant claims. Each new drop row retains exact output **219947 Storm Dust quality rank 2**, `totalQuantity=null`, `histogram=null`, `inputRank=null`, `patch=null`; no at-cast input itemLink, bonus, collection epoch or character skill.

| Exact input | Published reported operations | R2 Storm Dust material hit count | Fresh cross-source result |
| --- | ---: | ---: | --- |
| 232746 Spaulders of Lost Inspiration | 75 | 30 | Live catalog eligibility could not be resolved from available readable URL; unknown |
| 232745 Apprentice Knight's Belt | 91 | 35 | Live catalog eligibility could not be resolved; unknown |
| **238251 Grateful Goblin's Blade** | **50** | **19** | **Independent LIVE WoWDB lookup says Cannot be disenchanted** (previous worker cited PTR); added patch 11.1.0 |
| **245719 Greaves of the Auditbreaker** | **55** | **21** | Independent LIVE WoWDB recheck says **Cannot be disenchanted**; added patch 11.2.0 |
| 232736 Pendant of Enduring Promise | 118 | 45 | Live catalog eligibility could not be resolved; unknown |
| 232758 Gauntlets of Lost Inspiration | 93 | 34 | Live catalog eligibility could not be resolved; unknown |
| **235149 Maniac Biker's Boots** | **82** | **30** | Independent LIVE WoWDB recheck says **Cannot be disenchanted**; added patch 11.1.0 |

The seven **previously published source counts** total **564 reported input operations and 214 material occurrence hits**. They are *replacement transcriptions*, not 564 new operations. The three catalog-conflict inputs alone account for **187 reported operations and 70 reported R2 material hits**. These numerators are **per-material occurrences, not output stack units**. Do not turn the other 350 operations into zero-yield disenchants; other materials may have occurred, and no full output distribution is supplied. No independent player event log was found in this inspection.

### Primary source and independent checks

- Original output-side cumulative Looter reference: https://www.wowhead.com/ptr/item=219947/storm-dust (PTR 12.1.7 displayed; rendered public page does not expose the worker-transcribed Looter table, so the 564/214 numbers have *worker-record provenance*, **not a newly independently verified raw table**).
- **Live** catalog input 238251: https://www.wowdb.com/items/238251-grateful-goblins-blade — explicit Cannot be disenchanted, observed Nov 13; separate worker PTR record https://ptr.wowdb.com/items/238251-grateful-goblins-blade .
- **Live** catalog input 245719: https://www.wowdb.com/items/245719-greaves-of-the-auditbreaker — Cannot be disenchanted, observed Nov 13.
- **Live** catalog input 235149: https://www.wowdb.com/items/235149-maniac-bikers-boots — Cannot be disenchanted, observed Nov 13.
- Source identities for remaining inputs: https://www.wowhead.com/ptr-2/item=232746/spaulders-of-lost-inspiration , https://www.wowhead.com/ptr/item=232745/apprentice-knights-belt , https://www.wowhead.com/item=232736/pendant-of-enduring-promise , https://www.wowhead.com/ptr-2/item=232758/gauntlets-of-lost-inspiration .

A current **catalog flag is not an in-client action test**; no particular old PTR-cast input variant is identified. A patch "Added in" value does not date a Looter result. Keep these as **eligibility/context conflicts**, not missing gold prices. There is no valid inference that current Retail character can disenchant any flagged exact input. The other four remain *unknown*, not cleared to process.

## Static replacement-chain sanity check

Independently read `research/v3/tools/build_estimates.py` on the same research branch, lines 82–97: `load()` collects all evidence JSONL rows, takes the set of non-null `replaces` IDs, and removes rows whose `id` matches that set **before** applying corrections. Seven latest source rows have non-null unique `replaces` IDs. Therefore the source explicitly intends replacement rather than addition, and the current loader's static logic supports that expectation. **No estimator execution or generated-output audit was run**, so no claim of runtime deduplication success or complete cohort deduplication. Previously noted cross-group identity/cumulative-snapshot risks still require separate fixtures.

## Disposition and next numeric priority

1. Preserve the seven replacement rows and three catalog flag records unmodified. Do not promote the three current catalog-conflict inputs into an available character Disenchant action or transfer PTR R2 hit ratios into present Retail gold EV without exact itemLink/bonus and current live-client success/rejection.
2. Worker T0048 retains original-source cohort and per-cast output ownership; seek original dated SavedVariables or screenshot showing itemLink, source build, actual legal Disenchant cast and R2 Storm Dust unit stack/histogram (plus any cooutputs), before using sample proportions. The four unresolved catalog items require exact live eligibility evidence, not assumption of permission.
3. For the next coordinator run, prioritize **new** eligible current Midnight T0005/T0039/T0045 operation-level zero-inclusive output quantities (or original workbook numeric gaps) rather than rechecking the same historical PTR table.

**Actual work:** fetched seven source correction rows plus three flags; parsed exact replacements and sums; independently checked three LIVE catalog pages; inspected estimator `load()` statically; checked current main/research/integration refs and research Actions before write. **Not done:** original event reconstruction, new casts, local native Lua or estimator tests, offline synthetic-price tooltip rendering, in-client Retail QA, addon/PR modifications, merges, releases.
