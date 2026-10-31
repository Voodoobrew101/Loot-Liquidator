# Research evidence (v3)

> **Not read by the agents (session 14).** The research agents were switched to their own v3 workflow in
> `research/v3/` on `implementation/five-agent-completion` (rules there: `research/v3/README.md`).
> This branch takes their results through `tools/research_v3_to_baselines.py` (task D1c). Kept for the record.

Raw counts collected by the research agents, one file per run:
`research/evidence/v3/<agent>/<UTC-date>-<short-name>.json`, each file a JSON **list** of records.

- Record format and rules: `claude/research-agent-proposal.md`, sections 3 (evidence) and 3b (mechanics).
- Checker verdicts are records too: `{"kind": "check", "recordId": "<file>#<position>", "result": "confirmed" | "mismatch", "saw": "..."}`.
  A record's ID is its file path inside this folder plus `#` and its position in the list, counted from 0.
- Check your file before committing: `python3 tools/evidence_check.py`. Records that break a rule are
  **set aside with a reason**, never deleted. Fix them in a new file; don't edit another agent's file.
- Never type a final drop chance, average or confidence. A script works those out from the counts (task D1b).
- After checking, `python3 tools/evidence_to_baselines.py` turns the usable Disenchant / Mill / Prospect / Smelt
  records into `database/evidence-baselines.lua` (generated, never hand-edited), which the database compiler adds
  to ItemDB. Copies with the same `lineage` count once (the biggest wins); `stale` counts ×0.25; a sample counts at
  full weight only when `skill` equals `minimumSkill` and every stat is 0, otherwise ×0.5 until scaling rules exist;
  a percentage with no sample size counts as 20 casts; a record the Checker marked `mismatch` is skipped.
- **List outputs you counted zero of** with `"castsWithDrop": 0`. An output you leave out counts as "not reported",
  not as "never dropped".
