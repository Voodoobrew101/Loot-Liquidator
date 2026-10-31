# Research evidence (v3)

Raw counts collected by the research agents, one file per run:
`research/evidence/v3/<agent>/<UTC-date>-<short-name>.json`, each file a JSON **list** of records.

- Record format and rules: `claude/research-agent-proposal.md`, sections 3 (evidence) and 3b (mechanics).
- Checker verdicts are records too: `{"kind": "check", "recordId": "<file>#<position>", "result": "confirmed" | "mismatch", "saw": "..."}`.
  A record's ID is its file path inside this folder plus `#` and its position in the list, counted from 0.
- Check your file before committing: `python3 tools/evidence_check.py`. Records that break a rule are
  **set aside with a reason**, never deleted. Fix them in a new file; don't edit another agent's file.
- Never type a final drop chance, average or confidence. A script works those out from the counts (task D1b).
