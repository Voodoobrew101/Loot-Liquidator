# Loot Liquidator — processing research and confidence ledger

## Future output filename and hourly research prompt — 2026-10-28

**USER DECISION (supersedes older output filenames):** Future generated single shipped item/conversion database file is **`itemdb.lua`** (exact lowercase). `main/GameData.lua` is the CURRENT production file and its `LootLiquidator.toc` entry must stay unchanged until a reviewed migration is approved and tested. All compiled research candidates, schemas, examples and migration plans use `itemdb.lua` under `research/proposed/`; do not create a competing addon runtime table.

**Prompts committed for the hourly Research QA assistant:**
- [Full database generator and research specification](prompts/ITEMDB_CREATION_PROMPT.md), whose first research milestone is an independent rewrite/review into an executable and validated proposed schema.
- [Canonical concise hourly task prompt](prompts/HOURLY_ITEMDB_RESEARCH_TASK.md), preserving the existing hourly cadence and ongoing research/field-confidence QA.
- Read [ProfessionMechanicsRegistry.json](mechanics/ProfessionMechanicsRegistry.json) and [WoWRuntimeAPIRegistry.json](mechanics/WoWRuntimeAPIRegistry.json), all original observations, confidence ledgers, patch notes and integration issue before rewriting or compiling.
- Per output record exactly four independently supported confidence-scored fields: `dropChance`, `yieldMin`, `yieldMax`, `expectedQuantity` with source/conditions/patch, samples and blockers. Worst-field confidence caps a record. No fabricated numbers or unverified patch coefficients.

**Research next action:** Reconcile existing data generator assumptions and working v0.9.70/v0.9.71 runtime interfaces with the user-approved single-baseline model; rewrite the generator prompt where warranted, propose itemdb schema/build steps and maintain progress in separate research commits. Continue substantive research and review in each run; never claim a prompt rewrite is an implementation.

---


## Architecture update — 2026-10-28: single baseline and evidence storage (supersedes prior Low/High design)

**AUTHORITATIVE OVERRIDE FOR RESEARCH AGENTS AND ADDON DEVELOPMENT:** The old requirement in this file to maintain mandatory separate Low and High processing tables is **superseded**. Use ONE best-supported reference baseline per input/output/method/condition, with independently supported `dropChance`, conditional whole-number `yieldMin`/`yieldMax`, and unconditional decimal `expectedQuantity` per exact processing operation. Retain additional low/high and patch-stratified historical studies in the research **evidence archive**, not as redundant shipped material tables. The chosen baseline is not necessarily zero skill; label the measured character context.

**New canonical research files:**
- [Profession mechanics v0.2](mechanics/ProfessionMechanicsRegistry.json) — active, research-only, additive 0.1 migration; names all 12 expansion eras and details fail-closed rules. Still no verified numerical transformation formulas.
- [WoW addon runtime API coverage](mechanics/WoWRuntimeAPIRegistry.json) — 26 documented API capabilities, UI/open-recipe/current-character/offline-alt boundaries and in-game test requirements.
- [Raw research evidence archive](evidence/README.md) — explains existing source/TSM/confidence ledgers and a stable `observations/*.jsonl` location.
- [Raw observation schema](evidence/observation.schema.json) — includes sample source, game build/hotfix window, exact cast denominator, profession conditions, per-output raw totals, occurrence/histograms when known, and separate field evidence.
- [First migrated example study](evidence/observations/midnight-refulgent-copper-r2-50ore-community.jsonl) — source-reported aggregates, NOT current-Retail-verified probabilities or post-hotfix rates.

**Evidence pipeline:** Immutable source experiments and cited patch notes → verified sample context/API support → recipe-specific mechanics/patch registry → audited derived per-field confidence ledger → proposed baseline → explicitly approved `GameData.lua` update. The installed addon has ONLY ONE authoritative shipped conversion database, `GameData.lua`; JSONL/CSV/registry files live only in the research branch, not in the addon package. Personal SavedVariables remain a separate optional measured source.

**Normalization gate:** Never promote mismatched patch or profession contexts to current Retail unless every material contextual adjustment (and its coefficients) is supported. An unknown effect is **BLOCKED**, never silently treated as factor 1.0. No API reveals hidden drop percentages or numeric unpublished hotfix effect; collect real cast counts. `TRADE_SKILL_ITEM_CRAFTED_RESULT` is a promising event but prospect/mill/disenchant coverage must be live-tested. Client `GetBuildInfo` does not reveal the server's exact hotfix multiplier.

