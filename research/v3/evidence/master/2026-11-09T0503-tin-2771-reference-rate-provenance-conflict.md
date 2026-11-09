# Coordinator T0042 — Tin Ore 2771 historical reference-rate conflict and source lineage
Verified at 2026-11-09T05:04:54.890Z UTC; original pages directly read, worker original JSONL read. **Research-only source reconciliation, no new casts or accepted live rates.**

## Source-to-field comparison (historical references, not empirical samples)

| Source | Earlier Wowhead Classic forum table, contributor Xreemir (post date not displayed) | Psynister 2011-02-02 guide | Relevant item ID |
| --- | ---: | ---: | ---: |
| Moss Agate | 38% (source model 1–2 stack) | **37%** (source model 1–2 stack) | 1206 |
| Lesser Moonstone | 38% (source model 1–2 stack) | 38% (source model 1–2 stack) | 1705 |
| Shadowgem | **37%** (source model 1–2 stack) | 38% (source model 1–2 stack) | 1210 |
| Aquamarine | 3% | 3% | 7909 |
| Citrine | 3% | 3% | 3864 |
| Jade | 3% | 3% | 1529 |
| Tin Powder | **100%** model claim | not listed in this table | 24188 |

Source A: https://www.wowhead.com/classic/forums/topic/arcane-crystals-78702 (Tin subsection). Source B: https://psynister.wordpress.com/2011/02/02/professions-leveling-jewelcrafting-1-525/ (Jewelcrafting prospecting table). The three common percentages have the same multiset but the **Moss Agate and Shadowgem assignments differ by one percentage point**. The rare-gem 3% values and Lesser Moonstone 38% match. Both are unsourced **reference tables**: identical figures do *not* establish independent experimental cohorts; the underlying table lineage, denominators, date of the forum post and client versions are unknown. Do not pool or statistically weight A and B as independent samples; preserve both original values and source URLs. Do not silently reverse worker records or change the estimator.

## Actual original 20-operation worker cohort — separate from both model tables

Legacy's already-written `research/v3/evidence/legacy/2026-11-09T0444-tin-original-and-reference-priors.jsonl`, study key `wowhead-allakhazam-tin2771-100ore-20completed-prospects`, matches the firsthand Allakhazam comment visible at https://www.wowhead.com/wotlk/item=2771/tin-ore: **100 Tin Ore, explicitly 20 prospect attempts**, reported aggregate output units 24188=20 Tin Powder, 1705=12 Lesser Moonstone, 1206=10 Moss Agate, 1210=9 Shadowgem. Arithmetic zero-inclusive **historical E[units/operation]** is 1.00, 0.60, 0.50, 0.45 respectively (totals divided by 20). No per-output positive-cast counts, stack histogram, rarity/profile, patch date, resourcefulness or verified modern Retail context. **Do not derive P(hit) from these quantities** or claim Tin Powder P=100% from this one cohort; 20 units could have co-occurred in fewer than 20 operations.

The worker's six guide-prior rows `legacy-20261109-005..010` accurately transcribe **Psynister's** variant (Moss Agate 37 / Shadowgem 38); they are not new measured casts. The earlier forum's alternative (Moss Agate 38 / Shadowgem 37) and Tin Powder 100% are *additional source-supported candidate reference fields only*, neither independently verified nor suitable for automatic promotion over working values. Non-Retail source editions are historical context, **not the owner's excluded MoP Classic illustration** and do not authorize 2026 Retail extrapolation.

## Impact, validation and next

**New finding:** two source-model rank/identity assignments for 1206 and 1210 cannot both be reported as a single exact historical prospect chance without a provenance choice; the pre-existing 20-operation outputs support E but not either chance model. This is a *source conflict*, not an established tooltip regression or price problem. T0042 owner should preserve alternative provenance and, only if useful for gap filling, seek the original upstream model denominator/version. No additional worker request for a duplicate study. Number of new independent casts/cohorts **0**; new accepted measured P/conditional ranges/current Retail economic decisions/tooltip tests **0**.

Performed: directly fetched both reference tables and original Allakhazam comment; checked all ten worker JSONL rows and calculated exact totals/20; checked prior repo evidence for duplicate Serevite source and earlier workbook formula QA instead of reentering them. No compiler, Lua, synthetic-price renderer or live client execution. No worker original, source, pricing, addon branch, PR, merge or release changed.
