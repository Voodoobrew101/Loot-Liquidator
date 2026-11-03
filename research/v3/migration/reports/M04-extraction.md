# M04.3: batched extraction of the residual queue (MIG-007)

Tool: `tools/extract_batch.py` (prompt builder, answer validator, per-source checkpoints, deterministic writer; no network, no
model API). Tests: `tests/test_extract_batch.py` (69) and one new linker test. Outputs: `manifest/extraction/*.json` (55 checkpoints),
`research/v3/evidence/imported/extracted-historical-sources.jsonl` (12 rows), `reports/M04-extraction-data.json`,
`reports/M04-estimates-diff.md`. All numbers were measured by running the tools on branch `migration/v3-historical-research`.

## How it works

There is no model API in the migration workspace, so the tool does everything around the reading and the reader (here, Claude
in the session) answers in a fixed JSON shape. `prompt <source>` prints the source's files as numbered lines (`>>` counts found
by the linker, `@@` lines that name the source), the rules and the target schema. `submit <answer.json>` validates the answer and
writes `manifest/extraction/<slug>.json`; a rejected answer writes nothing. `write` turns the checkpoints into evidence rows.

What the validator enforces (an answer failing any check is rejected whole, and the tests cover each rejection):

- **Quoting.** Every evidence span is a verbatim substring (whitespace and quote marks normalised) of the named line of a file in
  the queue entry, and the file still has the sha256 the queue recorded. The line must sit under the source's own URL (the
  linker's "nearest URL above it in the paragraph" rule), or the answer quotes a line naming the source (`linkEvidence`).
- **Numbers.** Every number in a record (counts, totals, percentages, averages, item and spell IDs, ranks, dates) is written in
  the evidence or computed by a `derivations` formula over numbers in the evidence and other fields. The validator evaluates the
  formula (`+ - * /` and `round()` only) and compares. Dates must be written in the evidence.
- **Arithmetic.** hits <= casts; percent vs hits/casts (0.51 point tolerance); average vs total/denominator; total <= casts x max
  and >= hits x min; every hit gives at least one; histogram counts, amounts and zero bucket; casts = inputs / batch for
  `countedFromInputs`; casts x batch <= inputs; declared sums over rank rows; one study = one set of casts and inputs, one row
  per material.
- **Schema.** The finished record passes `validate.check_record` with no finding at all (errors or warnings).
- **Names.** An item name travels with an item ID only. A name without an ID in the text goes to `rawInputName` / `rawOutputName`,
  the row is stored unplaced, and nothing is placed by name (the open Master decision on name-only placement is untouched).
- **Holdings (PLAN section 3 rule 5).** A `rows` answer for a source v3 holds is refused at submit time, and the writer skips it
  and reports it if agents catch up later. A translated copy of a Wowhead page (`@es`, `@fr`, ...) counts as the same page.
- **Proposals.** `condition` and `rateChange` readings are kept in the checkpoint and never written to evidence: the estimator
  reads `condition` records straight from evidence, and `conditions.jsonl` and `rate-changes.jsonl` are the Master's. None
  was proposed in this run.

Checkpoints are self-contained: each stores the queue entry it was extracted from, so they stay valid after `link_sources.py`
drops an extracted source from the live queue (its rows make it held). The writer iterates checkpoints, not the live queue; the
test `test_rows_survive_the_source_leaving_the_live_queue` pins that. IDs are `import-extract-<source slug>-<hash>-<n>`, so
adding or removing another source never moves them. Reruns are byte-identical.

## Result: 55 of 55 sources have a checkpoint

| | Count |
| --- | --- |
| Queue sources | 55 (23 Wowhead entity pages, 14 Reddit, 3 Blizzard forum, 15 other) |
| Checkpoint with rows | **9 sources, 12 rows** (5 drop rows, 7 recipe rows) |
| Checkpoint null, with a reason | **46** |
| Null reason codes | ambiguous-doubt 12, qualitative 9, reference-table 8, numbers-not-this-source 8, identity-link-only 4, needs-original-post 2, held-elsewhere 2, no-observational-numbers 1 |
| Answers the validator rejected during the run | 1 (a rows answer for `wowhead:spell=225904@fr`: v3 holds that page under the English URL, `import-study-01027`) |

