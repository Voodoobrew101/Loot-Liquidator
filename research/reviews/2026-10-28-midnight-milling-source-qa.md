# Midnight Milling source corroboration and independence QA — 2026-10-28

## Scope and provenance
- Read actual main/GameData.lua SHA 1d47c4a961c5dc5af626e659f7d96d1490d3cf9e and main/StatYieldProfiles.lua SHA 1d80df8304acaa75a5b507089ef163696381b2ff.
- Read current research/PROGRESS.md, research ledgers, mechanics/API registries, both itemdb prompts and Issue #2. Original ZIP filename in main returns GitHub 404; extracted Lua is canonical.
- Eight input/output candidates, grouped in four confirmed herb/pigment families. **These are eight previously runtime-only overlay variants, not eight new measured distributions.**
- Process recipe: Midnight Milling 1269575, **10 herbs per operation**: https://warcraft.wiki.gg/wiki/Midnight_Milling and https://www.method.gg/guides/midnight-inscription-profession-guide.
- Output families corroborated by https://www.icy-veins.com/wow/professions-inscription , https://www.method.gg/guides/midnight-inscription-profession-guide, and herb/pigment references below.

## Input and output pairs
| Input IDs (individual item variants) | Product ID | Evidence |
|---|---:|---|
| 236761, 236767 Tranquility Bloom | 245807 Powder Pigment | https://warcraft.wiki.gg/wiki/Powder_Pigment ; https://www.wowhead.com/item=245807/powder-pigment |
| 236776, 236777 Argentleaf | 245804 Argentleaf Pigment | https://warcraft.wiki.gg/wiki/Argentleaf_Pigment ; https://www.wowhead.com/item=245804/argentleaf-pigment |
| 236778, 236779 Mana Lily | 245866 Mana Lily Pigment | https://warcraft.wiki.gg/wiki/Mana_Lily_Pigment ; https://www.wowhead.com/item=245866/mana-lily-pigment |
| 236770, 236771 Sanguithorn | 245864 Sanguithorn Pigment | https://warcraft.wiki.gg/wiki/Sanguithorn_Pigment ; https://www.wowhead.com/item=245864/sanguithorn-pigment |

## Numerical candidate — NOT observed
All eight retain exact legacy low-reference values `dropChance=1.0` (display **approximately** 100%, modelled proxy), `yieldMin=3`, `yieldMax=6` (conditional modeled bounds), and `expectedQuantity=4.5` unconditional decimal units per ten-herb operation (**unverified** modeled baseline). Source: `StatYieldProfiles.lua` four `millGroup(...,4.5,6.5,3,6,5,8,...)` rows. The old 6.5 high scenario remains research history only, not a competing shipped output table. 4.5 expected corresponds to 0.45 output units per consumed herb for per-input EV, without a second chance multiplier. No public report located with the exact 10-herb operation denominator, per-cast hits, and relevant skill/spec/gear/quality context. **Do not claim 4.5 or 100% is a true game rate.** No new sample count; `sampleOperations=null`.

## Quality and stats
- The existing single output ID per family is a preliminary source association; whether different output-quality item IDs replace it for better skill/gear/specialization must be modelled via explicit conditional identities and cannot be inferred solely from the input herb variant.
- See https://www.wowhead.com/guide/midnight/professions/inscription-specializations (Perfected Products/Processing/Perfect Milling; Multicraft/Resourcefulness/Ingenuity) and https://www.method.gg/guides/midnight-inscription-profession-guide (rank progression via skill). These sources demonstrate relevant mechanic categories but **do not quantify per-output adjustment formulas**.
- Azeroot 236775 has conflicting generic language (“10x any Midnight herb”) versus specific four-family pigment tables. Do NOT assign it a made-up pigment. Need actual recipe reagent eligibility and per-output observed cast; https://warcraft.wiki.gg/wiki/Midnight_Milling and https://www.icy-veins.com/wow/professions-inscription .
- Arathor's Spear 210808/210809/210810: multiple player reports from 2024-08-29 through 2025-04-29 describe absence from Khaz Algar Milling interface; https://us.forums.blizzard.com/en/wow/t/inscription-unable-to-mill-arathors-spear/1935257 and https://us.forums.blizzard.com/en/wow/t/inscription-arathors-spear-not-on-milling-list/2083666. Evidence type: player reported, patch-current status UNVERIFIED. The legacy overlay deletes these candidates; proposed database should instead retain a versioned eligibility block pending current Retail verification.

## Confidence scoring
Per-field rubric follows research/PROGRESS.md and QA_PROTOCOL.md. Candidate review scores per row: input-output identity 78 (two corroborating guides plus item pages); chance 12 (unmeasured proxy); conditional min 12 and max 12 (unmeasured modeled display bounds); expected units 18 (modeled scenario without a study); conditions 22 (specific operation identified, character/stat/patch not). Weakest material score=12. These are evidence-strength scores, NOT measured numerical accuracy percentages. No unsupported score promotions in the preexisting 1,256-row ledger. No promotion to >=90.
 
## Static QA completed
- Research test source `research/tests/test_itemdb_candidate.js` executed in JavaScript with actual main Lua and read-back candidate: **16 checks passed; 0 failed**.
- Tests cover 8 unique candidate IDs, expected mapping, ten herb inputs, independent fields, weakest-field score, no double multiplication, synthetic contradictory Cobalt tuple, unknown conditions, exact legacy source correspondences, simulated/real context selection policy, and legacy second-database mutation detector.
- Architecture detector is a **KNOWN DEFECT**, not a passed production migration. No in-game/retail API tests. No full JSON-Schema validator invoked.
- Two optional input IDs 36721/87821 excluded by old runtime overlay remain in research backlog; no fresh supporting materials found in this batch.

## Review decisions / next tests
1. Keep all eight as `PROVISIONAL_CANDIDATE` only in research; don't automatically choose quality-specific output tier or apply the heuristic 100% chance as fact.
2. Run live-milling caster probes with exact ten-input count, current build/time, child skill-line, tools, spec ranks, output item ID, zero-inclusive cast histogram, and input quantities actually spent.
3. Verify Azeroot/Arathor's Spear by live recipe filtering, distinguish explicitly ineligible from merely lacking known result.
4. Preserve all other GameData.lua records, untouched; integrate only in future reviewed itemdb.lua migration after all source families are captured and tests pass.
