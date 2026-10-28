# Database and profession modernization

## Baseline audit (2026-10-28)

Implementation starts at `feature/verified-mechanics-adapter` 4053640 (PR #4), based on main 051f582 / 0.9.70. PRs #1, #3 and #4 are visible; #4 is a draft. The existing adapter tests pass on Lua 5.1. GitHub GraphQL access is unavailable, so PR metadata was inspected using the GitHub web endpoint and Git refs.

The mechanics v0.2 proposal and critical review were inspected at review branch b07384f. They define recipe-scoped, build/context-matched rules, not verified coefficients. The research branch at 1962e00 contains a research-only compiler candidate; it is not merged or deployed. No separately named v0.9.71-test branch, tracked source or workspace artifact was available; all fetched branches retain 0.9.70 runtime source except PR #4's adapter. No unknown test-source functionality is deleted on that assumption.

Baseline: 24 TOC Lua files, one XML file. Runtime dependencies are optional TSM, ATT and BetterBags plus WoW APIs. No third-party Lua libraries are bundled. The cloud has no WoW client.

### Existing flow and problems

* ResearchDB supplies recipe/access metadata; GameData repeats processing maps plus historical TSM maps and low/high profiles. StatYieldProfiles mutates those maps on load and invents occurrence/range proxies from means.
* Core owns disenchant valuation separately from ConversionEngine's milling/prospecting path. Badges sometimes rebuilds a display model, risking divergence from pricing.
* Profession scanning and research snapshots already exist; AltRoster owns mode/eligibility policy. The compact roster uses native Settings controls and must retain its column layout.
* Personal observation recorders and ResearchModel share aggregation semantics but have separate event collectors. TSM prices and conversion reference rates are separate concepts.
* Core item caches and integration caches already avoid repeated lookups. Model caching must not retain market prices, and invalidation must include preference/profile changes.
* PR #4 is the only existing automated runtime fixture. No live-game test evidence is available.

### Ownership after migration

`itemdb.lua` is generated data, `Database.lua` validates and selects/blends evidence, `ConversionEngine.lua` owns final models/valuation and verified numerical mechanics, `Professions.lua` owns character context and eligibility, `Observations.lua` owns recording/aggregation, and shared settings and native bag modules own their corresponding interfaces. Token/ATT/TSM logic remains isolated.

No universal profession coefficient is supplied. Baseline estimates remain explicitly unadjusted until a verified rule applies. Preference weights are not posterior probabilities. Research source updates go through the compiler without engine changes.

## Compiled database

`lua5.1 tools/compile_itemdb.lua` deterministically writes `LootLiquidator/itemdb.lua`. It loads the retained 0.9.70 source snapshots at build time, validates migrated records with the runtime schema validator, and accepts reviewed extensions from `database/records.lua`. It does not fetch or merge ongoing research. The reproducibility test compiles to a fresh temporary file and byte-compares it with the shipped artifact.

Schema v1 contains `version`, `processing`, `inputs`, `mechanicRules` and compatibility aliases for fixed recipes, token candidates and disenchant eligibility metadata. Records identify method/profession, input or gear family, recipe when known, original batch, expansion/quality when known, study identity, provenance, reference conditions, patch scope when known, samples and provisional status. Each material has ID/quality/rarity where known and separate `expectedQuantity`, `dropChance`, `minQuantity`, `maxQuantity` evidence fields, each with value, status, confidence, and claim IDs. Missing fields stay absent. Zero is a genuine numeric value, not an unknown sentinel.

Current migration: 267 source records: 76 primary provisional references, 19 documented smelting recipes, 130 historical TSM references and 42 opt-in legacy scenarios. Most historical context/build/quality information is unknown. The original aggregate means do not establish occurrence probabilities or conditional bounds, so those fields are deliberately absent. The documented deterministic recipes have known quantities/probabilities. No 90-point threshold blocks compilation. Invalid, duplicate or contradictory records fail validation. Generic disenchant gear cohorts use expansion/rarity/weapon-or-armor identities rather than invented item IDs.

The old GameData/ResearchDB/StatYieldProfiles runtime files are removed. Runtime compatibility metadata aliases the compiled tables; it does not keep parallel conversion databases. Raw source snapshots remain outside the installable directory for provenance and reproducible migration. Some compiler inputs still contain old historical descriptions and unused scenario declarations; they are archival evidence, not executable scaling policy. New reviewed releases can replace data and bump `version` without rewriting the engine.

## Evidence weighting

Defaults: itemdb enabled/100, personal enabled/60, TSM reference enabled/30, legacy disabled/10. Weights are global and persisted as `source_<name>_enabled` / `source_<name>_weight`. Effective zero and disabled are equivalent. Market-price selection is independent.

For each eligible source/output/field:

```
weight = (userWeight / 100) × (fieldConfidence / 100)
       × sampleFactor × evidenceClass × contextCompatibility
sampleFactor = n / (n + 30), or 0.35 when n is unknown
class = verified/measured/observed: 1; provisional: 0.6;
        historical: 0.4; modeled: 0.25; unknown/contradictory: 0
contextCompatibility = 1 for an accepted common reference; otherwise 0
```

These are transparent conservative quality heuristics, not Bayesian posterior probabilities or confidence intervals. Expired/hotfix-blocked records, recipe/input-rank/expansion mismatches and uncovered reference-condition differences contribute zero. An exact, independently reviewed numeric bridge may cover the explicitly named context differences. Otherwise a compatible reference can remain a clearly labeled **baseline/unadjusted** estimate, with unknown conditions visible. Unknown-reference cohorts from different studies are not pooled as character-specific evidence.

Primary usable itemdb records anchor selection, followed by personal, TSM and legacy. Records without any usable expected quantity cannot hide a usable fallback. A different source must identify the same reference context/build and conditions to blend; an unidentified historical sample cannot be mixed into a measured character context. Duplicate study/output/field identities count once, in that precedence order. Archived TSM-derived legacy profiles share their underlying TSM study identity.

Means are normalized to the selected original batch before weighted averaging; occurrence probabilities and conditional bounds are never scaled by batch size. Each output/field normalizes its own actual eligible contributions. Bounds come from one identified source, never an averaged range. If combined mean/probability no longer supports those bounds, the displayed bounds are withheld. Compatible means differing by more than 2× generate a warning and halve the reported quality score. Confidence is the weighted field-confidence score, averaged across known outputs, independent of configured slider positions. Tooltip source percentages are the mean normalized contributions across outputs with known expected quantities; they are **not** monetary-value shares. Advanced details retain the personal histogram and bound-source attribution.

Economic value is `sum(expectedQuantity × netUnitPrice)`, with fees applied in the quote once, less additional reagent/vendor costs, divided by the **original** input batch. A verified input-savings rule can add the saved inputs' net value without changing per-operation output quantities or dividing by a reduced denominator. Processing time remains a separate dimension. Missing prices/means or insufficient personal-only samples withhold a recommendation; a partial lower bound remains diagnostic. Unknown conversions never become invented zero-output records.

## Mechanics and profiles

The PR #4 adapter and tests are retained. Executable rules require verified numerical evidence, >=80 quality, source claims, exact recipe/input/output/rank/expansion/build/reference scope and matching target conditions. Compiler additions additionally require `numericTransformValidated=true` and `independentReview='APPROVED'`. Shipped executable rules: **zero**. The v0.2 review supplies no approved numerical coefficients, so this release makes no claim that high profession skill universally raises yields.

Supported scalar dimensions are unconditional output expectation, independently verified occurrence, verified conditional bounds, expected input consumption and operation duration. Unknown coefficients, qualitative “better chance” statements, conflicting rules and unsupported quality/eligibility/vector transforms do not execute; the reference stays unadjusted. Yield changes invalidate baseline probability/bounds unless separate verified rules restore them. A model already transformed cannot be transformed again. Raw baseline records are never mutated. Discrete quality/eligibility transforms require a future reviewed formula implementation; no universal rank or unlock mapping is invented.

Current-character contexts reuse expansion snapshots, specialization ranks, operation base/bonus skill and typed operation stats where available. Profession equipment links are recorded from supported inventory APIs without guessing numeric bonuses. Nil stats stay unknown. Operation reads are cached, and skill/equipment/trait/recipe events invalidate context/model caches. Offline alts use their own saved snapshot and expose stale (>7 days) or incomplete status. They cannot borrow the logged-in character's stats. Fully identified, fresh offline contexts can match a verified rule; incomplete/stale ones cannot.

Each profession page edits a separately stored `manualProfessionProfiles[character][profession:expansion]` simulation. It supplies explicit skill and specialization only when Manual mode and that character's existing participation checkbox allow it. It never overwrites measured snapshots. Force On enables theoretical consideration but does not create recipe knowledge, gear or skill values. Force Off remains an eligibility exclusion. Existing binding, input-count, recipe and alt-transfer checks remain enforced.

## SavedVariables migration

Existing modes, colors, ignored items, observations and scanned characters are retained. New source defaults are added only when absent. On the first migration, a legacy global personal-only/reference-only policy is materialized into methods that were Automatic; explicit per-method choices win. The old global key stays saved but no longer invisibly overrides subsequent UI choices. Re-running migration preserves user source weights and policy changes.

Deprecated manual low/high sliders remain in SavedVariables but no longer drive unverified coefficients, diamond gates, made-up occurrence proxies or inferred ranges. New samples are keyed by character, recipe, build, input rank, batch and skill/spec context. Unversioned older observations remain in statistics/exports but are not silently promoted into a current-build character model. Statistical nearby-skill pooling retains the user's tolerance within an otherwise matching cohort; unsupported specialization point-to-skill coefficients and trend extrapolation are removed.

## Consolidation and preservation

Runtime Lua count **24 → 16** (one XML unchanged). The user-requested package is entirely under `LootLiquidator/`.

| Former files | Owner now |
| --- | --- |
| GameData, ResearchDB, StatYieldProfiles | itemdb + Database; original inputs outside package |
| ResearchModel, DisenchantTracking, ProcessingTracking | Observations (one event dispatcher) |
| AltRoster | Professions |
| ItemRules | Core |
| SettingsButtons, TSMRecommendedUI, ItemIgnoreUI | SettingsControls |
| BlizzardBags, GuildBank | NativeBags (one event dispatcher) |

Unchanged integration/data sources were moved into the package: ATTIntegration, DirectTokenCollector, AltRosterUI, TSMOperations, DB2Restrictions and WagoClassEligibility. Their original runtime APIs remain, as do ignore flags, token/appearance handling, manual participation controls and shared appearance preferences. Consolidated collectors retain independent attribution logic behind shared registration, rather than combining unrelated observations. No TSM operations/profiles are written; no automatic item action is introduced. Full feature equivalence still requires the Retail checklist.

## Validation and performance

`bash tests/run.sh` runs syntax checks, deterministic compilation, manifest coverage and load-order/XML validation, preserved PR #4 mechanics fixtures, modernization fixtures and native settings interaction fixtures. Tests load all 16 modules without the client and exercise initialized SavedVariables, weighted engine/tooltip consistency, documented missing-data behavior, observation identity, and a guild-bank event callback. They do not simulate Blizzard's full UI, protected execution, server loot or third-party addons.

The optional `tools/benchmark.lua` compares 10,000 historical milling-model lookups against the preserved PR #4 baseline. A representative cloud run measured 0.0461 CPU seconds before and 0.0741 seconds after, with 1.1 vs 4.5 KiB retained after GC. The weighted path is slower in this tiny synthetic case (~4.6 vs ~7.4 µs/call); **no overall performance improvement is claimed**. Existing item-decision caches still handle repeated bag redraws. New distribution caches are bounded at 512 entries, context caches at 256 entries / 5 seconds; profile/settings/observation changes invalidate them. Cached distributions exclude market prices; valuation refreshes prices each time. This is not a live-frame or large-bank measurement.
