# Boulderfist historical source-unit and reference-hit intake audit — 2026-11-18 18:02 UTC

**Scope:** research-only, no addon edit, new Retail valuation, imported rates, or current-character eligibility finding. Investigates the Legacy worker's newly filed exact-item historical source leads after its 17:53Z completed run. Original source rows remain unchanged.

## Sources and immutable reads

- Worker original: `research/v3/evidence/legacy/2026-11-18T175329-boulderfist-three-item-original-looter-hits.jsonl`, blob `38061965620f0cfb68a7ca0ac72e78c8b85bd1fd`; 10 rows, three input IDs, each `sourceKind=reference`, `percentShown/averageShown/totalQuantity/histogram=null`, with `casts` and `castsWithDrop`.
- Existing estimator: `research/v3/tools/build_estimates.py`, blob `0b09b553fef4214af8aaa93f1c85061956643711` (examined reference-prior handling and no-chance skip).
- Source worker claims: [Boulderfist Legplates 24987](https://www.wowhead.com/item=24987/boulderfist-legplates#disenchanting), [Boulderfist Armor 24984](https://www.wowhead.com/item=24984/boulderfist-armor#disenchanting), [Boulderfist Greaves 24983](https://www.wowhead.com/item=24983/boulderfist-greaves#disenchanting); pooled mutable item-side Looter tables, **not** independently dated character casts.
- Independent historical *reference* context checked 2026-11-18: [The Burning Crusade item-level 102–120 armor disenchant table (patch 2.4.3)](https://legacyofwarcraft.com/db/tbc/professions/disenchanting.html) gives Arcane Dust 75% (2–5), Greater Planar Essence 22% (1–2), Large Prismatic Shard 3%; [archived Boulderfist Legplates item page](https://wowwiki-archive.fandom.com/wiki/Boulderfist_Legplates) instead prints Arcane Dust 22%, Greater Planar Essence 75%, Shard 3%, an *inverted armor/weapon-style percentage attribution*. Treat these historical sources as **conflicting**, not measured or modern Retail probabilities. The archive was search-index-readable; direct page fetch was restricted.

## Exact new three-item comparison

| Source input | Looter reported item-side operations | Arcane Dust 22445 hits | Greater Planar 22446 hits | Large Prismatic 22449 hits | Lesser Planar 22447 hits | Total material hits | Operations minus listed hits* |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 24987 Legplates | 1,550 | 1,092 (70.452%) | 336 (21.677%) | 63 (4.065%) | 23 (1.484%) | 1,514 | 36 |
| 24984 Armor | 1,726 | 1,150 (66.628%) | 456 (26.419%) | 82 (4.751%) | — | 1,688 | 38 |
| 24983 Greaves | 1,951 | 1,515 (77.652%) | 355 (18.196%) | 51 (2.614%) | — | 1,921 | 30 |
| **Distinct input-source totals** | **5,227** | | | | | **5,123** | **104** |

*The residual is **not 104 observed no-output casts**. It is arithmetic across source-reported per-material occurrences and may include unlisted outputs, missing records or inconsistent event/context tracking. A source-specific event ledger is needed to infer any actual zero-yield operations or co-occurrences. Never sum item denominators separately per output as independent studies.

The 24987 **Lesser Planar Essence 22447** row is absent from the 2.4.3 historical level-102–120 armor reference, which lists Greater Planar but not Lesser Planar. Coupled with differing indexed item-level variants and unknown at-cast itemLink/bonus/build, this is an **era/variant conflict**, not proof of a new Retail output or source error. Eight of the 10 worker rows carry displayed `minSeen/maxSeen` spans, but original individual positive-stack logs were not recovered; do not label those empirical extrema or calculate output quantity from them. Distinct 2.4.3 reference table and old per-item archive disagree on dust/essence allocation, so no silent averaging.

## Actual numeric-ingestion finding

The present estimator routes `sourceKind=reference` rows into `g["refs"]`. In `analyze()`, `ref_p_rows` admits `chance_from_percent(r)` only when `percentShown` is present with `percentMeaning=perCast`; `ref_e_rows` admits only `unit_average`, requiring `averageShown`. It does **not** use `castsWithDrop/casts` for a reference chance. Therefore **none of these ten new occurrence numerator/denominator pairs can contribute a chance prior under this code path**. A displayed reference range might affect an already-supported group; never claim all groups now have zero coverage. This is a specific **usable-source-field not normalized/imported** case, distinct from missing material prices and from invalid current Retail eligibility. Do not relabel these pooled references as independent measured `study` samples to force numerical acceptance.

**Safe proposed research-only follow-up:** introduce a provider-aggregate reference incidence representation with explicit `positiveOccurrences`, `sourceReportedOperations`, `sourceEpoch/atCastVariant` unknown, and `displayStackSpan` distinct from `observedRange`. A narrowly gated adapter may expose a labeled historical/reference P(hit) for eligible matching contexts, **never** count it as measured casts or create E[units]/P(hit) for current Retail without a valid context bridge. If a genuine source-proven conditional yield model becomes available, compute an explicitly provisional E[units] separately under owner policy. Preserve original numerator, denominator and identity for dedupe.

## Checks actually performed

**93/93 bounded in-process JavaScript assertions passed** on the exact original JSONL and estimator source: ten source rows; method, source-kind and original URLs; numerator bounds and shared item denominators; null totals/means/histograms, unknown ranks; unique material IDs; code's actual reference-prior predicates and missing-chance skip; reported hit totals not exceeding item counts. The independent 2.4.3 table and archived source snippet were also read through indexed web retrieval. **Not executed:** Python estimator, compiled ItemDB, real Lua gold engine, tooltip, addon tests, live WoW or newly triggered GitHub CI. No observed new player casts, rank-scoped yields or economic decisions; no no-disenchant assertion.

**Next priority:** retain Midnight post-release `237362` x5 ranked 0–N material/refund/skill event data and `236761` x10-herb completed milling events as the highest-impact missing numeric originals; only then revisit historical Boulderfist source-era compatibility. Engineering may use this exact ten-row fixture on an isolated branch without modifying the owner's three-pass addon branch.
