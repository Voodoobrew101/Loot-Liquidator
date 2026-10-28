# Recover missing study context from historically calibrated mechanics

**Status:** Research-only latent-context inference specification, 2026-10-28. No production addon modifications. Current registry v0.2 proposal has **zero verified executable numerical correction rules**. The companion script ranks supplied hypothetical/externally calibrated predictions; it does not learn real WoW parameters from scratch.

## The user's proposed inverse question

Given an immutable study containing real processing operations, outcome frequencies, actual item/recipe/rank, publication and partial skill/bonus clues, estimate **which historically valid profession profile probably produced these outcomes**. Missing variables include effective/base profession skill, applicable specialization node ranks, tool/accessory stats, and patch/mechanics epoch. Infer probabilities over configurations, not a categorical guess; identify unresolvable alternatives.

This is the inversion of the forward validator. The research engine must eventually support both directions:

- `FORWARD: neutral itemdb baseline + historically scoped mechanics(profile, patch) -> output-count distribution`.
- `INVERSE: observed independent output-count distribution + constrained forward models + dates/documentary clues -> posterior over candidate profiles/epochs`.

## Required evidence and constraints

1. **Immutable original data:** Actual completed casts, per-cast zero-inclusive counts (prefer joint multi-output logs), input/output item IDs and rank, source/study/dataset lineage, game mode, historical build when known. Aggregate `totalUnits/n` is useful for baseline expectedQuantity but *cannot* alone define a categorical hit/count likelihood; require an independently justified aggregate model if using it.
2. **Historical plausibility:** Enumerate ONLY profiles legal under the actual recipe/item/expansion, stat system, specialization unlocks and game patch. A 2026 publication is at most an upper bound; it is not proof casts were post-hotfix. A sample published **before** a rule's release excludes that new rule. Use actual cast dates/builds and independently reviewed study wording first. A model can infer an epoch or range of patches; generally **not an exact day** within the same mechanic regime.
3. **Mechanics fidelity:** Candidate output distributions must come from previously calibrated, reviewed mechanic functions or clearly identified provisional hypotheses. Invert eligibility and output quality correctly. Do not multiply zero to create a new output or assume no proc where not observed. The registry tracks historically changing effects; a model calibrated only on 2026 Retail may not be applied to a 2023 cohort unchanged.
4. **Comparison:** For a single output, compare cast-level counts with the candidate's full probability mass `P(count = k | profile, epoch)` using a multinomial likelihood. Hit-count-only studies can contribute a binomial likelihood. If multiple output types are jointly observed from the *same* casts, use a **joint** distribution or explicit verified dependence model; naively multiplying their marginal likelihoods double-counts correlated evidence. Include sampling noise, independent source uncertainty and model-parameter uncertainty in a full future hierarchical Bayesian implementation.
5. **Priors:** Prior weights derive only from source-independent factors (real character/profile prevalence only if evidenced, recipe requirements, documented publication bounds, available patch interval). Always record their provenance and sensitivity. When no external prevalence information exists, an explicitly artificial uniform *per specified candidate* prior may support exploration but cannot justify real-world probabilities; candidate-grid density can distort results. Neither use the unknown study outcomes to tune candidate priors nor reuse them in the model's training set before calling posterior calibration independent.
6. **Identifiability:** Two skills, specializations, bonuses or patches can generate indistinguishable output distributions. Report an equivalence class or credible set, with observed statistical support. If candidate profiles all predict the same distribution, the study supplies **no likelihood information** for differentiating them. Higher sample size cannot resolve structural non-identifiability. For a patch where no numerical bridge is calibrated, report competing scenarios and do not assert precise post/pre confidence.
7. **Guard against circular validation:** An observation used to assign an inferred profile or train a mechanic coefficient cannot independently validate that assignment or coefficient. For QA, leave entire original dataset/study families out of training and compare their posterior-predictive outcomes independently. A latent-profile inference from the SAME study's yields is model explanation, not independent verification of the game mechanics.
8. **Master review:** Save derived context attribution as a **separate versioned record** (never overwrite raw source statements) with candidate profiles, posterior conditional on known assumptions, model/registry versions, uncertainty, discarded candidates, source/patch clues, and missing covariates. Keep direct historical fact separate from model-inferred context. A high-probability inferred profile may inform a *provisional* baseline model where justified, but is never automatically treated as measured skill, confirmed game build or a verified numeric rule.

## Current research-only prototype

`research/tools/infer_latent_study_context.js` takes one observation and an explicit list of complete profile hypotheses with calibrated `predictedOutputCountDistribution`, prior weights and known time bounds. It computes a normalized posterior using the zero-inclusive per-cast histogram or hit count; it refuses to infer a likelihood from only aggregate units. It identifies identical candidate distributions and training-study overlap, and filters scenarios impossible given the publication upper bound or an independently reviewed allowed epoch. The script does **NOT** generate candidate profiles, learn regression coefficients, validate claims of the candidate model's status, infer an exact cast date, or implement a full Bayesian model over uncertain parameters.

Execute synthetic regression checks with:

```bash
node research/tests/test_latent_study_context.js
```

The tool's quantitative output is **conditional on explicitly supplied hypotheses, prior weighting and predicted distributions**. It cannot claim to have discovered an author's actual skill, build or bonus configuration. Real-data integration requires a fully versioned mechanics model, defensible candidate profile enumerator, source/context labels and one-step generation of prediction distributions, posterior model comparison/holdouts, and feedback to the master research assignments.

## Feedback into `itemdb.lua` research

Master QA should prioritize studying which unknown variable would most reduce ambiguity between plausible profiles. For instance, a documented threshold unlock can distinguish spec rank zero from positive, while pure effective-skill and profession tool bonuses may be confounded unless other item/quality outcomes separate them. Run source text investigation first, then inverse inference, then forward residual analysis, then request specific missing corroboration. Below-90 confidence provisional baselines remain allowed; source historical time/bonus guesses must be marked as **model-inferred, not witnessed**.

## Synthetic scenario (numbers illustrative, not WoW data)

A 200-cast study with 100 hits is compared with two independently calibrated candidate profiles, one predicting 20% hits and the other 50%. Its likelihood favors the 50% hypothesis, but this does not establish that the character's actual skill/stat/patch was the second hypothesis: unlisted profiles, model error and prior assumptions could explain the same outcome. If two profiles both predict 50%, the observed casts provide no evidence distinguishing them.
