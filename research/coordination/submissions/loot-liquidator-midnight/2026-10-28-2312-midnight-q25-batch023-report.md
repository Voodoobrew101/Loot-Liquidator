# Midnight q25 Batch 023 — calculator formula audit and 25 exact numeric-gap keys

**2026-10-28 23:12 PDT | branch research/processing-confidence | research only | assignment 2026-10-28-batch023-midnight | queue revision 25**

## Scope and result

- Audited **25/25** exact master-assigned keys, all matched to GameData.lua source lines 727–799. Seven Eversong Diamond records and 18 gem/byproduct records; **82 compiler-missing field cells** (7×4 + 18×3). All **100/100 exact-current-context P/positive min/positive max/unconditional E fields lack independent measured proof**; 18 source-level provisional E references already exist but are not newly verified current-Retail values.
- **0 new legitimate input→output mappings, 0 verified current-Retail numeric fields, 0 new original measured cohorts.** Queue25 is a gap revisit, not new first-pass coverage.
- One previously unindexed **derivative April 2026 Google Sheets prospecting calculator** was downloaded and its formulas inspected. Author explicitly used hardcoded guide rates; it does not support independent P/min/max/E. Full evidence in accompanying observation file.
- One actionable P2 finding: with 5,000 Copper Ore and 7% Resourcefulness, spreadsheet projects 46 Eversong Diamonds vs its own baseline 25, because it adds +0.021 expected units per cast indiscriminately to each output. **84% inflated diamond estimate**; also fails to gate diamonds by ore-specific specialization. Not a measured yield, and not a validated Retail Resourcefulness coefficient.
- Original 2026 Blizzard gem-frequency hotfix and HeadtripVee pre-hotfix cohort are already in master source-memory and were reused for context only. Their provenance is independent of the derivative spreadsheet; they are not counted again as new studies.

## Four-field decision

All 25 records retain null for exact-context dropChance, positive yieldMin/yieldMax, and unconditional expectedQuantity; zero means UNKNOWN, not a numerical zero. Source GameData low/high proxies are recorded separately and never converted into measured P or E. No five-ore arithmetic is used to fabricate completed-cast denominators. No rank-exclusive output rows are summed as simultaneous guaranteed drops. No universal profession coefficient or Resourcefulness-to-output transfer is accepted.

## Source review and feedback applied

Read live queue25 assignments, latest master batch022 verdict, source-memory (190 canonical URLs at review), research-lessons, latest q24 worker source-review schema and source evidence. Master rejected re-auditing derivative TSM rows and transferring historical ranks without zero-inclusive cast counts; this run tested a previously unindexed calculator's actual formulas instead. The negative result is useful: it prevents importing an apparent skill/resourcefulness calculator as a measured source.

## Next exact IDs

1. **Diamond specialization/rank and zero-inclusive completed-cast data:** `237359→242608`, `237361→242608`, `237362→242608`, `237363→242608`, `237364→242608`, `237365→242608`, `237366→242608`.
2. **Copper rank-separated gems/byproducts:** `237359→242553/242554/242606/242607/242786/242788`; `237361→242553/242554/242606/242607/242786/242788`.
3. **Tin rank-separated gems/byproducts:** `237362→242606/242607/242610/242611/242786/242788`.

Seek post-hotfix actual completed-cast histograms including zeros, actual client patch, input rank, effective skill, spec nodes, reagent refunds and output item IDs; do not reuse the spreadsheet's modeled values as observations. Master may reassign after QA. No master ledger, production Lua/TOC, source-memory or schedule changes.
