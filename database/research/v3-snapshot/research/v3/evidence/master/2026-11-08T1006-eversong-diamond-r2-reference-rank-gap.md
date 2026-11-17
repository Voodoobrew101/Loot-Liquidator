# Midnight Eversong Diamond rank-2 reference-to-ItemDB gap — 2026-11-08 UTC

**Research-only static trace, no new casts or validated live recommendation.** The Midnight worker's already recorded catalog finding (`research/v3/evidence/midnight/2026-11-08T0941-eversong-diamond-rank2-live-identity.jsonl`) identifies **Eversong Diamond 242608 = rank 1/2** and **242712 = rank 2/2**. Independently read the two publicly indexed **Retail US commodity** pages:

- [GoldCap 242608](https://goldcap.gg/retail/us/items/242608): exact item ID **242608**, “Quality rank 1 of 2,” commodity acquired through Midnight prospecting.
- [GoldCap 242712](https://goldcap.gg/retail/us/items/242712): exact item ID **242712**, “Quality rank 2 of 2,” same description. Distinct ID and quality are confirmed at catalog level, **not** as outcomes of any measured prospect.
- Earlier repository [F004 source audit](https://github.com/Voodoobrew101/Loot-Liquidator/blob/main/research/evidence/v2/2026-10-30T0826Z-F004-midnight-diamond-ore-trait-gates.json) explicitly retained 242712 as **an unresolved same-name collision**. This current catalog verification is one source identity clarification, not an independent quantitative study.

## New cross-layer static trace (not a runtime test)

At protected three-pass implementation head `3d667d053db587c91401cfed7ecc56862b8340c9`, the frozen `database/reference-calculator-baselines.lua` (blob `52ce8aa9c25bcf43134306eaa6b089f38ad107c4`) contains **seven** Eversong Diamond conditional reference output entries, all **`id=242608`**, and **zero references to `242712`** in that file. They correspond to seven Midnight ore/rank input profiles (Copper x2, Tin x2, Silver x2, Thorium x1). This source assigns an output ID, not a proven distribution across output qualities; its estimated per-operation constants remain workbook-derived zero-Resourcefulness reference assumptions with unknown chance, bounds and recipient-quality proportions.

The [three-pass source-to-render audit](https://github.com/Voodoobrew101/Loot-Liquidator/blob/implementation/usable-data-tooltips/docs/usable-data-audit/summary.json) has exactly **seven partial prospecting profiles** for `237359/237361/237362/237363/237364/237365/237366`. Their ordinary outputs were valued in a **synthetic-price controlled test**; the Diamond figure was shown only as a conditional reference and omitted from gold totals until the particular ore specialization unlock is established. `primary_actionable_coverage=null`: do **not** recast these seven as measured Retail omissions or a current player valuation defect.

**Disposition:** A **newly grounded source/output rank identity** exists but its rank-2 alternative is **not represented in the frozen reference-calculator entries**. This is **usable catalog evidence requiring scoped importer/schema and live-quality selection review**, separate from (a) no per-quality measured expected quantities/hit counts/histograms, (b) client-specific per-ore specialization eligibility, (c) material price data and (d) tooltip field visibility. **Do not split, duplicate, or assign** the existing rank-unknown Diamond expected quantity to both `242608` and `242712`, nor choose a rank by price or treat one commodity as a full substitute. No direct client itemLink or batch-to-output mapping was verified.

## Next priority and ownership

- **Midnight worker** (T0039/T0005/T0026): obtain an original rank-linked output itemLink with exact ore/rank, unlock-on/off, completed-cast denominator, hit/zero histogram and per-hit quantity; investigate existing original 800-operation 237362 cohort before another copied reference.
- **Protected three-pass/addon owner**: review whether the supported conditional preview should expose 242712 as an **unpriced/unknown-quantity ranked alternative** (not an additional priced yield); compare 242608/242712 source selection in an isolated exact-engine/tooltip synthetic-price fixture before any numeric/rank mapping change. This coordinator makes **no addon changes or competing PR**.
- **Validation boundary:** exact static UTF-8 file reads and item-page inspection only; no Lua, compiler, exporter, WoW client or synthetic-price runtime test executed here. New independent casts **0**, current-Retail gold decisions verified **0**, new measured probabilities **0**. Unknown denominators remain unknown.

No MoP Classic material imported. Original research, immutable 4df9ae8 snapshot, worker evidence, PRs, three-pass implementation and main left unchanged.
