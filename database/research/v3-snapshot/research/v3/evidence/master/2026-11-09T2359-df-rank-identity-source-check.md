# T0046 / T0041 — Dragonflight ore identity concordance and one fixed-stack mean

Checked UTC: 2026-11-09T23:59:38.389Z. Manager-owned source verification only; no new independent operations, addon mutation, measured chances or live price valuation.

## Nine quality-rank/item-ID alternatives, individually source-checked

All quality labels below are **crafting reagent ranks**, not item rarity, output probability or percentile. These are separate item IDs; do not pool ranked cohorts. The source is live **Retail** commodity metadata (GoldCap), which reports the exact displayed "Quality rank X of 3" and "Item ID" on each page. It is a **secondary commodity source**, not the Blizzard Game Data API or a live-client tooltip. This corroborates a previously raised S19 candidate but **does not satisfy S19's outstanding authoritative client/API proof** or retroactively validate source rank assignments.

| Ore family | Q1 input | Q2 input | Q3 input | independently checked commodity pages |
|---|---:|---:|---:|---|
| Serevite Ore | 190395 | 190396 | 190394 | [Q1](https://goldcap.gg/retail/us/items/190395), [Q2](https://goldcap.gg/retail/us/items/190396), [Q3](https://goldcap.gg/retail/kr/items/190394) |
| Draconium Ore | 189143 | 188658 | 190311 | [Q1](https://goldcap.gg/retail/kr/items/189143), [Q2](https://goldcap.gg/retail/kr/items/188658), [Q3](https://goldcap.gg/retail/kr/items/190311) |
| Khaz'gorite Ore | 190312 | 190313 | 190314 | [Q1](https://goldcap.gg/retail/us/items/190312), [Q2](https://goldcap.gg/retail/us/items/190313), [Q3](https://goldcap.gg/retail/us/items/190314) |

**Conflicts/hold:** S19 notes AzerothAuctionAssassin's contradictory Serevite order (190394=Q1, 190395=Q2, 190396=Q3) while the checked GoldCap Retail pages show 190395=Q1, 190396=Q2, 190394=Q3, matching prior WowPriceHub/GoldCap citations already recorded in queue T0046. Therefore **new independent concordance for the Draconium and Khaz'gorite sets**, plus repeated Serevite secondary confirmation, not final authoritative resolution. No worker original or queue modified. Get Blizzard item-quality icon/quality-rank API or owner client itemLink, then apply auditable exact-ID mappings, particularly T0046 ar_rules cohorts with explicit Q2/Q3 wording and T0019/T0020 Draconium workbook rows; if first-hand study does not prove ore quality, leave its inputRank null even if item name is known. Do not assign reported ore consumption as casts, multiply diamond units as P(hit), or duplicate original study snapshots.

## New T0041 source-derived unconditional mean candidate for 202484 -> 194123

Independent original [Scalebands of Obsidian Secrets 202484 Wowhead PTR view](https://www.wowhead.com/ptr-2/item=202484/scalebands-of-obsidian-secrets) (also indexed [PTR view](https://www.wowhead.com/ptr/item=202484/scalebands-of-obsidian-secrets)) shows 18 *reported* item-side disenchants; **Chromatic Dust 194123 occurs once with fixed displayed positive stack 2**. Fresh worker record `dragonflight-20261109-2338-006` preserves `casts=18`, `castsWithDrop=1`, `minSeen=maxSeen=2`, but `totalQuantity=null` and `averageShown=null`. If source counts/stacks describe one coherent cohort, source-implied material units are **1 × 2 = 2**, and unconditional quantity **2/18 = 1/9 = 0.1111111111 units per reported disenchant**. P(material present)=1/18 under the same restricted cohort interpretation; this does not establish a full output distribution or skill/build context.

The same original page gives Resonant Crystal **13/18** with **no stack quantity**, and Vibrant Shard **7/18**, displayed positive **1–2**. Do not manufacture totalQuantity for those rows. Their material-positive incidence sum is **13+7+1 = 21 > 18**, so it is invalid to treat output rows as mutually exclusive categories or to infer joint probabilities/unique zero disenchants. The page variant says *Mythic* and PTR **12.1.5**, but that site view is not proof of sampled event game build, item bonus tuple, or profession skill. The fixed-stack calculation is source arithmetic, **not an additional original study, measured player log, or approved current-character gold value**.

No correction/derived-value import was applied; append-only worker originals retain ownership. Next engineering candidate only in isolated research-owned validation: a fixture that derives `totalQuantity = hits × fixedPositiveStack` when truly fixed, source cohort identity matches, and eligibility/epoch/rank gates are explicit. Synthetic prices are not market prices; the protected three-pass implementation remains untouched.

## Validation and limits

Executed: checked the three families' nine exact external Retail commodity metadata pages, compared T0046 queue S19/flags to avoid falsely declaring resolution, read the worker's 10 original JSONL rows, independently checked Wowhead 202484 occurrence/stack display, computed 1×2/18 and 13+7+1. No new casts, real-user auction prices, actual-engine valuation, Lua regression suite, estimator rerun, live WoW client QA, PR, merge or release. MoP Classic illustration excluded.
