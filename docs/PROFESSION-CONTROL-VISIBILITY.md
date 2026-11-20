# Profession control visibility

The profession editor uses the same typed effect catalog as the calculation engine. It includes all 727 native specialization paths and 4,821 milestones across Dragonflight, The War Within and Midnight, plus stat-only Cooking and Fishing profiles. The thirteen professions have separate recipe and gathering contexts.

Open **Professions (Simulated) → a profession → Advanced**. Skill, invested points, relevant ratings/percentages and conditional bonuses are editable. A **Learned** checkbox represents a native learning grant at zero invested points; positive invested points imply learning without adding that grant twice. Structured prerequisites remain enforced. Editing selects the saved Simulated profile; Reset to minimum clears that profile without changing scanned character data or actual recipe access.

The controls affect the dimension their native effect describes: quality, quantities, extra materials, input savings, time, concentration or recipe eligibility. Convenience and progression perks do not acquire a material multiplier. Effects remain scoped to the correct profession, expansion, recipe labels, input rarity/class and target. Conditional effects have explicit active-state controls; known aura IDs and stack caps use native data.

Gathering has a separate target selector and result card, including 173 native material/variant ability targets. Targets do not become inventory self-conversions or liquidation recommendations. Empirical gathering studies use creature, game-object or fishing identities in their own pipeline.

World loot and item use have a separate context selector, result card and hover tooltip. All 49 native output entries in these scopes reach 25 selectable contexts. Missing event frequencies use normalized output/discovery indexes at confidence zero; they do not become items per kill or actionable sale conversions. See [native opportunity previews](PROFESSION-OPPORTUNITY-PREVIEWS.md).

Static rules explicitly covering client12.1.5 can run on that version's compatible hotfix builds at or above their source build. Native captures remain exact to character, recipe, input allocation, build and freshness. An unknown later patch does not silently inherit an older numerical claim.

Confidence is the tooltip uncertainty signal. Assumptions and unresolved output identities stay in research/build metadata; the tooltip does not add estimate/provisional/unquantified caveats. Source-backed named outcomes can appear without an invented item ID or sale value, leaving valuation partial where necessary.

See [Profession baseline pipeline](PROFESSION-BASELINE-PIPELINE.md) for formulas, confidence caps, source preservation, automatic research review and verification. The [disenchant research report](DISENCHANT-FORMULA-RESEARCH-2026-11-19.md) retains the primary source analysis and endpoint assumptions.
