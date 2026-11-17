# Manager original-source audit: astroid Classic uncommon armor groups

Verified at 2026-11-16T01:04:32.359Z UTC. This is **research-only source integrity**, not a new current-Retail measurement, import, gold EV, or actual tooltip verification.

## Pinned inputs and exact checks

- [Original astroid Enchantrix SavedVariables](https://github.com/alex-berliner/wow_classic_de_table/blob/5918ca3e44f6e4bba9071731ab28be3189498001/dbfiles/astroid.lua), blob `9468de29626ccaf2462458df1b5a148b4c5cbdf0`, `EnchantedItemTypes` (not the price cache).
- [Legacy worker's new 21-row evidence](https://github.com/Voodoobrew101/Loot-Liquidator/blob/1d61511746a9f6dc7457b356ec0d12fbd5a3570e/research/v3/evidence/legacy/2026-11-16T0040-astroid-original-classic-armor-hits.jsonl), blob `98e56b47f1c01321029e474a320f4d41f32d7db7`.
- Research `build_estimates.py` blob `0b09b553fef4214af8aaa93f1c85061956643711`, `key_of` and `normalize_row` logic reviewed statically.
- **21/21 pinned original material-ID / positive-occurrence / total-unit / trailing-zero tuples matched**, across eight distinct original group keys: `41:2:4`, `43:2:4`, `46:2:4`, `47:2:4`, `51:2:4`, `54:2:4`, `55:2:4`, `56:2:4`.
- Original columns total **457 material-positive occurrences** and **1133 material units**; neither sum represents completed disenchant operations. `casts`, zero outcomes, 0–N histograms, patch/build, skill, eligibility, variant and current Retail applicability are **unknown**. The original tuple's trailing `:0` is not a zero-disenc​​hant outcome denominator.

## Newly checked identity defect

The original **8 level-specific groups / 21 material rows** reduce to only **11 group/output estimator keys**, with **6 multi-level collision keys** because `key_of` builds `gear:Classic:uncommon:armor` and omits `gearGroup.itemLevelRange`:

| Material ID | Original item levels collapsed into same estimator key |
| --- | --- |
| 11137 | 41, 43 |
| 11174 | 41, 43 |
| 11175 | 46, 47 |
| 11176 | 46, 47, 51, 54, 55 |
| 11177 | 41, 43 |
| 16202 | 51, 54, 55 |

This is **10 lost level-specific tuple distinctions** at the *group-key* level (21 tuples minus 11 keys), not ten discarded evidence rows or ten measured casts. The current `normalize_row` rejects numeric chance when `castsWithDrop` lacks `casts` (`hitsWithoutCasts`), and rejects the total quantity as an unconditional mean without a denominator (`totalWithoutCasts`). Thus do **not** claim that these new rows currently affect shipped valuation. A level-preserving key migration needs a separate, tested research-only compatibility proposal with no new addon snapshot/PR.

The same original SavedVariables contains 415 `EnchantedLocal` item entries from this contributor. Potential overlap with group aggregates cannot be ruled out, so original per-item and grouped records must not be counted as independent source cohorts without proven disjoint events. Different contributors (astroid versus ereduns) remain separate source identities.

## Gold-action disposition and next step

Classification: source identity verified; positive material counts/units usable as *historical positive-only evidence*, **not** a valid unconditional expected quantity or chance; estimator identity loses ilvl; missing denominator, context and live eligibility block current Retail gold decisions. No price or tooltip display experiment was run. Highest-value next evidence is a current-build, exact-item/bonus, character-skill-tagged, zero-inclusive DE per-cast ledger, ideally for task T0047 (Warmaul Legplates 24995) or another verified eligible item. Alternative isolated engineering: regression test that keeps level-group identity across existing studies before any admission. Do not ask workers to reharvest this pinned file; do not infer zero events or reuse market-price timestamps as cast dates.

**Validation executed:** 21 in-memory JavaScript original-tuple comparisons, eight group identities, six collision-key detection, one static estimator contract check. **Not executed:** Python compiler tests, Lua tests, synthetic-price renderer, actual client or live WoW QA, CI on this future commit.
