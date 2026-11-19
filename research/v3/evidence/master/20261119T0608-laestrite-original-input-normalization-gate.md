# 2026-11-19 06:08 UTC — two NEW Laestrite original-cohort input-unit gates (T0042)

**Classification: historical usable source-reported output totals, not yet imported from these two worker rows; no new current-Retail actionable gold coverage.** This is a separate input/quantity audit from the earlier Shadowlands herb-milling audit. Do not conflate the studies or turn raw ore input into observed prospect casts.

## Exact source lineage

The [original December 2020 Reddit thread](https://www.reddit.com/r/woweconomy/comments/k6fuik) contains multiple distinct 10,000-ore comments as well as the thread author's *different* original 10,000-ore output vector. The latest [legacy worker original](../../evidence/legacy/2026-11-19T0544-two-original-laestrite-prospect-comments.jsonl), GitHub blob `e0929d3d7ee983343b4084938a482b384569eb02`, transcribes **one additional December 4 10,000-Laestrite first-person reply** and **one December 9 19,600-Laestrite first-person reply**, seven material-total records apiece. These two dated source output vectors match the original thread text. The worker does **not** claim the two are physically observed 2,000 or 3,920 casts; `casts`, `castsWithDrop`, histograms, rank, skill, build, exact mass-versus-single recipe, refunded inputs and output-event distribution are all unknown.

| Output (ID) | Dec 4: 10,000 reported ore | Dec 9: 19,600 reported ore | Sum of source units | Units per 5 **reported input ore**, historical |
| --- | ---: | ---: | ---: | ---: |
| Umbryl (173110) | 1,021 | 2,014 | 3,035 | 0.512669 |
| Oriblase (173108) | 1,040 | 1,893 | 2,933 | 0.495439 |
| Angerseye (173109) | 1,024 | 1,937 | 2,961 | 0.500169 |
| Essence of Servitude (173172) | 78 | 138 | 216 | 0.036486 |
| Essence of Torment (173171) | 83 | 178 | 261 | 0.044088 |
| Essence of Valor (173173) | 82 | 178 | 260 | 0.043919 |
| Essence of Rebirth (173170) | 59 | 166 | 225 | 0.038007 |

The final column is **(Dec 4 total + Dec 9 total) × 5 / 29,600 originally reported ore**. These are source-normalized ratios, **not measured occurrence probabilities, observed five-ore cast means, stack-size distributions, refund-adjusted character rates, or evidence of 2026 Retail applicability**. Their aggregation assumes only that both historical comments describe the same named input and output identities. Preserve their separate study keys, dates, original quantities and unknown context for any future compiler candidate. Do not treat the original thread author's separate 10,000-ore experiment as a duplicate of either one.

## Actual admission/valuation comparison

The current [v3 estimator](../../tools/build_estimates.py), `row_use`, cannot admit `totalQuantity` into an expectation when `casts` and typed `inputsProcessed` are both absent; the two worker comments preserve the reported ore counts in `notes` only. They currently follow `totalWithoutCasts` rather than supplying an additional numeric study candidate. The preexisting [generated estimates](../../output/estimates.json), blob `15ae8c5b7f7b2587ceff1dcd3e8b9d13d4351d1e`, **already include all seven Laestrite output models** with average quantities 173110=0.4745, 173108=0.5054, 173109=0.5006, 173172=0.0385, 173171=0.0379, 173173=0.0400, 173170=0.0296. Those are existing compiler values, NOT values produced or replaced by this audit. Their listed occurrence chances are `chanceSource:estimated`, not observed hit counts. Two new historical normalized alternatives differ by roughly +8.0%, -2.0%, -0.1%, -5.2%, +16.3%, +9.8%, +28.4% respectively, but **no priced gold decision or synthetic ItemDB/tooltip rendering was executed**.

Potential acceptance path: have an authorized isolated reviewer confirm whether source-reported 10,000 and 19,600 ore are admissible as typed **processed inputs**, establish original-cohort independence against the preexisting five-study estimator and historical reference table copies, and retain source-specific patch/rank uncertainty. If supported, add append-only corrections (`inputsProcessed`, never fabricated observed `casts`), test that `row_use` supplies *quantity only* without measured P(hit), and check whether the historical input-equivalent mean remains compatible with the supported recipe/context. Preserve the existing usable baseline until the reviewed candidate passes exact original-cohort dedupe, estimator and actual synthetic-price runtime/tooltip regression. No direct owner integration-branch or main edits.

## Bounded reproducible source consistency check

In-process JavaScript parsed **14/14 new worker JSONL records** plus the existing generated estimator JSON from the exact GitHub blobs; **112/112 assertions passed** for original-source quantity vectors, input/output IDs, method, dates, seven distinct outcomes per cohort, null measured casts/hits/histograms/ranks/context and existing compiled model identities. Independently read the original Reddit December 4 and December 9 numeric comments and verified both seven-output vectors. These checks establish only faithful transcriptions and the stated static code/compiled disconnect. No local Python, Lua addon tests, final compiler rebuild, offline engine/formatter fixture, current NPC/game data inspection, price feed or live WoW client was run.

At inspection: research branch `57dced1d20d6823c613043553a636d331d17b913` had completed successful prior-head CI [44467207764](https://github.com/Voodoobrew101/Loot-Liquidator/actions/runs/44467207764); this success **predates** this evidence note. Main `bddd2c160f9f361647c4846bb42f57135045659c`, owner three-pass `3d667d053db587c91401cfed7ecc56862b8340c9`. Research PRs #22/#23 closed unmerged; #74/#75/#77 open research-only. No PR, merge, release, schedule or addon change.
