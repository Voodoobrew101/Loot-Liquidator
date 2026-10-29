# Current-baseline profession projection: review build

Built from `implementation/database-profession-modernization`, not production main.
No merge or release has been performed.

## Final architecture

- `ItemDBRuntime.lua`: deterministic schema-v1 adaptation of the pinned research
  ItemDB. Original records, field confidence, conditions and source ancestry survive.
- `itemTSM.lua`: frozen TSM conversion reference, including the complete original
  tables. Never changed by auction-price refreshes or profession settings.
- `GameData.lua`: fixed legacy values, disabled by default, filling gaps only.
- WoW SavedVariables: original personal cast logs, game build, character settings,
  per-cast input/output identities and histograms. Raw records are not rewritten.

Existing source checkboxes and 0–100 weights remain. Defaults: research 100,
personal 60, frozen TSM 30, legacy disabled. Existing `source_tsm_` preferences
migrate once to `source_itemtsm_`. Personal-only/external-only policies still apply.

## Implemented versus not yet supported by real research

The client now has shared, reversible, explicitly supplied skill-factor evaluation
and versioned personal patch bridges. The builder and runtime share
`ProfessionModels.lua`; model exports live in `database/profession-models.lua`.
No confidence-threshold approval ceremony is imposed on these new models; basic
number, identity and scope validation remains. Provisional models must stay
identified as such.

**No real numeric profession or personal patch rules are shipped.** The research
snapshot still does not establish normalized current baselines. The model file is
empty intentionally. Selecting different skills therefore keeps actual shipped
yields stable until research supplies matching numeric factors. The synthetic
regressions prove the plumbing and reversible arithmetic, not game accuracy.
This build does not finish the research team's historical replay engine or invent
coefficients for qualitative hotfix notes. It is not a claim that ItemDB now
contains fully current normalized baselines.

Current-build ItemDB forward adjustments never replay historical patches. Personal
estimates can cross builds only through explicit recipe/output-scoped patch edges;
missing adjustments leave old samples separate. Each estimate is recalculated
from its original source, so reloads and repeated evaluation cannot compound it.
Skill conversions use the source and target profiles with the same piecewise
factor definition. Missing stats or unsupported profiles are left unadjusted.
Probability and conditional bounds are not invented from a changed expected mean.

## Source lineage and coverage

Research commit: 2ad202077f9b5b11c22f014bc7b5c9d1776f6b1c
Research file commit: e4efb5eeaa8aec85c350670308f73f7d33c6c37d
Research snapshot SHA-256: 658445940ce97aa138f6a4677130140b21cd025d4e522e6ea85786ef68db93d8

The pinned compiler 0.6.0 snapshot has 1,003 mappings. The build adapts 91
non-TSM mappings, identifies 903 TSM-derived mappings as the existing frozen source
family, and rejects 9 multi-reagent/unsupported recipe mappings from live valuation.
Exact rejected identities and reasons are in `ItemDB.buildReport.rejected`.
The full research snapshot remains in `database/research/itemdb.lua`; it is not
loaded directly by the WoW TOC. Research version/count and active runtime count
are deliberately distinguished in `/ll status`.

Frozen TSM uses the project's pinned `main/GameData.lua` source revision
`1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`, not a fresh TSM add-on download.
All 903 raw TSM rows remain in the frozen raw tables, including rank alternatives.
130 grouped usable source records (534 output entries) are exposed for weighting.
31 of those output entries have internally conflicting source fields; all raw
values are retained and flagged. All 903 raw rows have all four fields populated.
Research has 801 four-field-complete mappings out of 1,003; 900 contain an expected
quantity. Filled fields describe completeness, not current-game accuracy. Ambiguous exclusive
ranks are not summed into new estimates. The dataset preserves original
`matRate`, `minAmount`, `maxAmount`, `amountOfMats` and source/output rank values;
per-operation E is the original per-input amount times its original batch.
Inconsistent historical fields are retained with conflict labels, not silently
corrected. Detailed tooltips show source-specific estimates independently of the
aggregate. Only unconditional E drives expected gold.

The legacy reference has 137 grouped records. These counts use different units
from research input/output mappings and do not imply exhaustive Retail coverage.

## Validation

`bash tests/run.sh` passes under Lua 5.1, including syntax, deterministic rebuilds
of all three databases, package/load-order checks, existing modernization and
native settings fixtures, cast recording/export checks, and the scaling audit.
New tests exercise baseline -> selected skill, skilled sample -> baseline ->
current patch -> selected skill, immutable observations, reload/idempotence,
missing/ambiguous/cyclic patch paths, fixed-source isolation before aggregation,
legacy gap behavior, old-setting migration and complete TSM field preservation.
No real-client QA has been performed.

Economic synthetic check: with ItemDB E=3 and a documented test skill factor 2,
the derived contribution is 6; frozen TSM E stays 4. With user weights 100 and 30
and equal evidence quality, the aggregate is approximately 5.538 units/operation.
At baseline skill it is approximately 3.231. Legacy E=9 contributes nothing when
these enabled sources cover the output. A historical personal E=2 with a test
50% patch bridge becomes 3; raw E remains 2 and repeated loading still gives 3.
These are test fixtures, not current market recommendations or WoW coefficients.

## In-game QA before promotion

1. Install this review package, back up SavedVariables, load Retail, and check for
   Lua errors and `/ll status` database versions/counts.
2. Toggle every source, test weight 0 and 100, reset, and reload. Confirm migration
   preserves an existing TSM preference and auction prices still refresh.
3. Open professions on the current character and relevant alts; verify Manual,
   Auto and Force Off retain global recipe/character eligibility checks. With no
   numeric model the tooltip must say unadjusted rather than invent a skill effect.
4. Record complete positive and confirmed-empty casts, reload normally, and check
   original counts/histograms. Old-build samples without a bridge stay separate.
5. Exercise source details, ATT/token tooltips, native bags, BetterBags, guild and
   Warband banks, binding restrictions, vendor/mail/action protections and refresh
   performance. The code never executes a craft, sale or mail automatically.
6. Research must export real scoped factors/bridges and normalized baselines before
   anyone describes character-adjusted outputs as quantitatively accurate.