The pilot was six sources chosen to mix types: a Blizzard forum thread (`blizzforum:1480672`), two Reddit posts (`reddit:nohny2`,
a file-level piece `reddit:k1zd4o`), a wow-professions table (`wow-professions.com/mop/...`), a Wowhead spell page
(`wowhead:spell=190381`) and a Wowhead comment (`wowhead:item=129034`). Every pilot row was read against its source line before
the other 49 were run.

### The 12 rows

| Source | Rows | What |
| --- | --- | --- |
| `reddit:nohny2` | 3 drop | 3,000 Nightshade (171315) milled into 781 Umbral (173056), 712 Luminous (173057), 884 Tranquil (175788), posted 2021-05-30. `casts` null (recipe size unknown); `inputsProcessed` 3000. **Placed** |
| `wowhead:item=129034` | 2 drop | Felwort beta report: 40 Felwort gave 89 Sallow Pigment (129034) and 17 Roseate. Felwort has no item ID in the text, so both rows are unplaced |
| `wowhead:spell=190381`, `256218`, `256221`, `256223`, `311413`, `359490`, `444181` | 7 recipe | 20 herbs per mass mill (five spells) and 10 herbs for Khaz Algar Milling, each quoted next to its spell link. No estimator effect |

### The 46 nulls

| # | Source | Result | Code | Reason (short) |
| --- | --- | --- | --- | --- |
| 1 | `blizzforum:1440624` | null | ambiguous-doubt | Two single-event bug reports (a rare Wind Generating Band giving Sacred Shard and two Soul Dust, repeated by a second player) about Shadowlands materi |
| 2 | `blizzforum:1463991` | null | ambiguous-doubt | One bug report of a Dragonflight rare staff giving two Large Brilliant Shards, a Classic reagent, with no input item ID or build. A single reported ma |
| 3 | `blizzforum:1480672` | null | qualitative | The thread is cited for a 2023 bug report (Prismatic Ore greyed out because the user had fewer than five ore). It states no outputs. The 400-ore / 80- |
| 4 | `buffed.de/world-of-warcraft-spiel-42971/news/wow-midnight-hotfixes-1524190` | null | numbers-not-this-source | The German hotfix article is only listed as a link (line 17). The cohort counts in the file (1,000 and 5,000 Titanium Ore, six gem totals each) belong |
| 5 | `drive.google.com/file/d/1nm7sjgugycz7kel72xm7vorkh_gnrrll` | null | reference-table | The workbook is cited for a formula audit. The quoted cells (F41=1.13, G41=0.38, H44=0.24) are the author's model coefficients, which the note says ha |
| 6 | `dving.net/guides/wow-midnight-jewelcrafting-guide` | null | qualitative | A secondary guide cited for two reagent ranks and specialisation-gated Diamond eligibility. The note calls it context, not a measured cohort; the coun |
| 7 | `gdoc:1Kx2qPiGXGqS5_zla1sSN69yxrYlGdEVTzR4bypP8yJU` | null | reference-table | The Milling herbs BFA sheet shows calculator defaults (1000 herbs, 310 Crimson, 130 Viridescent) that the note labels estimated quantities, not measur |
| 8 | `goldgoblin.net/berufe/verzauberkunst/verzauberkunst-von-khaz-algar` | null | qualitative | Cited as a qualitative support for rarity-to-material families in disenchanting. The sample claims (12, 4, 3, 3, 1, 1) are GameData profile counts, no |
| 9 | `gunnydelight.github.io/mozzletoff-wow-goldfarm-site/bfa-inscription-milling-shuffle.html` | null | reference-table | The page is the discovery link for the same Milling herbs BFA calculator sheet; its 1000 herbs / 310 / 130 figures are labelled estimates and calculat |
| 10 | `reddit:10k8158` | null | qualitative | A 2023 anecdote recalling ('IIRC') that skill 250 guarantees rank-3 pigment. No cast, count or output total; the note says it is not a completed-cast  |
| 11 | `reddit:1foca2r` | null | reference-table | A crafting spreadsheet post. The numbers in the note are the sheet's formula cells and talent coefficients (Shuffles!F41=1.13, H44=0.24 and so on), wh |
| 12 | `reddit:1g6jcfr` | null | reference-table | A 2024 milling calculator post, called a model lead by both notes: no cast histogram and no exact output totals. The 11 to 17 and 9 to 13 pigment rang |
| 13 | `reddit:1k78h4v` | null | qualitative | Reports that R2 gems are about 8 percent more valuable than R1, with no sample denominator or price snapshot. A value claim, no counts of outputs; the |
| 14 | `reddit:1l91chl` | null | no-observational-numbers | Reports a gold profitability result (about 42,000g input, under 32,000g returned) with no ore count, no output ledger and no casts; the note says not  |
| 15 | `reddit:1s3hnzo` | null | qualitative | A March 2026 discussion that reports rank-2 glass from skilled rank-2 ore in words. The note says it establishes no ore ID, probability or count. |
| 16 | `reddit:1szcgff` | null | qualitative | An April 2026 discussion that reports rank-2 stone and glass in words, with no ore ID, count or probability. |
| 17 | `reddit:1ub8pxv` | null | ambiguous-doubt | A commenter reports 35 to 40 dust after 1,000 ore. The result is a range of totals, the method is crushing rather than one of the four methods, and th |
| 18 | `reddit:1wwd0w0` | null | qualitative | Two player comments about profitability (losses with max talents; rank-one profitable, rank-two intermittent). The note says no cast denominator or it |
| 19 | `reddit:k1zd4o` | null | numbers-not-this-source | The post is named only as a TSM-string repost derived from the 2020 original, which both notes suppressed as a duplicate. Every count in these files b |
| 20 | `reddit:k6d0qk` | null | needs-original-post | A commenter references a chart from 3,300 Laestrite mass prospects, but the chart's outputs are not in the files and the note records it as NEEDS_RECH |
| 21 | `reddit:nohny2` | **3 rows** | - | 3 drop: Taken from the source-only archive note, which gives the item IDs and the post date; the batch013 report in th |
| 22 | `reddit:r80lkp` | null | ambiguous-doubt | The note gives 10,000 ore and about 0.7% 'per essence' for Progenium PTR and 3.5% against a reported 2.7% for Elethium. The output is not named (which |
| 23 | `reddit:xsjvq1` | null | numbers-not-this-source | The thread is cited as a TSM user discussion of whether amountOfMats is per herb. The Peacebloom, Mageroyal and Earthroot cast histograms in the same  |
| 24 | `repos.curseforge.com/wow/prospect-me/comparison/f9b6c0305908/modules/prospectme_tables.lua` | null | numbers-not-this-source | The Prospect Me table is named only as identity corroboration for the milling table. The counts in the file (2,000 herbs of each of six species; 1,000 |
| 25 | `repos.wowace.com/wow/reagentmaker/file/c6041a8cb7b8/millingdata.lua` | null | reference-table | A 2015 ReagentMaker data file whose values the note calls authored data-table assumptions, not measured evidence; the file's numbers are not quoted. T |
| 26 | `svetwarcraftu.cz/blue-posty/world-of-warcraft-midnight-hotfixes-27-october` | null | numbers-not-this-source | The October 27 hotfix page is cited because it gives no applicable numeric prospecting rate. The counts in the file (10,000 R2 Aqirite, 800 Silver cas |
| 27 | `svetwarcraftu.cz/profese/jewelcrafting/retail` | null | ambiguous-doubt | The Czech guide says crushing three identical gems gives one to three Glimmering Gemdust. That is a family-level range from a secondary guide, for a c |
| 28 | `thelazygoldmaker.com/felslate-prospecting-analysis` | null | numbers-not-this-source | Cited as derivative context for the Felslate and Leystone comparison. The counts in the file (143 powder from 1,000 ore, 177 casts) belong to a Wowhea |
| 29 | `thelazygoldmaker.com/understanding-crafting-stats-in-the-war-within-is-crucial-to-make-gold` | null | qualitative | Describes a general 30 percent reagent-return heuristic, which the note calls a secondary explanation and not a measured distribution. The counts near |
| 30 | `wow-professions.com/cataclysm/disenchanting-table-cataclysm-classic` | null | numbers-not-this-source | The guide is cited for its item-level brackets. The 288-cast counts (217 casts giving 554 essences, 71 giving 234 dust) belong to the original Wowhead |
| 31 | `wow-professions.com/cataclysm/prospecting-table-cataclysm-classic` | null | ambiguous-doubt | The review note says the guide gives six Pyrite common gem chances of 17% each, but does not name the gems or ranks, and the table itself is not in th |
| 32 | `wow-professions.com/mop/prospecting-table-mop-classic` | null | ambiguous-doubt | The review note gives 'common 24%, rare 5%, Trillium 17%' for the guide, but not which items or ranks each figure covers, and the guide's table is not |
| 33 | `wowhead:guide=mists-of-pandaria-jewelcrafting-overview-1638` | null | reference-table | The CSV is a first-pass audit ledger of TSM rows; the guide is cited beside a 'historical player-reported approximate 17%' that the ledger itself labe |
| 34 | `wowhead:guide=professions` | null | identity-link-only | The guide link supports Bubble Poppy and Writhebark to pigment identity and '5 herbs per mill'. It names no recipe spell and no result, so there is no |
| 35 | `wowhead:item=123919` | null | ambiguous-doubt | A 2017 comment on the Felslate page 'mixes 880 Leystone and 240 Felslate' in one report, so the gem yields cannot be tied to Felslate alone. The 10,00 |
| 36 | `wowhead:item=129034` | **2 rows** | - | 2 drop: Taken from the source-only note (outside the queue), which lists both outputs of the Felwort beta report; the  |
| 37 | `wowhead:item=153706` | null | numbers-not-this-source | The Kraken's Eye page is cited only for Tontons' later rate increase, a qualitative statement. The 1,610 ore / 322 casts and 2,775 ore / 555 casts coh |
| 38 | `wowhead:item=222618` | null | ambiguous-doubt | LotzBoi's comment gives 4 to 6, 5 to 7 and 6 to 8 pigments per ten-herb mill as illustrative skill examples. The notes call them unreplicated player c |
| 39 | `wowhead:item=224802` | null | ambiguous-doubt | The same LotzBoi comment replicated on the Orbinid page: illustrative bands of 4 to 6, 5 to 7 and 6 to 8 pigments with no cohort, no cast count. Null  |
| 40 | `wowhead:item=36721` | null | identity-link-only | Cited to show that item 36721 is a thrown weapon and not a herb; an identity correction with no outputs. |
| 41 | `wowhead:item=3819` | null | identity-link-only | Cited to identify Dragon's Teeth (3819) as the millable herb; an identity link with no outputs. |
| 42 | `wowhead:item=43105` | null | identity-link-only | Cited as an Indigo Pigment herb association for item 3819; an identity link with no outputs. |
| 43 | `wowhead:item=46849@wotlk` | null | needs-original-post | The ZeRoTaCtIcS comment reports 66 stacks of ore and about 264 prospects 'and exact aggregate gem counts', but the gem counts are not in the files. Th |
| 44 | `wowhead:item=52984@cata` | null | ambiguous-doubt | Stormvine comment: 21 stacks and 96 mills, 202 Ashen and 20 Burning. The master verdict marks the denominator contradictory (21 stacks imply 84 operat |
| 45 | `wowhead:item=52984@tw` | null | ambiguous-doubt | The same Stormvine comment as the cata page: 21 stacks and 96 mills, the batch note flags DENOMINATOR_CONTRADICTION. Null on doubt. |
| 46 | `wowhead:item=72103` | null | reference-table | Same TSM audit ledger as the Pandaria guide entry: the 17% is an unmeasured historical proxy beside TSM rows, not a count from this page. |
| 47 | `wowhead:news=crafting-work-orders-are-here-wowhead-economy-weekly-wrap-up-251-329620@es` | null | held-elsewhere | The Spanish copy of the Wowhead article reproducing the Liqourice5 beta milling study (2 to 5 pigments per mill, 2,000 herbs / 400 actions) is held by |
| 48 | `wowhead:spell=190381` | **1 row** | - | 1 recipe: Recipe fact only: the note's other figures are the 516803 comment's herb totals, which are a different source. |
| 49 | `wowhead:spell=225904@fr` | null | held-elsewhere | The French copy of Mass Prospect Felslate (spell 225904) is the same Wowhead page v3 already holds under the English URL (old-studies import-study-010 |
| 50 | `wowhead:spell=256218` | **1 row** | - | 1 recipe: Recipe fact only. The 177, 106 and 103 mass-cast counts in the same line belong to Jiyao's comment on item 153 |
| 51 | `wowhead:spell=256221` | **1 row** | - | 1 recipe: Recipe fact only. The 177, 106 and 103 mass-cast counts in the same line belong to Jiyao's comment on item 153 |
| 52 | `wowhead:spell=256223` | **1 row** | - | 1 recipe: Recipe fact only. The 177, 106 and 103 mass-cast counts in the same line belong to Jiyao's comment on item 153 |
| 53 | `wowhead:spell=311413` | **1 row** | - | 1 recipe: Recipe fact only, for spell 311413. The other five recipe IDs named on the line are not this source. |
| 54 | `wowhead:spell=359490` | **1 row** | - | 1 recipe: Recipe fact only. The 4,000-herb cohort in the same line is reddit t8lubc, a different source. |
| 55 | `wowhead:spell=444181` | **1 row** | - | 1 recipe: Recipe fact only; the note says it is not a yield distribution. |

(`ambiguous-doubt` is the large honest bucket: single bug-report events, approximate rates for an unnamed output, ranges, and the
Stormvine comment whose own denominators contradict. Each is listed in the spot-check report as a candidate for the Master.)

## Two scope findings

1. **The residual queue missed archive notes.** M01 classed some `source-links-only` notes as holding no numbers, so M04.1 never
   queued them. The linker's observational-count pattern needs a unit word after the number: "3000 Nightshade" and "781 Umbral
   Pigment" do not match, so a citation with real counts reads as `lead-only`. Two extracted sources had such a sibling note
   (`...batch013-nightshade-source-only.md` with the item IDs and the post date; `...batch012-original-source-only.md` with the
   second Felwort output). They are added through `EXTRA_FILES` in `extract_batch.py`, with the reason beside them; deleting an
   entry and resubmitting returns a source to the queue's files only. I read the other source-only notes that cite null sources
   (`r80lkp` Progenium, `10k8158`, `1k78h4v`, `1s3hnzo` and `1szcgff`, `222618`): they agree with the nulls. Across the 55 sources
   there are 114 file mentions outside the queue entries, mostly source-review JSONL, audit CSVs and `source-memory.json`. Other
   unheld sources with counts sit in out-of-scope files; a scan of citations with a number of 20 or more in files marked
   `source-links-only` or `no-observational-content` found 23 distinct unheld source keys: 10 of the ones I could name are
   queue sources already, most of the rest are guide URLs inside audit-CSV rows, and three are worth a look
   (`blizzforum:2277117`, `reddit:1s1dtuh`, the `gdoc:1jBMg...` workbook; their notes call them leads). M07 should decide whether
   to widen the linker's count pattern.
2. **Recipe-only holdings.** Once a recipe row held a Wowhead spell page, `link_sources.py` turned 7 files from residue to
   *exception* because other sources' counts share the citation line (for example Jiyao's 177 / 106 / 103 mass casts beside the
   spell links). A source held only by `recipe` records now classifies as `source-held` ("no cohort to be compared with").
   PLAN section 3 rule 6 is amended; one linker test added.

## Counts before and after

| | Before (MIG-006) | After (MIG-007) |
| --- | --- | --- |
| Effective evidence records | 4,933 | **4,945** (+12 imported rows) |
| Evidence files | 137 | 138 |
| Residual queue | 55 sources, 49 files, 138 anchors | 46 sources (the nulls), 42 files, 122 anchors |
| In-scope files (265) | linked 133, exception 44, residue 49, disposed 39 | linked **140**, exception 44, residue **42**, disposed 39 |
| Citation groups | linked 266, exception 91, source-held 340, residue 70 | linked 269, exception 83, source-held 375, residue 57 |
| Link strength | strong 191, weak 75 | strong 193, weak 76 (the new weak one is the Felwort report line linking to the row extracted from it) |
| Registry URLs held by a record's source | 162 | 171 |
| Estimates | 1,205 (447 unplaced) | 1,205 (**449** unplaced) |
| Study audit | 473 studies, 40 clean | 475 studies, 40 clean |
| Validator | 5 errors, 175 warnings | 5 errors, 175 warnings (no finding on any extracted row) |
| Corrections | 643 lines, 333 records | 643 lines, 333 records |
| Tests | 197 | **267** |

## Estimate changes (`M04-estimates-diff.md`)

0 added, 0 removed, **3 changed**; largest chance move 0.0020. All three are the Nightshade group (Mill 171315):

| Output | Chance | Average | Confidence | Study casts |
| --- | --- | --- | --- | --- |
| Umbral 173056 | 0.6549 -> 0.6529 | 1.3098 -> 1.3057 | 46 -> 49 | 576 -> 1,176 |
| Luminous 173057 | 0.59 -> 0.5917 | 1.1801 -> 1.1834 | 46 -> 49 | 576 -> 1,176 |
| Tranquil 175788 | 1.0 -> 0.998 | 1.5207 -> 1.4969 | 50 -> 50 | 576 -> 1,176 |

The new cohort has `inputsProcessed` 3000 and no cast count, so M06 counts 3000 / 5 = 600 five-herb casts (study casts 576 to
1,176): full weight in the average, 0.5 in the chance. The averages move by 0.3% to 1.6% and the chance by at most 0.002. If the
Nightshade recipe was the 20-herb mass mill (the note says unknown), the five-herb unit would overstate its casts; that is the
M06 rule for any inputs-only total, not something this task decided.
Nothing else changed: the other 11 rows are unplaced (an input without an ID in the text) or recipe records.
`estimates.json` sha256 `d959496a...` (SciPy), `summary.md` `fbf8e3b2...`. Two rebuilds were byte-identical.

## For the Master (proposals only)

1. **Wowhead entity pages: skipped or not?** Your M04.1 question. Result: 15 of the 23 pages are null as expected; 7 yielded a
   *recipe* fact (a batch size beside the spell link), which is a recipe row and not a drop row, and 1 yielded a cohort
   (item 129034). If you prefer no recipe rows from notes, delete the 7 `type: recipe` rows' checkpoints (or set them null) and
   rerun `extract_batch.py write`; nothing else depends on them.
2. **Name-only placement.** 3 of the 12 rows had IDs in a sibling note and are placed; Felwort (input without an ID) and
   Roseate stay unplaced. The same open rule from M03 applies: Felwort is a unique herb name, but the tool does not place by name.
3. **The 12 `ambiguous-doubt` sources.** They hold real numbers the rules refuse: Stormvine (`wowhead:item=52984@cata` and `@tw`, one
   comment: 202 Ashen and 20 Burning with 21 stacks vs 96 mills), Progenium PTR (`reddit:r80lkp`, 10,000 ore at about 0.7%
   per essence), the crushing report (`reddit:1ub8pxv`, 35 to 40 dust from 1,000 ore), the Pyrite table
   (`wow-professions.com/cataclysm/prospecting...`, 17% for six unnamed gems) and the MoP table (24 / 5 / 17%), the LotzBoi
   comment on two pages, the Czech guide, `item=123919` (mixed Leystone and Felslate) and the two Blizzard bug threads. Say whether
   any should be stored as `reference` rows with an `unclear` meaning.
4. **Queue completeness** (finding 1 above). The M04.2 queue is a lower bound. Widen the linker's observational-count pattern
   in M07, or accept `EXTRA_FILES` as the manual patch.
5. **The 46 null sources stay in the live queue** (the linker still sees them as residue). M07 should dispose their files using
   the checkpoint reasons rather than leaving 42 files as "residue".
6. **Stormvine and Felwort cohorts share a page with other authors.** Wowhead item pages host several independent comments, and
   the source key is the page. When an agent records another comment from `item=129034`, rule 5 will mark the page held and
   the writer will stop writing these two rows (reported as `held`). Say whether comment-level keys should be added.
