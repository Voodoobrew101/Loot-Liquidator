# Numerical research import review

Candidate version: `0.11.0-claude.23`; base main `905956d`.

## Included data

The pinned v3 research snapshot advances from `9a22e2787ec133419bad9bce66d036219e2439a4` to `2d6cbbe383bdf88ed18432b38024bbb878c21dcf`. The snapshot remains a verbatim copy of that research commit, with its calculator dependencies included. Worker evidence and the research branch are not edited by this integration.

| Compiled v3 coverage | Previous | Candidate |
| --- | ---: | ---: |
| Processing records | 89 | 199 |
| Materials | 443 | 766 |
| Token records | 229 | 230 |
| Token rewards | 645 | 652 |
| Listed disenchant gear-group gaps | 35 | 33 |

The current candidate includes 116 disenchant, 48 milling and 35 prospecting records. These counts describe coverage, not current-patch scientific verification. Exact-item records do not automatically cover every other item in their expansion/rarity group.

## Integration corrections

- Five new fixed-yield records failed ItemDB's probability/mean consistency validator because independent six-place rounding made the emitted values contradict one another. The converter now keeps twelve places and constrains serialization roundoff to the emitted conditional bounds. Original counts, distributions and genuinely contradictory means retain their existing treatment. Validation is not weakened.
- A mean estimated as occurrence probability times a range midpoint now receives the existing half-confidence treatment. Large measured hit counts cannot by themselves grant a guessed mean 100% occurrence confidence.
- The source-toggle regression now checks that disabled legacy data contributes nothing while allowing newly available independent ItemDB data. The gap list removes the two newly covered groups (TBC rare armor and Dragonflight epic armor) and updates its counterpart flag.
- The requested repeated `EV` label before each average quantity is removed. The tooltip still explains average units including zero outcomes.
- Core and TOC versions advance together to `0.11.0-claude.23`.

## End-to-end examples

`tests/test_numeric_refresh_tooltip.lua` loads the committed ItemDB, real conversion engine and tooltip renderer, with deterministic test prices of 100 copper per material. Its gold figures are not live Auction House quotations.

- Warmaul Legplates, item **24995**: Arcane Dust occurrence `1559 / 2068`, positive range **2–6**, estimated average **3.0155 units** including non-hits. The mean uses the existing midpoint model, not an invented measured total. The rendered option carries 50% confidence and provisional context; all four material rows render numbers.
- Midnight item **258931**: Eversinging Dust occurrence `896 / 1485`, range **1–3**, source-total average `1838 / 1485` (rendered **1.238**). Numeric quantities reach both valuation and the rendered breakdown.
- Disabling the contributing evidence sources still removes the value.

The fixture checks source-count preservation, probability/range/quantity output, expected-value pricing without a second probability multiplication, provisional labeling and disabled-source behavior. Separate unit regressions cover fixed-yield rounding and estimated-mean confidence.

## Validation performed

The full addon suite passed locally under actual Lua 5.1 (Lupa on Windows), including syntax, deterministic generated-data checks, package validation, Settings, source gates, projections, token import, recording, counts model and numeric tooltip fixtures. The baseline suite passed 2,551 assertions and the runtime v3 suite 892; the scaling audit passed 13 checks with no real numeric profession coefficients shipped. GitHub's native Linux PR suite is also required before recommending merge. No live WoW test of this new candidate is claimed.

## Remaining gaps

The converter still excludes nine unlock-dependent estimates without usable specialization mappings, seven curio exchanges without costs, eight missing-batch estimates, 74 mixed-batch estimates, unresolved rank families and unrecognized gear groups. The older rank audit still reports 113 unresolved identities and four preserved conflicts. These exclusions remain visible rather than turning unknowns into zeros or fabricated probabilities.

Item **272246** still has no new exact-item v3 record in this pin; this import does not claim to resolve every reported Midnight badge or tooltip discrepancy. Item **237362** retains provisional prospecting values; independently measured per-output hit distributions are still a research task. No real skill/spec normalization coefficients are added. Aggregated Looter observations lack complete patch, skill and item-version attribution and remain provisional.

PR #13 still has five conflicts in older JS preview tooling against the current research branch. That toolchain is separate from this pinned Python v3 import; resolving it is not a dependency for this candidate. Do not merge its complete old tree over the modern research branch or this addon.

This candidate requires owner approval before merging to main. No release ZIP, live installation, branch deletion, PR closure or production merge is performed by this review.
