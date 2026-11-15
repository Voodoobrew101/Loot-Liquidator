# ReagentMaker 2015 prospecting source contract: model prior, not measured Retail cohort

Audit at 2026-11-15 16:03 UTC, research head checked `e8f25db59d2de69b96981f6b65d2aca5b86da599`. Research-only provenance/units analysis. The Legacy worker independently added the original source transcription in `research/v3/evidence/legacy/2026-11-15T1549-reagentmaker-2015-cobalt-feliron-adamantite-reference.jsonl` (blob `0a039d3ff0af2b1127b709c92db1e5f5a3ef3b45`). Do not edit or duplicate it.

## Original source and exact scope

Primary archived 2015-07-30 ReagentMaker source, revision `42baf007f3c7`: https://repos.wowace.com/wow/reagentmaker/file/tip/ProspectingData.lua?style=paper . Its header explicitly credits Enchantrix (no original numeric study or denominators linked). Its recipe tuple documentation distinguishes a conditional one-item coefficient `{reagentID, numberNeeded, chanceToHaveOne}` from the separate minimum/maximum-produced representation. Therefore each literal `{ORE,5,p}` is a **historical source-model chance for one output** from five input ore, not a material count per ore, observed casts, modern Retail drop rate, or an output-quantity histogram.

The complete *new transcription* has **36 item/output rows**, **three** input/source model groups, **zero** newly observed completed casts or source-specific hits, and **no** measured output totals/zero bins. The original source's input/output IDs and rates agree with the transcribed rows at the group and frequency level:

| Source input | Six uncommon coefficients | Six rare coefficients | Sum of twelve per-output coefficients |
| --- | --- | --- | ---: |
| Cobalt Ore (36909) | 25% per output | 1.3% per output | 1.578 |
| Fel Iron Ore (23424) | 19% per output | 1.1% per output | 1.206 |
| Adamantite Ore (23425) | 19% per output | 3% per output | 1.320 |

These are sums of **individual, potentially simultaneous** output chances, not a mutually exclusive probability distribution. Do **not** normalize them to 100%, count them as 36 studies, or treat a sum as an observed number of gem units. The source's explicit `chanceToHaveOne` makes an **assumed one-unit conditional yield** a *defensible labeled provisional reference* under the owner's November 2 policy where no stronger compatible quantity exists. For example, a model-only Cobalt common outcome at `p=0.25` would price `E=0.25` per five-ore cast **under that assumption**, not `0.25` measured units or `0.25` per ore. No recommendation with actual prices, eligibility, skill or contemporary Retail correctness is validated.

### Economic-unit reconciliation: Cobalt

Historical frozen TSM data had for the same Cobalt common output `matRate=0.235`, range `1..2`, but untrusted `amountOfMats=0.5` **per input ore**: blindly multiplying by five ore produced `E=2.5` *per gem* despite `P(hit)=0.235`. The separately sourced 2015 `chanceToHaveOne=0.25` is within **1.5 percentage points** of the original TSM occurrence coefficient but yields a **10-fold lower reference one-unit expected quantity** compared with the invalid 2.5-per-cast projection. This is **cross-source consistency evidence**, not proof Enchantrix and TSM are independent or a new measured rate. The owner's protected three-pass candidate **already** has a Cobalt regression fixture requiring `referenceOriginal.expectedQuantity==2.5` but corrected modeled `expectedQuantity.value==.235` (`tests/test_reference_fallback.lua`, blob `4592d2a6cd955a2d855ad38ee9763b3ce50cec5`); do not overwrite or claim to have fixed it here.

### Missing and overlapping output identity

The same original 2015 source also has a separate `ADAMANTITEPOWDER` input tuple `{ADAMANTITE_ORE,5,1}` (item 24243) that the 36 **gem-only** worker rows do not transcribe. This is *not* newly absent from the entire corpus: earlier distinct 2021 TBC Classic-era player reports in `research/v3/evidence/legacy/2026-10-30T2245-feliron-adamantite-original-studies.jsonl` already record Adamantite Powder totals 2,051 from 2,051 and 140 from 140 historically reported prospects (`legacy-20261030-826`, `legacy-20261030-833`). Do not re-add them as novel independent casts or assume the 2015 historical table proves a current Retail powder drop.

## Static checks performed and boundaries

**20 guarded JS source-shape/code assertions passed:** 36 unique IDs, three shared source keys, each input with 12 outputs, exact six-plus-six coefficients, five-ore batch and per-cast source units, all measurement fields genuinely null, model classified `sourceKind=reference`, estimator's reference-prior and provisional `e=p*mid` paths present, and existing candidate Cobalt regression fixture preserved. Original ReagentMaker source table and tuple documentation independently inspected at the archived URL above. Compiler `research/v3/tools/build_estimates.py` inspected at blob `0b09b553fef4214af8aaa93f1c85061956643711`. **Not run:** Python estimator/full migration, Lua resolver/valuation/tooltip, full GitHub CI at final research head, WoW client, live AH prices. No new Retail completed casts, fitted probabilities, verified character eligibility or supported gold decisions.

**Next highest-value new evidence:** obtain original **current Retail** five-ore prospect operation counts, positive-cast counts, output-unit totals/0..N histogram and at-cast eligibility for these exact input/output IDs. Until then preserve this archival source as a nonindependent *reference/model prior*, review whether its explicit yield-one scope reaches the candidate's gap-only reference selection (without overwriting valid values), and resolve identity/epoch before any stronger valuation claim. PR Director retains integration and protected three-pass branch ownership.
