# Imported confidence semantics

## Scope and reproduced defect

Main `b6610848604f68f8f3b40834397b79ce53eb8fb5` computes imported drop-rate
confidence using a normal approximation to the probability of a rate being
within five percentage points. `ImportedEvidenceRecords` copied that number
into occurrence, mean quantity and observed minimum/maximum fields. Those are
different estimands: occurrence precision does not establish quantity precision.
The saved import aggregates contain casts, hit counts, totals and extrema,
not a complete quantity distribution or independent calibration outcomes.

The quantity field's score enters `EvidenceReliability`, anchor selection,
weighted means, per-material confidence and `ValueProcessingModel`'s
value-weighted score. The option tooltip and optional material rows previously
printed those scores as confidence percentages. Token reward disenchant quotes
also copied the model's numeric confidence. None of these calculations measures
the probability that a recommendation beats its alternatives.

## Bounded compatibility repair

Imported mean and bounds retain their values, observed status and sample counts.
Their statistical confidence is absent, explicitly `confidenceUnscored`; the
previous ordinal selection weight is retained as `evidenceScore`. Occurrence
keeps its existing approximate score and identifies its five-point basis.
No formula, coefficient, source preference, baseline or yield is changed.

The evidence engine reads the separate score for existing selection and
weighting. Only an accepted expected-quantity contribution marks its material
and model unscored. Disabled, incompatible, duplicate or unused imported
records do not mark a model merely by being present. Existing internal numeric
model/material/value scores remain compatibility heuristics, not calibrated
probabilities. Option APIs return `unknown` confidence for unscored models;
tooltips explicitly show unscored confidence, and token DE quotes omit the
unsupported number. Prices, estimated values and ordering remain available.
This does not redefine confidence for unrelated sources or validate their scores.

## Verification and limits

`tests/test_imported_results.lua` reproduces the actual import-to-model-to-price
and tooltip path. It checks unknown is absent rather than zero, retained
occurrence semantics, and numeric equivalence against the old field contract
for imported-only and mixed personal evidence, stale sources and three source
weights. Disabled imports leave the other model's confidence unchanged.
These synthetic fixtures are regression tests, not empirical evidence.

Empirical calibration still needs compatible independent cohorts with legitimate
operation denominators, quantity-distribution uncertainty and held-out outcome
checks. Recommendation-win confidence additionally needs joint output and price
uncertainty plus an explicit comparison/horizon contract. Existing overlapping
captures or synthetic/bootstrap repetitions cannot establish that calibration.
No new capture is requested, no rate promoted, and no release or live-game QA
is claimed. PR #51 salvage identity and PR #54 held disenchant context are
separate safeguards and remain unchanged.
