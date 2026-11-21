# Lavasalesmans Enchantrix — independent original-positive-only transcription review (2026-11-20T16:05 UTC)

**Scope:** Native original contributor data, not a new Retail cast-denominator study, observed P(hit), usable gold EV or live-client validation. No addon code, worker records or original archives changed.

- Pinned source: [original lavasalesmans_log.lua](https://github.com/alex-berliner/wow_classic_de_table/blob/5918ca3e44f6e4bba9071731ab28be3189498001/dbfiles/lavasalesmans_log.lua), author-repository commit `5918ca3e44f6e4bba9071731ab28be3189498001`; prior worker-reported source blob `480c1f5f5dad011f5626ea17e312210e56f4f5eb`. Original [item_names.csv](https://github.com/alex-berliner/wow_classic_de_table/blob/5918ca3e44f6e4bba9071731ab28be3189498001/item_names.csv), worker-reported blob `2d87410f7b0153fc59eef833f0f14542701ee66d`.
- Worker-owned transcript (preserved): `research/v3/evidence/legacy/2026-11-20T1538-lavasalesmans-original-enchantrix-positives.jsonl`, pinned Git blob `cc627c579996542b3d2691719f720e7387133856`, commit [b947dbd](https://github.com/Voodoobrew101/Loot-Liquidator/commit/b947dbd7f46ea3f4838fa12c3abb11516e6b035d).

## Independent verification actually performed

Fetched the immutable original Lua, original name index and the committed worker blob; parsed only native `EnchantedLocal` (not `EnchantedItemTypes`, market/cache prices or aggregate copies). The native key is `itemID:enchantID:suffixID` and each semicolon-separated value is `outputItemID:positiveMaterialSightings:materialUnits:trailingField`.

- **546 original item variants**, exactly **678 original item/output material tuples**; the worker has **678 JSONL rows** with **678/678 unique matching variant+output IDs**, no omissions/extras/duplicates.
- **404 distinct input IDs**, **22 distinct output IDs**; all **678/678 input and output names** match the pinned item-name CSV.
- Sum of source/worker **positive material sightings = 4,019**; source/worker **material units = 6,781**. Each worker row's `castsWithDrop` and `totalQuantity` matched the native tuple exactly; **0 mismatches**.
- Checked all rows for missing denominator misuse: `casts`, `histogram`, and `percentShown` remain `null` in every row. Native trailing `:0` is not a recorded failed disenchanted item.
- Static check only: the currently inspected `research/v3/tools/build_estimates.py` `row_use` cannot use positive `castsWithDrop` as an occurrence rate without an actual casts/processed-input denominator, nor use total units for per-cast EV absent one. The checked main `tools/prepare_build_research.py` builds an exact-research-SHA workspace, but **that pipeline was not run** in this session.

## Scientific admission boundary

Preserve as **source-exact historical item/material identities and positive-only sightings** for future independent original-source reviews. These are not 4,019 completed operations; repeated positive output sightings are not complete all-cast denominators, zeros, unconditional per-operation yields or independent experimental cohorts. Exact recorded client patch, skill, gear item level/bonuses, chance distributions and current Retail disenchant eligibility remain unknown. Do not infer actual Retail processing permissions from a historical Classic archive or promote source totals to a validated current Retail gold decision.

**Next:** focus on new existing/published, current-Retail original all-operation logs with zero-inclusive output observations and exact eligible item links, especially T0047 Warmaul 24995 context and T0022 Cobalt 36909; the newly verified source itself is exhausted for missing denominators. Do not ask for a duplicate transcription, alter the worker record, create a routine PR, or commit generated ItemDB files.
