# M05: study identity and deduplication

Session MIG-002, 2026-10-31. Numbers come from `tools/identity_report.py` and `tools/estimates_diff.py`
on the migration snapshot's evidence (4,404 effective records). Machine-readable lists:
`reports/M05-identity-data.json`. Full diff: `reports/M05-estimates-diff.md`.

## The rule now in `build_estimates.py`

A study is the rows sharing file + studyKey. Identity is computed per row:

1. `cohortKey` set: identity is `("cohort", cohortKey)`. It beats everything below.
2. Otherwise: (normalized source, inputRank, casts, numeric vector of the whole study). The vector holds,
   per row, (inputRank, casts, output, castsWithDrop, totalQuantity, percentShown, averageShown). Same
   fingerprint = copy. Same source with a different vector = independent cohort, so one matching zero-hit
   row merges nothing. `source_keys.normalize_url` (moved from `inventory.py`) compares sources.
3. Partial copies count as copies and are listed. Two studies from one source are copies when every
   numbered row of the smaller pairs with a row of the larger, it has 2+ non-zero rows, and rows **agree**:
   equal wherever both state a number. A copy under half the size of the original must also match labels.
4. Rows of a copy that lost item IDs land in a vaguer `family:` group, where the per-group dedupe cannot see
   the original. They are left out before grouping (S17). A row that states an unlock its original lacks is
   kept. The per-group "mark counted only when used" unlock skip is unchanged.

### Where this goes beyond the task prompt, and why

Each item was forced by real data; each has a fixture test.

| Addition | Why the prompt's literal rule was not enough |
| --- | --- |
| Outputs compared by **name first**, ID only without a name | The prompt said "outputItemID or lower-cased name", but then a copy with null IDs never matches its ID-carrying original |
| Vector rows carry input rank and casts | 5 studies span several ranks, with the same outputs repeated |
| Numbers compared null-tolerantly (rule 3) | `df-r3-serevite-8000…` adds `averageShown` to `reddit-108782r…`'s totals: same study, unequal tuples. Exact matching would have double-counted 8,000 and 4,000-cast cohorts that legacy merged |
| Labels ignored for copies of at least half the original | "Titanium Dust" vs "Titanium Powder" (18 of 19 rows equal), rows with an ID but no name, swapped gem labels |
| **Numbered batches stay apart even with equal numbers** (same file, keys differ only in digits) | Reddit 10u5ao8 batches 1 and 6 both report (7, 13) and 5 and 9 both report (15, 18). A plain fingerprint merges them, failing the acceptance criterion |
| **Pooled studies are left out** (exact sum of one batch family, same casts and totals, 2+ non-zero) | `df-q21-b019-100k` is the ten 10u5ao8 batches added up (20,000 casts, 112 + 194 diamonds). The source notes say not to add the total as another cohort. Counting both gives 40,000 casts for 20,000 real ones |

One more change outside identity: `load()` now writes `_file` with forward slashes. On Windows it held
backslashes, so all 610 file-scoped corrections silently failed (4,407 records and 1,181 estimates instead of
4,404 and 1,238). No effect on Linux.

## Before and after

| Measure | Before (legacy identity) | After |
| --- | --- | --- |
| Estimate groups where studies merge | 160 | 127 |
| ... with differing numbers dropped | **77** (236,076 material-level casts) | **0** |
| ... identical copies | 83 | 124 |
| ... inside a listed partial copy, numbers differ | n/a | 3 (see conflicts below) |
| Partial copies recognized | 0 | 23 |
| Pooled studies left out | 0 | 1 |
| Copy rows moved out of vaguer groups | 0 | 79 |
| Estimates | 1,238 | 1,203 (35 removed, 0 added, 79 changed) |
| Unplaced records | 35 | 35 |

**The logged 168 / 90 / 78 could not be reproduced.** The MIG-001 script was not committed. Using this
report's definition (study = file + studyKey, the four numeric fields) gives 160 / 77 / 83; counting by
studyKey alone gives 154 / 77 / 77; adding `histogram` gives 160 / 82 / 78. No variant tried gives 168 or 90.
The report's `legacy` block is the reproducible baseline from now on.

**The old "≈288k casts dropped" overstated the defect.** Of the 236,076 casts legacy appeared to drop, only
**29,056** were independent cohorts. The rest were copies with fields filled differently or labels swapped.

## Acceptance evidence

