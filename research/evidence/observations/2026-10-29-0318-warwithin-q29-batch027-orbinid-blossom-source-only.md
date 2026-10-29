# q29 b027 — Orbinid and Blessing Blossom milling: source-only evidence, NOT a cast dataset
**Retrieved/reviewed 2026-10-29. Scope: six q29 assigned exact keys, no other worker's keys.**

## P0 recipe and identity
- Pinned `GameData.lua` lines 265–276: `gd.mill[210802]` through `gd.mill[210807]` are **empty** 10-herb candidate blocks, not output observations. Source: https://github.com/Voodoobrew101/Loot-Liquidator/blob/main/GameData.lua
- Curated provisional itemdb rows retain rank-1/2/3 candidate pairs Orbinid `210802/210803/210804` → Orbinid Pigment `224800/224801/224802`, and Blessing Blossom `210805/210806/210807` → Blossom Pigment `224803/224804/224805`. This is an item-identity and candidate mapping cross-check, **not** proof of exact same-rank milling under a specified skill.
- Retail Khaz Algar Milling spell `444181` consumes **10 herbs per operation**. Source: https://www.wowhead.com/spell=444181/khaz-algar-milling. Recipe fact, not a cast count.
- 2024-08-10 Method guide explicitly identifies Orbinid→Orbinid Pigment and Blessing Blossom→Blossom Pigment, three output ranks, and says output quality depends on herb quality, skill and knowledge. It also claims input rank does not increase quantity. Source: https://www.method.gg/guides/the-war-within-herb-milling-and-pigment-guide. This is a **reused secondary guide**, not a cast dataset.

## P1 new source-context lead (no numerical promotion)
- **2024-11-02 original Reddit discussion**, source https://www.reddit.com/r/woweconomy/comments/1gi024f/, contains a commenter reporting that while producing rank-2 pigments, rank-1 herbs give **approximately 11 pigments per ten herbs**, whereas rank-2 herbs give **approximately 13**. This is a **first-person historical qualitative rate comparison**, not a verified experiment with stated actual completed operations, herb item ID, exact output item ID, sample count, specialization, equipment, concentration, Resourcefulness or patch build. The author identity/cohort independence relative to prior August/September 2024 discussions was not established. Do **not** attribute the figures to Orbinid or Blossom, or treat them as per-cast E or exact tooltip bounds.
- **2024-08-28 Wowhead profession guide comment** reports milling these four families and says output is roughly 12 pigments, with quality affected by milling inputs. Source: https://www.wowhead.com/guide/the-war-within/professions/inscription-overview. No exact herb/output rank, denominator or skill; this is a separate *unquantified source lead*, not 12 exact-rank records.
- Reused original LotzBoi comment on https://www.wowhead.com/item=224802/orbinid-pigment describes a Mycobloom example of 4–6/5–7/6–8 pigments for hypothetical skill increments. Its stated example is **not six Orbinid/Blossom exact-rank positive-outcome histograms**. Do not inflate maxima, infer P(hit), or assign those ranges to these six tuples.
- Reused 2024-08-31 discussion https://www.reddit.com/r/woweconomy/comments/1f5rby5 contains inconsistent same-period anecdotes (including 11–15, 7–13, rank and skill effects), reinforcing need to stratify by actual output quality and mechanics epoch. It is already in source-memory and is **not** a new independent cohort.

## P2 invariants and source limitations
- The six exact-pair `dropChance`, `yieldMin`, `yieldMax` and unconditional `expectedQuantity` remain **unknown/null** (24 fields); all tooltip-only P/min/max remain **unknown/null** (18 display slots). Unknown is not zero.
- A reported per-ten-herb average, even if precise, does not supply zero-inclusive actual completed-cast E without cast denominator and Resourcefulness/refund context; it cannot supply P(hit) or positive min/max.
- Different input and output ranks are possible under sufficient skill, so summing all three output-rank alternatives as guaranteed simultaneously would inflate gold valuation.
- Pinned `GameData.lua` has no per-output TSM numeric rates for these six empty candidate blocks. **No quantitative TSM mismatch or real AH recommendation flip is established.**
- Neither the secondary Method guide nor the original 2024 anecdotes bridge 2026 current-Retail mechanics. Do not apply a universal skill coefficient or call 2024 publication date a measurement timestamp.
- Source-only Markdown is deliberately not an `observation.schema.json` numerical cast observation: no real completed-cast dataset exists in these sources.

## Exact next evidence required
For each `210802→224800`, `210803→224801`, `210804→224802`, `210805→224803`, `210806→224804`, `210807→224805`: 2026 Retail patch/build, exact herb/output IDs and quality, number of **completed** ten-herb operations, zero-inclusive per-operation output histogram, effective skill/knowledge/equipment/concentration and Resourcefulness/refunds. Record a separate row per skill/rank cohort. Reconcile source author/cohort ancestry before awarding independent corroboration.
