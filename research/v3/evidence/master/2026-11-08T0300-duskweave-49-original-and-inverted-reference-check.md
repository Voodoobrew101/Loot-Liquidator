# Coordinator: Duskweave Belt original 49-operation histogram and historical table conflict

Date checked: 2026-11-08 UTC. Research-only source/identity and numerical verification. No addon, compiler, real-character or live Retail validation.

## Original/source identities

- Input: **Duskweave Belt**, item **41543**, historical WotLK ilvl **154**, cloth waist (not the currently scaled Retail version).
- Original first-person commenter **zetapoo** (also surfaced as numeric author 180353 on a mirrored PTR view) at [Wowhead WotLK Duskweave Belt](https://www.wowhead.com/wotlk/item=41543/duskweave-belt) reports **49 belts** disenchanted and enumerates material stack frequencies. Its collection date, game build, enchanting skill and exact patch are **not supplied**; the WotLK Classic category of the current mirrored page is not evidence of collection in the modern Classic client.
- The Legacy worker's [2026-11-08T0243 file](../legacy/2026-11-08T0243-wotlk-duskweave-firsthand-disenchants.jsonl) already records **three different authors** / 28, 50 and 100 operations for item 41543, but **does not include the 49-belt zetapoo cohort**. Do **not** treat the earlier cohorts as copies of this one without shared-original proof. Check older/imported histories before importer admission and ask the Legacy owner to handle any new structured evidence/lineage record.

## Original 49-belt arithmetic (not a new coordinator-performed study)

| Output | Original positive stack frequency | Source-derived units | Positive operations | Source-derived unconditional units / belt | P(>=1), conditional on source denominator | Positive-only units / hit |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| Infinite Dust **34054** | 1×3; 2×10; 3×11; 4×10; 5×3 | **111** | **37** | **111/49 = 2.2653061224** | **37/49 = 0.7551020408** | **111/37 = 3.0** |
| Greater Cosmic Essence **34055** | 1×6; 2×6 | **18** | **12** | **18/49 = 0.3673469388** | **12/49 = 0.2448979592** | **18/12 = 1.5** |
| Dream Shard **34052** | Not enumerated by this author | **unknown** | **unknown** | **unknown** | **unknown** | **unknown** |

Source arithmetic: Dust positive stack events 3+10+11+10+3=37; units 1(3)+2(10)+3(11)+4(10)+5(3)=111. Essence positive events 6+6=12; units 1(6)+2(6)=18. Both marginal event tallies sum to 49, but **no per-cast joint ledger** was published: their sum alone does NOT prove mutually exclusive outcomes, zero overall empty disenchants, a measured Dream Shard zero rate, or patch-stable probabilities. Marginal zeros per material are source-derived only if 49 denotes exhaustive completed operations: Dust zero=12; Essence zero=37. These are **not** no-output-operation counts.

For comparison only (not pooled): legacy worker's separate **28**-operation author 436760 has Dust **20/28 (71.43%)**, Essence **7/28 (25.00%)**, Dream Shard **1/28 (3.57%)** and complete named stack bins. The 50- and 100-operation authors give totals, not hit counts. All four authors have unverified patch/skill conditions. Their data can support **historical** field-specific means, not current Retail EV.

## New conflict with historical reference table — potentially material valuation error

[Archived WoWWiki Duskweave Belt table](https://wowwiki-archive.fandom.com/wiki/Duskweave_Belt) prints **Infinite Dust (22%)**, **Greater Cosmic Essence (75%)**, **Dream Shard (3%)** for historical ilvl 154. That is **opposite in ordering/magnitude** to **two independently authored** item-specific positive-hit samples: 28-belt author: Dust 71.43%, Essence 25%; 49-belt author: Dust 75.51%, Essence 24.49%. This is a **historical table-versus-source discrepancy**, NOT a verified swapped-field typo or current Retail correction. Dates/patch and actual meaning of the wiki percentages are unspecified; no replacement coefficients are authorized. Verify the original provenance and any linked TSM/group reference before choosing a field.

[Official 2009-10-22 disenchant/shatter hotfix archive](https://warcraft.wiki.gg/wiki/Hotfixes/2009_Archive) says Infinite Dust availability increased; **no magnitude** or mapping to these comment epochs is supplied. Do not infer a numerical hotfix multiplier, silently blend distinct eras, or convert the old 22%/75% table into 2026 Retail.

## Eligibility gate and recommended handoff

[WoWDB current Retail-scaled 41543](https://www.wowdb.com/items/41543-duskweave-belt) carries `Cannot be disenchanted` at ilvl 33, while historical WotLK version at ilvl 154 was disenchanted. Same base item ID therefore does **not** justify an available current Retail disenchant action. Validate the exact item version/bonus and in-game eligibility before runtime valuation. No measured current Retail source conditions or live client verification here.

**Next Legacy-owned follow-up:** confirm this 49-operation original is not present elsewhere under a different importer studyKey, preserve original name/link and historical context in an append-only worker record (if unique), then verify archived reference table provenance and distinct material probability ordering. Coordinator shall keep this as a field/identity discrepancy and pass to the three-pass implementation owner only after the original-cohort and current-eligibility gates are resolved. No PR, merge, release, or worker file change.

**Validation performed:** Reopened original 49 and 28/50/100-comment Wowhead page; independently reopened archived WoWWiki percentages, Oct 22 hotfix archive, and current WoWDB 41543 page; recalculated the two 49-operation marginal histograms and means. Repository read-back checked Legacy's latest 14-record file, current quiet status, and main code-search for unique author/49 marker; absence from *all* historical imported files is NOT established. **No code/engine/tooltip/compilation/client tests performed.**
