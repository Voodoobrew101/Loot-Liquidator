# Coordinator targeted admission/eligibility QA: six new historical Arcane Dust Looter input IDs (2026-11-14 22:01 UTC)

**Scope:** new source-identity, data-unit, evidence-kind and Retail eligibility discrepancy. Research-only; not a current Retail measured experiment, estimator execution, synthetic-price Lua probe, client test or addon import.

## New worker source records and independently checked accounting

Read the [legacy worker's 11-row append-only file](https://github.com/Voodoobrew101/Loot-Liquidator/blob/implementation/five-agent-completion/research/v3/evidence/legacy/2026-11-14T2157-new-tbc-arcane-dust-looter-and-classic-skill.jsonl) at Git blob `ee42ae481522e94c15b9f0cc6020b2264e652d33`. JSONL parsing and direct per-row arithmetic show **six different exact input item IDs, 22,304 source-reported disenchant denominator occurrences and 17,353 Arcane Dust-positive occurrence hits**; these are **historical anonymous cumulative Looter observations**, not 22,304 independently logged current casts. The six IDs are disjoint from the eight earlier Arcane Dust inputs in the worker's `1948` file; this does **not** prove uniqueness across the whole research corpus or independence across Looter collection epochs.

| Input ID / item | Arcane Dust-positive / source denominator | Exact ratio (historic source only) |
| --- | ---: | ---: |
| 25064 Amethyst Pendant | 1,859 / 2,346 | 0.792413 |
| 24831 Nexus-Strider Greaves | 1,486 / 1,876 | 0.792111 |
| 24878 Der'izu Belt | 1,846 / 2,378 | 0.776283 |
| 25048 Smoky Quartz Ring | 3,715 / 4,780 | 0.777197 |
| 25041 Ambusher's Cloak | 3,752 / 4,848 | 0.773927 |
| 25005 Bloodfist Vambraces | 4,695 / 6,076 | 0.772712 |

All six are `sourceKind:"study"` with `casts` and `castsWithDrop`, yet `totalQuantity`, `averageShown`, `minSeen`, `maxSeen`, histogram, source-data epoch, skill, variant/bonus and observed positive material stack quantities are **null**. **Occurrence != output quantity**, and lack of Arcane Dust does **not** mean the disenchant produced no materials. Do not pool these item rates or add them to an anonymous gear-wide table. Original [Wowhead PTR Arcane Dust page](https://www.wowhead.com/ptr/item=22445/arcane-dust) was independently opened in readable text, but its *JS Looter numerical table was not independently re-extracted*. The exact denominator pairs above are worker transcriptions, checked for internal arithmetic, **not independently source-count validated**.

## New *specific* current Retail eligibility conflict: item 24831

[WoWDB LIVE Nexus-Strider Greaves 24831](https://www.wowdb.com/items/24831-nexus-strider-greaves) was independently opened and explicitly says **"Cannot be disenchanted"** at currently displayed ilvl 30. Historical [WotLK Classic item 24831](https://www.wowhead.com/wotlk/item=24831/nexus-strider-greaves) has ilvl 90 and a different character context; the worker reports a Classic-only skill 225. Thus **1,486/1,876 historical Arcane Dust appearances cannot justify a current Retail disenchant recommendation for item 24831**, and current inability to disenchant does not invalidate its separate historical evidence. Current WoW client variant/bonus behavior was **not** tested. Preserve an explicit **eligibility/context exclusion** rather than deleting historical values or equating no-de with missing source.

## New incorrect record-type/field handling: four *historical skill minimum* "condition" rows

The same new worker file has four `type:"condition"` records for input IDs **25064, 24831, 24878, 25041**, with `requiresSkill` **225, 225, 275, 275** respectively (Cataclysm/WotLK/TBC Classic versions). Each has `outputItemID:null`, since these are **minimum disenchant eligibility** claims, not conditional material-unlock claims. Independently inspected [`build_estimates.py`](https://github.com/Voodoobrew101/Loot-Liquidator/blob/implementation/five-agent-completion/research/v3/tools/build_estimates.py) blob `0b09b553fef4214af8aaa93f1c85061956643711`: `load_conditions()` lines 146-160 skips conditions with missing output ID; `non_drop_usage()` lines 703-710 reports `condition:incomplete`. **No current v3 conditional output or Retail skill gate is imported from these four entries**; they remain append-only historical references but have the wrong schema for effective current Retail eligibility. Do not create fictitious output IDs merely to force usage, and never interpret Classic profession skill numbers as current Retail skill requirements. Source Classic page text independently checked for old item level/era; the exact skill numbers were worker-reported, not re-extracted here.

## Specific estimator-to-tooltip risk and bounded acceptance

With these six records classified as `study`, the v3 `row_use()` path lines 266-326 treats their numerator/denominator pairs as observed chance counts, `confidence()` can assign large-sample precision, and the no-quantity `lo=hi=1` fallback can create a provisional **E(dust)=source historic P(hit) x 1**. That **is not observed quantity**; anonymous historic/cross-build provenance and `24831` noDE current context must remain separate. This is a targeted *additional six-item gate* beyond the earlier [eight-item QA](20261114T2006-legacy-arcane-dust-looter-study-vs-reference-and-yield.md), not a second independent source-rate study.

Acceptance when owner-owned integration tests this later: keep six exact source identities and historical ratios; disallow DE quote/tooltip action for known ineligible current item 24831; do not promote four null-output Classic skill `condition` records into modern material unlock or Retail eligibility; show source-kind/era, unknown per-hit quantity and no manufactured empirical confidence; validate legal item profile and price fixture for each quote. Use original-specific material prices only where action valid; **no current Retail gold-decision improvement claimed**.

**Executed:** fresh GitHub branch and worker-file reads, JSONL parse/count/overlap checks against immediately prior eight, exact arithmetic, direct WoWDB live item source and Classic item identity reads, static estimator source-code inspection. **Not executed:** direct JS Looter raw table extraction, v3 compiler run, synthetic-price Lua/tooltip test, client action, current Retail skill checks.

**Ownership:** worker may add append-only source/context correction within its authorized evidence area; owner three-pass integration controls addon changes and tests. Coordinator owns only this master evidence note, coordinator quiet status and research dashboard. No changes to originals, `main`, owner implementation branch, PRs, schedules, flags, queue or worker reports.

**Next:** obtain exact original upload build/item bonus and per-hit dust-stack quantities; independently verify eligibility/variant for 24831 against current client. Favor new post-hotfix Midnight/TWW complete-operation output/refund records over another scrape of this same cumulative Looter source.
