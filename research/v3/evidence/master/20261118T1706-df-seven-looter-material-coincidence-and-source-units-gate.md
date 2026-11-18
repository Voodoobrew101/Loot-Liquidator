# Dragonflight seven newly indexed Looter tables: material-incidence overlap and unit gate

**UTC checked:** 2026-11-18 17:05:56.351Z. **Manager role:** source/identity QA, research only. **New input:** `research/v3/evidence/dragonflight/2026-11-18T1632-seven-unindexed-looter-denominators.jsonl` at blob `f3a25aeb949981a3c5004ec2de376e71eaa649cc` (18 rows, 7 item-side tables). These are **not** seven newly verified independent current-Retail character studies.

## Independently checked original item-side tables

All seven indexed Wowhead item pages exposed the relevant **Disenchanting** table, including material count fractions. The first count is a *per-material positive occurrence* and the second is the *provider's cumulative item-side disenchant count*; no event-level links, item bonuses, player skill/spec, timestamps, or quality-specific output identities are supplied. Live and PTR URLs are alternative catalog presentations of a source table, **not independent replications**.

| Input ID | Source | Item operations N (provider) | Distinct material rows | Sum of material occurrence numerators H | H-N positive excess | Displayed stack-size spans |
| ---: | --- | ---: | ---: | ---: | ---: | ---: |
| 197999 | [Windswept Hood](https://www.wowhead.com/item=197999/windswept-hood) | 564 | 3 | 287+265+27=579 | +15 | 2 |
| 194347 | [Expedition Researcher's Hood](https://www.wowhead.com/item=194347/expedition-researchers-hood) | 619 | 3 | 333+266+32=631 | +12 | 2 |
| 198028 | [Sleet Shined Skullguard](https://www.wowhead.com/ptr/item=198028/sleet-shined-skullguard) | 124 | 3 | 65+57+4=126 | +2 | 2 |
| 209937 | [Chartreuse Champion's Gavel](https://www.wowhead.com/item=209937/chartreuse-champions-gavel) | 55 | 3 | 39+16+2=57 | +2 | 3 |
| 209927 | [Summer Soother's Slippers](https://www.wowhead.com/ptr/item=209927/summer-soothers-slippers) | 438 | 2 | 362+107=469 | +31 | 1 |
| 202467 | [Faulds of the Cinderwolf](https://www.wowhead.com/item=202467/faulds-of-the-cinderwolf) | 31 | 3 | 17+14+2=33 | +2 | 2 |
| 194388 | [Obsidian Guardian's Cleaver](https://www.wowhead.com/item=194388/obsidian-guardians-cleaver) | 8 | 1 | 8 | 0 | 1 |

**Math and interpretation:** These are **1,839 item-side reported operations** across seven different items, **not** 18 independent denominators or independently audited casts. Six tables have H>N, with **64 total excess material-positive counts** above their respective N values. For any one source table, **if** all numerators are truly 0/1 per-output event presences over exactly the same N operations, the categories are nonexclusive and some operations must have multiple positive materials. Alternatively the provider rows may differ in event-population/unit semantics or transcription; event-level original evidence is needed to distinguish. **Neither 64 nor H-N is a measured number of multi-output operations**. Never subtract summed hits from N to invent no-output casts, treat individual material chances as a partition summing to 100%, or sum per-output numerators into new independent studies.

**New precise gap:** 13 of these 18 rows carry `minSeen/maxSeen` copied from the rendered `1–N` stack-size span. The source does **not** demonstrate those are observed extrema from this cohort; the estimator `research/v3/tools/build_estimates.py` currently collects them as study observed bounds in `analyze()` (at the `g["slo"]/g["shi"]` append) and can emit `observedRange`/`rangeSource="observed"`. This extends the earlier five-row Looter-provenance risk to **13 newly filed rows**, without implying a compiled build has actually been run here. Keep sourced per-hit stack range as a distinct reference-style field, **not** empirical min/max unless original operation logs prove it. Retain the count fractions and their precise provider aggregate provenance rather than dropping usable hit-only occurrence information.

**Owner source/valuation rule:** `castsWithDrop/N` is a historical provider-reported material occurrence fraction, not an independent current-Retail calibrated probability. `totalQuantity`, actual positive-stack frequency distribution, quality rank and conditional quantity are unknown, so no observed expected quantity or current-gold EV follows. The owner permits *labeled provisional one-unit-positive-yield* modeling where defensible; any such candidate must keep the source era/eligibility/quality flag and cannot be promoted to measured yields or a guaranteed current Retail recommendation. Do not use a source display's 1–3 span as evidence that both extrema happened in the counted events. No current character or live-WoW verification.

## Reproducible bounded source assertion

Read the exact 18 JSONL rows (blob above), group by `inputItemID`, assert every positive count is integer between 0 and denominator, group denominators agree, output IDs are unique within each item group, compare all seven vectors against the linked public Wowhead table, require 13 present paired stack-span fields but no histogram/totalQuantity/outputRank, then calculate `H=sum(castsWithDrop)`, `excess=max(0,H-N)`. **217/217 in-process JavaScript source/schema/vector/unit assertions passed at 17:05:56Z** (one earlier nonpublished check mistakenly expected 12 spans and was corrected to 13 before the completed validation). No Python estimator build, Lua, offline price/render, generated ItemDB, CI trigger or WoW-client test ran in this manager audit; repository CI at worker head is a separate check.

## Coordinator disposition

- Source identity: each input ID is distinct; live/PTR mirrors not independent studies; publication/character cohort epoch still unknown.
- Units: preserve material-occurrence numerators vs reported input operations; categories potentially overlap; quantity totals unknown.
- Display: 13 source stack spans not evidence of measured extreme yields; avoid `observedRange` contamination.
- Economics: do not falsely assert measured Retail expected quantities, zero-disproven materials or incremental actionable gold coverage.
- Scope: original worker rows, queue, strategy, implementation branch and snapshot untouched.
- **Next priority:** produce an isolated, reviewed research-only normalization fixture separating `providerAggregateOccurrence`, `providerDisplayedStackSpan` and `measuredPerCastQuantity`; preserve genuine counts, then seek independent post-release `237362` five-ore and `236761` ten-herb per-event rank/skill/refund data.

