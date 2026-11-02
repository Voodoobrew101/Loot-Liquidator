# Replace ATT with reviewed LootLiquidator data

The target is a standalone LootLiquidator catalog. ATT remains an optional research fallback until the relevant coverage is defined and verified. Alpha6 does not claim all ATT data has been gathered, and ships zero invented/approved real token entries.

## What belongs in our database

| Information | Collection/import route | Runtime source |
| --- | --- | --- |
| Possible token rewards and exchange costs | ATT relationship export plus direct merchant/open observations; independent review | `database/records.lua` → compiler → `ItemDBRuntime.lua.tokenRewards` |
| Item locations, difficulty, NPC/event identifiers, patch timeline and inherited requirements | Manual ATT source-context harvest; metadata and parent paths retained in export/staging | Research only until a reviewed source catalog and presentation are implemented |
| Class eligibility and no-disenchant exceptions | Existing independent DB2 snapshots; verify applicability | Existing class/restriction modules |
| Learned appearances and account collection state | Blizzard transmog APIs | Live Blizzard data, including when ATT is absent |
| Processing yields, drop probabilities, skill/bonus formulas | Existing reviewed research/mechanics pipeline | Existing ItemDB model; ATT links cannot supply these quantities |
| Auction prices and TSM's own tooltip block | TSM pricing | TSM, independent of ATT migration |

## Gather in game

1. Keep ATT enabled while gathering. Open the bags/banks containing relevant items. Run `/ll attcache` to explicitly harvest each candidate one at a time. This includes source contexts for ordinary equipment, not just token rewards. Known research candidate IDs and saved cache IDs supplement observed inventory IDs. No background whole-ATT database crawl or uncached bank redraw search is introduced.
2. Run `/ll tokenmigration` for progress. The update is bounded: legacy reward lists cap at 50, stored token lists at 600, and source metadata at 1,200 items, eight source groups and twelve parent levels. Metadata depth/size caps are also recorded. A hit, an empty result, an unqueried item and a capped result are different states. None establishes exhaustive Retail coverage.
3. Run `/ll attexport 1`, `/ll attexport 2`, etc. Copy every JSON page into a separate file. The page count is inside each export. Export promptly after a completed scan so pages describe the same snapshot. Metadata includes installed ATT version, client build, dates, queried relationships, raw costs/class/quest hints, ancestor contexts and limitations. Old caches without this metadata stay explicitly unknown. No player collection state or ATT implementation code is exported.
4. Also export `/ll tokenexport` pages for direct Blizzard merchant/open observations. Existing `att_*` migrated-cache rows remain ATT candidates; their old `1:1` placeholders are never treated as observed quantities.

The scanner operates on observed/requested items, not a defined complete ATT universe. Historical/seasonal items, unvisited sources, variants, unresolved symbolic links, incomplete caches and ancestor requirements must be tracked separately. Retries can refine candidates; repeated sightings are not independent yield samples.

## Stage and review

```
python3 tools/import_token_research.py att-page-*.json direct-token-*.txt \
  --output research/token-candidates.json
```

The importer reads plain exports; it does not execute SavedVariables Lua or ATT code. It preserves raw source snapshots and their SHA-256 document identities, stages distinct relationships, and reports missing pages, capped IDs and unresolved queries. All entries remain UNREVIEWED and ineligible for runtime. This script never edits `database/records.lua` or promotes approvals.

Review complete outcomes, exact builds and variants, all exchange costs and inherited class/faction/quest/reputation requirements against independent evidence. Approved entries go in the existing `tokenRewards` collection of `database/records.lua`. There is no parallel runtime source file. The shared compiler/client validator requires unique IDs, Retail/build scope, complete lists, independent approval, a named reviewer, confidence >=90 and two distinct evidence URLs. Unsupported nonempty requirements, incomplete exchange costs, duplicate/overlapping scope and yield/probability fields fail explicitly. ATT-derived entries must carry their MIT license text/attribution inside the compiled record. Confidence remains a review score, not a statistical probability.

The record contract is exercised with clearly synthetic examples in `tests/test_token_catalog.lua`; none is shipped as real data. Rebuild with `lua5.1 tools/compile_itemdb.lua LootLiquidator/ItemDBRuntime.lua`, then run `bash tests/run.sh`.

## Standalone behavior and retirement gates

Reviewed catalog entries resolve before checking ATT availability or its integration checkbox. Existing legacy ATT reward caches also work when the external addon is uninstalled, while retaining their unverified source label and the existing research-fallback toggle. Collection state still refreshes from Blizzard. Uncached misses return unknown without ATT; they do not become fabricated zero outcomes.

Remove ATT's OptionalDeps entry and live query/update controls only after:

- The relevant Retail token and source-metadata universe is written down and independently reviewed.
- All supplied export pages, source versions, cap/unresolved reports and variants are reconciled; no truncated cache is labelled complete.
- Required relationships and source-metadata features have reviewed standalone equivalents, including any conditional requirements that are currently rejected.
- A real client pass with ATT disabled covers token summaries, classes/alts, collection ownership, source metadata, ordinary equipment and item restrictions. Compare against the enabled-ATT results. Synthetic no-ATT tests establish routing only.

Do not copy ATT's current personal collection state into a static database or price a possible reward list as guaranteed output. Preserve source attribution when redistributing derived catalog material.

ATT's public repository is MIT-licensed. Reference examined: commit `b540d841c2d3e26850ea4e00b0ec7bd3e4ec1215`, <https://github.com/ATTWoWAddon/AllTheThings>. This pin documents the upstream review; it is not substituted for the actual version installed on a user's client. See THIRD_PARTY_NOTICES.md.
