# Coordinator: scaled plate source identity and bonus-context audit — 2026-11-16

**Scope:** Research-only retrospective source identity QA; no new player processing cohort, no newly usable Retail expected value, and no addon/owner-branch changes. This corrects the prior checkpoint's description of item 25003 as a "new" static source lead. The source had already been captured.

## Prior 25003 records found

- `research/v3/evidence/legacy/2026-11-01T1936-warmaul-retail-eligibility-conflicts-arcanoweave-boots.jsonl`, record `legacy-20261101-11109`: exact [WoWDB LIVE Bloodfist Legplates 25003](https://www.wowdb.com/items/25003-bloodfist-legplates) **Cannot be disenchanted**, item level 32, plate legs. The recorded notes already recognize the historical contradiction.
- `research/v3/evidence/legacy/2026-11-02T1042-tbc-scaled-gear-disenchant-eligibility.jsonl`, record `legacy-20261102-110003`: **same item ID and same WoWDB URL**, another static noDE entry. This is not independent evidence.
- `research/v3/evidence/legacy/2026-11-01T1644-matching-tbc-armor-weapon-looter.jsonl`, records `legacy-20261101-9101..9104`: one [Wowhead cumulative item-specific Looter](https://www.wowhead.com/item=25003#disenchanting) source study, reportedly **5,419 historical DE operations**, four output-positive counts: Arcane Dust 22445 **3,920**, Greater Planar Essence 22446 **1,190**, Large Prismatic Shard 22449 **157**, Lesser Planar Essence 22447 **100**. All four have `totalQuantity=null`; source build, input bonus, skill and source epoch unknown. Not four independent cohorts and not four current-player probability/EV observations. The source is not evidence that the 2026 static item-level-32 variant is currently disenchantable.
- The November 16 new coordinator lead repeats the **already present November 1/2** original static source. **No new source identity** for 25003 was established today; prior manager status should be read with this correction.

## Latest Legacy 2026-11-16T1150 ten noDE records: bounded deduplication

Inspected **52 filename-selected** scaled/eligibility/looter Legacy evidence JSONL files out of **263 total** Legacy JSONLs at research head `1650026c97c1fa57789399191ea209a37bd6c29c`. Exact same **item ID + WoWDB URL** existed before for:

| New row item ID | Earlier first/source-matching evidence |
|---|---|
| 25012 | `2026-11-07T0547-tbc-scaled-conqueror-armor-weapons.jsonl` |
| 25013 | `2026-11-13T1556-scaled-tbc-no-disenchant-and-gloves-yield.jsonl` |
| 25022 | `2026-11-06T1453-bfa-pigment-averages-and-tbc-discharge-eligibility.jsonl` (also 11-07) |
| 25025 | `2026-11-08T1444-bogslayer-warlord-retail-eligibility.jsonl` |

The **other six** new rows `25014..25019` were **not found in those 52 filename-selected candidate files**; they are **not claimed archive-wide unique**. All ten are reference metadata only, not independent attempted disenchant operations.

For **25025 Warlord's Iron-Gauntlets**, prior `2026-11-13T1646-tbc-looter-positive-stack-quantities.jsonl` records a *cumulative*, mixed-era item-side table at [Wowhead item 25025 with bonus=6654](https://www.wowhead.com/item=25025/warlords-iron-gauntlets?bonus=6654): **5,136** historical reported DE operations, output-positive counts **3,973** (Arcane Dust 22445), **976** (Greater Planar Essence 22446), **140** (Large Prismatic Shard 22449). Source transcribed positive-stack histogram totals independently reconcile to their stated hits and summed output quantities; denominator epoch, eligibility, real bonus application and character scope remain unknown. [WoWDB LIVE 25025](https://www.wowdb.com/items/25025-warlords-iron-gauntlets) independently displays the *base static* item-level-32 `Cannot be disenchanted` flag. **Do not treat a query parameter as verified player-instance metadata** or historical Looter as a 2026 eligible Retail cast. Variants can only be resolved by actual itemLink/bonus, build and attempted event.

## Checks and limitations

- **28/28 bounded JavaScript assertions passed**: nine original JSONL files parsed; item+URL duplicates, 25003 prior study identity/hits, 25025 histogram weighted quantities, and latest ten item IDs verified. No assertion failed.
- **52/52 filename-selected candidate JSONL files read as UTF-8 and parsed** during the broader source search; this **was not an exhaustive scan of all 263 Legacy JSONLs**. No code/test runner, Python estimator, Lua runtime, offline gold-value rendering, real-character QA or observed client disenchants were executed.
- Independently re-opened WoWDB LIVE pages **25003 and 25025** on November 16: both flag cannot disenchant at item level 32. These are *catalog references*, not direct failed operation tests.
- Prior research evidence files are append-only and unchanged. Neither a 5,419 nor a 5,136 historical cumulative denominator may be used to justify present-character Retail eligibility, and no new modern EV was established.
- **Next:** do not recrawl these exact WoWDB pages or duplicate existing 25003/25012/25013/25022/25025 flags. For gating, obtain a dated 2026 Retail client itemLink/bonus/ilvl/skill/build and a witnessed successful or failed DE attempt. The higher-value numeric priority remains T0039: original post-hotfix Midnight `237362/237359` per-output item IDs, zero-inclusive completed-operation histograms, skill/unlock and Resourcefulness refund ledger.
