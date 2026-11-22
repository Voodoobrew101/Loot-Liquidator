## Catalog and category cleanup, 2026-11-22

The runtime catalog now retains 659 referenced native item records and 40 full
recipe records. Unused item descriptions and recipe output/reagent catalogs are
omitted. Small recipe scope tuples retain specialization labels and native
capabilities needed when a real learned recipe is scanned or restored from saved
character data. Output quantities and identities come from that actual snapshot.

937 ordinary disenchant source records now use expansion, rarity, equipment type
and native level bands. They remain independent source cohorts with their original
numerical fields. No reviewed source established a genuine item-specific yield
exception. 22 duplicate lineages and 30 historical or unsupported cohorts remain
offline rather than being loaded as current gear overrides. The unused 937-item
no-disenchant observation payload and its warning scanner were removed; all 21,061
native prohibition flags remain.

Compared with the immediately preceding installed runtime, generated data fell
from 27,990,825 to 16,284,611 bytes. Fresh Lua 5.1 retained database memory after GC
fell from 68.80 to 35.65 MiB. These are offline database measurements, not a claim
about current in-game memory. Thirteen unaffected Milling/Prospecting/Craft
replays retain identical actual quantities, gold and formatted rows. Shared gear
models retain actual expected quantities and quote arithmetic; display estimates
never feed those calculations. All five Settings samples use the shared formatter.

## Repeated-use allocation cleanup, 2026-11-22

The remaining measured spikes were temporary work, rather than new retained
catalog data. Scope probes now copy only the top-level item/operation fields they
change. They no longer recursively copy a previous quote attached to item facts.
Each evidence evaluation reuses its target-profile calculation across its source
studies, while retaining independent source confidence caps and overrides. This
memo ends with that evaluation. Disabled or physically incompatible sources are
excluded before projection.

Ten cold evaluations of the actual 200-study Dragonflight epic armor category
allocated 104.60 MiB before and 41.76 MiB afterward. Tooltip helper/sort cleanup
reduced repeated actual saved-profile rendering allocation by about 55%, with
identical output in 200 before/after settings and item scenarios. Personal
disenchant aggregation no longer repeatedly serializes the same immutable input
context per cast or copies contexts it does not consume. One hundred actual
saved-profile lookups allocated 139.7 MiB before and 54.2 MiB afterward. Full raw
and public baseline exports remained byte-for-byte identical.

These measurements pause GC only in the offline tests to count transient
allocation. No garbage collector settings or forced collections were added to
the addon. Regression tests cover allocation, immutable evidence, source caps,
overrides, recording, sorting and the shared tooltip format.

## Bank refresh source reuse, 2026-11-22

A seven-minute client run still reached 398.5 MiB while using bank tabs and
moving gear, with visible 6-10 FPS drops. Memory also fell naturally to 107.2 MiB
with the Warbank open. This run demonstrates substantial temporary spikes; it
does not establish continuously growing retained memory or isolate every FPS cost.

Ordinary disenchant category sources now reuse their unpriced projection across
matching items. Final fusion, personal/imported observations, eligibility and
prices remain per item. Full character conditions, native rules, source identity
and output binding metadata guard reuse. Item-specific effects and reviewed
overrides retain their original path. The cache holds at most two scopes of 256
source projections, expires on access after five seconds and clears on normal
invalidation or database replacement.

Replaying 30 genuine Dragonflight epic armor items with the actual saved settings
reduced source projections from 6,000 to 200, temporary allocation from 121.95 to
42.93 MiB, and offline calculation time from 0.512 to 0.249 seconds. Bounded cached
sources cost about 1.8 MiB after GC. Every item's gold, material identity, expected
quantity, percentage, range, confidence and shared formatted rows matched the
immediately preceding installed runtime. These are offline workload results;
these results alone do not establish live FPS or memory improvement. The 36-check cache
regression and 46 other focused Lua test files pass. No database or saved data
changes are part of this fix.

