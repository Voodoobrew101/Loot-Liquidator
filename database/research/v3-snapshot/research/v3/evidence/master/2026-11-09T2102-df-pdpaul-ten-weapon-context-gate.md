# Dragonflight disenchant: Pdpaul's 10-weapon aggregate is source-real, but generic gear identity remains unverified

Reviewed 2026-11-09T21:02:46Z UTC. **Original-source text verification and research estimator static trace only; no actual estimator, ItemDB, Lua, tooltip or WoW-client execution.** This review is new to the 2026-11-09T2040 Dragonflight worker submission; it does not replace that worker's append-only record.

## Original measurement confirmed

Source: https://www.wowhead.com/profession-trait/insight-of-the-blue-68402 (original *Pdpaul* comment under *Insight of the Blue*; comment publication date not exposed in consulted indexed content).

Worker record: `research/v3/evidence/dragonflight/2026-11-09T2040-pdpaul-ten-green-weapons-25-dust.jsonl`, `dragonflight-20261109-204001`, original source checked verbatim.

- The writer reports **10 green weapons disenchanted** with **25 Chromatic Dust** obtained. These are source-reported observations, not a reconstructed distribution. On that sample, `25 / 10 = 2.5` dust units per reported disenchant (a source arithmetic *sample mean*, not a new independent experiment, calibrated Retail baseline, chance or conditional yield).
- The writer explicitly states **Draconic Disenchantment maxed**. This is not evidence for an untrained character or for a universal Dragonflight gear-group rate.
- The writer cites combined **778g vendor value** for the ten inputs and **38g 25s AH value** for the dust at the time of writing. Those are *historical prices*, not prices for the player's character/server/current date. The comment does not give a complete item-by-item valuation, material cooutput table or market-price basis.
- It does **not** identify any of the ten input item IDs, their expansion/patch/bonuses/levels, individual material-positive casts, dust stack-size histogram, zero buckets or exact collection date. The source comment is attached to a Dragonflight profession talent page, but that alone does **not** prove every green weapon was a Dragonflight-origin item.
- Separate author opinions about purple-crystal frequency and other materials are unstructured anecdotes, not an observed `castsWithDrop` numerator; keep that probability, any cooutput quantities and zero-inclusive outcome partition **unknown**. No measured Resourcefulness, recipe rank, or source build follows from this comment.

## Record-to-estimator admission risk

The new worker record contains `gearGroup={expansion:"Dragonflight",quality:"uncommon",kind:"weapon",itemLevelRange:null}`, `sourceKind:"study"`, `casts:10`, `totalQuantity:25`, `outputItemID:194123`, no item-specific input ID. The expansion-classified gear group is a **reasonable research lead, not original-source proof**.

Static review of current `research/v3/tools/build_estimates.py` (blob `0b09b553fef4214af8aaa93f1c85061956643711`): `key_of` prioritizes any nonnull `gearGroup` over `inputItemID`; `analyze` routes study rows into that keyed group. A future estimate could therefore treat these ten *unspecified* source weapons as a generic `Disenchant / Dragonflight uncommon weapon / Chromatic Dust` cohort unless later applicability gates reject the input context. This is a **static possibility**, not proof that current addon runtime/tooltip or saved compiled DB contains the row.

**Disposition:** preserve the worker's genuine ten-operation, 25-unit source observation and maxed-spec condition; do not invent chance, rank, histogram, price or complete value. Hold generic character-independent Dragonflight gear-group admission until input era/item identities and applicable specialization scope are justified. If subsequently admitted for a supported, correctly scoped profile, valid expected quantity can contribute to valuation with chance/range shown unknown, under the owner's Nov 2 policy. Research-only source review must not overwrite the protected `implementation/usable-data-tooltips` branch.

**Targeted follow-up:** recover the original comment's date and at least one of the ten weapon item links/ilvl/bonus or an independent linked completed-operation export; then decide if all ten share a compatible Retail gear group and source epoch. Preserve the original studyKey and avoid counting localized mirrors as new experiments.

**Actual validation:** read worker JSONL, source text in original English page, independently searched source mirrors, inspected estimator `key_of` and `analyze` code paths. **Not run:** `analyze()`, compilation, synthetic price valuation, tooltip rendering, full tests or WoW client. Newly collected observed operations **0**; newly verified worker-sourced aggregate **10 operations / 25 dust**; new supported gold recommendations **0**; new rendered tooltip fields **0**.
