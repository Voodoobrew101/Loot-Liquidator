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

## 2026-10-28 — Master batch013: decision-value-first corrections
- Four worker submissions audited 150 previously assigned material keys but discovered **zero new legitimate mappings and zero new current-Retail measured cast datasets**. Do not equate review volume with database expansion.
- 50 ranked Dragonflight output rows contained unverified family P/E copies; quarantine both cells and preserve source lineage. Fish 200061 has no input quality rank. Retain historical TSM family totals only as reference, not per-rank valuation.
- Two remaining compiler P>E contradictions were caught by a new invariant; eight additional legacy source-profile conflicts remain outside the selected candidate and must not be silently promoted.
- Compiler decoder metadata can diverge from intermediate JSON: regression-test generated Lua x[25]/x[26] so seven diamond specialization gates survive serialization.
- Assign exact missing expectedQuantity first, then P/ranges and multi-reagent recipe vectors. New Nightshade historical cohort has no matched cast denominator; historical corroboration is not a Retail skill/patch bridge.

## 2026-10-28 — Master batch014 recipe-vector and rank-specific gold-risk QA
- **P0 return per worker effort:** 150 assigned material keys → 8 previously excluded legitimate fixed-output recipe vectors admitted (not newly discovered) + 7 unsafe Dragonflight expectedQuantity cells quarantined + 1 new uncompiled glass-refining recipe lead; **0 new current-Retail measured cast studies**. Distinguish mapping admission, safety corrections and independent measurements.
- **RECIPE_VECTOR_GUARD:** All eight direct smelting vectors match pinned GameData lines 675–682 and worker independently researched skill/forge/learned gates. First reagent is ONLY a lookup anchor; full cost vector must be priced or no recommendation. Hardened Khorium requires rare teaching item 35273. Historical recipe fixed output is modeled, not observed current-client proof.
- **RANK_AND_DENOMINATOR_GUARD:** Seven retained DF exact-rank/gross-input E references were unsafe to value; quarantine even when this reduces numeric completeness. Preserve two existing P>E source conflicts after E becomes unknown, or compiler order can resurrect invalid probabilities.
- **SOURCE_REUSE:** Reusing JD3K, PeaEsk, Deckven and TSM is efficient for contradiction detection but does not add independent cohorts. Traziz is a separate author/cohort but not a matched historical numeric transformation. Worker source-memory remains stale until full Node rebuild; no invented freshness or reward effects.
- **NEXT STRATEGY:** 16 Crushing + two refining recipe-ID audits, full 2026 smelt eligibility, and 49 previously unassigned Dragonflight missing-value rows take priority over repeating the same 150 source-only references. Keep disjoint assignments and direct gold-impact evidence questions.

## 2026-10-28 — Master batch015 material-first strategy

Ten provisional mappings per 150 reviewed keys (6.7%), zero new current-Retail measured cast cohorts. Eight TWW Gem Finding outputs and two fixed recipes are not ten independent studies. Method guide secondary; Oct 2024 Aqirite and Jan 2023 Draenei original historical cohorts, forum mirror derivative. Do not double count old smelts. Prioritize exact Gem Finding node thresholds, zero-inclusive output-rank histograms and Midnight Crushing salvage whitelist; preserve full refining reagent costs.

## 2026-10-28 — Master batch016 evidence efficiency and compiler safety

