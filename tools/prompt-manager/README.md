# Loot Liquidator Prompt Manager — private ChatGPT plugin

Use @Loot Liquidator Prompt Manager in any chat and say **show my prompts**, **load 1**, **open the PR one**, or **activate the UI Director**. Names and spellings are not required; the plugin discovers entries from the GitHub registry and shows numbered choices.

The source of truth is docs/master-prompts/registry.json in Voodoobrew101/Loot-Liquidator, not the static skill bundle. A connected GitHub tool is required for live lookups and writes. While the setup PR is awaiting merge, it reads feature/prompt-manager-v1. For edits, it opens a PR; it does not merge anything.

Install the privately created plugin from its ChatGPT plugin page. Invoking the plugin loads prompt text into the assistant's context, **not** into the user's message composer. Prompt entries still awaiting exact historical text are labeled needs-import rather than fabricated.

To rebuild the private plugin archive from this folder: zip the **contents** of tools/prompt-manager/ so that plugin.json is at the ZIP root; do not zip the directory itself.
