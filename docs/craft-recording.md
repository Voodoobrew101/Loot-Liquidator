# Recording crafting evidence

Version 0.10.0-alpha10 records measured Retail crafting and processing operations for the mechanics v0.2 contract, empirical baselines, and the conversion engine. It never changes either item database or approves a numerical mechanics rule. Real-client validation remains pending.

## Recording workflow

1. Back up `LootLiquidatorDB`. Enable **Record crafting and processing results** for crafts/milling/prospecting, and the separate disenchant recording preference for disenchanting. Open your own profession UI so current skill, specialization and operation data can be read.
2. Run `/ll craftstudy LABEL` before a controlled session. Keep all required reagents in character bags. Craft normally; the addon only observes. Let each operation's loot/results settle before the next cast, and avoid looting unrelated items, trading, selling, mailing or bank transfers during capture.
3. Run `/ll craftstats` to inspect complete/unresolved counts. Timeout, missing loot, interruption, or an unknown output never automatically means zero. A successful isolated cast with consumed inputs and no outputs stays unresolved after the result window.
4. Only if you personally verified that such a cast genuinely produced nothing, run `/ll craftzero` after tracking finishes (normally 13 seconds after success). It confirms only the latest isolated empty candidate, on the same character/build with unchanged inventory, and labels it **operator-confirmed-empty**. Do not use it when loot is delayed or uncertain.
5. Stop crafting before exporting. `/ll craftexport 1` opens paged JSON, 25 records per page. Save every page indicated by `pages` as a separate `.json` file. `/ll craftbaseline` provides an inspection summary of eligible cohorts; retain the raw pages for review.

Validate and stage the raw pages outside the addon directory:

```bash
python3 tools/validate_craft_export.py cast-page-1.json cast-page-2.json --output staged-baselines.json
```

The validator requires all pages from one stable export, rejects duplicate or mismatched operations, and excludes cohorts with unresolved results or study coverage gaps. It outputs research JSON, not an installable Lua database. Reviewers must reconcile it with the research schema/compiler and independently approve any proposed mechanics. No sample-count threshold alone grants approval.

Exact ItemDB milling/prospecting recipes use their recorded method, input identity and batch before generic craft detection or compatibility hints. This includes BFA mass milling's twenty herbs. Unknown/mismatched input context or conflicting batch definitions remain diagnostics; they do not fall back to a convenient old batch. Raw collection can continue with yield sources disabled, while source controls still gate subsequent valuation. Bag-only outputs must belong to the captured recipe (or a reference with no recipe identity); reported typed results are reconciled with inventory independently.

## What is captured

Each cast log includes a unique player cast GUID, recipe/spell, method, character/build, completion evidence, timestamps, measured profession context, item input/output vectors, available item rank/rarity/level/link, actual reagent allocation and concentration choice when observed, and typed craft-result metadata. Input allocation and resource-return fields are preserved independently of bag deltas.

The context reads current recipe profession information, expansion skill line, base/bonus/effective skill, specialization ranks, equipment links, and operation stats using the actual allocation when available. Each unavailable field remains unknown. Manual simulations and offline profiles are never substituted into measured records. Current context must match again before personal valuation; a gear change, respec, unavailable skill field, or changed operation stats cannot silently reuse a different baseline.

The baseline is the average **at the recorded conditions**. It is not automatically a minimum-skill baseline or a formula for another character. API stats and proc labels do not establish hidden probability coefficients.

Per material, a complete cohort produces:

- Unconditional expected quantity: total output / all confirmed operations, including confirmed empties.
- Occurrence: operations with that material / all confirmed operations.
- Conditional bounds: observed minimum/maximum among positive results, explicitly not guaranteed limits.
- An output-count histogram including zero and the source operation IDs.

Nominal input quantity remains the valuation denominator. Reported reagent returns can establish lower **net** consumption without reducing the nominal batch. The engine accounts for the saved inputs once; no Resourcefulness or Multicraft coefficient is inferred. Multi-input crafts are captured and staged, but are not priced as if they consumed only the evaluated item. Fully empty cohorts do not invent output item IDs or a zero-gold recommendation.

## Provisional data and compatibility

Raw data uses `loot-liquidator.cast-log/1`, `sampleKind=RAW_CAST_LOG`, `independentReview=PENDING`, and `applyPolicy=NO_NUMERIC_TRANSFORM`. Staged cohorts use `loot-liquidator.empirical-baselines/1`. Confidence is unscored in both exports. The engine's existing personal-source capture-quality factor (0.85) and sample discount `n/(n+30)` are weighting heuristics only; personal tooltips display **Confidence unscored**, the measured context, and provisional status. No posterior probability or reviewed evidence score is claimed.

Only complete cohorts from the active study with exactly matching measured character/recipe/input/build/context can feed personal valuation. Personal-only policy still excludes external sources and enforces the configured minimum sample count. Existing itemdb precedence and source controls remain in effect. A missing usable cohort yields Insufficient Data under personal-only policy.

Old aggregates, preferences, processing CSV exports, and public diagnostic commands remain available. The new additive SavedVariables key is `craftResearch`; old positive-only records are not rewritten into zero-aware samples and no longer supply new personal valuation. New records retain immutable copies of their inputs and contexts.

## Capture limits

The collector accepts matched successful player casts with a pre-cast bag snapshot and either closed loot or matching typed craft results. It rejects ambiguous batches, mixed item variants, unmapped bag-only outputs, unrelated inventory interactions, conflicting result duplicates, and overlapping operations that cannot be separated. Diagnostics retain the available raw facts; a successful unattributed operation censors the study so its remaining successes cannot create a biased denominator. Start a new controlled study after investigating the gap. An active study left by an interrupted client session is also censored on reload.

Generic learned recipes support fixed required reagents and observed optional/alternative allocations. Recrafts, customer orders, enchant-only results, reagent-bank/customer inventory, and unknown allocations are not supported as complete samples. Rapid multi-craft sequences may be censored if their results overlap. Some modern API fields may be unavailable until the relevant profession UI is open; export still retains those unknowns.

The ledger retains at most 2,000 records, 256 distinct contexts, and 50 diagnostics. Eviction marks the affected study truncated, preventing incomplete-study baselines. Export regularly; the addon does not upload or clear data automatically. Retail testing of event ordering, loot delays, quality outputs and resource returns is required before treating this alpha recorder as a validated collection instrument. See [Retail QA](retail-qa.md).
