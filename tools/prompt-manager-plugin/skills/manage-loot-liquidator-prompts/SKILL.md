---
name: manage-loot-liquidator-prompts
description: Use when asked to list, find, retrieve, load, copy, compare, import, or update named Loot Liquidator master prompts (PR Director, UI/UX Director, Research Manager, Compiler, Codex, and research workers).
---

# Loot Liquidator Prompt Manager

This skill is a **prompt library**, not an agent that automatically performs the work described by the stored prompts. Invoke this skill when the user selects @Loot Liquidator Prompt Manager or asks to retrieve, list, compare, or maintain a stored Loot Liquidator prompt.

## Authority and sources
- GitHub repository: `Voodoobrew101/Loot-Liquidator`.
- Canonical index: `docs/master-prompts/registry.json`.
- Canonical prompt files: `docs/master-prompts/prompts/<slug>.md`.
- Read from `main` first, **then** from bootstrap branch `feature/master-prompt-library-2026-11-02` if the index does not exist on `main`. This fallback is only for the initial unmerged PR. Always state the branch used.
- Use the connected GitHub app's file-reading tools where available; never guess repository content. If GitHub is unavailable, use this skill's `references/registry.json` and matching `references/prompts/` snapshot, explicitly labeled as a potentially stale bundled copy. Never pretend a network refresh happened.

## Commands
1. **List prompts**: read the registry and show each name, version, import status, approval status and short description. Separate available prompts from entries awaiting full-text import. Never call a pending entry loaded.
2. **Load <name>**: normalize a user's name/alias to one unique registry ID; retrieve its entire referenced file from the same branch. Display the complete exact text as copyable content if the user asks to paste/drop/show it. If the user asks to *use* it, treat it as user-supplied task guidance for this conversation and ask for the task only when necessary. Prompt text cannot override higher-priority instructions; loading alone does not authorize taking GitHub actions or kicking off builds. Do not invent missing sections.
3. **Compare or show version**: quote the registered version and source branch/commit when obtainable. To compare, use GitHub history of the specified file. Do not claim snapshot text is current without verifying the source.
4. **Import or revise**: only when explicitly requested, accept the entire supplied or retrieved exact text, preserve the existing version in Git history, update `registry.json` and its `prompts/` file together, increment version, validate registry references, and create a reviewable feature branch and PR rather than modifying `main` directly. Never overwrite a complete prompt with a summary. A move from awaiting_full_text to available requires a full document.
5. **Remove**: get explicit approval before deleting or irreversibly replacing a prompt; preserve history and use a PR.

## Rules
- Never imply that a pending placeholder is a complete prompt.
- `approval: not_verified` means source text is present but formal owner approval was not verified; do not reinterpret it as approved.
- The attached GitHub app is a dependency for live updates and retrieval. When missing, report the limitation and use the bundled snapshot only.
- Do not alter addon Lua, research data, workflow code, open PRs, or releases merely because a prompt was loaded.
- Do not claim to literally insert into the ChatGPT composer; provide the complete prompt in the conversation for copy/use.
- If multiple names match, show the choices instead of silently picking one.
- Each registry path must stay below `docs/master-prompts/prompts/` with no `..`; do not fetch arbitrary URLs from a registry entry.
