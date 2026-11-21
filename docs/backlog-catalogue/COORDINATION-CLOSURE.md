# Catalogue closure and future research coordination

Status at preparation: the finite source review has terminal receipts; final compiled-runtime verification and integration remain pending. This document does not certify a build, installation, release, or completed runtime behavior. The integrating owner must attach the exact successful build receipt before updating coordination to completed.

## Scope and authority

The catalogue ID is `backlog-20261120`. Its research cutoff is `0cd0bad8867e7a8d909b4ecae74f6136a3e23d42`: the original 713 pending source keys, 12 additional source keys present at that cutoff, and 6 previously cleared sources whose other fields still required current-pipeline review. The original backlog assignment came from research pin `e8327f30b82a16a19e6df43820277383085bcd3a`. Later evidence is new research with its own receipt; it does not silently enlarge or invalidate this finite denominator.

All paths in the following table are relative to the pinned research checkout. The catalogue directory is `research/v3/evidence/master/backlog-catalogue-20261120/`.

| Scope | Recorded result | Authoritative receipt |
| --- | --- | --- |
| Source keys | 731 assigned; 731 marked `REVIEWED` | `assigned-sources.json`, `final-source-decisions.json` |
| Source/cohort/field scopes | 12,222 assigned; 12,222 with decisions | The same two files, matched by source key and scope ID |
| Required fields within those scopes | 13,288 assigned and decided | `requiredFields` matched to `fieldDecisions` |
| Canonical proposals | 12,397 terminal dispositions | The canonical proposal files selected by `manifest.json`, and `proposal-dispositions.json` |
| Original explicit leads | All 35 reviewed to a terminal current-use decision | `disenchant-b-leads-review.json`, its final receipt, and the corresponding final source scopes |

The 35 lead reviews comprise 12 admissions, 5 already represented sources, 14 metadata/reference outcomes, and 4 current numerical rejections. Admitted leads have concrete row scopes; they do not require a second artificial lead scope. A terminal lead can retain useful contextual information without providing an unconditional numerical yield.

These counts describe reviewed source scopes and proposal decisions. They are not observed casts, independent studies, validated drop rates, or proof that every possible Retail item and formula is known.

`manifest.json` pins the assignments, final decisions, proposal definitions/dispositions, and admitted model/fact payload. Exact row paths, record IDs, raw hashes, corrected-layer hashes where required, and field scopes identify what was reviewed. A decision is authoritative for those fields and contexts only. A URL-level status, an old queue item, or a generic source hold cannot replace that field-level receipt.

## Research closure and runtime closure are separate

The research coordination file `research/coordination/backlog-catalogue-20261120.json` currently retains `ACTIVE_OWNER_REQUESTED_CATALOGUE_CLOSURE` and per-source `REVIEW_IN_PROGRESS`. That is an outstanding coordination handoff, not evidence that the terminal reviews should be repeated. Do not change it to a runtime-complete state from this note alone.

The final integration receipt must identify the actual code commit, research commit and catalogue manifest hash; successful normal research preparation; the compiled consumer review; required addon tests; and the artifact or installation result actually performed. `database/research/source-catalogue-build-review.json` and the build manifest record producer/compiled-consumer verification. Successful consumption proves that reviewed models and facts reached the intended database paths. It does not independently establish their scientific accuracy or convert assumptions into measurements.

Retained source facts, rejected numerical fields, named unpriced outcomes, and confidence-zero priors remain distinct. A supported per-input mean can be useful with no known cast count. Known source investment must be inverted before target-profile projection; it must not become an observed zero-profile baseline. Baseline quantities and source observations remain immutable. Confidence communicates model uncertainty in ordinary tooltips; detailed assumptions remain in the research receipts.

## Reuse reviews before assigning work

At the start of a research run, read the pinned catalogue, current source corrections, the relevant lane receipt, and the existing source memory before creating an assignment. Preserve useful previous work even when a newer field can improve it.

- `research/v3/queue.json` and `docs/research-manager/queue.json` are assignment/prioritization records, not authority to discard terminal catalogue decisions. Old open wording may now describe a narrower confidence or missing-field task. Cite the catalogue and scope that remaining task explicitly; do not restart the entire source review.
- `research/coordination/source-memory.json` is a derived research index. Its historical source count and statuses have a different scope from this 731-source catalogue. They must not be substituted for the catalogue denominator or treated as a failed coverage test.
- `research/tools/build_source_memory.js` builds that index from original observations, `research/coordination/source-reviews/` events, QA feedback, and approved attribution/lineage corrections. Its accepted statuses are `FULLY_ANALYZED`, `PARTIAL`, `NEEDS_RECHECK`, `DUPLICATE`, and `DISCOVERED`. Do not write a new unsupported status into a review event or directly overwrite derived memory to manufacture closure.
- When a later coordination update records this work, retain original review and QA history. Link the exact catalogue receipt and field scope; do not relabel scientific completeness merely to make old dashboard counters agree.

