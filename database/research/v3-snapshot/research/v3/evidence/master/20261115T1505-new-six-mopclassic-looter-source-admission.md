# Newly filed MoP Classic Looter observations: Retail estimation admission hold

Checked: 2026-11-15T15:04:54.900Z UTC. Manager-owned research source audit only. Source at [worker original evidence](../../evidence/legacy/2026-11-15T1440-classic-original-looter-armor-weapon-hits.jsonl), fetched blob `0f043b2125c6aeaa8edf8505979d5509067b55a4`. No addon implementation, compiler, corrections or worker files changed by this note.

## Newly observed source/identity issue

Legacy worker's 2026-11-15 14:40 UTC evidence adds **19 output rows in six distinct item-specific cumulative Wowhead MoP Classic Looter snapshots**. Every row has an explicit `/mop-classic/` URL yet is marked `sourceKind=study`, includes an item ID, `casts` and `castsWithDrop`, and lacks a verified Retail patch, at-cast item link/bonus/ilvl, player skill and variant bridge. The six pages identify a **different game flavor**; these are not observed modern Retail events. Their original reported counts are historical source data and should remain append-only, not vanish from research history.

| Classic item/input ID | Source-reported item DE operations | Material rows | Sum of material-positive hits | Source output IDs |
| --- | ---: | ---: | ---: | --- |
| 6187 Dwarven Defender | 127 | 3 | 127 | 10940, 10939, 10978 |
| 5242 Cinder Wand | 105 | 3 | 105 | 10939, 10940, 10978 |
| 15204 Moonstone Wand | 262 | 3 | 262 | 10939, 10940, 10978 |
| 3582 Acidproof Cloak | 64 | 3 | 64 | 10940, 10939, 10978 |
| 7607 Sable Wand | 583 | 4 | 583 | 10939, 10940, 10998, 10978 |
| 19040 Zorbin's Mega-Slicer | 477 | 3 | 477 | 11175, 11176, 11178 |

The **1,618 source-reported item operations** are the sum of six distinct item-level page denominators, **not 19 independent studies and not Retail completed casts**. Material-positive hit counts sum to each page denominator, but that arithmetic alone does *not* verify a single mutually exclusive material per operation, per-cast 0/1/2 histogram, actual quantity, current eligibility or patch. **All 19 `totalQuantity` and `histogram` fields are null.** Do not infer unconditional expected material units from conditional min/max, source occurrence probabilities for Retail, or calibrated confidence. Original Looter numerator/denominator cells could not be independently extracted from the web-rendered page's JavaScript table this run; the source's MoP Classic game-flavor label and representative item levels were separately visually verified on original pages.

The six page URLs, retaining original flavor/identity, are:
- [Dwarven Defender 6187](https://www.wowhead.com/mop-classic/item=6187/dwarven-defender) — 127 item-side source operations, 3 output rows
- [Cinder Wand 5242](https://www.wowhead.com/mop-classic/item=5242/cinder-wand) — 105 item-side source operations, 3 output rows
- [Moonstone Wand 15204](https://www.wowhead.com/mop-classic/item=15204/moonstone-wand) — 262 item-side source operations, 3 output rows
- [Acidproof Cloak 3582](https://www.wowhead.com/mop-classic/item=3582/acidproof-cloak) — 64 item-side source operations, 3 output rows
- [Sable Wand 7607](https://www.wowhead.com/mop-classic/item=7607/sable-wand) — 583 item-side source operations, 4 output rows
- [Zorbin's Mega-Slicer 19040](https://www.wowhead.com/mop-classic/item=19040/zorbins-mega-slicer) — 477 item-side source operations, 3 output rows

## Current v3 estimator path and PR overlap

Read `research/v3/tools/build_estimates.py` and `research/v3/corrections.jsonl` at research head before any writes. `load()` recursively reads the worker evidence; `is_study_row()` labels a drop with `sourceKind` outside `REFERENCE_KINDS` a study; `analyze()` groups such rows as studies. Flavor suffixes are kept in source identity/deduplication, **not a Retail admission gate**. No `exclude=true` correction exists for the exact 19 record IDs `legacy-20261115-143501..143519` in the checked target branch. Thus they are **statically admissible to study estimation on the next rebuild**, not proven to have been consumed in a particular successful end-to-end model run.

[Existing draft research-only PR #74](https://github.com/Voodoobrew101/Loot-Liquidator/pull/74) file-scopes **nine older, different** MoP Classic rows `legacy-20261115-1047001..1047009` from [the earlier source](../../evidence/legacy/2026-11-15T1047-tbc-ilvl97-rare-armor-looter-and-original.jsonl). These six inputs (3582/5242/6187/7607/15204/19040) do not overlap the previous seven input item IDs (29325/29326/29327/29328/29344/29345/31190) in that original file. The existing narrow PR **does not cover** these newly filed rows; avoid a competing PR or blindly broadening a Retail compiler without reviewing source lineage.

## Verification and safe next gate

Executed eight deterministic in-connector static/source-shape assertions: exactly 19 rows; all Classic URLs; all `study`/drop; no current correction IDs; six distinct item inputs; each table's listed hit sum equals its page denominator; no output-unit totals or histograms; and the checked estimator has study admission/append-only correction code without an explicit named flavor gate. All eight passed. This is **not** an executed Python v3 build, comparison against compiled ItemDB, offline Lua valuation/tooltip test, or live client test. No new verified current-Retail measured cohorts, field completeness or gold recommendations.

**Next scoped acceptance check for the owner of draft PR #74:** preserve originals and audit all new Classic-flavor evidence files as part of the same research-only exclusion/scope correction. Test `apply_corrections` and `load()` against both original cohorts, inspect actual `analyze()` usage before/after, preserve unaffected Retail/cross-era references and rerun full migration, deterministic research audit and compatibility CI. Existing reported broader migration failures must be fixed, not hidden. Do not merge PR or modify the owner three-pass addon branch. No claim that all Classic data must be discarded for all historical research uses; only that it is **not measured Retail evidence**.
