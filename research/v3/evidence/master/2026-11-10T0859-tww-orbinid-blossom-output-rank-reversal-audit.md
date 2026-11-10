# TWW milling — Orbinid / Blossom pigment **output** quality-rank catalog crosswalk (2026-11-10 08:59 UTC)

**Scope:** Manager research-only identity QA of new worker evidence `research/v3/evidence/war-within/2026-11-10T0823-milling-pigment-family-and-arathor-conflict.jsonl` (records 001–008), queue T0010/T0011/T0040 and prior v2 milling candidate rank assumptions. **No new original measured operation/cast study.**

## Independently inspected product identity (Retail catalog, not a cast)

Current GoldCap Retail item pages explicitly label the following **output item IDs** and quality ranks; these are output item identities, **not** a rule that a matching-ranked herb always yields that pigment rank:

| Family | Output quality 1 | Output quality 2 | Output quality 3 |
| --- | --- | --- | --- |
| Orbinid Pigment | [224802](https://goldcap.gg/retail/us/items/224802) | [224801](https://goldcap.gg/retail/us/items/224801) | [224800](https://goldcap.gg/retail/us/items/224800) |
| Blossom Pigment | [224805](https://goldcap.gg/retail/us/items/224805) | [224804](https://goldcap.gg/retail/us/items/224804) | [224803](https://goldcap.gg/retail/us/items/224803) |

Catalog verification: direct GoldCap US pages for all six IDs, including cross-linked rank selectors. EU/TW listings for 224800/224803/224805 corroborate the **same provider's item classification**, not independent experimental validation. Method's [August 10 2024 milling table](https://www.method.gg/guides/the-war-within-herb-milling-and-pigment-guide) confirms the family associations (Orbinid→Orbinid Pigment; Blessing Blossom→Blossom Pigment) and says pigment rank depends on herb quality, Inscription level, and knowledge. Method **does not** establish one-to-one fixed input-rank-to-output-rank mapping.

## Exact conflict in existing *provisional* candidate crosswalks

Existing v2 [submission F004](../../../../research/coordination/v2/submissions/evidence-researcher/2026-10-30T1032Z-F004-tww-milling-skill-rank-submission.json) and [tww_milling_context_sensitivity_v1.js](../../../../research/tools/models_v2/tww_milling_context_sensitivity_v1.js) list provisional tuples:

- Orbinid herb R1 `210802 → 224800` (**actual output R3**, not R1); herb R2 `210803 → 224801` (output R2); herb R3 `210804 → 224802` (**actual output R1**, not R3).
- Blessing Blossom herb R1 `210805 → 224803` (**actual output R3**, not R1); herb R2 `210806 → 224804` (output R2); herb R3 `210807 → 224805` (**actual output R1**, not R3).

Four rank-association labels in those six *scenario candidates* invert the output quality. **Do not silently rewrite them into fixed reverse-rank yields either:** character skill, spec and output rank alternatives were never established by a completed-operation cohort. Rank-aware market pricing could materially differ by output, but no actual-engine pricing, installed version or tooltip regression was tested; do **not** call this a proven live defect.

The new November 10 War Within worker deliberately kept `outputItemID=null` for its eight recipe family records. **That is appropriate:** catalog identities prove possible ranked items exist, not which appears for a particular herb rank/context. Keep the eight worker original/correction records unchanged and identify these six IDs as **candidate output alternatives** only. Existing v2 F004 accepted the reused LotzBoi comment as single lineage/context-only; no re-admission as a new study here.

## Disposition and next field-gate

- **Newly verified for this review:** six retail output `itemID → quality rank` catalog identities (two families × three ranks); four mis-labelled rank associations in *prior v2 provisional same-rank candidate scenarios*; no new source cohort.
- **Still unknown:** input-rank-specific output occurrence/quantity by actual skill, spec, patch and bonus; completed casts, zero outcomes, histograms, net input/resourcefulness refund, expected quantity, chance and per-rank valuation. Historical references/old source counts must remain deduplicated.
- **Next:** ask the existing TWW worker (without changing queues/schedules) to preserve multiple candidate output IDs per herb family, independently capture original rank-linked source itemLinks and completed 10-herb milling output events by skill. Before any economic import, test **all three output ranks independently** with correctly keyed price fixtures and validate output rank identity in actual offline valuation/tooltip; integration branch owner alone controls addon change.
- **Executed:** GitHub original worker/v2 candidate file reads, live catalog page checks, family guide read and static crosswalk comparison. **Not executed:** numeric estimator, compiled ItemDB, Lua/engine/tooltip regression, native game client, in-game professions or CI for this note. No changes to addon, worker evidence, PRs, main, integration branch, or schedules.