| Case | Studies | Study casts before → after |
| --- | --- | --- |
| Reddit 10u5ao8, 10 Draconium R2 batches, 2,000 casts each | 10 of 10 count | `188658 → 192870`: 22,030 → 20,030; `→ 192871`: 22,000 → 20,000 |
| Bugy Serevite ore-1 and ore-2, 400 casts each | both count | `family:Serevite Ore → 192872`: 400 → 800; `→ 192880`: 400 → 800 |
| Bugy Draconium ore-1 and ore-2 | both count | `family:Draconium Ore → 192872`: 400 → 800 |
| Bugy Khaz'gorite ore-1 and ore-2 | both count | `family:Khaz'gorite Ore → 192872`: 20 → 40 |
| `war-within-20261031-823001..007` = `…701..707` | all 7 pairs share one identity | no casts stated, so no change |
| `midnight-20261031-13001` = `master-20261030-001` | share one identity | unchanged |
| zkay8v `dragonflight-20261031-50001..025` | excluded by correction; rule covered by fixture test | unchanged |

The Reddit total falls because the old 22,000 was one batch plus the pool. 20,000 is the true figure; the 30
in `192870` is a separate Neoslayyer cohort.

## Estimate changes

- **35 rows removed:** all `family:` duplicates of a study whose ID-level rows remain: Midnight jd3k ores
  (17), Superbondez Prismatic (10), R3 Serevite (7), Titanium (1). 57,106 material-level casts of double
  counting gone.
- **52 rows gained casts** (+29,056), **2 lost casts** (-4,000, the pool), 25 changed `studies` or derived
  fields only.
- **Chance:** largest move 0.0989. 2 rows moved 5+ points, 15 moved 2+, 24 moved 1+.

| Row | Chance | Study casts | Cause |
| --- | --- | --- | --- |
| Prospect 190311 → 192872 | 0.3114 → 0.4103 | 1,000 → 3,000 | df-beta carl, larry and sharon now all count |
| Prospect family:Draconium Ore → 192880 | 0.8917 → 0.9483 | 400 → 800 | Bugy ore-2 restored |
| Prospect family:Draconium Ore → 192872 | 0.8967 → 0.85 | 400 → 800 | same |
| Prospect family:Serevite Ore → family:Eternity Amber | 0.4425 → 0.3987 | 400 → 800 | Bugy ore-2 restored |
| Prospect family:Serevite Ore → family:Nozdorite | 0.145 → 0.185 | 400 → 800 | same |
| Prospect family:Khaz'gorite Ore → family:Neltharite | 0.02 → 0.055 | 20 → 40 | same (small cohorts) |

Confidence values in the diff came from the normal-approximation fallback in `confidence()`, because SciPy
was not available on the machine that ran this session. Chance, average and study casts do not depend on it.

## Partial copies (23)

Counted once; review welcome. `relabeled` = same size, labels differ.

| Kind | Copy | Original |
| --- | --- | --- |
| subset | reddit-10me1e7-hochenblume-r1-1500 | reddit-10me1e7-hochenblume |
| subset | reddit-10me1e7-hochenblume-r2-9000 | reddit-10me1e7-hochenblume |
| subset | wowhead-aary-saxifrage-r2-100 | wowhead-198418-Aary-saxifrage |
| subset | df-b008-sax-r2-100-units-ambiguous | wowhead-198418-Aary-saxifrage |
| relabeled | df-r3-serevite-8000-casts-2023-source-recheck-20261028 | reddit-108782r-comment-8000-casts-r3-serevite-full-output |
| relabeled | ww-b006-2023-q3-8000 | reddit-108782r-comment-8000-casts-r3-serevite-full-output |
| subset | midnight-b010-df-superbondez-prismatic-80casts | wowhead-superbondez-prismatic-ore-400 |
| relabeled | df-b008-fish-3-casts-wowhead-comment-primer | wowhead-primer-prismatic-leaper-15-fish |
| subset | 2026-10-28-0630-dragonflight-batch006-1000cast | df-r2-serevite-1000-casts-2022-source-recheck-20261028 |
| relabeled | ww-b006-2022-q3-20000 | df-r3-serevite-20k-ore-source-audit-20261028 |
| subset | felslate-3200ore-massprospect-legion-wowhead-comment | legacy-q16-deckven-3200-felslate |
| subset | legacy-q18-b016-almar-titanium-original-undated | almarsguides-titanium-prospecting-video-raw-output |
| subset | midnight-20261028-jd3k-237365-source-rechecked | wowhead-jd3k-midnight-q2-50-each |
| subset | midnight-copper-r2-50ore-comment-aggregate-001 | wowhead-jd3k-midnight-q2-50-each |
| subset | wowhead-1231127-jd3k-brilliant-silver-q2 | wowhead-jd3k-midnight-q2-50-each |
| subset | wowhead-1231127-jd3k-refulgent-copper-q2 | wowhead-jd3k-midnight-q2-50-each |
| subset | midnight-20261028-jd3k-237363-source-rechecked | wowhead-jd3k-midnight-q2-50-each |
| subset | wowhead-1231127-jd3k-umbral-tin-q2 | wowhead-jd3k-midnight-q2-50-each |
| subset | tww-2026-10-28-reddit-aqirite-r1-oct14 | reddit-1g350pq-aqirite-r1 |
| subset | tww-2026-10-28-reddit-aqirite-r2-oct14 | reddit-1g350pq-aqirite-r2 |
| relabeled | wowhead-wotlk-titanium-407900-ptr-680ore | wowhead-407900-titanium-680-ptr |
| subset | blizzard-2281743-joe-copper-20260328 | blizzard-forum-2281743-joe-copper-20260328 |
| subset | wowhead-radiant-ruby-raven11-r1-ironclaw (5 rows, other file) | wowhead-radiant-ruby-raven11-r1-ironclaw (6 rows) |

### Label conflicts (3 groups, not changed by M05)

R3 Serevite (input 190394): the copies agree on the numbers but not on which gem each belongs to. The
estimator keeps the first row in file order, as it did before M05, so these estimates did not change.

| Output ID | Counted now | Conflicting value |
| --- | --- | --- |
| 192842 | ww-b006: 455 (2022), 909 (2023), no names | df-r3: Mystic Sapphire 424, 906 |
| 192848 | ww-b006: 424 (2022), 906 (2023), no names | df-r3: Sundered Onyx 455, 909 |
| 192865 | dragonflight-20261031-13010 "Neltharite" 445 (2023); ww-b006 220 (2022) | df-r3: Ysemerald 471, 220 |

The ww-b006 records carry no names, and two named records disagree with them. Someone needs to read the
source; no network was used here.

## Not merged, for review

- **Single-row subsets (below the 2 non-zero bar, so counted separately):** the Diffracted Silver forum row
  (three records, Eversong Diamond 0 of 43), `reddit-1fdmzwy-mycobloom-r1/r2`,
  `reddit-1g9s48p-comment-r1-bismuth-400-20241022`, `wowhead-neoslayyer-draconium-r2-150`, the
  `…lavingrunatic…QUALITY-UNMAPPED-CORRECTED` row, `wowhead-aary-saxifrage-r3-100` and
  `df-b008-sax-r3-100-units-ambiguous`. Most look like real copies. The rule cannot tell them from chance,
  which is why the prompt set the bar at 2. S17's `midnight-20261031-9001`/`master-20261030-005` is in this
  list because its study is split across two files; that input/output pair yields no estimate before or
  after M05, so it changes nothing today.
- **Same numbers under different sources (9 pairs):** e.g. `wowhead:item=52988` vs `…@cata`, `spell=31252@cn`
  vs `@ru`, `item=23424@tbc` vs `@wotlk`. One study on regional or flavour pages of Wowhead. They stay
  double-counted, as before M05, until `originalSource` links them.
- **Near copies (8 pairs):** 2 shared non-zero rows out of many, or numbered batches. Read and judged
  independent.
- **`reddit-10u5ao8-draconium-r2-batch-1..10`:** a copy of the ten batches with `casts: null`. They add no casts
  but raise the `studies` field by 10 in the two diamond rows.

## Proposal for the Master

Claude and the Master own `strategy.md`, so this is a proposal only.

1. **S7:** implemented as above. Please confirm the numbered-batch and pooled-study rules; they are new.
2. **S17:** the worker rule still matters: the estimator now absorbs re-recorded studies, but only when
   numbers match. The proposed `roles/worker.md` line ("search evidence for the URL first") stands.
3. **Corrections to consider** (not made here; `corrections.jsonl` was out of scope):
   - exclude the single-row copies above once judged;
   - set `originalSource` on the 9 cross-source pairs;
   - resolve the R3 Serevite labels after reading Reddit `zh53dd` and `108782r`.
4. **M03 warning:** a `cohortKey` beats the fingerprint, so a study with a key never merges with an unkeyed
   copy. If importers start setting `cohortKey`, unkeyed agent copies of those studies will double-count.
   Either set keys on both sides or have M03 keep fingerprints until M10.
5. **Plan correction:** the headline defect was smaller than logged (see above): 29,056 independent casts
   restored and 61,106 double-counted casts removed (57,106 family rows + 4,000 pool).
