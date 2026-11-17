# Eight November 17 Conqueror's no-DE references: exact earlier-source identity deduplication

**Checked:** 2026-11-17T23:05:32Z. **Scope:** manager's research-only T0047/T0052 checkpoint. This is an original-file cross-check of a *new worker report*, not another source cohort, Retail disenchant attempt, numerical validation, or addon change.

## Specific worker delta and prior origins

The fresh Legacy worker file [2026-11-17T2251-conquerors-scaled-tbc-no-de-identities.jsonl](../legacy/2026-11-17T2251-conquerors-scaled-tbc-no-de-identities.jsonl) (Git blob `b4d62f12babc656db10b8a4561aff3fedc23e8a3`) contains exactly eight `noDisenchant` rows, for item IDs **25006–25013**. Each cites a WoWDB item page reporting the current catalog's scaled level-32 item and 'Cannot be disenchanted'. All **eight exact itemID + source.url pairs** are present in an earlier **distinct authored original evidence record**:

| Current item ID | Earliest prior record | Original file |
|---|---|---|
| 25006 | `legacy-20261116-99105` | [2026-11-16T1112](../legacy/2026-11-16T1112-bloodfist-conqueror-eligibility-willow.jsonl) |
| 25007 | `legacy-20261107-0543001` | [2026-11-07T0547](../legacy/2026-11-07T0547-tbc-scaled-conqueror-armor-weapons.jsonl) |
| 25008 | `legacy-20261116-99107` | [2026-11-16T1112](../legacy/2026-11-16T1112-bloodfist-conqueror-eligibility-willow.jsonl) |
| 25009 | `legacy-20261107-0543002` | [2026-11-07T0547](../legacy/2026-11-07T0547-tbc-scaled-conqueror-armor-weapons.jsonl) |
| 25010 | `legacy-20261107-0543004` | [2026-11-07T0547](../legacy/2026-11-07T0547-tbc-scaled-conqueror-armor-weapons.jsonl) |
| 25011 | `legacy-20261107-0543003` | [2026-11-07T0547](../legacy/2026-11-07T0547-tbc-scaled-conqueror-armor-weapons.jsonl) |
| 25012 | `legacy-20261107-0543005` | [2026-11-07T0547](../legacy/2026-11-07T0547-tbc-scaled-conqueror-armor-weapons.jsonl) |
| 25013 | `legacy-20261113-53001` | [2026-11-13T1556](../legacy/2026-11-13T1556-scaled-tbc-no-disenchant-and-gloves-yield.jsonl) |

All eight have exactly the same source URLs in the prior and latest record (https://www.wowdb.com/items/25006-conquerors-girdle through https://www.wowdb.com/items/25013-conquerors-vambraces, with their respective item slugs). A separate [November 16 manager audit](20261116T1126-scaled-bloodfist-conqueror-nonde-dedupe-and-25003-source.md) already raised overlapping prior rows; this comparison adds the *new November 17 file's complete eight-of-eight overlap*, not a discovery of eight new source identities.

## Field provenance, import effect, scope

**New source-independent item identities: 0. New independent eligible/failed disenchant operations: 0. New event zero bins, output quantities, gold decisions or tooltip fields: 0.** Modern catalog flags cannot be reinterpreted as a measured disenchant failure or applied to every item bonus/variant. The old TBC gear/reagent reference model belongs to an earlier item-level/build context.

The current `main` ingestion helper [tools/research_v3_no_disenchant.py](https://github.com/Voodoobrew101/Loot-Liquidator/blob/main/tools/research_v3_no_disenchant.py) collects valid `noDisenchant` rows by **unique item ID** and accumulates `sourceURLs` in a **set**. Therefore these eight identical-ID, identical-source rows do not add eight unique *compiled restriction identities* **when a future reviewed snapshot refresh includes them**. They do still add raw worker records and should **not** be reported as eight independent research-source discoveries. Existing immutable snapshot `4df9ae8` is not changed by this audit.

## Validation and next action

**45/45 bounded in-memory JavaScript assertions passed** on the five original JSONL blobs: eight latest row IDs/types, earlier exact ID existence, matching exact URL for each, zero empirical counters, plus unique-ID and source-dedup importer-code guards. Original file blob SHAs: Nov 7 `54a1195edb6546017f0a2a20ef0811fbaa3c36cc`; Nov 13 `6018074111933e7208eadd0c9333d3591cca520b`; Nov 16T1112 `76ee8fa691d0d02cc99f94318470c201e4446bb4`; Nov 16T1150 `7e80652baef10cf945f183d4dd77731de7299ffb`; latest `b4d62f12babc656db10b8a4561aff3fedc23e8a3`. The production importer was read for the code guard, **not executed**. No v3 estimator, Python ingestion, Lua engine/formatter, synthetic-price test, CI rerun, or live-WoW test was performed.

**Next priority:** stop rediscovering these same WoWDB Conqueror's pages. Keep Legacy on truly new raw T0047/T0042 item-specific zero-inclusive original histories and build/bonus eligibility, and Midnight on T0005/T0039 current-build Umbral Tin finished-operation hit and quantity logs; preserve all worker originals unchanged.