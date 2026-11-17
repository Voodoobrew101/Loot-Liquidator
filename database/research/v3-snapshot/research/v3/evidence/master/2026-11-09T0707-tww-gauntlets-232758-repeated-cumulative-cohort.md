# T0048/T0040 — Gauntlets of Lost Inspiration cumulative-source double transcription

Verified at 2026-11-09T07:08:50.440Z against repository branch `implementation/five-agent-completion` parent `507ca20a3f205b0b52c2f12d91cfd29117e04753`.

## Original-source identity and evidence
The Nov 9 worker file `research/v3/evidence/war-within/2026-11-09T0633-goblin-blade-gauntlets-de-conflict.jsonl` record `war-within-20261109-0633-002` records a **name-only** input **Gauntlets of Lost Inspiration**, `34/93` rank-2 Storm Dust 219947 positive *material occurrence* counts, output units unknown, source `https://www.wowhead.com/ptr/item=219947/storm-dust`, studyKey `wowhead-ptr-219947-input-gauntlets-lost-inspiration-one-cumulative-table`.

The Oct/Nov migration-era worker file `research/v3/evidence/war-within/2026-11-02T0051-r2-dust-looter-and-eligibility-conflicts.jsonl` record `war-within-20261102-0051-010` already identifies **the same named gear input as itemID 232758**, material 219947 and **the same 34/93 counts** from **the same PTR-hosted source page**; its prior studyKey is `wowhead-looter-219947-input-232758-cumulative`. The [German Wowhead item catalog](https://www.wowhead.com/de/item=232758/stulpen-der-verlorenen-inspiration) independently confirms item **232758** equals this named plate-hand quest reward, while [Cease and Desist](https://www.wowhead.com/quest=83446/cease-and-desist) independently anchors the reward name.

This is **one repeated cumulative source cohort**, not a new set of 93 independently measured disenchant operations. Different studyKeys and a null inputItemID in the newer row can prevent naive exact-key deduplication; whether the current estimator actually double-counts requires executing its current ingest/dedupe and offline valuation tests. Neither occurrence numerator is total item units, a zero-inclusive operation distribution, live Retail eligibility nor proof of actual character or patch. Do not sum 34+34 hits or 93+93 casts. The separate 238251 19/50 reference in the same new file is **not** identified as a copy by this audit.

## Disposition
- **Identity correction candidate:** `newer.inputItemID` should be associated with **232758**, but preserve worker-owned append-only originals and let the worker/validation owner issue a sourced replacement or canonical study alias.
- **Duplicate cohort guard:** canonicalize to one original PTR Looter item 232758 / material 219947 / 34-of-93 snapshot; compare sample epoch and source ID before future weighting. Do not take two independent counts merely because record IDs, studyKeys or source files differ.
- **Remaining unknowns:** per-operation material quantities, positive-stack/zero histograms, item bonus/ilevel at collection, game client build and character Enchanting skill/specialization, independent actual-cast log, current eligibility and prices. No numerical field or gold recommendation is promoted.
- **Validation:** GitHub source-file content and exact counts were directly read, plus independent item catalog web search. No compiler, local Lua, actual offline tooltip rendering, or live WoW was executed here.
- **Next:** add a research-only duplicate-alias regression in an authorized scoped validation branch or hand to the existing validation owner; protect `implementation/usable-data-tooltips` and worker file ownership. New raw Midnight current-patch 0..N logs remain higher-priority numerical research.