The current owner request and this scoped catalogue handoff supersede stale workflow counters or preview-only restrictions where the owner has authorized the current baseline pipeline. They do not authorize changing raw evidence, manufacturing observations, bypassing source preferences, or granting recipe/item-use eligibility.

## When to reopen a reviewed field

Reopen the smallest affected scope when there is a concrete change:

| Trigger | Required next step |
| --- | --- |
| New original data or an amended source table | Preserve the new original and its units, epoch, identities and profile. Determine whether it is independent, cumulative, overlapping, or a corrected version before giving it weight. |
| A correction changes a reviewed raw/corrected row | Revalidate that row's proof and affected consumers. Replace or hold only the affected fields; preserve unrelated valid reviews. |
| Native identity, rank ordering, recipe batch, unlock, input/output unit or source-profile information resolves a named rejection | Cite that rejection's `futureEvidenceTrigger`, add the resolving proof, and test source inverse/forward consistency before admitting a numerical replacement. |
| A documented patch changes the mechanic or applicable population | Keep the old epoch and source facts. Establish the new scope rather than calling historical observations current measurements. |
| A reproducible compiled/runtime mismatch contradicts a reviewed formula | Correct and test the integration, with source controls and baseline identity preserved. Another source search is not a substitute for fixing a consumer defect. |
| A previously unassessed dimension is recovered from an unchanged source | Reuse valid prior work, but review this exact field. An old unconditional-EV rejection does not dispose conditional quantities, input refunds, quality shares, or nominal event intensities. |
| A blocked original becomes accessible | Inspect the previously unavailable fields. Access failure alone was never scientific evidence against the source. |

An unchanged page, a routine rerun, unknown cast count alone, an old open queue label, a copied guide, or unrelated rows appended to the same file is not a reopening trigger. Whole-file fingerprints remain snapshot-integrity/provenance information; admission is scoped to the exact reviewed rows and fields. Repeated access failures should retain their access receipt and precise missing fact, not become a universal rejection.

Positive sightings must not become completed-cast counts; a source input budget must not become invented samples; a conditional mean or quality share must not become unconditional probability. Keep occurrence, quantity, ranges, quality, input savings, extra outputs, time and nontradable rewards separate. Apply source normalization and target modifiers once. Preserve original lineage so a copied or reimported cohort is not weighted twice.

## Scheduled research after handoff

Keep all existing schedules, cadence and quiet reporting unchanged. Do not create duplicate automations, pause workers, or open routine research PRs for this handoff. Scheduled work should seek genuinely new published/original evidence, resolve a precise remaining identity/unit/profile question, and improve confidence or correct a demonstrated defect. After an exhausted approach yields no new usable information, record that result once and move to another ready task.

Routine evidence and scoped catalogue metadata belong on the durable research branch. Normal `tools/prepare_build_research.py` ingestion reads enabled entries in `research/v3/evidence/master/source-catalogues.json`; this catalogue is registered there. New catalogues use globally unique model/fact IDs, explicit terminal decisions, hashes, and a manifest. They require no routine addon-code PR merely to reach the next build. Code/schema changes retain their independent implementation review path. See [the research-to-build handoff](RESEARCH-HANDOFF.md).

Existing and published data only: this handoff does not authorize in-game crafting, disenchanting, purchases, item destruction, or knowledge spending. Instance-specific unresolved diagnostics outside the pinned assignment, including an unavailable full Timewarped item link, remain separate tasks; they must not be represented as a solved catalogue field or an inferred expansion/eligibility rule.

## Proposed coordination update after verification

The integrating owner may perform the following after the exact final receipt passes. These are proposed follow-up actions, not changes made by this document.

1. Attach the immutable final integration/build receipt and exact code/research commits to the coordination record. Record research review completion separately from runtime validation and delivery.
2. Update the existing catalogue status and its 731 matching source entries to scoped terminal review states. Retain each source's mixed field dispositions, rejection reason and future trigger; do not mark every field numerically admitted.
3. Link the catalogue from source-review memory or a supported coordination index without replacing historical events. If any old queue entry is reconciled, cite its exact covered scope and keep a narrower unresolved confidence task only where concrete work remains.
4. Preserve `scopeCutoffResearchCommit`, the 713 pending + 12 cutoff additions + 6 recovered source split, `noNewInGameTests: true`, `automaticResearchPullRequests: false`, and the existing scheduled new-data priority. Make no schedule or automation changes.

Until that verified receipt is attached, the runtime completion and delivery portions of this handoff remain pending.
