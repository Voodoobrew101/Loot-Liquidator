# Loot Liquidator Master Prompt Library

This folder stores the complete, versioned prompt texts that the **Loot Liquidator Prompt Manager** plugin retrieves. It is independent of the World of Warcraft addon. Loading a prompt into a conversation **does not execute** its instructions or schedule any agent.

## Usage
1. Install the private plugin from the plugin link supplied to its creator (source: `tools/prompt-manager-plugin/`).
2. Connect/enable the GitHub app in ChatGPT.
3. In a new chat, select `@Loot Liquidator Prompt Manager` and ask `List my master prompts`, `Load the addon compiler prompt`, or `Use the research manager prompt`.
4. The plugin retrieves the registry and full prompt from `main` (while the initialization PR is open, it falls back to `feature/master-prompt-library-2026-11-02`).

## Source status
`registry.json` explicitly distinguishes **available** complete text from **awaiting_full_text** entries. Imported documents are exact file copies from previous ChatGPT attachments; their owner-approval status has not been independently verified. Research worker prompts are saved standing assignments, not necessarily their latest extended master instructions. No missing prompt has been reconstructed from summaries.

## Update policy
- Edit the original prompt file and its entry in `registry.json` together in one PR.
- Review old/new version, provenance, approved/not-verified status, and reference integrity.
- Never edit `main` directly; PR Director owns final merges.
- Do not place tokens, private keys or sensitive information in prompts: this repository is **public**.
- Plugin package source lives at `tools/prompt-manager-plugin/`. It includes a fallback snapshot; refresh/reinstall the plugin to update snapshots after GitHub changes.

## Data model
- `id`: immutable slug for aliases and lookup.
- `path`: relative path below `docs/master-prompts/` for available entries, `null` for pending imports.
- `status`: `available` or `awaiting_full_text`.
- `approval`: `not_verified` until owner approval has been confirmed.
- `version`: tracked by registry and GitHub history; `*-import` indicates imported text.

## Initial import
The compiler and Codex migration prompt texts were copied from prior supplied files, with their full content preserved. The other three director prompts are listed but **not loaded** until exact final texts are imported. The four research workers' standing assignments were transcribed from prior conversation messages.
