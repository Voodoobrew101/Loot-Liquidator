# TGEXP original legacy ore prospecting — pooled input-unit normalization and Retail applicability gate

Verified UTC: 2026-11-13T11:02:59.707Z. Research-manager source/field review for **T0042**, with relevance to legacy prospecting **T0021/T0022/T0044**; this is a verification of a newly added **worker source**, not a new cast study or a modification to worker originals.

## Primary source and newly indexed worker report

- Source: [TGEXP In-Depth Jewelcrafting Guide](https://tgexp.com/jc-guide/), section **Uncut Gems & Where to Gather / Vanilla WoW**. The page says its *guide* was refreshed for **patch 8.3**, but does **not** give the acquisition date, patch, client build, skill, method clicks or realm of any original ore sample. Do not assign patch 8.3 as the collection patch.
- Worker original: [legacy first-person ore quantity evidence](../legacy/2026-11-13T1046-tgexp-classic-ore-originals.jsonl), commit `ca5c2cbf6ee952f0d7148d962d4ddf56ada72260`; 15 JSONL output rows representing only three source-claimed processed-ore groups. Preserve all 15 IDs and the 3 original studyKeys. The worker correctly keeps `casts`, `castsWithDrop`, histograms, patch, source date, and player stats **null**.
- The page separately lists **farming-route acquisitions**, distinct from **ore prospecting**. Farming gem counts must not be added to prospect output quantities. Independent game records or exact output rank/bonus are not supplied.

## Exact first-person material totals and non-cast normalization

| Original input and reported ore | Source item-specific material units | Total units across listed outputs | Purely arithmetic units per *reported* ore | Conditional normalization per nominal **5 ore**, not observed casts |
| --- | --- | ---: | ---: | ---: |
| Mithril Ore **3858**, **1,000 ore** | Citrine 3864 **85**; Aquamarine 7909 **70**; Star Ruby 7910 **71**; Blue Sapphire 12361 **4**; Huge Emerald 12364 **4**; Large Opal 12799 **7**; Azerothian Diamond 12800 **6** | **247** | **0.247** | **1.235** |
| Thorium Ore **10620**, **1,000 ore** | Star Ruby 7910 **31**; Blue Sapphire 12361 **72**; Huge Emerald 12364 **67**; Large Opal 12799 **74**; Azerothian Diamond 12800 **62** | **306** | **0.306** | **1.530** |
| Copper Ore **2770**, **200 ore** | Malachite 774 **22**; Tigerseye 818 **18**; Shadowgem 1210 **22** | **62** | **0.310** | **1.550** |

**Verified arithmetic:** 7+5+3 = **15** unique material rows; summed output material units **247 + 306 + 62 = 615** (units, **not** material hit events). Normalization divides each total by the page's stated ore denominator; multiplying by five gives an explanatory proxy under a nominal five-ore processing batch. The guide independently describes prospecting in fives; it does not expose a per-click log. Therefore **200/200/40** are hypothetical *batch equivalents* for 1,000/1,000/200 reported ore, not observed casts, and the display-only 1.235/1.530/1.550 figures are **not** measured per-cast expected yields. Material-specific source ratios can likewise be computed from the preserved integer totals, without fabricating occurrence probability, zeros, histograms or conditional unit counts.

**Economic disposition:** These are **source-present, provenance-qualified historical raw quantities**. They may support a labeled historical reference **per-input opportunity-cost scenario only if** the compiler and owner-approved historical applicability/recipe assumptions explicitly support that scope. They must **not** be admitted as present-patch Retail cast rates, exact eligible current-character recommendations, measured probability confidence, or three independent source experiments per material. The timestamp on a guide refresh is not an observed patch. No ranking, refund, skill-scaling, modern version or other coefficient can be inferred. Preserve source groups and source-to-output identity without mutating older evidence or existing usable values.

## Reproducible validation and follow-up

Actually executed: opened and read the original public HTML; compared all 15 material quantities with the committed worker JSONL; calculated exact group totals and input-unit arithmetic from those integer records; verified 15 unique worker IDs, three studyKeys and null for all completed-cast, hit, histogram and source-date fields; reviewed the current research queue and worker status, source schema/mechanics and protected three-pass plan. **Zero** new player casts, probabilistic estimates, live Retail eligibility/price decisions or new current-patch processing studies.

Not executed: ingestion/estimator rebuild, actual offline addon valuation/formatter at synthetic prices, native Lua test suite, real WoW client testing, or any work on integration/main/PRs. The latest research CI is not evidence of those tests.

**Next research-only step:** Seek original source acquisition date/version or original SavedVariables/log for those three ore groups, and any direct confirmation that each repeated input denominator belongs to a single pooled run. Retain provisional input-unit ratios as historical context only; prioritize original **current-patch** Midnight T0005/T0039/T0045 per-operation output and refund receipts over repeating these historical quantities. No duplicate worker study requested.
