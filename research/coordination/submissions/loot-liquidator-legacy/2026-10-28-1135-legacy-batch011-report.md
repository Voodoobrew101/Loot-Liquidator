# Loot Liquidator Legacy — Batch011 P0 itemdb completeness research
**Run:** 2026-10-28-1135-legacy-batch011. **Branch:** `research/processing-confidence`. **Queue:** rev13, exact assigned 40 `profile:compiled:mill:...` keys. **Production GameData blob:** `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`. Research-only additive submission, no production/main/queue/master ledger edits.

## P0 coverage first: item-ID collision with a false milling input
**Critical confirmed identity distinction:** item **36721** is a *Dragon's Teeth thrown weapon*, not a herb. The similarly named actual millable herb is **3819** (Dragon's Teeth). [36721 item](https://www.wowhead.com/item=36721/dragons-teeth); [3819 herb](https://www.wowhead.com/item=3819/dragons-teeth); [independent Indigo Pigment herb association](https://www.wowhead.com/item=43105/indigo-pigment). `main/GameData.lua` contains an empty `gd.mill[36721]` candidate; `StatYieldProfiles.lua` already suppresses this candidate because it has no material outputs. **Do not ship an itemdb milling recipe for 36721**; master must validate the source-universe correction and preserve 3819 -> 39339/43105. This is an ID-identity/eligibility finding, NOT a numeric zero-yield observation.

## P0 40 assigned keys: 39 supported historical output mappings, 1 false candidate
All 40 assigned stable keys were `NEVER_EXAMINED` in the current master coverage ledger at read. **39** have historical TSM milling mappings, **76** distinct input/output rows. **All 40** compiled `gd.mill` profiles have **zero** static material outputs. The 39 mappings agree by herb/pigment family with the [retail-oriented WoW-Professions milling table](https://www.wow-professions.com/guides/milling-table-inscription); this establishes historical eligibility and plausible output identity, **not** 2026 live recipe availability or yield. Item 36721 has no TSM rows and is a thrown weapon. Exact 40-key census and 76 output candidates are attached in the CSVs.

**Compile recommendation:** For 39 eligible candidates, retain each input ID, batch=5, output IDs, historical TSM source, and explicit provisional unknown current-patch/skill/recipe ID. A complete itemdb must not silently replace missing P(hit) or yields with zero or present TSM as measured. Reject 36721 pending master identity decision. TSM is currently an independent runtime fallback, not a guarantee the future single itemdb has these rows.

## P1 source-backed provisional four-field candidates
The 76 TSM rows carry `matRate`, `minAmount`, `maxAmount`, and `amountOfMats` per original herb. We transcribed source values and converted **expectedQuantity exactly once** to a five-herb operation as `E5=5*amountOfMats`. Historical `matRate` and ranges are labeled **unverified source assumptions**, not original zero-inclusive observed P(hit)/conditional bounds. All 76 pass necessary `0<=P<=1`, integer positive range, and `P*min<=E5<=P*max` arithmetic; that alone does not validate common denominators or actual game mechanics. Proposed field confidence: P=22, min/max=25, E=28 (0–100 support strength, NOT measured accuracy probability). Original TSM sample count, patch, skill and rank conditions unknown. **No numeric current-Retail correction approved.**

## New original study: 2009 revised killerpet Northrend milling table
Recovered original author [killerpet's updated 2009 table](https://www.wowhead.com/wotlk/item=39343/azure-pigment), which supersedes the earlier 1473/399/255/540-mill snapshot copied to the Milling spell page. **One author, four assigned herb cohorts, not four independent experiments; no duplicate counting.** Original actual cast counts and rounded means:

| Input | Reported mills | Azure original / TSM | Icy original / TSM |
|---|---:|---:|---:|
| Goldclover (`36901`) | 313 | 2.57 / 2.6800 | 0.24 / 0.4375 |
| Tiger Lily (`36904`) | 871 | 2.45 / 2.6800 | 0.25 / 0.4175 |
| Adder's Tongue (`36903`) | 1975 | 2.98 / 3.0000 | 0.53 / 0.5375 |
| Lichbloom (`36905`) | 705 | 3.03 / 3.0000 | 0.52 / 0.5375 |

The original study supplies **eight historical unconditional expected-quantity means** (four inputs × two outputs), but **no exact unrounded material totals, per-cast hits, zero histograms or conditional integer ranges**. The source's two-decimal rounding alone permits approximately ±0.005 units/cast, before sampling uncertainty. The author does not report actual cast dates, skill, gear or a 2026 patch bridge. Raw source-only observations in JSONL preserve these unknowns and historical applicability; do not promote the 2009 means as current unskilled baselines.

An independently authored [Sgtown 128-cast Adder's Tongue experiment](https://www.wowhead.com/wotlk/item=39343/azure-pigment) was previously archived; its 383 Azure/128=2.9922 and 61 Icy/128=0.4766 are descriptively compatible in Azure but lower in Icy than killerpet's 2.98/0.53. Patch and profession context are insufficient for formal weighted pooling. The 2008 PTR Earthroot denominator contradiction remains unresolved: 29 enumerated positive outcomes, 12 claimed stacks and 76 pigment units; no zero padding.

## P2 highest possible gold-decision discrepancies
Historical TSM predicts Goldclover Icy `0.4375` versus original 2009 `0.24` per five-herb operation (**-0.1975**); Tiger Lily Icy `0.4175` versus `0.25` (**-0.1675**). If an Icy Pigment sells for `G` gold net of auction fees, these isolated historical differences alter the predicted material value by `0.1975*G` or `0.1675*G`, before other outputs. **No live auction prices or current Retail sampling available, so no actual recommendation reversal asserted.** Prioritize matched current-Retail zero-inclusive Goldclover and Tiger Lily casts.

## P3 separate Felslate mechanism (BLOCKED, no numeric promotion)
The prior [2017 original worksheet](https://www.scribd.com/document/359130779/full-legion-worksheet) reports 10,000 ore in each standard and mass arm; [mass recipe](https://warcraft.wiki.gg/wiki/Design:_Mass_Prospect_Felslate) nominally consumes 20 versus standard 5. Source uncommon totals 2063/2070 and rare totals 341/334 produce descriptive five-ore-equivalent means, but actual operations, exact output IDs, skill/gear and patch matching remain absent. No verified mass multiplier or universal curve. The new candidate explicitly retains `BLOCKED` and `numericTransformValidated=false`.

## Independent QA and next exact targets
- 15 deterministic source-identity, disjoint assignment, arithmetic, and observation-required-field assertions passed. **Full external JSON Schema validation, Node suites and in-game tests NOT run.**
- First-pass submission: **40 source profiles for master review**, not 160 newly verified output fields. Proposed 39 `EXAMINED_INSUFFICIENT`, one `BLOCKED_PENDING_MASTER_ID_CORRECTION`; master owns acceptance and any change to known-universe denominator.
- New original study families: **1**; new historical cohorts: **4**; original rounded output means: **8**; previously analyzed 2008 PTR and 2017 worksheet reused, duplicate 2009 copied snapshot avoided. Source-review events: **4**; no self-awarded rewards.
- Master-accepted baseline before this submission: **1,493/1,737** known source keys examined, **244** never examined, **zero** complete >=90 four-field records. This is **NOT** a claim of exhaustive 2026 Retail conversion coverage.
- **Next:** (1) master exclude 36721 false milling input, retain 3819 herb; (2) current-Retail Goldclover 36901 and Tiger Lily 36904, 200+ actual five-herb casts each, exact P(hit), conditional ranges, output IDs, skill/build and refunds; (3) Earthroot 2449 original 19 missing operations; (4) Felslate same-build matched standard/mass; (5) master-directed overflow only when reassigned.

Evidence confidence is 0–100 strength of support, not probability the number is correct. All data remains research-only and is not a second shipped mapping.
