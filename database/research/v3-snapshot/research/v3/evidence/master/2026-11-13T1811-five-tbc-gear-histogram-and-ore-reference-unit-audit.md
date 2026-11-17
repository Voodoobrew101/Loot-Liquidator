# Coordinator audit: five historical TBC gear histogram upgrades and Cobalt/Fel Iron references

**Checked (UTC):** 2026-11-13T18:11:56.817Z
**Task scope:** T0042 / T0052 / T0044 / T0022; next priority T0005/T0039/T0045.
**Upstream worker evidence:** [legacy 2026-11-13 17:41Z original transcription](../legacy/2026-11-13T1741-tbc-matched-stacks-and-legacy-ore-reference.jsonl), blob `de830bc66cb8f3f6a116382dddd2b4f65a42ffc6`. This is a **coordinator numeric consistency check** of source-transcribed observations, not a second observational source or new source re-extraction.

## Executed checks and results

Parsed **34/34** worker JSONL records; computed `positiveHitCount = sum(histogram[n])` and `materialUnits = sum(n * histogram[n])` for all. **34/34 reproduce their recorded totalQuantity**. All **16/16** item-side historical disenchant rows also exactly reproduce recorded castsWithDrop. Each of these 16 records explicitly replaces a **different prior record ID**; they are updates of the same five cumulative Looter cohorts, not 16 additional independent studies. No new coordinator-observed operations.

| Historical input and source | Source-reported item operations (one denominator per input) | Upgraded output IDs: reconstructed positive hits / material units; mathematical unconditional units per reported item operation |
| --- | ---: | --- |
| [Bloodfist Legplates 25003](https://www.wowhead.com/item=25003/bloodfist-legplates) | 5,419 | 22445: 3,920 / 13,826 (2.551393); 22446: 1,190 / 1,788 (0.329950); 22447: 100 / 208 (0.038383); 22449: 157 / 170 (0.031371) |
| [Derizu Chestpiece 24880](https://www.wowhead.com/item=24880/derizu-chestpiece) | 2,117 | 22445: 1,632 / 5,682 (2.683987); 22446: 375 / 595 (0.281058); 22447: 14 / 40 (0.018895); 22449: 52 / 52 (0.024563) |
| [Berserker Axe 25206](https://www.wowhead.com/item=25206/berserker-axe) | 934 | 22445: 202 / 707 (0.756959); 22446: 690 / 1,068 (1.143469); 22449: 27 / 27 (0.028908) |
| [Resonating Axe 30364](https://www.wowhead.com/item=30364/resonating-axe) | 188 | 22445: 26 / 108 (0.574468); 22446: 132 / 216 (1.148936); 22449: 1 / 1 (0.005319) |
| [Warp-Shielded Hauberk 30363](https://www.wowhead.com/item=30363/warp-shielded-hauberk) | 24 | 22445: 10 / 39 (1.625000); 22449: 1 / 1 (0.041667) |

**Arithmetic only:** the five distinct historical item-side source tables together report **8,682** item operations (5,419 + 2,117 + 934 + 188 + 24). Their 16 material rows report 8,529 positive material occurrences and 24,528 material units; material hits across rows are not independent operations. For example, 30363's 11 listed positive material hits out of 24 does **not** imply 13 material-free disenchants: other materials, missing rows, co-occurrences and historical variants remain possible.

**Units and uncertainty:** the positive-stack frequencies are worker-reconstructed by rounding original Looter `pctstack` with positive row count. A histogram can sum exactly while still differing from an unavailable event-by-event raw distribution. Conditional positive-stack frequencies, per-item source denominators, item quantities, and current-character eligibility are separate. `materialUnits / sourceReportedItemOperations` is a source-context estimate of unconditional *material units per reported disenchant*, **not P(hit), independently verified current Retail EV, or a newly measured sample**. Input opportunity cost, prices, AH cut, alternative outputs, bonuses, profession skill and actual build are not validated here.

## Separate ore references: exact output identities, but no denominator

- [Cobalt Ore 36909](https://www.wowhead.com/item=36909/cobalt-ore): **six rare-gem reference rows** with output IDs **36918/36921/36924/36927/36930/36933**; 6,926 source-derived positive material units over the six rows. These are additional identities from the **same cumulative source** already supplying six common outputs, not six studies.
- [Fel Iron Ore 23424](https://www.wowhead.com/item=23424/fel-iron-ore): **12 output reference rows**, IDs **21929, 23077, 23079, 23107, 23112, 23117, 23436, 23437, 23438, 23439, 23440, 23441**. The worker's positive-only histograms internally reproduce **118,214** source-derived material units.
- All 18 ore reference rows correctly preserve `casts=null` and `castsWithDrop=null`. The source's cumulative `outof` is **not a verified completed-prospect count**. No per-cast probabilities, zero outcomes, resourcefulness refunds, or actionable gold values can be derived by dividing these totals by those index counts. Do not treat `histogram` on a reference row as a completed-operation distribution.

## Source-to-valuation disposition

1. **Supported historic numerical field, held on context:** the 16 gear material-unit means are arithmetically recoverable from the transcribed source numbers and can be reviewed as provisional historic per-item reference *only with original Looter identity, current eligibility and unit scope visibly labeled*. Their update must replace, never add to, older same-study records. **Do not promote them to present-day positive disenchant recommendations without same-itemLink/bonus/build/skill validation.**
2. **Usable identity / unplaced numeric rate:** the 18 ore outputs have exact item-ID material references and positive-only quantities, but absent completed-cast counts, compatible acquisition epoch, input skill and refund normalization. Keep references accessible for source-gap reporting, not as measured per-cast probabilities.
3. **Pricing and display:** no synthetic-price engine/formatter run, compiled ItemDB delta, reference-selection import, or live character test was performed in this audit. Missing prices, missing probability, missing identity/context and missing display are **different** failure categories. The protected three-pass implementation branch is not modified.

## What remains unresolved and next work

First priority remains independently sourced current Midnight **T0005 / T0039 / T0045** exact input/output rank, original same-patch completed-cast records with per-material 0-inclusive histograms, resourcefulness refunded inputs, unlocks and character skill. For these five TBC gear groups, seek *actual current-Retail* disenchant success/failure with matched full itemLink, bonus/ilvl, build, skill, and complete output IDs/units before treating historical values as current actionable gold. For Fel Iron/Cobalt seek original independent per-click prospect ledger, not additional index snapshots.

**Validation scope:** GitHub JSONL fetch and 34 local JavaScript arithmetic assertions in this run; no new source-page HTML harvest, addon Lua tests, synthetic-price valuation/tooltip calls, actual client test, worker edits, main edits, merge, PR closure or release. Unknown casts, probabilities, unlisted outcomes and coefficients remain unknown.
