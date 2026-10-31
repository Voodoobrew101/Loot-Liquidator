# Research v3 log

- 2026-10-30: v3 rules, roles, record format, starter queue and rate-change list set up by the owner (drafted and committed by Claude with the owner's permission). SWITCHOVER-PROMPT.md holds the prompt the owner pastes into the Master agent.
- 2026-10-30: Switched all five existing research automations to v3 prompts; preserved their schedules and enabled state.

- 2026-10-30 (Master): Capped each worker at 3–6 open tasks; deferred T0023–T0028 as queued, not completed. Open tasks: Midnight 6, War Within 6, Dragonflight 6, Legacy 5; retained no-cast processing work first.
- 2026-10-30 (Master): No flags in flags.jsonl. Official March 31, 2026 Midnight prospecting change already listed; no duplicate rate-change entry.
- 2026-10-30 (Master): No new v3 worker records identifiable in available searches, so two new-record source spot-checks remain pending; no tasks marked done.
- 2026-10-30 (owner, via Claude): first v3 runs were too short. Most agents searched by item ID number, which search engines do not index, and stopped after two searches. Queue now has item names and search tips; T0013 skipped (item 200061 is Prismatic Leaper, a fish, so the old TSM mill mapping is bad); Draconium tasks moved from legacy to dragonflight. Rules now require at least 10 real records per run, searches by name, 6+ searches across 3+ sites before a searched record, and the old-evidence rescue when searches come up empty.