The full subsequent client readout reached 467.1 MiB, then recovered to 90.2 MiB
and ended at 92.5 MiB. Four readings initially scrolled out of view; the complete
user-supplied series supersedes the partial observed peak of 209.9 MiB. BetterBags
reported 2,193 timed jobs, 11,031 ms total and 178 jobs taking at least 16 ms; the
worst took 106.3 ms. The category optimization therefore did not resolve the
remaining badge stalls or temporary memory peaks.

## Repeated badge quote cleanup, 2026-11-22

Ready output prices are now reused only inside one synchronous `Evaluate`
request, keyed by exact item ID and full item link. Settings, database and AH-fee
guards prevent cross-context reuse. Pending binding and vendor information is
retried; a known zero remains zero. Success and error both discard the request
table, so the next evaluation reads current prices. No persistent price cache or
alternative tooltip renderer was added.

Recorded Craft lookups now reject a different recipe or method before building
its study/context key. Coverage, allocations and observation aggregation remain
unchanged. The 400-entry BetterBags decision cache expires and evicts individual
old entries instead of clearing all entries at capacity. Its physical instance
fingerprints, pending-data retries and explicit refresh behavior are retained.

Actual saved-profile replays of all five reported slow items preserve actions,
gold, material fields and formatted rows. Evercore's underlying price queries
fell from 455 to 84 and native metadata queries from 587 to 121; Resonant
Crystal's fell from 75 to 6 and 103 to 20. Offline cold evaluations fell from
25 to 17 ms and 10 to 6 ms respectively. These use deterministic native/market
fixtures; they do not establish current client FPS or a memory ceiling. The cold
raid-token appearance API cost remains separate from these reagent calculations.
All 50 focused Lua test files pass, including three new regressions. Full raw
and public baseline exports remain byte-for-byte identical. No catalog data or
SavedVariables were removed or rewritten.

## Guild-bank work scheduling and appearance reads, 2026-11-22

The next client run sampled 94.0-346.9 MiB and 32-75 FPS, ending at 169.2 MiB.
Its later BetterBags report contained 2,666 timed jobs, 13,615 ms total and 172
jobs taking at least 16 ms. Token 47242 reached 219.3 ms. Workloads and report
durations differ from the earlier run, so these figures do not establish a
controlled overall improvement or a fixed memory ceiling.

Native guild-bank refreshes previously evaluated all 98 slots in one callback.
They now use a replaceable slot queue, yielding after eight jobs or after the
observed work reaches roughly three milliseconds. One individual lookup may
still exceed that budget. Before and after valuation, each job checks the shown
frame, bank mode, tab, button, link and stack count. Tab changes, closing the
bank and disabling guild badges cancel stale work. Valuation and tooltip
rendering use the existing shared functions.

Confirmed appearance ownership from the current native API now returns without
a redundant legacy API call when the appearance ID is already known. Unknown,
negative, mismatched and incomplete results retain their previous fallback
checks and source/appearance identifiers. No appearance-state cache was added.
Twenty targeted Lua test files pass, including 1,055 guild-queue assertions,
64 new appearance checks, existing token values/collection/alt behavior, and
the shared tooltip and price checks. Nine before/after appearance scenarios
preserve all three return values. Live behavior still needs checking after
reload; this does not claim to resolve a single long native API call.

## Follow-up live trace and unnecessary calculations, 2026-11-22

The next full live memory/FPS run after the guild-bank queue change recorded
77.0/68, 108.0/79, 84.3/72, 106.8/67, 166.0/34, 156.1/48, 370.2/50,
154.9/62 and 210.2/71 (MiB/FPS). Warbank remained open after the run, so
these readings cannot establish closed-bank recovery. The BetterBags report
recorded 1,632 jobs, 10,688 ms total and a 224.7 ms worst item lookup (47242).
The following timing probe was a different workload, not a before/after test.

