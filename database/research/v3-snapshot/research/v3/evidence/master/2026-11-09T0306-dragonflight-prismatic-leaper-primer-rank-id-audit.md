# Prismatic Leaper 200061 — original Primer output rank identity crosswalk (2026-11-09 UTC)

**Scope:** research-only QA for queue T0013/T0041 and strategy S32. This is a cross-source identity recovery for an **existing** original three-mill cohort, **not** a new independent study, new measured cast, or runtime/tooltip proof. No edits to worker evidence, compiled data or protected three-pass branch.

## Original outcome and arithmetic (no inferred P(hit))

- Original firsthand Wowhead item page, Primer comment: https://www.wowhead.com/item=200061/prismatic-leaper
- Author expressly processed **15 fish, 5 per mill = 3 completed mills**; reported outputs **3 Serene Pigment R2**, **2 Flourishing Pigment R3**, **5 Flourishing Pigment R2**.
- Preserve three *different rank-qualified* material rows, not one family row and not another copy of this original study. Per 5-fish completed mill, the corresponding **reported pooled unconditional units** are 3/3=1, 2/3 and 5/3 respectively. These are three-cast sample ratios, **not calibrated current Retail rates**. Output-specific positive-hit counts, zero histograms, min/max stack and conditional yields are all unknown. No independently measured casts or output units were collected by coordinator.
- The original post gives no explicit date of in-game collection, character skill, build, exact input itemLink, refunds, or per-operation distribution. Do not apply present-day game eligibility, stat coefficient or chance confidence based on this old record.

## External identity checks, separate from the original numeric source

| Original source row | Candidate exact Retail item ID | Independent identity source | Confidence / gate |
| --- | --- | --- | --- |
| Serene Pigment R2 x3 | **198413** | https://goldcap.gg/retail/kr/items/198413 explicitly identifies quality rank 2 of 3; https://www.wowhead.com/item=198413/serene-pigment identifies family | Exact catalog identity supported; original comment does not show output itemLink |
| Flourishing Pigment R3 x2 | **198417** | https://wowpricehub.com/eu/tarren-mill/item/Flourishing%20Pigment-198417 identifies TIER_3; https://www.wowhead.com/item=198417/flourishing-pigment confirms family | Exact catalog identity supported; original comment lacks direct output link |
| Flourishing Pigment R2 x5 | **198416** | https://saddlebagexchange.com/wow/item-data/198416 explicitly titles Quality 2; https://www.wowhead.com/item=198416/flourishing-pigment confirms family | Exact catalog identity supported; original comment lacks direct output link |

Source [Warcraft Wiki Prismatic Leaper](https://warcraft.wiki.gg/wiki/Prismatic_Leaper) independently confirms the fish is millable and lists the pigment families (not a three-cast numeric sample). Original [Jan 2023 Reddit discussion](https://www.reddit.com/r/woweconomy/comments/100anp2) also states 5 fish per mill and includes firsthand comments asserting Resourcefulness does not proc on fish, **but this is not a verified present-day mechanic**, coefficient or extra sample. Keep refund/resourcefulness behavior unknown pending build-specific validation.

**Source separation / duplicate prevention:** Existing research record IDs `dragonflight-20261102-003..005` and queue T0013 already describe this exact Primer 15-fish sample. Do not append drop rows or increment observed sample counts. Existing compiled Mill 200061 x5 reference includes IDs 198413/198416/198417/**198419**, according to queue strategy S32; **198419 is not an outcome in Primer's three reported rows**. Retain any separately sourced Blazing pigment reference only under its own source/provenance and rank; do not misattribute it to Primer or treat a model's fourth material as one of Primer's observations.

**Next engineering handoff (not executed):** compare exactly these three mapped rank-qualified original rows to current pinned 4df9ae8 lineage and current three-pass ItemDB ingestion; guard against double ingestion and preserve separately sourced 198419. Validate `Mill 200061 x5` with actual offline synthetic-price engine/tooltip fixture **only in the protected implementation owner's branch**; test field status when rank-specific prices are missing and test method/character eligibility independently. No addon, source compiler, client, or GitHub Actions tests were executed for this note.
