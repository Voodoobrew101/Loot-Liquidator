# Usable data to tooltips — pass 2 checkpoint

Status: runtime and representative token integration complete; final closure/reconciliation/CI review remains pass 3. Continue on the same draft [PR #24](https://github.com/Voodoobrew101/Loot-Liquidator/pull/24), branch `implementation/usable-data-tooltips`. Do not merge or publish a release here.

## Revisions and source policy

Implementation base is `71bdd9f976ad5e3923cddf51ad01185d6b562ad2`. Main remains `c5930a796e92d7236217ccd672bdbd7bcdf90f31` at the start of this pass. The immutable numerical research snapshot stays `4df9ae8b1359d934828e4d0e6d39a9a4dba26fae`; the failed latest migration is not imported wholesale.

The owner explicitly supplied AllTheThings as an exchange-data source during pass 2. This supersedes older blanket source exclusions for ATT research. Runtime ATT integration remains unnecessary: the build imports bounded, pinned Retail data into the single ItemDB. Original ATT source, MIT copyright/permission notice, revision, line references and preserved cost tuples are archived in `database/research/att-exchanges-snapshot.json` and `ATT-LICENSE.txt`.

ATT source: `ATTWoWAddon/AllTheThings` at **`4a95eab7696e74a929996eefd2f6890890e26efe`**, using `db/Standard`, not its Classic branches. The importer parses literal equipment leaf/cost data without executing ATT Lua. It preserves all extra item/currency/money costs. It admits 11 exchange-token identities and 415 reward/cost relationships, including the full six-item Sanctification-mark family. Missing class masks and inherited/faction requirements remain unavailable for recommendations; known costs and reward values remain informative.

ATT's curio symlinks also confirm difficulty-specific tier membership, including all 65 Season 2 tier pieces. This corroborates the prior staged candidate membership. These symlinks do not establish complete exchange costs, so seven curio records remain informational. No free exchange, arbitrary bonus-ID transfer, invented probabilities or fabricated observed counts is introduced. Firecrawl could not verify additional web pages because its connected account had no credits; the GitHub source and existing pinned evidence were used instead.

## Runtime repairs

- Derive a supported mean from P(hit) and stated conditional bounds **before** anchor selection. The former gate rejected an entire TBC rare-armor record before the existing derivation could run. The derived value is marked modeled, discounted, and never written into the original evidence.
- Preserve source conditional ranges when selected means/chances disagree with them. Explain the disagreement instead of replacing the range with a question mark.
- Restore raw per-input expectations for the two previously unmapped raw-table inputs. Magma Thresher now has numeric reference values without inventing a fish-specific recipe or cast size. The inferred input hint is display-only; a verified live recipe must establish an action. An existing primary milling operation retains its original batch hint.
- Let a supported family reference replace a wholly unknown exact-rank placeholder, while keeping separately labeled rank-specific probability/range references. Protect already priced ranks/families from double counting or accidental distribution mixing.
- Show calculator Diamond estimates as **conditional**, with their ore-specific Proficient Processor requirement. Seven conditional material entries now reach the formatter. Their numbers do not enter the current total while the unlock is unverified; output ranks are not invented. The conflicting Silver quality-section constants are preserved, and the lower conditional scenario is displayed.
- Replace unexplained processing `?` fields with explicit chance/yield/average-unavailable labels and a field-level reason. Retain numerical means/values independently of missing chance/range. Average quantities remain optional/off by default; compact ranges and all five sorting choices remain intact.

## Token behavior

The real catalog -> item-facts -> economic comparison -> formatter path is now covered by integration fixtures. Reward metadata does not require the token itself to have an NPC sell price.

- Match the opener's class, including ATT source masks when the DB2 lookup is absent. Explicit class exclusions win. A wrong-class or unidentified-class price is informative and cannot authorize opening.
- Choose an eligible current character or a verified transferable enabled alt. Redeemed soulbound equipment can only use its opener's Enchanting path; another character's profession does not make the redeemed item transferable.
- Preserve supplied exact reward links throughout valuation. Otherwise mark base-item/difficulty/bonus estimates explicitly. Do not copy a token's bonus IDs onto another item.
- Use the conservative supported result for unknown loot-specialization alternatives, and allow the best known result only for an actual documented choice. One loaded choice can be usable while other choices load; a random/unresolved outcome set cannot imply all outcomes are priced.
- Subtract all extra costs, then divide once by the number of tokens consumed. Item inventory, token quantity, currency balance, character requirements and exchange controls affect availability. A currency balance does not invent a copper exchange rate. An unknown or unaffordable exchange does not become a profitable or collection action.
- Account for consumed bound gear's own vendor or eligible disenchant opportunity value. Show a net loss where costs exceed the output; consuming an existing valuable piece is not free.
- Compare available token reward alternatives with Auction as well as the token's own vendor price. Retain appearance precedence for an eligible, affordable redemption.
- Re-evaluate token facts/cost balances as item data loads or inventory changes, avoiding the former thirty-second stale decision. Restrict broad exchange quote loading to known eligible classes when possible.

`token-tooltip-proofs.md` contains actual formatter output from controlled synthetic fixtures, including native Midnight catalog items and an ATT Sanctification exchange. These are not live prices or client screenshots.

## Baseline dashboard

The common census uses the same 365 source profiles, synthetic build/skill, fixed **100-copper net price per output material**, and actual resolver/valuation/formatter as pass 1. It does not establish live character eligibility, exhaustive Retail coverage or current market profitability.

| Comparable profile result | Main baseline | Pass 1 | Pass 2 |
| --- | ---: | ---: | ---: |
| Complete listed values | 307 | 356 | 358 |
| Partial listed values | 8 | 7 | 7 |
| No model | 50 | 2 | 0 |
| Newly numeric vs baseline | — | 48 | 50 |
| Lost numerical profiles / runtime errors | — | 0 / 0 | 0 / 0 |

Two additional per-input normalization profiles are also recorded, bringing the current audit to 367 profiles: 360 complete listed values and seven partial values. These are unit-reference profiles, not newly verified one-item recipes.

Current inventory: 418 active processing records / 1,514 material entries; 137 nested legacy records; 3,593 source/output transcriptions. The token catalog contains 248 records / 1,497 direct reward relationships, including intermediate-token links and ATT cost relationships. None of those counts is a count of independent experiments or live actionable coverage. Ninety-four discovery hints still lack catalog relationships and include reagents/currencies; they are not 94 confirmed missing gear tokens.

The seven remaining partial ore profiles are IDs 237359, 237361, 237362, 237363, 237364, 237365 and 237366. Their ordinary outputs are valued; their Diamond scenario is visible and conditional. Its unlock/character-rate applicability is not established. The two BfA workbook rates still lack exact herb identity. An unidentified input or unverified requirement is not repaired by inventing a zero or a universal multiplier.

## Validation and pass 3

`bash tests/run.sh` passes under native Lua 5.1, including all existing addon checks, strict calculator/ATT parsers, source immutability, source and method controls, full token economic/tooltip integration, zeros versus unknown, cost conservation, rank-family isolation and the numerical-profile audit. Generated artifacts are reproducible. GitHub CI must pass on the exact pushed head. No live WoW QA is claimed.

Pass 3 must refresh main/PRs and resolve any relevant dependency; review the entire defined source/field/disposition ledger; verify source and artifact reproducibility; inspect exact final GitHub CI; resolve any remaining regression or merge conflict; and make the **same** PR non-draft and ready for PR Director review. Keep unrelated research migration failures distinct from addon validation. Preserve genuine source/identity/character unknowns and state actual-client QA limits. Do not merge the PR.
