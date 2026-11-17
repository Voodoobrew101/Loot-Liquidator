# Jallfo 2022 Dragonflight JC workbook: six omitted Draconium material transcriptions

**Checked:** 2026-11-17 UTC. **Scope:** original-source-to-research identity and quantity audit, not a new observed cohort, current-Retail applicability proof, addon patch, or live game test.

## Original source and exact gap

Original [Jallfo Dragonflight JC yield workbook](https://docs.google.com/spreadsheets/d/1B_CjPU0AUlJkbogauPTdo0W4dUZiP1hxZ8KMZX7qp3Q/edit), native tab `Sheet1`, input profiles P:R, S:U and V:X (rows 1–7) and output rows 19–20, **reports two material totals for each of three Draconium rank-3, 5,000 nominal-input-ore profiles**. The existing append-only [Jallfo research transcription](../../evidence/dragonflight/2026-10-30T2131-jallfo-beta-six-prospecting-cohorts.jsonl) includes 37 outputs per Serevite profile but **only 35 per Draconium profile**, omitting both Crumbled Stone and Fractured Glass for all three Draconium profiles.

| Source sheet column | Input | Labelled effective skill | Source P/S/V row 19: Crumbled Stone (192880) | Source P/S/V row 20: Fractured Glass (192872) | Source denominator |
| --- | --- | ---: | ---: | ---: | --- |
| P | Draconium quality 3 | 68 | 1,036 units | 769 units | 5,000 **nominal input ore** |
| S | Draconium quality 3 | 113 | 947 units | 1,079 units | 5,000 **nominal input ore** |
| V | Draconium quality 3 | 228 **disputed** | 986 units | 1,225 units | 5,000 **nominal input ore** |

Output ID crosswalk: [Crumbled Stone 192880](https://www.wowhead.com/item=192880) and [Fractured Glass 192872](https://www.wowhead.com/item=192872). The sheet itself names outputs but does not carry item IDs. Existing research maps the quality-3 Draconium source to input **190311**; the spreadsheet itself says only DRACONIUM and quality 3. Preserve source identity and provenance for any corrections.

These **six original quantities are usable historical input-normalized measurements for a clearly labelled quality/context**, but *not* counted completed prospects, independent studies, occurrence probabilities or current-patch yield. There is no source-verified net ore consumption, refund/reprocessing ledger, completed-cast denominator, per-material hit counts, output-by-cast histogram, or isolated skill effect. Source contexts and old beta-era patch remain distinct. Do not infer a 1,000-cast denominator from 5,000/5.

## What the check did and did not find

A bounded comparison of all **222 native source cells** (37 output rows x 6 character-condition columns) to the corresponding **216 existing research `drop` rows** found **216 quantity-exact matches** and **six missing rows, all the two Draconium materials above**. No mismatched transcribed numerical totals. Comparison normalized the sheet's `ILLUMINATED DIAMOND` label against the known research `ILLIMITED DIAMOND` spelling, and treated Crumbled Stone/Fractured Glass as rankless in existing records. These are source-name normalization rules, not new measurements or conjectured output quality ranks.

The owner's pinned `implementation/usable-data-tooltips` `database/research-v3-baselines.lua` already contains a selected `Prospect:190311:x5` record with **both 192880 and 192872** from existing research. Consequently **the two material types are not completely absent from the current selected compiled model**. The defect is the **loss of six profile-specific original-source rows** from the research provenance/condition matrix, not proof that the live tooltip hides the materials or that an actual gold recommendation is wrong. Existing selected values must not be overwritten or double-counted.

The [Nov 2 manager workbook source review](../../reviews/2026-11-02-dragonflight-jc-workbook-context.md) already documents a workbook projection-formula/header conflict (`$F$7` rather than each block's `EXPECTED CALC`), and a 228-vs-218 effective-skill arithmetic mismatch. Those are **pre-existing findings, not new work from this run**. Use raw `YIELD` cells with gross-input units; never import `EXPECTED` projections as measured outcomes, turn `% = quantity/5,000 ore` into P(hit), fit a skill curve or pool the distinct profiles.

## Reconciliation handoff

1. On a disjoint, reviewed research-only branch, propose an **append-only correction/addition** that references the existing Jallfo original cohort and the six specific workbook coordinates without creating new independent study IDs. Preserve per-profile source conditions and historical era; keep input/output identities source-backed.
2. Ensure any estimator import keeps existing Crumbled Stone 192880 and Fractured Glass 192872 values and their source precedence; never add the same six quantities as independent new outcomes or overwrite original evidence. Compare against other sources and the source-to-selected pipeline under controlled synthetic prices before promoting data.
3. Dragonflight T0020/T0041/T0046 workers retain their original-source/denominator/quality-identity responsibilities. No need to ask them to rediscover this already accessible source. Do not claim measured cast/hit/zero or current Retail eligibility.

## Reproducibility and limitations

- Live Google Sheets native bounded `A18:X55` UNFORMATTED_VALUE read plus exact repository research JSONL and selected compiled Lua reads, 2026-11-17 UTC.
- **672/672 bounded in-process source/identity/quantity assertions passed**, **216/216 existing transcriptions matched**; zero reported mismatch; six missing Draconium row identities verified.
- Research JSONL blob: `6fa190857771f434644a368c063632e0f0c76c0f`; owner's frozen ItemDB Lua blob: `ae953ffde49a27c0270408d0facbf6d96ee7955c`.
- No local Python estimator run, standalone Lua tests, actual new engine/tooltip rendering, modified addon, GitHub CI on a new code head, production market pricing or live WoW QA. **New independent samples = 0; newly measured casts = 0; new supported Retail decisions = 0.**