**Mandatory next research:** Fill precise profession/expansion skill-line IDs, specialization node/perk IDs and ranks, recipe eligibility, equipment/operation stats, hotfix effective windows, and numerical effect evidence. Prioritize current Retail measurements that bridge skill/spec or patch conditions. Keep all existing evidence; mark the older Low/High entries as historical/provisional until migrated rather than deleting them. The 90/100 confidence target remains aspirational and must NEVER be met by invented probabilities, output yields or adjustments.

---


## Canonical project
- Repository: https://github.com/Voodoobrew101/Loot-Liquidator
- Original baseline was `LootLiquidator-v0.9.70-Unified-Low-High-Processing.zip`; **that ZIP is not at the former main path now** (404 on 2026-10-27).
- **Current canonical source:** extracted `main/GameData.lua`, plus runtime processing overlays in `main/StatYieldProfiles.lua` and the live valuation/skill modules. GameData blob SHA at audit: `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`. Recheck SHA each run.
- Research branch: `research/processing-confidence`
- This file records the research workflow and its initial state. It is **not** evidence that individual data records have been checked.

## Research objective
Independently research and verify all applicable fields and processing relationships in `GameData.lua`, with a target **evidence confidence >=90/100 on every material field and record**. A score is an evidence-quality assessment, not a measured probability that a value is numerically correct. No records should be marked >=90 without supporting evidence, and no aggregate average may conceal low-confidence records.

## Current status — 2026-10-27
- **First per-field source inventory completed** on actual GitHub main `GameData.lua` (extracted Lua sources; previous ZIP path no longer exists).
- **389 source profiles** and **1,256 source output rows** catalogued in research ledgers; 92 additional runtime overlay mappings tracked separately. Source rows overlap; not all unique live item-output pairs.
- **0/1,256 output source rows** have every applicable material field independently scored >=90; 0 scored 70–89; 1,256 scored <70. Lowest 0, including 304 zero-score rows where evidence is missing. This is a conservative first scoring baseline, not a statement that all item IDs were independently checked.
- **40 TSM source consistency flags**; 12 severe Cobalt/Titanium rows cross-checked against historical/wiki sources and flagged as potentially unsafe for valuation.
- **12 newly sourced historical Titanium yield observations** across six uncommon gems (2022 Retail 200 casts; 2023 Classic PTR 1,000 casts), providing decimal unconditional means around 0.22–0.295 gems per five-ore cast, rather than contradictory TSM 2.5. Not promoted to current Retail rates or production.
- **1 verified mechanic-date correction proposed:** Midnight prospecting gem buff is in Blizzard's **2026-04-01** hotfix section, not April 17 (cumulative article title).
- **ALL-records >=90 completion gate: NOT MET.** No production Lua changed; no in-game tests.
- Latest detailed run notes: `research/run-log.md`. Source citations: `research/research-sources.md`.

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
Read the existing ledger and `research/run-log.md`, fetch fresh `main/GameData.lua` and compare SHA. Prioritize the **12 Cobalt/Titanium TSM expected-value contradictions**, then 28 other TSM anomalies and the **2026-04-01** Midnight hotfix dating. Research current Retail evidence and skill/quality conditions for high-impact Midnight/TWW/Dragonflight outputs. Update individual per-field confidence and source URLs only when independently justified. Include `StatYieldProfiles.lua` runtime overlays in QA; do not assume sliders are the final design.

### Persisted research files
- `research/ledger/source-inventory.csv` — 389 source profiles
- `research/ledger/processing-output-fields.csv` — 1,001 compiled/TSM output rows
- `research/ledger/supplemental-output-fields.csv` — 255 DE, low/high, fixed, token and cohort output rows
- `research/ledger/runtime-overlay-map.csv` — 92 runtime-generated scenario mappings
- `research/ledger/tsm-invariant-anomalies.csv` — 40 flagged contradictions
- `research/ledger/titanium-observed-yields.csv` — 12 historical source-backed Titanium expected-quantity observations
- `research/proposed/2026-10-27-corrections.md` — verified date correction and unsafe Northrend EV investigation
- `research/tests/QA_PROTOCOL.md` — executed QA checks and confidence rubric
- `research/research-sources.md` — external/internal provenance
- `research/run-log.md` — session-by-session evidence and continuation

