# 2026-11-19 02:04 UTC — Pioneer's Cloth Cuffs: Rare Resourcing conditional-intake gap

**Scope:** Research-only, source-to-generated-estimate audit. No addon edits, no claim of in-client or offline addon-engine valuation. Source [2024-10-22 original Reddit experiment](https://www.reddit.com/r/woweconomy/comments/1g9l8t8) states 7,250 initially crafted cuffs, 402 further crafted from **Tailoring** Resourcefulness, **7,652 completed disenchant operations**, Enchanting 100(+40), maxed Disenchanting Delegate (DD) and Rare Resourcing (RR). The 25.3% Resourcefulness is in Tailoring, **not** a Disenchant refund. Current worker [eight append-only corrections](../war-within/20261119T0124-pioneer-cuffs-source-batch-denominator.jsonl) retain this cohort under studyKey `reddit-1g9l8t8-pioneer-cuffs-7652`. Original text confirms the denominator and conditional RR context; worker-transcribed material totals were checked against the **existing generated estimates**, not independently re-extracted from an image in the post.

## Scoped numeric result — unconditional output means are real source-context units, not hit chances

| Output ID | Description | Source-reported units | Units / 7,652 completed DE |
| --- | --- | ---: | ---: |
| 219949 | Gleaming Shard rank 1 | 3,137 | 0.409958 |
| 219950 | Gleaming Shard rank 2 | 4,703 | 0.614611 |
| 219951 | Gleaming Shard rank 3 | 2,777 | 0.362912 |
| 210796 | Mycobloom rank 1 (**RR side output**) | 464 | 0.060638 |
| 210930 | Bismuth rank 1 (**RR side output**) | 510 | 0.066649 |
| 212667 | Gloom Chitin rank 1 (**RR side output**) | 501 | 0.065473 |
| 212664 | Stormcharged Leather rank 1 (**RR side output**) | 477 | 0.062337 |
| 222795 | Spool of Weaverthread rank 1 (**RR side output**) | 501 | 0.065473 |

The three shards sum to **10,617** reported units (**1.387480 per DE**); five RR side outputs sum to **2,453** reported units (**0.320570 per DE**). Combined observed context means are **13,070 / 7,652 = 1.708050 material units per DE**. At an **illustrative, artificial 100-copper price for each distinct material unit**, the RR bonus adds **0.320570 × 100 c = 32.057 copper gross value per DE** to a DD+RR-maxed character's outputs. This is *not* live profit/market price, cannot be assumed for a no-RR character, and no per-output occurrence probability, positive stack histogram, observed min/max or current build applies.

## Reproduced stage gap in exact existing compiled research artifact (NOT addon)

Research head `3c384b93afbf037c26f0680efaa2d3396c6ed5cd`, original correction blob `64ba969e0f9de0e59dcd3012a2124ad11a2c61a7`, generated estimate blob `15ae8c5b7f7b2587ceff1dcd3e8b9d13d4351d1e`. Read the existing `research/v3/output/estimates.json`: all **eight** 222833 disenchant outputs are labeled `conditional:false, requires:null`, including all **five** documented RR-only side materials. Their `averageSource:measured` appropriately reflects context-specific totals/7,652, but their `chanceSource:estimated` is simply `average / assumed midpoint range 1`, not the author's measured hits. In the generated file Bismuth is still `family:Bismuth`; the newly corrected exact ID `210930` is in the append-only worker record and needs a fresh, tested rebuild before making claims about the final artifact.

The current `research/v3/conditions.jsonl` (blob `8cacbbe6fcd20a1d3bc4cde8013343f29f6a42fb`) contains **no** `Disenchant` condition for these five output IDs on 222833. The current `build_estimates.py` (blob `0b09b553fef4214af8aaa93f1c85061956643711`) gates studies only when `condition_for(...)` returns a requirement. As written, its `unlock_state_from_text` does **not** recognize `"DD and RR maxed"` as an explicit unlock signal: it matches `max spec`, not `maxed`. Adding conditions *alone* will skip this genuinely maxed study; it will need a source-backed structured `unlockState:true` correction or reviewed equivalent, never a guessed generic skill curve. These are source/code/generated-artifact findings, **not** a rerun of Python or a demonstrated live-tooltip issue.

## Required safe reviewer action (separate scoped branch; not owner three-pass branch)

1. Preserve all eight source original rows and worker replacements. Establish an **input-scoped, profession-unlock** condition for the five RR side-output IDs, with explicitly unknown minimum skill/points (only **maxed** is observed). Avoid globally making the same reagent conditional for every disenchant item or another profession's output.
2. Confirm structured `unlockState:true` on *this* original DD+RR-maxed cohort; prove an RR-absent/unknown profile excludes side outputs but a specifically eligible RR profile can price the original **unconditional expected unit quantity**. Do **not** multiply it again by a derived chance. No observed probability, output histogram or generic current-Retail profile proof exists.
3. Run the **actual** Python estimator, deterministic source lineage/replacement audit, offline ItemDB resolver/valuation/rendering at synthetic prices, native addon regression and exact-head CI before claiming repaired gold coverage. Check the corrected Bismuth `210930` identity and no double count of old/new study.
4. Keep the 2024 source epoch distinct and the **Tailoring** input-saving boost separate from disenchant rewards; no unverified Multicraft coefficient, live current-behavior claim or production main/owner integration write.

**This run's verification:** 105/105 bounded in-process JavaScript assertions passed against eight correction rows, eight existing generated 222833 estimates, current conditions file and the estimator text, plus explicit unlock-phrase inspection. The primary Reddit text was independently re-read for cohort conditions and 7,652 operations. No Python estimator invocation, new build, native Lua suite, actual offline addon renderer or WoW client run was performed. Main `bddd2c160f9f361647c4846bb42f57135045659c`; owner integration `3d667d053db587c91401cfed7ecc56862b8340c9` untouched. Research pre-manager exact-head CI [44439667948](https://github.com/Voodoobrew101/Loot-Liquidator/actions/runs/44439667948) succeeded; it does **not** attest to the evidence/status/dashboard commits after this checkpoint. PRs #22/#23 closed unmerged; #74/#75/#77 research-only open.

**Priority:** Conditional AA: reviewer fix the RR no-unlock economic contamination before promoting 222833 into usable generic Retail results. Continue worker-owned post-release Midnight 237362 (5-ore prospect) and 236761 (10-herb mill) first-person 0..N/rank/refund/skill collection without repeating exhausted searches.
