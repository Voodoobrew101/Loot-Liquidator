# Five-agent execution runbook

The canonical functional queue is `research/coordination/five-agent-workflow.json` on `implementation/five-agent-completion`. Legacy expansion assignments remain preserved in `research/coordination/assignments.json`; their current frozen reference is queue30, not queue29. Existing schedules are retained.

| Existing automation | Functional role | Role prompt |
|---|---|---|
| Master | Coordinator/integrator | `coordinator.md` |
| Midnight | Completion/compiler engineer | `completion-engineer.md` |
| War Within | Baseline/mechanics modeller | `baseline-modeller.md` |
| Dragonflight | Targeted evidence researcher | `evidence-researcher.md` |
| Legacy | Independent validator | `independent-validator.md` |

Every automation reads `common.md`, its role prompt and the latest functional queue, then performs the highest-priority ready work. Prompt text for updating the five existing automations is in `automation-prompts.json`; do not create five duplicate schedules.

Read the current generated `research/coordination/completion-readiness.json` and `completion-priorities.json` for actual counts and next E/model risks. The initial 1,015 mappings / 511 evidence gaps are historical reference counters. Changed source selection or quarantines may increase evidence gaps while working coverage remains complete; report that change honestly. Initial tasks bootstrap the workflow; all roles continue with new ready tasks after those are accepted.

From the repository root, build and run required checks with `node research/tools/run_completion_pipeline.js`. Verify that committed artifacts match the inputs with `node research/tools/run_completion_pipeline.js --check`. Decode and check the generated candidate with `lua5.1 research/tests/test_generated_working_estimates.lua` when Lua 5.1 is available; state when unavailable. These checks do not establish in-game behavior.

Initial sequence: engineer produces the complete isolated preview; modeller and researcher work in parallel on prioritized E families/eligibility; validator independently checks changed artifacts; coordinator accepts results and publishes a single current scorecard. Evidence collection does not block confidence-0 preview completion. Validation failure blocks promotion/economic activation, not retention of honestly labelled research estimates.

Success gate A is 100% numeric working fields for the admitted valid mapping universe, with no evidence loss or economic leakage. Gate B is independently reviewed evidence strength at least 90 in every required field/context for the declared scope. Report both. Do not claim exhaustive Retail coverage until the separate universe audit closes. Do not change production or existing runtime behavior as part of this workflow.
