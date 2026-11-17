# Ceari Titanium Ore historical ID enrichment — source/replacement integrity QA

Date checked: 2026-11-07 UTC. **Research-only audit; no new observed operations, no current-Retail recommendation, no estimator/addon/client execution.**

## Original and checked evidence
- Worker source: [Ceari, Titanium Ore (WotLK Classic, patch 3.3.3)](https://www.wowhead.com/wotlk/item=36910/titanium-ore), a report of **200 Titanium Ore** prospected.
- Original 17 output lines: `research/v3/evidence/legacy/2026-10-31T0140-titanium-five-original-cohorts.jsonl`, ids `legacy-20261031-1063..1079`, `studyKey=wowhead-ceari-titanium-200-patch333`.
- New worker file: `research/v3/evidence/legacy/2026-11-07T2043-titanium-output-id-enrichment-adamantite-original.jsonl`, ids `legacy-20261107-90001..90017`. First 16 supply exact outputItemID mappings via `replaces`, not new source measurements; row 90017 is a *different*, Adamantite-to-Golden-Draenite source with casts unknown.
- Read actual `research/v3/tools/build_estimates.py` current research-branch blob `0b09b553fef4214af8aaa93f1c85061956643711`, lines 82–97: the loader gathers `replaces` target IDs globally, filters those originals before applying corrections.

## Independently executed read-only checks
A programmatic pairwise comparison of both original and new JSONL files found:
1. **16/16 one-to-one, distinct replacement IDs**; all targets exist in the original historical file.
2. Each replacement retains original `studyKey`, source URL, method `Prospect`, input `36910`, original `outputName`, `casts=40`, and original `totalQuantity`; each old mapped `outputItemID` was null and each new one is non-null.
3. The seventeenth original output `legacy-20261031-1079` remains **unreplaced**, properly: **Titanium Powder 46849, 25 units** already had exact ID. Thus the original one-cohort record remains **17 distinct material outputs**, not 16 or 33.
4. Source-reported aggregates across the same source cohort: **85 gem units** (sum of 16 named gems) and **25 Titanium Powder units** (the seventeenth material), **110 total reported output units**. These are material quantities **across one shared cohort**, not 110 independent trials. Forty is the source's **200 nominal ore / 5 ore per prospect** accounting equivalent, not a separately observed click/refund log. Raw positive hit counts, zeros, quality ranks, character skill and Retail patch applicability remain unknown.
5. The new standalone Adamantite `legacy-20261107-90017` reports 7 Golden Draenite over five unspecified-size stacks, with `casts=null`. It cannot be folded into this Titanium cohort or turned into a mean/hit probability.

**Scope:** This checks per-record replacement semantics against the current Python loader and verifies structural data identity using fetched source evidence. The script, compiler, deterministic audit, compiled ItemDB, addon valuation, synthetic-price formatter and live WoW were **not** run. It does not independently confirm source-linked itemLinks or current Retail eligibility. No original evidence/worker files were changed.

## Decision / next engineering priority
Preserve the 17-output historical cohort without counting 16 enriched lines as a new experiment, and keep the derived denominator provenance. Before using these as current Retail actionable quantities, check source epoch/eligibility and cross-source item-ID confidence, then execute isolated v3 rebuild and actual-engine tests with synthetic prices; obtain a recent itemLink/rank/skill/refund-stamped Retail recorder export for cross-patch validation. The unrelated, earlier 382-Elementium cross-file double-count threat remains a separate higher-priority dedup regression, not fixed by this QA.