The one-run live probe recorded 4,904 Evaluate calls (8,149 ms inclusive),
2,050 ConversionOptions calls (8,956 ms inclusive), 1,619 ProfessionCraftModel
calls (2,207 ms inclusive), 64 invalidations and 2,412 badge refresh requests
over 177.753 reported seconds. Direct selected-profile tooltip calculations
also call ConversionOptions outside Evaluate. These inclusive totals overlap
and must not be summed. TokenInfo took 416 ms across 9,801 calls in this run;
that does not prove the cause of the earlier single 225 ms stall.

The probe reported zero errors in its wrapped functions. The user also
reported execution-limit warnings naming BugGrabber without an originating
stack. Saved earlier logs contain Loot Liquidator calculations reached through
Pawn's private tooltip; those earlier stacks are supporting evidence, not an
attribution of the new warnings. The temporary probe restored its wrappers and
was removed from the installed addon and TOC. It remains only in offline
validation artifacts.

Five runtime files now address concrete unnecessary work:

- The registered tooltip callback skips Pawn's designated private scanner
  object only while its anchor is ANCHOR_NONE. Ordinary tooltips, pre-show
  tooltips, selected profession profiles and Pawn's anchored debug view retain
  the shared renderer and all material rows. In an isolated full-TOC replay of
  six actual item IDs and saved settings, private scans fell from six Evaluate
  calls/four ConversionOptions calls and 4.096 MiB temporary allocation to zero
  addon processing. Every public row, action, mean and gold value matched.
- TRANSMOG_COLLECTION events discard recommendation/token/badge decisions and
  priced display quotes while retaining profession contexts and numerical
  models. Covenant, profession, equipment, settings and evidence changes keep
  their existing invalidation scope. No caller breakdown was captured for the
  64 live invalidations, so their appearance-event share is unknown. In a
  matched offline two-pass replay at times 100 and 101, this avoided all 30
  model rebuilds and 913 source projections on the second 34-item mixed pass.
  Temporary allocation fell from 23.757 to 3.614 MiB. Twenty-four ordinary gear
  items fell from 17.366 to 0.897 MiB. Both variants used the same current
  binding guard, saved settings, native facts and fixture prices. Every action,
  gold value, numerical material field and shared tooltip row matched.
- Fixed profession recipe models skip an unused personal-record search in
  mixed and baseline-only modes. Personal-only notes and stochastic processing
  retain their original searches. Forty-five actual-item replay cases preserve
  gold, material numbers, notes, sources and formatting.
- Cached numerical models recheck native output binding/rank/family metadata.
  Hydration, replacement or in-place changes rebuild affected numerical policy.
  The existing valuation routine still obtains fresh output quotes. This adds
  metadata to existing cache entries without adding a new cache, native API
  queries, a longer lifetime or a larger limit.

Sixty-seven focused Lua test files pass, including 197 private/public-tooltip
checks, 82 fixed-recipe lookup checks, 52 invalidation checks and 38 binding
cache checks. Offline allocation and timing measurements are not live-client
performance claims. No forced garbage collection, new settings or persistent
calculated-data store was added. Profession snapshots continue to use the
existing SavedVariables database in WTF.
The five changed files were installed and all 20 addon files were verified
against the tested candidate. The first live run after reload sampled
93.3/29, 128.3/9, 99.7/8, 157.1/5, 180.7/4, 129.6/3, 184.9/5,
206.2/5 and 206.2/97 (MiB/FPS). Large equipment transfers from Warbank
into the backpack and guild-bank use were observed. Both windows were closed
by the final sample; closure throughout the last three samples is not
established. FPS recovered to 97 at the final sample and 94–98 on subsequent
screenshots. The severe 3–9 FPS bank slowdown remains unresolved. Sampled
memory peaked at 206.2 MiB in this run, without a continuously rising trend
across the whole series. Different workloads prevent attributing a causal
peak-memory improvement from these runs alone. The later badge report counted
481 timed jobs, 3,647 ms total, a 194.9 ms worst lookup (item 47242), 43 jobs
at least 16 ms, 16,131 repeated redraws skipped, one immediate cache hit and
zero queued jobs. Native guild-bank work is outside this BetterBags counter,
and no whole-client CPU breakdown was captured in this run. A one-minute
read-only C_AddOnProfiler sampling command was requested to identify that
remaining load; its results are pending. No further runtime changes were made
during or after this measurement. The saved BugGrabber log written at reload contained zero
errors, with restarted session numbering; that does not establish the absence
of unsaved live errors afterward.

