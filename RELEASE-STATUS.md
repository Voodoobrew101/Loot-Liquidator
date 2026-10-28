# Loot Liquidator — repository release / source status

_Last verified October 27, 2026 (Pacific)._

## Verified source on `main`

- `main` contains **27 individually tracked addon files** in the repository root.
- The complete 27-file set **exactly matches** the original `LootLiquidator-v0.9.70-Unified-Low-High-Processing.zip` using Git blob SHA-1 checks (byte-for-byte).
- `LootLiquidator.toc` identifies **0.9.70**.
- The latest ChatGPT-created **0.9.71-test** package is available in the Loot Liquidator project conversation, but **has not been applied to this repository**.
- The `research/processing-confidence` branch contains versioned data research and QA ledgers, **not a new released addon**. Do not overwrite game data merely by merging the research branch.

## Pending 0.9.71 test changes

Relative to the tracked v0.9.70 source, the v0.9.71 test package changes exactly these existing files:

1. `Badges.lua`
2. `ConversionEngine.lua`
3. `Core.lua`
4. `LootLiquidator.toc` (version becomes `0.9.71-test`)
5. `MIDNIGHT_MODEL_README.txt`
6. `Professions.lua`
7. `Settings.lua`
8. `StatYieldProfiles.lua`

It additionally contains `developer/README.md`, which is development-only material that should not be included in a public addon release by default. The other 19 existing addon files are byte-identical between the two packages.

## Integration checklist

- [ ] Stage and review the eight changed source files on a separate branch.
- [ ] Check real-profession skill detection vs manually configured simulated skill; low research fallback applies only when neither can supply usable conditions.
- [ ] Ensure tooltip probability and conditional integer yield bounds do not get confused with **unconditional decimal expected quantity** for gold calculations.
- [ ] Keep specialization/quality unlock restrictions; no arbitrary linear skill effect where the mechanic is unverified.
- [ ] Pass automated Lua 5.1 syntax and TOC file-manifest checks.
- [ ] Test in Retail WoW with real and simulated profession profiles.
- [ ] Only after review, approve merge to `main` and create a release package.

## Source checks

The proposed `.github/workflows/validate-addon.yml` workflow checks the TOC referenced paths and compiles top-level Lua files with Lua 5.1. These are **static checks**, not in-game behavioral validation or evidence that the research database has >=90/100 confidence.

## Safe branch conventions

- `main`: released or explicitly approved addon source.
- `research/processing-confidence`: ongoing data research, provenance and confidence audit.
- `maintenance/source-validation`: review of source validation workflow and synchronization status.

Never auto-merge research or test builds into released `main` without explicit approval.
