# M04.1 and M04.2: deterministic linking and the residual queue (MIG-006)

Tool: `tools/link_sources.py` (read-only on evidence, no AI, no network). Outputs: `manifest/links.jsonl` (1,563 lines),
`manifest/extraction-queue.jsonl` (55 sources), `manifest/links-summary.json`. Tests: `tests/test_link_sources.py` (49).
All numbers below were measured by running the tool on branch `migration/v3-historical-research`.

## What it does

For each of the 265 files the M01 inventory marks `candidate-unmigrated` (165), `candidate-no-url` (35) or
`covered-by-url` (65), it reads every cited URL (normalized with `source_keys.normalize_url`), every v3 study key or
record ID written in the file, and the numbers next to each citation. It compares them with what v3 holds **now**
(4,933 effective records: agent evidence plus imported rows, corrections applied).

| Status | Rule | Citation groups |
| --- | --- | --- |
| linked | v3 holds the source (same key or thread) and a *result* number next to the citation is a held row's total, hit count, percent, average, min/max or exchange count | 266 (191 strong, 75 weak) |
| source-held | v3 holds the source; the citation carries no observational count, or only batch sizes | 340 |
| exception | v3 holds the source; the citation has an observational count, a number that is not a held batch size, and no held result matches | 91 |
| residue | v3 does not hold the source and the citation (or the file) carries observational counts | 70 |
| skipped-decided | M03 `NEW_SOURCES` decision: qualitative, mechanics or an agent-held cohort under another URL | 63 |
| reference | reference host, entity page without counts, API or schema docs, URL template | 317 |

A file's outcome is the most open status it has: residue, then exception, then linked, else disposed.

Rules that matter (all tested): the window around a citation is its own line plus up to two neighbouring lines of the same
paragraph, never past a blank line, a heading, another source's URL, or a list item that belongs to another URL; table and
CSV rows stand alone; in JSON the window is the claim object. Only telling numbers count (not 0, 1 or a whole number up to
5), dates and bare years are ignored, 0-1 fractions also match as percentages. **Matching only the batch size is not a
link** (casts, `inputsProcessed`): many cohorts share 1,000 ore. A weak link is a single integer match below 100.
A URL that v3 notes mention but no record cites is not held (16 of the 543 registry URLs).

## Counts before and after

| | Before (M01, snapshot) | After (MIG-006) |
| --- | --- | --- |
| In-scope files | 265 (165 / 35 / 65) | linked **133**, exception **44**, residue **49**, disposed **39** |
| `candidate-unmigrated` (165) | 165 | linked 89, exception 24, residue 47, disposed 5 |
| `candidate-no-url` (35) | 35 | linked 2 (by study ID), disposed 33 |
| `covered-by-url` (65) | 65 | linked 42, exception 20, residue 2, disposed 1 |
| Markdown, all 168 in scope | 168 | linked 79, exception 30, residue 47, disposed 12 |
| The 124 Markdown `candidate-unmigrated` | 124 | linked 58, exception 18, residue 45, disposed 3 |
| Registry URLs (543) | 165 in v3 (notes mentions count), 378 not | 162 held by a record's source + 16 mentioned only = 178 (net +13; the two counts differ slightly in how they match threads); **365 not in v3** |
| Residual queue | n/a | **55 sources** in 49 files (70 file-source pieces: 40 numbers next to the citation, 30 numbers elsewhere in the file), 138 anchors |
| Study-ID links | n/a | 45 IDs in 20 files |
| Estimates | 1,205 (447 unplaced), `6976d1bd…` | identical (`cmp` with `before.json`) |

The 39 disposed files: 33 no-URL files (coverage, audit and score tables; reports citing no source), `PROGRESS.md` and two
master verdicts (reference links only), `evidence/leads/…two-2000ore-cohorts.json` (M03 skip), `proposed/itemdb.schema.json`
(schema URL), `proposed/itemdb-curated-additions.json` (no URL). Each has its reason in `links.jsonl`.
Of the 266 linked citation groups, 120 link only to rows the importer wrote (M03/M03b, from other files); the rest reach agent evidence.

## The three known link-candidate groups

