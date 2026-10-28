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
