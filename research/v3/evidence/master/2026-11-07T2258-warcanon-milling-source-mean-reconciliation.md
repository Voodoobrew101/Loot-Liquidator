# Warcanon original milling totals versus reported average and frozen legacy estimate — 2026-11-07 UTC

**Scope:** source-arithmetic / units audit only, not another independent experiment and not live Retail verification. Owner's source-inclusive policy applies. Preserve worker append-only originals and the protected three-pass integration branch. Task: `T0042` (legacy historic raw milling totals) / `COORD-WARCANON-SOURCE-MEAN-QA-20261107`.

## Original observations, checked from primary comments

- [Warcanon, Sorrowmoss item 13466](https://www.wowhead.com/item=13466/sorrowmoss): first round **425 input herbs**, explicitly mixed with Golden Sansam; **33×2 + 29×3 + 23×4 = 245** Silvery Pigment (39341) over 85 enumerated mills; **40×1 + 1×2 = 42** Sapphire Pigment (43107), 41 positive events. This is **not** an input-specific Sorrowmoss yield.
- Same author, second round **480 Sorrowmoss herbs**, explicitly skipped Golden Sansam: **36×2 + 26×3 + 34×4 = 286** Silvery over 96 enumerated mills, **47×1 = 47** Sapphire positive events. First plus second = 905 input herbs and 181 enumerated mills; **531 Silvery, 89 Sapphire**.
- That source then claims `1.5801 Silvery Pigment per milling`. **The same author's counts give 531 / 181 = 2.933701657 Silvery per mill, not 1.5801.** The written Sapphire mean `0.4917` is consistent with **89/181 = 0.491712707**. The Silvery `1.5801` must remain an auditable *source arithmetic conflict*, not be imported as observed per-cast mean. Source editing about historical stack size and an unspecified **guild perk** means date, processing conditions and bonus scope remain unknown; do not treat any 20-stack description as a new operation log.
- [Warcanon, Golden Sansam item 13464](https://www.wowhead.com/item=13464/golden-sansam): separate outing with **31×2 + 37×3 = 173** Silvery (68 enumerated mills), **16×1 = 16** Sapphire (16 positive events). The latter implies 16/68=**0.235294118** Sapphire units/mill in that historical run, *not* an additional study of Sorrowmoss. Source says approximately 17 historical stacks and picked Sorrowmoss along the route, but the milling passage identifies the herb as Sansam.
- The research worker already transcribed these exact 6 paired rows (3 source cohorts) to [2026-11-07T2246-silvery-sapphire-original-mill-histograms.jsonl](../legacy/2026-11-07T2246-silvery-sapphire-original-mill-histograms.jsonl). This coordinator audit does **not** append replacement worker drop records or assert new cohorts.

## New source-versus-current-estimate numerical disposition

Read `research/v3/output/estimates.json` from research branch at **c53ae44dcefeffb68951070a7f75a72806514d5e**, before this note; four relevant estimates all have `studyCasts=0`, `basis=starting guess only (reference values)`, thus they do not yet embody the new 2026-11-07 worker cohorts. The historical `research/legacy-addon-v0.9.70/GameData.lua` reference is `gd.tsmRetail.mill[13464/13466]`, whose output `amountOfMats` is per *input herb* and must be multiplied by **5 input herbs per mill**; `matRate` is not itself an expected unit quantity.

| Input / output | Frozen starting-guess EV units/mill | New source-historical units/mill | Difference |
| --- | ---: | ---: | --- |
| Golden Sansam 13464 → Silvery 39341 | 2.8900 | 173/68 = **2.544117647** | observed 11.97% lower |
| Golden Sansam 13464 → Sapphire 43107 | 0.4775 | 16/68 = **0.235294118** | observed 50.72% lower (reference ~2.03× this historical run) |
| Sorrowmoss 13466 → Silvery 39341, unmixed 480-input round only | 3.0000 | 286/96 = **2.979166667** | observed 0.69% lower |
| Sorrowmoss 13466 → Sapphire 43107, unmixed 480-input round only | 0.5375 | 47/96 = **0.489583333** | observed 8.91% lower |

These are **historical sample/reference disagreements**, NOT estimated current Retail drop rates, actionable-gold reversals or proof the reference is wrong for current characters. No AH prices used. Even if hit count is explicit, Silvery/Sapphire joint output and per-operation zeros/refunds are not reconstructed from separate marginals. The author uses a guild perk and patch unspecified. `P(hit)`, source range, conditional quantity and unconditional EV must not be conflated. The 425-herb mixed run cannot be merged into Sorrowmoss-only expected value or counted as an additional independent Golden Sansam sample.

## Actionable next step

Keep original 12 worker records unchanged. For future research/three-pass audit, flag the source-reported `1.5801` as an arithmetic inconsistency and use the independent enumerated **531/181** only as historical *mixed-herb context*, not as a Sorrowmoss-only or Golden-Sansam-only estimate. Separately reconcile Golden Sansam's 16/68 with source scope and current frozen .4775 reference via reviewable synthetic-price test when the protected implementation owner brings evidence into the engine; never import as live-character verified or force a research snapshot refresh. Seek independent **current Retail** 5-herb Golden Sansam / Sorrowmoss casts, output unit histograms and eligibility before recalibrating production recommendation confidence.

## Validation performed

Original primary Wowhead comment texts read directly on 2026-11-07; current worker evidence rows, existing `v3/output/estimates.json` values and legacy `GameData.lua` units independently inspected via GitHub at stated head; all numerator/denominator calculations executed in Python stdlib. **Not performed:** v3 estimator rebuild, migration suite, addon tests, offline valuation/rendering, current-character or live WoW QA. No addon, worker evidence, immutable snapshot, protected integration or main changes.
