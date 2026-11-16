# Manager source-admission gate — five legacy prospecting comment groups (2026-11-16T07:01Z)

**Scope:** research-only independent review of the Legacy worker's 2026-11-16 06:48Z source records. No addon changes, no source edits and no claim of current-Retail rates.

## Original sources and fidelity

- [TBC Classic Adamantite Powder / archived Thottbot comments](https://www.wowhead.com/tbc/item=24243/adamantite-powder): one anonymous comment reports **five stacks** of Fel Iron Ore and Star of Elune 23438 x2, Dawnstone 23440 x2, Nightseye 23441 x1. It does **not** specify a stack size or the number of completed five-ore prospects. A separate anonymous comment reports **50 Adamantite Ore**, **10 unspecified green gems**, Living Ruby 23436 x2, Star of Elune 23438 x1, plus powder of **unspecified quantity**. The 10 greens remain an identified *family quantity*, not ten units of any specific tradable item.
- [Nightseye original comments](https://www.wowhead.com/tbc/item=23441/nightseye): **thorin** explicitly reports one first five-Fel-Iron prospect at Jewelcrafting 300 producing Nightseye 23441 x1. This directly counts **one completed operation and one positive material hit**; it is not a population-level 100% drop probability and provides no separate other-output or full-event zero ledger. **33892** reports **150 Adamantite Ore** giving Nightseye 23441 x1 and Talasite 23437 x1, but provides **no completed operation count**; 150/5=30 is a *nominal ore equivalent*, not verified completed casts.
- [Cataclysm Classic Titanium Powder / archived 224763 comment](https://www.wowhead.com/cata/item=46849/titanium-powder): a **single unspecified stack** of Titanium Ore 36910 yielded Bloodstone 36917 x1, Dark Jade 36932 x2, Huge Citrine 36929 x3, Sun Crystal 36920 x1, Forest Emerald 36933 x1 and Titanium Powder 46849 x4. **12 material units** are cumulative output across six item IDs, not 12 hits or any count of casts. No four-cast assumption.
- Five separate comment-level study keys are recorded; anonymous archived Thottbot authorship does **not** establish five independently identified *players*. Do not treat five source groups as five independent player cohorts without cohort identity.
- The [pre-existing ZeRoTaCtIcS 66-stack Titanium report](https://www.wowhead.com/item=46849/titanium-powder), already in `research/v3/evidence/legacy/2026-10-31T2038-titanium-powder-retail-historical.jsonl`, is **not** a new finding and must not be recounted as 224763's one-stack cohort.

## Manager checks actually executed

At **2026-11-16T07:01:28.719Z**, **133/133 bounded JavaScript read-back assertions passed, 0 failed**, using:
- Worker original evidence file `research/v3/evidence/legacy/2026-11-16T0648-feliron-adamantite-titanium-original-comments.jsonl`, Git blob `fc762b840d6b172ba79699f77bd9bb5ddf962924`.
- Research estimator `research/v3/tools/build_estimates.py`, blob `0b09b553fef4214af8aaa93f1c85061956643711`.
- Prior Titanium cohort file, blob `b3db7960721e8249f49d991c43b348d77959fa65`.
- Independently retrieved three original comment pages above; their quoted output identity and raw quantities matched the checked worker records.

The assertions verified **14 distinct material records / five source comment groups** with sizes **3+2+1+2+6**; distinct IDs; exact named item IDs; 5-input prospect unit; null rank, epoch and fabricated P/averages; exactly **one** row with observed `casts=1`, `castsWithDrop=1`, `totalQuantity=1`, positive `histogram={"1":1}`; and **13** rows with neither casts nor hits nor histograms. They also checked that source `row_use` requires a denominator to convert a `totalQuantity` to an unconditional expected quantity and records `totalWithoutCasts` otherwise. No Python estimator invocation, full corpus deduplication, native Lua, offline synthetic-price valuation, or real WoW run occurred.

## Exact unresolved fields, effect and next priority

**Classification:** original historical evidence exists and contains valid *cumulative quantities*, but thirteen material records lack a supported completed-cast denominator; the one counted Fel Iron operation is a one-event observation, not a reliable current-Retail chance or EV. No original source provides patch/build and full current-Retail eligibility, zero-inclusive per-output distributions, refunds or overlapping cohort identity. The ten Adamantite green units cannot be assigned specific item IDs/prices. Preserve source group/quantity, do not invent rates or promote the observed `1/1` to general chance.

**Gold impact:** **0 newly supported current-Retail gold decisions, 0 promoted chance estimates, 0 additional output rank mappings**. Future importer/tooltip work must keep quantity-only references visible as uncertainty, not silently price an unknown family or change existing usable values.

**Next:** prioritize original, rank-resolved **current-Retail Midnight T0039** zero-inclusive output events with completed casts, original input/refund ledger and unlock/skill context. Secondary Legacy follow-up: identify independent player/epoch and actual completed five-ore operations for the 13 quantity-only rows if original data becomes available. Do not repeat archived comment searches. Research-only PR/worker branch ownership and the owner's three-pass integration branch remain untouched.
