# Loot Liquidator — processing research and confidence ledger

## Canonical project
- Repository: https://github.com/Voodoobrew101/Loot-Liquidator
- Published baseline: `main/LootLiquidator-v0.9.70-Unified-Low-High-Processing.zip`
- Canonical gameplay data to audit: `LootLiquidator/GameData.lua` inside that ZIP
- Research branch: `research/processing-confidence`
- This file records the research workflow and its initial state. It is **not** evidence that individual data records have been checked.

## Research objective
Independently research and verify all applicable fields and processing relationships in `GameData.lua`, with a target **evidence confidence >=90/100 on every material field and record**. A score is an evidence-quality assessment, not a measured probability that a value is numerically correct. No records should be marked >=90 without supporting evidence, and no aggregate average may conceal low-confidence records.

## Initial status
- **Initial per-record audit: not yet performed on this branch.**
- **Count of records verified at >=90: not established.**
- **Current completion gate: NOT MET / NOT VERIFIED.**
- The downloadable v0.9.70 addon package is present on `main`, but its individual Lua source files have not been extracted to this branch yet.
- The first research run must inspect that actual ZIP and enumerate data records before assigning scores or counts. Do not fabricate baseline completion metrics.

## Requirements for research runs
1. Read the existing ledger and current canonical addon data, and resume unfinished priorities rather than restarting.
2. Research a substantial batch across prospecting, milling, disenchanting, and other entries in `GameData.lua`. Verify genuine input/output item IDs and output eligibility.
3. Distinguish empirically observed unconditional expected quantities from occurrence probability and integer min–max ranges. For gold calculations, never derive the expected quantity from a range midpoint or multiply unconditional expectation by the occurrence chance again.
4. Prefer character- and patch-matched observations/TSM conversion quantities, preserve original evidence, and record source URLs, publication dates, sample sizes, conditions, and uncertainty.
5. Where eligible outputs are supported but no exact tooltip probability or integer range is established, supply visibly marked reasonable estimates rather than leaving empty tooltip fields. Do not invent possible outputs.
6. Keep separate low/high estimates and expansion, input quality, skill, specialization, and profession-stat conditions; low is the fallback when no better applicable data exist.
7. Check your own work at the **end** of every run: verify the exact data entered, numerical consistency, source citations, contradictory evidence and regression tests. Fix discovered problems immediately where possible.
8. Continue seeking and correcting records below 90 until **every** material field and record is independently supported at >=90. If the public evidence cannot support 90, keep an honestly scored useful estimate and a research blocker; never inflate confidence to finish.
9. Commit research updates and test outputs on this branch. Prepare reviewable PRs; **do not automatically modify or merge `main` or publish an addon release.**
10. End each run with actual totals for records reviewed, >=90, 70–89, <70, changes made, sources, tests, and the next set of research priorities.

## Recommended working files (create as evidence is audited)
- `research/confidence-ledger.csv` — one row per evidence-bearing output relationship and material field, including source links and scores
- `research/research-sources.md` — provenance, study conditions and caveats
- `research/run-log.md` — date-by-date changes, regression checks and unresolved priorities
- `research/proposed/` — additive, reviewable GameData proposals, not changes to released addon
- `research/tests/` — QA fixtures for checked relationships

## Current next action
Extract and inspect the canonical v0.9.70 ZIP, enumerate `GameData.lua` data fields, initialize the per-field confidence ledger, then research and correct the highest-impact entries lacking strong evidence.

## Required three-field output model (confirmed by user)

For every genuine output material and a SPECIFIC input/process/quality/profession-condition profile, keep these THREE conceptually separate values:

1. **Occurrence probability**, `dropChance` (percentage, 0–100%): probability that **at least one unit of that output** drops during ONE eligible processing operation. Display this next to the output in its tooltip, with `≈` or equivalent if estimated. Multiple different outputs may drop in the same operation, so material chances need NOT sum to 100%.
2. **Conditional integer drop quantity range**, `yieldMin` and `yieldMax`: smallest and largest WHOLE-number counts of this output **WHEN IT DROPS** in one processing operation. For an output that is able to drop, `yieldMin >= 1`, `yieldMax >= yieldMin`. These are tooltip display fields and must not be decimal-valued. Do not infer unconditional expected quantity from the midpoint of this range. Only call it observed/guaranteed if evidence supports it; otherwise flag as estimated. A 0% locked/impossible output is excluded from its ineligible profile rather than made up.
3. **Unconditional expected output quantity**, `expectedQuantity` (decimal): the long-run MEAN **output units per processing operation**, including operations where that output did not appear. This is the ONLY material-quantity multiplier for gold valuation; NEVER multiply it by `dropChance` again. Keep full meaningful decimal precision. If a source reports units per input resource, convert using the verified operation input count (`expectedPerOperation = expectedPerResource * inputCount`); no rounding to integer for profit.

Tooltip shape: `≈25% Some Gem [2–4]` and corresponding independently supported value `expectedQuantity=0.70 gem per 5-ore operation`. This is ILLUSTRATIVE, not a WoW claim. For valuation: `0.70 * TSM_price_per_gem`, optionally adjusting auction fees per addon settings. Do not use `25% * 3` as a substitute for measured 0.70; the exact conditional drop-count histogram is unknown unless researched.

**Consistency requirement** when a profile supplies all three genuinely comparable values: with probability fraction `p`, `p*yieldMin <= expectedQuantity <= p*yieldMax` (subject to floating tolerance); if this fails, investigate source condition, unit normalization, mismatched stat/quality profiles or a bad proxy. NEVER silently overwrite stronger expected-quantity evidence merely to make an estimated display probability fit. Prefer fixing the estimated probability or range, with clear provenance. A probability source may support only occurrence, a yield-range source only quantities-on-success, and a TSM source only unconditional mean; do not confuse these evidence claims.

**Low and high profiles:** All three fields should correspond to the SAME effective skill, specializations, eligible outputs and other conditions for that profile; sliders/interpolation should update displayed probability and integer ranges AND separately update unconditional expected quantity for pricing, based on appropriately condition-matched data. Default/fallback uses the low-profile `expectedQuantity`, not a generic unrelated fallback. Low/high quality or unlock gates must not produce impossible outputs.

**Confidence scoring:** Evaluate evidence for probability, conditional integer bounds and unconditional expected quantity INDEPENDENTLY. A well-grounded `expectedQuantity` must not acquire a higher/lower confidence because of separately modeled tooltip probability or range, and estimated display numbers must not be portrayed as empirical 90/100 evidence.
