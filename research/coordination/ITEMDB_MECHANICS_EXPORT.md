# ItemDB mechanics export

The normal ItemDB compiler now reads the reviewed ProfessionMechanicsRegistry.json on every build. Its SHA-256 and accepted rule count are embedded in sourceManifest. mechanicRules in generated itemdb.lua contain the reviewed scoped rules; they are not an optional manually copied sidecar.

The runtime builder consumes this collection from its pinned ItemDB. It binds every rule to compatible concrete input/recipe/batch/rank/output baseline rows, preserving the generated reference context identity. Unmatched approved rules fail the build. Research approval is translated to runtime EXECUTE only after validation; source observations remain unchanged.

Supported initial instructions: RATIO_ADJUSTMENT for unconditional expectation and RATIO_ADJUSTMENT_OCCURRENCE for occurrence. The multiplier is targetFactor/referenceFactor. All other approved formulas fail explicitly until their runtime semantics are implemented. Non-approved research hypotheses remain excluded.

Both referenceContext.build and targetContext.build must be explicit. A patch window is not interpreted as a source/target transformation. Required live fields must have exact target values. Reference context must match the baseline's recorded conditions. This version represents scoped conditions rather than an invented continuous skill curve; additional target profiles need their own verified instructions.

No coefficients are invented: the current registry exports zero executable rules, so ordinary yields remain unchanged. Synthetic tests prove export, translation, multi-output character adjustment and rejection paths. Actual patch/skill correctness still requires independent evidence and in-game validation.

Commands: node research/tools/run_completion_pipeline.js --check (research); bash tests/run.sh (runtime). Install Node, Python jsonschema and Lua 5.1 first.
