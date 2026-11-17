# Magma Thresher original 2-prospect cohort: resolve two exact Sundered Onyx rank IDs without inventing a recipe

**Checked:** 2026-11-17T16:07:25.661Z. **Scope:** manager source-to-evidence field-placement audit only; not a new study, added cast, probability or live-game test.

## Original observation and previously missing fields

The original [MystSpecimen comment on Magma Thresher item 199344](https://www.wowhead.com/item=199344/magma-thresher#comments) explicitly reports **two completed prospects**, with **2 Fractured Glass 192872, 2 Crumbled Stone 192880, 1 rank-2 Sundered Onyx and 1 rank-3 Sundered Onyx**. These four outputs are **one** cohort, not four studies. The phrase **“Q2 prospecting” does not establish an item-input rank**, a five-fish batch, current 2026 validity or the author's profession skill.

Existing intact research file [dragonflight/2026-10-31T2027-magma-thresher-prospecting-cohorts.jsonl](https://github.com/Voodoobrew101/Loot-Liquidator/blob/implementation/five-agent-completion/research/v3/evidence/dragonflight/2026-10-31T2027-magma-thresher-prospecting-cohorts.jsonl) already contains the full data in IDs `dragonflight-20261031-20001..20004`; therefore **do not re-record these casts**. Precisely two rows remain `outputItemID:null` despite known original ranks: `20003` R2 and `20004` R3.

**New source-to-record identity closure candidate:**

| Existing record ID | Source-stated output and original units | Exact rank-matching item ID | ID basis |
|---|---|---:|---|
| `dragonflight-20261031-20003` | Sundered Onyx, **rank 2**, **1 unit over 2 completed prospects** | **192847** | [Current Retail rank-2 item listing](https://goldcap.gg/retail/kr/items/192847) and [existing source-pinned rank family](https://github.com/Voodoobrew101/Loot-Liquidator/blob/main/database/research/rank-families.json) |
| `dragonflight-20261031-20004` | Sundered Onyx, **rank 3**, **1 unit over 2 completed prospects** | **192848** | [Current Retail rank-3 item listing](https://goldcap.gg/retail/us/items/192848), [WoWhead item identity](https://www.wowhead.com/item=192848/sundered-onyx) and same source-pinned family |

The rank-family registry already groups `[192846,192847,192848]` for Sundered Onyx. This work resolves the previously *unplaced exact output IDs for two specific original records*, not a new family mapping, fresh experimental evidence or claimed 2026 Retail eligibility.

## Quantities, uncertainty and prevented double counting

- Observed unconditional **units per completed reported prospect** for each Onyx rank are exactly **1/2 = 0.5** in this **two-cast historical source**. The numerator and denominator are original observations; these are *not* a calibrated current-patch estimate and **not** the historically stored per-input TSM reference rate. The source does not tell us which of the two casts produced each rank, whether both occurred together, or individual stack distributions. Do not infer `castsWithDrop`, hit probability, zero bins, range or a Quality 2 fish input.
- Fish **units consumed per operation remain unknown**. Neither the five-ore generic [Dragon Isles Prospecting spell 374627](https://www.wowhead.com/spell=374627/dragon-isles-prospecting) nor the existing owner's synthetic `Prospect:199344:x5` profile establishes the fish-specific consumed batch.
- The owner's pass-2 implementation retains [reference-only per-input fallback](https://github.com/Voodoobrew101/Loot-Liquidator/blob/implementation/usable-data-tooltips/docs/usable-data-audit/PASS-2.md). Do not sum this observed two-cast Sundered Onyx rank-specific quantity with the corresponding overlapping source family pool or count the two rows as independent cohorts. Preserve separate identity, source and rank candidates until an importer independently deduplicates and verifies units/profile.
- Neither source shows current build eligibility, source-era build/skill, character unlock, net reagent refunds, live AH prices nor best-action gold. Original [Badwulf 2×1,000 fish diamond batches](https://www.wowhead.com/item=199344/magma-thresher#comments) are *already* separately recorded in the same research file; do not enter them again.

## Scope and reproducible checks

**14/14 in-process strict JSON assertions passed**, directly reading the unmodified source file, main's source-pinned rank-family registry and the owner's stored integration audit summary. Original research file blob: `f5f79f750c44e61b1cdd1864d3df692039f566a7`. Existing family registry blob: `5577910f4fdfc7e0237708269cb5816f8d8f8082`. Original owner's integration audit summary blob: `d77638e8a6937278147817a250f2d1dde002472a`. Source pages were independently inspected; no compiler, Lua test suite, new actual resolver/formatter run, new empirical cast, or live WoW test was executed. No addon changes or worker evidence edits.

**Next concrete review:** have the authorized Dragonflight source/identity worker or reviewed isolated engineering correction place the two exact output IDs, preserving the source key and source rank, before trying the unverified fish-specific recipe/eligibility test. Do not request a duplicate study. Midnight Umbral Tin `T0005/T0039` hit/zero/rank/refund raw logs and Tranquility Bloom `T0045` completed ten-herb mills remain the higher-impact numerical research queue.
