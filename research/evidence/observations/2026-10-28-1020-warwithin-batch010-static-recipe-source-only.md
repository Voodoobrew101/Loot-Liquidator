# Batch010 original-source static recipe documentation — SOURCE ONLY

Research-only archive, 2026-10-28. This is **not** an empirical observation JSONL, not a second runtime mapping, and not a claim of independent experiments. Exact recipe output counts/reagents are documented in the source spell pages and compared to the shipping GameData source. Current Retail character learned/forge eligibility has not been live tested.

## Eight source-verified deterministic recipes
- **output-supp:smelt:2659:2841** — `GameData.lua:675`; Output 2; reagents 2840x1+3576x1; 2 distinct reagent types. Source: https://www.wowhead.com/spell=2659/smelt-bronze. Output chance 1, conditional min/max 2/2, unconditional 2 **only conditional on the recipe successfully executing**, not on an arbitrary item being processable.
- **output-supp:smelt:3569:3859** — `GameData.lua:676`; Output 1; reagents 3575x1+3857x1; 2 distinct reagent types. Source: https://www.wowhead.com/spell=3569/smelt-steel. Output chance 1, conditional min/max 1/1, unconditional 1 **only conditional on the recipe successfully executing**, not on an arbitrary item being processable.
- **output-supp:smelt:29356:23445** — `GameData.lua:677`; Output 1; reagents 23424x2; 1 distinct reagent types. Source: https://www.wowhead.com/spell=29356/smelt-fel-iron. Output chance 1, conditional min/max 1/1, unconditional 1 **only conditional on the recipe successfully executing**, not on an arbitrary item being processable.
- **output-supp:smelt:29360:23448** — `GameData.lua:678`; Output 1; reagents 23445x3+23447x2; 2 distinct reagent types. Source: https://www.wowhead.com/spell=29360/smelt-felsteel. Output chance 1, conditional min/max 1/1, unconditional 1 **only conditional on the recipe successfully executing**, not on an arbitrary item being processable.
- **output-supp:smelt:46353:35128** — `GameData.lua:679`; Output 1; reagents 23449x3+23573x1; 2 distinct reagent types. Source: https://www.wowhead.com/spell=46353/smelt-hardened-khorium. Output chance 1, conditional min/max 1/1, unconditional 1 **only conditional on the recipe successfully executing**, not on an arbitrary item being processable.
- **output-supp:smelt:55208:37663** — `GameData.lua:680`; Output 1; reagents 41163x3+35624x1+35627x1+36860x1; 4 distinct reagent types. Source: https://www.wowhead.com/spell=55208/smelt-titansteel. Output chance 1, conditional min/max 1/1, unconditional 1 **only conditional on the recipe successfully executing**, not on an arbitrary item being processable.
- **output-supp:smelt:74537:53039** — `GameData.lua:681`; Output 1; reagents 52186x10+52327x4; 2 distinct reagent types. Source: https://www.wowhead.com/spell=74537/smelt-hardened-elementium. Output chance 1, conditional min/max 1/1, unconditional 1 **only conditional on the recipe successfully executing**, not on an arbitrary item being processable.
- **output-supp:smelt:102167:72095** — `GameData.lua:682`; Output 1; reagents 72094x2+72103x2; 2 distinct reagent types. Source: https://www.wowhead.com/spell=102167/smelt-trillium. Output chance 1, conditional min/max 1/1, unconditional 1 **only conditional on the recipe successfully executing**, not on an arbitrary item being processable.

**Metadata correction:** Smelt Fel Iron (spell 29356) has exactly one reagent type (Fel Iron Ore ×2), although the supplemental ledger's generic context says “multi-reagent recipe.” The original GameData reagent list is correct. No code was changed.

## Token choice is not an RNG conversion
- Token 45634 Breastplate of the Wayward Vanquisher is a class-constrained tier 8 token. One documented selectable reward is Rogue chest 46123 Conqueror's Terrorblade Breastplate. Primary reference: https://warcraft.wiki.gg/wiki/Conqueror%27s_Terrorblade_Breastplate ; supplementary token reference: https://wowwiki-archive.fandom.com/wiki/Breastplate_of_the_Wayward_Vanquisher. Exact current Retail vendor action is untested.

## Original study REUSE, not a newly discovered cohort
- Silverleaf 765: original Wowhead commenter 180977 reported 48 actual five-herb milling operations with 30×2 and 18×3 Alabaster Pigment 39151. Archive observationID `legacy-b004-ptr180977-765-20261028` in `2026-10-28-0436-legacy-batch004-ptr180977-casthistograms.jsonl`; https://www.wowhead.com/mop-classic/item=39151/alabaster-pigment. E=114/48=2.375; P observed=1; positive sample bounds 2–3. **2008 PTR, not current Retail.** Do not duplicate raw observation.
- Crumbled Stone 192880: https://www.wowhead.com/item=192880/crumbled-stone contains Mgnta's 3125 stones, 160 self-return (0.256 per **derived** 625 five-stone equivalents), and separate LavingRunatic's 60 actual casts with 11 returned (0.183333 per cast). Laving was already archived in `2026-10-28-1008-midnight-batch010-laving-QUALITY-UNMAPPED-CORRECTED.jsonl`; source does not report gem rank IDs. Do not treat both as matched current Retail studies.

## Source-code overlay warning
- `StatYieldProfiles.lua:273–319` contains 18 audited expansion 9/10/11 rarity 2/3/4 armor/weapon scenarios. Two Dragonflight q3 branches have no compiled DE source and create synthetic `194124` with chance 1, expected quantity 1.0 armor / 1.5 weapon. No original sample backs those numbers. This is a QA warning, not a valid observation.

No production, main, master ledger or source-memory cache edits.
