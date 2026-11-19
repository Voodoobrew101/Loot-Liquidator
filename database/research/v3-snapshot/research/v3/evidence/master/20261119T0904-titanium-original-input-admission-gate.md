# Manager gate — WotLK Titanium original ore totals disconnected after nominal-cast repair

Checked 2026-11-19 UTC. Research branch before this manager write: `bef81b5c51e184cfe475b2bd69cdedeb89d779eb`. Source replacement file blob `539d7b88edc101431f6fc94ffc4c858c56adf0d2`; estimator code blob `0b09b553fef4214af8aaa93f1c85061956643711`. **253/253 bounded JavaScript source-field/lineage/static-code assertions passed**, using exact GitHub blobs and independently retrieved original Wowhead comment text. This is a **research-only data-admission finding**, not new Retail yield measurements, synthetic-price valuation, or actual WoW validation. Native Python estimator, Lua, full addon suite and CI were **not** run for this audit.

## Original source identities and verified field types

- [27928 original Titanium comment on Retail-hosted Wowhead page](https://www.wowhead.com/item=36910/titanium-ore): 360 Titanium Ore *reported prospected* and 17 named output totals (including 51 Titanium Powder), matching all 17 archived replacement rows in `research/v3/evidence/legacy/2026-11-19T0850-titanium-exact-ids-nominal-cast-repairs.jsonl`. Original author reports ore quantity, not an independently logged event-by-event cast denominator; historical context, not a proven current-Retail experiment. Nominal input/5 = 72 five-ore equivalents; 51/72 = **0.708333** powder units per nominal 5 ore.
- [Ceari original patch 3.3.3 comment](https://www.wowhead.com/mop-classic/item=36910/titanium-ore): 200 Titanium Ore *reported prospected*, 17 named output totals (25 Titanium Powder), all 17 matching archived replacements. Nominal input/5 = 40 five-ore equivalents; 25/40 = **0.625000** powder units per nominal 5 ore. Do **not** treat MoP Classic page hosting as MoP Classic data; the comment explicitly identifies historical patch 3.3.3. This is not new Retail evidence.
- These are **two** independent historical source authors, **34 material rows**, **34 distinct replacement IDs**, not 34 independent studies. Output names and quantities were cross-checked against readable original comment text. Worker-provided numeric `outputItemID` fields passed structural/intra-file checks but were **not** individually revalidated against a second independent item catalog in this audit.
- Per-material `castsWithDrop`, zero-outcome histograms, stack ranges, real completed event counts, at-cast skill and current Retail applicability are **unknown**. The original total quantity is distinct from observed hit probability and conditional units. No skill, Multicraft or Resourcefulness coefficient is supplied.

## Newly verified silent-admission problem

The 2026-11-19 legacy worker correctly replaced the old 72/40 nominal event counts with `casts:null`, preserving original output totals and source provenance. **However all 34 new rows omit typed `inputsProcessed`** (the original ore total is currently in free-text notes and quote only), and none supply a typed `averageShown`.

Exact estimator code `research/v3/tools/build_estimates.py`:
1. `load()` honors `replaces` and removes the 34 predecessor rows from its active record set.
2. `row_use()` at current lines 286-321 uses `casts` or typed `inputsProcessed` to normalize a `totalQuantity`. When both fields are absent it returns no `average` and labels the record `totalWithoutCasts`.
3. Consequently, **if the current replacements are compiled without additional typed-input corrections, their 34 original source totals contribute no independent expected quantity**. The published `output/estimates.json` remains the pre-replacement blob `15ae8c5b7f7b2587ceff1dcd3e8b9d13d4351d1e` and is **not** proof that new rows are admitted. No estimator regeneration was performed.

This is a **usable historical expected-quantity but not imported/admitted** gap. It is not a missing market-price issue, input-rank identity conflict, confirmed current-Retail eligibility, or mere tooltip formatting issue. Avoid using the old nominal 72/40 as *observed casts* merely to restore a numeric value.

## Reviewable recovery path (not applied)

On a **separate reviewer-owned research engineering branch**, and only after confirming original `ore prospected` means gross actual inputs consumed rather than ore purchased or reprocessed refunds, append 34 scoped typed correction records to the supported `research/v3/corrections.jsonl` format: `field:"inputsProcessed"`, `value:360` for the 17 `wowhead-27928-titanium-360` replacement IDs and `value:200` for the 17 `wowhead-ceari-titanium-200-patch333` replacement IDs. Never rewrite originals or infer casts, hit counts, patch for 27928, skill, new rates or probabilities. `row_use()` should then use `castsFromInputs` for **mean units per five ore only**, keeping occurrence probability unknown. Require original study deduplication with historical snapshots, patch/epoch filtering, exact output-ID review and actual estimator rebuild + output delta; **offline synthetic-price addon engine and tooltip test is mandatory before any Runtime handoff**.

The current high-impact queues remain Midnight `T0005/T0039` for 237362 and 236761 event-level rank/skill/refund proof, plus TWW measured post-hotfix 222833 context. Neither owner `implementation/usable-data-tooltips` nor immutable `4df9ae8` addon snapshot is touched. No PR, merge, release or schedule change.