## Required three-field output model (confirmed by user)

For every genuine output material and a SPECIFIC input/process/quality/profession-condition profile, keep these THREE conceptually separate values:

1. **Occurrence probability**, `dropChance` (percentage, 0–100%): probability that **at least one unit of that output** drops during ONE eligible processing operation. Display this next to the output in its tooltip, with `≈` or equivalent if estimated. Multiple different outputs may drop in the same operation, so material chances need NOT sum to 100%.
2. **Conditional integer drop quantity range**, `yieldMin` and `yieldMax`: smallest and largest WHOLE-number counts of this output **WHEN IT DROPS** in one processing operation. For an output that is able to drop, `yieldMin >= 1`, `yieldMax >= yieldMin`. These are tooltip display fields and must not be decimal-valued. Do not infer unconditional expected quantity from the midpoint of this range. Only call it observed/guaranteed if evidence supports it; otherwise flag as estimated. A 0% locked/impossible output is excluded from its ineligible profile rather than made up.
3. **Unconditional expected output quantity**, `expectedQuantity` (decimal): the long-run MEAN **output units per processing operation**, including operations where that output did not appear. This is the ONLY material-quantity multiplier for gold valuation; NEVER multiply it by `dropChance` again. Keep full meaningful decimal precision. If a source reports units per input resource, convert using the verified operation input count (`expectedPerOperation = expectedPerResource * inputCount`); no rounding to integer for profit.

Tooltip shape: `≈25% Some Gem [2–4]` and corresponding independently supported value `expectedQuantity=0.70 gem per 5-ore operation`. This is ILLUSTRATIVE, not a WoW claim. For valuation: `0.70 * TSM_price_per_gem`, optionally adjusting auction fees per addon settings. Do not use `25% * 3` as a substitute for measured 0.70; the exact conditional drop-count histogram is unknown unless researched.

**Consistency requirement** when a profile supplies all three genuinely comparable values: with probability fraction `p`, `p*yieldMin <= expectedQuantity <= p*yieldMax` (subject to floating tolerance); if this fails, investigate source condition, unit normalization, mismatched stat/quality profiles or a bad proxy. NEVER silently overwrite stronger expected-quantity evidence merely to make an estimated display probability fit. Prefer fixing the estimated probability or range, with clear provenance. A probability source may support only occurrence, a yield-range source only quantities-on-success, and a TSM source only unconditional mean; do not confuse these evidence claims.

**Low and high profiles:** All three fields should correspond to the SAME effective skill, specializations, eligible outputs and other conditions for that profile. Low and high are provisional research endpoints, NOT a settled slider formula. The actual interpolation method, UI widgets, specialization thresholds and effects on each of the three fields REMAIN TO BE RESEARCHED AND DESIGNED. Model effects separately when mechanically justified; do not assume linear interpolation or that every stat changes drop probability or conditional quantity. The fallback, when actual and explicitly configured simulated conditions are unavailable, uses the low-profile `expectedQuantity` and matching low display fields. Low/high quality or unlock gates must not produce impossible outputs.

**Confidence scoring:** Evaluate evidence for probability, conditional integer bounds and unconditional expected quantity INDEPENDENTLY. A well-grounded `expectedQuantity` must not acquire a higher/lower confidence because of separately modeled tooltip probability or range, and estimated display numbers must not be portrayed as empirical 90/100 evidence.

## Core product goal — real profession context, or configurable simulated context

**User-confirmed goal:** On each evaluated item conversion, determine the player's actual relevant profession skill and other known processing conditions where Blizzard exposes them. If the player lacks that profession or live information is missing, derive a **simulated profession profile from explicit settings** so valuation can still be calculated. The result must give the most defensible gold estimate obtainable for the item's actual processing eligibility, expansion, input quality and the real or configured skill/spec/stat conditions. DO NOT implement a fake fixed skill of 300, or classify simulated stats as player-scanned facts.

