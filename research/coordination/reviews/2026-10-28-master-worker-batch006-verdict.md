# Master independent QA — worker batch006 (2026-10-28)

**Baseline:** branch 49821faacb512d50837d6ebbb42a5ae4851ab731; root GameData.lua blob 1d47c4a961c5dc5af626e659f7d96d1490d3cf9e. Only research/processing-confidence changed. Canonical itemdb schema v1.1 milestone already completed; no gratuitous prompt rewrite.

## First-pass acceptance and strict limits

Accepted **150** previously NEVER_EXAMINED, disjoint exact source output keys: Midnight 35 (Dragonflight 190395 R1), War Within 35 (Dragonflight 190396 R2), Dragonflight 40 (194545/199344), Legacy 40 (Adamantite, Cobalt, Titanium, Saronite, Pyrite). Independently compared each stable key to its live GameData.lua input-family header, exact source line, output ID, TSM matRate/amountOfMats/minAmount/maxAmount, and 5*amountOfMats necessary bound; all 150 pass. Checked 2649 in-memory static assertions, no failures. TSM units, actual drop probabilities, min/max hard limits, zero-inclusive cast distributions and current Retail applicability remain unverified; passing an inequality is **not** independent empirical confirmation. Four scores are separate; no score >=90.

Coverage ledger: **1737** stable keys, **928** first-pass examined, **809** NEVER_EXAMINED, **915** EXAMINED_INSUFFICIENT, **13** BLOCKED, 0 corrected and 0 >=90. Material outputs four-field scored: **844**, critical fields **3376** (>=90 **0**, 70-89 **17**, <70 **3359**). Potential source+overlay material slots **5392**; nonprocessing GameData census still incomplete.

## Independently corroborated historical source checks

- Original January 17 2022 Titanium ore study https://www.reddit.com/r/woweconomy/comments/s6bfrl/ gives 1000 ore, 50 blue gem units and 54 epic gem units, total **104**, plus 152 Titanium Powder. Descriptive **104/(1000/5)=0.520** units per five-ore equivalent. Historical TSM sum for the same 12 blue/epic rows **0.516** under assumed native units. Difference **0.004**, about **0.775%** of TSM; source did NOT report completed cast count, so this is not a per-cast mean or field promotion.
- WotLK Classic guide https://www.wow-professions.com/wotlk/prospecting-table-wotlk-classic gives six Cobalt rare gem chances 1.3% each versus historical TSM 1.5%; Cataclysm Classic guide https://www.wow-professions.com/cataclysm/prospecting-table-cataclysm-classic gives six Pyrite common gem chances 17% each versus TSM 16.5%. These **12** historical disagreements do not establish 2026 Retail values. Guide comparison: 28 rates, 16 agreements, 12 disagreements; Titanium 12 excluded from same-guide comparison.
- Legacy worker also flagged 12 impossible Cobalt/Titanium common-gem tuples under per-ore E interpretation (p=.235, amount=.5, min1 max2, E5=2.5 > p*max=.47). **Master deduplication: all 12 exact stable keys are ALREADY classified BLOCKED** in the existing ledger from an earlier Northrend review. They are not new corrections, newly blocked rows or first-pass credit. Preserve the anomaly and its original semantics until native TSM documentation resolves it.
- Dragonflight 35-row R1/R2 families repeat 11 rank triplets; the 194545/199344 family repeats additional quality ranks. These cannot be added as independent simultaneous output rolls without verified rank-selection context.
- War Within worker archived Dec 2022–Jan 2023 Dragonflight R2/R3 Serevite cohorts, including the distinct 8000-cast R3 cohort with 2650 ore saved. It is historical Dragonflight input savings, **not** a TWW Resourcefulness formula. Source https://www.reddit.com/r/woweconomy/comments/108782r .

## Parallel numeric mechanics (separate from item coverage)

All **four** candidate JSON objects have required schema fields, applyPolicy=BLOCKED, null formulaID, no validated numeric transform and <90 confidence. Midnight pre/post March 31 2026 gem anecdotes lack matched ore/rank/skill/gear and post actual cast count; Blizzard hotfix https://worldofwarcraft.blizzard.com/en-us/news/24266320 supplies qualitative direction only. TWW lacks per-cast refund totals; Dragonflight historical Inspiration cohorts are unmatched and 2024 removed the stat; Legacy Felslate 5 vs 20 recipe is qualitatively distinct but no same-build matched labeled-output comparison. **VERIFIED_NUMERIC 0; EMPIRICAL approved 0; BLOCKED 4.** Do not apply patch coefficients, universal stat slopes, quality-unlock assumptions or convert saved inputs into extra gems.

## Next 150 disjoint assignments (queue revision 9)

- Dragonflight worker: 40 remaining Dragonflight prospect outputs.
- Midnight worker: 5 Dragonflight prospect outputs, then 30 Legacy prospect outputs.
- War Within worker: 35 Legacy prospect outputs.
- Legacy worker: 40 Legacy prospect outputs.

Exact stable IDs are in research/coordination/assignments.json, assigned only from current NEVER_EXAMINED status; no overlap. Numeric hypothesis assignments remain separate. Next priority: original TSM rate semantics, Dragonflight 194545/199344 recipe eligibility and rank, Pyrite/Cobalt published-rate disagreement, and zero-inclusive controlled cast logs.

## QA boundaries and ETA

2649 deterministic in-memory JS structural/source/arithmetic/queue/schema assertions passed. Candidate schema and proposed itemdb schema were inspected for required structures, **but the repository Node suites** (research/tests/test_numeric_rules.js, test_itemdb_candidate.js, test_mechanics_compiler.js) **were not executed** and no WoW client testing was performed. No production files or automation schedules touched. Rolling last three worker cycles 150/150/150; at 150 unique per four-worker cycle, remaining 809 known keys imply **ceil(809/150)=6** hourly cycles (about 0.25 day) for scoped first pass only. The complete GameData inventory and all-fields >=90 completion ETA are unknown; gate NOT MET.
