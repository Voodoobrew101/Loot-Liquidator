# Coordinator T0048 — Refulgent Crystal output-rank identity (Retail catalog, not loot-rate evidence)

Checked UTC: 2026-11-13T15:08:58.477Z. Repo: Voodoobrew101/Loot-Liquidator; reviewed main `b6610848604f68f8f3b40834397b79ce53eb8fb5`, research prewrite `1f578139c8018a0502108578580dba65e47563ee`, protected integration `3d667d053db587c91401cfed7ecc56862b8340c9`. This is a source-to-output-identity audit. No new original casts or studies.

## What is independently confirmed

Retail The War Within item catalogs explicitly label **Refulgent Crystal** as quality **rank 1 = 219952**, **rank 2 = 219954**, **rank 3 = 219955**. These are distinct item IDs with distinct prices, not alternative names for the same stack. Retail-labeled source pages:

- [Rank 1 / 219952](https://goldcap.gg/retail/us/items/219952) (Quality rank 1 of 3); [Wowhead item 219952](https://www.wowhead.com/item=219952/refulgent-crystal)
- [Rank 2 / 219954](https://goldcap.gg/retail/tw/items/219954) (Quality rank 2 of 3); [Wowhead item 219954](https://www.wowhead.com/item=219954/refulgent-crystal)
- [Rank 3 / 219955](https://goldcap.gg/retail/us/items/219955) (Quality rank 3 of 3); [Wowhead item 219955](https://www.wowhead.com/item=219955/refulgent-crystal)

The current `main` source `database/sources/ResearchDB.lua` already lists `[10].quality[4].candidates={219952,219954,219955}`, marked `legacy-candidates-only-unverified`. The table's `quality[4]` refers to **epic item rarity**, not a fourth reagent-quality rank, and the source list order must never be assumed to match an original loot-table row order. This audit corroborates item ID↔reagent rank only; it does not validate any probability, client itemLink variant, eligible disenchant or rank-specific sample assignment. This does not change the current source record's uncertainty label or its runtime implementation.

## Remaining high-impact T0048 source gap

The [War Within worker status](../../../coordination/quiet-status/war-within.json) reports new undated cumulative Wowhead Looter rows for epic gear **229258 (33 operations; 18/8/7 reported same-name row hits), 212069 (143; 72/41/21), 211999 (40; 32/5/3), 212085 (142; 68/49/24)**. The rows' actual linked output IDs/quality ranks remain **unknown**: the source names alone cannot tell which row is 219952, 219954 or 219955, and the three row totals must not be assigned to ranks by frequency or display order. The original [229258 item page](https://www.wowhead.com/item=229258/gale-sovereigns-bracers) and [212069 page](https://www.wowhead.com/item=212069/hexflame-covens-shawl) presently render basic metadata to web readers, not the underlying original Looter row links (JavaScript-dependent); this is an access limitation, **not** negative evidence. Three same-name material rows can share an operation denominator, and non-exclusive material occurrence rows must not be treated as separate studies.

Ask the existing War Within T0048 owner to capture the **source row href/item-ID** or original Looter export together with gear bonus/ilvl, source patch/epoch, skill/spec and per-operation stack quantities. Retain rankless occurrence counts as source-only pending linkage. Never convert `castsWithDrop` to output total units, assume one-unit output as measured, infer overall zero-casts, aggregate ranks at independent prices or claim a tested gold EV. Any optional provisional conditional-yield assumption needs an explicit label and cannot override supported measured means. Current auction listings on these catalog sites were **not** imported as source rates or price proof. Preserve original studies, snapshot `4df9ae8` and protected three-pass branch.

## Validation scope

Executed: GitHub readback of current manager charter, research schema/mechanics/queue/strategy/flags and protected three-pass checkpoint; original main `ResearchDB.lua` candidate mapping; source-labeled Retail rank pages and Wowhead identifiers; current War Within report and original item-page accessibility; latest branch/PR/CI metadata. Checked rank↔ID consistency across three catalog pages. No file or dataset outside coordinator-owned master audit/dashboard/status changed. **0** newly collected casts, **0** source-measured quantity/probability/skill coefficients, **0** current eligible gold recommendations; no Lua compiler, actual offline synthetic-price engine/render, live WoW or market-price scenario test. PRs #22/#23 closed-unmerged untouched, and no addon implementation/worker branch/schedule/merge/release changed.