Proposed context resolution to validate against the actual addon and WoW APIs:
1. Query available **real** relevant profession information for the eligible active character or known eligible configured alt: expansion-specific skill, skill bonuses/gear, unlocked specializations, crafting stats and relevant recipe/operation context. Distinguish fields that are known from those that are nil/unknown; don't treat a missing value as verified zero.
2. For missing profession capability/context, use a deliberate **settings-defined simulated profile** (e.g. manually configured skill, specialized unlocks and profession stats) instead of unconditionally aborting to a raw fallback. Preserve `source=simulated` and flag unsupported assumptions; simulation is for valuation/what-if, not a claim that the current character can process a bound item.
3. If neither usable live nor configured simulation data can establish conditions, evaluate using the conservative **low-skill research profile as fallback**.
4. Use condition-matched evidence to choose/derive each output's unconditional decimal mean, keeping original TSM study rates and provenance separate. Multiply each mean by the correct net sale price, sum material expected revenues and compare with other eligible action values on a common per-item/per-batch basis. Account for recipe batch size, market fees and applicable reagent savings only where mechanically justified. Do not double-apply chance or confuse chance with expected mean.
5. Independently display drop probability and integer conditional yield range as accurate, useful tooltip information. They may remain estimates (clearly labeled) when the gold-critical expected mean has better evidence. Dynamic updates should reflect actual condition-sensitive mechanics where documented, and should not invent changes merely because a generic slider moved.

**Settings/UI mechanism NOT DECIDED:** whether input uses numeric skill boxes, presets, dropdowns, checkboxes, sliders, or any combination; how to map profession skill and individual specializations onto empirical output distributions; and which effects can be interpolated versus threshold-gated. Research actual Retail APIs/expansion mechanics and audit the existing settings before selecting UI or formulas. Do NOT lock the project into linear low/high interpolation or mandatory adjustment of all three fields by one slider. Preserve the existing professions/alts settings interface and saved user configurations.

**Critical test cases:** player with real profession and full stats; real profession with some missing stats; no profession but configured simulated low/medium/high skill; no profession and no simulation profile; ineligible/untradeable item, alternate character proficiency and transfer restrictions; expansion-specific quality/rank and specialization gates; no-priced-output vs partially priced outputs; same-context matching real/simulated output choice. All require explicit source labeling and consistent bag/tooltip/valuation results.


## Continuation checkpoint — 2026-10-28 Batch 9
- One-database integration contract reconfirmed against Issue #2 and actual source; new migration audit at research/proposed/2026-10-28-batch9-one-database-migration-audit.md (commit 57488d5b4e7b135fc6fc5f6b1c9f2146fbb932b7).
- Runtime-only hardcoded mapping inventory: 9 TWW ore quality profiles, 20 TWW/Midnight milling profiles, 3 Null Stone output rows, 9 DE fallback anchors, 5 candidate deletions, plus dynamic DF TSM-derived milling mappings and other runtime mutation.
- Preserve source/condition-specific evidence, never treat rangeFor-generated bounds as measured; no addon release changes.
- Next highest-priority research: migrate valid output mappings to proposed GameData-only schema, verify 5 excluded herb IDs, test source-of-truth and condition selection. Processing ledger 1256 source output rows, >=90 0, 70-89 0, <70 1256, lowest 0. Full GameData non-processing inventory still incomplete and is an explicit blocker to all-record gate.


