# Midnight q27 Batch 025 — 32 Crushing rank/selector leads and new firsthand rank-context evidence
**Research date:** 2026-10-29 01:14 PDT. **Branch:** `research/processing-confidence`. **Worker:** loot-liquidator-midnight. **Assignment:** `2026-10-29-batch025-midnight`, queue revision 27. **Research-only; master owns itemdb and ledgers.**

## Actual result
- **32/32** disjoint assigned leads audited: **16 candidate uncut-gem item IDs × 2 Glimmering Gemdust output ranks**. These are **UNADMITTED possibilities**, not 32 confirmed conversions.
- **New independently established exact selector mappings: 0**; **new compiler-admitted mappings: 0**; **new exact pair-level P/min/max/E numeric fields: 0**; **current-Retail gold-ready fields: 0**. No zero substituted for unknown.
- **Four new source contexts reviewed** (Blizzard forum March 21, Reddit March 23, Reddit April 18, third-party game-record recipe candidate September 29), **two previously indexed source URLs reused** (Wowhead spell/Method, and March 12 Reddit with March 18 follow-up); one earlier Cardinalai 480-gem cohort explicitly reused, not independent.
- A defensible **family-level tooltip positive yield lead of 1–3 dust per completed three-gem operation** has multiple source anchors, but **none of the 32 output-rank-specific min/max fields is filled**: selector whitelist and actual rank eligibility remain unproven. No tooltip P is inferred.

## P0 — correct recipe economics and scope
The Retail spell `1231132` says “Crush 3 Midnight gems into dust,” with **Dusk-Shrouded Stone ×1** shown as a reagent; its Salvage Item Crafting Data effect has value **3**. This is a **multi-reagent recipe**, not a one-gem destroy or three-gems-with-free-stone transaction. Source: https://www.wowhead.com/spell=1231132/midnight-crushing (Retail, checked 2026-10-29; spell added 12.0.0).

Exact nominal cost is **3 × selected eligible gem item price + 1 × selected eligible Dusk-Shrouded Stone price** before actual verified Resourcefulness savings. Stone rank substitution **242788 vs 242789** and whether all 16 exact gem IDs are selectable remain **UNKNOWN**. A secondary Method guide says individual gems can also be crushed to obtain stone, but that statement is not a verified second spell or free output of `1231132`; keep it separate from this recipe. Do not count input refunds as extra Gemdust.

The source ledger identifies these exact candidate gem IDs and qualities; the 2026-09-29 third-party build-12.1.0.69933 recipe listing corroborates **242553/242723 as two Sanguine Garnet quality choices** and **242620/242621 as two Gemdust quality choices** in a **gem-cutting recipe 1230462**, *not* in Crushing. It establishes item identity/quality families, **not** Crushing selector eligibility: https://www.wowdayday.com/wiki/entry/profession:jewelcrafting:recipe:1230462.

| Candidate gem family | Rarity | R1 input | R2 input | Candidate dust ranks | Exact salvage whitelist |
|---|---|---:|---:|---|---|
| Sanguine Garnet | uncommon | 242553 | 242723 | 242620 / 242621 | selector unverified |
| Amani Lapis | uncommon | 242554 | 242722 | 242620 / 242621 | selector unverified |
| Harandar Peridot | uncommon | 242607 | 242720 | 242620 / 242621 | selector unverified |
| Tenebrous Amethyst | uncommon | 242606 | 242721 | 242620 / 242621 | selector unverified |
| Flawless Sanguine Garnet | rare | 242613 | 242724 | 242620 / 242621 | selector unverified |
| Flawless Amani Lapis | rare | 242612 | 242727 | 242620 / 242621 | selector unverified |
| Flawless Harandar Peridot | rare | 242610 | 242726 | 242620 / 242621 | selector unverified |
| Flawless Tenebrous Amethyst | rare | 242611 | 242725 | 242620 / 242621 | selector unverified |

