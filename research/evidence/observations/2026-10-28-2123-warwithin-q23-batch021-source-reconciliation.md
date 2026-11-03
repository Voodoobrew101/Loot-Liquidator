# War Within worker q23 — authorized Dragonflight overflow source reconciliation
**2026-10-28 · research/processing-confidence · SOURCE-ONLY, NOT a new independent observation**

## Exact assigned source universe
Queue revision 23, assignment `2026-10-28-batch021-war_within`, 45 distinct keys: Draconium Ore R3 `190311` (25 rows, GameData 1259–1285) and Khaz'gorite Ore R1 `190312` (20 rows, GameData 1288–1307). Pinned GameData SHA `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`; all 45 line/output IDs matched. 42 source rows carry a targetQuality value, and 3 are unranked by the source. Exactly 34 unique output IDs across both inputs.

## Existing primary study, explicitly reused
The archived Jallfo Dragonflight beta spreadsheet is **one author/study** with three 5,000-R3-Draconium initial-ore cohorts at skill 68/113/228, not three independent authors. Existing original transcription: [research/evidence/observations/2026-10-28-0728-dragonflight-batch007-2022beta-six-cohorts.jsonl](https://github.com/Voodoobrew101/Loot-Liquidator/blob/research/processing-confidence/research/evidence/observations/2026-10-28-0728-dragonflight-batch007-2022beta-six-cohorts.jsonl). Spreadsheet: https://docs.google.com/spreadsheets/d/1B_CjPU0AUlJkbogauPTdo0W4dUZiP1hxZ8KMZX7qp3Q/edit?usp=sharing. The author's [Wowhead explanation](https://www.wowhead.com/news/dragonflight-jewelcrafting-analysis-wowhead-economy-weekly-wrap-up-249-329385) is derivative of that same sheet, not independent corroboration.

For the three cohorts, reported **Sundered Onyx quality 1/2/3** aggregate totals are respectively:
- Effective skill 68: R1=224, R2=0, R3=70; Crumbled Stone=1036, Fractured Glass=769; 5,000 initial ore
- Effective skill 113: R1=196, R2=0, R3=7; Crumbled Stone=947, Fractured Glass=1079; 5,000 initial ore
- Effective skill 228: R1=0, R2=194, R3=14; Crumbled Stone=986, Fractured Glass=1225; 5,000 initial ore

The study explicitly names outputs by rank but its original JSONL retains `unmappedReportedOutputs` because original rows do not embed item IDs. GameData and [Sundered Onyx item 192848](https://www.wowhead.com/item=192848/sundered-onyx) support the item family; the quality-to-ID mapping should be independently verified before attaching these aggregate counts to `192846/192847/192848`. **No new mapping, P, E, or bounds are promoted here.** Low-skill cohort reports some rank-3 outcomes, requiring source-interpretation caution. Original completed cast counts, zero-inclusive per-output histograms, inspiration events, refund quantities and 2026 patch bridge are absent. Do not treat 5,000/5 as observed completed operations.

## P2 source-semantic invariant
Across 45 assigned GameData rows, `matRate > amountOfMats` in 45/45. For any real output with strictly positive integer yields, unconditional E must be >= occurrence probability P. Thus interpreting `matRate` as P and `amountOfMats` as per-cast E would violate the invariant. This is a **column-semantic blocker**, not proof the original TSM data are incorrect. Each source's `minAmount/maxAmount` is a reference range, not verified 2026 positive-outcome bounds. Repeated rates across R1/R2/R3 alternatives cannot be summed as independently measured probabilities. The exact TSM importer semantics and output-rank selection must be resolved before gold-optimal liquidation use.

## Negative findings / next exact IDs
No matched 2026 Retail zero-inclusive cast study found for either assigned input. Do not reuse 2022 beta, 2023 original aggregate or current AH prices as current drop rates. Highest decision-risk targets: `190311 → 192846/192847/192848` (rank alternatives), `190311 → 192849/192850/192851`, `190311 → 192872/192880/194545`, and `190312 → 192837/192838/192839`. Capture actual completed operations and per-output histogram, skill, specialization, stats, patch, input rank and full reagent units. No shared ledger, canonical registry, source-memory, main or production files changed.
