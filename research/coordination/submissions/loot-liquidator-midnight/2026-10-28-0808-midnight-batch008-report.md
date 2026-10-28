# Midnight worker — numeric follow-up, 2026-10-28-0808-midnight-batch008
**Research branch head before writes:** `73b0c03260882322bb7454e4773fc8daaf079005`
**Master queue:** revision 9, assignment `2026-10-28-batch007-midnight`, 35 keys. The existing batch007 audit/report already submitted those exact keys. **Do not resubmit or claim first-pass credit.** Queue has not assigned a new disjoint batch; nextBatchPreview is empty.
**Item first-pass this run:** **0 new keys** (no unauthorized overflow). **Numeric hypothesis investigated:** 1, still BLOCKED. **New original-source lead:** 1 same-author two-date comparison, not two independent experiments.

## Finding
The SAME forum account (Jacara-3179955) reported **6 unspecified gems from 400 ore** on March 22, before the March 31 hotfix, and on April 10 estimated **15–20 unspecified gems per 100 ore** with nodes maxed. Links: https://us.forums.blizzard.com/en/wow/t/prospectingcrushing-needs-a-huge-buff/2274222 and https://us.forums.blizzard.com/en/wow/t/jc-glimmering-gemdust-is-disgusting/2272506.
Ore-normalized descriptive values: 0.075 versus 0.75–1.00 gem units per five ore, an apparent 10–13.33-fold range **which is not a causal hotfix coefficient**. Ore IDs, ranks, recipe, output IDs/ranks, cast denominators, refunds and matched character conditions are missing. April 10 is an approximate anecdotal rate without a sample size; the same author may have changed ore or setup. No statistical interval or per-cast occurrence can be calculated. Preserve this as an unmapped source lead, not a schema-compliant numeric observation.

## Independent QA
- PASS pre_rate
- PASS post_low
- PASS post_high
- PASS descriptive_ratio_low
- PASS descriptive_ratio_high
- PASS source_count
- PASS no_unverified_id
- PASS no_coefficient
- PASS no_false_cast_count
- PASS fail_closed
- PASS no_master_review
- PASS one_hypothesis
**12/12** deterministic in-memory assertions. JSON candidate serialized and parsed; schema shape manually compared to required top-level/scope/source/review keys, but **external JSON Schema validator, Node repository suites and WoW client not run**. No source numeric formula verified.

## Master handoff
- Numeric candidate: `research/coordination/submissions/loot-liquidator-midnight/2026-10-28-0808-midnight-batch008-numeric-candidate.json` (BLOCKED, no parameters, 20/100 *research evidence confidence*, not error margin).
- Original-source note: `research/evidence/observations/2026-10-28-0808-midnight-batch008-same-author-source-only.md`.
- Missing exact next experiment: matched pre-2026-03-31 and post-hotfix casts, same ore ID/rank/recipe/skill/spec/gear and exact patch/build; output IDs/ranks, per-cast zeros, Resourcefulness saved ore, independently replicated.
- Remaining first-pass: latest master baseline **809 NEVER_EXAMINED at queue rev9**, before any master acceptance of batch007 or concurrent submissions. Cannot safely decrement without a new master ledger.
- Zero verified numeric rules, zero new >=90 fields, zero current-Retail corrections. No production Lua/TOC, central ledger, master queue, master progress or merge touched.
