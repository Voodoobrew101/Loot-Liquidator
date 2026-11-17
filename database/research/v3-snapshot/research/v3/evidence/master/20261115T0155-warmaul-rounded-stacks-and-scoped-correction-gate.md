# Coordinator audit — Warmaul historical conditional-stack reconstruction and duplicate-ID admission gate

Audit time: 2026-11-15 01:55 UTC. Research-only; not a new current-patch Retail cohort or an addon/code change.

## New checks on the Legacy worker's 01:45 UTC source repair

Read the *preexisting* source transcriptions at `research/v3/evidence/legacy/2026-11-01T1441-warmaul-looter-item-specific-hit-counts.jsonl` and the new *nonweighted* derived rows in `research/v3/evidence/legacy/2026-11-15T0145-warmaul-conditional-stack-arithmetic-reference.jsonl`. Each original row contains an integer positive-hit count and decimal **percentages of the positive-hit stack sizes** (not probabilities of an entire disenchant's material outcome). For all twelve rows, independently enumerated integers 0..hits for each displayed percentage at its own decimal precision, and found **exactly one compatible stack-bin count per size**. All twelve reconstructed histograms sum to their original positive-hit counts, and all twelve quantity totals equal the size-weighted bin sums. No missing bin or invented observation was added.

| Input gear (original reported operations) | Output item | Historical material positive hits | Reconstructed total material units | Derived unconditional material units / reported operation |
| --- | --- | ---: | ---: | ---: |
| Warmaul Legplates 24995 (2,068) | Arcane Dust 22445 | 1,559 | 5,638 | 2.726306 |
| 24995 | Greater Planar Essence 22446 | 417 | 695 | 0.336074 |
| 24995 | Lesser Planar Essence 22447 | 7 | 19 | 0.009188 |
| 24995 | Large Prismatic Shard 22449 | 48 | 48 | 0.023211 |
| Warmaul Breastplate 24992 (2,256) | Arcane Dust 22445 | 1,757 | 5,960 | 2.641844 |
| 24992 | Greater Planar Essence 22446 | 389 | 583 | 0.258422 |
| 24992 | Lesser Planar Essence 22447 | 13 | 37 | 0.016401 |
| 24992 | Large Prismatic Shard 22449 | 55 | 55 | 0.024379 |
| Warmaul Greaves 24991 (2,140) | Arcane Dust 22445 | 1,628 | 5,529 | 2.583645 |
| 24991 | Greater Planar Essence 22446 | 422 | 654 | 0.305607 |
| 24991 | Lesser Planar Essence 22447 | 12 | 34 | 0.015888 |
| 24991 | Large Prismatic Shard 22449 | 43 | 43 | 0.020093 |

These are **mathematically reconstructed material units from archived source percentages**, not original independently logged quantity totals. The input-side denominators are mutable Wowhead Looter cumulative reports, with original collection version, character skill and item bonuses unknown. Their reported operations sum to 6,464 across three input items, not 6,464 newly measured or current Retail events. An individual material's non-hit count can be obtained from a validated item-side denominator minus its material positive hits; it must **not** be advertised as a zero-total-material disenchant or a joint outcome histogram. The four listed material-hit sums are 2,031 / 2,068, 2,214 / 2,256 and 2,105 / 2,140; the unexplained differences of 37, 42 and 35 are not proven zero-outcome casts and may reflect other/unlisted outputs or source sampling.

## Newly demonstrated concrete data-integrity blocker

Each original Warmaul record ID `legacy-20261101-201` through `legacy-20261101-212` **collides** with a different record in `research/v3/evidence/legacy/2026-11-01T0752-outland-disenchant-originals-ulduar-token.jsonl`. The collided IDs there describe *Netherweave Bracers/Belt* 21849/21850 with distinct source studyKeys, not Warmaul gear. Current `research/v3/tools/build_estimates.py` `load()` builds a global set of `replaces` **by record ID alone** and drops every row whose ID matches. Thus adding `replaces: "legacy-20261101-201"` to the new Warmaul entry would also erase an independent unrelated Netherweave source record. **Do not set `replaces` or an unscoped correction for these IDs.** The 12 new rows are correctly `sourceKind:reference`, `replaces:null` while held for adjudication; do not treat them as 12 new independent studies.

A lower-risk numeric-only implementation already exists in the compiler: `apply_corrections()` accepts `{"recordID":..., "file": "<exact source path>", "field":"totalQuantity","value":...}` and `CORRECTABLE` includes `totalQuantity`; it applies file-qualified fixes **after** the global replacement filter. After review and a paired Netherweave no-loss regression, file-qualified correction of the original twelve Warmaul quantities could preserve their original positive-hit counts and original study identities without treating the new reference as a second cohort. However, **`histogram` is not in `CORRECTABLE`** and the current estimator has no `histogram` handling; importing the whole distribution requires a separate reviewed schema/compiler update. The source's rounded-percent reconstruction must remain labeled as inferred, not independently observed totalQuantity.

Stored `research/v3/output/estimates.json` at blob `15ae8c5b7f7b2587ceff1dcd3e8b9d13d4351d1e` has **no 24995/24992/24991 estimate entry**. This is a stored artifact inspection, not an actual current-branch compiler or addon run. Treat the missing record as a research-to-compiled-data gap, not proof of a currently broken in-client tooltip. A correction might feed supported historical estimated material value in a controlled synthetic-price test **only after** input legality and version/skill compatibility are established. A modern Retail item listing verifies item identity, *not* disenchant eligibility or output rates.

## Acceptance gate and next work

1. Preserve both append-only original files. Ensure future source promotion is keyed by (file, recordID) or a verified unique study/record identity; do not apply an unscoped `replaces` to any collided ID.
2. Recompute all twelve positive histogram bin sums, derived quantities and source-precision roundtrip, then verify the twelve original Warmaul rows and twelve independent Netherweave rows remain present exactly once.
3. For scoped quantity corrections, verify before/after actual v3 compiler output and downstream *owner-controlled* offline ItemDB/valuation/tooltip proof with synthetic prices. No fake per-hit zero bins, no extra casts, no manufactured confidence, and no inferred Retail rank/skill/bonus applicability.
4. Prioritize original *current-patch* full itemLink+bonus, enchanting skill/specialization, confirmed eligibility and per-completed-operation 0..N materials if Warmaul gold decisions are to be supported for present Retail. Keep distinct TWW Shimmering Dust weekly conditional knowledge (227662) and Pioneer's Cuffs Rare Resourcing side-output (210930) gated to documented context rather than unconditional salvage value.

**Checks actually performed:** GitHub original and worker evidence read-back, independent integer-enumeration percentage-roundtrip on 12/12 rows, independent histogram/total/units arithmetic, file ID join revealing all 12 collisions, static examination of `load()`, `CORRECTABLE` and `apply_corrections()`, and stored estimate content inspection. External current Wowhead Looter HTML could not be independently reopened; historical third-party WotLK item tables and 2026 Retail item listings confirm name/ID background only, not source denominators. **Not run:** Python estimator, Lua/synthetic-price audit, live WoW, or CI on this manager revision. No main, owner three-pass branch, shared corrections, queue, worker files, PRs, or schedules edited.

Sources: archived worker snapshots above; original cumulative page links [24995](https://www.wowhead.com/item=24995), [24992](https://www.wowhead.com/item=24992), [24991](https://www.wowhead.com/item=24991); current item-identity background [Warcraft Wiki Warmaul Legplates](https://warcraft.wiki.gg/wiki/Warmaul_Legplates), [historical WotLK table](https://wotlk.evowow.com/?item=24995).
