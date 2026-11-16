# Shadowlands beta five-cohort source, units and admission gate — 2026-11-16T13:11:04.976Z

## Scope and primary proof

Independent check of Legacy worker's **new** `research/v3/evidence/legacy/2026-11-16T1300-shadowlands-beta-gear-disenchant-primary.jsonl` (research commit [4ec9994d033a](https://github.com/Voodoobrew101/Loot-Liquidator/commit/4ec9994d033a6571eba0fed178f8d1e9658d7c67)). Original firsthand source: [BilisOnyxia, 2020-09-25 Reddit Shadowlands **beta** enchanting test](https://www.reddit.com/r/woweconomy/comments/izlctn). Indexed original post reproduces all five rarity/slot 5,000-operation tables, material totals and the two 10,000-operation rollups. The original post carries an edit that dust/shard **upgrade** conversions were removed; its original conversion-equivalence prices are **not** reliable current-game gold conversions. The worker record's `source.author=null` can be improved to `BilisOnyxia` by a separate append-only correction, not by editing the original 15 rows.

This is an original historical beta *grouped* research study, not a 2026 Retail experiment, and is not five independent authors. The author did not identify item IDs, item levels or item-version bonus IDs, game build, enchanting skill/specialization, output positive-hit counts, zero-inclusive 0/1/2+ stack histograms or modern eligibility. There is no basis to assign these group totals to an exact present-day item or infer an output occurrence probability.

## Original material unit totals versus per-completed-operation quantities

The three output IDs are Soul Dust **172230**, Sacred Shard **172231**, Eternal Crystal **172232**. All five below are source-reported **5,000 disenchant operations**, one gear input per operation; values in parentheses are arithmetic `source totalQuantity / 5000` **unconditional material units per beta DE**, *not* P(hit), rank scaling, or a calibrated present-day drop rate.

| Source group | Soul Dust total (units/DE) | Sacred Shard total (units/DE) | Eternal Crystal total (units/DE) |
| --- | ---: | ---: | ---: |
| Uncommon armor | 11292 (2.2584) | 0 (0) | 0 (0) |
| Rare armor | 7502 (1.5004) | 7043 (1.4086) | 0 (0) |
| Rare weapon | 7496 (1.4992) | 7016 (1.4032) | 0 (0) |
| Epic armor | 0 (0) | 1712 (0.3424) | 5283 (1.0566) |
| Epic weapon | 0 (0) | 1773 (0.3546) | 5267 (1.0534) |

Author's rare **10,000** aggregate (14998 Dust, 14059 Shards, 0 Crystals) and epic **10,000** aggregate (0 Dust, 3485 Shards, 10550 Crystals) reconcile *exactly* with their armor+weapon parts; **do not count another 20,000 operations**. Six explicit source `totalQuantity=0` output fields are measured zero **units in those entire group samples**, not six independent 0-hit histograms. Some nonzero material outcomes can co-occur within one disenchant; do not manufacture a mutually exclusive material-probability distribution.

## Admission/identity gate

- **Evidence exists:** 15 directly source-reconciled total quantity rows; five beta rarity+kind cohorts and 25,000 source-reported completed DE operations, NOT 75,000 operations from repeating denominator per material row.
- **Scope barrier:** `inputItemID=null` and `gearGroup.itemLevelRange=null`, beta epoch explicitly encoded in `gearGroup.expansion="Shadowlands beta (2020-09-25)"`; no current Retail item-variant, postlaunch patch equivalence, skill, or item-specific eligibility. Current Retail gold decisions and supported exact-item tooltip field gain **zero**.
- **Unit barrier:** unconditional E[units] can be computed from totals/casts for this beta cohort. `castsWithDrop`, per-event quantities and P(hit) are unknown; no `range` can be inferred.
- **Compiler review:** `research/v3/tools/build_estimates.py:key_of` represents group keys as `gear:<expansion>:<quality>:<kind>` and does **not** include `gearGroup.itemLevelRange`. The beta string retains a separate key from `Shadowlands`, correctly avoiding silent co-mingling, but is not evidence that current Retail ItemDB will map such keys to eligible gear. Do **not** "fix" beta scope by renaming its expansion to modern Retail.
- **Duplicate scope:** original source ID `izlctn` was **not** present in six selected earlier Shadowlands/legacy JSONL candidates (141 previous rows total). This is *not* a complete 1,159-file research archive source-ID dedupe, and no global uniqueness assertion is made. Source author and exact original publish date are independently identified above.
- **Separate change:** originally discussed bidirectional conversion ratios were edited as removed on the original thread; keep conversion recipe existence and eligibility separate from measured DE source totals.

## Actual validation and next task

**48/48 bounded JavaScript assertions passed, 0 failed** against the connector-read worker JSONL, covering exact rows, original totals, five keys, casts, output identities, source and beta scope, six zeros, missing probabilities/context, rare/epic aggregate reconciliation, and the six-file duplicate candidate scan. Original Reddit table checked by search index; [compiler source](../../tools/build_estimates.py) read for group key behavior. This is **not** Python estimate compiler execution, Lua actual-engine test, synthetic-price tooltip test, in-game client verification, or a full archive deduplication audit.

Before allowing a Retail conversion recommendation, obtain postlaunch/item-instance eligibility + variant/bonus + patch/skill context, then validate actual resolver, valuation and tooltip for a concrete item. The highest-impact **next** numerical task remains Midnight **T0039** (237362 and related current 12.1.5 ores): original completed event ledger, rank-tagged material item IDs, zero-inclusive per-output occurrence histograms, and Resourcefulness refund/skill/unlock conditions. Do not recycle previously exhausted sources. Preserve Legacy worker's original file.

Research heads at source check: main `5dd5aa2f7f05656e7580ea744f657209db59a195`, owner three-pass integration `3d667d053db587c91401cfed7ecc56862b8340c9`, research `4ec9994d033a6571eba0fed178f8d1e9658d7c67`. Exact-head research CI [43871760173](https://github.com/Voodoobrew101/Loot-Liquidator/actions/runs/43871760173) **passed before this manager write**; do not transfer that result to later commits. Research PR #22/#23 closed unmerged; #74 draft. No addon/main/owner-branch writes, worker edits, merge/close/release, new PR or schedule changes.
