# Loot Liquidator 0.11.0-claude.20 — automated build report

**BUILD PASSED** for the owner's requested working branch and pinned research policy. Needs an in-game check before public release.

Built November 1, 2026. ZIP: `dist/LootLiquidator-v0.11.0-claude.20-2026-11-01.zip`.

- Size: 370,371 bytes; 19 manifest-declared files in one `LootLiquidator/` folder.
- ZIP SHA-256: `7271727cd7a07081f0948c66a5ef6fb5b3b4dbd7239aa00c311708cc4cbbb3ca`.
- ItemDB SHA-256: `8ed3446a3eb1d9afc9a8524c7a61323471999dcacdd9b25d62925a92d7459f23`.
- Source branch: `LootLiquidatorclaude-V0.1`.
- Source commit: `fd43c0da0b68aa1368b294999bb4e0e04a799957`.
- Research snapshot: `implementation/five-agent-completion` at `9a22e2787ec133419bad9bce66d036219e2439a4`.

The owner explicitly paused research and the handoff says to keep this snapshot. No other branch was merged, no research refreshed, and no original evidence changed. The source selection and freshness policy follow those instructions instead of the compiler skill's general request to find newer research.

## Research and compiler audit

Read the active `claude/HANDOFF.md` decisions and tasks, the pinned research [README](https://github.com/Voodoobrew101/Loot-Liquidator/blob/9a22e2787ec133419bad9bce66d036219e2439a4/research/v3/README.md), and [strategy](https://github.com/Voodoobrew101/Loot-Liquidator/blob/9a22e2787ec133419bad9bce66d036219e2439a4/research/v3/strategy.md), especially S5–S13. Inspected the pinned calculator, `tools/research_v3_to_baselines.py`, `tools/compile_itemdb.lua`, the token/no-disenchant adapters, and runtime valuation in `ConversionEngine.lua` with their tests.

The build uses real studies for v3 yields; reference/TSM values and the re-imported old disenchant table are not counted again. Source identity deduplicates copied studies, old epochs count less, mixed batch sizes are left out, and conditional unlock-only drops stay out of ordinary baselines. Inferred chance/quantity fields stay provisional with reduced confidence under the owner's current handoff policy. Gold valuation multiplies expected quantity by price once and divides by inputs per cast; it does not multiply the drop chance into an unconditional average again. Resourcefulness stays in input savings, and no new scaling or Multicraft coefficients were introduced.

The new gem identity mapping is restricted to explicitly sourced names and stated quality ranks: [Ysemerald](https://warcraft.wiki.gg/wiki/Ysemerald) and [Neltharite](https://warcraft.wiki.gg/wiki/Neltharite). Unknown ranks remain unknown. The research files and calculator on disk are unchanged.

## Fresh build and regression comparison

Built from a clean `git archive` of the source commit in a separate workspace directory. Ran the official workflow there:

1. `python tools/evidence_to_baselines.py`
2. `python tools/research_v3_to_baselines.py` (no `--refresh`)
3. `tools/compile_itemdb.lua LootLiquidator/ItemDBRuntime.lua` with embedded Lua 5.1.
4. Every check in `tests/run.sh` through the local Windows runner.
5. `python tools/package_addon.py <ZIP path>`.

Generated ItemDB is byte-identical to the source commit. Compared with the pre-session baseline, v3 still has 89 inputs and 443 material rows, with no records added or removed. Only prospecting records for Serevite 190394/190396 and Prismatic Ore 194545 changed, as expected from the gem correction. The compiler reports 285 processing records overall, 47 older research rows superseded, and 137 research-only no-disenchant additions. Token coverage stays at 229 tokens and 645 rewards. No unexplained coverage reduction was found.

## Verification

| Check | Result |
| --- | --- |
| Authoritative branch/snapshot selection | PASS — owner handoff policy |
| Compiler/source and economic calculation audit | PASS within the current handoff policy |
| Fresh evidence conversion and official ItemDB compile | PASS |
| Generated database reproduction and regression comparison | PASS |
| Lua 5.1 syntax; database schema/identifiers/distributions | PASS |
| All checks from `tests/run.sh` | PASS in clean local build |
| Unmodified Linux CI suite | PASS — [run 41315171004](https://github.com/Voodoobrew101/Loot-Liquidator/actions/runs/41315171004), exact source commit |
| TOC, load order, runtime references, standalone loading | PASS |
| Optional dependencies; no bundled third-party addons | PASS |
| ZIP manifest, one top-level folder, CRC integrity | PASS |
| Extraction and every extracted file vs. stage/source | PASS |
| Archive and extracted ItemDB SHA-256 | PASS |
| World of Warcraft client testing | NOT RUN — owner check needed |

The Windows runner redirects only test temporary files and preserves LF on Lua output. It intercepts Lua `os.exit` so the scaling audit cannot terminate the remaining checks. The unchanged Linux CI independently confirms the suite passes. Local logs are in `../.validation/claude-session18-release.log`; structured build facts are beside the ZIP as `.build.json`.

## Known limits and next checks

Conditional-drop unlock mapping, per-stat scaling, and curio exchange costs remain waiting for research as documented in the handoff. The pinned strategy's open S19 questions Dragonflight input ore rank mappings; this separate issue remains unconfirmed, and no ore rank mapping was guessed here. Confidence penalties for derived estimates are heuristic under the existing owner policy. This session adds no claim of calibrated confidence or in-game validation.

Install the `LootLiquidator` folder from the ZIP. Check version `.20`, Serevite prospecting with separate gem prices, and an unrelated ore's tooltip. Follow `RELEASE-CHECKLIST.md` before uploading to CurseForge.
