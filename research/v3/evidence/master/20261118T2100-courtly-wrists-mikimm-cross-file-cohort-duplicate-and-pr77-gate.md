# 2026-11-18 21:00 UTC — Courtly Wrists original-cohort refile / PR #77 exclusion hole

Research-only source identity and admission audit; no new Retail drops, client results, addon edits, merges, releases or validated actionable gold decisions.

## Newly verified identity defect

A **single original MikiMM 1,000-disenchant Courtly Wrists (item 239671) study** appears in **two distinct worker-owned evidence files**, on 2026-11-02 and again on 2026-11-18. The Nov 18 file is a re-transcription, **not an independent 1,000-operation cohort**. Both point to the same original [Wowhead comment](https://www.wowhead.com/item=239671/courtly-wrists) and state Disenchanting Delegate / Shard Supplier maxed.

- Prior original transcription: [2026-11-02T1105-miststalker-and-courtly-de-milling.jsonl](../midnight/2026-11-02T1105-miststalker-and-courtly-de-milling.jsonl), blob `4b7b87c09c6a3e6bf7c3b7d78b5570829fca81f2`, IDs `midnight-20261102-110512` through `-110518`, studyKey `wowhead-mikimm-courtly-wrists-1000`.
- Newly duplicated transcription: [2026-11-18T2015-courtly-wrists-1000-original-de.jsonl](../midnight/2026-11-18T2015-courtly-wrists-1000-original-de.jsonl), blob `52e9340229cdf838658f80a97c713f8b29f7bdf8`, IDs `midnight-20261118-2015-001` through `-007`, studyKey `wowhead-mikimm-courtly-wrists-1000-original`.
- The seven exact source output item/rank/total vectors match: Bright Linen 236963 R1=71, Radiant Shard 243602 R1=629, Radiant Shard 243603 R2=660, Tranquility Bloom 236761 R1=60, Refulgent Copper Ore 237359 R1=43, Void-Tempered Scales 238513 R1=72, Void-Tempered Leather 238511 R1=43. All seven rows repeat **the same 1,000 completed operations**, not 7,000 or 2,000 independent casts. Neither file has per-output hit counts, zeros or histograms. These are material units, not occurrence probabilities. Original source has no actual at-cast item bonus/level, full skill, item build/patch or per-event co-outcome export.
- For the **maxed-spec character only**, the source gives 1,289 Radiant Shard units across 1,000 disenchants (1.289 units per cast across two ranked materials); this does **not** identify shard hit probability or justify applying the yield to a generic unskilled character.

## Why this matters at the newest heads

- The v3 estimator's source identity and row-vector dedupe in `research/v3/tools/build_estimates.py` (`source_key`, `study_vector`, `study_identity`) can recognize exact same-source vectors; **no actual double-counting was demonstrated**. The danger is not an asserted 2,000-cast result.
- **Open [research-only PR #77](https://github.com/Voodoobrew101/Loot-Liquidator/pull/77)** already adds seven `exclude=true` corrections for the **Nov 2** version of this maxed-spec study, to prevent unconditional generic skill/spec valuations. On the inspected PR branch `fix/research-accuracy`, **none** of the seven **Nov 18** refiled record IDs is excluded. Thus applying #77's older-ID-only exclusions now leaves the same maxed-spec source eligible for the usual reference/estimate path. The full estimator and addon have not been rerun against a candidate combining this newest research head with PR #77; this is an observed **correction-scope hole**, not a claimed observed tooltip regression.
- Main has advanced to `bddd2c160f9f361647c4846bb42f57135045659c` via the separate owner-managed research refresh; its pinned `database/research/v3-snapshot/SNAPSHOT.json` points to `d5f32b2cc7a452f019ddc0533eaf032fed398f3d`, which includes the Nov 18 refile. The main build workflow reports success on that main head, but success does not validate specialization eligibility.
- The three-pass owner addon branch `implementation/usable-data-tooltips` at `3d667d053db587c91401cfed7ecc56862b8340c9` is untouched.

## Actually executed verification

149/149 bounded, in-process JavaScript assertions passed on the two fetched source files, current research corrections and the pending PR #77 corrections: seven rows each, exact matching item IDs/ranks/material totals/casts/source URL/sourceKind/all four numeric fingerprint fields, one original source, distinct studyKeys, absent per-cast hit histograms, seven older exclusions but zero newer exclusions in #77, and zero exclusions for these rows on current research. This is **source/code-path checking only**. No Python estimator, compiled ItemDB, synthetic-price resolver/tooltip, Lua addon test, game client or post-write CI was executed by this manager.

## Next targeted engineering / worker disposition

Preserve both immutable source transcriptions and one real original cohort. In the **existing research-only #77 review path** (not a competing addon/snapshot PR), extend cohort-wide typical-character exclusion or replace ID-specific guards with an original-source/cohort-identity scope; test old-only, new-only and both present against the actual v3 estimator, plus generic-vs-maxed-spec synthetic-price output. For supported maxed-spec character modelling, retain a labeled 1.289 shard units-per-cast conditional mean by output rank, while leaving occurrence chance, conditional yield histogram, patch and skill scaling unknown. Have Midnight target genuinely new current-patch per-cast Umbral Tin/T-Bloom records, not refile this source. Do not touch source originals, main or owner integration.
