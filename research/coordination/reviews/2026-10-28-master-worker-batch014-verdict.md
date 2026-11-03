# Master QA batch014 — reagent-safe candidate v0.4.0
2026-10-28 · research/processing-confidence only · queue revision 17

## Actual build and independent QA
Compiler v0.4.0 executed twice on pinned live GitHub source bytes and matched byte-for-byte. **984 provisional mappings / 165 input IDs; 799 four-field numeric complete (81.20%); 403 missing numeric cells** of 3,936 (P172/min68/max68/E95). 1,202 GameData source-line identities validated, zero JS invariant errors. Candidate has 32 numeric fields in confidence 70–89 (eight modeled fixed recipes × four) and 3,904 below 70, zero ≥90; all 984 record-wide scores below 70. **No verified current Retail unskilled baseline**. The independent exhaustive Retail-universe audit is NOT COMPLETE. The old 1,643/1,737 first-pass source inventory is not an exhaustive mapping denominator.

## Four workers: 150/150 exact assigned keys reviewed
- **Midnight 35:** no new current cast evidence; 7 diamond E unknown, 28 historical reference E; original JD3K R2 study is one source family. New unassigned spell **1307462 Refine Crystalline Glass** is a genuine recipe-family lead, NOT accepted exact item-ID mapping: live 10 R1 glass → 1 R2, PTR displays conflicting 5+10; item IDs 242786/242787 require in-game verification. No fabricated R2 prospecting output rows.
- **War Within 35:** 13 TWW output studies normalized from gross ore, not actual casts; 14 Midnight overflow references; 8 fixed smelts independently reconciled to direct reagent vectors, expansion skill floors and forge/learned recipe. **Eight previously excluded recipe-output mappings now staged** with full cost vectors; not eight new experiments. Spell 46353 requires teaching item 35273, not just Mining skill 75. No current-client proof.
- **Dragonflight 40:** accepted seven source-only E safety quarantines (two Crumbled Stone gross-input equivalent and five rank-specific Illimited Diamond), preserving raw original values; two original P>E contradictions remain unknown. Previously quarantined 31 milling-rank families are not counted again. Fish input rank erratum preserved.
- **Legacy 40:** 33 original TSM P/E/min/max contradictions documented as historical source conflicts, not newly discovered outputs; original Traziz Felslate 100-ore cohort independently distinct from Deckven 3,200 mass Felslate and 2016 Reddit batches, but cohorts are not patch/skill matched and cannot justify a numeric multiplier. Six Midnight Crushing candidate inputs remain unverified as exact eligible recipes.

## Gold-decision safeguards
The first reagent is only a Smelt lookup anchor; valuation MUST sum every direct reagent in `reagents` and verify learned spell, expansion Mining skill and forge. Bronze makes two bars, Fel Iron consumes two units of one ore type, Hardened Khorium needs 3 Khorium Bars plus 1 Hardened Adamantite Bar. The seven quarantined E fields are UNKNOWN, not zero, and old TSM/Gamedata claims remain archived. Never use P×E, yield midpoints, inferred hotfix multipliers, or rank-family rates copied into all qualities. No current AH prices were checked, so no actual gold-decision flip is asserted.

## Uncompiled and blocked
16 Crushing candidate gem-input families (exact eligibility and Gemdust ranks unknown); two Midnight refining candidates (Dusk stone 18-to-1, Glass live 10-to-1/PTR discrepancy); 52 generic disenchant output profiles without concrete input IDs; self-return resource savings and token choice not random conversions. Four independent numerical mechanics hypotheses remain blocked. PR #3 remains open/unmerged. `itemdb.lua` is RESEARCH ONLY, never loaded by current addon.

## QA execution and source memory
Actual deterministic V8 compiler runs and structural validation passed; generated Lua was committed with source manifest. Node CLI test suite, independent Lua interpreter load, full Node source-memory rebuild and actual WoW client tests were NOT executed in the connector-only runtime. Source memory is **stale** at 112 canonical sources / 110 reviews / 38 QA events; batch014 worker reviews and new master feedback are not yet incorporated, so no fresh source-memory count is claimed. Schema and Node regression test were updated but not executed. The original studies and worker submissions remain immutable.

## Next assignments
Revision 17 contains **150 disjoint exact keys**: Midnight 16 Crushing + 2 refining +17 numeric; War Within 13 TWW +8 recipe-eligibility +14 Midnight overflow; Dragonflight 40 rank/output gaps; Legacy 31 historical +9 Dragonflight overflow. The queue is master-owned and scheduled worker cadence is unchanged.

Sources: main/GameData.lua lines 675–682 (SHA 1d47c4a961c5dc5af626e659f7d96d1490d3cf9e); original worker batch014 reports and JSONL; https://www.wowhead.com/spell=46353/smelt-hardened-khorium ; https://www.wowhead.com/item=35273/study-of-advanced-smelting ; https://www.wowdb.com/spells/1307462-refine-crystalline-glass-a-professions-chaticon ; https://ptr.wowdb.com/spells/1307462-refine-crystalline-glass-a-professions-chaticon .

Production main/GameData.lua, addon Lua/TOC, releases and PR #3 untouched; automation schedules unchanged.
