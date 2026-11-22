# Profession calculations and automatic research admission

The profession editor and item quote engine share typed item-processing effects across Dragonflight, The War Within and Midnight. The editor catalog is scoped to supported tooltip operations; shared native recipe identities and recorded character contexts remain available for real item processing. Profession rules retain their source build, native IDs, recipe labels and evidence hashes.

## Calculation path

Source observations remain source observations. The compiler creates separate minimum-profile model views in `modeledProfessionBaselines` and `modeledDisenchantBaselines`; it does not replace the original source means, casts, histograms or provenance with adjusted observations. The client uses the same inverse and forward arithmetic to move from a recorded profile to the selected live or simulated profile. An unknown source character is an explicit low-confidence baseline assumption, rather than an observed zero-skill character.

Each retained effect changes item output or value. Supported skill and difficulty models affect output quality; Multicraft affects eligible Craft quantities; Resourcefulness affects consumed inputs and eligible additional reagent costs. Speed, Ingenuity, concentration and world-gathering projections are removed. Disenchanting, milling, prospecting and crushing do not acquire crafting Multicraft. Hypothetical allocations do not grant the actual character a learned recipe or an actionable conversion. Original recorded timing, concentration and stat observations remain source metadata.

Native operation ratings already include current specialization bonuses. Those bonuses are not added again. Manual rating changes use an immutable anchor and native rating/percentage calibration when available. Conditional perks use actual aura identities or explicit entry-specific simulation states and native stack caps. Recipe allocations retain every required reagent and cost; missing requirements are never silently free.

Quality ordering comes from the native Item → CraftingQuality relationship and verified family membership, or a native quality-specific output hyperlink. Item IDs are not sorted to invent quality ranks. Quality redistribution conserves the affected family’s units. Source selection and user weights remain active; a projection changes only the contributing source terms. Personal observations retain their original raw estimates and cast counts.

## Estimates and confidence

Client-defined skill grants and milestone boundaries are distinct from inferred drop curves. Model assumptions stay in the research metadata, generated policy and this document. The tooltip uses its confidence score without an additional estimate/provisional/unquantified label.

Numerical processing models use source-backed quantities and coefficients:

- Resourcefulness uses the midpoint of the saved-reagent interval when both native endpoints are supplied, with a confidence cap of 15.
- Multicraft uses the midpoint of the native extra-quantity percentage interval, with a confidence cap of 15. Native per-recipe stat eligibility takes precedence over a modeled capability.
- Ratings require a native rating/percentage pair or an explicit source calibration. Unquantified perk descriptions do not create numerical bonuses.
- Legacy disenchanting retains its source category rank mix when no calibrated quality response is available. It does not acquire a fabricated highest-rank endpoint.
- Midnight Dust Deliverer, Shard Supplier and Crystal Collector use separate primary-quantity, quality-share and additional-material curves. Crystal Collector’s extra essence pool unlocks at 20 points and increases at 30; its possible pool and quantity assumptions carry confidence 5 separately from the crystal distribution.
- Gleaming Shatter uses the actual published rank-specific means from 1,064 and 1,066 completed crafts. Mapping the stated 133 profession/tool skill and maxed native 145 specialization skill to a 278-skill endpoint, and interpolating from three rank-one dust, are confidence-zero model assumptions. The three-unit total and input-rank ceiling are preserved. The separate 1,700-craft refund report does not become an output denominator.

An exact item identity is not proof of its probability or expected quantity. Source-backed named output families can be shown numerically while their item identities remain unresolved; they receive no invented item ID or market price. The quote remains partial where an output cannot be valued. Bound and conjured copies do not gain Auction House sale value. Species-dependent skinning pools require an explicit compatible target-output filter, or remain named opportunities.


## Research and build path

`tools/prepare_build_research.py` resolves a fetched immutable research commit, runs the source generators, reviews every study row and compiles ItemDB in the build workspace. Its manifest records the exact research revision, review results and runtime hash. With no new ref it reproduces the committed pin.

The review classifies admitted fields, duplicate copies, corrections, metadata and unresolved/held evidence. These dispositions are automatic admission checks, not a claim of independent scientific approval. Original evidence and denominators remain unchanged. Generic crafting studies require explicit profession, recipe, expansion, input batch and source-profile scope, so unrelated recipes cannot be pooled. Reviewed operation aliases are pinned to exact source-row hashes; they do not broadly relabel arbitrary disenchanting evidence.

Distribution and explicitly requested release preparation use the same review/generation entry point. Scheduled research builds and automatic version commits are removed. Publishing remains a separate explicitly requested action.


## Verification

The regression suites exercise retained item-processing paths and milestones, scoped effect handlers, inactive and stacked conditions, affine inverse/forward round trips, quality identities, conserved replacements, source isolation, real recipe quote and tooltip routes, all thirteen profession contexts, native Settings pages, exact allocation costs and automatic study admission. These are offline and native-API fixtures using existing/published evidence; they are not a claim of live-WoW crafting experiments.
