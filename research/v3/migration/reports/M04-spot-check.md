# M04.4: spot-check of the extracted rows, the nulls and the weak links (MIG-007)

Everything below was re-read against the source text in the repository after the extraction, by hand, not by the validator
that accepted the rows. Sampling is deterministic so the draw can be repeated: sort the candidates, take the items at positions
`int((i + 0.5) * n / k)` for `i` in `0..k-1`, with `k = ceil(10% of n)`.

| Sample | Population | Drawn | Result |
| --- | --- | --- | --- |
| Extracted rows | 12 rows, 9 sources | **all 12** (10% would be 2; the population is small enough to check whole) | 12 correct |
| Null checkpoints | 46 | 5 (positions 4, 13, 23, 32, 41 in source-key order) | 5 confirmed null |
| Weak links in `links.jsonl` | 75 before extraction, 76 after | 8 + 2 (the redraw on 76 moved two positions) = **10 distinct** | 8 true, 1 right source with a coincidental number, 1 false link |

## 1. Extracted rows (12 of 12 checked)

Each row's source line was reopened, the quote and every number compared by eye, and the interpretation checked
(method, input, output, what is a count).

| Row | Source line | Verdict |
| --- | --- | --- |
| `import-extract-reddit-nohny2-64012f-01..03` | `...batch013-nightshade-source-only.md` line 2: "3000 Nightshade `171315` into 781 Umbral Pigment `173056`, 712 Luminous `173057`, 884 Tranquil `175788`", dated 2021-05-30. Also in the queue's batch013 report line 18 | **Correct.** IDs, totals, date and `casts` null agree with the note's "completed operations UNKNOWN". The note's per-five figures (1.3017, 1.1867, 1.4733) equal each total / (3000 / 5), a cross-check of the totals |
| `import-extract-wowhead-item-129034-b3b471-01` | `...batch012-original-source-only.md` line 16: "40 Felwort, 17 Roseate, 89 Sallow, no exact actual cast log"; batch012 report line 47 agrees on 89 | **Correct.** Output ID 129034 comes from the item link whose slug is `sallow-pigment`; Felwort has no ID in the text, so the row is unplaced, as intended |
| `...-129034-b3b471-02` | same line | **Correct.** Roseate 17 has no ID; unplaced |
| `import-extract-wowhead-spell-190381-...-01` | q18 batch016 report line 11: "Mass Mill Frostweed ... uses **20 herbs**" | **Correct** |
| `...-spell-256218-...-01`, `-256221-`, `-256223-` | q19 batch017 report line 12: the three recipe links "independently document 20-herb reagent units"; the same line says the cohort was "actual mass milling operations, each consuming 20 herbs" | **Correct.** Method Mill comes from "mass milling"; input names from the link text (Star Moss, Siren's Pollen, Sea Stalk) |
| `...-spell-311413-...-01` | midnight batch009 report line 18: "six mass-mill recipes ... consume **20 herbs per operation**; specific recipe IDs ... 311413 Death Blossom" | **Correct** for 311413 only; the other five IDs on the line are not this source and were not written |
| `...-spell-359490-...-01` | batch003 report line 25: "First Flower 187699" and "Mass Mill First Flower recipe ... uses 20 herbs" | **Correct.** The ID is paired with the name in the same line |
| `...-spell-444181-...-01` | mycobloom source-only note line 18: "Khaz Algar Milling spell **444181** ... specifies **10 herbs** per operation" | **Correct** |

No error found. One thing to note rather than fix: the Nightshade and Felwort rows record `inputsProcessed` without a cast count,
so their weight in the estimator comes from the M06 inputs-only rule (see `M04-extraction.md`).

## 2. Null checkpoints (5 of 46 re-read)

The risk with null-on-doubt is a missed cohort, so these were reopened and every number near the citation was attributed.

| Source | Re-read | Verdict |
| --- | --- | --- |
| `drive.google.com/file/d/1nM7...` (`reference-table`) | Q25 batch023 formula audit lines 5 to 16: cells F41 = 1.13, G41 = 0.38, H44 = 0.24 are model coefficients; the note says no cast denominator or histogram is attached | Null confirmed |
| `reddit:1l91chl` (`no-observational-numbers`) | Line 17: about 42,000g of ore for under 32,000g of materials, no ore count or output ledger; the note says not to import its ROI | Null confirmed |
| `repos.wowace.com/.../millingdata.lua` (`reference-table`) | Batch004 report line 6: "authored data-table assumptions, not measured per-cast evidence"; the cast histograms at lines 18 to 21 belong to Wowhead commenter 180977 | Null confirmed |
| `wowhead:guide=professions` (`identity-link-only`) | Q22 batch020 lines 8 and 9: guides corroborate the Bubble Poppy and Writhebark identities and "5 herbs per mill"; no spell, no result | Null confirmed |
| `wowhead:item=52984@cata` (`ambiguous-doubt`) | Batch009 verdict line 8: 21 stacks and 96 mills, 202 Ashen and 20 Burning; 202/84 and 20/84 match the author's own averages, 96 does not | Null confirmed, and **the best candidate for a row** if the Master accepts 21 stacks of 20 herbs as 84 derived casts (the same comment appears at `@tw`) |

Also reopened, outside the sample: the source-only notes that cite null sources but sit outside the queue (`r80lkp` Progenium,
`10k8158`, `1k78h4v`, `1s3hnzo`/`1szcgff`, `222618`). All agree with the nulls; the Progenium note says outright not to assign
0.007 to the output records.

## 3. Weak links (10 distinct of 75/76)

A weak link is one small-integer result match (PLAN section 3 rule 6). Each was checked for two things: is the *source* really the
one v3 holds, and is the matched number really that source's result?

| Citation (file, line) | Matched | v3 rows | Verdict |
| --- | --- | --- | --- |
| wow-professions midnight JC guide (`master-worker-batch020-verdict.md` 16) | 12 | reference rows `percentShown` 12 (the guide table) | **False link.** The 12 in the text is JD3K's "Glass 7/8/12", another source. The guide is held, but the citation carries no count of its own, so the right status is `source-held` |
| wowhead spell 225904 (`legacy-batch008-report.md` 29) | 20 | the 113-mass-cast cohort (`import-study-01034`) | **Right source, coincidental number.** The 113 casts in the text equal the held `casts`; the matched 20 is the 20-ore mass recipe |
| wowhead item 774 (`legacy-q23-batch021-report.md` 11) | 12 | WokkaD copper 16 prospects (`import-study-00460`), 12 Tigerseye | True |
| wowhead item 1210 (same line, other citation) | 20 | Nakthar copper 200 ore (`import-study-00462/3`: casts 40, total 20, inputs 200) | True |
| wowhead spell 1307466 (`midnight-batch012-report.md` 17) | 18 | recipe record, 18 stones to 1 | True (a recipe fact) |
| wowhead spell 1307466 (`midnight-batch013-source-reconciliation.md` 9) | 18 | same recipe record | True |
| Blizzard forum 616811 (`batch004-0413-report.md` 21) | 10 | `import-study-00713`: 1,000 ore, 200 casts, 10 diamonds | True; the line states "1,000 copper ore / 200 prospects, 10 diamonds" |
| reddit 1sfds1u (`batch002-report.md` 33) | 20 | `import-study-00579`: 200 casts | True (about 20% over 200 crafts) |
| wowhead spell 434018 (`tww-batch001-report.md` 14) | 20 | PeaEsk 100-ore cohorts (casts 20, inputs 100) | True; the match is the five-ore-equivalent denominator |
| reddit zh53dd (`...F004-df-r3-ore-591-diamond-cohort.json`, `$.otherPrimaryContext`) | 29 | `import-study-00038`: 20,000 ore, 29 diamonds | True, and strong in substance (20,000 also matches) |

**Reading.** 8 of 10 are true links, 1 is the right source with a spurious number, 1 is false. Neither miss changes a count or
creates a duplicate: both sit on held sources, where the only effect is `linked` instead of `source-held`. Across all 75 weak
links (measured), 40 have a matched denominator as well, and 18 match only reference or recipe rows with no study row; that second
group is where the false link above comes from, and is the cheap place to look if M07 wants to tighten the rule.

## Findings from the spot-check that changed the work

1. Two sources had a sibling archive note outside the queue with richer text (item IDs, date, the second Felwort output); they
   were added through `EXTRA_FILES` (see `M04-extraction.md`). This turned the Nightshade rows from unplaced to placed.
2. The language-variant rule (`@fr` is the same Wowhead page as the English URL) stopped a double count of the 113-cast Felslate
   comment that v3 already holds.
3. A checkpoint for a source that v3 later holds had been revalidated as "invalid"; it is now reported as `held` (this is the case
   M10 will hit when agents record these pages). Found by `test_held_source_writes_nothing_and_is_reported`.
