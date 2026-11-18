# Research Manager — WotLK milling source-to-existing-mean audit

Checked UTC: 2026-11-18T00:03:38.981Z. Scope: research-only provenance and numeric-field audit. Task **T0042**. No production/owner-integration, worker-original, queue or scheduler edits.

## Original source and immutable preexisting output

Original [killerpet Azure/Icy milling table](https://www.wowhead.com/wotlk/item=39343/azure-pigment) gives **completed five-herb mills** and **rounded unconditional average output units per mill**, not material-hit denominators, per-output probabilities, raw unit totals, stack histograms, character skill or current Retail epoch. Independently re-located the same table in [Cataclysm Classic indexed comments](https://www.wowhead.com/cata/it/item=39343/azure-pigment); these are *mirrors of the same author table*, not independent studies. Exact research worker input: [legacy 2026-11-17 23:42 JSONL](../legacy/2026-11-17T2342-original-wotlk-herb-mill-averages.jsonl), blob `919b38e0d90007149e2529df4d27c54a4eb5b18b`.

Compared eight named-herb/output rows with the **previously generated / currently frozen** [research/v3/output/estimates.json](../../output/estimates.json), blob `15ae8c5b7f7b2587ceff1dcd3e8b9d13d4351d1e` (not rebuilt from the Nov 17 worker file):

| Input | Source ops | Source E Azure / Icy per mill | Frozen E Azure / Icy | Frozen study casts for *each* output | Frozen P Azure / Icy |
| --- | ---: | --- | --- | ---: | --- |
| Goldclover 36901 | 313 | 2.57 / 0.24 | 2.5766 / 0.2519 | 313 | 0.8589 / 0.1259 |
| Tiger Lily 36904 | 871 | 2.45 / 0.25 | 2.4698 / 0.2613 | 1,071 | 0.8233 / 0.1307 |
| Adder's Tongue 36903 | 1,975 | 2.98 / 0.53 | 2.9819 / 0.5267 | 2,379 | 0.9940 / 0.2633 |
| Lichbloom 36905 | 705 | 3.03 / 0.52 | 3.0292 / 0.5205 | 705 | 1.0000 / 0.2602 |

Output IDs: **Azure Pigment 39343**, **Icy Pigment 43109**. Both material rows for each source herb share its mill count; **do not add them as two independent cohorts**. The exact Goldclover/Lichbloom denominator matches and Tiger Lily/Adder's Tongue prior denominators exceed the freshly transcribed table. These are strong **pre-existing numerical-field/overlap** indicators, *not* a claim that every historical original has been exhaustively de-duplicated. Do not credit the eight rows with eight newly populated fields or 3,864 fresh independent milling operations until prior original study identities are reconciled. The prior selected means already appear at essentially the same magnitudes.

All eight frozen **`chanceSource` fields are `estimated`**, and **`averageSource` fields are `measured`**. The high-salience case is **Lichbloom→Azure**: frozen `chance=1.0` is **estimated from mean/range**, not source-reported 100% material-hit frequency. This can look certain if a tooltip drops the source label. No false claim of a presently verified addon/display bug: this check used a **static frozen generated artifact**, not live tooltip rendering or current-client data. A supported unconditional expected quantity is already priceable without knowing the chance; do not multiply the per-mill output mean by estimated chance again or treat it as an observed P. The older `range` is reference only.

The new 270-mill author **317829** has two distinct source-reported averages (Azure 2.95, Icy 0.59) from a *mixed unspecified higher-Northrend-herb basket*. The original author did not allocate casts among Adder's Tongue 36903, Icethorn 36906 and Lichbloom 36905. **Hold as mixed contextual evidence, no per-input compiled E/chance or Retail valuation** unless actual allocation/epoch is found. Keep those two material rows under one shared study key.

## Bounded checks and disposition

Executed **35/35 in-process JS assertions** over the worker JSONL and frozen estimate JSON: one exact selected method/input/output row for each of eight named source rows; prior mean marked measured; prior study cast count at least source cast count; selected means within 0.1 units; both mixed rows share a study key and have distinct output IDs. No new Python estimator, importer, Lua, actual valuation engine, tooltip render, GitHub CI job or WoW client test. This is a **usable already represented** mean, not missing-source volume; field-level risk is **estimated chance presented as certain**. Source era is historical, current Retail equivalence not verified.

**Action:** retain append-only worker originals; prevent overlap reweighting on next snapshot refresh; keep observed P unknown wherever the source supplies only E. Owner three-pass implementation branch is untouched. Next original-source priority remains exact current Retail 237362 Umbral Tin and 236761 Tranquility Bloom operation/rank/zero/refund ledgers; separately review chance labels during owner integration, not by editing their branch.
