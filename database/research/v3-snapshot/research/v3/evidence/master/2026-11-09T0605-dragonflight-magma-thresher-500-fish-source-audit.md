# T0041 — Dragonflight Magma Thresher (199344) 500-fish original-source aggregate

Audited 2026-11-09T06:07:39.244Z UTC against the current research branch parent `30e67228b497025cb086e30ce2abca25b959ffe7`. Historical Retail Dragonflight source, **not** 2026 live-character proof. Source: [January 12, 2023, first-person r/woweconomy thread](https://www.reddit.com/r/woweconomy/comments/109yr4s), **“Data from prospecting 500 Magma Thresher.”** Its indexed text was retrieved with a direct search result; direct Reddit page fetch was unavailable. [Wowhead Magma Thresher](https://www.wowhead.com/item=199344/magma-thresher) independently names item 199344 as a **prospectable fish**, and [Goldcap Retail catalog](https://goldcap.gg/retail/us/items/199344) retains that identity. Source numbers were checked against the indexed table, **not** reconstructed from TSM rates.

The author wrote **“With 25 points in prospecting specialization (all R2)”**. This is source-stated context, not verified exact input-item rank, tooltip-linked output IDs, profession skill, specific unlocked nodes, Resourcefulness, a recipe spell or completed-cast log. The post reports **500 Magma Thresher fish**, not 500 confirmed completed casts. Never apply generic *5 ore per prospect* to a fish without a fish-specific recipe/consumption source.

| Source output label | Reported total units |
|---|---:|
| Illimited Diamond | 0 |
| Nozdorite | 6 |
| Neltharite | 3 |
| Ysemerald | 2 |
| Alexstraszite | 4 |
| Malygite | 1 |
| Eternity Amber | 45 |
| Mystic Sapphire | 11 |
| Queen's Ruby | 16 |
| Sundered Onyx | 17 |
| Vibrant Emerald | 16 |
| Glass (generic, not source-linked to an exact ranked ID) | 121 |
| Stone (generic, not source-linked to an exact ranked ID) | 140 |

**Interpretation:** A candidate **new source-linked aggregated output vector**, not a proven new independent *completed-cast* cohort. The distinct thread URL is absent from repo-default-branch source search (`109yr4s`), and was not seen in the existing [October 31 Magma Thresher evidence](../dragonflight/2026-10-31T2027-magma-thresher-prospecting-cohorts.jsonl), which holds different Wowhead and January 1 Reddit cohorts. The author identity and repost relationship are still unknown; **do not pool or double weight** until deduped against original authors/other 2023 datasets. The existing old TSM input 199344 table is a reference, not this original experiment.

**Numerical gate:** `reportedFish=500`; `completedCasts=null`; `inputsPerCast=null`; `castsWithDrop=null` for all rows; `perCastZeroHistogram=null`; `totalQuantity` is source-stated above. “0 Illimited Diamond” describes the reported sample total, **not** an impossible drop or measured current Retail probability. The “all R2” parenthetical is **not** proof of rank-2 IDs for each output; preserve the author's exact names and unresolved output alternatives. No estimated P(hit), per-cast EV, skill coefficient, Multicraft, sale price or recipe/eligibility claim is warranted.

**Why it matters:** Pass-2 [implementation checkpoint](../../../..//docs/usable-data-audit/PASS-2.md) already recognizes Magma Thresher 199344 as a special prospectable input with an unresolved actual fish recipe/batch. This original-source vector can improve documented historical field coverage **only after input-operation units, output identities and cohort dedupe are resolved**. Do not make a current-character recommendation or overwrite the protected three-pass code.

**Actual validation:** retrieved source-index text, independently checked catalog item/name, searched repository for source URL/ID, compared the existing Magma source file, and transcribed all 13 aggregate totals. No direct Reddit raw HTML, in-game operation, Lua test, synthetic-price formatter, source-to-ItemDB import or customer price check was performed. Next research priority remains source-linked completed-operation/zero-inclusive Midnight fields (T0005/T0039/T0045); Dragonflight owner can investigate the 500-fish recipe and original author under T0041 without rerunning old studies.
