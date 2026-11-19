# Manager gate — BfA Tidespray Bracers: source-level DE means usable, runtime input identity unresolved

Verified November 19, 2026 on research branch pre-review head `dc9f64dbc517718a78759c28d8f77b6450de0417`, against source blob `a512e16fe8a87c23232b3bf73fbcc01957d7624a`, generated estimates blob `15ae8c5b7f7b2587ceff1dcd3e8b9d13d4351d1e`, study audit blob `eb95c9d5e1861c3dbb5fdaa7135264c7d38d7057`, and estimator implementation blob `0b09b553fef4214af8aaa93f1c85061956643711`. **196/196 bounded JavaScript field, group, lineage and static code-path assertions passed.** No Python estimator, native Lua, synthetic-price ItemDB/tooltip, WoW client, or market-price testing occurred.

## NEW study and field gate

The legacy worker [2026-11-19 07:48 source file](../legacy/20261119T0748-bfa-tidespray-bracer-disenchant-originals.jsonl) has **ten source-transcribed material total rows** from **three original links/four rarity arms**, not ten independent studies and not four independent 1,000-craft experiments. All rows have a stated **completed disenchant denominator** and exact output material IDs. They therefore support source-conditional **unconditional mean units per DE** without any invented occurrence probability, hit count, zero-bin histogram or observed stack range. Source-specific means, not live Retail predictions:

| Reported source and context | Completed DE | 152875 Gloom Dust per DE | 152876 Umbra Shard per DE | 152877 Veiled Crystal per DE |
| --- | ---: | ---: | ---: | ---: |
| [Dec 2019 Reddit ebo0z5](https://www.reddit.com/r/woweconomy/comments/ebo0z5), blue bracer procs | 4,730 | 6997/4730 = 1.479281 | 10098/4730 = 2.134884 | 1169/4730 = 0.247146 |
| [Etamalgren Wowhead spell 257103](https://www.wowhead.com/spell=257103/tidespray-linen-bracers), green arm | 852 | 7583/852 = 8.900235 | not reported | not reported |
| Same Etamalgren original **1000-craft** study, blue arm (not another independent 1000) | 148 | 221/148 = 1.493243 | 326/148 = 2.202703 | 39/148 = 0.263514 |
| [May 2020 Reddit gdmjtv](https://www.reddit.com/r/woweconomy/comments/gdmjtv), **mixed green/blue** | 1,000 | 7777/1000 = 7.777 | 304/1000 = 0.304 | 42/1000 = 0.042 |

Total source-stated DE operations across these independent experiments = **6,730**, partitioned 4,730 blue + 852 green + 148 blue + 1,000 mixed. Do **not** pool as 6,730 homogeneous gear casts or assume mixed-quality distribution. The source reports 852/148 within one 1,000-craft experiment. Etamalgren's original displayed Wowhead comment was independently inspected and confirms its 1,000 crafts, 148 rare, 852 uncommon, Iwen's Rod, and exact material totals. The two Reddit original pages were not fetchable this run: their totals and claimed operation context were checked against the current GitHub worker transcription, **not independently verified live**. A duplicate check found none of these four `studyKey` values in the currently generated study audit; that is **not** a complete historical source archive deduplication.

## Missing source-to-valuation identity

All ten rows set `inputItemID:null`, `gearGroup:null`, `inputRank:null`, and use qualified `inputName` strings (rare, uncommon, mixed). The current estimator `key_of` would create distinct `family:Tidespray Linen Bracers (rare/blue ...)` / green / mixed keys when no exact name match exists. These are **not verified item-instance identity keys** and must not be silently assigned to either [Horde 154692](https://www.wowhead.com/item=154692/tidespray-linen-bracers) or [Alliance 161984](https://www.wowhead.com/item=161984/tidespray-linen-bracers). Nor may the narrow crafted-bracer yields be projected to all Battle for Azeroth rare armor. The existing generated estimator has one `gear:7:2:armor` Gloom Dust model (8 study casts, mean 5.25) and **no `gear:7:3:armor`** model; these new source rows have **not** been rebuilt/imported and do **not** establish new runtime coverage. Correct gear/item/rarity/bonus and patch eligibility before admission.

Every new source row has `castsWithDrop:null`, `histogram:null`, `minSeen/maxSeen:null`, no documented numeric input/output rank or faction ID. Therefore **P(hit), conditional stack range, confidence calibration, 2026 Retail eligibility, character status, profession skill and actual gold decisions remain unknown**. Reported mean units may be valued when input identity, context and price are appropriately supported, without fabricating probability. Do not infer that unreported green cooutputs have measured zero probability.

## Reviewer next step / scope

1. Confirm original Reddit item/quality and completed-DE wording, including any disenchant bonuses, and check separate historic sources for exact faction output item IDs and bracer quality/bonus at DE. Preserve both the original four arms and their distinct Iwen's Rod context.
2. Check original-source ID/total vectors against archival imported studies before admission; an empty current study-audit match alone is insufficient. Propose correction or explicit bracer-family evidence profile on a separate **research-only reviewer branch**. Do not change the protected owner three-pass addon branch.
3. If exact context is supported, test source averages in a real estimator build then synthetic-priced ItemDB/tooltip fixture with known eligibility. Keep rate/change epoch and missing chance/range explicit.
4. Higher-priority present-context worker tasks remain Midnight 237362 / 236761 at-cast rank+zero-inclusive logs and TWW 222833 Rare Resourcing true-state; those workers remain assigned.

No original evidence edits, added probability, production main modification, competing addon PR, merge, release, schedule or claimed current-client verification.
