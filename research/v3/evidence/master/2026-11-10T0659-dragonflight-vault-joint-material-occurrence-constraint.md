# Coordinator research-only source QA: Dragonflight Vault raid-gear joint material occurrences

**Checked (UTC):** 2026-11-10T07:00:04.308Z. **Task:** Dragonflight gear disenchant source-context QA / T0020 related fallback; no new raw experiment, no accepted unconditional output quantity, no tested compiled valuation.

## Newly checked original source observations

The Dragonflight worker's November 10 file `research/v3/evidence/dragonflight/2026-11-10T0645-warlock-vault-gear-and-material-index-hits.jsonl` adds input-specific Wowhead Looter rows. Coordinator independently reopened **both original item pages** and read their item-side *Disenchanting* tables:

| Source input / record IDs | Item-side stated disenchants | Vibrant Shard `194124` hits | Resonant Crystal `200113` hits | Sum of material occurrences | Minimum intersection *if counts share one operation universe* |
| --- | ---: | ---: | ---: | ---: | ---: |
| [Scalesworn Cultist's Girdle `200339`](https://www.wowhead.com/item=200339/scalesworn-cultists-girdle); `dragonflight-20261110-0635-001/-002` | 55 | 34/55 (62% rounded; displayed positive stack 1–2) | 28/55 (51% rounded; stack unknown) | 62 | **7** |
| [Scalesworn Cultist's Sandals `200334`](https://www.wowhead.com/item=200334/scalesworn-cultists-sandals); `dragonflight-20261110-0635-003/-004` | 62 | 39/62 (63% rounded; displayed positive stack 1–2) | 39/62 (63% rounded; stack unknown) | 78 | **16** |

The material identities are separately confirmed by the [Vibrant Shard `194124`](https://www.wowhead.com/item=194124/vibrant-shard) and [Resonant Crystal `200113`](https://www.wowhead.com/item=200113/resonant-crystal) item pages. The input pages currently render item level 72 and their material links display item level 60; neither is evidence for the actual item bonus/ilvl and patch of historical samples.

**Arithmetic check:** For two material-hit sets A and B in the *same* N-operation population, inclusion/exclusion implies `|A ∩ B| ≥ max(0, |A|+|B|-N)`. Thus at least 7/55 or 16/62 joint-positive events **or an inconsistent/heterogeneous source denominator interpretation**. The original pages do **not** expose event-level joint results. This is a deterministic conditional constraint, **not an observed co-drop count**; do not enter it as a measured joint histogram, a new study, or an extra denominator.

## Required treatment / risk to gold decisions

- **Probability:** Rows describe material-specific positive-occurrence fractions only; leave source percentages rounded as site display and use exact numerators/denominators when supported. `N-hit` is a per-material non-hit count, not a verified globally empty disenchant.
- **Quantity:** The source's `1–2` for Shard is a positive-stack range, not a mean. Neither input has an observed total Shards/Crystals, zero-inclusive histogram, conditional average, per-cast Resourcefulness effect, or actual sale-price context. No exact unconditional expected output units or gold EV was newly verified. No observed per-character eligibility, item bonus/ilvl, skill/spec, or source collection epoch.
- **Selection risk (static code inspection only):** `research/v3/tools/build_estimates.py` `row_use()` accepts `castsWithDrop`/casts as chance, while `analyze()` can fill missing average as `chance × midpoint(positive range)` (or fallback 1 if absent) and labels `averageSource=estimated`/`provisionalValuation=true`. If these rows reach that branch, the amount is a **provisional assumption**, not a measured mean. Do not treat midpoint yield as observed or infer exclusive output bins; only use the owner's defensible explicitly labeled provisional yield-1 policy with appropriate profile/epoch review.
- **Data integrity:** These four rows are two **input-source populations**, not four independent cohorts. Their input IDs and output IDs are directly source-matched. Cross-file duplicate independence for the other six new worker rows was not independently established here; retain the worker's source caveats. Do not pool future mutable Wowhead Looter snapshots as independent studies.

**Disposition:** two original item/source identities and their four existing hit fractions directly rechecked; two new conditional inclusion/exclusion constraints documented. **New independent casts/cohorts, observed output quantities, supported actual-character gold decisions and live-client tests: zero.** This note is QA only, not code or estimate acceptance. No prior worker evidence modified.

**Next:** Obtain the original Looter operation-level event sequence or a character addon export with both outputs, per-hit stack quantities, the actual bonus/ilvl and build, then test raw-source -> estimator -> actual tooltip under synthetic prices on a separate authorized engineering branch. Preserve unknown source dates and any cross-page cohort uncertainty.