## 2026-10-28 — itemdb first milestone + Midnight milling evidence batch (verified)
- **Latest contract respected:** future sole shipped source will be lowercase `itemdb.lua`; current `main/GameData.lua` and TOC remain untouched. ONE condition-labelled baseline, not mandatory low/high sibling tables. Raw legacy high points stay in nonshipped evidence.
- **Source versions checked:** main GameData SHA `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`, StatYieldProfiles SHA `1d80df8304acaa75a5b507089ef163696381b2ff`; original ZIP former main path remains 404. Read current Issue #2 and mechanics/API registries.
- **First milestone delivered:** creation prompt v1.1 independently reviewed, schema `research/proposed/itemdb.schema.json`, eight-record `research/proposed/itemdb-midnight-milling-candidate.json`, test `research/tests/test_itemdb_candidate.js`. Not yet a complete itemdb.lua or authorized production migration.
- **Research:** 4 Midnight herb-to-pigment families, 8 input-variant/output relations with corroborated item IDs; 10 herbs/operation; source links in `research/reviews/2026-10-28-midnight-milling-source-qa.md`. Existing numeric candidate 4.5 expected units, 100% occurrence proxy, [3–6] estimated conditional bounds remain **modeled** (no measured n), no invented rates. Per-field scores identity 78, p 12, min 12, max 12, E 18, conditions 22; record minimum 12. New separate eight-row ledger `research/ledger/midnight-milling-field-review-2026-10-28.csv`. These are not confidence promotions of the existing 1,256 source rows.
- **Eligibility unresolved:** player reports 2024–25 support non-millable Arathor's Spear 210808/210809/210810; needs 2026 live recipe check. Generic Midnight Milling description says any herb but specific guides list 4 pigment families; Azeroot 236775 remains unresolved, NO fabricated output association.
- **QA:** 16 executable JavaScript checks passed, 0 failed, using fresh main Lua + research candidate; tests include 10-herb normalization, per-field independence, source correspondence, contradictory TSM tuple and REAL/SIMULATED/REFERENCE *policy-only* precedence. Known overlay-mutation architectural debt detected, NOT FIXED. No in-client tests or complete JSON-Schema validator. Independent review strengthened schema types: probability 0..1; conditional yield integers; expected nonnegative decimal.
- **Broader-scope audit:** 2,034 lines in main GameData; lexical named-assignment census found 81 tokens/keys and 10,348 occurrences (includes non-data and repetition; NOT a Lua AST or evidence verification). File: `research/ledger/gamedata-lexical-key-census-2026-10-28.csv`. The existing processing ledger remains 1,001+255=1,256 rows: >=90 **0**, 70–89 **0**, <70 **1,256**, minimum **0**. 92 runtime overlay rows still separately listed; full non-processing/GameData field inventory remains incomplete. Completion gate NOT MET.
- **Next priority (exact):** collect current Retail per-cast and conditional-hit histograms for Midnight milling by 10 herbs with skill/spec/gear/output qualities; confirm Azeroot and Arathor recipe eligibility in the WoW client. Independently check 12 economically dangerous Cobalt/Titanium TSM contradictions and other 28 anomalies with source field semantics. Extend AST-level all-GameData inventory and versioned migration no-loss tests. Do not publish a main addon release.


## 2026-10-28 — Northrend 12-record economic anomaly re-audit
- Read current research ledgers, current extracted main/GameData.lua SHA 1d47c4a961c5dc5af626e659f7d96d1490d3cf9e, Issue #2, existing itemdb contracts. Original ZIP former pathname remains GitHub 404; source extracted Lua unchanged.
- **12 individual Cobalt 36909 and Titanium 36910 uncommon-gem output source rows rechecked against original TSM tuples**, Warcraft Wiki Cobalt/Titanium Prospecting references and existing distinct 2022 Retail/2023 Classic PTR Titanium experiments. Each TSM tuple p=.235, per-input amountOfMats=.5, conditional [1,2] implies E=2.5 units per five ore vs p*max=.47 (factor 5.319). Source values remain unmodified; ambiguous TSM field semantics under investigation.
- New **proposed** quarantine disposition table: `research/ledger/tsm-northrend-quarantine-proposal-2026-10-28.csv` (12 rows). No runtime gating implemented; original TSM evidence retained. Detailed review: `research/reviews/2026-10-28-northrend-tsm-math-and-source-audit.md`. Static source test: `research/tests/test_northrend_tsm_anomalies.js`, 9 passed / 0 failed when executed against fetched main Lua; no client test.
- Independent end audit confirms unchanged scoring in BOTH ledgers: 1,001 processing output source rows + 255 supplemental = 1,256; >=90 0; 70-89 0; <70 1,256; weakest 0. **12 reviewed/proposed dispositions, zero measured numerical field corrections, zero score promotions.** No production addon modified.
- Current next batch: original TSM rate/denominator implementation semantics, another 28 flagged anomalies (200061 milling and 123919 ore first), source-backed current Retail five-ore sampling, exact quality/spec profiles; all-GameData semantic inventory remains unfinished. Retain one-baseline `itemdb.lua` future filename under Issue #2, no addon main migration without approval.