## Hidden native frame duplication, 2026-11-22

The next live check used WoW's existing C_AddOnProfiler recent-average counters
without enabling legacy script profiling or installing another probe. The six
Loot Liquidator readings were 2.060, 0.247, 7.509, 15.095, 12.574 and 15.754 ms.
The final reported top three were BetterBags_AIO 96.782 ms, BankStack 43.211 ms
and Loot Liquidator 15.754 ms. These are rolling averages over 60 profiling
ticks, sampled every ten seconds. A Loot Liquidator value printed again in the
top-three list is the same reading and must not be counted twice. The complete
user-pasted report is preserved in the hidden-native validation receipt.

Installed BetterBags reparents the combined/default bag frames and optionally
BankFrame under a hidden parent. A child's IsShown remains true in that state.
Loot Liquidator's native adapter used IsShown for roots and pooled bank buttons,
so it could evaluate invisible Blizzard widgets in addition to BetterBags.
The BetterBags badge timer report does not include that native adapter work.

NativeBags now uses IsVisible, with an IsShown fallback for older adapters,
before scanning native roots/children and evaluating queued bank buttons.
Queued bank painting also rechecks visibility after evaluation. The guild-bank
root follows the same visibility rule. The adapter neither changes parentage
nor touches other addons' frames or API implementations.

The same change corrects the full-refresh selection: `fullPending and nil or
changedBags` always selected changedBags. An explicit branch now passes nil for
a requested full refresh, allowing settings/appearance updates and native
visibility restoration to revalue unchanged painted items. Ordinary dirty-bag
updates remain restricted to their bag IDs.

In a matched offline replay of six actual item IDs on six default-bag and six
bank-panel widgets, the hidden-ancestor case fell from 12 evaluations, 56 fixed
profession models, 1,380 output quote calls and 3.897 MiB temporary allocation
to zero evaluations and about 0.00074 MiB of harness allocation. Both visible
variants still performed the same 12 evaluations/56 models, with every action,
gold value, material number and formatted tooltip row matching exactly. Native
API availability and market prices were controlled fixtures, so this is not a
live FPS or market-price claim.

All 68 focused test files pass, including 82 new visibility/full-refresh checks,
1,055 guild queue checks and 1,054 modernization checks. An independent review
found no visible-native regression. Only NativeBags.lua changed in this step;
all 20 installed addon files match the tested candidate.

The complete post-reload one-minute memory/CPU run then recorded:

| Sample | Loot Liquidator MiB | Loot Liquidator recent ms |
| --- | ---: | ---: |
| 1 | 113.828 | 0.180 |
| 2 | 97.418 | 1.624 |
| 3 | 179.634 | 1.863 |
| 4 | 213.585 | 2.118 |
| 5 | 109.295 | 1.298 |
| 6 | 121.483 | 0.638 |

Warbank transfers, real public gear tooltips and the native guild-bank
Enchanting tab were observed. Memory reclaimed naturally after the fourth
sample; this series does not show continuously increasing retained memory.
It also does not establish a lower peak than every preceding different
workload. At the last slow-bank reading, BetterBags_AIO was 94.584 ms and
BankStack 23.574 ms versus Loot Liquidator 0.638 ms. The sustained low FPS
remained while those other addons had substantially higher attributed CPU.
The earlier rare 195 ms token lookup was not separately retimed and is not
claimed absent. All 20 source/installed hashes were verified again after the
live check; no additional runtime code changed during sampling.

