# Numerical profession-mechanics research program implementation — 2026-10-28

**Scope:** research-only infrastructure completed at user request. This report does not represent discovery of a live WoW mechanics coefficient, creation of production itemdb.lua, or in-game validation.

## Changed artifacts
- `research/mechanics/NUMERIC_MODEL_RESEARCH_PROTOCOL.md`: falsifiable matched-cohort study requirements, independent QA, exact recipe/output/rank/patch gating, unsupported-formula blocking.
- `research/mechanics/numeric-rule-candidate.schema.json`: structured hypothesis provenance, precise applicability, context dependencies, parameters/units and blocked status.
- `research/mechanics/ProfessionMechanicsRegistry.json`: research program, disjoint hypotheses, empty `numericRuleCandidates` master-approved compiler source, release criteria. Existing qualitative `quantifiedMechanicRules` remain unchanged.
- `research/coordination/assignments.json` revision 5: separate mechanic hypothesis for each of Midnight, War Within, Dragonflight and Legacy; item record target IDs unaffected.
- `research/proposed/itemdb.schema.json`: optional `mechanicRules` section strictly limited to reviewed numeric rules. All existing processing fields and old candidate fixtures retained unchanged.
- `research/tools/compile_verified_mechanics.js`: deterministic future *staged research JSON* build from approved registry candidates only; rejects invalid claimed approvals; preserves baselines, tracks registry checksum; never generates production Lua.
- `research/tests/test_numeric_rules.js` and `research/tests/test_mechanics_compiler.js`: effect-specific numerical eligibility, negative tests, synthetic positive case, itemdb baseline preservation. Syntax/test exercise run in an isolated JavaScript harness with Node fs/assert/crypto compatibility stubs, not directly with the Node CLI.
- `research/prompts/ITEMDB_CREATION_PROMPT.md` v1.3 and `research/prompts/HOURLY_ITEMDB_RESEARCH_TASK.md`: mandatory parallel numerical research and master review.

## Existing hourly automations updated
All five saved task prompts (Master QA, Midnight, War Within, Dragonflight, Legacy) were updated to read the protocol and queue, investigate an independent mechanism hypothesis, report exact source and blockages, and require master QA before promotion. Their schedules were kept unchanged.

## Validation results and limitations
- `test_numeric_rules.js`: **28 passed, 0 failed** in isolated JavaScript harness.
- `test_mechanics_compiler.js`: **13 passed, 0 failed** in isolated JavaScript harness (crypto digest length checked with stub; run actual Node CLI later for full platform validation).
- Existing `test_itemdb_candidate.js`: **16 passed, 0 failed**, existing second-database runtime debt still correctly detected.
- Total: **57 static checks passed**. These are not WoW client tests; no real profession formula, batch-specific character adjustment, or current-Retail hotfix coefficient has been newly verified by this implementation.
- Registry numeric-rule approved count **0**; staged compiler's real output remains `mechanicRules: []` until independent evidence and tests pass.
- Existing `main/GameData.lua`, live TOC, conversion engine and `StatYieldProfiles.lua` are deliberately untouched; actual addon migration still requires user approval and regression/in-client smoke tests.

## Next hourly research deliverable
Workers investigate the hypotheses in `research/coordination/assignments.json#mechanicsTrack` **alongside** their original 25–50 record first-pass targets. Every result must be one independently sourced, controlled and reproducible candidate OR a precise BLOCKED finding with the next needed experiment. Master reviews acceptance, tests and next distinct assignment; no fake coefficients and no output-record count inflation.
