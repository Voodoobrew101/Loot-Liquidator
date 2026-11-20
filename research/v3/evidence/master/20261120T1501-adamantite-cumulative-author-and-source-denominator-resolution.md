# T0051 — verified original 29,865 → 48,315 Adamantite cumulative lineage (2026-11-20 15:01 UTC)

**Independent original-source resolution, not a Retail cast study or addon validation.** Previous research manager review left the author and 29,865-versus-48,315 relationship unresolved. The original Reddit discussion now resolves both directly.

## Original sources reopened

1. [2021-07-27, original 29,865 ore report](https://www.reddit.com/r/classicwow/comments/ospt2y/prospecting_results_for_3k_and_30k_adamantite_ore/), author **u/GuildLeaderCali**. Its author's top-level table/comment reports 29,865 ore prospected and thirteen material output totals, including **5,973 Adamantite Dust**.
2. [2021-08-19, another user's thread with GuildLeaderCali's comment](https://www.reddit.com/r/classicwow/comments/p71mrp/the_casino_of_tbc_dont_gamble_kids_prospecting/), comment by **u/GuildLeaderCali** (NOT the thread OP u/Dodgemyshred). The commenter says **"To date I have prospected 48,315 ore"** and lists the corresponding thirteen material totals, including **9,662 Adamantite Dust**. This is an explicitly *cumulative later update by the same source author*, not an independently sampled 48,315-ore cohort or 18,450-ore separately reported batch.
3. [2021-07-27 cross-post](https://www.reddit.com/r/woweconomy/comments/osu2fp), by the same author, also repeats the older 29,865 ore snapshot.

The 48,315-ore original appeared as a **comment** inside someone else's 513-stack experiment, not the result of that thread's main author. Never conflate **u/Dodgemyshred's 2,051 logged prospects** with **u/GuildLeaderCali's cumulative table**.

## Record and unit checks actually performed

- Read all **13** rows in `research/v3/evidence/legacy/2026-10-31T0843-adamantite-29865-original-study.jsonl`, pinned blob **310dc9f335ad9c44781c8826d479f022f11e41f7**. All identify the 29,865 source, with `casts=5973` and `inputsPerCast=5`. `casts` is computed from 29,865/5, **not** an independently archived sequence of completed operations. The **13/13** table percentages agree with `output units ÷ 5,973 × 100`, rounded to two decimals.
- Read **13** source percentage rows in `research/v3/evidence/legacy/20261107T1701-adamantite-48315-and-tbc-disenchant.jsonl`, pinned blob **c0d0e7d2dc4d5a3179daae9dbd0451d0cf0f7bcb**, and **13** same-source rows in `research/v3/evidence/legacy/2026-11-10T0442-adamantite-48315-original-reddit.jsonl`, pinned blob **26e0fab6f49ddd46e03f025a0149cd3ab0b4d833**. All **26/26** source percentage rows agree with `output units ÷ (48,315/5) × 100`, rounded to two decimals; this is arithmetic **per nominal five-ore equivalent**, **not independently observed P(at least one output in a cast)**.
- The later update's **48,315/5=9,663 nominal equivalents** and **9,662 powder units** differ by one, a source discrepancy that remains unresolved. Do not invent one lost cast, refund or omitted powder unit.
- Previous [four-copy review](20261120T1408-adamantite-four-copy-source-cohort-review.md) established that the four 48,315 transcription sets contain identical thirteen output-ID/total pairs (52 rows), not four cohorts. This review **adds verified original author and cumulative relationship**, superseding its prior unknown-author/independence diagnostic.

## Reversible source-metadata correction

The original 29,865 raw evidence records stay unchanged. Appended exactly **13** file-scoped `castsBasis="countedFromInputs"` records to `research/v3/corrections.jsonl`, one per original record ID. This makes the arithmetic provenance explicit in the existing estimator's supported `castsBasis` contract. It does not alter any output totals, ranks, source URLs, input quantities or `percentMeaning`, and does not turn those percentages into observed hit counts. Do **not** add 29,865 and 48,315 as two independent studies or re-transcribe the same evidence. The larger report is the author's cumulative replacement in source interpretation; retaining earlier raw evidence is mandatory.

## Remaining admission boundary and tests

Both reports concern **2021 Burning Crusade Classic**, not measured 2026 Retail conditions; contemporary Retail profession/recipe/eligibility applicability still requires review. Source output unit ratios are not the same thing as observed hit probability. The main `tools/research_build_review.py` pipeline is an automatic row review, not standalone scientific approval. This run independently reread source HTML and reviewed repository rows and the source-derived correction; **did not execute** `tools/prepare_build_research.py`, `tools/research_build_review.py`, actual Lua, synthetic-price engine/tooltip, or live WoW. The current environment's Git CLI cannot reach GitHub to fetch the full exact-revision build workspace.

**Next:** run pinned main build admission/valuation regression after checkout of exact latest research SHA; assert 29,865 and 48,315 snapshots are not weighted as independent cohorts, that the 48,315 source does not borrow u/Dodgemyshred's 2,051 real casts, and that TBC Classic context cannot silently masquerade as verified Retail. Escalate any adapter/context defect through the separate implementation workflow, not a routine research PR.
