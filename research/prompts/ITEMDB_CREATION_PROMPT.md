# Loot Liquidator — ItemDB creation, research, and integration prompt (v1.0 draft)
**Status:** Canonical *proposed* generator/research contract. Research assistant must independently review, challenge, revise, and maintain it. Not an approved production release.
**Target file (EXACT case):** `itemdb.lua`
**Legacy released file:** `GameData.lua` is still referenced in `main/LootLiquidator.toc`. NEVER rename/delete/update it on main without a reviewed, tested addon migration and user approval.
**Repository:** https://github.com/Voodoobrew101/Loot-Liquidator
**Research branch:** `research/processing-confidence`
**Release branch:** `main` (DO NOT automatically overwrite).

## Mission and priority order

Create and progressively improve **ONE versioned, source-backed, machine-validated, Retail-current item/profession processing database**, ultimately compiled as `itemdb.lua`. The database must enable accurate gold liquidation recommendations for prospecting, milling, disenchanting and other *eligible* conversions across expansions, including Dragonflight, The War Within and Midnight.

The **first research milestone** is to review and rewrite THIS prompt, resolving its gaps against the latest mechanics registry, API coverage, research evidence, and actual addon code, and commit a concrete revision that another developer/agent can execute. Continue useful source research in the same run. Later runs continuously improve the prompt only when findings change the contract, not gratuitously rewrite it every hour.

**One shipped static database:** `itemdb.lua` alone must hold ALL bundled permanent item->output mappings, reference probabilities, yield limits, decimal unconditional expected quantities, method/recipe/quality/patch conditions, supported stat adjustment parameters, source identifiers and field-level confidence. The old `GameData.lua` is the source for migration and compatibility checking until release. `ConversionEngine.lua`, `StatYieldProfiles.lua` and UI code implement formulas and read `itemdb.lua`; they may not maintain another permanent item-yield table or silently overwrite it at load time. Personal SavedVariables observations remain separate nonbundled evidence.

## Authoritative research inputs (read fresh, every run)

