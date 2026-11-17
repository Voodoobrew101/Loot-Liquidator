# Coordinator T0047/T0053 — original Enchantrix item-level identity and material-unit audit

Audit timestamp (UTC): 2026-11-16T00:02:23.052Z

## Exact original source and worker records

- Original immutable source: https://github.com/alex-berliner/wow_classic_de_table/blob/27797f18f8f34bfc19c74635aba337864ca1f65c/dbfiles/ereduns_log.lua
- New original worker transcription: `research/v3/evidence/legacy/2026-11-15T2346-ereduns-uncommon-armor-and-weapons.jsonl` (18 rows, nine source groups: uncommon armor level 57–59 and uncommon weapons level 60–65; source blob e9703d676e11f836bb6f167e6ada43dcc067d7bb).
- Prior transcription (NOT independent): `research/v3/evidence/legacy/2026-11-15T2251-original-ereduns-classic-groups-scott75-bracers.jsonl` (13 item-level armor rows across six groups 60–65; only the ereduns `studyKey` rows were reviewed here; source blob fae6046911c6c9c4c4a91ecf414d7d1a55573a23).
- Estimator examined: `research/v3/tools/build_estimates.py` (blob 0b09b553fef4214af8aaa93f1c85061956643711).

## Reproducible bounded read-only audit

Directly matched each worker row's `studyKey` to `EnchantedItemTypes["itemLevel:quality:class"]` in the pinned raw file. Verified each `outputItemID:positiveMaterialOccurrences:materialUnits:0` tuple, item-level group, and the absence of a completed `casts` denominator. **31/31 exact material-row assertions passed, zero discrepancies**; 18 new rows and 13 older distinct rows. These checks ran as in-memory JavaScript source assertions against fetched original and branch files; **no Python compiler, native Lua, synthetic-price valuation/tooltip, CI suite or live WoW test was executed for this audit**.

Nine new original groups contain **80 material-positive occurrence counts and 133 units** across 18 rows. With the six earlier group identities, there are **15 distinct original item-level groups**, **31 original material rows**, **218 material-positive occurrence counts** and **503 material units**. The units/positive occurrence ratio is conditional material stack size, **not unconditional units per completed disenchant**. These material-positive counts are NOT 218 independent completed casts; a material can co-occur with others. The trailing source `:0` is not a zero-yield bin. Material-zero events, independent completed-operation denominators, input variant, skill, build/patch and actual distribution remain unknown.

## Verified normalization collision / gold-use blocker

Current `key_of` projects gear groups as `gear:{expansion}:{quality}:{kind}` without `itemLevelRange`. Therefore these 15 original level-separated groups produce only **five distinct estimator input/output keys** (three armor outputs 16203, 16204, 14344; two weapon outputs 16203, 16204). This is an **identity collision hazard** if later compatible completed-cast data is added. It is not proof that current compiled values or live gold recommendations changed: current worker rows supply no completed denominator and cannot establish P(hit) or unconditional E[quantity]. The raw `EnchantedLocal` file is from the same author; do not count it as an independent cohort without deduplication.

Original source context is historical Classic Enchantrix. This is **not MoP Classic illustration data** and is still **not independently verified as current Retail rates**. Preserve source identities, source units and provenance; do not map item-level groups onto modern Retail items, and do not combine levels or derive modern quality/scaling coefficients without supported version/eligibility data.

## Priority / scoped follow-up

1. Under T0047/T0053, obtain a direct, dated and build-tagged Retail 2026 real-player per-operation disenchant export for the relevant exact input/bonus/level/skill with all observed outputs, material units and zero bins. No original 2019 source data should be inflated into a current Retail cohort.
2. On a **separate research-only engineering branch**, add a minimal source identity preservation regression for 15 level-specific groups and test an itemLevelRange-aware key/compatibility migration **before** any import; do not modify the owner's `implementation/usable-data-tooltips` branch or core addon. PR Director retains merge/closure authority.

**No newly validated current Retail gold action or tooltip field, no new independent current-build yield cohort.**
