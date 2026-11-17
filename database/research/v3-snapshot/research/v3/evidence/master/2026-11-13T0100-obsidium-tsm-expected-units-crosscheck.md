# Obsidium Ore 53038 — historical two-original-cohort / TSM quantity-unit cross-check
Checked: 2026-11-13T01:00Z. Research-only manager audit; **not** current-Retail gameplay, a pricing test, a build test or independent new physical casts.

## New specific comparison
The Legacy worker filed a distinct original Rikikijr 1,755-ore result table at `research/v3/evidence/legacy/2026-11-13T0042-obsidium-rikikijr-original-quantities.jsonl` (12 materials, total 553 gems). I compared its original displayed quantity vector with the separately archived original Enchantrix-tracked **nubi** sample, `research/v3/evidence/legacy/2026-11-01T0540-cataclysm-original-enchantrix-prospect.jsonl` (5,016 physically counted prospects, 25,080 ore, 7,927 gems), and all **12** TSM source rows in main's `research/ledger/processing-output-fields.csv` (`tsm:prospect:53038:52177..52195:L963..974`). Both commenters' original result tables are visible together on [Wowhead Cataclysm original comment archive](https://www.wowhead.com/cata/item=53038/obsidium-ore) (also on locale / MoP Classic mirrors, **not additional sources**). Source authors and input volumes differ: do not conflate their study keys. Archive mirror is not evidence of a Classic experiment or current-2026 Retail behavior.

| Output ID | Material | New Rikikijr total / 1,755 ore | Prior nubi total / 5,016 counted prospects | TSM historical chance field | TSM historical expected units / operation |
|---:|---|---:|---:|---:|---:|
| 52177 | Carnelian | 89 | 1228 | 0.235 | 0.25 |
| 52178 | Zephyrite | 84 | 1273 | 0.235 | 0.25 |
| 52179 | Alicite | 103 | 1192 | 0.235 | 0.25 |
| 52180 | Nightstone | 94 | 1340 | 0.235 | 0.25 |
| 52181 | Hessonite | 79 | 1232 | 0.235 | 0.25 |
| 52182 | Jasper | 77 | 1291 | 0.235 | 0.25 |
| 52190 | Inferno Ruby | 5 | 49 | 0.0125 | 0.0125 |
| 52191 | Ocean Sapphire | 2 | 71 | 0.0125 | 0.0125 |
| 52192 | Dream Emerald | 8 | 66 | 0.0125 | 0.0125 |
| 52193 | Ember Topaz | 5 | 63 | 0.0125 | 0.0125 |
| 52194 | Demonseye | 4 | 65 | 0.0125 | 0.0125 |
| 52195 | Amberjewel | 3 | 57 | 0.0125 | 0.0125 |

### Exact unit gates / arithmetic verified
- New original 1,755 **ore**, not counted casts. `1755 / 5 = 351` **nominal batch equivalents only**, assuming the ordinary five-ore recipe and no unrecorded input returns; physical completed casts remain **null**. New aggregate = 526 common + 27 rare = **553 total gems**. Relative to nominal equivalents only: common `526/351 = 1.4985755`, rare `27/351 = 0.0769231`, all `553/351 = 1.5754986` units per *nominal five-ore input*, **not** independently observed per-cast EV, P(hit), or zero outcomes.
- Existing independent nubi original explicitly counts **5,016 prospects**, with **7,556 common + 371 rare = 7,927 units**, hence `7556/5016 = 1.5063796`, `371/5016 = 0.0739633`, `7927/5016 = 1.5803429` observed aggregate output units / original counted operation; its per-output hits and per-cast stack histograms remain **unknown**.
- All six historical TSM common output rows have **chance=0.235** but **expected_units_per_operation=0.25**, with conditional range 1..2; six rare rows each have chance and expected units 0.0125. Sum of **TSM expected units = 6×0.25 + 6×0.0125 = 1.575** per operation. By contrast, summing chance fields `6×0.235 + 6×0.0125 = 1.485` is **not the same as expected units** and would understate common material units by `0.09/1.5 = 6%` if misused as output quantity; **no claim the addon makes this mistake**.
- The new ore-normalized overall output (1.57550) and old directly counted output (1.58034) are close to reference expected-unit sum (1.575). This is a **consistency check, not a calibrated current patch estimate**. Different original cohorts/contexts could vary by patch and skill; rare samples are small. Do not pool or modify reference chance/hits or denominator and do not elevate the new 351 nominal equivalents to measured casts.

## Disposition and next priority
**Research identity/units audit passed:** 12/12 input/output IDs agree, distinct original author/source lineages, exact source quantities and the historically captured TSM expected-units field reconciled. **Newly verified from this audit:** 12 TSM chance-versus-E field distinctions and one additional source-to-reference aggregate comparison; **new original player studies submitted by manager: 0; completed casts newly observed: 0; new Retail priceable decisions proven: 0.** Original Legacy worker evidence untouched. Missing: Rikikijr completed physical casts, refunds, skill/patch; both source cohorts' output-specific hits/zero/stack histograms; current Retail applicability and source-independent numeric compile. Highest priority remains source-original current Midnight T0005/T0039/T0045 raw per-operation, rank-linked output and refund logs before any production valuation change. Inspect source metadata and use an isolated synthetic-price actual-engine/tooltip fixture before claiming imported actionable coverage. No production, integration, PR, CI or live-client execution by this manager note.

Sources: [original comments](https://www.wowhead.com/cata/item=53038/obsidium-ore); [Rikikijr original transcript](../legacy/2026-11-13T0042-obsidium-rikikijr-original-quantities.jsonl); [nubi original transcript](../legacy/2026-11-01T0540-cataclysm-original-enchantrix-prospect.jsonl); [main first-pass TSM source ledger](https://github.com/Voodoobrew101/Loot-Liquidator/blob/main/research/ledger/processing-output-fields.csv).