- **Accepted newly legitimate conversion mappings / worker material keys:** 0 / 150; do not reward re-examining the same TSM or low/high rows as fresh coverage. Reassign 16 uncompiled Crushing recipe families and missing expected-quantity/rank cells, rather than repeating profile-only audits.
- **Source lineage correction:** independent Primer three-cast fish report yields Serene Pigment R2 **198413**, not Blazing Pigment R2 **198419**. An immutable original observation may be corrected through a master-owned deterministic attribution overlay without deleting other possible mappings. A separate TSM output relationship is not evidence that the original author observed it.
- **Numerical denominator:** 15 fish / 5 per operation = 3 actual casts supports descriptive historical E=5/3 Flourishing R2 and 2/3 R3, but a three-cast cohort is not a 2026 unskilled baseline. By contrast Almar Titanium 121 powder has **no ore denominator** and therefore no E. Initial ore / 5 is not a cast count if Resourcefulness or refund recycling is involved.
- **Reused versus new:** Primer and Cardinalai are reused originals, not new studies. Two TWW commenters in one thread are separate author cohorts but neither is patch/skill matched. Almar is a new original raw-total source with no denominator. Method guide, TSM and reposts are derivative/context sources, not independent replications.
- **Tooling reliability:** source-memory replay must canonicalize URLs consistently; descriptive originalDocumentRef labels are not URLs. Replaying q17/q18 sources exposed two duplicate slash variants and required a deterministic merge. Full Node directory rebuild remains preferable when a complete repository checkout is available.
- **Mapping-gap bookkeeping:** a compiled provisional refining recipe should not remain labelled CANDIDATE_NOT_COMPILED. Distinguish staged mapping coverage from in-client recipe eligibility verification. Do not inflate 100%-known-admitted coverage into an exhaustive Retail-universe claim.
- **Next allocation:** Midnight 16 Crushing + 19 numeric; TWW 21 native + 14 DF overflow; DF 40 rank-specific; Legacy 31 historical + 9 BfA/WoD milling. Prioritize records where a missing E or omitted reagent could change the liquidation decision.

## 2026-10-28 — Master batch017: recipe identity and denominator QA

- Jiyao's original revised BfA study gives 177/106/103 completed **20-herb mass** operations, not five-herb standard operations. Nine historical recipe/output rows from one study were compiled separately; rounded means retain ±0.005 reporting uncertainty and current-Retail eligibility remains unverified.
- Queue19 workers independently reviewed 150 exact keys and 120 GameData output-line IDs, but supported **zero new current-Retail numeric fields**. Queue20 prioritizes 68 previously unassigned gaps, 9 new mass recipe rows, and source conflicts rather than repeating source-only profiles.
- Dragonflight beta skill 250 **guarantees** R3, not prohibits R3 below 250. Preserve immutable interpretation erratum and reject unverified universal skill coefficients.
- Never divide 20-herb mass yields by four and call them observed standard five-herb E. Keep actual completed casts, nominal input normalization and Resourcefulness savings distinct.
- Full source-memory rebuild needs 95 JSONL files and hit connector tool-call ceiling. Incremental q19 replay is labelled, not presented as a full Node rebuild. Reward points remain separate from evidence confidence.

## 2026-10-28 — Master batch018: source-unit and original-wording correction

- Actual compiler replay generated **byte-identical** v0.6.0 Lua from live inputs; zero new source-backed current-Retail fields justified changing the staged candidate. This is useful QA, not a version increment.
- **Original-source wording matters:** Dragonflight original Reddit commenter wrote “3.8 herbs per mill,” not pigments. Reject a pigment-E promotion; corrected worker erratum accepted. Likewise 0.19 < 0.2005, not greater.
- **Two independent Osmenite authors, not two casts:** 16,760 and 6,800 gross ore yield Sage 265 and Azsharine 264; normalized five-ore equivalents 0.0562394 and 0.0560272, respectively. TSM 0.165 raw matRate is a source-semantic mismatch candidate, not a current Retail measured E. Reused studies yield no new verified current fields.
- **Throughput:** 150/150 unique exact material/recipe keys audited; 136/136 original GameData lines matched; 224 historical numeric references and 376 unknown cells; zero newly verified current fields. Reward useful negative conclusions but move queue21 toward **unassigned E/P gaps and exact Crushing eligibility**. Nine BfA mass-cast outputs were already compiled in batch017, not nine new q20 records.
- Keep no invented rank transfer, five-to-twenty-herb operation equivalence, hidden profession coefficient or gross-ore-as-cast denominator. Full Node source-memory rebuild remains outstanding.
