# Loot Liquidator Legacy — batch006 (2026-10-28)

**Worker:** loot-liquidator-legacy. **Assignment:** `2026-10-28-batch006-legacy`, queue revision 8, 40 disjoint master-assigned output-main TSM stable keys (L881–L940, selected only). **Current baseline:** 778/1737 first-pass examined, 959 never examined at master queue rev8; this submission does not advance master counters. **Source:** actual root `GameData.lua` blob `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`. **Branch:** `research/processing-confidence`. No production or master-owned files modified.

## Scope and independently scored fields

40/40 assigned keys read from exact source lines and examined: Adamantite Ore 23425 (4 rare outputs), Cobalt Ore 36909 (6 rare), Titanium Ore 36910 (12 blue/epic), Saronite Ore 36912 (12 common/rare), Pyrite Ore 52183 (6 common). See immutable [40-key CSV](2026-10-28-0640-legacy-batch006-40key-audit.csv) for each source line, input/output ID, 5-ore batch, original TSM `matRate`, `amountOfMats`, conditional min/max, per-five-ore expectation, external occurrence claim, four independent confidence scores, unknown sample count and blockers. No new >=90 field-complete record; **0 verified current Retail corrections**.

For each output, historical `E5 = 5 * amountOfMats` is an explicitly *conditional interpretation* of TSM's source units, not a verified measured current-Retail expectation. `matRate` is a historical proxy, **not proven P(at least one)**. All 40 assigned rows satisfy the necessary `matRate * minAmount <= E5 <= matRate * maxAmount` arithmetic bound. This does not prove probabilities or actual TSM units. **Never multiply E5 by matRate again.** Yield extrema are historical TSM claims, not verified observed hard limits.

## Independent published-guide cross-check

