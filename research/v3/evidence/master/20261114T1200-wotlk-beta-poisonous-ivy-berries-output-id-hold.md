# Coordinator source-identity correction — WotLK beta Poisonous Ivy Berries 43557

Verified at 2026-11-14T12:00:04.789Z UTC against the current research head. **One historical beta item-identity field, zero new source casts, zero current Retail gold decisions.**

## Original/cohort linkage
- The legacy worker's original-source row `legacy-20261114-481014` in `research/v3/evidence/legacy/2026-11-14T1154-original-wrath-beta-milling-hit-and-zero-cohorts.jsonl` quotes Wowhead commenter **204361**, source [Dusky Pigment comments](https://www.wowhead.com/wotlk/item=39334/dusky-pigment). For **Wrath beta build 8905**, author says **8 completed dusky-tier mills**, **4 Poisonous Ivy Berries** units. This remains one already-recorded historical cohort, not a new study. Herb identity within the stated herb tier remains unspecified, and output hits/zero-inclusive histogram remains unknown.
- Exact named **historical beta output ID = 43557**, independently recovered from the item-indexed [WotLK Wowhead Poisonous Ivy Berries page](https://www.wowhead.com/wotlk/item=43557/poisonous-ivy-berries), which labels the exact item and its rare milling description. [Warcraft Wiki's item page](https://warcraft.wiki.gg/wiki/Poisonous_Ivy_Berries) explicitly classifies it as **removed before Wrath's beta concluded**. This is an **identity match only**; indexing a removed item in a modern database does **not** establish live item availability or Retail-valued output eligibility.
- Cross-check against the source's beta build 8962 follow-up: that commenter says the uncommon output reverted to **Verdant Pigment**, corroborating the need to isolate beta 8905 instead of treating 43557 as a stable live output.

## Disposition
1. **Resolved:** previously null historical beta-only `outputItemID` for the named source row is **43557**. Do **not** mutate worker-owned original evidence; worker may add a linked append-only correction with `replaces` at their own checkpoint.
2. **Not resolved:** input herb ID(s), source operation-by-operation output occurrences, 0/1/2 histogram, full skill/build/client context. Four units across eight operations is an output total, **not four hit casts**.
3. **Scope:** pre-release **beta-8905 historical only**; quarantine from current Retail ItemDB/valuation/tooltip. Historical lookup and price sites do not establish current eligibility.
4. **Tests:** source-page/worker-record textual cross-check only. No addon runtime, synthetic prices, Lua tests, active Retail character or new compiled data tested.

## Highest-priority live-data follow-up
Continue distinct queue **T0005/T0039/T0045** original Midnight per-operation source receipts (ranked itemLinks, completed casts, refunds, zero-inclusive results, skill/unlocks). No repeated beta searches unless an original conflicting ID or build-specific mechanic appears.
