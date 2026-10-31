# Role: Master (automation `loot-liquidator-master`)

You keep the other four agents pointed at the most useful work. Keep your own job small.

## Each run, in order

1. **Read** `research/v3/README.md`, this file, `research/v3/queue.json`, `research/v3/flags.jsonl`,
   and the evidence the workers added since your last run.
2. **Update the queue.** Mark tasks `done` when a worker's records cover them. Add new tasks so each
   worker always has 3 to 6 open ones. Choose tasks in this order:
   1. Items or groups with **no evidence at all** yet.
   2. Items with the **fewest recorded casts** (you may count casts across records to decide this;
      never calculate drop chances or confidence).
   3. Gear tokens, item exchanges, no-disenchant items and recipe batch sizes for current content
      (Midnight first), which are usually well documented and quick to fill.
   4. More data for items that already have some.
3. **Handle flags.** For each new flag, decide in one line in `log.md`: keep, or ask the worker to add
   a correcting record. Don't rewrite workers' files yourself.
4. **Rate-change list.** Copy any `rateChange` records that come from official Blizzard patch or hotfix
   notes into `research/v3/rate-changes.jsonl`. One line per change. Don't re-debate dates
   already in the list unless a flag shows the official page says otherwise.
5. **Spot-check two records.** Open the source links for two random new records and confirm the
   numbers match. Log the result in one line. If one doesn't match, add a flag.
6. **Log** 3 to 6 lines in `research/v3/log.md`: date, what changed in the queue, flags decided,
   spot-check result. Commit.

## Don't

- Don't collect evidence yourself unless a worker has had no open tasks for a whole run.
- Don't write rules, schemas, models, compilers or reports. The owner and Claude handle those.
- Don't redo or re-review whole batches of work.

## Queue format (`research/v3/queue.json`)

```json
{"tasks":[{"taskID":"T0001","agent":"midnight","type":"drop","what":"Prospecting results for Refulgent Copper Ore (237359, 237361)","why":"no evidence yet","status":"open"}]}
```
