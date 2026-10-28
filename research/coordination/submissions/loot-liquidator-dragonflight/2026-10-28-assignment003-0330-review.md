# Dragonflight research assignment 003 — 2026-10-28
**Worker:** loot-liquidator-dragonflight. **Assignment:** 2026-10-28-batch003-dragonflight. **Research branch only.**

## Coverage and evidence
- **40/40 assigned distinct keys examined** (11 Serevite R3 supplemental keys and 29 Draconium R3 historical TSM keys). These are first-pass worker submissions, pending master QA; do not claim central coverage advanced.
- **2 independent newly archived historical source cohorts**: 8,000 reported R3 Serevite operations from [January 10, 2023](https://www.reddit.com/r/woweconomy/comments/108782r), and 1,000 reported R2 Serevite operations from [December 12, 2022](https://www.reddit.com/r/woweconomy/comments/zkay8v). The former reports skill 283, 15% Inspiration, 22% Resourcefulness and 2,650 saved ore; the latter skill 171, 18% Inspiration, 3% Resourcefulness, Prospecting 25/25, Enterprising 10/30, Toolset 10/30 and 36 saved ore. **39 aggregate output totals** (14+25), zero per-cast histograms.
- Historical reference: [December 9, 2022 R3 Serevite 20,000-ore study](https://www.reddit.com/r/woweconomy/comments/zh53dd). It provides 4,000 five-ore equivalents, **not 4,000 observed casts**. Keep studies separate; patch/gear/skill and denominator semantics differ.

## Independent R3 comparisons
| Family | R3 ID | Dec 2022 E/5 equivalent | Jan 2023 E/cast |
|---|---:|---:|---:|
| Sundered Onyx | 192848 | 0.113750 | 0.113625 |
| Eternity Amber | 192851 | 0.363000 | 0.347750 |
| Alexstraszite | 192855 | 0.049250 | 0.061375 |
| Malygite | 192858 | 0.058000 | 0.051250 |
| Neltharite | 192861 | 0.058250 | 0.055625 |
| Ysemerald | 192865 | 0.055000 | 0.058875 |
| Nozdorite | 192868 | 0.178750 | 0.188125 |
| Illimited Diamond | 192871 | 0.007250 | 0.005375 |
| Fractured Glass | 192872 | 1.283000 | 1.286000 |
| Crumbled Stone | 192880 | 1.451000 | 1.434000 |
| Prismatic Ore | 194545 | not reported | 0.032625 |

These are **unconditional output quantities**. No aggregate total is a valid independent P(at least one), positive conditional minimum or maximum. The R3 output item IDs are matched to the legacy rank-ID family, not independently documented by the player posts. A historical study cannot automatically validate current Retail output quality or rates.

## Key findings
1. **8 assigned R3 Serevite gem-family rows** point at R1 family-anchor IDs (e.g., Sundered Onyx 192846) while the matched historical source yields R3 item IDs (e.g., 192848). The R3 measured E cannot be assigned to R1. Existing `low/high` clamps and `highRaw` are not verified R1 rates.
2. **3 assigned R3 Serevite byproducts** have direct material IDs (Fractured Glass, Crumbled Stone, Prismatic Ore). The January 2023 study reports respectively 10,288, 11,472 and 261 units over 8,000 casts, or 1.286, 1.434 and 0.032625 units/cast. Prismatic Ore may depend on specialization; source's exact node state is unknown. No current 2026 correction approved.
3. **29 assigned R3 Draconium TSM rows** pass mathematical `P*min <= E <= P*max` after `E=amountOfMats*5`, but the source lacks raw sample counts, current patch/skill/spec context, and output-quality transition evidence. R3 **Serevite** studies cannot validate R3 **Draconium** rates. Triplicate rank rows must not be summed as simultaneous outputs.
4. The R2 1,000-cast source independently reports **both R2 and R3 gems** from rank-2 input, so output quality is not identical to input quality. Its Vibrant Emerald R2 total **132** was annotated **13.4%** in the source; 132/1000 is **13.2%**. Preserve original counts and flag the typo.
5. Resourcefulness saves input reagents; it must not inflate gem yield. Inspiration was historical quality context, not a generic output-frequency multiplier. The mechanics registry has **no verified current-Retail numeric normalization coefficients**.

## Per-field confidence and QA
- 11 assigned supplemental rows: current-context `P=0, min=0, max=0, E=0` evidence confidence (not zero material values); 8 R1 quality mismatches and 3 historical direct-byproduct records blocked on current context. Historical Jan 2023 **E confidence 70**, Dec 2022 **E confidence 65**, but all raw P/min/max evidence confidence 0.
- 29 assigned TSM rows: `P=25, min=30, max=30, E=30` provenance-confidence scores, worst-field 25. None at >=90; **zero** approved current-Retail numerical corrections.
- QA: 40 unique assigned keys, 29/29 TSM arithmetic invariants passed, 39/39 source totals normalized from explicitly reported cast counts, positive integer raw totals, no invented per-cast hit counts or ranges, both JSONL objects structurally checked. **Full external JSON Schema validation and in-game tests not performed.**
- The user's one-baseline future `itemdb.lua` rule remains in force. No main, GameData.lua, addon files, PROGRESS, assignments or shared ledgers changed.

## Blockers and next targets
Current 2026 Dragonflight skill/gear/specialization and patch bridge; independent exact output-rank item IDs; original TSM sample denominator and per-cast histograms; recipe-specific runtime API checks. Next only master-assigned keys, prioritizing R3 Draconium unexamined outputs (e.g., `output-main:tsm:prospect:190311:192868:L1279`, `...:192872:L1283`, `...:192880:L1284`, `...:194545:L1285`) if explicitly assigned. No self-claimed overflow.
