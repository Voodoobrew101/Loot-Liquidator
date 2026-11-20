# Resonant Crystal cumulative source denominator review

This review applies only to the ten `dragonflight-20261120-347001` through `dragonflight-20261120-347010` records in `research/v3/evidence/dragonflight/2026-11-20T0347-resonant-crystal-ten-unindexed-gear-items.jsonl`, pinned at research commit `36449aa5fee6c25e587b6c0eb9b2294dc8ef7d80`. Their material is Resonant Crystal, ItemID 200113. The cited source is the material-side [Wowhead table](https://www.wowhead.com/ptr/item=200113/resonant-crystal).

The records explicitly describe cumulative indexed item observations whose completed-craft denominator has not been validated. They mark the displayed percentage meaning as unclear, and their own notes reject interpreting these numbers as independently verified per-operation occurrence. No total output units, complete outcomes, zero counts, or stack histogram are supplied. Storing the displayed table denominator under `casts` does not establish completed operations.

The existing field adapter would otherwise accept those positive `casts` and `castsWithDrop` integers and derive a per-cast probability. The reviewed admission policy therefore holds these ten original identities and their study-key aliases before numerical aggregation. This does not reject all Wowhead or cumulative-table research. A distinct source with a verified operation denominator can still contribute under the existing policy.

| Record suffix | Input ItemID | Displayed table denominator | Displayed occurrences |
| --- | ---: | ---: | ---: |
| 347001 | 207150 | 127 | 77 |
| 347002 | 207165 | 108 | 66 |
| 347003 | 195508 | 204 | 124 |
| 347004 | 204393 | 157 | 96 |
| 347005 | 204467 | 158 | 96 |
| 347006 | 207118 | 246 | 151 |
| 347007 | 195511 | 193 | 119 |
| 347008 | 208445 | 181 | 112 |
| 347009 | 195496 | 186 | 115 |
| 347010 | 200338 | 144 | 88 |

All source rows, identities, observations, quotations, unknown dates and reported counts remain unchanged in the pinned snapshot. The hold does not manufacture sample sizes, reinterpret conditional stack ranges as unconditional outcomes, or use the displayed percentage as a separately supported probability. Automatic build review records the reason; it does not claim independent scientific approval.
