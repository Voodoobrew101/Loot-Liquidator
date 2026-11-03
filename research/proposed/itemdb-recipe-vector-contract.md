# Research-stage recipe-vector contract — v0.4.0

Eight source-backed fixed-output smelting recipe relationships are included as **provisional** entries. The `inputItemID` and `inputCountPerOperation` identify only the FIRST reagent as a lookup anchor. **They are never the complete crafting cost.** Every `Smelt` record MUST carry a nonempty `reagents` array of exact direct `{itemID,quantity}` pairs. Valuation must sum ALL reagent costs, check the learned recipe, expansion Mining skill, forge and any acquisition requirements; if these cannot be checked, no recommendation is permitted. No automatic one-input fallback.

The compiled output is conditional on an eligible successful learned recipe: P=1, positive min=max=expectedQuantity=1 except Bronze Bar output count 2. These are **recipe-description modeled fields**, not 2026 observed casts. Historical source mapping confidence 65, conditional-context confidence 55, numeric-field confidence 80; record confidence 55. For spell 46353 the rare bind-on-pickup teaching item 35273 is explicitly required. Exact original source `main/GameData.lua:L675–682`, independently reconciled against worker queue16 and Retail recipe pages; the actual 2026 client has NOT been tested.

Seven Dragonflight exact-rank or gross-input-equivalent expected quantities were quarantined to UNKNOWN. The original numbers remain in immutable worker evidence and GameData/TSM source; do not reintroduce them as measured exact-cast rates. Two preexisting P>E contradictions remain quarantined as well.

The live Midnight Refine Crystalline Glass spell 1307462 describes 10 rank-one glass to one rank-two glass, but item-ID linkage and PTR's conflicting 5+10 rendering remain unverified. It is a mapping-gap lead, NOT an admitted output. Crushing and Dusk-Shrouded Stone refining remain uncompiled until exact recipe vectors and output IDs are independently resolved.

Research-only file; production `main`, addon TOC and runtime Lua are not modified.
