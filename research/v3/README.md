# Loot Liquidator research, version 3: shared rules for all five agents

Read this file, then your role file in `research/v3/roles/`, at the start of every run.
These rules replace the old five-agent workflow in `research/prompts/five-agent/`.
Leave all old files where they are. Don't edit, move or delete them; they are history.

Repository: `Voodoobrew101/Loot-Liquidator`, branch `implementation/five-agent-completion`.
Work only inside `research/v3/`. Never touch `main`, the addon folder `LootLiquidator/`,
or other branches.

## What we are building

Loot Liquidator tells a player what to do with each item: auction it, vendor it, disenchant it,
mill it, prospect it, smelt it, or keep it for transmog. To do that it needs one database,
**ItemDB**, that holds:

1. **Processing results:** what disenchanting, milling, prospecting or smelting an item gives,
   how often each material drops, and how many drop at once.
2. **Gear tokens:** which token turns into which gear, for which classes.
3. **Item exchanges:** trade X of one item for Y of another, at a vendor or by using the item.
4. **Items that cannot be disenchanted.**
5. **Recipe facts:** batch sizes, such as 5 ore per prospect, 5 or 10 herbs per mill, or 20 herbs for mass milling.
6. **Rate changes:** patches and hotfixes that changed any of the above, with dates.

## Your job: collect evidence, never calculate results

You find sources and **write down what each source says, in the source's own numbers.**
You do **not** work out final drop chances, averages, confidence scores or gold values. A script
does that later, the same way every time. That is how we avoid invented numbers.

## The five rules

1. **Everything counts, weak evidence just counts less.** Don't reject a source because it is
   small, old, missing details, or only gives percentages. Record what it has and leave unknown
   fields as `null`. A 10-cast forum post is worth recording; it simply carries 10 casts of weight.
2. **Never invent a number.** Every number you write must appear in, or be directly counted from,
   the linked source. If a source gives only a percentage, record the percentage and leave
   `casts` as `null`. Simple arithmetic on the source's own stated numbers is fine and expected:
   "100 ore prospected" at 5 ore per prospect is `casts: 20`. Say so in `notes`.
3. **Record where a study originally came from.** Big player studies get copied across Wowhead
   comments, Reddit and guides. Put the original link in `originalSource` so the same data is
   never counted twice. If you can't tell, leave it `null`.
4. **Don't redo other agents' work.** Don't review, re-check, rewrite or argue with other agents'
   records. If you think a record is wrong, add one line to `research/v3/flags.jsonl` (see
   `evidence-format.md`) and move on. The Master decides.
5. **Use the whole run and bring back data.** A run is not finished after one task or two searches.
   Keep working through tasks, then standing tasks, until you have added **at least 10 real records**
   (any type except `searched`) or have honestly tried every open task and standing task.
   - **Always search by item name, never by ID number.** Search engines don't index item IDs.
     Get a name from `https://nether.wowhead.com/tooltip/item/<ID>`.
   - Wowhead item pages often don't load for automated browsing. Use search results, Reddit,
     wow-professions.com, warcraft.wiki.gg, Icy Veins, Method and guide pages instead.
   - **Prefer pages that cover many items at once:** full prospecting, milling or disenchanting
     tables in guides, big result posts, and wiki pages listing every ore or herb of an expansion.
     One good table page can fill dozens of records; record every item on it, even ones outside
     your current task, as long as they belong to your expansion.
   - A `searched` record is allowed only after **at least 6 searches across at least 3 different
     sites**, all by name, each listed in `whereLooked`. Then move straight on to the next task
     in the same run.

## Accuracy goal (for knowing what to look for)

About **±5 percentage points** on drop chances is good enough. Roughly 200 to 400 recorded casts of
one item gets there. Items with the fewest recorded casts come first. Items that already have a
lot still benefit from more data, but at lower priority.

Yield ranges are small whole numbers, usually 1 to 4. Just record the smallest and largest amount
a source reports seeing in one cast.

## Where things go

| What | Where | Who writes it |
| --- | --- | --- |
| Shared rules (this file) | `research/v3/README.md` | Owner only |
| Role instructions | `research/v3/roles/` | Owner only |
| Record format and examples | `research/v3/evidence-format.md` | Owner only |
| Work queue | `research/v3/queue.json` | Master only |
| Rate-change list | `research/v3/rate-changes.jsonl` | Master only (workers suggest via flags) |
| Evidence | `research/v3/evidence/<your-agent-name>/` | Each agent, its own folder only |
| Generated estimates (chance, average, range, confidence) | `research/v3/output/` | Only the script `research/v3/tools/build_estimates.py`; agents never edit these. Use `summary.md` to see which items are weakest. |
| Records converted from the old research | `research/v3/evidence/imported/` | Only the script `research/v3/tools/import_existing.py`; agents never edit these |
| Flags | `research/v3/flags.jsonl` | Anyone; add lines only, never edit |
| Run log | `research/v3/log.md` | Master only, a few lines per run |

## Commits

- Make one commit per run, touching only files you own.
- Each run, add a new evidence file named `YYYY-MM-DDTHHMM-short-topic.jsonl` in your folder.
  Never rewrite old evidence files; if something was wrong, add a corrected record that names
  the old record in `replaces`.
- Commit message: `v3 <agent-name>: <what you added>`, for example `v3 midnight: 3 prospecting studies for Refulgent Copper`.

## Quoting sources

Keep any quote short (under 25 words), only enough to show where a number came from.
Write everything else in your own words.
