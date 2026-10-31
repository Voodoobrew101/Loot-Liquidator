# Working estimates and the confidence target

This policy fills the four operational cells for every admitted mapping while retaining the research evidence exactly as it was. It applies to `research/tools/working_estimates.js`, policy version `working-estimate-policy-v1`. It does not change production addon files.

## Two completion measures

**Operational coverage** is the fraction of admitted, legal records with finite numeric `workingEstimate.dropChance`, `yieldMin`, `yieldMax`, and `expectedQuantity`. The target is 100%. Missing evidence is not a reason to leave the working layer blank.

**Evidence completion** is the fraction of required raw fields that meet the published evidence rubric. Raw nulls remain null, and the missing-field ledger remains an evidence backlog. Report raw completeness, operational completeness, and the number of fields at confidence >=90 separately. Newly populated working cells do not count as evidence progress.

The existing 0–100 confidence is an ordinal evidence grade. A grade of 90 is not a calculated 90% probability that an estimate is correct. The proposed >=90 gate requires traceable independent evidence, verified item/recipe/rank identity, a known zero-inclusive completed-operation denominator where needed, verified patch and character context, a validated numeric transform if normalization is used, and independent review. Statistical precision must also meet an agreed field-specific absolute or relative tolerance. Those tolerances must be configured and recorded before applying this gate; this policy does not silently invent them.

Where raw operation data support an interval, report the interval, its confidence/credible level, denominator, estimator, and assumptions separately from the evidence grade. Do not fabricate intervals from policy defaults or sample extrema. Distinguish confidence in a mean from variation in a single operation. A 90% interval for each field does not imply 90% simultaneous confidence across the entire database.

## Layer boundary and admission

The compiler admits legal mappings and quarantines known illegal identities, recipes, or rank combinations before calling this module. This module rejects malformed IDs, self mappings, invalid batch counts, and records explicitly marked illegal. Filling all legal records does not require retaining a known illegal mapping.

`applyWorkingEstimates(records, options)` adds only `record.workingEstimate`. It never writes the original field value, status, confidence, source claims, tooltip data, or conditions. `validateWorkingEstimates(records)` returns violations. Re-running with the same records and options produces the same working layer; no clock, random number, network request, or source-order selection is used.

All working estimates have `economicUse: PREVIEW_ONLY`, `normalizedVerified: false`, explicit source/target-context metadata, per-field confidence/status, and a list of assumptions. They are not a production economic input, an empirical finding, or a verified minimum-skill baseline. A future promotion needs the separate evidence and normalization gates. Existing source quantities are retained only as source-context preview quantities; this does not establish that their units or character contexts match the desired baseline.

## Deterministic fallback order

1. Copy coherent finite evidence values whose status is not contradictory. A retained contradictory number is unavailable for both copying and donor selection; its exclusion is recorded explicitly and any replacement has confidence 0. Copied admissible field confidence remains the original confidence.
2. Preserve a valid unconditional expectation when choosing missing probability or support. Expected quantity alone does not identify occurrence probability. The policy chooses positive support, derives a compatible probability, and labels the choice as an assumption with confidence 0.
3. If probability is available but expectation is missing, use the midpoint of the available positive bounds, or the single available bound, or one unit. The resulting expectation has confidence 0.
4. If probability and expectation are both absent, use the median of admissible expectations for the same output item, method, expansion, operation size, input quality, operation variant, and patch label. This transfer is an unvalidated prior for the new input, with donor record IDs and confidence 0. Contradictory, gross-input, and unresolved-rank expectations do not become donors.
5. With no comparable donor, use a plainly synthetic default: occurrence 0.5 at the midpoint of existing positive bounds, the single available bound, or one unit. This is a policy choice, not a claimed game probability. Confidence is 0.

The working values obey `0 <= P <= 1`, nonnegative E, and `P * min <= E <= P * max`. For a positive outcome, min/max are positive safe integers. The compiler may need to expand a provisional range or replace an inconsistent probability to preserve E; each changed working field has confidence 0 and a consistency-adjustment status. Its original evidence is untouched. An integer distribution on the chosen support can realize the conditional mean `E/P`; choosing that support does not establish measured extrema or the real output distribution.

If working P and E are zero, positive conditional yield is not applicable. The numeric min/max cells are then zero **sentinels**, accompanied by `conditionalYieldApplicable: false` and `zeroSemantics: WORKING_ZERO_EXPECTATION_NOT_PROVEN_IMPOSSIBLE`. These are not observations of positive yields of zero, and a historical zero proxy does not prove an output impossible. Unknown evidence remains a raw null and is distinguishable from this working case.

Any policy assumption makes overall working confidence 0. A copied field may keep its original confidence, but confidence cannot pass from a donor, a repeated source, or the arithmetic into an imputed field. New contradictory evidence and patch changes may lower confidence.

## Rank alternatives and context

An unresolved rank-specific E is not filled by copying the full family expectation to every rank. Prefer reviewed canonical family identity via `outputFamilyID`, `conditions.outputFamilyID`, or the optional `outputFamilyByItemID` lookup. Group allocation by that family and the full input-operation context.

If canonical family identity is unavailable, use one explicitly synthetic shared preview pool for unresolved rank records in the same input-operation context, marked `CANONICAL_FAMILY_UNKNOWN`. Its default total expected quantity is **one unit**, split uniformly across the unresolved members. The optional `unresolvedRankPoolExpectedQuantity` changes that explicit prior. This is a bookkeeping choice to avoid duplicate valuation of a family rate; it is neither an empirical family yield nor a physical upper bound. Pool membership, prior total, share, and `physicalUpperBound: false` are stored. Adding or removing a member can change the allocation and must remain visible in review.

This synthetic pool does not identify which ranks are possible, imply that all outputs in the pool are one real family, or recover omitted co-outputs. A reviewed canonical identity/context model replaces it when available. Independent output marginals are not enough to reconstruct co-output covariance; preserve shared operation IDs in future samples and adapters.

## Baseline normalization gate

Raw observations and character context remain immutable. Define and version the reference state, eligible recipe, skill, specialization, stats, patch, and operation size before inversion. A scalar inverse is permitted only after verifying the corresponding multiplicative mechanic and propagating its uncertainty. If skill changes quality selection, eligibility, thresholds, or co-output probabilities, use a conditional outcome model instead of a single multiplier. Missing context remains a blocker to verified normalization.

Validate a proposed transform by predicting original, unnormalized outcomes in held-out characters or sessions spanning the relevant settings. Do not validate a transform only against values it normalized itself. The current working module applies **no** numeric skill/stat inversion and asserts no verified normalization.

## Research cadence and the zero-delta pivot

Each cycle reports newly admitted legal mappings, newly numeric raw fields, changes in >=90 fields, validated transforms, and unresolved high-value blockers, separately from working-layer population. Preserve a stable record key and deduplicate claims with shared source ancestry.

After **two consecutive cycles with zero raw numeric-field improvements and zero confidence promotions for an assigned blocker**, stop repeating the same public-source search. Pivot that assignment to one concrete next action: obtain a zero-inclusive operation sample with full character context, resolve family/recipe identity, validate a shared transform, or document a source unavailable blocker and move to the next useful family. A pivot never grants new confidence by itself and never deletes the working estimate.

Sample work should prioritize expected reduction in valuation uncertainty per unit effort. Reuse validated mechanics across compatible families, count independent operations or sessions, and retain a joint operation ID for co-outputs. Choose sample sizes from the agreed precision tolerance and observed variance rather than a universal fixed sample count.
