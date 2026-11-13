# Original Retail Recycling receipts: nominal/net input and shared-bag aggregation guard

Reviewed UTC: 2026-11-13T08:06Z  
Scope: `COORD-RECYCLE-RECEIPT-VS-BAG-20261113` (manager-owned source QA; research-only, not an added study or engine test).  
Frozen original data: main `b6610848604f68f8f3b40834397b79ce53eb8fb5`, Retail build `70783`, recorder revision `5`, capture version `3`. The exact observed operations and study IDs were archived earlier; this audit adds **zero** independent casts.

## Original sources

- [200 no-gear Recycling casts at measured Engineering skill 40](https://github.com/Voodoobrew101/Loot-Liquidator/blob/b6610848604f68f8f3b40834397b79ce53eb8fb5/research/integration/measured-captures/2026-11-07-recycling-40-skill-200-casts/export-page-1.json), [original intake](https://github.com/Voodoobrew101/Loot-Liquidator/blob/b6610848604f68f8f3b40834397b79ce53eb8fb5/research/integration/measured-captures/2026-11-07-recycling-40-skill-200-casts/intake-review.json), study `Voodoobrew - Grizzly Hills:70783:1794091861:24`.
- [200 geared Recycling casts at measured Engineering skill 80](https://github.com/Voodoobrew101/Loot-Liquidator/blob/b6610848604f68f8f3b40834397b79ce53eb8fb5/research/integration/measured-captures/2026-11-07-recycling-80-skill-200-casts/export-page-1.json), [original intake](https://github.com/Voodoobrew101/Loot-Liquidator/blob/b6610848604f68f8f3b40834397b79ce53eb8fb5/research/integration/measured-captures/2026-11-07-recycling-80-skill-200-casts/intake-review.json), study `Voodoobrew - Grizzly Hills:70783:1794104466:27`.
- [Existing source validator](https://github.com/Voodoobrew101/Loot-Liquidator/blob/b6610848604f68f8f3b40834397b79ce53eb8fb5/tools/validate_craft_export.py) already requires agreement of typed receipt, individual output, nominal inputs/refunds, group members and shared bag delta. This note does **not** allege the validator currently double-counts.

## Newly independently checked numeric field relationships

Read both original 200-record JSON pages in memory and recomputed from each distinct `operationID`, `recipeID`, `nominalInputs`, `inputs`, `outputs`, `resultMetadata.resourcesReturned` and `bagReconciliation`. This is an original-source arithmetic/reconciliation check; not a game replay, addon invocation or synthetic-price valuation.

| Field | Skill 40, no tools | Skill 80, geared |
| --- | ---: | ---: |
| Unique completed Recycling operations | 200 | 200 |
| Recipe ID / nominal batch | `1229930` / 5 × R1 Powder Pigment `245807` | same |
| Nominal pigment input | 1,000 | 1,000 |
| Explicit saved pigment units, verified against nominal minus net | 0 | **67** |
| Operations with nonzero resource-return receipt | 0 | **42** |
| Actual net pigment input | 1,000 | **933** |
| R1 Evercore `243581` units (typed receipts) | **388** | **396** |
| Per-operation output 1 / 2 / 3 histogram | 72 / 68 / 60 | 67 / 70 / 63 |
| Observed mean output units per completed operation | 388/200 = 1.94 | 396/200 = 1.98 |
| Distinct bag-reconciliation groups | **25** | **32** |
| Group-output total, counted **once per group** | 388 | 396 |
| Wrong total if each row's *repeated* bag delta is added | **3,934** | **3,254** |
| Nominal minus net equals individual `resourcesReturned` | **200/200** | **200/200** |
| Group size equals announced operations; grouped input and output deltas reconcile | **25/25 groups** | **32/32 groups** |

`bagReconciliation.outputs` are a repeated *group* inventory delta, **not a new per-record output**. Summing every row's shared group total would artificially create 3,934 or 3,254 units instead of 388 or 396. Recompute output from each unique operation's typed `outputs`/receipt, or add a shared bag delta **once** for reconciliation only. The existing validator explicitly accounts for shared group members; protect this on any future reference importer, alternate compiler, source blending or tooltip renderer.

**Output occurrence and refunds are different dimensions.** In the 80-skill original, the 42 positive-refund operations have output counts 13 × 1, 15 × 2, 14 × 3 (85 units); the other 158 operations have 54 × 1, 55 × 2, 49 × 3 (311 units). The observed `42/200` refund-event incidence is *not* an approved new Resourcefulness coefficient. Inputs consumed remain **5 nominal per operation** and **4.665 net per operation** in that exact 80-skill observed context; they are not to be treated as output probabilities or a generic recipe multiplier.

**Ingenuity false-positive safeguard:** Every one of the 200 skill-40 receipts contains numeric `ingenuityRefund=163` and every one of the 200 skill-80 receipts contains `ingenuityRefund=161`, **yet `hasIngenuityProc=false` and `concentrationSpent=0` in all 400**. Thus nonzero `ingenuityRefund` alone is **not evidence of an actual proc or reagent return** and must not be added to input savings, output quantities or EV. Actual reagent savings are recorded in `resourcesReturned` and reconciled against nominal minus net.

## Confidence, limitations and next handoff

The two original cohorts differ in bonus Engineering skill, gear and Resourcefulness (skill 40 has zero Resourcefulness; skill 80 has native 17.11111068725586%, gear and other stat changes). The 1.94 versus 1.98 outcome is **descriptive, not a causal skill/output quality or proc-calibration study**. Both cohorts yielded R1 Evercore, without proving R2 impossible. No unknown result, denominator, synthetic gold value, tool-tip visibility, universal game coefficient or new experiment is invented.

**Follow-up for the separate three-pass implementation owner or importer reviewer, not a manager branch edit:** whenever owner-measured salvages are admitted as a source, retain exact five-unit nominal input and per-receipt net input separately; de-duplicate shared `bagReconciliation.id`; disregard non-proc `ingenuityRefund`; require separate recipe/build/profile/quality context and preserve the source-only/review labels. Future independent controlled experiments would be required to identify skill or refund impacts. Workers' original numeric task queues are unchanged.

Validation performed: direct JSON parsing and in-memory arithmetic/uniqueness/group cross-checks of 400 archived records; source validator code inspected, **not executed**. No Lua, Python test suite, synthetic-price resolver/formatter, live-WoW verification, addon modifications, original-file changes, merge, release or new schedules.
