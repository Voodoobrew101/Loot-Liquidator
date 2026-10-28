# Batch 8: Personal observation blending unit mismatch

Research-only audit of main/ConversionEngine.lua, 2026-10-28.

Finding A: BlendProcessingYields requires personal.inputCount == batch and reference.inputCount == batch (near line 251). Legacy TSM fallback returns inputCount=1 (near line 519), while prospecting operations normally use batch=5. When that fallback reaches Automatic mode with personal five-ore observations, the blend returns the reference unchanged. The issue is specific to the path and requires runtime confirmation of selected model and observations; no live reproduction claimed.

Finding B: BlendProcessingYields maps personal output IDs and uses observed=0 for an absent personal output. If absent means a true observed zero over all operations, this is correct. If the personal recorder omits untracked output types, the reference is improperly pulled toward zero. Confirm recorder completeness before changing logic.

Finding C: Compiled fallback rows copied from TSM are constructed with expectedQuantity=amountOfMats*batch and inputCount=batch; those can blend with same-batch observations. But ProcessingYieldDisplayModel checks legacy TSM before compiled fallback, making the compiled normalization potentially unreachable for overlapping inputs without earlier model selection.

No addon Lua modifications. No confidence promotions. Next: trace actual Cobalt/Titanium lookup and personal recorder's zero-output semantics; build deterministic Lua fixtures to verify the mismatch. The all-field >=90 evidence gate remains unmet.
