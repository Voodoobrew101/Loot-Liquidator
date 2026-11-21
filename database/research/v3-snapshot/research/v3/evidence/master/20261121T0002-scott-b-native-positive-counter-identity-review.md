# scott_b original Enchantrix native source — independent identity/unit review

Reviewed UTC: 2026-11-21 00:02. Scope: **source-transcription identity only**, no new Retail operations, no numerical baseline or valuation approval.

## Pinned originals and research transcription

- Original source: [scott_b.lua](https://github.com/alex-berliner/wow_classic_de_table/blob/5918ca3e44f6e4bba9071731ab28be3189498001/dbfiles/scott_b.lua), section `EnchantedLocal`, original repository commit `5918ca3e44f6e4bba9071731ab28be3189498001`.
- Item identity/name index: [item_names.csv](https://github.com/alex-berliner/wow_classic_de_table/blob/5918ca3e44f6e4bba9071731ab28be3189498001/item_names.csv), same revision.
- Worker transcription: `research/v3/evidence/legacy/2026-11-20T2345-scott-b-original-positive-enchantrix.jsonl` on the research branch, blob SHA `20cef68c42b62eb8648dd2d27316c0788024862a`.

## Checks independently performed

Read the actual pinned raw Lua and CSV, parsed all 79 `EnchantedLocal` exact item-variant keys and their 85 semicolon-delimited material tuples, then parsed all 85 worker JSONL rows. All **85/85** original variant/output/hit/quantity/terminal tuples matched; **85/85** input names and **85/85** output names matched the original CSV (170 name-cell checks), and all item/variant keys were unique for each material tuple. No missing, invented or duplicate original tuple.

The 85 material records span **79 exact gear variants, 76 base item IDs and 8 output material IDs**. Pinned source and worker records agree on **90 material-positive sightings and 213 material units**. The source also has **35 `EnchantedItemTypes` grouped/type rollups**, but those are not new independent material-event cohorts and were not separately transcribed or counted here.

Every reviewed worker record explicitly uses `sourceKind=reference`, `casts=null`, `histogram=null`; the native `material:hits:units:0` last field is **not** a count of no-output operations. Positive sightings are not an all-disenchant denominator. Consequently these historical Classic counters do not establish Retail current-build eligibility, per-cast occurrence probability, unconditional expected output units, item-level/bonus/skill conditions, or gold decisions. Preserve exact historical variants, item IDs, raw counts and names as reference evidence only; do not reinterpret as current Retail measured P(hit) or independently weighted additional contributor datasets.

## Pipeline applicability and next gap

Inspected main `tools/research_build_review.py` and `tools/prepare_build_research.py` statically: automatic build review distinguishes uncounted reference rows from admitted observed cohorts and generates only in the build workspace at a specified research revision. This review does **not** establish that the current pinned build processed these 85 rows or their exact disposition. Original/worker source files unchanged; no generated addon database, compiler, Lua, actual resolver/tooltip, or live WoW tests executed in this run.

**Next actionable evidence:** independently completed **Retail** disenchant or prospect/mill operation ledgers including genuine zero-inclusive events and context (item variant, output rank, patch, build, skill, recipe, refunds). For scott_b specifically, re-reading the positive-only Lua cannot reconstruct missing completed casts or zeros; avoid recycling source checks. The Legacy worker retains T0042/T0047 scope and schedule.

Compared before writing: main `4190fe93cadfeda361445829750bb46d4fccc9f3`, owner implementation `3d667d053db587c91401cfed7ecc56862b8340c9`, research `2acb6ae5a58f6ef70f703ad15ea22aa3a8d58a21`. That research head had successful **Verify five-agent completion** CI (GitHub run [44839148227](https://github.com/Voodoobrew101/Loot-Liquidator/actions/runs/44839148227)); it predates this memo, and is not build/tooltip validation. Existing PRs #22/#23 were already closed without merge; no PR operations performed. No changes to production main, owner's three-pass implementation, worker evidence, research schedules, releases, or PRs.
