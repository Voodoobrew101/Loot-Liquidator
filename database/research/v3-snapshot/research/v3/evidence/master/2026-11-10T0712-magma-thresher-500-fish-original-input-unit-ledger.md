# Original Magma Thresher 500-fish prospecting cohort: source-unit ledger
Checked (UTC): 2026-11-10T07:11:31.340Z. Research-only manager analysis; not an addon import, estimator acceptance or client test.

## Original, identity and nonduplication check
- [Original Reddit firsthand table, 2023-01-12](https://www.reddit.com/r/woweconomy/comments/109yr4s) reports processing **500 Magma Thresher** with **25 prospecting specialization points** and the qualifier **"all R2"**. It publishes material **totals**, not individual completed clicks, per-output hit counts, zeros or conditional quantity histograms. Author identity/precise output rank scope and refund accounting were not independently retrieved.
- Input **Magma Thresher = item 199344**, a Dragonflight *fish/cooking ingredient* rather than an ore: [TSM Retail item catalog](https://tradeskillmaster.com/retail/us/items/199344), [Retail GoldCap catalog](https://goldcap.gg/retail/us/items/199344), and [Warcraft Wiki older item overview](https://wowpedia.fandom.com/wiki/Magma_Thresher). Source and catalog corroborate the possibility of prospecting, but do **not** establish a specific fish-per-recipe batch, active Retail recipe spell, character skill or live eligibility. Do not apply the general five-ore-per-cast rule to this fish.
- Existing [2026-10-31 worker Magma Thresher original file](../dragonflight/2026-10-31T2027-magma-thresher-prospecting-cohorts.jsonl) contains separately sourced Wowhead *two completed prospects*, two distinct Badwulf 1,000-fish diamond receipts and an independent Jan 1 Reddit 1,000-fish account. The present Jan 12 Reddit 500-fish table is a **different original URL** with a different input total; do not copy any old sample into it. GitHub indexed search on main for original ID `109yr4s` returned no match, but that search alone does not prove a comprehensive cross-branch cohort audit.

## Verbatim numeric fields and deterministic source-input normalization
The original table's 13 named material totals are preserved below. Third column is **reported material units per one of the 500 source-reported fish**, not measured units per cast and **not** P(hit). Rank/item-ID verification remains open, notably the generic `Glass` and `Stone` labels.

| Source output label | Source total units | Source ratio: units / reported fish |
| --- | ---: | ---: |
| Illimited Diamond | 0 | 0/500 = 0.000000 |
| Nozdorite | 6 | 6/500 = 0.012000 |
| Neltharite | 3 | 3/500 = 0.006000 |
| Ysemerald | 2 | 2/500 = 0.004000 |
| Alexstraszite | 4 | 4/500 = 0.008000 |
| Malygite | 1 | 1/500 = 0.002000 |
| Eternity Amber | 45 | 45/500 = 0.090000 |
| Mystic Sapphire | 11 | 11/500 = 0.022000 |
| Queen's Ruby | 16 | 16/500 = 0.032000 |
| Sundered Onyx | 17 | 17/500 = 0.034000 |
| Vibrant Emerald | 16 | 16/500 = 0.032000 |
| Glass (source generic label) | 121 | 121/500 = 0.242000 |
| Stone (source generic label) | 140 | 140/500 = 0.280000 |

Arithmetic: total reported output units = **382**; across heterogeneous outputs this is **382/500 = 0.764000 units per reported input fish** solely as a sum/checksum, **not** a material-specific economic value. Individual output sample rates are usable **per reported fish** for a future auditable input-cost/output-price normalization only after correct material ID/quality and input consumption are established. Do not treat a single reported zero Illimited Diamond as zero probability in general.

## Material blockers (do not infer)
1. **Fish count vs operation count:** `reportedInputFish=500`, `completedCasts=null`, `inputsPerCast=null`, `actualNetConsumed=null`, `refundedFish=null`. There is no basis for treating this as 100 five-fish casts, 500 casts, 500 independent zero-inclusive events, or 500 chance trials. The rate is units per *reported fish*, not proven per consumed fish. No cast probability or chance confidence is calculated.
2. **Output identity/ranks:** the source writes `Glass` (121) and `Stone` (140) without full item names, linked IDs or rank; `all R2` does not identify which output IDs/ranks it covers. The older Jan 1 1,000-fish source explicitly reported no Crumbled Stone, but generic `Stone` here is not enough to declare a patched contradiction or assign `192880`. Do not merge family and exact-rank projections.
3. **Context:** January 2023 Dragonflight, not demonstrated for November 2026 Retail; skill bonus, refund basis, actual build/recipe and fish-specific eligibility unknown. Existing historical TSM fallback must not be confused with a new independent chance study. This source does **not** establish a current-character actionable recommendation.
4. **No double counting:** one original study with 13 correlated material rows, not 13 independent trials; row totals represent aggregate units and are never recast as `castsWithDrop`. Historical 500-fish and older 1,000-fish studies remain separate cohorts until verified common authors/receipts indicate overlap.

## Integration handoff, without touching protected three-pass branch
This is new field-level source evidence for the already-known `Prospect:199344` ingestion gap. The protected three-pass [PASS-2](../../../..//docs/usable-data-audit/PASS-2.md) explicitly retains numeric per-input references without inventing a fish-specific action/batch. A future **scoped, reviewed** correction can carry the original 500-fish denominators as a labeled *per-input reference*, resolving output names/ranks from original links first; any per-cast estimate, chance/range, recipe eligibility or live prices must remain unknown until independently demonstrated. The immutable `4df9ae8` compiled snapshot is not modified. No new current-Retail gold actions or measured casts were verified.

**Actual work here:** read current research and three-pass checkpoints, original public source table and item catalogs, checked all 13 source totals/one denominator with exact rational arithmetic, compared existing worker source cohorts, and recorded this note. **Not run:** importer/compiler, Lua/addon/tooltip tests, synthetic valuation, client verification. Next priority: source-author/itemLink validation of the fish batch and R2/Glass/Stone identities, then independently sourced current-patch per-output measurements for Midnight T0005/T0039/T0045.
