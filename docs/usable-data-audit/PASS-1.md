# Usable data to tooltips — pass 1 checkpoint

Status: ingestion repairs implemented and locally validated; broader runtime/token completion continues in pass 2. One integration branch/PR is used through all three passes. No main merge or release is performed here.

## Source and code revisions

- Current main reviewed: `c5930a796e92d7236217ccd672bdbd7bcdf90f31` (PR #21 already merged).
- Implementation starting point: `implementation/usable-data-tooltips` at `d7a04fc002b7b8b02a19d3af91e15e7220a61e43`, including the already tested optional averages, compact ranges and five output sorting choices.
- Immutable numerical evidence snapshot retained: `4df9ae8b1359d934828e4d0e6d39a9a4dba26fae`.
- Latest research reviewed separately: `db80de8088ecef511de66ee45c44d597f8ceda87`, 277 relevant v3 evidence/tool/condition files and 7,234 raw records. The failed migration output is not imported wholesale. Research PRs #22/#23 remain separate dependencies to review, not changes silently folded into this branch.
- Git CLI cannot reach its configured proxy. Connected GitHub tools supply exact current heads, source reads and publication. Original worker files and evidence history are unchanged.

## What changed

The build deliberately omitted 130 stored historical conversion records even though their numerical fields remained available. These are now admitted as the unified **Reference tables and calculators** source inside ItemDB, with a visible checkbox/weight control. This implements the owner's current clarification superseding the earlier prices-only rule for conversion evidence. Live TSM Auction House pricing remains an independent pricing path.

Reference values fill missing fields only. Usable research, personal, imported or legacy values keep their existing precedence and are not averaged with another copy of a historical rate. Disabled/zero-weight sources and personal-only mode still work; the cache includes the reference preference. Fixed reference rates never pass through ItemDB-only profession scaling.

The source also contained quality alternatives that its old adapter dropped. Fourteen additional grouped records now retain 74 conservative unknown-rank output pools. Pool identity comes from sourced family-ID mappings or an explicit three-quality milling contract, never matching totals alone. The expectation is the minimum source projection across alternative qualities, not their sum, and pricing uses the existing cheapest-priced-rank behavior. Original variants and the assumption are preserved. Existing priced rank-specific or family outcomes suppress overlapping fallback pools to prevent double counting; partially known rank cases remain a pass-2 selection review.

Thirty-one historical means contradicted their own probability/range fields. For example, Cobalt common gems had E=2.5 each alongside P=.235 and range 1–2. Blindly restoring six such means would restore an implausible total. Every original value remains in the source and in generated `referenceOriginal`. The alternative E=P×minimum-positive-yield is explicitly modeled at reduced confidence and labeled as a conservative correction. It is not a measured mean or a source rewrite.

The publicly readable Midnight prospecting workbook was inspected live, including formulas and both quality sections. Its ordinary base constants are usable even though its additive Resourcefulness formula is flawed. `reference_calculators.py` parses only the recognized formula's base term in an explicit zero-Resourcefulness scenario. It imports no saved prices, profits, cached zero outputs, fake sample counts or stat bonuses. Seven input records carry 42 ordinary material entries. The two output-quality sections are alternatives and remain one rank-unknown family per output. Seven unlock-only Diamond formula rows and two unidentified-herb BfA calculator rates remain held with specific reasons.

Two other native spreadsheets and one Excel workbook were located and inspected through bounded reads/readable extraction. They already have 444, 26 and 88 pinned evidence transcriptions respectively; they are not new independent experiments. Their source metadata, formula/denominator follow-ups and exact URLs are in `source-inventory.json`. In particular, the Dragonflight workbook contains six skill/talent-conditioned raw-yield columns. Recover compatible quantities from that original source rather than requesting duplicate studies or inventing a skill curve.

The compiled dataset now carries its v3 source revision plus the reference version/calculator hash. `/ll status` includes the reference-record count and actual v3 pin, rather than reporting only the old research compiler manifest.

## Reproducible audit

Run from the repository root:

```sh
python3 tools/reference_calculators.py --check
python3 tools/audit_usable_data.py --validate
bash tests/run.sh
```

`processing-ledger.csv` traces **3,586 source/output transcriptions**, including raw quality variants, through normalization/admission and actual runtime/tooltip fields. These are transcriptions, not 3,586 independent studies. `runtime-probes.jsonl` stores each actual offline rendering once. `token-ledger.json` inventories the 230 compiled token records/652 reward relationships and 103 discovery hints lacking validated catalog relationships. Those hints include currencies and reagents; they are not 103 confirmed gear tokens.

The controlled census uses 365 known method/input/batch profiles, explicit synthetic build/skill conditions, source settings enabled and a fixed **100-copper net price per output material**. It calls the real resolver, valuation engine and formatter. It bypasses real character ability and is not an exhaustive eligible-Retail-item census or live best-action coverage measurement. Average quantities are enabled for the audit's Breakdown view even though the player default is off.

| Offline result | Main baseline | Candidate |
| --- | ---: | ---: |
| Profiles with complete listed values | 307 | 356 |
| Profiles with partial values | 8 | 7 |
| Profiles without a model | 50 | 2 |
| Additional profiles with numerical values | — | 48 |
| Previously partial profiles completed | — | 1 |
| Runtime errors / lost numerical profiles | 0 / — | 0 / 0 |

The active ItemDB contains 416 processing records (265 existing research plus 151 reference fallbacks), with 1,490 material entries; 137 legacy records remain separately nested in the same ItemDB. Counts alone do not establish character eligibility or scientific current-context accuracy.

Generated ledgers and renderings reproduce byte-for-byte across consecutive audit runs. Full native Lua 5.1 addon checks pass, including calculator parsing/quality isolation, actual reference-to-tooltip propagation, source toggles/zero weight/personal-only behavior, primary-value preservation, rank-family overlap protection, source immutability, existing token/cost/recording checks, and the new census regression guard. No WoW client test is claimed.

## Work to execute in pass 2

1. Fix the remaining TBC rare-armor model gate: `Disenchant:gear:1:3:armor:x1` has chance/bounds but cannot anchor because all stored expected quantities are missing. Derive a labeled supported expectation before anchor selection, retaining independent field confidence and original evidence.
2. Resolve `Prospect:199344:x5` input identity/processing eligibility before admitting its raw rates; neither existing curated input metadata nor a compiled record identifies it. Do not turn an unresolved source ID into a current Retail recommendation.
3. Trace the seven partial profiles: the exact IDs are in `summary.json`. Separate usable missing cooutputs from incompatible rank/recipe profiles, preserve observed ranges, and retain a clear reason whenever a field stays unknown. Expand field selection safely rather than mixing a pooled expectation with a rank-specific occurrence rate.
4. Audit tokens through the real character/variant/appearance/redemption path. Test known reward values and vendor/eligible disenchant alternatives, wrong-class tokens, transferable alts and unknown curio costs. The relationship ledger is ready; token behavior is not declared complete by catalog counts.
5. Reuse the original paired-skill Dragonflight and Legion sheets already represented in evidence. Fill ready field gaps from their source totals/reference formulas without counting the same original study twice. The BfA sheet needs a concrete herb identity; it is not rejected for lacking measured casts.
6. Keep the already tested display settings: average quantity off by default, no x in ranges, output sorting in native Tooltips settings. Show supported fields and prices while making real field-level unknowns understandable.

Pass 3 will reconcile current main, close the complete audit ledger, run final local/GitHub checks and make the single integration PR ready for PR Director review/merge. Retain the distinction between this passing addon pipeline and the separate six-failure research migration workflow.
