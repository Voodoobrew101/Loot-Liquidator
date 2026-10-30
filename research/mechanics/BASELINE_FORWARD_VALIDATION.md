# Reverse-to-baseline and forward-to-observation validation contract

**Status:** Research-only design and partial diagnostic implementation. Does NOT implement a learned profession-stat model or generate production `itemdb.lua`. Applies to `review/profession-mechanics-registry-v0.2`, which remains an unmerged proposal.

## Purpose

Use chronological original observations to infer ONE minimum-eligible, zero-optional-bonus baseline for each real item/input/output/recipe/quality/target-patch combination. Validate the inferred baseline by **forward** application of historically applicable profession mechanics back to independent original study conditions. Agreement is an *out-of-sample consistency check*, not proof merely because the same data can be reconstructed.

## Modeling loop

1. **Source preservation and mechanic epochs:** Keep original casts, materials, histograms, skill/rank/gear/patch context and publication-date clues immutable. Assign historical epoch from actual game time or independently reviewed original-study context, never publication date alone. Source cohorts crossing incompatible or unknown numerical patch events stay separate until a supported bridge exists.
2. **Study grouping / clustering:** Group exact item/output/rank/recipe/batch/patch/mode first; compare independent samples with the same known skill/bonus context. Identify likely shared profession mechanic *families* only where evidence justifies borrowing. Preserve individual authors/studies, original dataset ancestry and unknown covariates. Grouping is exploratory; it is not proof that recipes share rates.
3. **Inference of unskilled anchor:** Use direct minimum-eligible no-bonus studies when available. Otherwise infer a neutral anchor using reviewed, invertible field-specific effects, or clearly labelled provisional statistically fitted estimates. Unknown zero is not verified zero. Where effects are additive, thresholded or eligibility/quality-specific, do not try to divide by a multiplier or infer an unlocked rank. Score the resulting four database cells independently.
4. **Fit candidate effect models:** Compare additive, multiplicative, step/unlock, rank-transition, and nonlinear regression where mathematically and biologically/game-mechanically applicable. Use per-cast sample weights/actual precision; include model and context uncertainty. Hierarchical/partial pooling can learn **shared bonuses** across items, without forcing identical base chances. Bayesian posteriors can represent parameter uncertainty and competing model structures; priors/likelihoods and training cohorts must be documented. Do not substitute a heuristic fixed multiplier for observed game behavior.
5. **Forward-check from the neutral baseline:** For each original **held-out** study, select the rules effective **at the study time**, apply its measured skill/spec/gear/stats and exact recipe/rank, predict four metrics where the model truly supports them, then compare to the *unmodified observed data*. Note that post-current patch target extrapolation is a separate step. Keep expected input consumption and operation time separate from output yield.
6. **Cross-validation and posterior-predictive checks:** Hold out **whole primary datasets**, not random individual casts when study/author/session leakage would compromise independence; use leave-one-original-study-out or out-of-time holdout, respecting patch. Compare observed and predicted occurrence probabilities (binomial or beta-binomial predictive, under documented assumptions), expected quantities (mean residuals and variance only when per-cast data support it), and **positive conditional ranges** (sample extrema are not universal hard bounds). If four-field values imply inconsistent `p * conditional mean = E`, investigate; don't force an incompatible tuple to match. A model's own in-sample goodness of fit or fitted posterior alone is NOT independent validation.
7. **Model revision / research feedback:** Flag systematic residuals by skill, spec, node, patch, item, and output rank. Ask whether the difference is measurement noise, confounder, bad patch timing, effect misspecification, source mapping or missing output. Delegate the smallest concrete high-value unanswered question to the expansion worker. Model revisions and changed candidate fields must carry source and registry version hashes, training/test dataset ancestry, field confidence, and explicit QA status.
8. **Release boundary:** A good fit to held-out data supports the candidate but does **not** establish a causal profession mechanic or justify shipping an unverified numeric rule. Master may maintain below-90 provisional baseline candidates. Numeric runtime rules require exact reviewed mechanic applicability and separate release approval.

## Four-field checks and limits

| Target field | Infer / predict | Independent check | When unsupported |
| --- | --- | --- | --- |
| `dropChance` | Probability from hit-and-zero events; bounded by 0 and 1 | Held-out hit counts, binomial residual or beta-binomial predictive check with TRAINING-only posterior | Unknown rather than assuming 0 or equating E to probability |
| `expectedQuantity` | Unconditional units per operation, zero-inclusive | Held-out output totals/actual casts and model residual; uncertainty from full cast histogram when available | Preserve reported mean; never manufacture variance or multiply by chance again |
| `yieldMin` | Conditional positive count support | Check only actual positive cast observations; independently documented hard minimum may reject impossible samples | Observed sample minimum is descriptive, not the game's proven lower limit |
| `yieldMax` | Conditional positive count support | Check independent observed positive extremes; a verified hard maximum is falsified if exceeded | Observed sample maximum is descriptive, not proven upper limit |

**Zero-baseline rule:** A proven absent output in a baseline may become available only under a separately documented additive/proc/unlock or threshold mechanic. A zero *observed* count from a finite number of casts is not proof of structural impossibility.

## Available diagnostic prototype

`research/tools/validate_forward_predictions.js` accepts a JSON document with `researchOnly:true`, `modelRevision`, `registryRevision`, and `evaluations`. Each evaluation supplies an **externally computed** candidate prediction (the current registry has no verified numeric coefficients), independent study/dataset ancestry, exact recipe/patch matching claims, and original observed hit/total count/histogram.

The script flags incompatible context, training/holdout leakage, missing hit counts, inconsistent four-field predictions, very large probability/mean residuals, and verified hard-bound violations. Optional `prediction.trainingPosteriorForDropChance:{alpha,beta}`, where parameters come only from disjoint training observations, supports an analytic beta-binomial posterior-predictive z diagnostic. It does **not** fit Bayesian models, run a full posterior sampler, estimate coefficients, or promote current-Retail rules. A matched holdout is labelled `HOLDOUT_CONSISTENT_NOT_PROOF`, not verified correctness.

Synthetic tests are in `research/tests/test_forward_validation.js`. For implementation in an actual `itemdb.lua` build, the missing steps are a deterministic **registry interpreter for real effect formulas**, archived source cohort independence bookkeeping, unskilled inverse-model fitting, independent holdout allocation, candidate compiler and current-WoW tests. The present standalone checker intentionally cannot claim those jobs have been completed.

## Master agent requirement

On each cycle, master must recalculate or at least audit forward-validation results for all *affected* candidate fields using the latest versioned evidence and mechanically relevant epochs. Compare exact out-of-sample residuals before increasing confidence. Record changes, failures and missing formula/test support; prioritize higher expected liquidation impact and shared-rules affecting many cells. Keep production `main` untouched.
