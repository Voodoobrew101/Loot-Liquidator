# 2026-11-20 — Xenastro two newly indexed dated worksheet batches: source-stage and identity guard

**Scope:** manager cross-record integrity review of freshly committed Dragonflight worker evidence. This checks the repository records and the existing automatic build-review code, not the original spreadsheet cells independently and not a run of the ItemDB compiler, price engine, tooltip or World of Warcraft client.

## Pinned source data and nonindependence

- New original-worksheet transcription file: `research/v3/evidence/dragonflight/2026-11-20T1938-xenastro-khazq2-and-sereviter3-original-held-batches.jsonl` (13 valid JSONL rows; one source and two distinct dated worksheet batches, not independent authors).
- **Khaz'gorite Ore Q2, item 190313**, original dated 2023-01-03, 1,000 nominal ore, 20 returned ore units, skill 238, Inspiration 0.339 and Resourcefulness 0.051 (reported fractions). Six new pooled output bucket totals: green Q1/Q2/Q3 = **0 / 184 / 65**; blue Q1/Q2/Q3 = **0 / 180 / 85**. Sum of new pooled buckets = **514**. Previously archived exact diamond quantities **7× 192870 (Q2) and 1× 192871 (Q3)** belong to this same study key in `2026-11-08T2349-original-xenastro-ranked-epic-ore-logs.jsonl`; do not record them as a new independent cohort or re-add them from the 13 rows. Source-reported aggregate with the already indexed diamonds = 522 units, not per-ore EV.
- **Serevite Ore Q3, item 190394**, original dated 2023-01-01, 10,000 nominal ore, original refund cell blank (unknown), skill 267, Inspiration 0.339 and Resourcefulness 0.051. Six new pooled bucket totals: green Q1/Q2/Q3 = **3 / 342 / 1878**; blue Q1/Q2/Q3 = **14 / 58 / 851**; plus **17× 192871 (Q3 Illimited Diamond)**. File-sum = **3,163** units. This is not a verified output per completed cast; the worksheet supplies no actual operation count.
- All **13** new rows have `sourceKind=reference`, `casts=null`, `castsWithDrop=null`, no zero-inclusive per-event histogram; **12** pooled species rows have `outputItemID=null`, while the seventeenth diamond unit record has a named exact item ID. A zero pooled total is not a zero-outcome cast.

## Admission / research instruction

The original author's [two-stage discussion](https://www.reddit.com/r/woweconomy/comments/10vz6jh/prospecting_calculator_not_for_squids/) indicates prospecting ore and then re-prospecting Prismatic Ore / Crumbled Stone. The worksheet aggregates do not attribute material outcomes to the individual processing stage. Preserve these totals as **held descriptive reference source data**, not additive ore-only yields, independent cast cohorts, rank-resolved gem species or P(hit). No assignment of 13 raw rows to supported direct-ore economic recommendations is authorized by this review.

Current main `tools/research_build_review.py` checks original identity and operation scope before source counting; uncounted sources are ordinarily preserved as reference, and unresolved identities may be held earlier. The precise disposition and generated ItemDB effect for these new rows **have not been executed on an exact pinned research snapshot** in this manager run. Build-time automatic review is not scientific approval. Do not infer an adapter success or failure from this file-only check.

## Required unblock

For Khaz Q2 and Serevite Q3 separately: obtain the original **ore-stage versus secondary-stone-stage output ledger**, exact species/item and output rank, actual completed ore prospects and secondary operations, refunds and retained inputs, and per-event successes/zeros in each stage. Confirm the same original worksheet/date/study key is deduplicated against previously indexed diamond records. Do not request repeated downloads of this already inspected workbook when the missing stage ledger is unavailable.

**Validation performed:** programmatic parse of 13 new JSONL rows, study-key grouping, per-bucket addition, and exact-key comparison with the two previously archived Khaz Q2 diamond rows; static inspection of main automatic build-review source. **Not performed:** original XLSX re-download, exact-SHA build/review execution, Lua/tooltip tests, current-client eligibility test, or new player observation. No new observed casts, coefficients, currency valuations or supported gold actions.
