# Loot Liquidator Master Prompt Library

This folder is the version-controlled source of truth for Loot Liquidator prompts used by the private @Loot Liquidator Prompt Manager ChatGPT plugin.

- registry.json: searchable IDs, aliases, source, readiness, and exact relative file paths.
- agents/: historical verbatim worker instructions available for retrieval. These are **archived snapshots**, not a claim of current agent policy.
- needs-import entries: known master prompt conversations whose exact final text has not yet been imported. Never reconstruct them from summaries and label them final.

Say @Loot Liquidator Prompt Manager show my prompts and select a number. Or ask for a role with rough spelling, like load my PR one or UI boss. To import finalized prompts, paste the exact final text in a chat invoking the manager and ask it to create a versioned import PR. The PR Director controls merges and closure.

The repository is public. **Do not store credentials, tokens, private messages, account identifiers, or confidential instructions in this library.** This registry concerns prompt text, not World of Warcraft addon runtime; no compiled addon output belongs here.
