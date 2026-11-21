# T0051: 48,315-ore Adamantite cohort — four-copy identity and nominal-cast review (2026-11-20 UTC)

Scope: **source lineage and static scientific review only**, no new source measurements, no cast execution, no build-time admission or game-client validation. Original source: https://www.reddit.com/r/classicwow/comments/p71mrp . The original Reddit comment could not be independently reopened in this run; statements about the source are attributed to the four extant source transcriptions, not a fresh author or timestamp verification.

## Independently compared pinned evidence files

All four files contain **the same 13 outputItemID:totalQuantity tuples**, the same input Adamantite Ore (23425), and the same Reddit thread URL; they use four different `studyKey` values. The identities and source blob SHAs are:

- `research/v3/evidence/legacy/2026-11-07T1818-adamantite-original-commenter-cumulative.jsonl` — `fde434952bdaac07340a70465b426b1597ecb413`: 13 `study` rows, source percentages omitted.
- `research/v3/evidence/legacy/20261107T1701-adamantite-48315-and-tbc-disenchant.jsonl` — `c0d0e7d2dc4d5a3179daae9dbd0451d0cf0f7bcb`: 13 `study` rows, source percentages retained as `percentMeaning=unclear`.
- `research/v3/evidence/legacy/2026-11-10T0442-adamantite-48315-original-reddit.jsonl` — `26e0fab6f49ddd46e03f025a0149cd3ab0b4d833`: 13 `study` rows, same percentages, `percentMeaning=unclear`.
- `research/v3/evidence/legacy/2026-11-13T1941-adamantite-48315-cumulative-original-update.jsonl` — `1b7880755546d5c3eb198c1ea88f997807e077cb`: 13 `reference` rows, source percentages omitted.

Sorted output fingerprint, verified equal across all four: `21929:1841 23077:1705 23079:1818 23107:1798 23112:1727 23117:1760 23436:372 23437:376 23438:375 23439:375 23440:312 23441:367 24243:9662`. These are **52 transcriptions of 13 original source outputs**, not four independent studies or 52 observations. All 52 rows have `casts=null` and no per-cast hits or zero histograms. 48,315 / 5 = 9,663 **nominal** five-ore equivalents only. The source's 9,662 Adamantite 'Dust' versus nominal equivalents differs by one; do not invent a missing cast/refund. Output 24243 is a tentative alias to Adamantite Powder, not a freshly verified source hyperlink.

## Distinct older cohort — independence not established

`research/v3/evidence/legacy/2026-10-31T0843-adamantite-29865-original-study.jsonl`, blob `310dc9f335ad9c44781c8826d479f022f11e41f7`, from https://www.reddit.com/r/classicwow/comments/ospt2y/prospecting_results_for_3k_and_30k_adamantite_ore/ contains 13 lower totals for the same outputs (29,865 source-reported ore). The author is transcribed as GuildLeaderCali, unlike the unknown commenter identity in the 48,315-ore record. Every older total is less than or equal to the larger record; this alone is **not proof** that the newer totals are a cumulative snapshot by the same author. Keep the two sources' lineage/independence unresolved; do not add or subtract their outputs as independent batches.

**Additional denominator diagnostic:** the older source has `casts=5973` in 13 records, but their own notes explicitly say 29,865/5 = 5,973 was **derived from reported ore**, not a separately logged number of completed casts. Their `castsBasis` is unset and no matching correction was found in `research/v3/corrections.jsonl` as read this run. Before any cast-weighted estimate, review this provenance and annotate nominal versus observed operation basis without changing original evidence. This is not evidence of a completed-cast sample of 5,973 or a current Retail profile.

## Pipeline classification and unresolved verification

Inspected current `research/v3/tools/build_estimates.py`: source-URL normalization, `study_vector`/partial-copy merging, and `study_identity` are intended to collapse same-source rows with different studyKeys. `NUMBER_FIELDS` includes `percentShown`, explaining why one copy is a partial numeric transcription; source-linked dedupe must still be verified with **actual exact-research-SHA** `tools/research_build_review.py` dispositions. Static field/value comparison is **not** an executed compiler, ItemDB, valuation or tooltip test. `sourceKind=reference` copy is not an independent measured cohort. Neither the historic 48,315 nor the 29,865 TBC Classic study establishes 2026 Retail processing rates.

**Next:** pin one current research SHA and run the existing main build-time review; inspect all 52 source rows' dispositions and the older 13-row `castsBasis` handling; verify one effective original source identity, no double-weighted probability or quantity, no fabricated completed casts and no unsupported Retail context. Escalate code/schema changes separately; do not create data-only PRs, touch main, or rewrite the four append-only originals.
