# Loot Liquidator — War Within worker q23 / batch021 (Dragonflight overflow)
**2026-10-28 · research/processing-confidence · research-only**

## Queue / feedback
Read LIVE assignment revision **23**, `2026-10-28-batch021-war_within`, master batch020 QA verdict, source-memory, research-lessons and recent q22 worker/source-review changes before this submission. Master expressly assigned **45 Dragonflight overflow exact keys**; no native TWW key is assigned this run. The previous q22 War Within 32/35 repeats prompted this nonrepeating allocation. Worker did not self-claim other keys.

## P0 legitimate mappings and recipe/rank
**45/45** exact pinned GameData source lines and input/output IDs verified: 25 Draconium R3 `190311`, 20 Khaz'gorite R1 `190312`; 34 distinct outputs, 42 target-rank-annotated rows. Five ore per nominal Dragon Isles Prospecting recipe `374627`; actual 2026 recipe eligibility/skill and completed cast outcomes unverified. These 45 are existing TSM-derived candidates, **0 newly discovered legitimate mappings**. Ranks are imported source claims, not current Retail skill-gated proof.

## P1 four-field audit
**180 exact-context numeric slots: 180 unknown; 0 new current Retail P, positive min/max or unconditional E.** Each null has confidence 0 and explicit blocker. 90 imported `minAmount/maxAmount` source references retained separately, **not** promoted to measured positive yield bounds. Historical TSM `matRate/amountOfMats` remain raw source columns with unverified units. No zeros, midpoint E, Poisson P, rank transfers or unreported cast counts invented.

## P2 economic and source-semantic risk
**45/45 source rows** would violate P<=E if `matRate` were misread as occurrence P and `amountOfMats` as unconditional per-cast E (positive integer yield). These columns cannot jointly serve as the requested fields without importer documentation. Repeated rank-family rates create overvaluation risk if all alternatives are priced simultaneously. Actual gold-optimal flips **not** established without matched source semantics, current auction prices and profession state.

## Source lineage / learning
Reused the original Jallfo 2022 beta 3-character study and previously archived observations for `190311`; its derivative Wowhead summary is not a second study. Three 5,000-ore cohorts are **initial ore counts**, not completed-cast denominators. Source sheet has output family/rank labels but no embedded item IDs; preserved unmapped raw aggregates. A new look at the 2026 web sources found item identity and rank context, not a new current Retail output study. Useful negative conclusion: 45 potential P/E misinterpretations blocked. No reward points applied to confidence. Avoid re-fetching Jallfo without new data.

## Exact next IDs / master handoff
`190311 → 192846/192847/192848`, `190311 → 192849/192850/192851`, `190311 → 192872/192880/194545`, `190312 → 192837/192838/192839`. Request current Retail per-cast zero-inclusive histograms at specified rank, skill, inspiration/resourcefulness, patch and exact recipe units. Assignment exhausted for q23; request master reassignment, not self-claim.

## Validation and protections
45 unique exact assigned keys, 45/45 source-line checks, 180 null field objects with confidence zero, 0 invariant failures in promoted numeric data; 45 hypothetical source-column P/E violations flagged. No Node CLI, Lua or client tests. No production Lua/TOC, main, shared assignments, master ledgers, canonical registry, source-memory or schedules edited.
