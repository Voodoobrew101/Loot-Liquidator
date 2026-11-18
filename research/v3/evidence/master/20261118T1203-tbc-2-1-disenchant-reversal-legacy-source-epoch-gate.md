# TBC 2.1.0 disenchant reversal: two newly recorded historical no-DE reports cannot be adopted as timeless Retail exclusions

**Research-only manager source-to-version audit — 2026-11-18 12:03 UTC.** This is a correction/eligibility hold on a new Legacy worker report, **not** new processed-item observations, a current-Retail enchantability assertion or actual gold/tooltip coverage. Preserve the append-only original [12-row Legacy source file](../legacy/2026-11-18T1144-original-nonde-classic-tbc-wotlk.jsonl) (blob `224279c23efbf8eb0fb0bd84518352fbcfc6c6f7`). No worker, owner integration or frozen research snapshot changes.

## High-impact chronological conflict

Two *original* old-player “cannot disenchant” reports in that file conflict with a later **explicit official version-change rule**:

| Exact item | Historical worker row and old claim | Patch 2.1.0 (May 22, 2007) | Disposition |
| --- | --- | --- | --- |
| **31272 — Crown of Endless Knowledge** | `legacy-20261118-201`, WotLK-mirrored old player refusal | Patch notes **explicitly enable disenchanting** this exact item | Do **not** import historical refusal as a persistent no-DE flag. Historical before/after game-build and current Retail itemLink/eligibility still unknown |
| **31303 — Valanos' Longbow** | `legacy-20261118-203`, archived old failed attempt | Patch notes **explicitly enable disenchanting** this exact item | Same chronology gate; no current Retail measured cast or assumed material yield |

**Original dated patch-note witness:** [Engadget/Joystiq reprint published 2007-05-22](https://www.engadget.com/2007-05-22-2-1-patch-notes-part-2.html); independent contemporary [2.1 test realm patch-note mirror](https://ironsongtribe.com/thread-2958-post-11061.html). Both explicitly name **both item IDs by exact names**, not an inferred equipment-class rule. This makes the latest worker source a valid historical record but not a current global exclusion. The patch also reports that *some* Tranquillien reputation rewards became no-DE: that is **not** itself an exact-item proof for Apothecary's Waistband 28155.

## Source admission and bounded baseline check

Compared all **12 newly written exact Legacy no-DE identities** to the owner's pinned **Retail ItemSparse 12.1.7.70493** explicit `NO_DISENCHANT` table in `implementation/usable-data-tooltips/database/sources/DB2Restrictions.lua` (blob `e03c7b0c302b1ef718b62b7de9c364e2c0b6ea03`). The source has **21,061 unique flags**. Only **28155 (Apothecary's Waistband)** and **9240 (Mallet of Zul'Farrak)** are already flagged there. The other ten IDs **31272, 32660, 31303, 6218, 18863, 18864, 52019, 208425, 6202, 20917** are absent from this exact-ID flag set. An absent DB2 flag **does not prove enchantability or a wrong tooltip**, particularly for white gear, shirts, trinkets, profession tools, and an item from **Classic Season of Discovery** (208425). Likewise these source catalog/archival comments do not supply Retail 12.1.x attempted disenchant operations.

**32660 Crystalforged Sword** also needs source-version reconciliation: an archived refusal report is in the worker file, but the [TBC Classic item catalog](https://www.wowhead.com/tbc/item=32660/crystalforged-sword) is not proof of the same failure for current Retail or all historical builds. Do not automatically elevate the refusal. **18863 vs 18864** are different class-specific trinket item IDs; same name does not justify cross-ID cloning. The owner MoP Classic example is not evidence for Retail and must not be imported. Item rarity/eligibility, current item bonus and source epoch remain distinct from conversion probabilities and quantities.

## Validation actually executed

Connector-fetched the unchanged worker JSONL and frozen owner DB2 Lua; parsed all worker records and the exact 21,061-entry DB2 set. **44/44 in-process JS source/schema/ID/overlap assertions passed, zero failed**: 12 unique `noDisenchant` IDs, all 12 sourced, none with invented `casts`, two explicit DB2 overlaps and ten absent; separately inspected both original Patch 2.1.0 patch-note mirrors with web lookup. This was a **bounded static identity and chronology audit**, not an exhaustive research-archive deduplication. **No Python estimator, addon importer, Lua suite, actual resolver/tooltip render, synthetic-price run, live price or WoW client test executed; no new observed cast, quantity, probability, coefficient, actionable Retail gold decision, or tooltip field.**

## Next owner-safe action

Keep the 12 worker originals intact. In a future reviewed correction/normalization layer, add a dated patch 2.1.0 reversal gate for 31272/31303 before evaluating historical no-DE flags, then test Retail 12.1.x itemLink/bonus eligibility against the actual resolver and tooltip on a separately authorized integration path; do **not** create a competing addon PR or edit `implementation/usable-data-tooltips`. Continue NEW source-led current-Retail `T0005/T0039` Umbral Tin 237362 five-ore ranked per-output operation/refund/unlock/hit/zero ledger, then `T0045` Tranquility Bloom 236761 actual ten-herb batches. The old 4,000-Tin-input Cardinalai source does **not** establish 800 measured operations.
