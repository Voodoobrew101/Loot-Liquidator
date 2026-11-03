# Loot Liquidator War Within worker — queue 24, batch 022

**Date:** 2026-10-28. **Assignment:** `2026-10-28-batch022-war_within`. **Actual assigned scope:** 35 explicitly authorized **Dragonflight overflow** stable keys (War Within home scope not self-claimed). **Source:** live `research/coordination/assignments.json` queue revision 24; pinned GameData blob `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`.

## Outcome

- **35/35 exact assigned GameData lines checked**, matching the pinned blob and output IDs; 30 Dragonflight Prospect and 5 Dragonflight Mill rows. Distinct input IDs: `190312,190313,190314,190394,190395,190396,191460,191461`.
- **140/140 current-Retail exact-context numeric field slots unknown** (dropChance, positive-only yieldMin/yieldMax, zero-inclusive expectedQuantity). No fabricated zeros or transferred rank probabilities. **New legitimate mappings: 0; verified current-Retail numeric fields: 0; corrections admitted: 0.** Existing TSM min/max columns preserved only as source references, not verified rank-specific bounds.
- Exact five-unit recipe vectors: prospecting spell `374627` consumes five ore; milling spell `382981` consumes five herbs. The profession/recipe family is supported; output quality-rank eligibility, skill and specialization remain conditional/unverified.
- **35/35 raw `matRate > amountOfMats`**, but **35/35 pass** the conditional invariant `P*min <= E <= P*max` under the unproven alternative `P=matRate; E=5*amountOfMats`. This spans **30 prospecting and 5 milling** rows. Example Khaz'gorite `190312 → 192858`: P=.2, hypothetical E=.2045, bounds 1–3. Hochenblume `191460 → 198422`: P=1, hypothetical E=3.5, bounds 2–5. **Do not promote this algebraic fit into four-field evidence**: TSM's original units/denominator remain unverified.
- **Rank-alternative valuation risk:** all three `191460 → 198421/198422/198423` source rows copy `matRate=1`, `amountOfMats=.7`, `min=2,max=5`. Adding hypothetical E=3.5 for each rank gives **10.5 pigments per five herbs** and triples the family value, inconsistent with a 2–5-total-pigment family interpretation. For `191461`, the two assigned rows share the same issue and the third family rank exists in GameData but was **not** claimed as an assigned key. Model ranks as conditional alternatives, not independent guaranteed drops.
- **Primary source reuse without duplication:** original Wowhead commenter **Bugy** already indexed for Draconium cohorts also published two Khaz'gorite rows, each labeled amount 100 and averages such as .058 per ore. A literal 100-ore denominator yields fractional implied unit totals (5.8), whereas 500 ore (100 five-ore operations) gives integer totals. This is a useful **denominator ambiguity**, not proof of 100 actual casts; original sample date, ore rank and output rank are unknown. See source-only reconciliation.

## Evidence and lineage

- [Pinned GameData source](https://github.com/Voodoobrew101/Loot-Liquidator/blob/main/GameData.lua) — historical TSM-derived source, **derivative**, not 35 independent samples.
- [Dragon Isles Prospecting](https://www.wowhead.com/spell=374627/dragon-isles-prospecting) — five-ore spell and Bugy **same-author** Khaz'gorite subgroups; no additional independent-author credit.
- [Dragon Isles Milling](https://www.wowhead.com/spell=382981/dragon-isles-milling) — five-herb spell.
- [Shimmering Pigment](https://www.wowhead.com/item=198422/shimmering-pigment) — Hochenblume family comments, not rank-specific measurements.
- [Dragon Isles Inscription guide](https://www.wow-professions.com/guides/dragon-isles-inscription-leveling-guide-dragonflight) — 2–5 pigment family-level range; secondary guide, not original casts.

## QA and handoff

Checked all 35 exact line IDs and quality fields against pinned GameData, validated unique keys and nonnegative source values, and tested both raw semantic conflict and hypothetical five-input positive-yield invariant. No prior q21–q23 stable keys reused. Master batch021 QA accepted source-only work but rejected treating historical family/rank transfers as 2026 measurements; preserved those rules. Source-memory read before re-fetch prevented double-counting Bugy as a new author. No unverified TSM probability or output rank is promoted. No changes to main, production Lua/TOC, canonical registry, master ledgers, assignments, or source-memory cache.

**Next master decision:** Treat q24 keys as first-pass audited; assign new disjoint missing material/selector keys. Highest-value unresolved inputs: `190312/190313/190314` rank-matched prospecting, `190394/190395/190396` prospecting, and `191460/191461` Hochenblume pigment ranks. Seek 2026 Retail zero-inclusive actual cast histograms with skill/spec/gear, exact output IDs/ranks, and direct original TSM unit documentation. Avoid revisiting Bugy absent author clarification or patch evidence.