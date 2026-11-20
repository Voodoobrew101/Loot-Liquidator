The compiler emits dense integer lists with Lua list constructors so Lua 5.1
allocates compact array storage. Sparse integer maps retain explicit keyed
constructors and their existing length behavior. The frozen legacy reference
block retains its original keyed encoding and byte checksum.

The current-main comparison uses commit `96df9772b`, including the shared
profession baseline engine and all 1,494 source records. Every compiled key,
value, value type and table length matches the pre-change runtime: 243,857
tables and 936,812 scalar values. Source evidence and model coefficients are
unchanged; the generated diff changes constructor syntax.

Measurements use actual embedded Lua 5.1 (`lupa.lua51`), 64-bit Windows and
minimal offline game API stubs. Each startup candidate runs in a fresh VM;
full garbage collection precedes each reading. These are offline retained
allocations, rather than measurements from a running WoW client.

| Measurement | Current main | Native lists | Reduction |
| --- | ---: | ---: | ---: |
| ItemDB load, fresh VM | 80,432.8 KiB | 74,776.7 KiB | 5,656.1 KiB / 7.03% |
| All 20 addon Lua files plus initialized ItemDB, fresh VM | 85,071.0 KiB | 79,414.9 KiB | 5,656.1 KiB / 6.65% |
| Additional data allocation with existing strings/compiler state shared | 71,876.2 KiB | 70,643.0 KiB | 1,233.2 KiB / 1.72% |

The fresh-VM startup saving is 5.52 MiB. The shared-state regression deliberately
measures a narrower allocation difference; it does not replace the isolated
startup comparison.

`tests/test_itemdb_memory.lua` checks all database values/types/lengths and
asserts smaller allocation against a reconstructed keyed representation.
`tests/test_itemdb_serialization_parity.lua` compares 1,393 actual source, profile
and target receipts, including 305,198 scalar fields and rendered tooltips.
It covers Disenchant, Gleaming Shatter, all nine crafting professions, all
available gathering contexts, native Loot/Use opportunity previews, and every
distinct exact-input processing operation in the current compiled sources. Both
tests run in the standard suite and accept an optional pre-change runtime path
for a direct current-main comparison.

To repeat the fresh-process measurements, extract the pre-change runtime into
a temporary file, then run each command in its own Lua 5.1 process from the
repository root:

```sh
git show 96df9772b:LootLiquidator/ItemDBRuntime.lua > /tmp/ItemDB-before.lua
lua5.1 tools/measure_addon_memory.lua /tmp/ItemDB-before.lua
lua5.1 tools/measure_addon_memory.lua
lua5.1 tests/test_itemdb_memory.lua /tmp/ItemDB-before.lua
lua5.1 tests/test_itemdb_serialization_parity.lua /tmp/ItemDB-before.lua
```
