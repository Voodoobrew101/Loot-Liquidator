# Coordinator source audit: missing Indigo Pigment cooutputs and zero-count range minimum

- Reviewed UTC: 2026-11-07T15:07:03.225Z
- Original author/comment: 180977, historical pre-live Inscription PTR; [Emerald Pigment Wowhead original comment](https://www.wowhead.com/cata/item=39339/emerald-pigment)
- Worker source: `research/v3/evidence/legacy/20261107T1447-ptr-mill-histograms-stormvine.jsonl`, blob `c15765dbd0e4fe1cc6d7f61712419d6e99a5502f`
- Catalog identity corroboration, not original author's item hyperlink: [Indigo Pigment 43105](https://www.wowhead.com/item=43105/indigo-pigment), [milling family table](https://www.wow-professions.com/guides/milling-table-inscription)

## Source-reported cooutputs not included in newest worker transcription

The original post reports Emerald Pigment (EP) positive-unit stack counts **and** an additional "IP" material in each of the *same* three herb cohorts. The new worker file contains the EP rows only (IDs below), not the separate original IP totals. These are candidate **previously untranscribed fields**, not new independent cohorts, extra casts, or current Retail measurements.

| Same original study and worker record | Input item ID | EP positive stack counts, source | IP source total units | Nominal 5-herb mills from source EP stack counts | Arithmetic IP units per nominal mill |
|---|---:|---|---:|---:|---:|
| Fadeleaf `legacy-20261107-7712` | 3818 | 4×2 + 5×3 = 23 EP | 1 | 9 | 1/9 = 0.111111 |
| Goldthorn `legacy-20261107-7713` | 3821 | 12×2 + 14×3 = 66 EP | 10 | 26 | 10/26 = 0.384615 |
| Khadgar's Whisker `legacy-20261107-7714` | 3358 | 0×2 + 10×3 + 12×4 = 78 EP | 14 | 22 | 14/22 = 0.636364 |

`IP` resolves plausibly to Indigo Pigment 43105 from a current item catalog that names these specific herbs; however the original source abbreviates the output name and links no exact item ID. Record catalog identification as *supported secondary mapping*, not a source-stated original itemLink. Preserve this distinction in any eventual field correction. Author's sample was on an older PTR, with patch/collector build, character eligibility, profession, changes to yield, refunds and current Retail operation behavior unverified. The source-reported numerator is a material **unit total**, not a per-output positive-event count. P(hit), zero-inclusive histogram and conditional average for IP remain unknown.

The Fadeleaf source explicitly says **1 IP** over **2.25 herb stacks** but also calls its IP average **0.1 per stack**. These are arithmetically inconsistent: 1/2.25 = 0.444444 per 20-herb stack, whereas 1/9 = 0.111111 per five-herb mill. Do not silently substitute the author's printed rate for either unit; keep original text and numeric count separately. Goldthorn's printed 1.5 per stack and Khadgar's 2.5 per stack are approximately consistent with 10/6.5 and 14/5.5.

## Independently checked positive-stack minimum discrepancy

`legacy-20261107-7714` stores `histogram: {"2":0,"3":10,"4":12}`, `casts=22`, `castsWithDrop=22`, `totalQuantity=78`, `minSeen=2`, `maxSeen=4`. The original source explicitly states **0×2**, so the smallest **positive observed quantity** is **3**, not 2. All positive stack counts sum to 22, and the reported EP total is correct (10×3 + 12×4 = 78). This is a worker-evidence range field correction candidate; no actual compiled ItemDB or tooltip regression was executed or demonstrated.

**Disposition / next owner:** Ask the Legacy worker, in its own append-only correction/evidence scope after whole-corpus original-study deduplication, to retain the three original IP totals, source unit/rank ambiguity and historical context under the **same studyKeys**, and correct the observed EP minimum for record 7714 to 3. Do not overwrite the worker's original JSONL. No unsupported source-derived current Retail probability or best gold action. Controlled synthetic-price engine/display tests belong to a separate reviewed implementation branch if source conditions become admissible.

**Checks performed:** Read the exact 18 worker evidence rows; independently recalculated nonzero histogram counts, quantities and minimum across its 10 histogram rows; re-read original commenter 180977 and separate Indigo Pigment identity catalog. **Not performed:** full cross-corpus duplicate audit, estimator run, actual addon runtime valuation/formatter execution, live WoW character or price verification. Coordinator adds **zero** measured cohorts and **zero** verified current Retail economic decisions.
