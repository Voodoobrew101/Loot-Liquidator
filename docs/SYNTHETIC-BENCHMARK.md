# Synthetic benchmarks

A synthetic benchmark changes a selected simulated model after source selection, baseline normalization and profession projection. It never rewrites original means, casts, probabilities, histograms, source weights or recorded character data.

The output factor is `outputLevel / 100 * (1 + specializationBonus / 100)`. It applies once to numerical expected quantities, including named output quantities, after the profession model. It does not invent a new hit probability, conditional range or observed count. Reapplying the same benchmark to an already benchmarked model does not scale it again. Benchmark results carry confidence zero.

Resourcefulness benchmark inputs replace the projected input-saving factor for eligible modern processing/crafting. They also replace the additional eligible reagent-cost factor; they do not multiply material outputs. Disenchanting, gathering, world loot and item-use previews do not acquire crafting Resourcefulness. Real profession ratings and native specialization effects remain distinct from these explicitly chosen scenario percentages.

Fixed native crafting recipes, researched processing recipes, disenchanting, gathering and native opportunity previews all use the benchmark stage. Opportunity scenarios scale their normalized output indexes once. Gathering and opportunities remain informational and never become bag conversions. Known recipe access, item binding and complete reagent costs still determine whether a quoted action is available.

Choose **Simulated** in a profession's settings to edit a what-if profile. Changing a rating or percentage uses its saved anchor; named specialization points and learning states use native grants and milestone boundaries. Reset to minimum clears only that simulated profile. Actual recorded profiles and learned recipes remain separate.

The tooltip communicates uncertainty through confidence, without an additional estimate/provisional label. Provenance and assumptions belong in the [profession baseline pipeline](PROFESSION-BASELINE-PIPELINE.md), compiled model policy and source research records. No new in-game crafting or disenchanting experiments are required by this workflow.
