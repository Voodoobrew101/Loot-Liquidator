# 2026-10-28 — 28 additional TSM anomaly records independently audited

## Canonical source and inventory
Read live itemdb creation prompt v1.1, mechanics/API registries, observation schema, PROGRESS, run-log, ledgers, Issue #2, and main GameData.lua, TOC, ConversionEngine.lua, StatYieldProfiles.lua and Professions.lua. Main GameData SHA `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`; v0.9.70 is still production. Future authoritative file is **itemdb.lua**. No main or release edits.

The existing source ledgers hold 1,001 processing + 255 supplemental = **1,256 source rows**. Deduplicating identical method/input/output/quality/context keys yields **1,171 scoped logical source-output records**; 85 duplicate source rows. Six material fields per record (identity/eligibility, occurrence, conditional min, conditional max, unconditional expectedQuantity, conditions) = **7,026 critical scoped fields**. This is NOT a complete GameData AST inventory. Separate 92 overlay entries are inventoried (62 explicit numeric mappings, 30 dynamic/profile rules); some overlap and require quality/context reconciliation.

Previous independently examined first-pass: 12 Cobalt/Titanium. **This batch adds 28 distinct logical records**; cumulative **40/1,171**, remaining **1,131** never examined. Of 40, **25 BLOCKED**, **15 EXAMINED_INSUFFICIENT**, zero numerical corrections, zero independently promoted >=90. Scoped distinct confidence bands >=90 **0**, 70–89 **0**, <70 **1,171**, lowest **0**; existing source rows >=90 **0/1256**, 70–89 **0**, <70 **1256**. A score of 90 means evidence strength, not 90% statistical accuracy.

## Four batch families: 28 rows
| Inputs / outputs | Count | Original historical TSM tuple and per-five-input calculation | Source precision result |
|---|---:|---|---|
| Pandaria Black/White Trillium 72094/72103, six rare-gem IDs 76130,76133–76137 each | 12 | p=.16; conditional [1,1]; amountOfMats=.0341/input; E=.1705/cast | **INCOMPATIBLE even after source rounding**: p rounded to 2 decimals <=.165, E rounded from four-decimal amount >=.17025 |
| Legion Felslate 123919, six rare gems 130178–130183 | 6 | p=.01; conditional [2,5]; amount=.002/input; E=.0100/cast | **POSSIBLE after rounding**: p displayed to two decimals could mean ~.005, consistent with conditional min 2 and E~.01 |
| Dragonflight Draconium R1/R2/R3 189143/188658/190311 × Illimited Diamond quality R1/R2/R3 192869–192871 | 9 | p=.0142; conditional [1,2]; amount=.0028/input; E=.0140/cast | **POSSIBLE after four-decimal rounding**: p interval .01415–.01425, E interval .01375–.01425 |
| Dragonflight milling input 200061 -> Rousing Order 190322 | 1 | p=.002; conditional [1,1]; amount=.001/input; E=.005/cast | Only **BOUNDARY_ONLY** at .0025 under source rounding; source input identity and milling eligibility unverified |

**Crucial:** these checks assume `matRate` means P(at least one) per operation and `amountOfMats` means unconditional units per input. That interpretation of the historical TSM exporter is NOT independently proven. The 28 original tuples are preserved, not silently replaced. No 2026 Retail matched zero-inclusive histograms or verified sample n. The tests do not validate 2026 Retail drop rates.

## Independent source leads, checked 2026-10-28
- https://www.wowhead.com/mop-classic/item=72094/black-trillium-ore — historical commenter reports roughly 17% rare gem chance, no n, Classic/historical; https://warcraft.wiki.gg/wiki/Sparkling_Shard — confirms both Trillium ores prospect into the Pandaria output family, not exact six rates.
- https://warcraft.wiki.gg/wiki/Design:_Mass_Prospect_Felslate — Legion 20-ore mass recipe, distinct from five-ore single operation; https://www.wowhead.com/ptr-2/item=130178/furystone — one output identity, not six independently verified mappings.
- https://warcraft.wiki.gg/wiki/Illimited_Diamond — confirms Dragonflight gem family; https://warcraft.wiki.gg/wiki/Draconium_Ore — ore family; https://thewowdb.com/item/draconium-ore-189143/ — rank IDs from client data. These do NOT establish quality-specific yields.
- https://www.wowhead.com/item=190322/rousing-order — identifies output 190322, but does NOT prove milling input 200061 yields it.
- https://warcraft.wiki.gg/wiki/Prospecting — ordinary five-ore casts vs mass twenty-ore casts; do not mix denominator.
- A **separate concurrent research lead**, `research/evidence/leads/dragonflight-draconium-illimited-diamond-two-2000ore-cohorts.json`, reports two 2,000-ore aggregate Illimited Diamond family cohorts: 3/400=.0075 and 8/400=.0200 per five-ore equivalent, without input/output rank or patch mapping. Keep separate; do not allocate to any of the nine rank-specific records.

## Research artifacts and tests
- `research/ledger/tsm-anomalies-batch2-field-review-2026-10-28.csv`: 28 raw source tuples, numeric bounds, independent source leads and flags.
- `research/ledger/first-pass-coverage-v1.csv`: 1,171 stable logical keys, source keys, six conservative field scores and first-pass statuses.
- `research/ledger/overlay-first-pass-inventory-v1.csv`: 92 separately tracked legacy overlays/rules.
- `research/evidence/observations/tsm-anomaly-source-audit-2026-10-28.jsonl`: seven historical TSM source snapshots, all explicitly unverified, **zero fabricated measured casts**.
- `research/tests/test_tsm_batch2_and_coverage.js`: **16 static checks passed, 0 failed** against the live research artifacts. No in-client WoW testing or full JSON Schema validation.

## Next batch and first-pass-only ETA
Exact next 30 keys are persisted in PROGRESS/run-log: 12 remaining Trillium gem outputs, six Felslate uncommon outputs, 12 additional milling 200061 outputs/qualities. Prioritize input 200061 identity and eligibility, then TSM exporter field meanings and current Retail matched studies. Next expand TWW/Midnight new first-pass coverage.

Three-run rolling throughput is not yet available (two attributable first-pass batches: 12 and 28). Provisional two-run mean **20 distinct records/run**; 1,131/20 => ~**57 hourly runs, 2.4 days**, **ONLY for scoped first-pass coverage**, assuming pace holds. Complete all-data inventory and every-field >=90 evidence gate have no reliable ETA. **ALL-records >=90 gate NOT MET**.