1. `research/mechanics/ProfessionMechanicsRegistry.json` — primary mechanic/gear/specialization/patch applicability reference. **Its existing v0.2 rules include NO verified executable adjustment coefficients; do not treat it as a numeric normalization service.**
2. `research/mechanics/WoWRuntimeAPIRegistry.json` — what WoW Retail exposes live; distinguish own-character current API, UI-dependent, event-only, cached alt, simulated, external-only, and unavailable values.
3. `research/evidence/README.md`, `research/evidence/observation.schema.json`, and `research/evidence/observations/*.jsonl` — source-backed original measurements and their *original* conditions.
4. `research/ledger/*.csv`, `research/research-sources.md`, `research/run-log.md`, `research/PROGRESS.md`, `research/tests/*` — inventories, anomalies, peer comparisons, scoring, continuation.
5. The *actual* `main/GameData.lua`, `main/LootLiquidator.toc`, `ConversionEngine.lua`, `StatYieldProfiles.lua`, `Professions.lua`, and other related source modules. Check live GitHub SHA; do not rely on an obsolete ZIP pathname.
6. [Integration Issue #2](https://github.com/Voodoobrew101/Loot-Liquidator/issues/2) and any approved updated design decisions.

If a source conflicts with this prompt, preserve evidence and explicitly document the conflict. **Newest user decision takes priority:** one baseline, future filename `itemdb.lua`, per-field confidence, no generic Low/High parallel tables.

## Data model: source and operation identity

For each processing input and genuinely obtainable output, identify:
- Retail vs Classic/PTR, expansion/skillline, exact recipe/spell, input ID and reagent rank, output ID and output rank (NOT item rarity), relevant item level/rarity/armor class for disenchant cohorts, processing method, and exact consumed-input batch.
- Reference game version/build, known effective hotfix window, skill, committed specialization node/ranks, applicable profession tools/accessories, stat values, buffs, Concentration usage, and eligibility restrictions.
- A stable reference-context ID and the selected source observation(s). One **best-supported baseline under EXPLICIT CONDITIONS**, not necessarily zero skill nor max skill. Maintain multiple independent experiments in the archive; DO NOT force two fabricated Low/High columns in `itemdb.lua`.
- A provenance link to raw observations, source type, exact sample count, publication/retrieval date, verified or unknown patch window, and conflicts. Data cannot be marked current merely because it is the newest historical study.

Each genuine output has **four separate values**, with evidence and confidence scored *independently* (0–100):
1. `dropChance`: probability 0..1 of getting >=1 output unit in ONE operation (tooltip).
2. `yieldMin`: smallest positive INTEGER units when output occurs; mark observed vs verified mechanical minimum (tooltip).
3. `yieldMax`: largest positive INTEGER units when output occurs; mark observed vs verified mechanical maximum (tooltip).
4. `expectedQuantity`: UNCONDITIONAL decimal mean units per operation, including zero-drop casts (the ONLY material count multiplier for gold valuation).

For EACH field preserve `value` or null (unknown), `confidence` or null, `status` (measured, official, reported, modelled, proxy, unknown or contradictory), sample n, uncertainty interval where estimable, `sourceClaimIDs`, patch/context compatibility, verified date and research blockers. Also track separate transformation confidence and derived-result confidence. A per-record confidence floor is the weakest material field, never an average hiding weak fields. A 90 evidence score does NOT mean 90% statistical accuracy.

**Numerical invariants:** `0<=dropChance<=1`, conditional limits are integers `1<=min<=max` if outcome is possible; `expectedQuantity>=0`; for the SAME eligible operation/context and independently supported fields, `p*min<=E<=p*max` subject to documented measurement tolerance. Do not force weak probabilities/ranges to match good E; investigate. Multiple outputs can co-occur; their chances need not sum to 100%. Missing/unknown != confirmed 0 or ineligible.

**Preserve raw data beyond these four numbers:** zero-inclusive per-cast output histograms, simultaneous outputs, bonus-proc flags, resource savings, craft-result event completeness and operation denominators when available. Aggregate totals/N support E, NOT P(drop) or positive conditional min/max without per-cast evidence.

**Valuation:** compute `sum(expectedQuantity_adjusted * net_realizable_output_unit_price)`, using the correct input batch and output item/rank, and adjust for confirmed costs/savings, posting fee, AH cut, ignored or inaccessible outputs. Do NOT multiply unconditional E by P again or infer E from midpoint [min,max]; do not normalize the same batch twice. Missing material prices imply a labelled partial lower bound, not guaranteed full conversion EV.

## Mechanics normalization and API boundaries

Use `ProfessionMechanicsRegistry.json` to determine patch windows, eligibility, effective skill/gear/specialization/stats, and **verified applicability per recipe/output**. Only apply an executable correction when its formula, patch domain, units, rank/quality conditions, direction and independent evidence are verified. Qualitative descriptions or unknown numeric effects are **BLOCKED** for conversion; an absent coefficient is never treated as 1.0 or a universal linear skill slope.

Handle separately: output chance, conditional yield distribution, unconditional E, output rank/quality transition, material eligibility, input reagent savings, operation time, and Concentration/Ingenuity expenditure. Resourcefulness input savings must not be multiplied into drop counts. Inspiration cannot be substituted for Ingenuity. Treat ore-specific Eversong Diamond nodes as *increased chance* unless strict zero-without-node eligibility is independently proven.

Critical historical event: **2026-04-01 Midnight prospecting gem frequency hotfix**, with an unknown numerical magnitude; do not numerically convert unbridged prehotfix gem-rate studies to posthotfix. Client build from `GetBuildInfo()` does NOT reveal an unpublished hotfix ratio.

WoW API provides player/current-recipe context when accessible: child profession skill-line IDs, recipe requirements, specialization ranks, equipped gear, optional crafting operation stats, quality and observable outcomes. It **does not provide hidden output drop probabilities**. Operation APIs may require real reagent allocations and open own-profession UI; do not assume all outputs/events are complete for prospect/mill/DE. An offline alt has only a timestamped cached snapshot; never read current character stats as though they belong to an alt. Unknown is null, not zero. No in-game verification claim without real client results.

**Reference selection:** same-patch, same-recipe, same-input-quality, same-output-quality, same relevant profession condition > independently *transformable* measured alternative > explicitly described provisional baseline/fallback if no valid transform. Label live vs simulated vs cached-alt vs reference and all uncertainty. Do not call unmatched old data “normalized current Retail.”

## Build and migration deliverables (research branch only)

- Maintain a **rewritten and versioned** `research/prompts/ITEMDB_CREATION_PROMPT.md` following the first research pass, with a change log and reviewed unresolved questions.
- Source-backed `research/evidence/observations/*.jsonl`, cited mechanics/patch claims, confidence ledger, deterministic normalization/selection tests, and precise patch/skill/quality cohort matching.
- `research/proposed/itemdb.schema.json` (or documented Lua schema) and `research/proposed/itemdb.lua` as **proposed** generated artifact ONLY after evidence and schema checks. If numbers aren't supported, use null/provisional status or explicit blockade—not a fake 90/100 field.
- A deterministic reproducible build method and manifest recording source SHAs, generator version, game version/hotfix coverage, count of accepted/blocked records, output checksum, and a full no-loss comparison against existing `GameData.lua` plus **all runtime overlays** currently outside it.
- Regression tests: correct 5-ore vs 10-herb normalization, per-cast probability vs quantity, same-output quality variants, actual/simulated/offline-alt conditions, Talents/Node ranks, unidentified gear, nonconvertible patch samples, output/item eligibility, 0 vs unknown, TSM inconsistent rates, missing prices, no duplicate static mappings, and exact same selected data in tooltip and gold evaluation.
- A safe rollout plan for later **renaming the addon module**: create `itemdb.lua`, change `LootLiquidator.toc` load entry, migrate all `GameData.lua` references/initialization as needed without silently altering the runtime namespace unless agreed, test Lua 5.1 syntax/load ordering and WoW smoke tests, then remove `GameData.lua` *only after successful reviewed migration*. **Don't rename current main production file automatically.**

**Incremental scope:** inventory all data types in the legacy file (processing outputs, tokens, conversions, profession data, historical TSM, etc.), not only Midnight ores; retain legal valid associations, but flag dubious historic conversions. Prioritize high-impact Midnight, TWW and Dragonflight, then systematic historical expansions.

## Every research run

1. Read and reconcile GitHub source revisions, current research state, this prompt, current mechanics/API registries, and previous QA/test failures. On first run, rewrite this database creation prompt with a concrete field schema and actionable staged migration; preserve existing measured data. Commit the rewrite.
2. Perform a substantial new research/verification batch; check official patch docs, current Retail data, measured experiments, item IDs and profession mechanics. Prioritize high-economic-impact and weakest-evidence relationships.
3. Archive sources immutably, cite claims, update only justified values and individual field scores; stratify patches, spec ranks, gear and item qualities. Examine independent counterevidence and self-audit.
4. Run reproducible schema/math/provenance/compatibility checks, record which tests actually ran and which require an in-client WoW test; do not pretend CI/in-game checks passed.
5. Commit the work to `research/processing-confidence`, verify GitHub readback. Never merge to main, rename production files, or overwrite this project's unreviewed developer work.
6. Update `research/PROGRESS.md` and `research/run-log.md` with exact next targets and actionable blockers. Report scored coverage bands `>=90`, `70–89`, `<70` **per material field AND worst-field record**, numbers improved, data sources, unresolved corrections, build/test status, commit links, and whether all *verifiable* data reach >=90. Continue researching honestly if not.

If repository writes fail, report the error and supply downloadable deltas where possible. Do not promise a background release. The hourly schedule is managed by the automation, NOT by this document.
