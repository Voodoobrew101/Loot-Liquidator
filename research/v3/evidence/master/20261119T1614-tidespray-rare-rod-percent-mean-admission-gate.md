# Manager gate — 2020 Tidespray rare-bracer `perInput` rates are quantity, not occurrence

Checked 2026-11-19 UTC on research prewrite head `c2c2c75627266901a5cc8bd61f0e68d2787e443f`, new Legacy evidence blob `51ca9036fcbd54b75dc1e517bff6320946f53256`, prior original evidence blob `a512e16fe8a87c23232b3bf73fbcc01957d7624a`, estimator blob `0b09b553fef4214af8aaa93f1c85061956643711`, and generated-estimates blob `15ae8c5b7f7b2587ceff1dcd3e8b9d13d4351d1e`. **35/35 bounded connector-side JavaScript field/arithmetic/dedupe/code-path checks passed**. A new original Wowhead comment was directly reopened; Reddit could not be fetched here. No Python estimate rebuild, Lua test, synthetic-price runtime/tooltip test or live WoW test.

## Distinct new numeric source and precise units

Legacy's new [2026-11-19 15:54 source transcription](../legacy/2026-11-19T1554-bfa-tidespray-three-original-de-cohorts.jsonl) contains **11 material rows / four labeled cohorts / three source-page URLs**. Most importantly, the [original edwallols Wowhead item comment](https://www.wowhead.com/item=161984/tidespray-linen-bracers) explicitly reports **3,384 disenchanted rare-quality Alliance Tidespray Linen Bracers, historical ilvl 233, with Iwen's Enchanting Rod**. It separately reports 28,000 *crafted* bracers, which must **never** be counted as 28,000 disenchants. The original explicitly states material output percentages per rare DE, including a rate above 100%; these are units per 100 completed operations, **not material P(hit)**.

| Output | Original rate per 100 completed DE | Conditional source-normalized unconditional expected units per completed DE |
| --- | ---: | ---: |
| Gloom Dust 152875 | 149.0839243% | 1.490839243 |
| Umbra Shard 152876 | 215.0118203% | 2.150118203 |
| Veiled Crystal 152877 | 24.793144% | 0.24793144 |

These three source averages are valid arithmetic on the original published rates, **not observed integer output totals, sample histograms, hit probabilities, ordinary generic rare-armor expectations, or current-Retail rates**. No `castsWithDrop`, output 0/1/2 histograms, measured stack bounds, output ranks, exact collection date, modern gear instance, or comparable no-Rod source was supplied. The current visible item tooltip is ilvl 18 versus author's historical 233. Iwen's Rod and rare proc are important scoped modifiers; do not pool with green bracers, base gear, non-Rod or current Retail without proof.

## An exact prior cohort was re-transcribed

The new three mixed-rarity 1,000-operation original-poster `reddit-gdmjtv` rows **exactly duplicate** old `legacy-20261119-908..910` from the [07:48 archive](../legacy/20261119T0748-bfa-tidespray-bracer-disenchant-originals.jsonl): same source URL, casts=1,000, output IDs 152875/152876/152877 and total units **7,777 / 304 / 42**. Different `studyKey` and qualified `inputName` strings are NOT a new experiment. Existing [08:00 manager source-identity gate](20261119T0800-tidespray-bracer-source-quantity-identity-gate.md) already documented that original. Hold additive cohort credit; preserve both append-only transcriptions and reconcile via explicit source/cohort identity, not by editing source or relying only on names. The estimator's identity contains source, rank, casts and study vector **within each normalized input/output group**; different unresolved family-name groups can hide this overlap until reviewed mapping. No duplicate-addition into a live output was demonstrated.

The *different Reddit reply* reports 1,000 **crafted** bracers and three material totals; the April Reddit post reports 600 **crafted** bracers and two totals. Their five rows intentionally have `casts:null`. Do not manufacture DE denominators or a mean from crafted counts; no Veiled Crystal observation in the April file is **unknown, not observed zero**. Original Reddit pages could not be reopened during this manager run; only archived source transcriptions were compared.

## Confirmed current pipeline gap

The v3 estimator `chance_from_percent` intentionally accepts only `percentMeaning="perCast"` as a chance, and `unit_average` only accepts `averageShown/averagePer`. `row_use` has no `percentMeaning="perInput"` expected-quantity pathway: for all three edwallols rows, despite `casts=3384`, neither a measured `totalQuantity` nor typed `averageShown` exists. Static code-path inspection therefore shows their valid source-stated quantity rates **would be ignored as means** by the current v3 importer. This is a **usable-but-not-imported field**, not an absent-evidence problem and not proof of a shipped tooltip bug. Prior Legion milling per-input percentages show a similar schema path, but the rare Rod-conditioned 3,384-operation source and exact output quantities here are distinct.

The committed generated `research/v3/output/estimates.json` contains 1,180 estimates and **no input keyed 161984 or 154692**. It predates this new worker source file. No current-character eligibility, net prices, expected gold action, new numerical coverage, or tooltip completeness is established.

## Review action

1. On a **disjoint research-only reviewed correction lane**, retain original `percentShown` and `percentMeaning="perInput"` fields and add a precisely scoped **unconditional expected quantity per completed DE** adapter/correction for the three edwallols material rows. A source rate of X% units per input means X/100 expected units per input, **not P(hit)=X/100**. Use an explicit source/gear/era/Rod context label; if no schema can represent that context without incorrectly broadening gear eligibility, hold numeric admission.
2. Flag the repeated 1,000-mixed cohort with reviewed original identity; do not sum the 07:48 and 15:54 copies or misinterpret two different Reddit commenters under one post as duplicate merely from URL.
3. Before any additive compilation or gold claim, run actual Python estimator and deterministic audit, then the owner's separate three-pass branch's priced offline decision/tooltip tests after explicit integration review. Verify distinct blue/green/faction/rod/patch eligibility first. PR Director owns final integration.
4. Workers continue current priorities: Midnight 237362 / 236761 exact current-rank event/zero/refund logs and TWW 222833 rare-resourcing state. No repeat historical source harvest.

No addon code, owner implementation branch, originals, queue, production main, PR status, worker assignments/schedules, merge or release changed by this audit.
