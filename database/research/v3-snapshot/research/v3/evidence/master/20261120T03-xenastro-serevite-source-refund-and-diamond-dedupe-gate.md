# Xenastro Serevite source-unit, refund and diamond-lineage gate

Updated 2026-11-20 03:07 UTC. Research-only audit of existing evidence; **no new Retail cast-rate, supported gold value or character eligibility was verified**.

## Exact evidence compared

- New Dragonflight worker transcript: [Nov 20 four Serevite batches](https://github.com/Voodoobrew101/Loot-Liquidator/blob/implementation/five-agent-completion/research/v3/evidence/dragonflight/2026-11-20T0038-xenastro-four-refunded-serevite-cohorts.jsonl), blob `26407f235b5d14cfc26bd66e5d54a7225cb0dd82`, **32** output records across **four author-dated workbook rows**, all from the **same Xenastro source workbook**, not four independent contributors.
- Prior archived input-quality-2 Serevite transcript: [Nov 8 original row 31, present in main research snapshot](https://github.com/Voodoobrew101/Loot-Liquidator/blob/main/database/research/v3-snapshot/research/v3/evidence/dragonflight/2026-11-08T2349-original-xenastro-ranked-epic-ore-logs.jsonl), blob `e74454b9094ba584bfe1e117c38f67110cd555a7` in research. The previously archived three rank-specific Illimited Diamond outcomes are **Q1=0, Q2=12, Q3=6 units** at input rank 2, skill 238, stated quantity 15,000 and Ore Refund 557.
- Current Nov 20 workbook-row-31 records repeat the **same Q2=12 units for item 192870** and **Q3=6 units for item 192871**, with the same day, input rank, skill, quantity, refund and original source URL. These **two Diamond material rows are transcription copies, not new independent observations**. The earlier Q1=0 is an *output-unit total*, not zero completed operations. Six additional green/blue pool rows from this same batch preserve category/rank totals but have no unique material item IDs. Do not double-count the shared Q2/Q3 Diamond totals when combining original study identities.
- Three other new workbook rows in the checked named-Xenastro transcripts are distinguishable by author-date/CSV index; this is **not** an exhaustive search of every spreadsheet transcription or a direct reinspection of the original workbook.

## Batch identity and denominator gate

| Original Prospecting Log CSV row | Date | Input and quality | Stated Quantity (ore) | Separately stated Ore Refund | Skill |
| --- | --- | --- | ---: | ---: | ---: |
| 25 | 2023-01-02 | Serevite 190394, Q3 | 5,000 | 216 | 266 |
| 27 | 2023-01-03 | Serevite 190396, Q2 | 10,761 | 180 | 237 |
| 30 | 2023-01-05 | Serevite 190394, Q3 | 9,701 | 530 | 267 |
| 31 | 2023-01-06 | Serevite 190396, Q2 | 15,000 | 557 | 238 |

These quantities/refunds are **as transcribed from the source workbook by the worker**, not newly verified against a downloaded workbook in this run. The original source was not retrievable directly here. It remains unknown whether the source Quantity field is gross, net, or includes reprocessed refunded inputs. None of the 32 records includes actual completed casts, material hit counts, 0..N output histograms, or `inputsProcessed`; each has `inputsPerCast=5`. **Do not divide nominal ore by five and claim observed casts**, infer occurrence P from output unit totals, add refunds to numerator/denominator, or treat six pooled green/blue families as six specific item-ID outputs. Distinguish historical 2023 from current Retail eligibility/skill.

## Compiler and review gate

Performed **252/252 bounded JavaScript source-record, lineage and policy-shape assertions** on the two named repository evidence blobs and the research estimator source blob `0b09b553fef4214af8aaa93f1c85061956643711`. The checks covered four×eight record structure, original source URL, quality and item IDs, date/skill/quantity/refund notes, absence of invented denominators, distinct material-pool identity, and exact Q2/Q3 overlap. Code inspection of `research/v3/tools/build_estimates.py` found per-source partial-study canonicalization (lines near `study_vectors`) and the `totalWithoutCasts` hold in `row_use`; **neither the estimator nor actual addon/tooltip was executed**. This audit is not proof that future compiled dedupe, synthetic pricing, or Retail in-game behavior passes.

Observed reference state before this manager write: main `63c832add9b1612ba6565b6968ea594102309fbf`; research `32eebbf6d5c5d5af646e60355b228aa2ff0370bc`; owner integration `3d667d053db587c91401cfed7ecc56862b8340c9`. Research exact-parent push CI [succeeded](https://github.com/Voodoobrew101/Loot-Liquidator/actions/runs/44663250598); this new manager commit has **no CI claim**. PR #22/#23 closed unmerged and remain outside this audit. Main, immutable evidence snapshot, owner three-pass branch, worker records, other status files, PRs and schedules untouched.

## Next exact task

On the existing Dragonflight research assignment **T0046/T0041**, seek a directly inspectable original `Prospecting Log`/saved export for **CSV rows 25/27/30/31** that explicitly identifies ore processed versus purchased/refunded, actual completed operations and character build/skill, plus species-specific green/blue output IDs. Compare cohort identities to the Nov 8 snapshot **before** compiling or requesting a duplicate study. Then an integration owner may run actual estimator + synthetic-price tooltip regression using that reviewed source; do not alter `implementation/usable-data-tooltips` from this research branch.

**Blockers:** original workbook not independently fetched on this run; source epoch 2023, refund basis and original 0..N operation ledgers not established, pooled species IDs not resolved. External sheet browser unavailable and alternate web fetch credits exhausted; no source arithmetic promoted to a new Retail gold decision.
