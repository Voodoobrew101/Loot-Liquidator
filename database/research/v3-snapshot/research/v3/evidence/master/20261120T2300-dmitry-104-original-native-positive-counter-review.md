# dmitry_popov original native 104-row Enchantrix review (2026-11-20 22:59 UTC)

## Decision
Research-only original-source integrity VERIFIED for the Legacy worker's additional 104 historical positive-only material counters. They are **not** 104 independent studies, do not establish current Retail eligibility, and cannot contribute measured P(hit), measured completed-cast denominators, unconditional per-operation expected quantities or confident gold decisions. Preserve as labeled historical `sourceKind=reference`; do not convert counts of positive material occurrences into all-operation cast counts. No new game testing, crafting or purchases.

## Exact pinned inputs
- New evidence: [research/v3/evidence/legacy/2026-11-20T2238-dmitry-untranscribed-high-hit-native-counters.jsonl](https://github.com/Voodoobrew101/Loot-Liquidator/blob/60d002c452ca908e8cfdb5bbf2746e92017b63ad/research/v3/evidence/legacy/2026-11-20T2238-dmitry-untranscribed-high-hit-native-counters.jsonl), blob `c83fb1d5c6d7d2ca42a077c913da32291bbb0991`; 104 JSONL drop rows
- Earlier same-contributor 91 drop rows (+1 token): [research/v3/evidence/legacy/2026-11-20T1640-dmitry-native-classic-and-valorous-45661.jsonl](https://github.com/Voodoobrew101/Loot-Liquidator/blob/60d002c452ca908e8cfdb5bbf2746e92017b63ad/research/v3/evidence/legacy/2026-11-20T1640-dmitry-native-classic-and-valorous-45661.jsonl), blob `c3c0187762fd7eb7de533ddae6b62063fecc85e0`
- Author's native SavedVariables: [dmitry_popov.lua](https://github.com/alex-berliner/wow_classic_de_table/blob/5918ca3e44f6e4bba9071731ab28be3189498001/dbfiles/dmitry_popov.lua), immutable upstream revision `5918ca3e44f6e4bba9071731ab28be3189498001`
- Native item-name crosswalk: [item_names.csv](https://github.com/alex-berliner/wow_classic_de_table/blob/5918ca3e44f6e4bba9071731ab28be3189498001/item_names.csv), same immutable upstream revision
- Source research branch checked at `60d002c452ca908e8cfdb5bbf2746e92017b63ad`. No source record or imported generated addon DB modified.

## Independent checks executed (source-to-row, not ItemDB)
1. Parsed all 104 JSONL records and the previously recorded 91 drop records.
2. Indexed the native Lua item-variant -> semicolon-separated material counters; independently matched **104/104** exact `variant -> output ID:positive count:output units:terminal 0` tuples.
3. Independently checked **104/104 input names** and **104/104 material names** against pinned original CSV.
4. Zero same-`studyKey+outputID` duplicates within the 104 new rows; **zero overlap with the earlier 91** rows from the same contributor. This is new transcription coverage, not independent cohort evidence.
5. Source summary: **50 exact gear variants**, **48 distinct input IDs**, **18 output IDs**, **531 material-positive sightings**, **1029 material units**. The same contributor's two evidence files must remain linked, not treated as independent contributor samples.
6. All 104 `casts=null`, `sourceKind=reference`, `histogram=null`, `percentShown=null` as intended. `castsWithDrop` stores native material-positive counters only and is not a denominator. Native trailing `:0` is not an observed zero-outcome cast.

## Admission/gold implications
The missing denominator, full 0..N event histogram, actual character skill, exact suffix/bonus/ilvl context, historical Classic vs Retail applicability, and overlap with other contributors' compiled summaries prevent direct current-Retail chance or expected-gold claims. A source-identity check is not exact-SHA build review. Keep distinct input savings, quantity, occurrence and quality; do not infer any probability, operation count or current-item eligibility.

**Validation boundary:** performed read-only independent original-source comparison using GitHub connector and JavaScript; no native `tools/prepare_build_research.py`, `tools/research_build_review.py`, ItemDB compilation, Lua/tooltip synthetic-price test, live WoW validation, new worker task or schedule change.

**Next priority:** seek genuinely completed **current-Retail** zero-inclusive prospect/mill/disenchant operation cohorts with explicit rank, skill, refunds, patch and output ID; separately audit exact-pinned build-review admission of these positive-only rows in scoped implementation, without touching owner's three-pass branch.
