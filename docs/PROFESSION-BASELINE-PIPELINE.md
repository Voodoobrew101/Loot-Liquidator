# Profession calculations and automatic research admission

The profession editor and quote engine share typed client effects for all thirteen professions across Dragonflight, The War Within and Midnight. Cooking and Fishing have stat profiles without fabricated specialization trees. The inventory includes all 727 native specialization paths and 4,821 milestone entries. Profession rules retain their source build, native IDs, recipe labels and evidence hashes.

## Calculation path

Source observations remain source observations. The compiler creates separate minimum-profile model views in `modeledProfessionBaselines` and `modeledDisenchantBaselines`; it does not replace the original source means, casts, histograms or provenance with adjusted observations. The client uses the same inverse and forward arithmetic to move from a recorded profile to the selected live or simulated profile. An unknown source character is an explicit low-confidence baseline assumption, rather than an observed zero-skill character.

Each effect has its own dimension. Skill and difficulty affect output quality; Multicraft affects eligible crafting quantities; Resourcefulness affects consumed inputs and eligible additional reagent costs; crafting speed and Deftness affect time; Ingenuity affects expected concentration use. Finesse and Perception belong to gathering targets. Disenchanting, milling, prospecting and crushing do not acquire crafting Multicraft. Recipe unlocks and hypothetical allocations do not grant the actual character a learned recipe or an actionable conversion.

Native operation ratings already include current specialization bonuses. Those bonuses are not added again. Manual rating changes use an immutable anchor and native rating/percentage calibration when available. Conditional perks use actual aura identities or explicit entry-specific simulation states and native stack caps. Recipe allocations retain every required reagent and cost; missing requirements are never silently free.

Quality ordering comes from the native Item → CraftingQuality relationship and verified family membership, or a native quality-specific output hyperlink. Item IDs are not sorted to invent quality ranks. Quality redistribution conserves the affected family’s units. Source selection and user weights remain active; a projection changes only the contributing source terms. Personal observations retain their original raw estimates and cast counts.

## Estimates and confidence

Client-defined skill grants and milestone boundaries are distinct from inferred drop curves. Model assumptions stay in the research metadata, generated policy and this document. The tooltip uses its confidence score without an additional estimate/provisional/unquantified label.

The declared fallback models include:

- Resourcefulness uses the midpoint of the native 20–40% saved-reagent interval, with a confidence cap of 15.
- Multicraft uses the midpoint of the native extra-quantity percentage interval, with a confidence cap of 15. Native per-recipe stat eligibility takes precedence over a modeled capability.
- A missing rating conversion uses 0.1 percentage points per rating, capped at confidence 10.
- Gathering Finesse and rare-discovery models have a confidence cap of 5. Native gathering ability targets use an explicit one-unit canonical baseline and evenly spaced quality-threshold prior at confidence zero; these are not measured node yields. Empirical gathering studies use a separate native-target admission contract.
- Legacy disenchant quality curves without a published maximum distribution use a transferred 66% highest-rank/34% next-rank endpoint at confidence zero. The family total is conserved. A saturated source cannot be uniquely inverted without an independent declared prior.
- Midnight Dust Deliverer, Shard Supplier and Crystal Collector use separate primary-quantity, quality-share and additional-material curves. Crystal Collector’s extra essence pool unlocks at 20 points and increases at 30; its possible pool and quantity assumptions carry confidence 5 separately from the crystal distribution.
- Gleaming Shatter uses the actual published rank-specific means from 1,064 and 1,066 completed crafts. Mapping the stated 133 profession/tool skill and maxed native 145 specialization skill to a 278-skill endpoint, and interpolating from three rank-one dust, are confidence-zero model assumptions. The three-unit total and input-rank ceiling are preserved. The separate 1,700-craft refund report does not become an output denominator.

An exact item identity is not proof of its probability or expected quantity. Source-backed named output families can be shown numerically while their item identities remain unresolved; they receive no invented item ID or market price. The quote remains partial where an output cannot be valued. Bound and conjured copies do not gain Auction House sale value. Species-dependent skinning pools require an explicit compatible target-output filter, or remain named opportunities.

World-loot and item-use effects have their own selectable context preview on the profession page. The displayed result and its hover tooltip use normalized output indexes and discovery factors at confidence zero when no measured event denominator is available. These previews do not assert items per kill, grant a craft or register an item-to-itself sale conversion. Crafting Resourcefulness and Multicraft do not apply to these event contexts.

## Research and build path

`tools/prepare_build_research.py` resolves a fetched immutable research commit, runs the source generators, reviews every study row and compiles ItemDB in the build workspace. Its manifest records the exact research revision, review results and runtime hash. With no new ref it reproduces the committed pin.

The review classifies admitted fields, duplicate copies, corrections, metadata and unresolved/held evidence. These dispositions are automatic admission checks, not a claim of independent scientific approval. Original evidence and denominators remain unchanged. Generic crafting studies require explicit profession, recipe, expansion, input batch and source-profile scope, so unrelated recipes cannot be pooled. Reviewed operation aliases are pinned to exact source-row hashes; they do not broadly relabel arbitrary disenchanting evidence. World gathering targets use creature/game-object/pool identity separately from consumed item IDs.

Distribution, scheduled research artifacts and CurseForge build preparation use the same review/generation entry point. The scheduled research build creates validated artifacts without a routine PR, generated-database commit, version bump or release. Publishing remains a separate explicitly requested release action.

The existing Research Manager, Completion, Baseline, Evidence and Validation schedules have the owner’s November 19 no-routine-PR policy. Scientific source records and compact review state remain on `implementation/five-agent-completion`; builds consume them automatically. Existing cadence and role ownership are preserved.

## Verification

The regression suites exercise every native path and milestone, scoped effect handlers, inactive and stacked conditions, affine inverse/forward round trips, quality identities, conserved replacements, source isolation, real recipe quote and tooltip routes, all thirteen profession contexts, native Settings pages, exact allocation costs and automatic study admission. These are offline and native-API fixtures using existing/published evidence; they are not a claim of live-WoW crafting experiments.
