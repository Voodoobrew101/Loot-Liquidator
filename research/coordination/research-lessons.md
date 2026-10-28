# Research lessons learned — QA-reviewed strategy memory

Generated as a human-readable, master-maintained summary of verified research outcomes. Avoid mistaking agent self-reports for accepted findings.

## Starting hypotheses (NOT scored results yet)

- Original published datasets with actual denominators, skill/patch/rank and input/output IDs are more useful for unconditional expectedQuantity than secondary rate tables without provenance.
- Forum comments and Reddit reports can be useful primary experiments, but count republished spreadsheet links once and distinguish report from validated cast records.
- Blizzard hotfix notes identify patch effects and directions; absent a numeric coefficient or matched pre/post study, no patch multiplier is verified.
- Existing observations should be read before repeated web fetches; recheck sources when an actual update, unresolved gap or contradiction justifies it.
- Never infer occurrence probability from aggregate yield totals, use midpoint of min/max for EV, or let aggregate reward points change evidence confidence.

## Future updates by Master QA

Add date, reviewed claim IDs, accepted/rejected outcome examples, sampling caveats, and specific strategy changes. No self-awarded agent rankings.

## 2026-10-28 — Master batch008 source-strategy QA

- ORIGINAL_DATASET corrected Tontons Platinum/Storm Silver input associations for 26 historical output rows; old archive is derivative, not independent evidence (b008-tontons-correction).
- DENOMINATOR_GUARD: 20-ore mass versus five-ore equivalent is not the same operation (b008-mass-denominator).
- NUMERIC_INVARIANT: three quality-rank alternatives cannot be priced as three simultaneous pigment drops (b008-df-rank-doublecount).
- SOURCE_REUSE: Osulivan six ore table is one experiment; no independent-source inflation (b008-osulivan-reuse).
- PATCH_MATCHING: same-author hotfix anecdotes and historical Felslate recipe comparisons are not current Retail coefficients (b008-midnight-no-credit, b008-felslate-coefficient).
- Source-memory reward feedback never changes numerical confidence; full deterministic Node cache rebuild pending.

## 2026-10-28 — Master batch009 source-strategy findings

Original cast histograms (Carnelian Spikes 50) establish historical P and unconditional E for an exact item, while unknown patch/skill prevents generic current Retail promotion. Historical nubi 288-cast conditional means were internally wrong: recompute from hit counts and totals. Stormvine 21 stacks versus 96 mills requires a source NEEDS_RECHECK state; do not pick the derived 84 as observed. Do not equate mass milling with normal five-herb operations or count multiple herbs from one author as independent studies. Original Jiyao 310 mass casts and two distinct Whiptail commenters are useful field-level evidence, not 2026 patch bridges. Reward validated corrections and negative conclusions without modifying confidence scores.

## 2026-10-28 — Master batch010 independently reviewed lessons
- Exact stable first-pass identity is not a four-field output record: 150 accepted keys included 100 profiles/overlays/token and only 50 output candidates. A self-return output candidate remains quarantined until Resourcefulness vs output is distinguished.
- A rank-unmapped original source must retain family-level totals with null rank IDs (Laving 60 casts), even if the historical database has a rank-1 row. The additive erratum is not an independent new study.
- Historical BfA 20-herb mass milling and 5-herb standard milling cannot be pooled without a verified operation bridge; original authors and mixed skill context matter. Do not use a post-hotfix publication date to place actual casts.
- Current StatYieldProfiles.lua q3 Dragonflight disenchant fallback synthesizes a 100% Vibrant Shard chance without compiled source. Flag as a production migration regression target, not evidence of actual output.
- Existing prospect chance=1-exp(-E) is a Poisson proxy, not observed P(hit); historical TSM P/E contradictions must not be "fixed" by widening tooltip ranges.
- Smelting fixed recipe outputs may have moderately supported four-field values while record-wide current-Retail eligibility remains weak. Evidence confidence is not a measured percent accuracy.

## 2026-10-28 — Master batch011 P0 compiler and source-identity correction
- The first working compiler stages 975 source-backed **provisional** item/output mappings, but 871/975 numeric-complete source tuples are not 871 verified unskilled baselines. Maintain separate denominators and fail closed on patch/skill/eligibility.
- Legacy worker's 76 historical TSM mappings were exact source reuse, not 76 new measurements. The invalid `36721` milling input is a thrown weapon; the actual Dragon's Teeth herb is `3819`. Require item ID/class verification before promoting namesake mappings.
- All 150 batch011 first-pass records were profiles, zero newly measured material output rows. Next queue should prioritize exact candidate output cells, multi-reagent smelt schema and rank-exclusive output QA instead of profile-only throughput.

## 2026-10-28 — Master batch012 material-first compiler QA
- **Original-source discovery produced one real missing mapping** (36910→46849 Titanium Powder) from 150 targeted material-field audits; 0 newly measured current-Retail cast-level outcomes. This is better than treating 150 reviewed profile keys as 150 newly discovered outputs. Historical 12.0.5 gross-ore E=0.715 is explicitly not a 2026 cast denominator.
- **Rank-exclusivity correction had higher decision value than first-pass churn:** 31 Dragonflight pigment rank rows each carried copied family P/E; quarantine 62 numeric cells while retaining item IDs and historical source values. Provisional completeness decreased from 871/975 to 840/976 intentionally; false completeness is worse than transparent unknown.
- **Eligibility can be more important than sample precision:** seven Midnight Eversong Diamond rows require ore-specific Proficient Processor nodes. Preserve conditional mapping, never write zero for unskilled outcomes without actual proof.
- **Recipe vectors are a schema requirement, not a numerical tweak:** 16 Crushing input families need 3 gems + 1 stone and uncertain output rank; refining needs 18 stones, skill 50, tools and bench. Do not force a multi-reagent craft into a single-input prospect model. Fel Iron smelt 29356 uses one reagent type (23424×2), not two types.
- **Source memory input format defect:** six Dragonflight batch012 source-review records use `canonicalUrl/worker/date` rather than builder-required `sourceUrl/workerID/reviewedAt`. Raw records remain immutable and are warned, not silently accepted. Worker must emit a schema-compatible addendum; the five original source-cohort reconciliation rows also need canonical observation schema if intended for the central evidence database.
- **QA feedback and reward points never alter field confidence.** 16 valid worker source reviews and six master feedback events were incrementally replayed; full Node rebuild and Lua/client execution remain outstanding. Future priority: original cast-level data for the missing powder, rank-specific pigment histograms, actual Midnight diamond eligibility, TWW hotfix-stratified byproducts, and recipe-aware compiler support.
