# Critical architecture review: ProfessionMechanicsRegistry v0.1.0

**Review date:** 2026-10-28  
**Examined:** `research/mechanics/ProfessionMechanicsRegistry.json` at blob `b8e7d141a946ce39e0dfe6398c30244e39e5bf65`  
**Disposition:** **RESEARCH INDEX ONLY — NOT A SAFE NUMERIC NORMALIZER OR PRODUCTION MODEL**

## Executive conclusion

The current registry's conservative rule — *never invent patch/skill multipliers* — is sound. Its contents are **not sufficient to convert historical or unknown-skill samples into a current-Retail baseline**. There are 12 expansion labels, 11 high-level stats, four coarse specialization records, five patch events, and no evaluated per-recipe conversion coefficients. Absence of a correction coefficient MUST NOT trigger an assumed multiplier of 1.0, particularly across an identified hotfix with an unknown size.

The most important distinction is between (a) a fact that some mechanic exists, (b) **proof that it applies to an operation/output**, and (c) **a verified transformation of the output distribution**. The v0.1 registry tends to represent (a), not (b) or (c).

## Findings and required repairs

| Priority | Finding | Risk | Correction and acceptance criterion |
|---|---|---|---|
| P0 | Mechanic scope stops at profession/expansion, not a *specific recipe/spell/input/output*. | Ingenuity/Concentration, Multicraft or Resourcefulness can be applied to an ineligible processing operation. | Fail closed without a verified recipe family or IDs and applicable output category. Store eligible/explicitly ineligible/unknown and exact evidence for each. |
| P0 | No normalized executable adjustment-rule representation (effect type, target field, coefficient, prerequisites, patch interval, variance). | Conversion engine cannot apply registry safely; agents may devise ad hoc universal factors. | Typed versioned rule with target field(s), unit, `formulaId`, parameters, applicability and status. Only numeric-verified rules may execute. |
| P0 | Registry labels one baseline but not an *identifiable reference condition* and exact target patch. | Untrained + max-skill and pre/post-hotfix experiments can be silently pooled. | Each baseline references observed context ID (recipe/rank/skill/spec/gear/stats/patch/game mode) and target build. Baseline is chosen, never synthesized without identified transforms. |
| P0 | Patch records are sparse and hotfix coverage incomplete; effectiveDate nullable without clear boundaries. | Samples cannot be screened for all relevant era transitions. | Every event has `firstAffectedBuild/date` or explicit unknown, affected *methods/output families*, and `knownNumericalEffect`; any crossed unknown-effect event blocks numerical conversion. |
| P0 | Diamond node wording says “better chance”, not “can only drop when learned”. | The released engine's binary diamond gating can turn legitimate non-specialized probability into zero. | Store `effectType: probability_increase`, `unlockStatus: UNVERIFIED`, not an eligibility gate until supported. Review existing engine against source. |
| P0 | Additional ratio transformation assumes effect is multiplicative with no independence/interaction proofs. | Wrong per-material EV if quality bins change, eligibility is gated, or stat effects combine nonmultiplicatively. | Require exact recipe/output-specific, validated model domain; enforce positive denominators, no rank/cap crossings unless model explicitly handles it. |
| P1 | No distinction between observations' **aggregate yields** versus per-operation hit histograms. | A 0.7 mean is mistaken for 70% chance or its observed min/max treated as true bounds. | Raw histograms/cast counts support drop chance and observed conditional bounds; aggregate totals support only decimal expected quantity. Always retain `fieldEvidence` and sampling uncertainty. |
| P1 | `observationContextSchema.required` includes fields routinely undisclosed, but lacks missingness reasons and observed-vs-derived sources. | Unsupported unknown -> 0 (e.g., 0 specialization) or false precision. | Use typed nullable fields with `unknownReason` and `observationQuality`; separate 0 from unobserved; block extrapolation when pertinent context missing. |
| P1 | Old expansion labels indexed numerically 0–11 but no version/skill-line namespace. | Retail expansionID might be confused with a skill-line ID, expansion enum, or classic-era taxonomy. | Define stable registry expansion key plus explicit `skillLineID` per profession/expansion; distinguish Classic-era skill-system from modern Retail API. |
| P1 | Equipment registry has no actual item IDs, stats, quality, or equipped-sample evidence. | Secondary-stat retroactivity may be confused with primary-skill retroactivity; wrong expansion applicability. | Catalog gear item ID, item quality, base + bonus skill, secondary-stat rating and effective %, gear-expansion and target-expansion applicability, with patch-specific evidence. |
| P1 | `craftingSpeed`, `deftness` and Resourcefulness do not share the same economic dimension. | Output-per-cast and gold-per-hour or input costs get mixed. | Separate `outputDistribution`, `expectedInputsConsumed`, `timePerOperation`, `qualitySelection` and `eligibility` effects; prohibit direct EV changes absent proof. |
| P1 | No evidence claim identifiers or source-to-rule traceability. | A URL to a broad guide is mistaken for numerical validation. | Claim ID, linked source URI, relevant claim/section, publication date, patch validity, evidence class, sample count and confidence per field/rule. |
| P1 | `status: DOCUMENTED_MECHANIC` and “PARTIAL” are not machine decision states. | Parser cannot tell which rules are safe to apply; impossible to test. | Enums: `VERIFIED_NUMERIC`, `VERIFIED_QUALITATIVE`, `EMPIRICAL_ESTIMATE`, `UNVERIFIED`, `CONTRADICTED` + `applyPolicy`: `EXECUTE` or `NO_NUMERIC_TRANSFORM`. |
| P2 | Registry has only a handful of patch entries; even a non-yield stat rebalance can matter for real character snapshots. | Historical/current profession stat ratings compared on wrong conversion curve. | Index relevant official patch notes per expansion; distinguish throughput-only changes from yield changes and update stat-rating conversions. |
| P2 | Separate `focus` key is unresolved, while “all era” coverage suggests completeness. | Nonexistent universal stat or conflation with Concentration. | Keep `focus` quarantined as unresolved term, do not include in a universal stat normalization table without a named mechanic and IDs. |

