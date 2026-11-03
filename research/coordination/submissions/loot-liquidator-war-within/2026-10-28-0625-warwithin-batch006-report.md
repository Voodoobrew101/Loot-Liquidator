# Loot Liquidator — War Within worker Batch 006 (2026-10-28)

**Live master assignment:** 2026-10-28-batch006-war_within (queue revision 8) supersedes home scope: **35 Dragonflight Serevite Ore rank 2 (190396) records**, GameData.lua L1478–L1512. Source blob `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`; central coverage blob `c686a9582f981a2528454711f98a35d940fbdcb2`. Research branch only.

## Exact first-pass audit

- **35/35** assigned stable keys exist at the exact GameData source line and are **NEVER_EXAMINED** in the live central ledger. All 35 historical TSM tuples pass necessary `matRate * positiveMin <= amountOfMats*5 <= matRate * positiveMax` bounds; this is not proof `matRate` is measured P(at least one).
- **33** quality-labelled outputs form **11 complete R1/R2/R3 triplets** with identical family rates; two unranked outputs are Fractured Glass 192872 and Crumbled Stone 192880. Do not sum three ranks as simultaneous independent drops.
- Input **190396 is Serevite R2**, not R3. Dragonflight quality item IDs are nonsequential: R3 Serevite 190394, R1 190395. Historical TSM source rows label `sourceQuality=2`.
- Per-record independent **current-Retail** confidence: P 25, positive min 30, positive max 30, unconditional E 30, worst 25. **35 EXAMINED_INSUFFICIENT**, zero all-fields >=90, zero approved current-Retail corrections. See attached exact-key CSV.

## New original-source historical cohorts (separate from first-pass count)

1. **R2 Serevite, December 7, 2022:** [12,000 ore experiment](https://www.reddit.com/r/woweconomy/comments/zez5sj) gives 34 total Illimited Diamonds and 15 named output totals. Its 7,000-ore/32-diamond pre-reset and 5,000-ore/2-diamond post-reset subsets overlap this 12,000 total and must not be double-counted. Rank-specific output IDs and actual completed casts unreported. Derived per-five-ore equivalent 34/(12000/5)=**0.0141667** diamonds, not proven per-cast E.
2. **R2 Serevite, January 13, 2023:** [30,000 ore experiment](https://www.reddit.com/r/woweconomy/comments/10b8z7x) reports **20 rank-2 and 6 rank-3 Illimited Diamonds**, 35% Inspiration. Derived per-five-ore equivalents 20/6000=**0.0033333 R2** and 6/6000=**0.001 R3**. Saved ore and actual completed operations unknown; historical patch/skill context differs.
3. **R3 Serevite, December 9, 2022:** [20,000 ore original](https://www.reddit.com/r/woweconomy/comments/zh53dd) reports 13 output totals including 29 diamonds, 5,804 Crumbled Stone and 5,132 Fractured Glass; reported 265 skill breakpoint. This is **different input 190394**, not directly assigned 190396. Actual completed cast count not given.
4. **R3 Serevite, January 10, 2023:** [8,000-operation original study](https://www.reddit.com/r/woweconomy/comments/108782r) reports 43 rank-3 Illimited Diamonds, 10,288 Fractured Glass, 11,472 Crumbled Stone, 261 Prismatic Ore, and **2,650 ore saved**. Character reports skill 283, difficulty 265, Inspiration 15%, Resourcefulness 22%. Historical E for R3 diamonds is **43/8000=0.005375** per reported operation; no per-cast occurrence or conditional yield distribution. Resourcefulness saved **2650/8000=0.33125 ore per reported Dragonflight cast**, or 6.625% of nominal 40,000 ore. Not portable to TWW.
5. **R3 Serevite, January 22, 2023:** [400,000 ore experiment](https://www.reddit.com/r/woweconomy/comments/10i63zb) reports **591 diamonds** at skill 266, explicitly excluding Resourcefulness-saved ore and Prismatic Ore follow-up. Five-ore equivalent **591/80000=0.0073875**; actual completed operations not given.

All six original-source cohorts are archived in observation-schema-shaped JSONL. Historical data are not current-Retail verification. The sole explicit completed-cast cohort is the 8,000-operation Dragonflight experiment; all other ore denominators remain labelled ore equivalents, not invented actual casts. No P or positive conditional yield is inferred from aggregate totals.

## Parallel numeric hypothesis: TWW prospecting Resourcefulness

**BLOCKED, confidence 0, no formula.** The [September 3, 2024 Aqirite study](https://www.reddit.com/r/woweconomy/comments/1f83cnd) reports 1,040 clicks, 5,200 initially purchased ore and reprocessing Resourcefulness returns, but not actual saved ore or final inventory. Since 1040*5=5200 nominal, those numbers alone cannot identify refunds. A new historical Dragonflight study reports 0.33125 saved ore per cast at 22% Resourcefulness; [another Dragonflight study](https://www.reddit.com/r/woweconomy/comments/10s9ol9) reports 0.26 saved ore per prospect at 17.9% over 10,000 ore. These are **not** TWW same-context cohorts, and cannot justify a universal savings curve.

**Required experiment:** Same-build Algari Prospecting spell 434018 with Aqirite R2 (210934), >=500 actual completed casts per matched Resourcefulness cohort; log each cast's saved ore (including zeros), inventory reconciliation, skill, node ranks, gear, rating and percent, patch and independent replication. Apply only to effective input consumption, never gem output.

## Validation and handoff

35 unique assigned keys, 35 source line/ID checks, 35 ledger checks, 35 necessary bounds, 11 quality triplets and six source cohorts checked in memory. **External JSON Schema validation, repository Node tests and WoW client tests were not run.** Master acceptance pending; central baseline 959 NEVER_EXAMINED before these 35 pending keys. No master-owned files, main, production Lua, TOC or ledgers edited. First pass is not the >=90 all-fields gate.

**Next exact targets:** master review of attached 35-key CSV; original TSM `matRate` semantics; current-Retail zero-inclusive R2 Serevite output-rank observations; and matched TWW Aqirite Resourcefulness refund logs.
