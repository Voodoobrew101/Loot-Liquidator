# DobberSH original Null Stone prospect — one operation across two research files

**Review date:** 2026-11-21T00:57:38.847Z UTC
**Task:** T0040 (cross-file cohort independence and build admission safety).
**Status:** original comment independently reopened; source/correction JSON inspected. No new study or Retail gold decision.

## Source and exact observation

- Original: https://www.wowhead.com/spell=434018/algari-prospecting (DobberSH comment on Algari Prospecting, source date not stated).
- The commenter describes **one** prospect consuming five Null Stones and receiving **one ruby, one emerald, one pebble, and one glass**. The spell's current indexed description specifies a five-input prospect. This is one positive event for each of four named outcomes, **not four independent operations**.
- Historical input: Null Stone 210939; research output identity mappings: Radiant Ruby 212495, Extravagant Emerald 212505, Handful of Pebbles 213398, Glittering Glass 213399. Source comment itself gives output names, not explicit output item IDs, quality ranks, character skill or spec.
- Never treat the four single-positive results as measured frequencies for future casts, per-output zero rates outside the one observed output event, a representative Retail sample or evidence of current-build eligibility.

## Duplicate transcriptions and correction

The first file `research/v3/evidence/war-within/2026-11-02T0918-null-stone-prospects-and-glass-cohorts.jsonl` records IDs `war-within-20261102-0918-004..007` under `wowhead-algari-prospecting-dobbersh-null-stone-one-cast`.

The second file `research/v3/evidence/war-within/20261117T1130-original-de-rank-cohorts-nullstone-prospect.jsonl` records IDs `war-within-20261117-113010..113013` under `wowhead-algari-prospecting-DobberSH-one-nullstone-cast`.

All **eight** file-scoped source rows have the same source URL, author, input 210939, exact four output IDs, 1 completed cast, 1 total unit, 1 positive hit, and positive stack `{"1":1}` per output. Four older and four newer rows are **one original four-outcome cohort**, not two independent four-outcome cohorts.

Appended exactly eight `cohortKey` corrections to `research/v3/corrections.jsonl` (commit [`405f4f480b`](https://github.com/Voodoobrew101/Loot-Liquidator/commit/405f4f480b097cb6c138a22e8ba0daa9884d618d)):

`wowhead-algari-prospecting-dobbersh-one-original-null-stone-cast`

Applied to all eight IDs with exact file keys. `research/v3/tools/build_estimates.py` defines `cohortKey` as an overriding independent-study identity. All four material groups can use a consistent one-original-cohort key, so copies are not weighted separately even when source `studyKey` spelling differs. Original evidence files remain byte-for-byte unchanged. This is provenance/deduplication correction, **not** a new observed yield, fabricated sample or confidence.

## Validation and limits

- Re-read both source JSONL files, compared the four ID/output pairs and operation, total, hit, histogram, source, input and method fields (8/8 consistent); ensured no prior `cohortKey`, `exclude` or `sourceKind` correction on these eight IDs.
- Appended eight syntactically valid JSONL correction records; verified row count increased by eight before GitHub update. Original source file blob SHAs: `97d5e2fd4000eddf5b9e9a3416231db67b9c2490` and `d2c0c95cdefcf6cc5049344c15a395bfab993d68`.
- Statistically the source is **one historical reported operation** under unknown character/build conditions. A single 1/1 hit may be recorded as a one-cast observation, but cannot establish a useful current Retail probability or population EV.
- **Not run:** exact-research-SHA automatic build review, ItemDB generation, actual resolver/tooltip with synthetic prices, Lua regression tests or live WoW client. No production files or owner implementation branch changed.
- **Next:** request scoped exact-research-revision build review to confirm two copies collapse to one source operation across four distinct outputs; prioritize independent current-Retail post-hotfix, rank/skill/refund-scoped zero-inclusive operation logs rather than more positive-only historical copies.

No new PR, merge, release or schedule change.
