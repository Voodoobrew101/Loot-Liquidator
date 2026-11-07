# Cumulative 194-cast 82-skill update

Preserve the exact compact upload and decoded JSON from recorder revision 5 /
ecd189a. This is an update to the previously saved 97-cast study, not another
194 new observations. Operation-ID deduplication identifies **97 new casts**,
producing **87 R1 / 10 R2** Radiant Shards. All previous inputs, outputs,
contexts and metadata match; 53 prior duration floats differ only in their
last represented digits after a saved-variable/export roundtrip (less than
1e-12 seconds). Both source snapshots remain unchanged.

The cumulative study contains **194 Disenchant casts: 178 R1 / 16 R2**. All
measure base skill 64 + bonus 18 = 82, specialization none, and consume one
Evercore Shade 244752 at item level 165. Every record has real START, success
and complete output coverage. Account metadata reports 1,092 retained records.

The study is flagged for Craft:1229863 (unsettled inputs), with 50 retained
Craft diagnostics. There is no Disenchant gap, global gap or truncation.
Recipe-scoped strict staging therefore accepts all 194 Disenchant records in
four exact-context empirical cohorts. No trimming or gap waiver is needed.
The unrelated crafting gap and all raw flags remain intact.

This cumulative staging supersedes the numerical staging of
`../2026-11-07-pr49-82-skill-97-clean/`; never sum both snapshots. With the
earlier eleven distinct measured rod casts, the deduplicated usable 82-skill
sample is **205 casts: 187 R1 / 18 R2**. The separate flagged 172-record study
and its buffered 162-observation sensitivity sample remain available for
comparison without being counted in the 205. Across all those sources,
there are 377 distinct recorded 82-skill successes.

The optional 200-cast comparison target has been met. Do not request more
casts to reach it or discard the earlier observations. These files remain
research-only, with no automatic runtime-rate promotion, minimum-skill
assumption or specialization/skill coefficient. Addon runtime is unchanged.

The subsequently supplied SavedVariables file was copied locally and reviewed
read-only. Its 1,030 operation IDs are already archived: 791 Disenchant,
200 Recycle and 39 Craft. All 39 successful Craft records belong to the earlier
PR48-reported 1250ms study and are already preserved. No additional successful
crafting records or recorded-results backup were found. This disk file is
62 Disenchant observations behind the cumulative upload; those later results
are already preserved here. `savedvariables-review.json` records the source
hash and inventory. The raw local backup and unrelated player settings are
not uploaded, and no game files or settings were changed.
