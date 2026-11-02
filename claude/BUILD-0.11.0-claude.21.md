# Loot Liquidator 0.11.0-claude.21 — automated build report

**BUILD PASSED** for the requested working branch and pinned research policy. Needs an in-game check before public release.

## Release

- Date: November 1, 2026.
- ZIP: `dist/LootLiquidator-v0.11.0-claude.21-2026-11-01.zip`, 370,371 bytes, 19 runtime files.
- ZIP SHA-256: `3182489fa4d86a5aa6d43a18ea6c5380e52114c44f99332a6f329ebfdeffdace`.
- ItemDB SHA-256: `8ed3446a3eb1d9afc9a8524c7a61323471999dcacdd9b25d62925a92d7459f23`.
- Source: `LootLiquidatorclaude-V0.1` at `781216f7cf7a5fcd12b984c600f6bdf1daf9b205`.
- Research: `implementation/five-agent-completion` snapshot `9a22e2787ec133419bad9bce66d036219e2439a4`.

## Research strategy and findings

The owner's handoff keeps research paused and selects this branch. No snapshot refresh or cross-branch merge was performed. The strategy/compiler audit from [version .20](BUILD-0.11.0-claude.20.md) applies to the unchanged evidence, calculator, compiler, database and economic valuation code. The new research audit only reads evidence after existing corrections; it cannot fill unknowns, change counts, infer ranks or alter ItemDB.

Checked the explicit quality tables on [Serevite Ore](https://warcraft.wiki.gg/wiki/Serevite_Ore), [Draconium Ore](https://warcraft.wiki.gg/wiki/Draconium_Ore), and [Khaz'gorite Ore](https://warcraft.wiki.gg/wiki/Khaz%27gorite_Ore). Their rank 1/2/3 IDs are, respectively:

| Ore | Rank 1 | Rank 2 | Rank 3 |
| --- | --- | --- | --- |
| Serevite | 190395 | 190396 | 190394 |
| Draconium | 189143 | 188658 | 190311 |
| Khaz'gorite | 190312 | 190313 | 190314 |

The audit found 403 matching study rows, 113 rows with an unknown rank or ID, and four contradictions. Serevite records `dragonflight-20261031-10007`, `10008`, `10013`, `10014` in `2026-10-31T0727-hochenblume-writhebark-and-diamond-cohorts.jsonl` say rank 2 but carry ID 190395. Some notes infer the rank and none supplies completed casts. These rows do not currently supply yield estimates. They remain unchanged for research to resolve from original sources; no global ore-rank swap was applied. The command `python tools/audit_research_input_ranks.py` prints these findings and returns 1 for conflicts. This finding is separate from the passing runtime/build checks.

Wowhead tooltip responses did not expose the reagent-rank marker; the `quality` value was rarity and was not treated as rank confirmation. The recorded rank mappings come from the wiki's explicit Tier 1/2/3 External-links columns.

## Fresh compilation and regression comparison

Created an isolated `git archive` of the exact source commit. Ran `tools/evidence_to_baselines.py`, `tools/research_v3_to_baselines.py` without `--refresh`, then the official `tools/compile_itemdb.lua` with Lua 5.1. Ran every check from `tests/run.sh` in that clean copy, then `tools/package_addon.py`.

The fresh ItemDB matches both the source commit and version `.20` byte-for-byte. The v3 baseline records also match version `.20`, with no additions, removals or numerical changes: 89 v3 inputs, 443 material rows. The full compiler reports 285 processing records, 47 older rows superseded, and 137 research no-disenchant additions. Token coverage stays at 229 tokens/645 rewards. No coverage regression was found.

## Validation

| Check | Result |
| --- | --- |
| Source/snapshot selection and research policy | PASS — current owner handoff |
| Strategy/economic implementation | PASS — unchanged, prior audit retained |
| Fresh official compilation and exact database reproduction | PASS |
| Lua 5.1 syntax; database schema/distributions; TOC and load order | PASS |
| Every `tests/run.sh` check, including input-rank audit regressions and four packaging CLI tests | PASS |
| Unmodified Linux CI for the exact source commit | PASS — [run 41316027852](https://github.com/Voodoobrew101/Loot-Liquidator/actions/runs/41316027852) |
| Independent loading and optional dependencies | PASS |
| Manifest-only ZIP; one `LootLiquidator/` folder; CRC integrity | PASS |
| Extracted files vs. clean stage and source | PASS — every file compared |
| ZIP and extracted ItemDB SHA-256 | PASS |
| In-game testing | NOT RUN — owner check needed |

The packaging fix makes `--help` read-only even without an addon folder present; missing output paths show usage. Actual ZIP contents follow the same manifest policy. The ZIP contains no research, tests, build tools or third-party addons.

Local log: `../.validation/claude-session19-release.log`. Structured build facts: the `.build.json` beside the ZIP. Final ZIP and logs are preserved; disposable release staging is removed after verification.

## Remaining limits

The four contradictory source rows need research follow-up. Conditional unlock mapping, per-stat scaling and curio costs remain waiting as described in the handoff. In-game behavior and yield data were not changed by this maintenance session. Check version `.21`, existing ore values and ordinary token badges, then use `RELEASE-CHECKLIST.md` before CurseForge upload.
