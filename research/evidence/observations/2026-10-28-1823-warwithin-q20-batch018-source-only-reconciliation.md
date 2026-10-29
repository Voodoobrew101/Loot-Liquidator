# Source-only reconciliation — q20 War Within worker (assigned overflow)
This is **not a new independent experiment** and is intentionally Markdown rather than a duplicate canonical observation JSONL. No observationID or measured-field coverage credit is claimed.

## First Flower — original reused mass-cast cohort
- Original author: BullDozzer; published March 7, 2022; original source: https://www.reddit.com/r/woweconomy/comments/t8lubc
- Input item 187699, reported 4,000 First Flower; recipe 359490 **Mass Mill First Flower**, 20 herbs per cast; author explicitly reports 200 mass casts.
- Outputs: 173056 Umbral Pigment 972; 173057 Luminous Pigment 1,031; 175788 Tranquil Pigment 1,984.
- Historical mass-cast means: 4.86, 5.155, 9.92 units respectively. These are unconditional means **for the reported 20-herb mass operations**, not for standard five-herb milling.
- Unknown: per-cast zero-inclusive hit histograms, positive conditional bounds, character skill/stats, 2026 Retail patch bridge. Source status: REUSED; derivative Wowhead comments are same original author/data.
- Assigned TSM row `187699→175788:L1932` has min=2/max=3; this is a **different, unverified operation context** and cannot be overwritten with 9.92.

## Dragonflight Serevite ranked output references
- Original game spell: https://www.wowhead.com/spell=374627/dragon-isles-prospecting (five Dragon Isles ore per cast).
- Existing original R2 Serevite cohort: https://www.reddit.com/r/woweconomy/comments/zkay8v ; existing beta R3 skill comparison: https://docs.google.com/spreadsheets/d/1B_CjPU0AUlJkbogauPTdo0W4dUZiP1hxZ8KMZX7qp3Q/edit?usp=sharing
- Reuse only for context; neither supports exact 2026 R1/R2/R3 outcome probabilities for all assigned target ranks.
- Source alternative warning: 28 ranked rows carry duplicated family `matRate` and `amountOfMats` across three output quality ranks; no simultaneous three-rank valuation.

## Deterministic source-semantic invariant
For positive integer outputs under one consistent completed-cast denominator, `E[units] >= P(units >= 1)`. Every one of the 35 assigned TSM rows has raw `matRate > amountOfMats`; hence those raw labels must not be assigned directly to the four independent P/E fields without a verified source conversion. This does **not** assert a bug in TSM itself.
