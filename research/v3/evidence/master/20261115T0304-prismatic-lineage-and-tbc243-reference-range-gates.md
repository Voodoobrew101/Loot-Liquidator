# Coordinator QA — Prismatic original-cohort lineage and TBC 2.4.3 modeled-stack retention

Audit: 2026-11-15 03:04 UTC. Research-only source/identity and static compiler trace. No new live Retail cast, price, eligibility, or tooltip result.

## 1. Dragonflight: new v3 row is an already preserved original cohort, not an independent new sample

Read Dragonflight worker's new `research/v3/evidence/dragonflight/2026-11-15T0235-prismatic-comment-and-original-histogram-check.jsonl` record `dragonflight-20261115-9501`: source commenter, [January 10 2023 Reddit thread](https://www.reddit.com/r/woweconomy/comments/108782r), says **25 Illimited Diamonds from 1,000 Prismatic Ore**. Input item **194545** is correct, as separately confirmed in the [Prismatic Ore item catalog](https://www.wowhead.com/item=194545/prismatic-ore) and [Warcraft Wiki](https://warcraft.wiki.gg/wiki/Prismatic_Ore). The statement has no observed per-cast count, material-positive hit count, histogram, rank IDs, refunds or build.

**Verified pre-existing record for this exact cohort:** immutable `research/evidence/v2/2026-10-30T2028Z-F004-df-two-stage-diamond-denominators.json`, cohort `B-prismatic-1000`, records the same **verbatim 25/1,000 source statement at the same Reddit URL**, with lineage `reddit-108782r-comment-B-prismatic-1000-25-diamonds`. Its input ID was erroneously **192880** (Crumbled Stone). The already recorded, separate correction in `research/evidence/v2/2026-10-30T2130Z-F004-df-prismatic-identity-and-primary-ore-cohorts.json` sets the intended input to **194545**; this is an **identity correction, not a second study**. The 2026-11-15 v3 row correctly uses 194545, but its `studyKey` differs from the v2 source-lineage ID. No v2 evidence was rewritten or destroyed.

**Disposition:** 1 existing historical first-person cohort (25 output units / 1,000 reported *nominal* Prismatic Ore inputs); **0 newly independent source cohorts** from the new v3 transcription. For reference only, 25/1000 = **0.025 diamond units per reported ore unit** or 0.125 per *nominal* five-ore equivalent. Neither expression is an observed P(hit), 200 completed casts, material-rank mean, current Retail rate or verified character-specific EV. Preserve original text, old mistaken identity with its correction trail, new v3 transcription and source pin. Add common cross-schema lineage/dedupe key only through a reviewed correction or migration fixture if v2 and v3 are ever compiled together; **do not exclude the sole useful v3 row merely for having a historical v2 ancestor**. The current `research/v3/tools/build_estimates.py` loads only `research/v3/evidence/**/*.jsonl` and does **not** compile v2 JSON files, so current double weighting was **not** demonstrated.

The catalog also contains an older *separate* original `superbondez` report of 400 Prismatic Ore / 80 reported prospects and rank-tagged diamonds. This was already indexed in `research/coordination/source-memory.json` and the 2026-10-30 v2 correction; it was **not** recopied or added as a new cohort. No original spreadsheet or event log in this lane supplies missing 0..N histogram/Resourcefulness context.

## 2. New legacy game-data model: exact supported reference quantities are stranded in prose

Independently opened the [patch 2.4.3 original derived disenchanting table](https://legacyofwarcraft.com/db/tbc/professions/disenchanting.html). It explicitly defines a **historical game-data model**, not 11,018 measured disenchants (the 11,018 are item definitions). For uncommon **armor item level 102–120** the source specifies:

| Material | Model result probability | Conditional positive quantity | Bounds, expected material units per modeled operation | Model midpoint proxy, *not observed mean* |
| --- | ---: | --- | --- | ---: |
| Arcane Dust 22445 | 75% | 2–5 | 1.50–3.75 | 2.625 |
| Greater Planar Essence 22446 | 22% | 1–2 | 0.22–0.44 | 0.33 |
| Large Prismatic Shard 22449 | 3% | 1 | 0.03 | 0.03 |

These are explicit source **P(result)** and **conditional stack-size bounds**, not empirically logged independent casts, zero-inclusive histograms, or current Retail item-level bands. The legacy worker's 12 new reference rows in `research/v3/evidence/legacy/2026-11-15T0244-tbc-243-game-data-rarity-level-reference.jsonl` correctly preserve source kind `reference`, patch `2.4.3`, item-level scope and quoted quantities. However **`minSeen`/`maxSeen`, `averageShown` and `inputsPerCast` are all null**; the only record of 2–5 and 1–2 is the quote/notes. Keeping `minSeen/maxSeen` null is correct if they mean **observed** extrema; it also means there is no typed `modelConditionalMin/Max` for normalization.

Static `build_estimates.py` trace: `key_of()` builds gear identity only from `expansion:quality:kind`, **not `gearGroup.itemLevelRange`**. For a stand-alone reference row, `analyze()` gets P from `percentShown` but defaults the unknown numeric range to 1–1, then derives E=P×midpoint. Thus this source's dust example would yield **0.75** units per operation (instead of the source's bounded **1.50–3.75**, midpoint proxy 2.625), *if compiled on that path in isolation*. The source's known minimum alone is **twice** the provisional yield-one rate. This is a code-equivalent static path demonstration, **not** a run of the current compiler or synthetic price fixture. The same omission could combine incompatible item-level bands if subsequent historical reference rows share expansion/quality/kind; current twelve rows alone do not establish that such a collision has occurred.

**Acceptance for owner-controlled integration/reviewed engineering:** retain `gameFlavor=historical TBC`, patch and original item-level band in the estimate/group key; type model conditional quantity range separately from observed extrema; map P(result)×conditional bounds into a labeled bounded expectation (or explicitly declared midpoint proxy when allowed) without fabricating sample counts or live Retail character eligibility. Give exact input version a positive eligibility gate before allowing a gold recommendation. This is **usable historical reference context stranded in text**, not permission to apply the patch 2.4.3 model to scaled Retail item IDs 24995/24992/24991 or override the already archived cumulative Looter rows.

## Checks and scope

Actually performed: GitHub branch/PR and successful latest research CI read, original v2 F004 and correction files opened, new v3 worker records opened, static `load()`/`key_of()`/`row_use()`/`analyze()` inspected, external current-readable TBC table and Prismatic item identity read, exact arithmetic cross-checked. Worker status files independently read: DF 02:36Z, Legacy 02:44Z, TWW 02:27Z, Midnight 02:19Z. No original sample or source was counted twice.

Not performed: Python compiler, Lua engine, synthetic gold pricing, actual tooltip, WoW client, migration or import, CI on this note. No mutation of worker evidence, corrections, research queue, main, owner integration, PRs or schedules.

**Next:** reviewed file-/source-qualified acceptance for modeled historical conditional quantity bounds and gear item-level scope; coordinate v2↔v3 Prismatic study lineage if aggregating sources. Actual current Retail actionable gold coverage remains unverified; prioritize new current-build completed-operation output/rank/refund logs over repetitive historical search.