## Verified external checks

1. **April 1, 2026 Midnight gem buff:** Blizzard documented higher gem frequency but gave no numeric coefficient. All unbridged pre-hotfix gem-rate transformations remain blocked. Source: https://worldofwarcraft.blizzard.com/en-us/news/24266320 .
2. **Inspiration → Concentration / Ingenuity:** Blizzard's TWW pre-expansion patch explicitly says Inspiration was removed; Ingenuity refunds a percentage of Concentration when it procs. It is not interchangeable with Inspiration probability. Source: https://worldofwarcraft.blizzard.com/en-us/news/24119590 .
3. **Midnight prospecting specializations:** Wowhead describes ore-specific nodes as increasing the chance for Eversong Diamond. It does **not** in this description establish a strict 0% chance without nodes. The same guide says Concentration/Ingenuity *can* be used with Prospecting and Crushing, but does not prove that either modifies drop frequency per cast. Source: https://www.wowhead.com/guide/midnight/professions/jewelcrafting-specializations .
4. **Gear backward secondary stats:** Blizzard's Midnight content notes confirm secondary stats apply to previous expansions for the same profession; does not establish primary skill retroactivity or recipe-wide yield changes. Source: https://worldofwarcraft.blizzard.com/en-us/news/24244646 .
5. **Quality-rank changes:** Blizzard says stackable reagent/consumable qualities in Midnight were lowered to two. This does not license a universal rank-3-to-rank-2 remapping for old expansion products. Source: https://worldofwarcraft.blizzard.com/en-us/news/24244646 .
6. **Dragonflight crafting stats:** Blizzard's profession introduction identifies Resourcefulness as eligible-reagent savings, Multicraft as additional output on eligible recipes, Inspiration as bonus skill/quality. Not a universal multiplication of an ore's gem probabilities. Source: https://worldofwarcraft.blizzard.com/en-us/news/23876529 .
7. **2026 12.0.5 patch:** Blizzard documented reduced Deftness scaling for Dragonflight, Khaz Algar and Midnight. This is relevant to throughput/stats, *not direct gold per prospect*. Missing from v0.1 registry. Source: https://news.blizzard.com/en-us/article/24271855/12-0-5-content-update-notes .
8. **Event dating:** TWW prepatch was July 23, 2024; Midnight prepatch Jan 20, 2026; Dragonflight 10.0 phase 1 Oct 25, 2022. Current `dragonflight_profession_stat_system` date 2022-11-15 is explicitly approximate/unverified and should not be used as a numerical event boundary. Sources: https://news.blizzard.com/en-us/article/24115314/twiw-the-war-within-pre-expansion-season-of-discovery-phase-4-and-more ; https://worldofwarcraft.blizzard.com/en-us/news/24256617 ; https://news.blizzard.com/en-us/article/23859636/the-dragonflight-pre-expansion-patches-go-live-beginning-oct-25 .

