# TWW Refulgent Crystal: item-version aggregation and listed-outcome bounds (2026-11-08, coordinator)

**Scope:** Research-only source/identity and integer-bound review of the **new** War Within worker evidence file `2026-11-08T0431-new-priest-cloth-and-anniversary-source-hit-cohorts.jsonl`. This is not a new independent player study, not a finished cast log, not a Retail profession/character eligibility test, not a rank-ID mapping, and not an addon gold-valuation test.

## Source provenance / variant test

The original indexed Wowhead **item-side** "Disenchanting" tables show:
* [Confessor's Unshakable Boots, item 229336](https://www.wowhead.com/item=229336/confessors-unshakable-boots?ilvl=678): 122 reported disenchant operations, three same-name Refulgent Crystal rows with 59, 38, 24 positive occurrences. The displayed `ilvl=678` gear version is Epic/Mythic.
* [The *same* item 229336 with bonus 11948](https://www.wowhead.com/it/item=229336/stivali-incrollabili-del-confessore?bonus=11948): search-indexed Italian variant displays **Rare** quality, while the disenchant table still gives **122** and **59/38/24** exactly. Its item-level/bonus differs from the Epic/Mythic page. This is **strong evidence that the Looter table is keyed to base item ID / shares counts across item versions**, not a version-specific Rare/Epic controlled cohort. The index cannot prove the uploader's exact bonus mix, and live plain-HTML retrieval strips JS lists.
* [Confessor's Unshakable Lightcover, item 229329](https://www.wowhead.com/item=229329/confessors-unshakable-lightcover?bonus=12020): 107 operations, same-name rows 57, 35, 13. [An ilvl=678 Mythic preview](https://www.wowhead.com/item=229329/confessors-unshakable-lightcover?ilvl=678) shows the identical 107 and 57/35/13 counts.
* [Malevolent Gladiator's Treads of Cruelty, item 227625](https://www.wowhead.com/ptr/item=227625/malevolent-gladiators-treads-of-cruelty): 22 operations, same-name Refulgent rows 13, 6, 2 **plus Sha Crystal 74248 once**; the catalog says this is a Season-12-style item reissued in 11.0.5. Its mixed MoP/TWW outcomes are a direct context-exclusion warning, **not** a normal TWW epic DE distribution.

The source pages give three **same-name** Refulgent rows but the indexed material names do not expose each row's output item ID or rank. Known catalog item IDs 219952, 219954, 219955 are *candidates for separate rank families*, **not established row matches**. Do not assign these IDs by displayed order or presumed price/quality.

## Exact arithmetic (no invented outputs)

For N reported operations and positive material occurrence counts h_1..h_k, the number with *none of the listed rows* is at least `max(0,N - sum(h_i))`, because the union cannot exceed the sum. This remains true if outputs co-occur, and **does not** prove an operation produced no material at all.

| Input | N | Refulgent source rows | Sum of source Refulgent hits | Lower bound: operations with none of these listed Refulgent rows |
| --- | ---: | --- | ---: | ---: |
| 229336 | 122 | 59 / 38 / 24 | 121 | **1** |
| 229329 | 107 | 57 / 35 / 13 | 105 | **2** |
| 227625 | 22 | 13 / 6 / 2 | 21 | **1** |

For 227625 one additional Sha Crystal occurrence is reported (22 total listed row hits), but rank outputs and Sha cannot be assumed mutually exclusive. The unlisted-outcome bounds are conditional on site row numerator/denominator meaning **per-operation material occurrences from the same cohort**. They cannot be treated as directly observed zero-disenchants. They do not establish unconditional expected **unit quantities**, because positive-stack sizes and source versions are unknown. Do not renormalize row counts into exclusive 100% chance distributions.

If all listed rows are attributable to the stated denominator, the fraction with any *listed Refulgent* is bounded above by 121/122=99.1803% for 229336; 105/107=98.1308% for 229329; and 21/22=95.4545% for 227625. These are **upper bounds on source-table coverage of listed material events**, NOT current-character drop probabilities or rank shares.

## Disposition / next original-source work

**Gap:** Invalid/missing source context, row output identity, and positive quantity histogram; also an eligibility/material-context exclusion for reissued 227625. Not a price-data or display gap. No new eligible current Retail gold decisions proven.

**Worker handoff (T0048):** Obtain full original itemLink/bonus and dated individual disenchant exports for 229336/229329, or raw Looter row output hyperlinks plus upload patch/gear-variant segmentation; recover per-output item IDs, rank, units and per-cast 0..N joint events. Retain base-ID aggregate observations separately and never count Rare and Epic query views as independent studies. 227625 must be split by actual source era/game-system context before any TWW valuation.

**Verification performed:** independently checked indexed original item-side counts for all three item IDs and distinct 229336 quality variants; read new worker JSONL and original metadata; checked integer inequalities. Direct current WoW client eligibility, live itemLink, underlying Looter uploads, character professions, Lua tests, synthetic prices and runtime tooltip were NOT executed. Third-party live JS scraping unavailable.

No research originals, worker records, owner three-pass integration, main, build, CI, PRs or releases changed in this analysis.