**1. Agent-held name-only rows.** The handoff said 92; the M03 report's own table and the data say **86** (83 held by URL,
3 held by numbers; the 6 "placed" rows make 92). Result: **58 linked, 6 exception, 22 unlinked.**
- Linked: Reddit zez5sj 15, Almar 11, Jallfo sheet 6, zkay8v 23, Kyparite Sparkling Shard 3 (numbers). 23 of the zkay8v rows link
  to agent rows that `corrections.jsonl` excludes as duplicates of the import (`dragonflight-20261031-50001..50025`), so the
  import-side rows are the only live copy; the link says so.
- Exception (6): Jallfo's Crumbled Stone / Fractured Glass cohorts: imported totals 1036, 947, 986 / 769, 1079, 1225 against agent
  totals 1016, 1025, 980 / 1106, 1162, 790, all 1,000 casts. Different cohorts or different transcriptions; not decided here.
- Unlinked (22): zkay8v's **10,000-ore cohort**. Agents recorded only the 1,000-prospect cohort, so these rows have no agent copy.

**2. 1smgllg rates (14).** Name linking against v3's own names for the same expansion (Midnight evidence): **11 link, 3 listed.**
Lapis → Amani Lapis 242554, Garnet → Sanguine Garnet 242553, Peridot → Harandar Peridot 242607, Amethyst → Tenebrous Amethyst 242606,
Diamond → Eversong Diamond 242608, "Flawless X" → the flawless IDs 242610/242611; the ore family is a rank pair
(Refulgent Copper 237359/237361, Umbral Tin 237362/237363, Brilliant Silver 237364/237365), so the input is family-level.
Listed: "each of 'the others'" (aggregate) and the two co-output averages whose ore family is "all mentioned". These are
proposals recorded in `links.jsonl` (`kind: candidate`); the importer places nothing from this source and is unchanged.

**3. s6bfrl uncommon gems (6).** **6 exceptions.** v3 holds s6bfrl's powder and rare gems (25 records) but none of the six
outputs (Bloodstone 53, Sun Crystal 44, Chalcedony 49, Shadow Crystal 53, Huge Citrine 47, Dark Jade 59 per 1,000 ore). The post is
not readable offline, so they stay unverified and unimported.

## The residual queue (M04.2)

55 sources, one entry each in `manifest/extraction-queue.jsonl` (sorted by source key): the raw URLs, the files with their
sha256, the anchors (line number or JSON path, text, numbers), `expectedTypes` and `methodHints`. By host: Wowhead 23 (item and
spell pages cited with counts, no comment ID; most will extract nothing), Reddit 14, Blizzard forum 3, wow-professions.com 3, others 12.
`expectedTypes` are keyword hints for M04.3, not decisions: drop 55, recipe 19, condition 4, rateChange 4, exchange 2.
A `proximity: file` piece means the file holds counts that are not next to the citation, so M04.3 must decide whether they
belong to that source (at most three such sources per file; longer source lists stay out of the queue).

## Method notes and limits

- Linking is by numbers, not meaning: a link says the source is held and a result number agrees. 75 weak links (one small
  integer) are the likeliest false positives; M04.4 should sample them.
- An exception means "same source, other numbers", often a note that quotes a ratio or an audit count rather than a cohort. 91
  groups in 68 files go to M07 for review. The sources behind most of them: wowhead spell 374627 (8), item 200061 (7), reddit 1f83cnd (5).
- JSON claims are the object that holds the URL (as in the M03 importer), so a parent object that nests other URLs also
  contributes its children's numbers.
- Candidate matching reads raw agent rows (before corrections) so rows excluded as duplicates still link; label resolution reads effective rows only.

## For the Master (proposals only)

1. zkay8v 10,000-ore cohort: 22 name-only rows, no agent copy, stored unplaced. Decide whether to place them by name
   (R2/R3 names are unambiguous in the 1,000-cast study) or ask an agent to record the cohort.
2. 1smgllg: 11 rates now have unambiguous output IDs and a family-level input. Placing them needs an importer change
   (M10 or a later step); the rates are one commenter's approximations, so weight them as reference, not a study.
3. s6bfrl uncommon gems and the six Jallfo exceptions need the original posts; they cannot be settled offline.
4. The 23 wowhead entity-page sources in the queue are probably identity links with incidental counts. Say whether to skip them in M04.3.
5. Handoff said 92 name-only rows; the data says 86 (+6 placed). Correct anywhere the 92 is quoted.