## 2026-10-28 — 28 new distinct TSM anomaly source audits + deduplicated first-pass ledger
- Source of truth: main GameData SHA `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`, Issue #2 and current itemdb v1.1 creation prompt, mechanics/API registries, evidence schema. Future shipped database is `itemdb.lua`, main untouched. Existing first-milestone creation prompt already independently reviewed; no repeated rewrite.
- **Universe:** 1,001 processing + 255 supplemental = 1,256 source rows; 85 duplicate logical source/context keys -> **1,171 distinct scoped logical output records**, six critical fields each = **7,026**. 92 legacy overlay entries separately inventoried (62 numeric mappings, 30 dynamic/profile rules); full non-processing GameData semantic inventory still incomplete.
- **Unique first-pass coverage:** 12 prior Northrend + **28 NEW** (12 Pandaria Trillium, 6 Legion Felslate, 9 Dragonflight Draconium/Illimited Diamond rank combinations, 1 Dragonflight milling) = **40 cumulative**, **1,131 never examined**. **25 BLOCKED, 15 EXAMINED_INSUFFICIENT, 0 CORRECTED, 0 independently >=90**. Source row bands: >=90 0, 70–89 0, <70 1256, lowest 0. Scoped logical record bands: >=90 0, 70–89 0, <70 1171, lowest 0. Evidence score 90 is NOT 90% measured statistical accuracy.
- **Independent numeric findings:** Under UNVERIFIED historical TSM matRate-as-occurrence interpretation, 12 Trillium tuples remain impossible after raw precision rounding (p<=.165 vs E>=.17025); 6 Felslate and 9 DF Illimited Diamond tuples *could* reconcile through rounding; milling 200061->190322 only meets at boundary and recipe eligibility remains unknown. No replacement of TSM raw evidence, no invented 2026 Retail rates, no measured numeric correction.
- **Research files:** `research/ledger/tsm-anomalies-batch2-field-review-2026-10-28.csv`, `research/ledger/first-pass-coverage-v1.csv`, `research/ledger/overlay-first-pass-inventory-v1.csv`, `research/evidence/observations/tsm-anomaly-source-audit-2026-10-28.jsonl`, `research/tests/test_tsm_batch2_and_coverage.js`, `research/reviews/2026-10-28-28row-anomaly-and-firstpass-coverage.md`. **16 static QA checks passed, 0 failed**. No WoW client tests. Independent read-back verified each new file.
- **Rolling 3-run unique first-pass rate:** unavailable (only two attributable batches, 12 then 28). Provisional 2-run mean 20/run, 1131/20≈57 hourly runs (~2.4 days) for scoped first-pass only. Complete itemdb universe and all-fields >=90 completion ETA unknown; gate **NOT MET**.
- **EXACT NEXT 30 logical keys (first-pass unexamined):** source|prospect|72094|76131|-|-|-, source|prospect|72094|76138|-|-|-, source|prospect|72094|76139|-|-|-, source|prospect|72094|76140|-|-|-, source|prospect|72094|76141|-|-|-, source|prospect|72094|76142|-|-|-, source|prospect|72103|76131|-|-|-, source|prospect|72103|76138|-|-|-, source|prospect|72103|76139|-|-|-, source|prospect|72103|76140|-|-|-, source|prospect|72103|76141|-|-|-, source|prospect|72103|76142|-|-|-, source|prospect|123919|130172|-|-|-, source|prospect|123919|130173|-|-|-, source|prospect|123919|130174|-|-|-, source|prospect|123919|130175|-|-|-, source|prospect|123919|130176|-|-|-, source|prospect|123919|130177|-|-|-, source|mill|200061|190320|-|-|-, source|mill|200061|190328|-|-|-, source|mill|200061|198412|1|1|-, source|mill|200061|198413|1|2|-, source|mill|200061|198414|1|3|-, source|mill|200061|198415|1|1|-, source|mill|200061|198416|1|2|-, source|mill|200061|198417|1|3|-, source|mill|200061|198418|1|1|-, source|mill|200061|198419|1|2|-, source|mill|200061|198420|1|3|-, source|mill|200061|198421|1|1|-.
- Next investigate TSM exporter semantics and 200061 recipe/identity; verify per-cast skill/quality conditions; expand TWW/Midnight families. No production release.

---

