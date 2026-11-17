# Enchantrix original-log dual-view identity: exact-item and gear-group totals are not independent

Checked 2026-11-15 17:05 UTC. Research-only source-contract audit after Legacy worker's 16:43 UTC evidence. This is a **new duplicate-cohort identity finding**, not a new Retail measurement, new measured completed-cast denominator, or an addon valuation fix.

## Sources pinned and scope
- Original [lavasalesman Classic Enchantrix saved variables](https://github.com/alex-berliner/wow_classic_de_table/blob/master/dbfiles/lavasalesmans_log.lua), including `EnchantedLocal` and `EnchantedItemTypes`. The worker [transcribed 17 output rows across five gear groups](../legacy/2026-11-15T1643-original-classic-enchantrix-raw-hit-quantities.jsonl) (blob `e5379aa854f68da9b153bbba863b51afe8950876`), with `casts=null`, `histogram=null`, one source author and no measured Retail conditions.
- [Enchantrix source implementation](https://github.com/NoobyGains/Auctioneer-Forever/blob/main/Enchantrix/EnxStorage.lua), inspected blob `0e98b1fccc400913b269caea57d042d1bd063ef6` (a current maintained fork, **not independently proved to be the exact 2019 deployed revision**). Its `saveDisenchant` constructs a single reagent tuple `reagentID:1:quantity:0` and calls `mergeDisenchant` for **both** `EnchantedLocal[sig]` and `EnchantedItemTypes[itype]` within the same success path. The serializer identifies the two numeric dimensions as `N_DISENCHANTS` and `N_REAGENTS` and appends the last `:0` literally. Thus that last zero is not an observed empty cast or histogram bin.

## Newly verified exact-item/group overlap
The archival saved-variable file contains an exact-item key **`EnchantedLocal["4362:0:0"]`** and the corresponding **`EnchantedItemTypes["10:2:2"]`** aggregate. [Rough Boomstick 4362](https://www.wowhead.com/classic/item=4362/rough-boomstick) is a Classic uncommon item-level-10 weapon; use this as a source-identity crosswalk, not a current-Retail item-level assertion.

| Output ID | Exact 4362 positive-output events | Exact 4362 material units | Group 10:2:2 positive-output events | Group 10:2:2 material units |
| --- | ---: | ---: | ---: | ---: |
| 10938 Lesser Magic Essence | 243 | 368 | 315 | 475 |
| 10940 Strange Dust | 55 | 83 | 70 | 102 |
| 10939 Greater Magic Essence | not logged for 4362 | not logged | 6 | 8 |

The 4362 **conditional units per positive output** are 368/243 (~1.514) and 83/55 (~1.509). These are **not** unconditional units per disenchant. No separate per-input completed-operation ledger, zero outcomes or joint result histogram is supplied; `243 + 55` is **not** a verified 298 independent casts, and `315 + 70 + 6` is **not** a verified 391 independent casts. The shared write path shows why counting the exact-item and group entries as independent studies would double-count original observations. The group data may be useful as a fallback where the exact-item view is missing, but not as an additive cohort.

## Guarded checks and scope limits
**48/48 guarded source/schema assertions passed** on the actual two original Lua sources and worker JSONL: exact five gear-group transcriptions and 17 unique row IDs, source tuple values and identities, same-account provenance, unknown casts/histograms, two table writes in the storage path, two counted dimensions and a literal trailing zero, and exact-item/group consistency for 4362/10938/10940. No migration rebuild, Python estimator test, native Lua test, synthetic-price tooltip or Retail client/AH/eligibility validation was run; no production code or worker evidence was changed. The 2026 fork supports the dual-write mechanism, but the historical 2019 executable version remains a provenance question.

**Research handling:** treat this archive as **one contributor** with linked `exact-item` and `gear-group` storage views; prefer correctly scoped exact-item rows where possible and never add the same results twice. The new worker records have no denominator and cannot establish current Retail P(hit), per-cast E[units] or a supported current-character gold decision. Future import/review should pin the contemporaneous Enchantrix code and verify the raw save path or independent per-operation log before extrapolating the exact overlap. Do not modify the protected three-pass addon branch or reopen closed PRs #22/#23.

**Next step:** provenance-link the worker's five group records to this dual-view source identity, request original item-level operation logs with complete denominators and patch/skill context only if truly available, and keep known Classic-only evidence out of unqualified current Retail estimates.
