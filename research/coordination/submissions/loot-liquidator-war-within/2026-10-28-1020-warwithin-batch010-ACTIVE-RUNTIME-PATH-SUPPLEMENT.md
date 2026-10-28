# Batch010 independent active-runtime-path supplement — HIGH PRIORITY

**Research-only, additive correction to the Batch010 report.** Subsequent source read confirms the synthetic Dragonflight q3 disenchant fallback is **not merely dormant code**.

1. `Core.lua:370–398` implements `DisenchantEstimate(f)`: when an item is eligible, its expansion resolves, the user's data mode is not personal-only, and no usable matching personal observation is returned, it calls `self:StatDisenchantYields(f)` **before** `self:GameDisenchantYields(f)`. This is the live recommendation path, subject to those gates.
2. `StatYieldProfiles.lua:273–319` finds no `gd.disenchant[9][3]["armor"]` or `["weapon"]` source table in `GameData.lua`. It generates material 194124 (Vibrant Shard) with **chance=1**, `expectedQuantity=1.0` armor or `1.5` weapon, and speculative high-slider adjustments. The output has **zero measured source samples**.
3. `Core.lua:399–416` prices the synthetic `m.expectedQuantity` using TSM material quotes. `Core.lua:418–429` can then return this estimate with `method="Game Data observed yields"`, even when the yield was **modeled**. The method label is therefore potentially misleading, and the invented rate may influence the D-versus-other liquidation decision if all eligibility/pricing conditions hold.
4. This is a **verified code-path audit**, not evidence that the underlying disenchant distribution is known, not an assertion that all rare Dragonflight items are eligible, and not a claim that any actual item was priced incorrectly in a live client.

**Master action recommended:** Independently reproduce this branch with a mocked eligible Dragonflight rare armor/weapon input and no personal observations; assert that unmeasured fallback does not become a guaranteed observed result, and that tooltip/provenance distinguish modeled vs measured. A future development fix should fail closed or clearly mark provisional estimates, on a separate reviewed coding branch. **No production source was modified here.**

Also correct the main Batch010 report's relative link to source-only evidence: from `research/coordination/submissions/loot-liquidator-war-within/`, the proper relative path is `../../../evidence/observations/2026-10-28-1020-warwithin-batch010-static-recipe-source-only.md` (the report used one too few parent segments). The exact GitHub path remains valid.

**Source SHA context:** `GameData.lua` blob `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`; `Core.lua` and `StatYieldProfiles.lua` read from `research/processing-confidence` on 2026-10-28. No main/production, master ledger, assignment, source-memory cache, or schedule changes.
