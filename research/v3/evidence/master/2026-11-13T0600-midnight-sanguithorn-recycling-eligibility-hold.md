# Midnight Engineering Recycling — Sanguithorn Pigment input eligibility hold

**Reviewed (UTC):** 2026-11-13T06:04:21.716Z  
**Manager scope:** research-only original-source identity/eligibility checkpoint; candidate task T0024 (Midnight exchanges), downstream method comparison with T0045 milling. No item-to-material numeric measurement, no current Retail cast log, and no addon change.

## Distinct source finding

1. **Firsthand profession forum assertion (March 9, 2026):** Teishoku says *Sanguithorn Pigment* is the one pigment engineers cannot recycle, despite other pigments being recycled to supply Evercore. Primary original source: https://us.forums.blizzard.com/en/wow/t/why-did-sanguithorn-become-immediately-worthless/2268090 (post 5). This is an **eligibility assertion**, not a completed-cast report or a current-client verified negative event.
2. **Earlier same-author recipe reference list (February 27, 2026):** https://us.forums.blizzard.com/en/wow/t/engineer-recycling-only-gives-evercores/2259599 (post 2) includes *Argentleaf Pigment* and *Powder Pigment* -> Evercore with descriptive **1–3** output range, but omits Sanguithorn Pigment. Its omission is only supportive, **not independent corroboration** because the March claim is by the same author. The **1–3** is NOT a measured mean, chance, or input efficiency for Sanguithorn, and must not be copied to it.
3. **Scope tension with broader guide:** https://www.wow-professions.com/midnight/engineering-guide broadly calls crafted Midnight reagents recyclable and describes five input reagents per recycle and ~3 Evercore/Aetherlume at 30 Recycling KP (secondary approximation). The same guide cites Powder Pigment as a normal source of Evercore. Its generic "any" phrasing conflicts with a player-reported narrow exception; a tested current recipe eligibility list would be more authoritative than either. Do not silently turn generic guide permission into specific Sanguithorn eligibility.

## Exact candidate identities and unknowns

- Sanguithorn Pigment is a **two-quality family**, with item **245865** (quality rank 1) and **245864** (quality rank 2) per independent item pages: https://goldcap.gg/retail/us/items/245865 and https://goldcap.gg/retail/us/items/245864 ; item names verified at https://www.wowhead.com/item=245865 and https://www.wowhead.com/item=245864 .
- Teishoku's wording does **not** specify whether the refusal affects both item IDs, particular rank/recipe modes, the character's skill/spec/unlocks, or only the February–March 2026 build. The current November 2026 client result is **unknown**; no verified fail/success cast, input selector or tooltip was supplied.
- Positive comparison input family: Argentleaf Pigment **245803** quality rank 1, **245804** rank 2 (https://goldcap.gg/retail/us/items/245803 ; https://goldcap.gg/retail/us/items/245804). February table names it but again does not establish rank-specific yields or hit distributions.
- **No observed casts, output total quantities, histograms, P(hit), or current Gold EV** are authorized by these sources. Do not assign a zero yield to Sanguithorn on this forum claim alone. Do not assign the generic five-item recipe to an ineligible input without eligibility proof.

## Why this matters for gold decisions

Incorrectly treating cheap Sanguithorn Pigment as a valid five-input Evercore Recycling conversion could falsely recommend Engineering instead of auction/vendor/ink use; it is a **method-eligibility/context concern**, not missing AH prices or missing average units for an already verified Sanguithorn conversion. A different output family or specialization cannot be inferred from price.

## Recommended independent verification — no duplicate worker assignment

Request a screenshot/recorded successful or rejected **current Retail Midnight Engineering Recycling** recipe selection using both 245865 and 245864, including spell/recipe ID, input itemLink/quality, quantity, skill, Recycling KP/unlocks and game build; compare eligible Argentleaf rank IDs as a positive control. If true, record a rank-scoped eligibility exclusion with provenance rather than fabricating a zero-result numeric study. Implementation/usable-data-tooltips owner should exercise the actual offline engine/tooltip with synthetic prices to ensure unsupported Sanguithorn Recycle is not advertised; this manager **did not execute that fixture**.

**Evidence outcome:** one new, narrow, source-backed potential exclusion/identity flag; **0 new estimator-eligible numeric cohorts; 0 new tested gold decisions.** This note is not a gameplay verification and does not modify the immutable 4df9ae8 numerical snapshot.
