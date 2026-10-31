# Role: worker (automations `loot-liquidator-midnight`, `-war-within`, `-dragonflight`, `-legacy`)

You find evidence for your expansion and write it down in the agreed format.

| Agent | Covers |
| --- | --- |
| `midnight` | Midnight (current expansion) |
| `war-within` | The War Within |
| `dragonflight` | Dragonflight |
| `legacy` | Everything older (Classic through Shadowlands) |

## Each run, in order

1. **Read** `research/v3/README.md`, `research/v3/evidence-format.md`, this file, and
   `research/v3/queue.json`.
2. **Pick your open tasks** (`agent` = your name), starting at the top.
   If you have none, work through **Your standing tasks** below.
3. **Search.** Good places to look:
   - Wowhead item pages: the "Prospected from", "Milled from", "Disenchanted from" and "Contains" tabs,
     and comments that post results with counts
   - Reddit r/woweconomy result posts
   - Profession guides (wow-professions.com, Method, Icy Veins, Wowhead guides)
   - warcraft.wiki.gg item and profession pages
   - Official Blizzard patch notes and hotfix pages (for `rateChange`)
4. **Record** every useful source as records in a new file in `research/v3/evidence/<your-name>/`,
   following `evidence-format.md` exactly. Record what the source says, in its own numbers.
5. If a real search finds nothing, add a `searched` record.
6. **Commit** your one new file.

## Your standing tasks (when the queue has nothing for you)

1. **Rescue old evidence first.** The folders `research/evidence/observations/` and
   `research/evidence/leads/` hold about 125 older files from the previous workflow. Many contain
   real studies with counts that the old rules refused to use (for example a 1,040-prospect Aqirite
   study). Re-record the ones for your expansion in the new format. Link the original source,
   not the old file. Skip anything with no source link.
2. Gear tokens, exchanges, no-disenchant items and batch sizes for your expansion.
3. More processing studies for your expansion's ores, herbs and gear.

## Don't

- Don't calculate drop chances, averages, confidence or gold values.
- Don't edit files outside your own evidence folder (except adding lines to `flags.jsonl`).
- Don't review or redo other agents' records.
- Don't stop at "not enough evidence". Record what exists.
