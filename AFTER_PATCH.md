# After a WoW patch: review, validate, then decide

Verified 2026-11-09 against [main b6610848604f68f8f3b40834397b79ce53eb8fb5](https://github.com/Voodoobrew101/Loot-Liquidator/commit/b6610848604f68f8f3b40834397b79ce53eb8fb5), addon version 0.12.19. This guide replaces the old branch-specific automatic refresh/upload procedure. It does not authorize merging, publishing a release, or uploading to CurseForge. See [release status](RELEASE-STATUS.md) and [pending Retail QA](docs/retail-qa.md).

## Start with an explicit scope

1. Record actual main/research heads, open PRs and active work before choosing a change. Use an isolated branch based on current main unless the owner explicitly chooses a candidate. Do not assume the historical `LootLiquidatorclaude-V0.1` branch is the current destination.
2. Identify the exact Retail version, build and interface from reliable current sources and the client. Do not extrapolate an interface number or update it merely because this guide's example is old. Check `LootLiquidator/LootLiquidator.toc` and `LA.targetInterface` in `Core.lua` together. Do not bump the addon version for a documentation-only cleanup. `.github/workflows/addon-version.yml` manages versions after main merges; any separately requested version edit must keep TOC/Core consistent.
3. Run baseline validation before substantive changes. Inspect Blizzard API changes against actual addon calls, especially Settings, tooltips, bags, professions and transmog. Add regressions for changed behavior. Never claim in-game testing from fixtures.
4. Select each data update explicitly. Record source URL, exact build/commit, source hashes, transformations, rejected rows and intended destination. Review flavor, input/output rank, study identity/overlap, denominator/coverage, context, requirements and costs before admitting data. A changed count or failed pin is a reason to investigate, not permission to update an assertion until it passes.

## Patch-data generator inventory

These are existing offline paths, not a claim that all patch data is generated or current for the live game. Paths below are repository-relative. The complete mandatory check list lives in [tests/run.sh](tests/run.sh).

| Area | Existing tool and committed source | Output / limitation |
| --- | --- | --- |
| v3 research | `tools/research_v3_to_baselines.py`; `database/research/v3-snapshot/SNAPSHOT.json` pins `4df9ae8b1359d934828e4d0e6d39a9a4dba26fae` | `database/research-v3-baselines.lua`, including token/no-disenchant adapters. New research branch evidence is not automatically bundled. |
| Evidence and Midnight yields | `tools/import_midnight_enchanting.py` reads `research/mechanics/midnight-enchanting-yields-2026-11-06.json`; `tools/evidence_to_baselines.py` reads `research/evidence/v3` | Staged evidence then `database/evidence-baselines.lua`; identities/coverage and applicability still require review. |
| Recorded output identities and reviewed Recycling | `tools/capture_observations.py` reads `research/integration/measured-captures`; `tools/recycling_capture_baselines.py` uses the explicitly reviewed `2026-11-07-recycling-200-casts` capture and its coverage review | `database/capture-observations.lua` is identities, not yield rates; `database/recycling-capture-baselines.lua` is the separately admitted exact-context cohort. Other archived captures are not automatically numeric baselines. |
| DE categories, reference calculations, skill/quality, specialization | `tools/disenchant_categories.py`, `tools/reference_calculators.py`, `tools/skill_quality_to_rules.py`, `tools/specialization_effects.py`; their versioned sources under `database/` and `research/mechanics/` | Separate generated Lua inputs; regenerating them does not discover or validate new coefficients. |
| Profession UI catalog | `tools/import_profession_catalog.py`; `database/wago-professions-70783.json` | `LootLiquidator/ProfessionCatalog.lua`. Importer pins `12.1.5.70783` and expects its named DB2 CSV tables; not an arbitrary-build or ItemSparse importer, and not yield/rating formulas. |
| Pinned ATT token research | `tools/att_token_references.py`; `database/research/att-exchanges-snapshot.json`, `att-lost-snapshot.json`, `att-wayward-snapshot.json` and their hashed source archives | `database/att-token-baselines.lua`. Parses bounded source literals without executing ATT. Runtime ATT installation is not required. Preserve attribution and review exact requirements/costs/variants. |
| Token observation staging | `tools/import_token_research.py` | Stages direct/archived export evidence for review; does not automatically promote approvals or edit runtime records. Possible rewards are not probabilities. |
| Runtime database | `tools/compile_itemdb.lua`; `database/records.lua` and the committed source/generated inputs | `LootLiquidator/ItemDBRuntime.lua`; do not hand-edit the compiled artifact. Frozen legacy/TSM inputs remain guarded, not regenerated from market prices. |
| Build provenance and test ZIP | `tools/stamp_build_info.py`, `tools/package_addon.py` | Packaging stamps `LootLiquidator/BuildInfo.lua` in the working tree and includes only TOC-declared files. A ZIP is a test artifact, not a release decision. |

### The ItemSparse gap is still open

`LootLiquidator/WagoClassEligibility.lua` and `database/sources/DB2Restrictions.lua` identify their source as user-supplied Retail ItemSparse **12.1.7.70493**. No `tools/generate_from_itemsparse.py` exists in this main tree. The profession catalog importer above does not generate these files.

A future ItemSparse refresh needs a separately reviewed deterministic generator and the actual source CSV, with source/build hashes, schema validation, class-mask semantics, flag tests, stable ordering and before/after ID/count comparisons. Current flags are NO_DISENCHANT `0x8000`, Mill `0x20000000` and Prospect `0x40000`; verify their applicability rather than treating this note as permanent API truth. Preserve known-item regressions and explain deliberate build-pin changes. Do not silently hand-edit lists, invent missing IDs, or claim these sources were refreshed without the input. The missing generator is implementation backlog, not completed by this documentation.

### Research refresh is not routine patch validation

The existing opt-in command is `python3 tools/research_v3_to_baselines.py --refresh GIT-REF` (the script's default ref is `origin/implementation/five-agent-completion`). It replaces the pinned snapshot and rebuilds baselines. Use only after selecting and reviewing an exact fetched commit, not as a blanket patch-update step. Do not run it just to verify these docs.

The immutable research audit reference checked on 2026-11-09 is `8e845ab46cc55ba93828b39fe0073fb302d2f59a`; the bundled pin above is deliberately different. This is a dated reference, not a promise to track the moving branch head. Open PR52 and PR56 address future-refresh admission/curio issues and are not in main at this checkpoint. Other research identity, cost and applicability gaps remain. Neither a green research workflow nor successful generation is approval for a wholesale snapshot refresh. Preserve raw source evidence and inspect the semantic diff, not only file checksums.

The older `database/research-itemdb-source.json` pins the separate legacy ItemDB research input to `d7bece6a30c411125e47c44a1b9932f505924e55`; it is not the v3 snapshot manifest. Do not substitute one pin for the other.

## Deterministic validation without a data refresh

Run from the repository root, using Python 3 and native Lua 5.1/luac5.1 on `PATH`:

```bash
bash tests/run.sh
```

The checked-in `tools/lua51-shim` uses Lupa's embedded Lua 5.1, but its `lua5.1` wrapper does not support the `lua5.1 -` stdin invocation used by the current skill/quality pipeline test. Putting that shim on `PATH` alone is **not** a working full-suite substitute. Native Lua 5.1 is the CI path. If an existing environment uses a separately corrected stdin-capable Lupa wrapper, record that wrapper and dependency explicitly as a local validation limitation; it is not a repository fix or native-CI result.

The suite runs the existing generator `--check` modes, compiles ItemDB to a temporary directory and compares bytes to the committed artifact, tests frozen inputs and package structure, then runs the Lua/Python regressions and usable-data validation. It does not refresh research or fetch new DB2 data. The suite uses some fixed `/tmp/loot-*` fixture paths: serialize full runs sharing the same machine.

For an explicit deterministic compile check (also performed by the suite):

```bash
check_dir=$(mktemp -d)
lua5.1 tools/compile_itemdb.lua "$check_dir/ItemDBRuntime.lua"
cmp "$check_dir/ItemDBRuntime.lua" LootLiquidator/ItemDBRuntime.lua
python3 tests/validate_package.py
rm -r "$check_dir"
```

To build a local test artifact after committing the reviewed candidate, use a clean disposable checkout/worktree so the build stamp is not accidentally committed as a source edit:

```bash
python3 tools/package_addon.py dist/LootLiquidator-test.zip
```

Record the tested commit/tree, interpreter, full command results and ZIP manifest check. Inspect the expected BuildInfo stamp separately from source changes. Do not call the test package a release or commit generated provenance by accident. Do not install software or refresh external data merely to run a docs-only check when the existing environment suffices.

## Handoff and release decision

- Supply the diff, exact head, full validation result, generated-data comparison and known limits for independent review. Verify remote head and CI if publication is authorized; opening a draft PR does not authorize merge or release.
- Complete and record the [Retail QA matrix](docs/retail-qa.md) on the actual chosen candidate, including source toggles, current/offline/simulated profiles, missing data, token eligibility, recorder gaps, SavedVariables and bank performance. Existing captures and synthetic tests are not a new live pass.
- State failures and unrun checks explicitly. Keep unknown yields/probabilities and unsupported profile effects unknown rather than filling gaps for the patch.
- Ask for the owner's separate merge/release decision after review. CurseForge upload, GitHub release publication and changing release type are separate actions, not the automatic next step after producing a ZIP.
