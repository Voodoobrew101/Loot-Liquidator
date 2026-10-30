# Immutable observations, chronological mechanics, and repeatable ItemDB builds

**Status:** Research-only proposal on `review/profession-mechanics-registry-v0.2`. No current addon Lua, production itemdb, or verified formula has been modified. This branch is not yet merged into `research/processing-confidence`.

## Core principle

A raw community study or in-game observation is an immutable measurement: item IDs, observed outcomes, cast count, input/output rank, profession configuration, author/source ID, and **when processing happened**. A mechanics-rule revision is a different record containing what was learned about behavior **during that historical gameplay interval**. The current registry is a *knowledge snapshot*, not a retroactive rewrite of the past.

Keep three independent temporal axes:

| Clock | Meaning | Why retained |
| --- | --- | --- |
| Gameplay observation date / [start,end] | When processing occurred; also capture game mode/build/hotfix if known | Chooses the historically applicable rules |
| Original publication date | When the original report first became public, not a processing timestamp | **Upper bound** on sample date if actual observation dates are missing |
| Registry revision / QA approval date | When a historical rule or date correction was learned | Enables deterministic as-of-knowledge reproductions |

**Never** use `retrievedDate` as a sample timestamp. Never assume a study published after a patch was measured after that patch. A publication before the patch does support placing a pre-patch sample (if genuine original first publication). If the only available time is a year/month, preserve that coarse precision; do not manufacture the first day of the period as a known observation date. Only date-scoped classifications are currently supported by the prototype; more precise as-of-build/time resolution is future work.

## Storage and evidence preservation

Raw source data belongs in the existing `research/evidence/observations/*.jsonl`. The additive `research/evidence/observation.schema.json` update on the active research branch adds `observationTiming`, `source.publishedDate`, and precision/source provenance fields. Existing raw JSONL records remain valid and should not be mass-rewritten just to add approximate timestamps. When more precise dating is discovered, append a linked temporal attribution/correction event or auditable derived overlay; preserve the original source report.

Every observation's source, cohort ID, sample context, original yields/histograms and publication should be preserved. Provenance scores and derived target-era confidence are **not** to be stored as replacements for raw observations.

## Versioned mechanics changes

Store historically effective patch/mechanic events in `research/mechanics/mechanics-chronology.json` with exact scope, active revision, source claim IDs, date/build precision, affected fields, coefficient status and revision history. The official March 31, 2026 Midnight prospecting change is the first recorded event; an earlier April 1 misdate is retained in its correction history.

When credible later research supplies a new exact patch timestamp, skill rule, formula or counterexample:

1. Append evidence and a **new rule/event revision**, with old revision preserved in history.
2. Independently QA scope, sample ancestry and chronology; never promote unreviewed mathematical effects.
3. On next proposed `itemdb.lua` rebuild, run the archived raw observations through the then-current audited mechanics timeline.
4. Partition source cohorts by their historical rule era; mark boundary-day, cross-patch, and publication-only ambiguous samples explicitly.
5. Recalculate impacted per-field unskilled baseline candidates, reference-profession adjustments and confidence. Retain original sample counts and outputs, as well as the rule revision, evidence fingerprints, selected model and assumptions.
6. Validate against holdout cohorts and target Retail patch. Stage results for human/master QA; only separately reviewed and proven formulas may be shipped.

**No numeric effect is assumed to be 1.0 just because a coefficient was not found.** A useful, below-90 provisional baseline may still be proposed, but cannot silently be passed off as a proven neutral-baseline inversion.

## Prototype commands (run from a checkout containing the full research observations)

```bash
node research/tests/test_mechanics_chronology.js
node research/tests/test_observation_reprocessing.js
node research/tools/resolve_mechanics_epoch.js research/mechanics/mechanics-chronology.json
node research/tools/reprocess_observation_archive.js \
  research/evidence/observations \
  research/mechanics/mechanics-chronology.json \
  research/proposed/reprocessed-observations.json \
  research/mechanics/verified-item-family-map.json \
  research/mechanics/ProfessionMechanicsRegistry-v0.2-PROPOSAL.json
```

The fourth argument (verified family map) and fifth argument (registry snapshot) are optional. If family mapping is missing, the classifier returns `UNKNOWN_SCOPE` instead of fabricating gem/ore identity. The family map must be a verified JSON object such as `{"inputs":{"<known item ID>":"MIDNIGHT_ORE"},"outputs":{"<known output item ID>":"GEM"}}`; this is an illustration of schema keys, not an assertion that any item ID is valid.

The derived JSON preserves source file SHA-256 fingerprints, chronology hash, optional registry snapshot hash/version, observation timing provenance, historical epoch classifications, source item/recipe/profession context, and unmodified source-derived reported mean/chance data. **It is not a generated `itemdb.lua` and it does not execute numeric mechanics.** No automatic promotion occurs. The downstream deterministic four-field model/inverse-normalization compiler and verified current-Retail adapter still need implementation.

## QA invariants

- Never merge independent samples with different verified mechanic epochs unless a validated bridge explicitly supports it.
- Missing sample time is unknown; publication-only time is a one-sided bound, not a point observation.
- A release-date patch entry cannot retroactively be treated as proof of a specific bonus coefficient.
- The same raw study + same pinned timeline/registry revision yields identical staging output.
- Correcting historical effective dates or mechanics can reclassify old studies without changing their source file hashes.
- Distinguish skill-bonus research models from current verified runtime transformations; separate eligibility, occurrence chance, unconditional expected quantity, conditional min/max, ranks, input refunds and costs.
