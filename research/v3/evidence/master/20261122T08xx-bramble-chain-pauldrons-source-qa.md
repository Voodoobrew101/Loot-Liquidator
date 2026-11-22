# Research Manager source QA — Dragonflight Bramble Chain Pauldrons 198019

**Checked:** 2026-11-22T08:04:36.275Z UTC. **Ownership:** manager independent review of NEW worker-authored source only; no alteration to worker evidence, the 731-source owner/Codex catalogue, three-pass addon branch, production main or generated databases.

## Original-page evidence and provenance

- Source: https://www.wowhead.com/item=198019/bramble-chain-pauldrons (independent indexed Wowhead live-page retrieval, 2026-11-22; search index displays related Disenchanting table, while direct HTML text rendering may omit that dynamic table).
- Input: Bramble Chain Pauldrons **198019**, Dragonflight added in patch 10.0.0. Current page shows a bind-on-pickup mail shoulder and item level 44; this is not proof of the instance itemLink/bonus, disenchant-time game build, source profile or current character eligibility.
- Site reports **90 item-side disenchants**: Chromatic Dust **194123** appears in **76/90** (display **84%**, exact **84.444...%**) and Vibrant Shard **194124** in **14/90** (display **16%**, exact **15.555...%**). Both independent arithmetic checks **pass**.
- Related table visually displays a **1–2** positive stack notation next to Chromatic Dust; this is a source-displayed range, **not** a zero-inclusive distribution, material total, observed unconditional E[units] or a proven at-cast histogram. Do not silently substitute a midpoint or yield-1 for a measured average.
- The **two rows are one pooled source cohort**, not 180 reported operations or independent studies. Although hits total 90, they do not prove mutually exclusive outcomes, no overall zero-output operations, shard conditional quantity, skill/quality scaling or probabilities at a particular patch/character.

## Research and pipeline disposition

Worker evidence: [2026-11-22T0731 source rows](../../evidence/dragonflight/2026-11-22T0731-bramble-chain-pauldrons-looter.jsonl), IDs `dragonflight-20261122-073101` and `dragonflight-20261122-073102`, studyKey `wowhead-looter-198019-bramble-chain-pauldrons-20261122-snapshot`; discovered/read-back in worker commit `78827f68a4922f162e2aff4c75d00bb94cfffb9b`. Same original source and cast denominator, with missing `totalQuantity`, `histogram`, sample patch, bonus, skill and spec explicitly null. No source-original operation-level log has been recovered.

Narrow dedupe check: exact source item ID `198019` and title were absent from the owner team's current 731-source catalogue manifest text (blob `1bb9a4100c2be45282532f6205d722946f3b3e44`); do not reopen or recatalogue its assigned records. New **source-reported occurrence fields**, **zero new expected-quantity/EV fields**, **zero new manager-discovered independent cohorts** and **zero supported gold decisions**.

GitHub checks observed (not run locally): main `bd38a158ea79309ae3be34adaf2c31ad95bce159`, Actions `44972080103` and `44972118290` success; prewrite research `b9c9e3267b7e4b5a215d658502d065fc49977547`, Actions `44999124250` success. No current-client, local Lua, build-time pinned-revision, tooltip, or real-character verification performed.

**Next:** obtain actual per-disenchant source event stacks/zeros and at-cast itemLink/bonus/build for 198019 before any unconditional output-quantity estimate; retain higher priority for genuinely original, rank/profile/refund-aware completed Midnight 237359/237362 prospect and TWW 210796 mill logs. No game actions, experimental crafting, PR, merge, release or schedule changes.
