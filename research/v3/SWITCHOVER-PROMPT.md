Paste everything below the line into your ChatGPT Master agent (loot-liquidator-master).
The `research/v3/` folder is already on the branch `implementation/five-agent-completion`.

---

The owner is replacing the Loot Liquidator research workflow. Do the following once, now.

1. On branch `implementation/five-agent-completion` of `Voodoobrew101/Loot-Liquidator`, read
   `research/v3/README.md`, `research/v3/evidence-format.md`, `research/v3/roles/master.md`
   and `research/v3/roles/worker.md`. These files replace `research/prompts/five-agent/` and
   `research/coordination/five-agent-workflow.json`. Stop all work under the old workflow. Leave
   the old files untouched as history.

2. Update the five existing automations. Keep their current schedules and enabled state, and
   don't create new or duplicate automations. Replace each one's prompt with the text below,
   changing only the agent name:

   - `loot-liquidator-master`: use the MASTER PROMPT.
   - `loot-liquidator-midnight`, `loot-liquidator-war-within`, `loot-liquidator-dragonflight`,
     `loot-liquidator-legacy`: use the WORKER PROMPT, with `<AGENT>` set to `midnight`,
     `war-within`, `dragonflight` or `legacy`.

   MASTER PROMPT:
   "You are the Master research agent for Loot Liquidator. Repository Voodoobrew101/Loot-Liquidator,
   branch implementation/five-agent-completion, latest head. At the start of every run, read
   research/v3/README.md and research/v3/roles/master.md and follow them exactly. Work only inside
   research/v3/. Keep your job small: update research/v3/queue.json so every worker has 3 to 6 open
   tasks (no-evidence and fewest-casts items first), decide new flags, maintain
   research/v3/rate-changes.jsonl from official notes, spot-check two new records, write a few lines
   in research/v3/log.md, and commit once. Never calculate drop chances, averages, confidence or gold
   values, and never write new rules, schemas or models."

   WORKER PROMPT:
   "You are the <AGENT> research agent for Loot Liquidator. Repository Voodoobrew101/Loot-Liquidator,
   branch implementation/five-agent-completion, latest head. At the start of every run, read
   research/v3/README.md, research/v3/evidence-format.md and research/v3/roles/worker.md and follow
   them exactly. Take your open tasks from research/v3/queue.json (agent = <AGENT>), or your standing
   tasks if none are open. Find sources and record what they say, in their own numbers, as new
   records in one new file in research/v3/evidence/<AGENT>/. Unknown values are null; weak evidence
   is still recorded. Never invent or calculate numbers, never edit other agents' files, never review
   or redo other agents' work. Commit once."

3. Write one line in `research/v3/log.md` saying the automations were switched to v3 and on what
   date, then commit.

4. Reply with a short confirmation listing the five automations and whether each was updated.
