# Loot Liquidator 0.11.0-claude.22 — automated build report

**BUILD PASSED** for the owner's selected branch and paused-research policy. Needs an in-game check before public release.

## Release

- Date: November 1, 2026.
- ZIP: `dist/LootLiquidator-v0.11.0-claude.22-2026-11-01.zip`, 370,906 bytes, 19 manifest-declared runtime files.
- ZIP SHA-256: `24131a641cf454bb947ead8880868234ea88d01bd5f86a3b86cbedf9bb3f21eb`.
- ItemDB SHA-256: `8ed3446a3eb1d9afc9a8524c7a61323471999dcacdd9b25d62925a92d7459f23`.
- Source: `LootLiquidatorclaude-V0.1` at `5eb7b59d805aae44d215d3ebdfd1f65f419f5cba`.
- Research: `implementation/five-agent-completion` snapshot `9a22e2787ec133419bad9bce66d036219e2439a4`.

## Research strategy and compiler audit

The owner's current handoff explicitly selects this branch and keeps research paused. No snapshot refresh or cross-branch merge was performed. Read the pinned research [README](https://github.com/Voodoobrew101/Loot-Liquidator/blob/9a22e2787ec133419bad9bce66d036219e2439a4/research/v3/README.md), [strategy](https://github.com/Voodoobrew101/Loot-Liquidator/blob/9a22e2787ec133419bad9bce66d036219e2439a4/research/v3/strategy.md), and [mechanics](https://github.com/Voodoobrew101/Loot-Liquidator/blob/9a22e2787ec133419bad9bce66d036219e2439a4/research/v3/mechanics.md) through the GitHub connector. The local clone lacked that historical Git object; fetching it returned an empty server reply, so the connector supplied the exact pinned files instead. Original evidence and calculator files were untouched.

Inspected the evidence adapter, official compiler and runtime valuation against the active owner decisions and retained audit in [version .20](BUILD-0.11.0-claude.20.md). The unchanged pipeline counts real studies rather than TSM/reference yields or a second copy of legacy disenchant tables; source identity deduplicates studies and epochs count at reduced weight. Unknown input ranks, mixed batch sizes and unsupported conditional unlocks remain explicitly excluded from ordinary baselines. Measured and inferred fields retain separate statuses; inferred estimates carry reduced confidence under the owner's policy. Expected quantity is multiplied by price once, then divided by inputs per cast. Resourcefulness belongs in input savings, and no new Multicraft, skill or specialization coefficients were added. The existing research limits in D1b, D1c3, C4b4 and C7c remain; this import fix does not claim to resolve them.

## Fresh compilation and regression comparison

Built an isolated `git archive` of the exact source commit. Ran `tools/evidence_to_baselines.py`, `tools/research_v3_to_baselines.py` without `--refresh`, then `tools/compile_itemdb.lua LootLiquidator/ItemDBRuntime.lua` with embedded Lua 5.1. The fresh ItemDB matches the committed file and version `.21` byte-for-byte, so coverage, probabilities, expected quantities, confidence and provenance are unchanged.

The v3 records also match the pre-session baseline `8273371` exactly: 89 input records and 443 material rows, with no additions, removals or changed rows. The full compiler reports 285 processing records, 47 older rows superseded and 137 research no-disenchant additions. Token coverage remains 229 tokens and 645 rewards. No database regression was found.

## Import change and validation

B7b rejects malformed numbers, unescaped control characters, invalid Unicode escapes and repeated JSON fields. Null entries are retained until per-cast validation, and item vectors must be arrays. Escaped Unicode operation IDs retain their UTF-8 identity, so they match literal duplicates without merging unrelated names into question marks. Valid decimal/exponent numbers and confirmed-empty results remain supported. Parsed JSON tables are temporary; only validated cast counts enter the existing saved-data format. Existing imports and weights need no migration.

The import test now has 109 assertions. Running the new regression against the previous importer confirmed the actual failure: the old reader accepts quantity `03` as 3, while the new reader rejects the page without changing stored counts. Every `tests/run.sh` check passed before the source commit and again in the clean release stage.

| Check | Result |
| --- | --- |
| Source/snapshot selection and research policy | PASS — current owner handoff |
| Compiler/economic audit within current policy | PASS — unchanged pipeline inspected |
| Fresh official compilation and exact database reproduction | PASS |
| Lua 5.1 syntax, schema/distributions, TOC and load order | PASS |
| Every `tests/run.sh` check in isolated clean stage | PASS |
| New import regressions and previous-reader failure reproduction | PASS |
| Unmodified Linux CI for the exact source commit | PASS — [run 41317050440](https://github.com/Voodoobrew101/Loot-Liquidator/actions/runs/41317050440) |
| Standalone loading and optional dependency policy | PASS |
| Manifest-only ZIP, one `LootLiquidator/` folder, CRC integrity | PASS |
| Extracted files compared with clean stage and committed source | PASS — every file |
| ZIP and extracted ItemDB SHA-256 | PASS |
| In-game testing | NOT RUN — owner check needed |

Local logs: `../.validation/session20-baseline.log`, `session20-final.log` and `session20-release.log`. Structured build facts: the `.build.json` beside the ZIP. The final ZIP, logs and report are retained; disposable staging and extraction files are removed after verification.

## What to check in game

Check version `.22` and saved settings. Import a friend's valid export page, then paste it again to check duplicate refusal; importing your own export should still skip your own results. Familiar ore/herb and token badges should behave as before. Follow `RELEASE-CHECKLIST.md` before a public upload.
