# Primary-source exact item-link reconciliation: Cardinalai, 800 Brilliant Silver prospects

**Research-only cross-source identity audit — 2026-11-17 UTC.** This is a correction lead for an **existing** cohort, **not** seven new experiments, a new current-build calibration or a new addon baseline. Never silently edit the originals or import this note as a fresh study.

## Original source and existing v3 rows

Firsthand [Cardinalai's Brilliant Silver Ore comment](https://www.wowhead.com/item=237364/brilliant-silver-ore) reports 800 completed prospect operations on **item 237364** (silver-quality Brilliant Silver Ore), 3,285 ore **net consumed**, 715 ore **saved** at 39.6% Resourcefulness and max knowledge stats. With five nominal ore per prospect, 800 × 5 = 4,000 nominal input units and 4,000 − 715 = 3,285 net consumed, as reported. **Saved ore are input savings, not extra casts or output quantities.** The source does not supply per-output hits, zero bins, conditional stack histograms, a verified exact patch/build, or a source-collected date.

This source is **already transcribed** into seven records `midnight-20261030-010` through `-016` in `research/v3/evidence/midnight/2026-10-30T1824-midnight-prospecting-studies.jsonl` (`studyKey=wowhead-cardinalai-brilliant-800`; source blob `59833c90d040ce272aba0cffe132b551e4cb288e`). Each of the seven pre-existing rows has `outputItemID=null` and `outputRank=null`, although the author's actual inline output hyperlinks **resolve to exact Retail item IDs**:

| Existing row | Original source output (units in the same 800 operations) | Click-through item ID | Exact original link |
| --- | --- | --- | --- |
| midnight-20261030-010 | 43 Eversong Diamond | **242608** | https://www.wowhead.com/item=242608 |
| midnight-20261030-011 | 111 Flawless Sanguine Garnet | **242613** | https://www.wowhead.com/item=242613 |
| midnight-20261030-012 | 114 Flawless Amani Lapis | **242612** | https://www.wowhead.com/item=242612 |
| midnight-20261030-013 | 153 Sanguine Garnet | **242553** | https://www.wowhead.com/item=242553 |
| midnight-20261030-014 | 145 Amani Lapis | **242554** | https://www.wowhead.com/item=242554 |
| midnight-20261030-015 | 671 Crystalline Glass | **242787** | https://www.wowhead.com/item=242787 |
| midnight-20261030-016 | 874 Dusk-Shrouded Stone | **242788** | https://www.wowhead.com/item=242788 |

**Meaning of the identity fix:** The source's **671 Glass units are explicitly linked to item 242787**, *not* an undifferentiated Glass family. The guide's separate general guarantee reference links to **242786**. These are different quality-item IDs, so **671/800 = 0.83875 units per completed operation for 242787 only**. It would be incorrect to infer that all Crystalline Glass qualities combined produced fewer than 800 units, to assert 129 glass-free operations, or to disprove the qualitative every-cast claim using this one rank's total. The source does not publish a 242786 total. The source's 874/800 = 1.0925 units per cast refers specifically to item 242788; it does not establish `P(hit)`. This source-link distinction resolves an *identity/unit comparison* that is easily lost when old transcriptions leave `outputItemID` null.

## Uncertainty, eligibility and actionability

- Existing qualitative M2 in `research/v3/mechanics.md` and the separately preserved `research/v3/evidence/midnight/2026-10-30T1827-guaranteed-prospect-reagents.jsonl` quote a reference guide saying every prospect yields Crystalline Glass and Duskshrouded Stone. **Do not mark the mechanic false** from 671 units of *one exact quality item*. Test the whole Glass family across both 242786 and 242787 and capture actual completed per-cast outcomes, quality, original patch and skill before deciding whether the guarantee applies to quantity, family occurrence or item rank.
- The direct original source supports linking each **existing** measured unconditional quantity to its exact output item ID, subject to review of whether the author's item links described the actual quality received. This is **source identity recovery**, not new yield evidence or a global/current-patch quality coefficient. No reconstructed per-cast hits, probabilities, zeros, quality thresholds, Resourcefulness multiplier or confidence score is justified.
- A reviewed research-side normalization/identity correction may recover usable exact-rank pricing for these same seven output quantities if not already present elsewhere. First compare the actual current compiled ItemDB and other references; avoid double-counting source copies or replacing a priced existing value with a second copy of Cardinalai's report. The owner-controlled `implementation/usable-data-tooltips` branch and immutable snapshot `4df9ae8b1359d934828e4d0e6d39a9a4dba26fae` are not to be modified here.
- **Priority:** identify whether current renderer/valuation already preserves these IDs and, separately, seek new original current-build rank-aware per-output 0-inclusive cast logs for T0005/T0039 and 236761 mills T0045. All remaining source-date/patch, price, character-unlock and chance/stack questions remain unknown.

## Validation and scope

**20/20 bounded JavaScript assertions passed** against the actual seven stored JSONL cohort rows and two qualitative guide-reference rows, including casts, input ID, units, Resourcefulness/saved inputs, missing hits/histograms and `671/800` / `874/800` arithmetic; the exact seven output hyperlink targets were independently opened through their original Wowhead comment. No Python compiler, Lua addon suite, actual engine/tooltip synthetic-price pass, live market or client/WoW test was run. **No new actionable current-Retail gold decisions or numerical current-Retail rates verified.**
