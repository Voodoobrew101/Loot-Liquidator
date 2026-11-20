# Native loot and item-use scenarios

The profession settings expose a separate context selector for native effects
scoped to `Loot` or `Use`. These scopes cannot use the crafting or gathering
route: cloth discovery from enemies is not additional cloth from crafting, and
a consumed flask's vial refund is not crafting Resourcefulness.

`GetProfessionOpportunityTargets` derives contexts from the compiled native
node and method. It retains native label membership, entry IDs and named output
families. `ProfessionOpportunityPreview` resolves the selected real/manual
profile and calls `OpportunitySimulationModel`. Every current native Loot/Use
output entry is reachable through these public APIs: 49 output entries across
25 context groups. Settings displays their numeric metrics and the same model
in a native hover tooltip.

The reference is **one normalized baseline opportunity**, not an observed kill,
loot roll, consumed item or sample denominator. These scenarios have confidence
zero because the baseline frequencies and some coefficients are unknown.

- Typed additional-output priors become normalized additional-unit indexes.
  Their sum gives an output index of `1 + sum(additional units)`.
- Native relative-chance terms retain their relative discovery factor.
- A typed absolute-chance term with no absolute activity baseline is represented
  as an index increment `1 + term`; this is an explicit normalized scenario
  assumption, rather than an asserted probability of loot from one kill.
- Known item identities remain IDs; unresolved families remain named. A numeric
  index does not resolve an item's identity or price.
- Skill, stat grants, recipe unlocks, eligibility and other effect totals remain
  separate displayed dimensions. They are not forced into extra item quantities.

Target selection supplies scope labels. It does not silently activate an aura,
holiday or regional condition. The existing conditional controls let the user
explicitly select those states. Positive investment and learned-at-zero states
retain the native point/milestone dispatch rules.

The result has no priced material rows, liquidation value or actionable
conversion. No per-kill gold rate is assigned to a bag item, and no use refund is
charged or credited a second time. Crafting Multicraft/Resourcefulness do not
change these activity outcomes. A selected benchmark scales normalized output
indexes once; it does not create probabilities or Resourcefulness consumption.

The APIs allocate separate result objects and preserve all processing source
means, counts, observed profiles and compiled baseline records. The public-API
regression exercises every registered context/entry, both methods, conditional
states, benchmark replay and absence of fake probabilities or actions. Native
Settings tests exercise actual selectors, sliders, conditional controls and
hover tooltips.