## Badge continuation cooldown, 2026-11-22

After that live check, the owner questioned the extra delay before applying
badges. BetterBags jobs still use the existing maximum-eight-job batch and
observed three-millisecond work budget. The additional 60/200 ms cooldown
after a slow job, and 30 ms no-clock fallback wait, are removed. Unfinished
work now resumes with C_Timer.After(0) on the next frame. Pricing, instance
checks, cache policy, event coalescing and material rendering are unchanged.

The deterministic 60 FPS queue comparison used the same 16 cheap/6/16/195 ms
lookup fixtures. Fixed waiting fell from 720 ms to zero and simulated queue
completion from 1,001 to 284.3 ms; exact decisions, values, contexts and batch
grouping matched. Twenty cheap jobs without a timing API retained 8/8/4 job
batches, with simulated completion falling from 83.3 to 50 ms. These are queue
scheduling fixtures, not live FPS measurements. A synchronous 195 ms lookup
still blocks, and successive slow lookups can now affect successive frames.

Fifteen focused test files pass, including 93 new next-frame/budget checks.
Independent review found no correctness blocker. Only Badges.lua changed in
this step, and all 20 installed addon files match the tested candidate.

After reload, the complete six-sample run recorded memory 132.104, 156.330,
191.155, 116.108, 134.476 and 159.167 MiB. Loot Liquidator recent CPU was
0.667, 1.392, 1.462, 0.279, 0.463 and 0.246 ms. Memory reclaimed naturally
after the third sample. Other attributed CPU remained much higher:
BetterBags_AIO 104.719–160.232 ms and BankStack 12.432–66.259 ms. These runs
are different workloads, so no controlled percentage improvement is claimed.

The user also reported ten repeats of an execution-limit warning naming
BugGrabber, followed by its capture flood message. The stored database held
two warning entries without stacks or locals; the second was source-labelled,
matching BugSack's non-deduplicating report-import path. Its counter is a copy,
not evidence of ten additional independent errors. No normal Lua error or
Loot Liquidator stack was present. Read-only source review found a possible
report-callback reentry path but no evidence that it occurred. No third-party
addon, error filter, error-capture setting or reporting code was changed.

## Earlier storage-layout measurements

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
retained item-processing profile contexts, and every
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

## Runtime cache retention, 2026-11-21

The item-decision cache previously checked its 30-second expiry on reads but
never removed expired entries. Distinct bag, slot and stack-count signatures
therefore retained complete processing models until global invalidation.
Processing contexts also generated new model-cache keys on each refresh.

Decisions now expire during periodic cache sweeps and have a 256-entry limit.
Capacity eviction happens only when inserting a new signature. Processing
models replace refreshed generations under a stable context key, expire after
30 seconds, and have the same entry limit. Token results, which deliberately
bypass cache reads, are no longer stored in that cache.

A real compiled Draconium Prospect workload (item 190394, recipe 374627,
39 outputs, 2,400 changing bag/slot/count contexts at six-second intervals)
retained 456.512 MiB before the fix and 82.376 MiB afterward in fresh embedded
Lua 5.1 VMs. The latter remained within 82.376–82.377 MiB from 256 through
2,400 requests; invalidation returned it to 81.581 MiB. Every output quantity,
probability, range and calculated value matched between versions. These are
offline retained-memory measurements after full GC, not client memory readings.

Separately, immutable profession aura-ID sets are cached while live buff state
is still read on each relevant event. Fifty real two-profession fingerprint
reads allocated 37.5 KiB after the change versus 46,468.48 KiB before it. The
old allocation was reclaimable, so this addresses churn rather than the
decision-cache leak. No forced garbage collection was added to the addon.

`tests/test_decision_cache_memory.lua` covers real-source expiry, capacity,
cache hits at capacity, release on invalidation and unchanged processing values.
`tests/test_profession_aura_cache.lua` covers unrelated aura updates, live buff
gain/stack/expiration, operation scope and database replacement.
