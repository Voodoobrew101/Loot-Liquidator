# War Within worker — Batch 005 (2026-10-28)

**Assignment:** `2026-10-28-batch005-war_within` (master queue revision 7); research branch head at read `f17e1389f76ec3addca60bba9f045b50f8176282`. Actual GameData blob `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`, central ledger blob `3581deee9d71efaebbeada5f117d304e8d6ad51b`. No production or master-owned writes.

## 35 distinct Dragonflight overflow first-pass reviews

| Input | Rank | Assigned output rows | Source |
|---|---:|---:|---|
| Khaz'gorite Ore 190313 | 2 | 15 | GameData.lua L1347–L1361 |
| Khaz'gorite Ore 190314 | 3 | 20 | GameData.lua L1364–L1383 |

All 35 assigned keys were `NEVER_EXAMINED` in the live master ledger at read. Historical TSM `amountOfMats` was normalized exactly once from per-ore to per-five-ore E. All 35 pass the **necessary** `matRate × positiveMin <= E5 <= matRate × positiveMax` proxy bound. This does NOT establish that TSM `matRate` is independently observed P(at least one), or that historical min/max are current-Retail guaranteed bounds.

**Quality duplication:** Ten complete gem-family rank triplets repeat identical historical TSM rates across R1/R2/R3. R2 Khaz'gorite → Neltharite 192859/192860/192861 each has historical E5=0.2045; summing them to 0.6135 without measured rank selection is unjustified. R3 Khaz'gorite → Queen's Ruby 192837/192838/192839 each E5=0.13; 0.39 is similarly not proven. Source quality is absent for byproducts and was not invented. [Dragon Isles Prospecting 374627](https://www.wowhead.com/spell=374627/dragon-isles-prospecting) consumes five ore; [Khaz'gorite quality ranks](https://thewowdb.com/item/khaz-gorite-ore-190312/) confirm 190313=R2 and 190314=R3.

**Independent field scores (all 35):** P 25/100, conditional positive min 30/100, conditional positive max 30/100, unconditional E 30/100, worst 25/100. Unknown actual source casts, sample count, patch/build, skill/spec, profession gear, rank-transition distribution and output zeros. **35 EXAMINED_INSUFFICIENT; 0 ≥90; 0 approved numerical corrections.**

### Original Khaz'gorite cohort denominator audit

[Bugy's original Wowhead comment](https://www.wowhead.com/spell=374627/dragon-isles-prospecting) labels two Khaz'gorite cohorts as 100 each and lists 14 per-ore rates. Treating 100 as ore makes 11/14 and 12/14 output totals fractional (impossible for item counts); 500 ore makes all 28 integral. This suggests 100 five-ore casts but does **not prove actual completed casts** or output quality. Preserve original study as already archived; no invented denominator or rank.

## Separate numeric hypothesis — TWW prospect Resourcefulness

`tww-prospect-resourcefulness-savings`: **UNVERIFIED / BLOCKED**, numerical confidence 0, no formula or parameter. [Algari Prospecting 434018](https://www.wowhead.com/spell=434018/algari-prospecting) consumes five ore. An [October 21, 2024 community discussion](https://www.reddit.com/r/woweconomy/comments/1g8kbaq) reports a 1000-ore stack queues 200 prospect operations and returned ore does not necessarily extend that queue; queue count is not refund count.

The [September 3, 2024 Aqirite study](https://www.reddit.com/r/woweconomy/comments/1f83cnd) says 1040 clicks and 5200 initially purchased ore, with returns reprocessed. Since 1040×5=5200 nominal gross, without other flows the **unreported ending inventory equals unreported refunded ore**. The source does not report either value. Thus the refund coefficient is not identifiable. Previous original study archive is referenced, not duplicated.

**Required experiment:** same-build R2 Aqirite (210934), recipe 434018, ≥500 completed casts per matched Resourcefulness cohort, per-cast saved-ore counts including zeros, pre/post inventory, skill, specialization ranks, gear, exact rating and percent, plus independent replication. Apply verified savings only to effective input consumption, not gem output.

## Validation and handoff

35 unique exact assigned records, 35 ledger checks, 35 line/ID matches, 35 necessary bounds, 10 quality triplets and 28 Bugy integer-denominator checks passed. Research-only in-memory JS assertions; **external JSON Schema, repository Node suites and in-game testing not run**. No main, GameData.lua, addon Lua, TOC, shared assignments, PROGRESS or central ledger changed.

**Next exact targets:** master acceptance of the 35 stable keys in attached CSV; rank-labelled Khaz'gorite per-cast zero-inclusive outputs; original TSM `matRate` semantics; controlled TWW Resourcefulness saved-ore distributions. The master ledger at read had 1109 NEVER_EXAMINED; these 35 remain pending master acceptance, not yet deducted. First pass is not the all-fields ≥90 gate.