## 2026-10-28 — hourly batch: 34 NEW first-pass source records, source backed

**Canonical main unchanged:** `GameData.lua` SHA `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`; future single shipped `itemdb.lua` not generated/approved. Original former v0.9.70 ZIP path remains 404; source is extracted Lua. Reviewed live Issue #2, creation prompt v1.1, mechanics/API registries, evidence schemas, raw observations, original ledgers and tests.

- **Source-record universe inventoried and deduplicated:** 1,737 stable keys (1,001 main processing output, 255 supplemental, 92 runtime overlays, 389 source profiles), 0 duplicate keys. This is not every nonprocessing semantic field in the 2,034-line GameData source. `research/ledger/first-pass-coverage-2026-10-28.csv`.
- **New distinct first-pass:** 34 (12 Pandaria Trillium gem rows 72094/72103; six Legion Felslate rare 123919; nine Dragonflight Draconium diamond quality rows 189143/188658/190311; one unresolved milling 200061; six additional Felslate uncommon gem rows). No repeat row counted as new.
- **Original player study preserved:** source Wowhead Legion Jewelcrafting guide, Felslate 3,200 ore, six rare + six uncommon gem output totals and 742 unidentified-color Gem Chips; 640 five-ore *equivalents*, actual Mass Prospect recipe cast count NOT specified. Updated observation schema to permit `completedOperations=null` rather than inventing a cast denominator. Historical decimal E for 12 gems recovered, **not** 2026 Retail-normalized. `research/evidence/observations/legion-felslate-3200ore-community.jsonl`.
- **Other evidence:** a Wowhead White Trillium comment cites ~17% each rare gem vs TSM p=.16 and E=.1705; Dragonflight Wowhead diamond family two distinct 2,000-ore cohorts (3/8 diamond units) lack quality-specific ID allocation and are leads only; milling input 200061 eligibility/item identity unresolved, with E=.005 vs p*max=.002 under assumed five-input batch. Source details: `research/reviews/2026-10-28-first-pass-34-source-backed-study.md`.
- **Field-level score and dispositions**: `research/ledger/first-pass-34-critical-field-scores-2026-10-28.csv` (34 distinct rows, each P, conditional yieldMin, yieldMax, unconditional decimal E scored independently, minimum record score). 13 record floors 0, 21 floors 12; 0 >=70. Original source-confidence ledgers unchanged, none promoted to 90.
- **QA:** `research/tests/test_first_pass_tsm_other28.js`, 27 source/normalization/coverage checks PASS, 0 FAIL after fixing the intermediate CSV newline test bug. Existing second bundled processing overlay issue remains unresolved, no game client or full JSON Schema validator used. Raw TSM evidence retained; no unsupported patches or stat transformation.
- **Coverage now:** 54 cumulative distinct first-pass, 1,683 never-examined, 41 examined-insufficient, 13 blocked, zero corrected current Retail, zero independently substantiated >=90. Original 1,256 material source-output ledger bands: >=90 0, 70–89 0, <70 1,256; min 0. ALL-records-at-90 gate NOT MET.
- **3-run observed new unique** = (8,12,34), average 18/run. At currently configured hourly cadence, 1683/18 -> about 94 runs / 3.9 days for FIRST PASS of only the known partial source-row universe if that rate continues; not an all-fields-confidence completion estimate. Larger source scope means actual timeline uncertain.
- **Exact next 39 unexamined keys**: `research/next-batch-39-tww-prospect-keys-2026-10-28.txt` (TWW Prospect 210930–210938, 39 output IDs). Follow with DF rank evidence, 200061 eligibility, and full nonprocessing GameData semantic inventory. Never modify `main` or create a second bundled database.


