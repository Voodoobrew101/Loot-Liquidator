# Loot Liquidator Legacy — Batch019, queue revision 21
**2026-10-28 · worker loot-liquidator-legacy · research-only branch `research/processing-confidence`**

## Outcome
- Audited **40/40 exact master-assigned stable keys**: 31 previously unassigned P0 field gaps (1 Titanium Powder, 6 Legion, 12 WotLK, 12 MoP), 7 Osmenite matched-context follow-ups, and 2 BfA 20-herb mass-mill follow-ups.
- Verified **37/37** assigned TSM `GameData.lua` source lines against main blob `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`; 0 line/input/output mismatches and 0 cross-worker key collisions.
- **160 numeric field slots**: 74 low-confidence historical TSM positive range references, 2 previously compiled BfA historical mass-cast E, and **84 exact-context unknowns**. No new current-Retail P(hit), positive bounds, or completed-cast E.
- **Two independently authored original historical Titanium Powder cohorts newly indexed**, both from distinct comments on an already known Wowhead URL. **Zero new legitimate conversion mappings, zero newly verified 2026 Retail numeric fields, zero newly verified 2026 unskilled baselines.** Master queue and compiler unchanged.

## P0/P1 — Titanium Powder independent cohort reconciliation
The already admitted `36910 → 46849` Titanium Powder mapping is legitimate but its staged `E=0.715` is **143 powder / (1000 ore / 5)**, a gross-input-normalized **provisional proxy**, not a directly observed zero-inclusive completed-cast mean. Original current-ish author globalmenace says Retail 12.0.5, 1,000 ore, 143 powder; exact casts and skill unknown. Source: https://www.wowhead.com/item=46849/titanium-powder .

New source-only cohorts on that same page:
| Independent commenter / reported era | Gross Titanium Ore | Powder units / source rate | Powder per nominal five ore | Provenance |
|---|---:|---:|---:|---|
| Ssateneth / Retail 8.1.5 | 26,000 | Approx. 14.426% per ore; **exact powder count NOT stated** | approx. **0.72130** | NEW independently authored historical aggregate |
| codiferous87 / Retail 10.1 | 4,500 | 764 powder | **0.84889** | NEW independently authored historical aggregate |
| archived 2022 Reddit author | 1,000 | 152 powder | **0.76000** | REUSED original cohort, not new |
| archived globalmenace / Retail 12.0.5 | 1,000 | 143 powder | **0.71500** | REUSED already compiler-admitted cohort |

**Important:** These are different historical patches and original authors. The two new studies are independent *cohorts*, not two independent websites. No cross-patch pooled estimate, P(hit), positive min/max, or current 12.1 expectedQuantity was promoted. The 8.1.5 approximate rate is NOT a verified integer powder total. The 10.1 nominal-five equivalent is ~18.7% above the 12.0.5 value, which may reflect sampling/patch/skill effects; it does not prove a rate change. Source for 2022 archived cohort: https://www.reddit.com/r/woweconomy/comments/s6bfrl .

## P0 — Other assigned output families
- **Legion** `123919 → 130178–130183` (six rare-gem outputs): TSM source `matRate=0.01`, `amountOfMats=0.002`, positive source range 2–5. These fields cannot be naively mapped to same-cast P(hit) and E, because E would be smaller than P despite positive integer yields. The historical Felslate/Leystone comparison at https://thelazygoldmaker.com/felslate-prospecting-analysis is derivative context, not a new matched 2026 study.
- **WotLK** Cobalt `36909` and Titanium `36910` (six common gems each): raw `matRate=0.235`, `amountOfMats=0.5`, source range 1–2. Treating these as P and E violates `E ≤ P × positiveMax` (0.5 > 0.47). Neither rate is promoted. Titanium Powder is a separate output, not part of the six common gems.
- **MoP** `72094/72103 → 76130/76133/76134/76135/76136/76137`: historical `matRate=0.16`, `amountOfMats=0.0341`, positive range 1–1. Interpreting these as P and E violates `E ≥ P`; preserve as source-only.
- **BfA** `168185 → 168188/168189/168190/168191/168192/168193/168635`: two independent 2019 original cohorts already reconciled in q20; rare Sage Agate and Azsharine raw TSM rates ~2.93–2.95× the pooled historical gross-input equivalents. No new matched Retail study; **do not claim an auction/prospect action flip without prices and valid current rates**.
- **BfA 20-herb mass milling** `152506 → 153635/153636` spell `256218`: previously admitted rounded historical E **15.48** and **5.89** units per actual 20-herb mass cast (177 casts). Do not convert these into measured standard five-herb yields.

## P2 — Gold decision and numeric QA
The principal decision risks are (a) assigning TSM source-unit columns as P/E, (b) treating a gross ore normalized ratio as measured completed-cast E, (c) omitting Titanium Powder from a prospecting value, and (d) transferring historical 20-herb milling into five-herb recipe EV. Candidate itemdb already includes Titanium Powder; **no new mapping is claimed**. 37 historical source lines were read locally before new web searches. No current auction prices were queried and no action flip is asserted.

Static QA: 40 distinct assigned keys; 37 exact source-line matches; 0 invalid numeric values or reversed range references; no complete P/min/max/E tuples to test `P×min ≤ E ≤ P×max`; 84 exact-context fields unknown; zero invented zeros. New evidence JSONL preserves author, reported ore denominator, patch wording and unknown cast count. The source-review cache is master-owned and untouched. No Node CLI, Lua interpreter, WoW client or live AH tests.

## Source-learning handoff
- NEW: two original Titanium Powder author cohorts, historical only, distinct `studyID` on same canonical Wowhead URL; avoid duplicate-source miscount.
- REUSED: 2022 1k-ore Titanium, 12.0.5 globalmenace 1k-ore, 2019 Osmenite, Jiyao BfA mass and local GameData; no re-fetch required for those claims.
- NEGATIVE: a published 26,000-ore rate does not supply exact powder count or cast histogram; do not fabricate either. Historical source bounds and `matRate`/ `amountOfMats` are not observed P/E. Source-confidence scores remain independent of rewards.

## Exact next IDs for master
1. `36910 → 46849`: 2026 current-Retail 12.1 zero-inclusive per-cast powder histogram, completed cast count, JC skill and recipe eligibility. Distinguish any 0/1/2 outcomes and confirm actual five-ore consumption.
2. `168185 → 168188/168193`: 2026 current-Retail mass versus standard Osmenite operation and zero-inclusive outcomes; highest legacy rare-gem valuation discrepancy.
3. `123919 → 130178/130179/130180/130181/130182/130183`: Legion rare-gem actual output/rank and skill/patch.
4. `36909/36910 → 36917/36920/36923/36926/36929/36932`: current Retail per-cast P/E, source unit correction.
5. `72094/72103 → 76130/76133/76134/76135/76136/76137`: MoP recipe eligibility and current Retail positive yields.
6. `152506 → 153635/153636`: modern 20-herb mass-cast histograms, distinct from standard five-herb milling.

**Assigned scope exhausted:** report completion for master reassignment. No shared master, canonical registry, source-memory cache, main, production Lua/TOC or schedule writes.
