# Verified profession-mechanics integration — phase 1

Status: **draft / not production-approved**. Source: `review/profession-mechanics-registry-v0.2` proposal and its audit. The proposal is **not** a verified numeric yield database. At time of integration it has no executable coefficients.

## Changes actually implemented

- `ConversionEngine.lua` owns the verified numeric adapter. No new runtime Lua file is loaded.
- The existing `ConversionOptions` processing path invokes the adapter on the reference model **before personal observation blending** and before valuation. Its returned `yieldModel` is also used by tooltip displays.
- Original reference material records are copied, never rewritten.
- No real numeric rules are populated in ItemDB yet, so the default behavior is unchanged. No numeric impact should be claimed without eligible verified rules.
- CI includes a standalone Lua 5.1 regression fixture, including no-op, missed build, missed recipe, missing evidence, conflicting rules, offline alt and probability/quantity distinctions.

## Compiled contract (not raw JSON)

After scientific review, a build process must emit `LL.ItemDB.mechanicRules` as a Lua array within generated `ItemDBRuntime.lua`. Each rule must contain:

| Key | Requirement |
| --- | --- |
| `ruleID`, `sourceClaimIDs` | Stable rule and at least two distinct traceable scientific claims |
| `evidenceStatus`, `applyPolicy`, `applies` | `VERIFIED_NUMERIC`, `EXECUTE`, `VERIFIED_APPLIES` |
| `confidence0to100` | Numerical score >= 90, *not* merely qualitatively documented |
| `method`, `expansionID`, `recipeID`, `inputItemID`, `inputQualityRank`, `outputItemID` | Exact identifiers; no expansion-wide or recipe-family guesses |
| `sourceBuild`, `targetBuild` | Source model build and live client build; both required |
| `sourceReferenceContextID` | Exact ID matching reference model's `referenceContextID` |
| `targetConditions` | Exact known character context fields or an explicit empty table for truly unconditional rules |
| `effectTarget`, `formulaID`, `parameters` | See below |
| `numericTransformValidated`, `independentReview` | `true`, `APPROVED` |

Supported strictly bounded operations:

- `OUTPUT_UNCONDITIONAL_EXPECTATION` + `MULTIPLY` with `parameters.multiplier` from 0 to 10. This changes EV units **only**; no additional probability multiplication.
- `OUTPUT_OCCURRENCE` + `MULTIPLY`, only with `material.probabilityVerified=true` and an output probability <=1.
- `OUTPUT_POSITIVE_QUANTITY` + `SET_VERIFIED_RANGE`, with positive integer `minQuantity` and `maxQuantity`.

The adapter does **not** derive ranges or event probabilities from expected quantities. When expected units are transformed, baseline occurrence and ranges are invalidated until separately verified and transformed.

A different mathematical transformation, an unknown patch coefficient, a missing source build/context, an offline character, or conflicting rules for the same field cannot modify a baseline. **Do not emit a fake 1.0 multiplier when coefficients are unknown.**

## Integration remaining

1. Research/review team produces **numeric, recipe-scoped** coefficients with versioned source claims and exact reference contexts; review each before shipping.
2. The compiler now translates reviewed registry rules into generated `ItemDBRuntime.lua` and rejects unsupported approved transforms. The live adapter reads this canonical collection directly; the obsolete GameData alias does not execute. Current research deliberately yields **zero applicable rules**.
3. Add exact build and reference context IDs to eligible compiled baseline records; do not manufacture missing IDs.
4. Run Lua 5.1 tests and real Retail tests using measured profession snapshots, personal and alt modes, and tooltip display.
5. Audit duplicate/dead functions, compare `v0.9.71-test` changes against v0.9.70 tracked source, then consolidate only proven redundant modules. Keep a clean, separate refactor commit.
6. Only after review, merge and package. Do not touch `main` automatically.

## Consolidation scope

Current tracked TOC: 25 Lua sources + one XML. Target reduction is not a guarantee. Begin with redundant tracking and UI wrappers; preserve BetterBags, Guild Bank, ATT, TSM, token progress and personal observations. No deletion can be justified from file names alone.
