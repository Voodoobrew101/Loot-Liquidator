# Loot Liquidator PR #20 build report

BUILD PASSED — verified pull-request candidate; no in-game QA performed.

- Version: 0.11.0-claude.22
- Source: fix/research-export-precision / PR #20, 5a00877c0ff14dbf39e14fafdefbaa9137f3b04e
- Base: main @ 905956d7597a4b79eda99873b9e6e4b50ef1b252
- Build timestamp: 2026-11-02T02:11:37.652296+00:00
- Research v3 pin: 9a22e2787ec133419bad9bce66d036219e2439a4
- Research ItemDB export pin: d7bece6a30c411125e47c44a1b9932f505924e55; source checksum verified.
- ZIP: LootLiquidator-v0.11.0-claude.22-2026-11-02-pr20-5a00877.zip
- ZIP bytes: 371060
- ZIP SHA-256: 34ef259625b931c6b9a0fe727cb233b63782bbc9f88f0a9341b6d12f264bcc07
- Runtime DB SHA-256: 8973189ac01a29605d116bee6c9970258180484b818c3ff978c608e1714bc9ef
- Archive files: 19

## Compilation and validation

PASS: regenerated baselines with `python3 tools/research_v3_to_baselines.py` and `python3 tools/evidence_to_baselines.py`.
PASS: fresh official compiler `/workspace/.loot-liquidator-tools/lua/usr/bin/lua5.1 tools/compile_itemdb.lua LootLiquidator/ItemDBRuntime.lua`.
PASS: full `bash tests/run.sh`, including Lua syntax, schema, runtime initialization, standalone loading, token validation, expected quantities, profession mechanics, packaging, and five new precision regressions.
PASS: generated baselines and runtime DB exactly match PR baseline bytes; zero record or coverage regressions versus that baseline.
PASS: git diff --check and clean source checkout after regeneration/tests.
PASS: runtime TOC file manifest, coherent load order, optional dependencies only, and production-only staging.
PASS: official packager, ZIP integrity, exact manifest, single top-level LootLiquidator folder, extraction, and SHA-256 comparison of every extracted file.
NOT RUN: World of Warcraft in-game QA.

## Strategy and research scope

Reviewed main's owner decisions and integration rules in claude/HANDOFF.md; the research v3 README/strategy; tools/research_v3_to_baselines.py, tools/evidence_to_baselines.py and tools/compile_itemdb.lua; and the active tests. The precision change preserves computed values and leaves runtime contradiction validation intact. Evidence sources, deduplication, probability/quantity separation, provisional confidence, unknown fields, conditional exclusions, and runtime schema remain governed by those existing audited paths.

Owner-selected input is PR #20 including its pinned research. The separately tested research branch 4290c80dcd4ab682f194cc68e45463eb3684f1bd is NOT included: compilation succeeds with the precision fix, but its client regression fails `manually disabled legacy yields stay off`. It is not a safely compatible replacement for this pinned build. No stale database was substituted and no validation was bypassed.

Known data limitations preserved by the tests: 113 unresolved input-rank identities and four known conflicts. Existing provisional/legacy evidence is not represented as independently measured data. No research evidence or repository branches changed during this build. PR #20 remains unmerged.

## Database coverage

```
Source records: 285
Primary records: 148
Legacy records: 137
Distinct numeric input items: 159
Distinct output items: 276
Numeric probability fields: 521
Numeric expected quantity fields: 782
Provisional records: 266
Token catalogs: 229
Mechanic rules: 0
Expansion 0: 3
Expansion 1: 1
Expansion 10: 49
Expansion 11: 49
Expansion 2: 6
Expansion 3: 4
Expansion 4: 2
Expansion 5: 2
Expansion 6: 4
Expansion 7: 11
Expansion 8: 2
Expansion 9: 15
Expansion unknown: 137
```

## Installation

Extract the ZIP into World of Warcraft/_retail_/Interface/AddOns/. The archive contains one LootLiquidator folder.
