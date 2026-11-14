# Manager audit — ten source-backed TWW Looter reference rates omitted by v3 estimator and mapped to broad gear groups
Date checked: 2026-11-14T19:10Z. Scope: research-only static code-path and independent source-record arithmetic. No live-client or addon runtime valuation claim.

## Original record and data lineage

Read the worker's *append-only corrections* `research/v3/evidence/war-within/2026-11-14T1823-looter-original-rank-stack-corrections.jsonl` (blob `fa21647859b9804ebc4c07ab9c7f6e263450c111`). All **10** lines replace previously preserved, **not independent**, `war-within-20261113-2325-001..010` rows from exactly **three** original Wowhead Looter item-page cumulative cohorts, according to the worker's original-HTML review. The ten outputs have exact material IDs and ranks, `casts`, `castsWithDrop`, `totalQuantity`, and per-material reconstructed 0/1 histograms, but **null** `averageShown`, `percentShown`, build, date, skill, spec and actual disenchant item bonus. These are `sourceKind:"reference"`, not controlled current-build measurements.

Source item pages: [212017 Lightless Scavenger's Bonegirdle](https://www.wowhead.com/item=212017), [212044 Gatecrasher's Cord](https://www.wowhead.com/item=212044), [229141 Lamplighter Elite's Polearm](https://www.wowhead.com/item=229141). Public material identity crosscheck: [Gleaming Shard rank 1 item 219949](https://goldcap.gg/retail/us/items/219949), [rank 3 item 219951](https://goldcap.gg/retail/us/items/219951), [Refulgent Crystal rank 2 item 219954](https://goldcap.gg/retail/kr/items/219954), and a [2025 item-ID reagent list](https://www.reddit.com/r/woweconomy/comments/1mmjgm0/enchanting_concentration_alt_macros_i_use/) listing all six rank IDs. These establish catalog identity, **not** character processing eligibility or prices for the historic study. Original item pages did not load through this manager's web browser; raw Looter text is a *worker-reported original-source transcription*, not independently re-scraped by the manager.

## Exact source-record arithmetic (not inferred observations)

A programmatic read of all ten JSONL correction rows checked: every non-null numerator and denominator, sum of the two reconstructed 0/1 bins equals its row's denominator, every source-reported positive stack is [1,1], and `totalQuantity == castsWithDrop`. These are **source-implied per-material expected units per reported item disenchant**, not ten independent samples, new observed event receipts, or present Retail rates.

| Input (one source cohort) | Output rank/item ID | Source units and reported item disenchants | Source-implied units / operation |
| --- | --- | ---: | ---: |
| 212017 epic armor | Refulgent R1 219952 | 21/35 | 0.600000 |
| 212017 | Refulgent R2 219954 | 12/35 | 0.342857 |
| 212017 | Refulgent R3 219955 | 2/35 | 0.057143 |
| 212044 epic armor | Refulgent R1 219952 | 27/42 | 0.642857 |
| 212044 | Refulgent R2 219954 | 10/42 | 0.238095 |
| 212044 | Refulgent R3 219955 | 5/42 | 0.119048 |
| 229141 rare weapon | Gleaming R1 219949 | 48/87 | 0.551724 |
| 229141 | Gleaming R2 219950 | 22/87 | 0.252874 |
| 229141 | Gleaming R3 219951 | 15/87 | 0.172414 |
| 229141 | Refulgent R1 219952 | 2/87 | 0.022989 |

Exactly **164 original source-reported item disenchants** = 35 + 42 + 87; the ten numerator values also happen to sum to 164. This does **not prove** per-event exclusivity, zero total empty events, joint material covariance, independent output trials, or eligibility at a different item bonus/patch. Per-material `histogram["0"]` means **that output** absent in reported events, not "nothing dropped." No 2026 character rate, confidence calibration or hit probability for other builds is derived.

If eligibility and an appropriately labeled historic reference scenario were separately accepted, linear *source-conditional* expected **gross** output values can be priced with distinct rank-specific synthetic price symbols: `212017: (21*C1+12*C2+2*C3)/35`; `212044: (27*C1+10*C2+5*C3)/42`; `229141: (48*S1+22*S2+15*S3+2*C1)/87`. Here Ck/S k denote arbitrary **hypothetical** prices for quality-k Refulgent/Gleaming. These are algebraic checks, not actual engine executions, market values, or live-gold recommendations.

## Two independent v3 source-to-estimate disconnects

**A. Reference numerators are silently unconsumed.** In [build_estimates.py](https://github.com/Voodoobrew101/Loot-Liquidator/blob/implementation/five-agent-completion/research/v3/tools/build_estimates.py), `load()` correctly suppresses replaced originals (lines 90–96). But `analyze()` partitions all ten corrected `sourceKind:"reference"` rows into `g["refs"]` (around lines 746–750). It constructs reference chance only with `chance_from_percent(r)` (`percentShown` and `percentMeaning=="perCast"`), and reference mean only with `unit_average(r,unit)` (`averageShown` and `averagePer`; around lines 789–794). It does **not** apply `row_use()` to reference `castsWithDrop/totalQuantity/casts` (though `row_use` supports these for study rows at lines 266–319). Thus **all 10 new corrected reference rows have neither kind of reference prior and individually fall to `reference:noUsableValue`** rather than contributing their internally valid source rates. Other study/reference data might still supply a group result; this audit proves only the loss of these ten row contributions, not that all addon values are blank. SourceKind distinctions and fallback precedence must be preserved.

**B. Explicit input item IDs lose specificity.** `key_of()` (around lines 188–201) takes the `gearGroup` branch **before** `inputItemID`. All 10 corrected rows specify both. Thus 212017 and 212044 map to the identical `gear:The War Within:epic:armor` key; 229141 maps to `gear:The War Within:rare:weapon`. Even if (A) is repaired, blindly enabling reference numeric means would pool distinct source items instead of keeping the source item-specific provenance/means. The two epic source distributions differ, especially Refulgent R2 (12/35 vs 10/42) and R3 (2/35 vs 5/42). The existing `key_of` logic may intentionally support **gear-group fallback** for aggregated/unknown-item evidence; preserve that capability, but retain explicit-item identity and prevent unexamined cross-item blending when a record provides an exact input ID.

**C. Protected integration branch snapshot is not this feed.** On immutable head `3d667d053db587c91401cfed7ecc56862b8340c9`, a **literal string search only** in `database/sources/ReferenceData.lua` found zero occurrences of input IDs 212017/212044/229141 and output-quality alternative IDs 219950/219951/219954/219955; the file does contain some 219949/219952 occurrences for unrelated contexts. This is not an executed ItemDB, actual synthetic-price valuation, or rendered tooltip audit; dynamic group fallback may exist. No changes to the protected integration branch were made.

## Recommendation / acceptance fixture for engineering owner

1. Admit a labeled *reference* mean from `totalQuantity / casts` **only when** same-source counted-operation denominator, output ID/rank, single positive stack units and compatibility scope are supportable. Do not promote the anonymously pooled Looter entries into controlled independent post-hotfix observations or invent calibrated confidence. Reference wins only a genuine gap under the owner's November 2 source precedence.
2. Prefer exact input item ID for item-specific evidence and support a separate explicit, auditable category fallback for true `gearGroup` records. Maintain three independent source cohorts, ten material-specific rows; do not sum ten denominators as trials. The corrected rows must replace their own original counterparts once.
3. A deterministic **actual** research compiler + ItemDB + offline tooltip/valuation fixture should use distinct symbolic or synthetic prices for all three ranks, verify source-to-field result and correct action gating, assert no duplicate rank/family expected units, verify that missing version/item-bonus/skill yields labeled non-eligibility instead of a guessed live recommendation, and report the ten exact row dispositions.
4. Keep current owner three-pass `implementation/usable-data-tooltips` branch exclusively owned by its implementer. This note is a handoff/QA finding, **not** a competing addon change, an import, a successful compiler run or an authorization to merge.

**Validation performed:** current GitHub branch and source/code fetches, ten-row JSONL parse and numerator/denominator/histogram/replace assertions executed as JavaScript, code-path inspection, catalog identity web crosschecks, protected-branch static literal scan. **Not performed:** `build_estimates.py` execution, native Lua, actual ItemDB evaluation, synthetic-price runtime rendering, build testing, current real-character data, live WoW client QA. Research CI last checked as passing on pre-manager SHA `d83fed02a6c1fd5e67adea5e4e12696bbf353186`; it does not validate this manager note.
