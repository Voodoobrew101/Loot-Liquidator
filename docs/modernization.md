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
