# Shadowlands 2021 original milling: typed-input denominator and historical-rate admission gate

Source checked: [June 29, 2021 first-person source, original material totals](https://www.reddit.com/r/woweconomy/comments/oahhoi). Newly transcribed worker originals: [11 rows](../../evidence/legacy/20261119T0352Z-shadowlands-mill-input-totals-and-cata-mixed.jsonl), pinned blob `3df23af1353bbb88cd8d2d06a14114cd482146b6`. Source records three **separately attributed** herb cohorts, totaling nine material-specific rows, and two unrelated **pooled Cataclysm** rows. All are **historical**, not present-Retail client trials.

## Direct source-count audit and normalized, clearly non-cast equivalents

The original author says total herbs **milled** and named pigment totals (not herbs bought); the same source does **not** give a count of actual completed standard or mass-mill operations, confirmed per-cast hits, zeros or quantity histograms. All row-level `casts`, `castsWithDrop`, observed ranges, skill and rank values remain null. The worker transcribes `inputsPerCast:20` for Shadowlands mass-milling interpretation, not an observed completed mass-cast denominator.

| Original source herb | Source-stated herbs milled | Luminous (173057), units per 5 herb equivalents | Umbral (173056), per 5 | Tranquil (175788), per 5 |
| --- | ---: | ---: | ---: | ---: |
| Death Blossom (169701) | 1,700,000 | 0.73288824 | 0.72960588 | 0.02432647 |
| Nightshade (171315) | 10,000 | 1.2605 | 1.256 | 1.494 |
| Marrowroot (168589) | 1,000 | 0.405 | 1.07 | 0.025 |

Each figure = source-reported total material **units** × 5 / source-reported herb inputs. This is a **historical input-normalized ratio** only (per nominal five-herb equivalent); no 20-herb physical-cast tally, occurrence chance, conditional quantity, 2026 quality, skill curve, or measured future rate follows. Five-herb and 20-herb outputs must not be treated as separate observed cohorts. Source's retrospective and TSM-tracking context may limit the completeness of the counts.

## Exact data-to-estimator disconnect

The new nine rows preserve `totalQuantity` and source-stated herb counts **in prose**, but omit typed `inputsProcessed`. The current [estimator's `row_use`](../../tools/build_estimates.py) accepts `totalQuantity` numerically only with source `casts` or a typed `inputsProcessed` and batch-unit normalization; for these nine rows the static code path is `totalWithoutCasts`. This is **usable historical input quantity, not yet admitted through this research estimator**; it is not missing historical counts and cannot establish P(hit). Actual Python estimator, generated output and ItemDB were **not** executed in this run.

Existing research/legacy Shadowlands Death Blossom, Nightshade and Marrowroot **already have TSM/reference/compiled candidate output routes** (main `research/ledger/itemdb-source-alternates.csv`, `research/legacy-addon-v0.9.70/GameData.lua`), so this independent source must be compared and deduped against the originals, **not blindly blended or advertised as nine new missing tooltip models**. Source prices, character eligibility and current Retail compatibility are not verified.

The two other [worker rows](../../evidence/legacy/20261119T0352Z-shadowlands-mill-input-totals-and-cata-mixed.jsonl) pool **545 Whiptail and 32 Cinderbloom** before reporting 341 Ashen Pigment and 68 Burning Embers; since input item identity is mixed, both remain **held from item-specific valuation**. Their source reports gathering herbs, not a proved individual processing denominator; no apportionment by herb or fabricated 577/5 casts.

## Scope and reviewer acceptance path

An isolated **reviewer-owned append-only correction** can place source-reported `inputsProcessed` of 1,700,000 (Death Blossom), 10,000 (Nightshade) and 1,000 (Marrowroot) on the corresponding **three output rows each**, after checking input-consumption basis and original study independence. Retain `casts:null`, `castsWithDrop:null`, `histogram:null`, no measured probability, raw totals unchanged; ensure recipe conversion is labelled input-equivalent and no existing supported fallback is overwritten or doubled. Then execute standalone Python estimator/unused-reason test, exact-source dedupe, and (only on owner-approved integration work) actual offline synthetic-price ItemDB/tooltip probes with field unknowns. Do not edit owner three-pass addon branch, original worker files, main or PRs.

**Executed verification:** 76/76 bounded JavaScript assertions on all 11 worker rows and nine expected original-source total/identity pairs; no Python estimator, native Lua, priced ItemDB/renderer, or live-WoW validation. Research starting head `cd300c015ea96cd415c00d49349064046d5b6bf3`; its [Verify five-agent completion run 44454475866](https://github.com/Voodoobrew101/Loot-Liquidator/actions/runs/44454475866) succeeded **before this research-only note**, not attributable to the new manager commit.
