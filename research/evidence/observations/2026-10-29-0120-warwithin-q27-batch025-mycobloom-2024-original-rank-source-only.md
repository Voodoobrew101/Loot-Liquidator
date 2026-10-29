# War Within q27 Batch 025 — primary-source milling rank evidence (research only)

Date retrieved: **2026-10-29**. Assigned exact keys: **12**, queue revision **27**. Original 2024 and 2025 player observations are historical Retail evidence, **not 2026 verified outcomes**. All direct source relationships below remain provisional and require master QA admission.

## New original author, not previously in source-memory

Source: https://www.reddit.com/r/woweconomy/comments/1fdmzwy — **2024-09-10** original r/woweconomy post and author's replies. Author says they milled **20,000+ herbs total**, without reporting split by input rank, actual completed operation counts, skill values, equipment, specialization or zero-inclusive cast histograms. They report Mycobloom **R1 producing Nacreous Pigment R2** at **1.15 pigments per herb** and Mycobloom **R2 producing Nacreous Pigment R2** at **1.35 pigments per herb**. Their illustration uses **100 nominal ten-herb R2 crafts → 1,350 R2 pigments**. Author also explicitly states their earlier lower-skill **100 R1 Mycobloom → 135 R1 Nacreous Pigment**. A respondent suggests base returns **1.1/1.3 per herb** without resourcefulness; the original author acknowledges the correction. **Neither the suggested baseline nor the original ratios are clean, zero-inclusive current-Retail per-cast expected quantities.** The 20k+ sample is across unknown cohort splits; 100-craft illustration is not an independently documented sample denominator. Do not conflate resourcefulness saved inputs with extra produced pigments.

### Direct historical output-rank relationships within assigned q27 keys

- `lead:tww:mill:210796:222618:rank-eligibility-unverified` — R1 Mycobloom `210796` → R1 Nacreous `222618`: source author reports earlier R1 output from R1 herb at lower skill. Mapping evidence provisional **65/100**, 2024 patch; **not** a measured current Retail probability.
- `lead:tww:mill:210797:222619:rank-eligibility-unverified` — R2 Mycobloom `210797` → R2 Nacreous `222619`: source author directly reports R2 output from R2 herb. Mapping evidence provisional **70/100**, 2024 patch; **not** current gold EV.

Unassigned but relevant **master-only follow-up**: R1 Mycobloom `210796` → R2 Nacreous `222619` is explicitly described by the original author and corroborated qualitatively by a **2025-03-15** community discussion (https://www.reddit.com/r/woweconomy/comments/1jc2ya5). Do **not** self-claim or compile that unassigned key; request master assignment/QA. This also demonstrates why one-to-one rank mappings are not exhaustive.

## Recipe and source lineage

- Retail Khaz Algar Milling spell **444181** (https://www.wowhead.com/spell=444181/khaz-algar-milling) specifies **10 herbs** per operation, salvage crafting data value 10; not 5. Input count is a recipe fact, not a measured output yield.
- Reused https://www.method.gg/guides/the-war-within-herb-milling-and-pigment-guide, **2024-08-10**, identifies Mycobloom→Nacreous, Luredrop→Luredrop, Orbinid→Orbinid, Blessing Blossom→Blossom and says output rank depends herb quality, Inscription skill and knowledge. It claims herb rank does **not** increase pigment quantity. Later independent September 2024 player observations report **rank-dependent yield**, a likely historical version/mechanics disagreement. No fixed universal yield coefficient is defensible.
- Reused LotzBoi Wowhead original comment (https://www.wowhead.com/item=224802/orbinid-pigment) describes illustrative 4–6/5–7/6–8 per 10-herb rank family; one author copied across item pages, not 12 independent per-output histograms. Its ranges differ from other authors' 11–15 historical examples; **do not** replace measured bounds or manufacture per-output min/max.
- March 2025 player replies in https://www.reddit.com/r/woweconomy/comments/1jc2ya5 confirm that sufficiently skilled scribes can mill R1 herbs into R2 pigment and often receive fewer units than using R2 herbs; no exact cast denominators, IDs or probabilities.

## Numerical context, never current economic field values

| Historical original-author statement | Per-herb ratio | Nominal per-10 equivalent | Exact current-Retail completed-cast E? |
|---|---:|---:|---|
| R1 Mycobloom → R2 Nacreous | 1.15 | 11.5 | **NO** — unassigned tuple, cohort/context confounded |
| R2 Mycobloom → R2 Nacreous | 1.35 | 13.5 | **NO** — assigned lead, cohort/context confounded |
| R1 Mycobloom → R1 Nacreous (earlier lower skill) | author illustration 135/100 | 13.5 per nominal 10-herb craft | **NO** — illustration not cast histogram |
| Respondent's claimed no-resourcefulness base | 1.1 / 1.3 | 11 / 13 | **NO** — independent underlying data absent |

**No output-specific P(hit), positive yield min/max or current-Retail economic expectedQuantity can be promoted.** Sample denominators remain unknown by exact input/rank/skill. Economic decision risk: overvaluing R1→R2 as though its output equals R2→R2; resourcefulness affects input costs, not produced quantities. No current TSM matched rank-specific E was found in the source processing ledger, so no numerical TSM disagreement or AH decision flip is asserted.

## Next exact targets

1. Master QA evaluate 210796→222618 and 210797→222619 for provisional mapping admission (2024 direct evidence, 2026 eligibility unverified), without numerical EV.
2. Master QA assign **210796→222619** separately if desired; it is outside this worker's exact q27 keys.
3. Obtain per-operation cast logs for each of the 12 assigned tuples: actual input/output ranks, 10-herb consumed, effective skill, knowledge, gear, resourcefulness, patch, zero-inclusive hits, and output counts. Plot-group before modeling.
