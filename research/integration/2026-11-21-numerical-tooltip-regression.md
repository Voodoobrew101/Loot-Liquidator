# Numerical tooltip pipeline regression

The regression starts with an explicit zero skill, zero specialization and zero
stat profile. It then resets that profile before each skill/stat scenario.
`tests/test_numerical_pipeline_stages.lua` uses the real profile selector and
`ProcessingPlayerConditions`, compiled studies and native recipe definitions.
Only game action access, UI boundaries and market prices are fixture values.

- 78 compiled modern numerical processing inputs/categories have finite baseline
  quantities and quotes; no source-scoped operation remains without a baseline.
- 209 isolated scenarios cover all 13 professions, native crafting recipes,
  processing and gathering modifier previews. Gathering indexes do not claim
  unobserved world-item yields.
- Quality-only changes conserve each material family's units. Unidentified rank
  references cannot become extra milling cooutputs alongside a measured family.
- The named-character route reads 64 skill plus 40 equipment once and retains
  the existing goggles cohort: 200 operations, 90%/10% shard probabilities and
  85% source confidence. Those are historical observations, not current-build
  casts. All source fields are checked for mutation after the scenarios.
- Known means remain numerical in tooltips even when occurrence probability is
  not identifiable. Fixed-stack inference rejects contradictory contributor
  summaries and records; modeled probabilities never acquire target counts.

Recycling retains all fourteen original build70783 contexts and their 200 unique
operation IDs. A separate, explicitly assumed zero-profile prior uses 421/200 =
2.105 rank-one Evercore units per five inputs. Its active sample count and current
patch applicability confidence are both zero. Source skill21–35 quantity
invariance and patch transfer are assumptions; no current probability or range
is manufactured. Native recipe, input rank and output family bindings are
validated at compilation. See `tests/test_recycling_zero_prior.py`.

The earlier zero-bonus test had an incorrect colon-method receiver and silently
exercised the wrong profession. Its receiver is corrected. Source-only mode
is diagnostic: disabling required normalization can admit a different set of
records than a complete zero profile, so it is not an equivalent baseline.
