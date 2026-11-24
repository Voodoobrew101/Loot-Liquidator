# Build-pinned crafting quality identity corroboration — 2026-11-24 UTC

Research-only coordinator metadata; no new observed cohort, gold decision, confidence score, or production change. This adds **direct extracted client-table provenance**, not another re-transcription of the existing studies or earlier secondary catalogue rank reviews.

## Midnight: exact source joins

Read individually filtered Item rows for build `12.1.5.70961` and the same-build [CraftingQuality table](https://wago.tools/db2/CraftingQuality?build=12.1.5.70961). Item table columns explicitly include ModifiedCraftingReagentItemID and CraftingQualityID. The same-build quality table maps ID 13 to QualityTier 1 (atlas set 6) and ID 14 to QualityTier 2 (atlas set 7); **quality-table foreign keys are not rank numbers**. Exact row IDs matched the requested filters.

| Material | Item ID and source | ModifiedCraftingReagentItemID | CraftingQualityID | Joined QualityTier |
| --- | --- | --- | --- | --- |
| Crystalline Glass | [242787](https://wago.tools/db2/Item?build=12.1.5.70961&filter%5BID%5D=exact%3A242787) | 593 | 13 | 1 |
| Crystalline Glass | [242786](https://wago.tools/db2/Item?build=12.1.5.70961&filter%5BID%5D=exact%3A242786) | 593 | 14 | 2 |
| Dusk-Shrouded Stone | [242788](https://wago.tools/db2/Item?build=12.1.5.70961&filter%5BID%5D=exact%3A242788) | 594 | 13 | 1 |
| Dusk-Shrouded Stone | [242789](https://wago.tools/db2/Item?build=12.1.5.70961&filter%5BID%5D=exact%3A242789) | 594 | 14 | 2 |
| Umbral Tin Ore | [237362](https://wago.tools/db2/Item?build=12.1.5.70961&filter%5BID%5D=exact%3A237362) | 555 | 13 | 1 |
| Umbral Tin Ore | [237363](https://wago.tools/db2/Item?build=12.1.5.70961&filter%5BID%5D=exact%3A237363) | 555 | 14 | 2 |

This confirms the counterintuitive Crystalline Glass rank order directly; the earlier [November 8 refine-direction audit](2026-11-08T1105-crystalline-glass-refine-rank-identity-inversion.md) used recipe and commodity rank sources. Dusk-Shrouded Stone and Umbral Tin have ascending IDs in these exact pairs. The paired family identifiers are identical within each pair. The Item table itself does not contain English display names; names are the already established identities in the earlier rank audit and queue T0005/T0001. No input-rank/output-rank association, quantity, chance, casts, refund rate, historical build equivalence or learned-recipe eligibility is inferred.

## TWW worker QA and consumer boundary

The 13:22 UTC war-within report in `research/coordination/quiet-status/war-within.json` records 18 historical rank identities from build 11.2.7.65299. Independently re-opened its exact [224802](https://wago.tools/db2/Item?build=11.2.7.65299&filter%5BID%5D=exact%3A224802) and [224800](https://wago.tools/db2/Item?build=11.2.7.65299&filter%5BID%5D=exact%3A224800) Item rows and [same-build CraftingQuality](https://wago.tools/db2/CraftingQuality?build=11.2.7.65299) table: both have ModifiedCraftingReagentItemID 499, CraftingQualityID 1 and 3 respectively, joined to tiers 1 and 3. Thus Orbinid Pigment R1=224802, R3=224800; not an output distribution or study. Worker verified R2=224801 and other families; those 16 rows were not independently re-read in this manager run. Previous [November 17 positional rank audit](20261117T0300-tww-pigment-rank-catalog-versus-old-positional-candidates.md) remains the historical candidate-mismatch context, not a current-regression claim.

Pinned main `3e814929ecffc2c2a282fddaead2012e5b44e9a9` static inspection:
- `database/research/skill-quality-rules.json` blob `5fe67c374c28ebd9731750221346230985775c7b` already correctly orders glass [242787,242786] and stone [242788,242789].
- `database/research/rank-families.json` blob `5577910f4fdfc7e0237708269cb5816f8d8f8082` holds both as unordered sets, without verifiedRanks. It lacks Luredrop, Orbinid and Blossom Pigment entries; this is a precise gap in this adapter's mapping table only, not proof all runtime paths lack these families. TWW input-rank audit file likewise currently contains DF mappings only.
- `tools/research_v3_to_baselines.py` blob `597fef07d1f604fa293ca863745fea6fa52d9759` resolve_ranked_outputs uses only explicit verifiedRanks from that family table; known rank plus name cannot use these missing mappings through that function. Family-only pools and exact source links are distinct; never coerce an unknown rank into the first ID or sum alternatives.
- `tools/research_build_review.py` blob `e0ae3c25b634bb702af79654b439fdc100b5c3ae` enumerates JSONL evidence; this review note and worker status are metadata, not automatic numeric admission records. Source catalogue paths are separate, so do not reopen completed cutoff decisions or infer a live defect.

Eight bounded static assertions passed on the pinned source files (glass unordered set, existing correct glass/stone skill-rule order, absent explicit verifiedRanks for both families, absence of three TWW pigment family keys, explicit verifiedRanks adapter gate and JSONL review scan). No compiler, runtime, synthetic-price tooltip or game-client tests were run. Next step for authorized implementation is to connect verified metadata through existing reviewed mapping/consumer tests only where a reachable source field is missing or incorrectly selected; do not overwrite existing correct results or admit any new empirical cohort. Prioritize actual new completed processing ledgers and use the direct table join for new identity gaps rather than repeated secondary rank searches.

Research head before write: `05f662cfc84af8e263f7c5bca8874b8dc93af46a`; owner integration `3d667d053db587c91401cfed7ecc56862b8340c9`. Cutoff catalogue remains closed verified per owner receipt; no changes to worker ownership, schedule, addon, PRs, releases or main.
