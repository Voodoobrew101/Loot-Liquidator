# Dragonflight Batch 019 — queue revision 21
2026-10-28 19:31 PDT · worker loot-liquidator-dragonflight · research-only

## Assignment and reproducible QA
Read live queue21 assignments, master batch018 verdict, source-memory, research lessons, previous q19/q20 Dragonflight source-review events, and original GameData source lines. Before writing, re-read branch head `ff981e073d4e36e79457df11315d67a0e841d0db`, queue revision 21, and all 40 exact assigned keys. **40/40 GameData source-line + enclosing input + output IDs matched**; 34 prospecting and 6 milling rows; no cross-worker claims. Exact audit JSONL accompanies this report.

## P0/P1 findings
**New independent first-hand historical cohort lead:** Reddit commenter (February 5, 2023) in https://www.reddit.com/r/woweconomy/comments/10u5ao8 reports 100,000 **rank-two Draconium** ore prospected, yielding 112 rank-two Illimited Diamonds (item 192870) and 194 rank-three Illimited Diamonds (192871). Ten separate 10,000-ore rows reconcile: R2 112, R3 194, total 306. This source was **absent from the live source-memory URL inventory** at read time. The first-person table was accessible via search-index text; direct Reddit open failed and an alternate scraper rejected Reddit. Preserve this retrieval limitation; not a live direct-page attestation.

Nominal **five-ore input equivalents**, for historical source-only comparison: 100,000/5=20,000; R2 112/20,000=**0.0056**, R3 194/20,000=**0.0097**, combined **0.0153** diamonds per nominal five starting ore. These are **NOT** zero-inclusive E per completed operation. Actual casts, recycled ore, Resourcefulness, skill, specialization, client build and sample period are unknown. Do not promote these to current-Retail per-cast E or P. The author does not explicitly list item IDs; rank-to-ID correspondence is independently supported by GameData and item pages (https://www.wowhead.com/item=192870 and https://www.wowhead.com/item=192871).

The four independent fields on all 40 assigned exact-rank records: **P unknown (40), conditional positive min/max historical TSM family references only (80 low-confidence slots), unconditional per-completed-cast E unknown (40)**. Range references are not observed exact-rank bounds. All original source fields and status/confidence are in the audit; zero new verified 2026 Retail numeric fields, zero new legitimate conversion mappings.

## P2 valuation and source-semantic risk
For 188658→192870/192871, imported GameData has `matRate=0.0142` **on each** rank alternative. Naïvely adding both would imply 0.0284 nominal rate versus historical aggregate **0.0153 per nominal five ore** (~1.86x). This comparison deliberately uses *unverified TSM field units* and a *historical gross-input normalization*: it flags a **potential 86% inflation from naïve double-rank counting**, not proof of a 2026 gold-action error. TSM `amountOfMats=0.0028` also cannot be treated as a measured unconditional E while `matRate=0.0142` is called P; E>=P would fail if these were same-operation values. All 40 assigned rows have `matRate>amountOfMats`, a **semantics warning, not proof of a TSM defect**. Distinguish any saved ore from diamond outputs.

## Independent vs derivative evidence
- **New, separate first-person historical cohort (1):** Feb 5, 2023 rank-two Draconium 100k ore / 306 diamonds / ten batch table; search-index excerpt, direct Reddit fetch blocked.
- **Reused historical sources:** October 2022 Jallfo beta high-quality ore and original Saxifrage discussions; not new studies or current patch bridges.
- **Derivative/context:** GameData's TSM-derived rates and Wowhead item identity pages. No independent current-Retail cast-level study found.
- **Useful negative conclusions:** 40 exact identities checked; rank-copy warning retained; no fabricated P, E, or conditional bounds; no need to re-fetch already archived Jallfo study.

## Master handoff and exact next IDs
1. `tsm:prospect:188658:192870:L1205` and `tsm:prospect:188658:192871:L1206`: get 2026 Retail, rank-two Draconium, actual completed casts, Resourcefulness accounting, skill and separate zero-inclusive R2/R3 diamond histograms; then assess whether historical 112:194 split persists.
2. `tsm:mill:191465:198420:L1957` and `tsm:mill:191466:198418:L1960` / `198419:L1961` / `198420:L1962`: independently verify Saxifrage rank outcomes; the historical 2–5 source family range is not per-rank hit evidence.
3. `tsm:prospect:189143:192870:L1243`, `192871:L1244`, `tsm:prospect:190311:192870:L1281`, `192871:L1282`: rank-matched Draconium R1/R3 comparisons; do not borrow the R2 study.

## Tests and constraints
Exact source-line 40/40 PASS; 40 unique queue keys PASS; batch arithmetic 112+194=306 PASS; all 80 provisional bounds positive and min<=max PASS; 80 unknown P/E retain null/zero confidence PASS; original 2023 aggregate does not enter numeric candidate. No Node CLI, Lua runtime or WoW client tests. Master review required before compiler action. Production Lua/TOC, main, shared master ledgers, assignments, canonical registry, source-memory cache and schedules unchanged.
