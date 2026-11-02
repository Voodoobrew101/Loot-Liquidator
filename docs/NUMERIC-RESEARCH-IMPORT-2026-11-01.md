# Numerical research import review

Merged baseline version: `0.11.0-claude.23`, main `9c20291e02915254f9717d771b32e36efd0b672c` (PR #19; prior main `905956d`). Research Manager activation rechecked the manifest and generated counts below. The earlier report named a superseded source pin and understated the final merged data.

## Included data

The pinned v3 research snapshot advances from `9a22e2787ec133419bad9bce66d036219e2439a4` to **`4df9ae8b1359d934828e4d0e6d39a9a4dba26fae`**, as recorded in `database/research/v3-snapshot/SNAPSHOT.json`. The snapshot remains a verbatim copy of that research commit, with its calculator dependencies included. Worker evidence and the research branch are not edited by this integration.

| Compiled v3 coverage | Previous | Candidate |
| --- | ---: | ---: |
| Processing records | 89 | 206 |
| Materials | 443 | 780 |
| Token records | 229 | 230 |
| Token rewards | 645 | 652 |
| Listed disenchant gear-group gaps | 35 | 33 |

The merged baseline includes 123 disenchant, 48 milling and 35 prospecting records. These v3 counts are a subset of 265 active ItemDB processing records; 137 historical legacy records are stored separately. These counts describe database contents, not actionable item coverage or current-patch scientific verification. Exact-item records do not automatically cover every other item in their expansion/rarity group.

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

The original implementation was tested under actual Lua 5.1 (Lupa on Windows). Research Manager activation reran `bash tests/run.sh` under native Lua 5.1 against merged main: all checks passed, including 2,600 v3 baseline assertions and 906 v3 runtime assertions. Main's GitHub addon run 41379049334 passed. The separate research-branch migration workflow failed 6 of 402 tests at reviewed head `9bc7f267`; this failure is distinct from the passing addon pipeline. The scaling audit passes 13 checks with no real numeric profession coefficients shipped. No live WoW test is claimed.

## Research Manager follow-up (separate candidate)

The S21 import correction restores one previously discarded Eternity Amber family output for `Prospect 194545 x5`, giving **781** material entries while retaining the same 206 records and original evidence pin. The original four units over 80 completed prospects provide unconditional E=0.05; P(hit), conditional range and exact output rank remain provisional/unknown as appropriate. The family is priced through existing `rankIDs=[192849,192850,192851]` behavior, never described as measured rank 1. Existing material values are unchanged. The pinned evidence/calculator files are unchanged; the import's versioned in-memory output-identity correction is recorded in generated provenance.

The follow-up passes the full native Lua 5.1 addon suite, three new S21 regressions, and a real-engine/expanded-tooltip fixture at synthetic prices. Its v3 suites pass 2,603 baseline and 907 runtime assertions. These are candidate results awaiting PR Director review, not changes already integrated into main. See `docs/research-manager/CHECKPOINT.md` and `baseline.json`.

## Remaining gaps

The converter still excludes nine unlock-dependent estimates without usable specialization mappings, seven curio exchanges without costs, eight missing-batch estimates, 74 mixed-batch estimates, unresolved rank families and unrecognized gear groups. The older rank audit still reports 113 unresolved identities and four preserved conflicts. These exclusions remain visible rather than turning unknowns into zeros or fabricated probabilities.

Item **272246** still has no new exact-item v3 record in this pin; this import does not claim to resolve every reported Midnight badge or tooltip discrepancy. Item **237362** retains provisional prospecting values; independently measured per-output hit distributions are still a research task. No real skill/spec normalization coefficients are added. Aggregated Looter observations lack complete patch, skill and item-version attribution and remain provisional.

PR #13 still has five conflicts in older JS preview tooling against the current research branch. That toolchain is separate from this pinned Python v3 import; resolving it is not a dependency for this candidate. Do not merge its complete old tree over the modern research branch or this addon.

PR #19 is already merged. The Research Manager follow-up requires separate PR Director integration; this activation performs no release, live installation, branch deletion, PR closure or production merge.