## Output model and confidence tests

For one output per eligible operation: `p = successful_operations / completed_operations`; `E = total_units / completed_operations`; observed positive bounds are `min/max` among successful operations. When only aggregate counts are given, `E` may be estimable; `p` and positive bounds are **not identifiable** without a per-operation histogram or independent evidence.

Source condition includes: build/era, current Retail vs historical Classic, input/output ranks, item and recipe IDs, exact batch (including milling 10-herb operations), character skill/specialization, gear, optional reagents, applied concentration, known buff effects, actual observation denominators, and sample date relative to hotfix.

Separate confidence for each original field and for each numerical transform. A 95-confidence baseline with an unknown specialization correction does **not** imply a 95-confidence adjusted value.

## Model selection policy

```text
source observation with exact, documented context
   -> verify sample eligibility and patch window
   -> normalize units per operation (without altering source row)
   -> if source == target context: use sample directly
   -> else enumerate context differences and intervening patch events
       -> require applicable, independently verified transformation for EVERY
          material difference that could affect that output or reagent cost
       -> otherwise BLOCKED (no claim of current-Retail normalization)
   -> select condition-matched current evidence, or explicitly label fallback
   -> maintain raw field confidence separately from derived estimate confidence
   -> feed one selected data model to tooltip and conversion value
```

**Never mistake an unavailable transform for multiplier=1.** Do not “repair” bad TSM `amountOfMats` data by guessing a ratio from another expansion. Models changing eligibility or quality rank require discrete output-vector handling, not a scalar yield multiplier.

## Suggested regression fixtures

| Fixture | Expected result |
|---|---|
| Pre-April-1 Midnight ore sample -> post-April-1 Retail | `BLOCKED_UNKNOWN_PATCH_EFFECT` for gem rates |
| No node -> Copper Consumer node 1; diamond probability unknown | `BLOCKED_NO_QUANTIFIED_RULE`, **not** force diamond 0% in baseline |
| Midnight reagent equipment affecting Dragonflight of same profession | Secondary stats may apply; skill retroactivity *not inferred* |
| Raw 7 gems across 10 casts with no per-cast logs | `E=0.7`; `dropChance=null`; observed `yieldMin/Max=null` |
| Dragonflight Inspiration 20% vs Midnight Ingenuity 20% | `BLOCKED_DIFFERENT_STAT` |
| 10-herb milling report of 100 units over 10 operations | `E=10 per operation`; `E=1 per herb`; never divide by 5 |
| Known reference stats but unknown gear during source sample | `BLOCKED_MISSING_CONTEXT` for gear-sensitive correction |
| 95-score mean + 20-score adjustment formula | Transformed estimate confidence <=20, baseline field stays 95 |
| Verified resource savings vs output drop | Adjust input-consumption cost; unchanged per-cast output quantity absent evidence |
| Live newer GameData with distinct observed distributions vs old hardcoded overlay | Compiled GameData wins; no duplicate shipped mapping table |
| Verified Dragonflight secondary rank from reagent source ID | Distinguish **reagent quality rank** from item rarity and from crafting quality result |
| Two contradictory studies on same material but different skill/patch | Retain both as evidence; no naive pooling, investigate cohort matching |

## Recommended next action

**Do not replace the v0.1 registry in the agent's active branch blindly.** Review the accompanying typed schema prototype and regression cases. Once accepted, update the research agent's instructions to populate concrete recipe/specialization/gear/patch records under this contract. In the addon release, keep ONE static yield/mapping authority: `GameData.lua`; this research registry is build-time provenance, not another shipped table.

New work must prioritize actual numerical condition-paired studies and patch-matched experiments rather than a superficial count of named skills.
