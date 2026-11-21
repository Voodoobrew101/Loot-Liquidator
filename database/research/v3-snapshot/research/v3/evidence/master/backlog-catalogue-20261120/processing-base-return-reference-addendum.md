# Mycobloom base-return comment: scoped scientific correction

2026-11-20. This addendum corrects the current numerical admission of exactly two processing proposals; original observations, `processing-review.json`, `processing-proposals.json` and `processing-notes.md` remain unchanged.

The preserved rows `war-within-20261101-2108` and `war-within-20261101-2109`, lines 8 and 9 of `research/v3/evidence/war-within/2026-11-01T2123-milling-skill-ranges-and-pooled-herb-studies.jsonl`, quote a comment in [the original milling discussion](https://www.reddit.com/r/woweconomy/comments/1fdmzwy): “without accounting for resourcefulness the base returns are 1.1 and 1.3”. These are purported base pigment units per herb for Mycobloom 210796 and 210797, respectively. They are `sourceKind: reference`; their original notes explicitly distinguish them from the firsthand 1.15/1.35 averages and forbid combining them as additional measured samples.

The previous current model interpretation was too broad: an assumed neutral source profile and a nominal-stock-budget label allowed the base-return comment to blend with firsthand means whose Resourcefulness/refund and input accounting were not established as matching. Zero active sample count alone does not make those contexts comparable. Neither the difference between the two reports nor the quoted rounded values proves an inverse Resourcefulness coefficient, independent additional measurements, or a changed game formula.

## Corrected current-use decision

- Remove only active models `evidence:reviewed-backlog:processing:c2b2c05229d5849e9ee4fede` and `evidence:reviewed-backlog:processing:e39f01734856de5e672e835e`.
- Preserve the source quantities as two `sourceProfileMeanUnitsPerInput` informational facts: 1.1 and 1.3 units per input, Resourcefulness explicitly excluded from the quoted base reference. Their 11/13 units per native ten inputs are unit-conversion metadata, not observations of ten-input operations.
- Retain exact physical/corrected row hashes and original quote, notes, publication context and provenance. Underlying casts, material totals, processed-input budget, skill and allocation remain unknown. Current modeling confidence is 0; no observation count, probability, zero-bin or refund rate is invented.
- Do not add these references as independent evidence weight to the firsthand cohorts, normalize them as a measured zero-skill profile, or transfer their output to gold valuation. The actual source-fact query and recommendation tooltip may display their source-profile base references under normal ItemDB source controls.

Only the two affected proposal dispositions change from numerical model admission to `SOURCE_FACT`. Every other processing admission and raw receipt remains intact. The curator implements this by exact original record ID, item IDs, source kind, source study key, source mean and quote guards.

Reopen numerical comparability only when a primary clarification establishes matching gross/net input, Resourcefulness and character-profile conditions. A claim of an additional measured cohort also needs its own original quantity/denominator evidence. This does not require discarding the already supported firsthand means or relabeling them as an RF-neutral observation.

## Verification

The bounded base-reference correction, before the separate translation of older source-fact schemas, yielded 623 models and 1,129 facts, with all 3,181 proposal dispositions retained. A semantic comparison against the pre-correction derived policy found exactly the two removed models, two added facts, and two changed dispositions; all other models, facts, proposal definitions, row-field decisions and the source-field exclusion were unchanged. All 623 remaining models passed actual Lua 5.1 source inverse/forward, immutable-input and replay checks.

Both new facts passed the actual `Database.lua`/`Observations.lua` source policies, `ReviewedProcessingSourceFacts` query and `AppendRecommendationTooltip` renderer: per-gross-input units, explicit Resourcefulness exclusion and Confidence 0% survived; disabled ItemDB, zero ItemDB weight and personal-only mode suppressed them. Rendering added no availability, action, priced material or value. These focused checks do not claim a full compiled database, installed addon or live-game validation; the integrating owner performs those final gates.
