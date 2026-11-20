# Dragonflight Bugy Draconium: held family-anchor identity admission gate — 2026-11-20

## Source and exact scope
The original **held/source-only** JSON is `research/evidence/observations/2026-10-28-draconium-bugy-2x2000ore-unassigned-quality.json` (Git blob `df3cf0070b0760dc1330141af06f65ae50d3a679`). It explicitly says `SOURCE_ONLY_UNASSIGNED_QUALITY_NOT_OBSERVATION_SCHEMA`. The two Bugy Draconium cohorts each report **2,000 nominal ore**, do **not** report completed prospect operations or refunded/reprospected inputs, and do **not** identify the ore or output ranks. Their arithmetic 400 five-ore equivalents **must not** become observed casts.

| Held cohort | Source output name | Incorrect `outputFamilyAnchorID` | Correct *family rank-one anchor* | Original source-reported mean units/ore |
| --- | --- | ---: | ---: | ---: |
| bugy-draconium-2000-1 | Neltharite | 192859 | **192862** | 0.023 |
| bugy-draconium-2000-1 | Ysemerald | 192862 | **192859** | 0.026 |
| bugy-draconium-2000-2 | Neltharite | 192859 | **192862** | 0.029 |
| bugy-draconium-2000-2 | Ysemerald | 192862 | **192859** | 0.0305 |

Identity corroboration: [historic Dragonflight TSM gem families](https://pasted.drakeerv.com/xj0aR17Y), [Neltharite rank-one item 192862](https://goldcap.gg/retail/eu/items/192862), [Ysemerald rank-one item 192859](https://www.wowhead.com/it/item=192859/ysemeraldo). The anchor is **not** an observed `actualOutputItemID` and must **not** be promoted to a rank-specific item ID, priced material, or measured source outcome. The original `actualOutputItemID`, `outputQualityRank`, `hitOperations`, and completed operations remain `null`.

## Admitted-versus-held boundaries
- **Preserve the original archived JSON unchanged.** The archive is outside `research/v3/evidence/*.jsonl`-recursive input scanned by current-main `tools/research_build_review.py`. It is not itself an automatically reviewed v3 row. Check other legacy/observation adapters independently before any archive promotion; no executable build fixture was run for this report.
- Dragonflight's subsequent `research/v3/evidence/dragonflight/2026-11-18T2129-bugy-original-linked-ore-quality-corrections.jsonl` (blob `5c2ba5a519dcc7b21e5244b06a63959c2ec71365`) contains **12 Neltharite/Ysemerald name rows** across its six linked original ore cohorts; all keep `outputItemID=null`, `outputRank=null`, `casts=null`, and `averagePer=input`. These are the same original Bugy source, not new cohorts.
- The linked Draconium **input** ore identities in the worker rows are 188658 (rank 2) and 190311 (rank 3); an unmatched 189143 (rank 1) remains a separate queue gap. Matching input ranks does not identify the output gem rank or an actual operation count.
- **Review condition:** if an archived source importer or future adapter uses `outputFamilyAnchorID`, it must use the correctly named family anchor or hold the source; it must never inherit the swapped pair. Keep the two 2,000-nominal-ore batches distinct, preserve output-name/mean values and profile scope, and do not count `2000/5` as measured sample size. Do not change the immutable source archive, existing runtime, generated database, or output-ID guessing rules here.

## Validation performed
Direct GitHub read of both exact blobs and **77/77 programmatic JavaScript assertions**, covering two source cohorts, four swapped anchor references, unknown operation/output identities/ranks/hits and all 12 newer worker name rows. The current-main automatic review implementation was inspected for input file scope. This is an **identity/unit source audit**, not automatic build-review execution, Python estimator execution, synthetic-price valuation, Lua test, tooltip rendering, or live WoW verification.

## Next owner-build gate
Run an exact-research-SHA build-review fixture on a copy of the real builder after a scoped importer/adapter decision, inspect named-outcome dispositions and the actual generated ItemDB for `Neltharite` and `Ysemerald` under both Draconium input ranks. Never claim that this standalone archive discrepancy currently changes gold valuation without a traced source-to-runtime path. Follow up with original completed-operation/refund counts, gem linked output IDs/ranks and profile/patch applicability only, not a duplicate copy of Bugy's published table.
