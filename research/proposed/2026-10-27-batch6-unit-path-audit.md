# Batch 6: TSM units and valuation path audit

Source inspected: main/ConversionEngine.lua and main/StatYieldProfiles.lua, 2026-10-27. Research only.

ConversionEngine.lua lines 491-519: legacy TSM fallback sets each output expectedQuantity=amountOfMats, inputCount=1, processingBatchSize=option.inputCount or 5, confidenceCap=80. The stated unit is expected output per input item. In ConversionOptions lines 650-680, total output price is divided by yieldModel.inputCount, so this fallback is internally consistent per input item IF amountOfMats really is per-input expected quantity. Do not simply multiply its quantities by five; that would double scale its per-item valuation.

StatYieldProfiles.lua lines 234-258: empty compiled candidate records filled from TSM use expectedQuantity=amountOfMats*compiled.batch and per-operation inputCount=compiled.batch. This is mathematically equivalent to the other path when batch is correct, but rangeFor() may infer occurrence/ranges rather than measure them. These must be labeled inferred and cannot earn high field confidence.

GameData.lua Cobalt/Titanium rows show matRate=0.235 and amountOfMats=0.5 per input, with minAmount=1,maxAmount=2. For each gem, this implies 2.5 expected units per five-ore operation versus maximum 0.47 if matRate is an operation-level hit probability. The discrepancy is in source field semantics or data, NOT proven to be a runtime double-multiplication bug.

Additional caution: legacy TSM fallback confidenceCap=80 is a cap, not proof the underlying probability and expected quantity fields have 80-point evidence. Missing output prices are treated as partial priced outputs and the subtotal may not justify a winning action without other gating.

Next: inspect selection order for Cobalt/Titanium fallback vs compiled models; verify TSM matRate semantics against original source; verify whether partial-priced output totals can win. No addon edits; full >=90 evidence gate not met.
