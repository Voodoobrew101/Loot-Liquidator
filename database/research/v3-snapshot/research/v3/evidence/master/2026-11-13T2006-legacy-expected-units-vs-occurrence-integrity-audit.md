# T0042: internal chance–expected-quantity incompatibility in archived research estimates (source/valuation gap; not new casts)

**Checked UTC:** 2026-11-13T20:07:38.321Z. **Research branch head before write:** `239c4e3929ba5b23f640ac6bc61fb9c3a70d0e95`. **Main:** `b6610848604f68f8f3b40834397b79ce53eb8fb5`; **three-pass integration:** `3d667d053db587c91401cfed7ecc56862b8340c9` (left untouched).

## Independently executed numeric validation

Parsed all **1,180** archived entries in `research/v3/output/estimates.json` (Git blob `15ae8c5b7f7b2587ceff1dcd3e8b9d13d4351d1e`) and checked each populated `chance`/unconditional `average` against `E[positive material units per process] >= P(at least one unit) × minimum positive stack`. For 15 entries across **four** historical methods/inputs (**Mill 52988, Prospect 10620, 23425, 36910**) the displayed observed minimum is 1 yet **P(hit) exceeds E[units]**, an internally impossible *single* output distribution. All 15 archive entries have `chanceSource=measured`, `averageSource=measured` and `conflict=false`; these field labels do **not** establish that those figures came from compatible original cohorts. These are archived research output contradictions, **not independently checked original player data**.

Directly cross-read the **actual compiled Lua database data** on the owner-protected implementation branch, `database/research-v3-baselines.lua` (Git blob `ae953ffde49a27c0270408d0facbf6d96ee7955c`), selecting the *same 15* method/input/output identity rows. The protected compiled material rows have **13 expected quantities = unknown** and **two with present, internally compatible quantities**. This is a measurable **supported-field coverage gap**, but it is **not proven a regression in actual Lua rendering**, because no resolver, synthetic-price or client test ran. The compiled values differ from the old archived research output and must not be replaced by the latter without validating source/units/version. No source was edited.

| Archived method/input → exact output | Archived P(hit) | Archived E[units] | Positive range | Compiled P(hit) | Compiled E[units] | Compiled field status |
|---|---:|---:|---|---:|---:|---|
| Prospect 10620 ×5 → 12364 | 0.1868 | 0.1746 | 1–2 | 0.0556 | unknown | unknown |
| Prospect 10620 ×5 → 12799 | 0.2658 | 0.2465 | 1–2 | 0.2222 | 0.2393 | measured |
| Prospect 10620 ×5 → 12800 | 0.2395 | 0.2189 | 1–2 | 0.1667 | 0.2094 | measured |
| Prospect 23425 ×5 → 23079 | 0.2235 | 0.1911 | 1–2 | 0.2857 | unknown | unknown |
| Prospect 23425 ×5 → 23107 | 0.2824 | 0.1816 | 1–2 | 0.4286 | unknown | unknown |
| Prospect 23425 ×5 → 23112 | 0.2824 | 0.1785 | 1–2 | 0.4286 | unknown | unknown |
| Prospect 23425 ×5 → 23437 | 0.0529 | 0.0383 | 1–1 | 0.0714 | unknown | unknown |
| Prospect 36910 ×5 → 36918 | 0.0563 | 0.0451 | 1–2 | 0.0833 | unknown | unknown |
| Prospect 36910 ×5 → 36919 | 0.0906 | 0.0445 | 1–2 | 0.1667 | unknown | unknown |
| Prospect 36910 ×5 → 36920 | 0.3333 | 0.2539 | 1–2 | 0.3333 | unknown | unknown |
| Prospect 36910 ×5 → 36925 | 0.0906 | 0.0474 | 1–2 | 0.1667 | unknown | unknown |
| Prospect 36910 ×5 → 36929 | 0.4167 | 0.2513 | 1–2 | 0.4167 | unknown | unknown |
| Prospect 36910 ×5 → 36933 | 0.0563 | 0.0436 | 1–2 | 0.0833 | unknown | unknown |
| Prospect 36910 ×5 → 36934 | 0.0594 | 0.0473 | 1–2 | 0.0833 | unknown | unknown |
| Mill 52988 ×5 → 61980 | 0.5333 | 0.5260 | 1–3 | 0.5400 | unknown | unknown |

## Interpretation and safe next fix

- **Do not repair by merely clamping P to E** or increasing E to P. That would invent probability/quantity. First trace source cohorts, input ranks, positive-outcome numerator denominators, nominal-versus-completed operations and release/game flavour for each pair, and confirm whether historical chance and mean represent different populations.
- For a source-backed, properly normalized unconditional **mean**, retain the usable mean for valuation with `chance=unknown` where occurrence data are incompatible. If occurrence is valid but mean is not, retain the supported occurrence field and explicitly hold expected quantity. Do not conflate numerical source absence, eligibility, price, and display.
- Prioritize **Titanium Ore 36910** (seven affected outputs; largest archived difference 36929 P=0.4167 versus E=0.2513) and **Adamantite Ore 23425** (four), then Thorium Ore 10620 (three) and the historical mill 52988 (one). Historical TBC/other older cohorts require Retail-context review; never market these old totals as modern live WoW/price measurements.
- Source-local identity follow-up: two original **29,865 nominal Adamantite ore** files on the research branch contain **13 matching per-output units each**, identical original Reddit `ospt2y` URL, with distinct `studyKey` values. Their contents were read independently today, not a new cohort. The Legacy worker's later **48,315 ore** `p71mrp` cumulative reference remains separate, author/overlap unresolved; do not add the three archives as independent studies. Old `build_estimates.py` study identity hashes normalized source and full numeric vectors and *may* deduplicate the first two, but this run did not rebuild the estimator or verify its dedup output.

**Executed checks:** fetched exact branch blobs, parsed full archived 1,180-estimate JSON, applied the inequality deterministically and matched all 15 output IDs to the full current-protected Lua baseline. Source file values and Git SHAs recorded above. **Not executed:** original source reharvest, estimator rebuild/tests, actual Lua decision/tooltip, synthetic-price run, current-character eligibility or live Retail check. **No new independent measured casts, P(hit), quality/rank, skill coefficients or gold EV.** No original files, worker checkpoints, owner integration branch, main, PR, schedules, releases or addon code changed.
