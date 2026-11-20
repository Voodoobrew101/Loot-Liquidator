# Dragonflight Walking Mountain source-cohort / display-identity gate

**Checked:** 2026-11-20T02:05:56.945Z UTC • **Research base:** `acd4f8120c0ab423a2973b449c8675ef984d2dd4` • **Scope:** manager research-only, source/identity checks; no addon, importer, prices, calculated gold, or live-client tests.

## New comparison and original sources

Audited the Dragonflight worker's [six material rows](https://github.com/Voodoobrew101/Loot-Liquidator/blob/acd4f8120c0ab423a2973b449c8675ef984d2dd4/research/v3/evidence/dragonflight/2026-11-20T0139-walking-mountain-three-gear-looter-and-gap-search.jsonl) against publicly indexed original Wowhead **item-side Looter** tables and the older, pinned original-evidence snapshot. Source rows are pooled site reports, not first-party export events.

| Input base item | Site-reported item disenchant count | Vibrant Shard 194124 positive count | Resonant Crystal 200113 positive count | Positive material counts summed |
| --- | ---: | ---: | ---: | ---: |
| [Husk 200423](https://www.wowhead.com/ptr/item=200423/husk-of-the-walking-mountain?bonus=13470) | 37 | 24/37 (display 65%) | 19/37 (display 51%) | 43 |
| [Gauntlets 200425](https://www.wowhead.com/ptr-2/item=200425/gauntlets-of-the-walking-mountain) | 38 | 18/38 (47%) | 24/38 (63%) | 42 |
| [Casque 200426](https://www.wowhead.com/ptr/item=200426/casque-of-the-walking-mountain?bonus=13470) | 33 | 24/33 (73%) | 13/33 (39%) | 37 |

The indexed pages match **all six original reported output numerators, input denominators, rounded displayed percents and output identities**. Three distinct *base-item* report groups account for **108 site-reported operations** and **122 material-positive appearances**. The latter are not units, not 122 distinct operations and not 122 independently observed drops. Each input's cross-material positive counts sum above the item count, so normalizing outputs to an exclusive one-of distribution would discard potentially co-occurring materials. This does **not** demonstrate any source arithmetic error.

### New de-duplication / identity checks

* Wowhead's [Casque bonus=9000 view](https://www.wowhead.com/ptr/item=200426/casque-of-the-walking-mountain?bonus=9000) gives the same 33/24/13 site totals as bonus=13470. A selected UI bonus does **not** prove a bonus-resolved 33-operation sample. Treat alternative URL/bonus/locale/PTR version mirrors as the **same underlying Looter source cohort pending original-event evidence**, not fresh experimental samples.
* The [12.1.5 PTR Gauntlets view](https://www.wowhead.com/ptr-2/item=200425/gauntlets-of-the-walking-mountain) already presents 38/24/18, and the current worker's 12.1.7 page also reports 38/24/18. A page's displayed build does not date the observations or prove they came from that client.
* Potential nearby [Poleyns 200427](https://www.wowhead.com/ptr/item=200427/poleyns-of-the-walking-mountain) report **36** with Shard **25** and Crystal **19**. **Not new**: already present as records `dragonflight-20261114-0335-009..010` in the [immutable main research snapshot](https://github.com/Voodoobrew101/Loot-Liquidator/blob/main/database/research/v3-snapshot/research/v3/evidence/dragonflight/2026-11-14T0335-five-walking-mountain-looter-cohorts.jsonl), blob `df1b6c63ecf32c76d9bfbc25490c416dbbf98944`. Do not ask the worker to re-add or double-count Poleyns.
* All three newly checked base-item IDs have earlier *token-reward mapping* references in the main source inventory. Those token catalog references are distinct **identity** data, not prior disenchant outcome cohorts or independent experiments.

## Calculation / field admission gate

Wowhead visibly describes Vibrant Shard as **1–2** on a positive outcome. This is a source-page stack description, **not** a verified 0/1/2 per-operation histogram or measured total quantity. The six worker rows correctly leave `totalQuantity`, `histogram`, `inputRank`, `outputRank`, `skill`, `specialization`, `patch` and `dataDate` null. The base-item Looter denominator is cumulative and original itemLink/bonus, original flavor/build, character conditions, per-event outcomes, zero-inclusive units and Retail **current-instance** eligibility are not certified. A provisional yield-one model would need separate, explicit eligibility/provenance review; these figures alone are not a calibrated current Retail gold EV.

Classification: **historical source positive-hit/denominator observations**; partial evidence available, not a measured quantity/yield and not a current enabled gold method. No prices were checked. Do not infer overall no-material disenchants from gaps or duplicates from similar positive totals alone.

## Validation actually executed

A bounded JavaScript check against GitHub blobs `4445301361a980b6d583bd1e469ec50fd48040b4` (new worker 6 rows) and `df1b6c63ecf32c76d9bfbc25490c416dbbf98944` (older pinned 10 rows) passed **56/56 static assertions**: input/output identities, six numerator/denominator/percentage tuples, shared per-item study keys, absent unit/hist/rank fields, three nonexclusive count sums, old Poleyns presence, and no overlap of the three new IDs with the prior five gear groups. Source-page counters were **independently inspected in indexed pages**; no direct raw Looter export or contemporaneous page-version archive was obtained. No estimator rebuild, native Lua runtime, actual-engine synthetic-price rendering, live WoW, benchmark or new confidence calibration executed. Research head `acd4f8120c0ab423a2973b449c8675ef984d2dd4` had [exact-head GitHub validation](https://github.com/Voodoobrew101/Loot-Liquidator/actions/runs/44656127987) reported successful before this audit, **not CI for this manager write**.

**Next:** Dragonflight worker T0041/T0020/T0018/T0015 should seek independent current-Retail per-event rank/bonus/build/skill and 0..N unit/zero/refund data rather than re-indexing source mirrors. Current highest gold-priority originals remain Midnight Umbral Tin 237362 and Tranquility Bloom 236761, TWW Ironclaw 210937 and Mycobloom 210796. Owner implementation branch, original evidence, worker files/schedules, main, PRs and releases untouched.