## P1 — four independent numeric fields, quality-only candidates
Every assigned key has `dropChance=null`, `yieldMin=null`, `yieldMax=null`, `expectedQuantity=null`, with separate field blockers and no synthetic cast count. Exact rank-specific Gemdust output selection may depend on effective skill, input gem rank and stone rank; it is **not justified** to assign simultaneous probabilities to both quality ranks.

**Family-level display lead (NOT per-rank promotion):** Method (2026-03-05) says any gem variety/quality yields **1–3 dust**; firsthand 2026-03-21 Blizzard forum commenter says even three blue gems can yield **1 dust**; firsthand March 23 Reddit players report **1**, **2**, and **3** dust in Crushing. These are different authors/contexts, but not a zero-inclusive, per-input-rank, per-output-rank cast study. Keep 1–3 as a conservative, source-anchored **family fallback candidate only**; do not assert it is a measured max-stat profile. Sources: https://www.method.gg/guides/midnight-jewelcrafting-profession-guide ; https://us.forums.blizzard.com/en/wow/t/why-is-jewelcrafting-so-incredibly-expensive/2277117 ; https://www.reddit.com/r/woweconomy/comments/1s1dtuh/jc_prospecting_is_atrocious/.

**Rank-dependent output qualification:** A March 18 follow-up within an already indexed March 12 Reddit thread reports displayed effective Crushing skill **255** against a displayed **440** target and explicitly notes the role of **R2 gems plus R2 stone**. This is firsthand UI-context evidence for ingredient quality mattering, **not** a measured 440 universal cutoff or a proof that a particular assigned pair yields rank 2. Source: https://www.reddit.com/r/woweconomy/comments/1rrn6of/resourcefulness_in_crushingprospecting/ (same URL/source lineage, new commenter/subcohort; do not count as a new independent dataset).

**Additional negative:** April 18 firsthand player reports crushing **three Eversong Diamonds** can produce just **one** Gemdust, consistent with rarity not guaranteeing a higher yield. Diamond is outside the 16 assigned gem inputs; this is context, not a newly admitted assignment or new numeric field: https://www.reddit.com/r/wow/comments/1sp0dax/jewelcrafting/.

## P2 — gold decision risks
- **Reagent omission:** costing only one gem, only three gems, or ignoring the stone can reverse the auction-vs-crush recommendation. This is a material, structural risk; no AH price or live decision flip measured.
- **Output rank double-count:** Gemdust R1 `242620` and R2 `242621` are alternative quality outputs, not proof of two concurrent dust stacks. Avoid adding both at full value.
- **False denominator:** Cardinalai's previously archived 480 gems / 160 stone / 330 dust with 40.7% Resourcefulness is **mixed-gem aggregate**, not a per-item or per-output-rank zero-inclusive histogram. Do not convert 480/3 into observed completed casts unless stone/refund context is independently verified.
- **Tooltip/economic isolation:** family 1–3 is **never** an EV midpoint, P(hit) or economic expected quantity; no method-selection promotion.

## Source learning / next exact IDs
New forum and Reddit first-person reports support family positive bounds and the possibility of blue/diamond low dust outcomes, but **do not resolve exact selectors or rank-specific output**. Avoid refetching Cardinalai or Method as if new; keep author and publication/observation dates distinct. The next high-value experiment is to record in-client recipe selector acceptance for each of **242553,242723,242554,242722,242607,242720,242606,242721,242613,242724,242612,242727,242610,242726,242611,242725**, stone `242788/242789`, and whether `242620/242621` output rank changes at measured skill. Capture exact **three-gem + one-stone** reagent vector, completed casts, per-cast output rank and count, resource refunds, skill/spec/patch; do not assume identical rank output across all inputs.

**Master handoff:** 32 leads remain unadmitted; 128 pair-specific numeric slots remain unknown. One new family-level 1–3 display lead and one reused-source rank/stone skill context are research-only; master alone decides if any future exact-context tooltip fields qualify. Production, master coordination and hourly schedule unchanged.