### Final independent end-of-run score and regression reconciliation (2026-10-28)
- Re-fetched and re-executed three persisted static research tests against unchanged canonical main source: **16 previous Midnight candidate + 9 previous Northrend + 27 current source/coverage = 52 PASS, 0 FAIL**. These are source/JavaScript tests, NOT in-game WoW client tests, not release qualification.
- Published `research/ledger/field-scorecard-2026-10-28.json` (commit `334a01d93d28667ff92a411d7235bca20b06adbf`, GitHub read-back verified). Across original 1,256 source-output rows, five **legacy** evidence dimensions each = 6,280 scored slots: **0 >=90, 24 at 70–89, 6,256 <70**. The combined old min/max dimension is not the desired separately scored min and max. All original source records still have worst-field <70.
- New 34 source records have **136 independently scored required numerical fields** (P, conditional min, conditional max, E): **0 >=90, 0 at 70–89, all 136 <70**. All 34 new record minima <70 (13 minimum 0, 21 minimum 12). No unsupported score promotions; no current Retail normalizations claimed.
- Deduplicated known source universe remains **1,737 stable keys**, 54 unique first-pass examined cumulatively, 1,683 never examined, 41 examined insufficient, 13 blocked, 0 corrected current Retail, 0 independently substantiated >=90. The whole-file nonprocessing semantic field census is still incomplete; the all-fields-90 gate remains **NOT MET**.
- Run throughput 34 previously unexamined source rows; last 3 record-review batches = **8, 12, 34**, mean 18/run. 1,683 / 18 => **94 additional hourly runs ≈3.9 days** for FIRST PASS of known partial universe only, conditional on sustained rate; not an all-confidence completion estimate. Next 39 exact TWW prospecting overlay keys already persisted at `research/next-batch-39-tww-prospect-keys-2026-10-28.txt`.

---

## 2026-10-28 — Master coordinator first four-worker handoff
- Created versioned master-owned `research/coordination/assignments.json` and independent QA verdict `research/coordination/reviews/2026-10-28-master-initial-qa.md`. Four workers were configured but had not yet executed or submitted reports; no worker results counted early.
- Assigned **140 disjoint NEVER_EXAMINED keys**: Midnight 35, TWW 39, Dragonflight 36, Legacy 30. Workers submit under separate worker-owned directories; master alone integrates central ledgers. Original 54 first-pass examined remain 54; 1,683 never examined until accepted worker QA.
- Independent historical Felslate source audit rechecked 12 output totals and five-ore equivalent arithmetic, without inferring actual Mass Prospect cast counts. Blizzard's April 1 Midnight gem hotfix confirmed; coefficient unknown. A 20-ore Mass Prospect Osmenite recipe documents why operation batch must be recipe-specific.
- No new current-Retail numerical corrections, no >=90 promotions, no new first-pass records from master. No in-game test. 1,737 stable keys / 5,392 potential numeric output-field slots (source-overlap caveat); independently four-field scored 34/136 all <70. Gate NOT MET.
- Rolling 3 attributable unique first-pass batches still 8,12,34 (mean 18/run); 1,683/18≈94 single-worker-equivalent hourly runs ≈3.9 days, **not** a reliable four-worker wall-clock forecast until real worker throughput is measured. Complete inventory and all-fields-90 ETA remain unknown.


## 2026-10-28 — Master QA: Felslate 20-ore recipe and raw evidence schema guard
- Independently verified Legion Mass Prospect Felslate spell 225904 consumes 20 Felslate Ore (123919), supported by Wowhead and Warcraft Wiki; registry records recipe-specific metadata at evidence strength 88, **no output probability/yield coefficient**. The 3,200-ore prior study remains 160 conditional mass equivalents, not 160 observed casts.
- Archived separate 113-reported-cast, 13-unlabeled-total historical Felslate study with 13 exact total/113 arithmetic means; no invented item IDs, drop chances, ranges, current Retail rates or rank mapping. Raw prior study unchanged.
- Fixed evidence schema mismatch: existing historical aggregate status was rejected. Guarded unmapped-only study support now preserves source totals while rejecting empty evidence. Queue revision 2 retains 140 disjoint unexamined assigned keys and 32 distinct next-preview keys; no worker submissions yet.
- New master QA **27 PASS / 0 FAIL**, structural only. Universe 1,737; first-pass 54; remaining 1,683; insufficient 41; blocked 13; current Retail corrections 0; >=90 records 0; modern scored fields 136 all <70; all-fields gate NOT MET. Rolling latest 34/0/0 is not a meaningful four-worker ETA. Full nonprocessing inventory incomplete. See `research/coordination/reviews/2026-10-28-master-qa-schema-and-legion-recipe.md`.
- Next exact worker record keys remain in `research/coordination/assignments.json`; do not replace them with unlabeled historical indices. Production files unchanged.
