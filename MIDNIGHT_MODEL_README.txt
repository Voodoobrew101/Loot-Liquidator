# Loot Liquidator 0.9.67 — Midnight prospecting fallback

- **Implemented** the 28-row Midnight research model for Refulgent Copper, Brilliant Silver, Umbral Tin, and Dazzling Thorium.
- **Low/basic expected outputs are the default** (0% upgrade). Uses expected quantities per **5 ore**, not probabilities; values are provisional estimates.
- Applies the same ore-family fallback to both quality variants, **but labels Rank 1 as a proxy** because direct small-sample basic experiments used Rank 2 ore.
- Optional 0–100% upgrade slider under **Options > Processing Research** interpolates **individual** non-diamond materials between low and high study values. If a high study is below low, preserves low instead of treating improvement as harmful. The original raw high value remains in `GameData.lua`.
- Four optional ore-specific Eversong Diamond unlock toggles; default locked (diamond yield zero); unlock uses each ore's own estimated diamond rate.
- Preserved personal observation blending and its manual/Automatic/Reference processing data modes; no changes to alt/profession dropdown UI, bags or non-Midnight data.
- Corrected three misindexed Rank 2 input conditionModel records and registered Dazzling Thorium as a research input.
- Output item references are **quality-1 material IDs**. Matching the true quality output by character skill, equipment, input ore quality and concentration is **not yet implemented**; output value may be under- or overestimated due to rank/price mix.
- The slider is deliberately **manual**: addon does not claim to know an exact skill-to-yield conversion. Diamond unlocks are also manually configured, not scanned from the specialization tree.
- No Resourcefulness ore savings modeled (per-five means per completed prospect), and no exact specialization proc multiplier is asserted.
- Prices require current supported price data for all selected expected outputs, matching the existing engine behavior; if prices are missing the prospective value may remain unknown.
- **Not in-game tested.** Static logic and packaging checks only.

## Sources and data notes

- Basic Rank 2 samples: 50 ore / 10 operations for Copper, Silver and Tin; Wowhead Midnight Prospecting comments, patch era uncertain.
- Tin upgraded observations: 4,000 ore, specialization max, input rank unspecified; other high endpoints weaker estimates.
- Thorium basic values and several rates are guide proxies, not measured minimum-skill tests.
- Source comparison: `/mnt/data/LL-Midnight-prospecting-low-high-rebuilt.csv` outside the addon. The Lua model includes separate `lowBasis` and `highBasis` per material and the unmodified original low/high figures.
- Modeled uncertainty: user-facing gold estimate indicative only (previous planning allowance ~±50%, not a statistical guarantee).
