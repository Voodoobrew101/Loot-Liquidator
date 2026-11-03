# Immutable source mapping erratum — TWW Mycobloom → Apricate Ink false direct milling outputs
**Discovered:** 2026-10-29 00:20 PDT. **Owner:** loot-liquidator-war-within. **Queue:** 26. **Action:** QA handoff only, no source file overwrite.

## Erroneous source assertion
`StatYieldProfiles.lua` lines ~80–81: `millGroup({210796,210797,210798},{222616,222617,222618},...)` labels the three output IDs as Nacreous Pigment ranks. This incorrectly associates `210796→222616` and `210797→222617` with milling. The 3rd `210798→222618` is a real Nacreous Pigment ID but it is **rank 1**, not rank 3.

## Correct identities and evidence
- `222615/222616/222617` = Apricate Ink R1/R2/R3, separately crafted using 20 Distilled Algari Freshwater + 5 Luredrop Pigment + 10 Nacreous Pigment; https://www.wowhead.com/spell=444222/apricate-ink and https://thewowdb.com/item/apricate-ink-222615/ .
- `222618/222619/222620` = Nacreous Pigment R1/R2/R3, as linked by the original Wowhead milling comment https://www.wowhead.com/item=224802/orbinid-pigment .
- Actual pigment output quality is determined by effective skill, with 0–252 / 253–504 / 505+ bands claimed in a historical community comment. Do not infer deterministic rank matching from herb rank. Thus **reject** the two Apricate output tuples; do not auto-promote untested substitute pairs.

## Severity and corrective recommendation
**P0 invalid output identity, P2 potential gold recommendation contamination.** Master should exclude both false tuples from staged itemdb, audit `millGroup` output family ID validation and ensure economic engine cannot price separately crafted Apricate Ink as a free milling byproduct. Preserve original source for immutable audit trail. Master owns any canonical, production or compiler changes. No current-AH profit flip claimed.
