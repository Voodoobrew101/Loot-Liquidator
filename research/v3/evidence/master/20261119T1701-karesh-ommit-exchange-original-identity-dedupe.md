# K'aresh Om'mit historical offers: source-identity hold (2026-11-19 17:01 UTC)

**Scope:** Research-only provenance/deduplication audit for TWW worker evidence file `2026-11-19T1622-karesh-herb-exchange-snapshot.jsonl`. No addon import, valuation rule, live vendor validation, compiler rewrite or PR integration. This is **not** 16 new independent vendor observations.

## Exact evidence comparison

The 16 new rank-specific exchanges are identical as **directed (give item, give quantity, get item, get quantity)** tuples to **all 16** exchanges in each of THREE earlier research files, using the exact current branch blobs below. This is one original **Wowhead guide dated 2025-08-03**, copied into multiple transcriptions; it is not four source cohorts.

| Evidence archive | Blob SHA | Relevant matching edges |
| --- | --- | ---: |
| `research/v3/evidence/war-within/2026-10-30T2221-karesh-phantom-bloom-herb-exchanges.jsonl` | `170e19911e2d0585045a9e25ee0dbd9499b30472` | 16/16 |
| `research/v3/evidence/war-within/2026-10-31T1216-karesh-rotating-market-exchanges.jsonl` | `52edf94eec5bb7c1c91b5b7ca4c79981e3113997` | 16/16 of 34 total exchanges |
| `research/v3/evidence/war-within/20261116T0027-ranked-ommit-historical-exchanges.jsonl` | `f9218f77418512990a57ce01361c91c125bf696c` | 16/16 |
| **New 2026-11-19 TWW file** | `03996a5d606dc976ebc516fd895f5399244719c5` | 16/16, no distinct new rate |
 
Main's `database/research/v3-snapshot/research/v3/evidence/war-within/20261116T0027-ranked-ommit-historical-exchanges.jsonl` also has the identical `f9218f77...` blob (checked at main `0dc7c0269a2a5cce9ed21179d3bfdbf24d44834b`). This does **not** change the owner's separately pinned immutable `4df9ae8` reference.

The 16 distinct stated offers: Phantom Bloom ranks 1/2/3 (`239690/239691/239692`) to corresponding ranks 1/2/3 of Mycobloom (`210796..210798`) at 2:1, Luredrop (`210799..210801`) at 3:1, Orbinid (`210802..210804`) at 4:1, Blessing Blossom (`210805..210807`) at 5:1, and Arathor's Spear (`210808..210810`) at 1:1; plus K'areshi Lotus `240194` to Null Lotus `213197` at 1:1. **Input rank is not output quantity, output rank is not expected yield.** Every row is a deterministic vendor *offer in a dated reference table*, not an observed completion, measured probability, or verified current-price conversion.

Original [Neryssa Wowhead herbalism guide](https://www.wowhead.com/guide/the-war-within/professions/herbalism-overview) (updated 2025-08-03) directly displays all six item-family costs and quantities. Prior transcriptions and the latest worker report cite a [comment about changing Om'mit vendor costs](https://www.wowhead.com/npc=242306/ommit); independently verified **current 2026 in-client vendor prices and purchase eligibility are absent**. Treat as historical references only, not current guaranteed arbitrage. The 16 latest rows introduce **zero** new independent source edges and **zero** measured prospect/mill/DE yields; append-only originals are preserved.

## Bounded validation executed

A connector-side JavaScript comparison parsed the four exact JSONL blobs and ran **130/130 assertions**, with **0 failures**: 16 expected rows, 16 unique edges, 48 matches across three prior archives, 16 one-item output counts, 16 same source URLs, 16 patch labels `11.2.0`, 16 historical-context labels, 15 rank-compatible herb edges, and one separate lotus edge. No Python estimator, Lua test suite, synthetic-price actual resolver/tooltip, CI run initiated by this audit, or live WoW inspection. No claim that current vendor offerings or Retail character eligibility have been verified.

## Correct disposition and next step

Keep each worker's original rows unchanged, but canonicalize source identity by the **original guide + directed exchange tuple + time/patch** in any later exchange-catalog ingestion. The Oct/Nov copies must contribute **at most one historical candidate per edge**; never infer independent experimental confirmations. This is an **already imported historical original / repeated transcription** gap, *not* absent source evidence, new numeric yield, missing TSM price, or a proven current-runtime display defect.

Do **not** add an unconditional static gold action from these offers: live vendor cost/availability would need a validated character/context-aware price-and-eligibility mechanism, otherwise historical ratios should remain reference-only. Priority remains genuinely fresh current-patch completed-operation/zero-inclusive source cohorts for Midnight `237362/236761`, TWW `210937/210796`, and material-level price/identity/rank gaps; original worker ownership and the three-pass implementation branch are protected.
