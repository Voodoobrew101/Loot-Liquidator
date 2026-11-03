# Master QA batch013 — candidate v0.3.0, source-rank safeguards
2026-10-28 · branch research/processing-confidence · queue revision 16 · no production changes

## Independent worker review
Four submitted batches (35 Midnight, 35 TWW, 40 Dragonflight, 40 Legacy) were compared against exact queue-revision-15 assignments. **150 material keys reviewed, zero new legitimate mappings, zero new measured current-Retail baselines, zero new first-pass records.** The existing 1,643/1,737 source-inventory first-pass status is unchanged (94 never examined). Do not count follow-up research as new mapping coverage.

- **Midnight:** 16 Crushing family candidates remain blocked by exact rank/reagent/output verification; no invented Gemdust outputs. Refine 1307466 18×242788→1×242789 is a plausible fixed recipe but requires multi-reagent-aware schema/learned-skill confirmation. Historical JD3K aggregates cannot supply zero-inclusive P/min/max. No current neutral numeric promotion.
- **TWW:** 8 fixed smelt recipe vectors reviewed, excluded from single-input compiler pending full reagent cost and eligibility; 13 TWW ore outputs retain historical quantity estimates but lack per-cast P/ranges. Twelve assigned DF quality-specific prospect outputs require P/E quarantine. Unassigned Null Stone 210939 and Handful of Pebbles 213398 prospectability leads require independent ID/recipe verification before adding outputs.
- **Dragonflight:** 38 assigned rank-specific output mappings have historical TSM family P/E reused across quality alternatives. Accepted **38 P and 38 E unknowns** with source claim retention, plus **12 Prismatic Leaper pigment input-quality corrections** (fish 200061 is unranked). TSM original source still preserved. Discovered compiler decoder was hardcoding current-Retail eligibility and dropping the seven Midnight diamond specialization gates; fixed in v0.3.0.
- **Legacy:** 40/40 keys reexamined; Titanium Powder 36910→46849 already accepted in batch012, no double credit. Eight historical source profiles have P>E, violating P(hit)≤E for positive integer outputs; preserved as source conflicts, not silently patched. Independent 2021 Nightshade cohort 3000 herbs→781 Umbral, 712 Luminous, 884 Tranquil, compared with independent 2020 cohort 1640→432,381,501. These are gross-herb-equivalent estimates, not matched current Retail casts.

## Actual compiled candidate and QA
The deterministic compiler **v0.3.0** was executed in a V8 JavaScript runtime against pinned live GitHub inputs; two identical in-memory compilations matched byte-for-byte. Generated research/proposed/itemdb.lua, build report, compiler source, regression test and missing-fields CSV were committed and verified by GitHub file readback. The decoder now reads x[25]/x[26] for eligibility and baseline, rather than replacing the seven previously reviewed Midnight diamond gates with generic status. Node CLI suite, independent Lua interpreter and WoW client execution were **not** performed.

- Candidate: **976 mappings, 159 distinct input IDs**, all provisional; 1,194 original source-line identities verified.
- Four-field numeric complete **791/976 (81.05%)**; 396 unknown field cells of 3,904: dropChance 172, yieldMin 68, yieldMax 68, expectedQuantity 88.
- Rank-specific P/E quarantines this run **50 records/100 cells**, fish input-rank corrections **12**, additionally **2** compiled source P>E probability contradictions quarantined. 8 legacy P>E conflicts are in historical GameData source profiles and were **not falsely counted** as candidate-cell changes.
- Source alternatives 227; exclusions 62: generic DE 52, multi-reagent smelt 8, self-return 1, token choice 1. Historical study and TSM proxy values remain archived. None of 976 records is verified as a 2026 unskilled baseline. 0 full records ≥90, but provisional values below 90 are intentionally permitted.
- The independently exhaustive Retail item/recipe/rank/output universe remains **NOT AUDITED**. 976/976 is compiler-admitted source mapping coverage only, not all legitimate Retail conversions.

## Gold-decision risk
Historical family P/E applied to all three mutually exclusive rank outputs can triple output value; v0.3.0 fails closed on 50 additional affected rows. Fish input rank is not a rank-1 herb. Reagent-aware smelt/refining/crushing cost and current patch eligibility remain blockers. For valuation use only unconditional expectedQuantity per *completed operation*, never P×E or yield midpoint; unknown E is not zero. Current AH prices were not fetched, so no actual auction-vs-convert flip is claimed.

## Source lineage / reward feedback
Nightshade 2020 and 2021 are two independent author/date cohorts but have unmatched recipe/skill/patch and no actual standard-cast denominators; not pooled. Reused historical TSM/GameData is one source lineage, not 150 new experiments. QA-feedback batch013 records accepted safety corrections and blocked numeric claims; no self-awarded reward scores. Central source-memory cache remained at the last 112-source snapshot because full Node rebuild could not be run in the connector-only execution environment; no false freshness claim.

## Next queue
Revision 16 assigns 150 disjoint exact material/recipe keys: Midnight 35, TWW 35 (13 TWW numeric +14 Midnight overflow +8 smelt recipes), Dragonflight 40, Legacy 40 (31 legacy numeric +3 DF overflow +6 Crushing recipe follow-ups). Source-derived gaps take priority over profile-only audits. No new automation schedule or production changes.
