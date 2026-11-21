# Xenastro historical prospecting — ore versus secondary-stone attribution gate (2026-11-20)

**Review scope:** Original-source method statement, not a new measured study, revised yield, or importer/runtime fix. This review independently reopened the [author's original Reddit post](https://www.reddit.com/r/woweconomy/comments/10vz6jh/prospecting_calculator_not_for_squids/) on 2026-11-20. The existing workbook extraction and field checks are inherited from the previously recorded coordinator review, not rerun here.

## Source-grounded distinction

Xenastro (u/Different_Dig2687) says they first prospect all ore using a Resourcefulness tool and then prospect both prismatic and crumbled stones using an Inspiration tool; they state the published data follow that workflow. The original post advertises an historical log of over 700,000 ore and links the associated spreadsheet. A separate reply says the log has entries with varying skill, Inspiration, and Resourcefulness settings. These are direct **process/profession-profile context statements**; they are not cast counts, output totals or per-step numeric attribution.

The coordinator's prior original-workbook verification covers Xenastro's Serevite Q3 Prospecting Log rows 46/47/50/51/57 (45 transcribed quality-bucket output records; source workbook SHA256 `847caa75c43c1227a29eb0939c80cc0d077c997c3321d3bd76dc640a519bb4ca`). That earlier **transcription check remains valid** as a cell-to-record check. It does **not** by itself prove the gem totals are entirely from direct Serevite ore processing: the author's published methodology includes a secondary step with different inputs and a different tool.

Before any rate or baseline admission by **ore input**, examine the workbook's exact sheet formulas, source columns, row-group names, and secondary-stone accounting to decide whether the specified gem outputs represent direct ore-only outcomes, ore-plus-secondary-processing totals, or already-separated results. Preserve original row values, source identities, and alternative input/output profiles in every case.

## Admission/interpretation boundaries

- No original **completed-operation count**, per-material hits, zero-inclusive histogram, refund reuse basis, or source-backed per-step split was independently recovered in this review.
- Do not divide nominal ore by batch size and label the quotient observed casts. Do not assign secondary-step output to the direct ore recipe without the original worksheet's step attribution.
- Do not assign pooled green/blue quality-bucket totals to species-specific material IDs without source support. Do not combine same-author cumulative batches as independent cohorts.
- Keep quantity, hit probability, input savings, skill, Inspiration, output quality, recipe and processing step separate. Unknowns stay unknown, and named unresolved outcomes remain unpriced rather than given fabricated item IDs.
- This is historical Dragonflight source context, not confirmed current Retail rates, real-character profit, or a completed actual-engine/tooltip test.

**Queue handoff:** T0046/T0041 (Dragonflight). Check workbook method/row grouping against the source post; document an explicit step-level disposition for each affected output and only then run exact-revision build review. Do not modify the original workbook or existing source rows.

**Primary source:** https://www.reddit.com/r/woweconomy/comments/10vz6jh/prospecting_calculator_not_for_squids/

**Existing worker checkpoint:** `research/coordination/quiet-status/dragonflight.json`, verified in repository at `44aee4db3ccbcac07135e60427039910ab6aafea`.
