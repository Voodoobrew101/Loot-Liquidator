# TWW prospecting source epoch and DobberSH repeated-cohort review — 2026-11-20 13:00 UTC

**Scope:** independent source/document reconciliation, not a new original cohort, runtime fix, measured probability, or live-client check. Research task T0009/T0040; worker task T0048 is a separate DE task.

## Original historical rate epochs verified

1. [Blizzard running hotfix list, section **August 29, 2024**](https://worldofwarcraft.blizzard.com/en-us/news/24134803): improved gem prospecting rates for **Bismuth, Ironclaw Ore and Aqirite**, including the item-quality effect. The URL/page title may contain **October 16** because the running article was subsequently updated; the *dated section* carrying this specific change is August 29, not October 16.
2. [Blizzard hotfix list, section **October 25, 2024**](https://worldofwarcraft.blizzard.com/en-us/news/24148555/hotfixes-october-25-2024), independently corroborated by [Wowhead's Oct 25 hotfix transcription](https://www.wowhead.com/es/news/patch-11-0-5-hotfixes-for-oct-25th-more-class-bug-fixes-and-profession-economy-348782): corrected the Prospecting 40/40 Ambivalent Amber byproduct, changed Pebbles/Glass byproducts to every prospect, and slightly reduced gem/max-byproduct yields. This is a **second, separate** rate epoch.
3. Consequently, original Oct 15 **Reikah** Ironclaw observations are after the Aug 29 buff but before Oct 25; original Oct 27 Glass/Byproduct averages are *after* both changes. They cannot all be labeled "pre-Oct16 and pre-Oct25." Do not backdate historical rates or pool incompatible epochs. Post-Oct25 data still require exact rank, profession profile and actual casts before a measured modern rate can be claimed.

## DobberSH Null Stone one-operation source copy

Independently opened the [Algari Prospecting spell 434018 source comment](https://www.wowhead.com/spell=434018/algari-prospecting), with publicly readable mirrored comment on [Wowhead French language page](https://www.wowhead.com/fr/spell=434018/prospection-algarie). DobberSH reports **one** prospect consuming five Null Stones and receiving one each of a *ruby, emerald, pebble, glass*. This is **one original 5-input operation**, not four independent casts; original author did not provide patch, profession skill/spec or per-other-material zero-inclusive event log. His item names are plain names in the comment, not source-linked output IDs.

Checked two independently stored v3 copies, without modifying them:

- `research/v3/evidence/war-within/2026-11-02T0918-null-stone-prospects-and-glass-cohorts.jsonl` (blob `97d5e2fd4000eddf5b9e9a3416231db67b9c2490`), DobberSH IDs `war-within-20261102-0918-004..007`, studyKey `wowhead-algari-prospecting-dobbersh-null-stone-one-cast`.
- `research/v3/evidence/war-within/20261117T1130-original-de-rank-cohorts-nullstone-prospect.jsonl` (blob `d2c0c95cdefcf6cc5049344c15a395bfab993d68`), DobberSH IDs `war-within-20261117-113010..113013`, studyKey `wowhead-algari-prospecting-DobberSH-one-nullstone-cast`.

All four output tuples repeat exactly: input 210939 (one cast, 5 inputs), output IDs 212495/212505/213398/213399, one unit and one reported hit for each, histogram `{"1":1}`, same source URL and author quote. These are **eight transcribed rows but only four material outcomes from a single original cast**. IDs are the transcribers' catalog mappings, not independent original item links. Do not count two casts or infer a general drop probability from the one successful event.

The current research estimator `research/v3/tools/build_estimates.py` (`study_vector`, `source_key`, `study_identity`) fingerprints normalized original URL, input rank, casts and full numeric output vector; this pairing appears eligible for existing duplicate suppression despite differently cased studyKeys. However **the actual full estimator/build review was not run in this review**, so mark effective admission as unverified until an exact-revision generated report demonstrates one retained original cohort. Do not rewrite append-only originals merely to silence a duplicate warning.

## Remaining admission and next test

Run an exact-SHA build-time review from a fetched current research revision and assert four duplicate material rows cannot add a second cast; check disposition/reason in `build-study-review.json` and generated baseline. Keep unrelated Genyachris same-input separate as an independent author. Audit rank, recipe, skill and source patch before using even the deduped observation for current Retail pricing. Unknown other-output zeros, live eligibility, missing market prices and unsupported scopes remain separate from duplicate science.

**Validation completed in this manager pass:** compared the eight specific JSONL rows by source, input/output IDs and numeric semantics and separately opened the source page and dated hotfix announcements; reviewed estimator source logic. **Not completed:** full raw original game log, generated ItemDB/tooltip, automated build test, CI, synthetic-price engine test or live WoW. **New measured samples added: zero.**
