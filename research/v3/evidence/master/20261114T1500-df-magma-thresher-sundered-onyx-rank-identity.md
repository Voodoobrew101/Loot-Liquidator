# Dragonflight Magma Thresher: source-ranked Sundered Onyx item identity crosswalk
Checked 2026-11-14 UTC. Research-only original-record identity audit, **not a new prospecting study**.

## Previously recorded source, preserved unchanged
- Worker original: `research/v3/evidence/dragonflight/2026-10-31T2027-magma-thresher-prospecting-cohorts.jsonl`, records `dragonflight-20261031-20003` and `dragonflight-20261031-20004`, same study `wowhead-magma-thresher-mystspecimen-two-prospects`.
- Original attributed source: https://www.wowhead.com/item=199344/magma-thresher , commenter MystSpecimen (date, actual build and skill not established).
- Input: **Magma Thresher, item 199344**; commenter reports **two completed prospect operations**; **input fish quantity per operation unknown**. Described outputs include one **rank-2 Sundered Onyx** and one **rank-3 Sundered Onyx**, each with `totalQuantity=1`; `castsWithDrop`, zero-inclusive per-material histograms, skill, stats, bonus/build, and patch remain **unknown**.
- The worker's two rows correctly leave `outputItemID=null`; they should not be rewritten or duplicated as new casts.

## Newly crosschecked output item-rank identities
Independent public item-specific pages (read on 2026-11-14) supply item ID and displayed crafting quality **together**, rather than assuming the rank by sorting the pre-existing family IDs:
- **Rank 1 = 192846** https://goldcap.gg/retail/eu/items/192846 — catalogue context only; **not an observed output** in the MystSpecimen two-cast source.
- **Rank 2 = 192847** https://goldcap.gg/retail/kr/items/192847 — matches source record `dragonflight-20261031-20003`, whose output rank is 2.
- **Rank 3 = 192848** https://goldcap.gg/retail/us/items/192848 — matches source record `dragonflight-20261031-20004`, whose output rank is 3.
- The old family membership was already listed as `[192846,192847,192848]` in `database/research/rank-families.json`, but without a `verifiedRanks` map. This audit adds **public explicit rank-label evidence** and its exact relationship to two original null-output-ID rows, not newly discovered family members or independent new output quantities.

## Admission guard / relevance
- The complete **two-operation cohort** is one old reported source, not two studies. Both outputs' total quantities are source-reported, but no material-specific occurrence counts or histograms are established; do not use **totalQuantity** as `castsWithDrop` or assume zero rows.
- The 5-ore general Dragon Isles Prospecting recipe does **not** establish how many Magma Thresher fish a fish-specific operation consumed. Current 2026 Retail processing eligibility, input batch, character skill, and source build remain unresolved. No current-Retail output valuation, standalone client operation, or current-patch odds are verified here.
- No addon/ItemDB migration, worker evidence, original workbook, source rank-family file or integration branch was changed. An append-only, worker-owned reviewed correction/crosswalk may attach `192847` and `192848` to the two existing records **only after applicability/lineage review**, without reproducing the two operations as fresh research.
- Do not reuse the original **400-input/80-operation Prismatic Ore** Sundered Onyx rows as an independent Magma Thresher cohort or confuse those separate input methods.

**Validation performed:** fetched original worker JSONL and current family registry, crosschecked source-row ranks to explicitly labeled public item pages, and searched indexed repository for any existing `MystSpecimen 192847` / `Magma Thresher 192848` crosswalk (none found). No Lua, offline valuation/tooltip, live client, or CI run was executed as part of this source audit.

**Next highest-priority gold research:** original current-patch Midnight `T0005/T0039/T0045` rank-resolved, refund-aware 0..N outputs/operation receipts; Dragonflight `T0041` may reconcile this ranked identity on its own append-only worker branch after fish eligibility and input count are verified.
