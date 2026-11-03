# Shared operating contract: complete first, improve evidence continuously

Work in `Voodoobrew101/Loot-Liquidator`, branch `implementation/five-agent-completion`. Read this contract, your role file, and `research/coordination/five-agent-workflow.json` at the current branch head before each run. The baseline snapshot is `3bf3cf102c95b29e8a4f128069ea718fc618b689`; do not reset a newer branch to that snapshot. The runtime integration dependency is `implementation/five-agent-runtime-profiles`; inspect it as needed, but this workflow does not authorize production migration or edits to that branch.

## Objective and boundaries

Make the working `itemdb.lua` candidate numerically complete for **every admitted legitimate input/output/recipe/rank/context mapping**, then raise independently reviewed field evidence toward 90. A complete numeric preview is not a verified game mechanic or a confidence claim. Never fill missing item IDs, recipes, ranks or eligibility by inventing mappings. Keep unresolved universe candidates in a separate mapping backlog.

Preserve the evidence layer, historical ledgers, raw observations and current `research/coordination/assignments.json`. The latter remains the legacy expansion queue and is not this workflow's assignment authority. Do not change production `main`, addon load order, distributed ZIPs or live value/recommendation paths. Preserve the frozen historical TSM tables, their original units and source lineage. Historical TSM may inform an explicitly labelled prior; it cannot become measured current-patch evidence by copying, renaming or increasing confidence.

Maintain three separate channels:

1. **Evidence:** source facts with honest nulls, actual sample context, independent lineage, per-field provenance and uncertainty.
2. **Working estimates:** all four numeric values (`dropChance`, positive conditional `yieldMin`, positive conditional `yieldMax`, unconditional `expectedQuantity`) for admitted mappings, including explicitly imputed fallback estimates with confidence 0. Keep status, method, parent evidence/model IDs and sensitivity. Modelled min/max are working bounds, never asserted hard game bounds without evidence.
3. **Economic use:** only fields passing the existing independently reviewed applicability and economic gates. Every new imputed/working fallback is `economicUse="PREVIEW_ONLY"`, `normalizedVerified=false`. Complete storage must not silently replace live EV, recommend an action, satisfy eligibility or overwrite a stronger evidence field. Preserve the separate tooltip-only fallback channel and its prohibitions; do not derive E from tooltip quantities or multiply an unconditional E by P.

## Shared identity, context and units

Use one typed, versioned context shared by candidate generation and forward/inverse models: game mode, target build/patch epoch, expansion, method, recipe/operation variant, input/output IDs and quality ranks, nominal input batch, full direct reagent vector, minimum recipe-eligible skill, optional skill/spec/gear bonuses, relevant profession stats and their units, unlocks, source study/lineage and actual observation epoch. Unknown is an explicit value, not zero or “same as current”. Distinguish a reference baseline with zero **optional** bonuses from zero profession skill or an impossible recipe.

Keep actual completed casts separate from nominal/gross-input equivalents; record saved/refunded reagents separately. Use zero-inclusive per-cast totals for E and success casts/actual casts for P when directly measured. Preserve co-output and rank dependence. Do not force marginal multi-output probabilities to sum to 1; only an evidenced exclusive exhaustive partition has that invariant. Enforce P in [0,1], nonnegative E, ordered positive bounds when P>0, and `P*min <= E <= P*max` for a common supported conditional model. A zero-output baseline requires P=E=0 with an explicit not-applicable conditional-range convention, not a fabricated positive minimum.

## Confidence and promotion

Confidence is a documented 0–100 evidence-strength score, not the probability of a drop or a claim of 90% statistical accuracy. Track measurement intervals, mapping/context applicability, model/transform uncertainty and held-out validation separately. A record clears the 90 gate only when every required field and its mapping/context pass the documented independent rubric; an average cannot hide a weak field. Fallback completion receives confidence 0. Do not raise scores because a value is now numeric, a source is prestigious, many derivative pages agree or an in-sample fit looks good.

Preserve unknown study skill/stats and plausible alternatives. Invert only identifiable, independently supported mechanics. Otherwise use labelled partial pooling/sensitivity ranges or a latent-context hypothesis with uncertainty. Validate on whole independent study families excluded from estimation; never infer a study's hidden context and count that study as independent validation of the same model.

## How to work each run

Perform the highest-priority ready task assigned to your role in the v2 workflow. Produce a concrete artifact/code/evidence/QA change and run the relevant available checks; do not spend the run rewriting plans or re-auditing unchanged rows. Claim a task using a unique role-owned run record, not by editing another agent's files. Inspect current head before writing and preserve concurrent commits. Never reset, force-push, overwrite another role's files or silently adopt an unreviewed mechanics branch.

Initial tasks are bootstrap work. Once accepted, continue with the latest ready tasks, newly changed inputs and unresolved model/validation risks. The canonical generated counters and priority backlog are `research/coordination/completion-readiness.json` and `completion-priorities.json`. Run `node research/tools/run_completion_pipeline.js` after accepted build inputs change and `node research/tools/run_completion_pipeline.js --check` to detect stale generated artifacts. Use `lua5.1 research/tests/test_generated_working_estimates.lua` for generated-file decoding when available; report unavailable checks honestly.

Submit a unique run report under `research/coordination/v2/submissions/<role>/<UTC-timestamp>-<task-id>.json` containing task/queue revision, base/result commit, exact keys/files changed, accepted-versus-proposed status, numeric cells filled, new E cells, invalid mappings removed, confidence promotions, independent study lineages, tests actually run, runtime/Lua/client tests not run, blockers, and one next task. Submit immutable evidence/model proposals; the coordinator alone accepts central queue and scorecard changes.

The starting snapshot had 116 missing E cells and 511 numeric evidence gaps. Read the current `research/coordination/completion-readiness.json` and `completion-priorities.json` each run; prioritize their remaining E/model risks while keeping the working preview complete. These reference counts are not fixed quotas. Rank subsequent research by likely reduction of decision/value error and number of dependent rows, not raw reviewed-key counts. A model-family repair may be more useful than another individual source audit.

After two consecutive role cycles with zero new usable evidence, zero corrected mappings, zero populated preview cells and zero reduced model uncertainty for a source/approach, mark that approach exhausted and pivot to a different ready engineering/model/measurement task. Do not repeat the same search under new item IDs without a new source lead. Report a genuine blocker once with exact prerequisites; never manufacture a result to meet a quota.

Changes are research-only. Complete authorized candidate, model and validation work without asking again. Any proposed production migration must remain a concrete reviewable diff with outstanding in-game verification stated.