Sources: [WotLK Classic prospecting table](https://www.wow-professions.com/wotlk/prospecting-table-wotlk-classic), [Cataclysm Classic prospecting table](https://www.wow-professions.com/cataclysm/prospecting-table-cataclysm-classic). Both specify a five-ore standard operation, with common and rare gems potentially produced together; neither publishes sample N or 2026 Retail build.

- Adamantite's four assigned rare outputs: TSM 4.0% vs published 4.0% (four agreements).
- Cobalt's six assigned rare outputs: TSM 1.5% vs published 1.3% (six disagreements, 0.2 percentage points each).
- Saronite's six common and six rare assigned outputs: TSM 18%/4% vs published 18%/4% (12 agreements).
- Pyrite's six assigned common outputs: TSM 16.5% vs published 17% (six disagreements, 0.5 percentage points each). Published Pyrite table additionally mentions Volatile Earth, which is **outside these assigned keys** and requires a separate eligibility/coverage audit.
- Titanium: the WotLK guide does not list Titanium; use original player aggregates and [Wowhead Titanium ore historical comments](https://www.wowhead.com/wotlk/item=36910/titanium-ore) as leads, not an invented guide percentage.

**Total guide comparison:** 28 assigned rows with comparable guide rates, 12 rate differences, 16 agreements; 12 Titanium rows have no same-guide item-rate comparison. None of the 12 differences alone proves a current-Retail defect.

## Original Titanium aggregate: 12 mapped gem outputs

A [January 17, 2022 original player report](https://www.reddit.com/r/woweconomy/comments/s6bfrl/) describes **1,000 Titanium Ore** and exact totals for all 12 assigned blue/epic outputs: blue [10,10,11,8,5,6] = **50**; epic [13,12,7,7,8,7] = **54**; combined **104** gem units. It also reports 152 Titanium Powder (not a member of these 12 assigned gem rows). Source-only structured [observation JSONL](../../evidence/observations/2026-10-28-0640-legacy-batch006-titanium-2022-1000ore.jsonl) preserves mapped item IDs and source totals with `completedOperations=null`, unknown hits/zeros and unknown skill/gear/patch.

- 1,000 / 5 = **200 derived five-ore equivalents**, NOT a source-reported actual cast count.
- Descriptive aggregate: 104/200 = **0.520** blue+epic gem units per five-ore equivalent.
- Historical TSM sum for those same 12 outputs: 6*(5*0.0081) + 6*(5*0.0091) = **0.516** per five-ore equivalent.
- Difference: **0.004 units/equivalent**, about **0.78%** of TSM sum. This is a valuable independent aggregate cross-check but **not** verification of individual P(hit), conditional yields, a same-build study or 2026 Retail applicability. No coefficient or source blending was applied.

## Important adjacent anomaly — NOT credited as assigned first pass

While verifying the assigned rows, detected **12 adjacent, currently unassigned TSM common-gem source rows**: `GameData.lua` lines 887,889,891,893,895,897 (Cobalt) and 901,904,907,910,913,916 (Titanium). Each stores `matRate=0.235, amountOfMats=0.5, minAmount=1, maxAmount=2`. Under the project's current per-ore interpretation, `E5=2.5` per operation, exceeding the stated maximum possible output of **2** for each row. It also violates `E5 <= matRate*maxAmount = 0.47`. These are **source semantic/normalization blockers**, not proof that the game drops are wrong. Do not silently fix by changing probability, range or denominator. **Master should assign these 12 keys for explicit source-unit reconciliation**; this worker claims zero first-pass credit for them.

## Parallel numeric mechanics hypothesis: legacy-felslate-standard-mass-compare

- Standard Felslate prospecting consumes **5 ore**; [Mass Prospect Felslate spell 225904](https://www.wowhead.com/de/spell=225904/massensondierung-von-teufelsschiefer) consumes **20 ore** and is a separate profession recipe. The original **113 mass-cast, 13-column vector** remains unmapped to item IDs and lacks per-cast zero counts.
- The [September 8, 2016 original Felslate thread](https://www.reddit.com/r/woweconomy/comments/51ovfk/possible_prospecting_nerf/) reports first 15*1,000 ore = **560** rare gems, last 10*1,000 ore = **97** (independently corrected by master; **not 101**). Descriptive five-ore equivalents: **0.186667** vs **0.0485** rare units. The author attributes a possible patch effect; these are **not** same-build standard-versus-mass cohorts.
- A distinct [Wowhead Empyrium mass-prospect recipe commenter](https://www.wowhead.com/pt/item=152726/desenho-prospeccao-em-massa-de-empirita) describes a *matched input amount* of **340 Empyrium ore per method**, 63 standard gems versus 31 mass gems. Arithmetic: 63/340*5 = 0.92647 and 31/340*5 = 0.45588 per five-ore equivalent; mass/standard = **31/63 ≈ 0.4921**. **Different ore and unknown build/skill:** this is a historical warning that recipe methods might differ, not evidence of any Felslate multiplier. Actual cast counts, output IDs and zeros were not supplied.
- **Mechanic remains BLOCKED**: no matched same-build 5-ore vs 20-ore Felslate cohorts, no mapped 113-cast vector, no verified 2026 recipe/character context. No formula, output multiplier, confidence >=90 or shipped candidate approved. See [schema-shaped numeric candidate](2026-10-28-0640-legacy-batch006-felslate-numeric-candidate.json).

## QA and exact next targets

Static independent tests: 40 unique assigned keys, 40 exact GameData line/output matches, 40 internal necessary P/E/yield bounds, 28 guide comparisons, 12 documented rate differences, 12 adjacent unassigned normalization violations, 12 source-mapped Titanium aggregate outputs, 104=50+54 and 0.520 vs 0.516 source arithmetic. Observation and numeric-candidate required-field/type/enum shape checked against current schemas; **full external JSON Schema runner, repository Node harness and live WoW tests not executed**. [Validation file](2026-10-28-0640-legacy-batch006-validation.json).

**Master handoff:** 40 first-pass audits submitted pending master acceptance; 0 verified corrections; 1 distinct numeric hypothesis examined and BLOCKED; 0 VERIFIED_NUMERIC. Master to reconcile the 12 unassigned common-gem denominator contradictions (exact lines above), check Titanium source cast counts and per-item P, verify Pyrite's Volatile Earth association, and request matched Felslate 5/20 recipe experiments with >=200 actual casts each, per-cast zeros, explicit IDs, build, skill, spec, gear, and input refunds. Remaining first-pass at queue revision 8 was **959 before this batch and other concurrent submissions**, not an independently refreshed global count. Do not advance master ledger or claim all-fields >=90.
