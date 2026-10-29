# Legacy q26 batch024 — source-only fish pigment-family and denominator reconciliation
2026-10-29 00:41 PDT; worker loot-liquidator-legacy; no new current Retail numeric measurement.

## Directly inspected sources and original units
- https://www.reddit.com/r/woweconomy/comments/100anp2 (Jan 1 2023 discussion, **reused URL, newly isolated claim**): participant says five Prismatic Leapers per mill and describes all four pigment families: Flourishing, Serene, Blazing, Shimmering. No output item IDs, per-rank counts, original completed-cast sample or skill context in that claim. Treat as qualitative family eligibility only. Thread also contains conflicting Resourcefulness claims, no controlled test.
- https://www.wowhead.com/item=200061/prismatic-leaper (Retail raw HTML checked 2026-10-29): original author Primer reports 15 fish, 3 completed casts, 3 Serene R2, 5 Flourishing R2, 2 Flourishing R3. Output IDs 198413,198416,198417 independently match GameData and pigment identity. **One author, three historical output totals, not three independent cohorts.** All other pigment outputs unreported; do not infer their true absence from a three-cast sample.
- https://warcraft.wiki.gg/wiki/Prismatic_Leaper (secondary, read 2026-10-29): lists only Serene/Flourishing. This is incomplete relative to the four-family player account; does not prove other outputs impossible. No current Retail recipe selector.
- Retail item pages https://www.wowhead.com/item=198418, https://www.wowhead.com/item=198419, https://www.wowhead.com/item=198420 (Blazing Pigment R1/R2/R3), https://www.wowhead.com/item=198421, https://www.wowhead.com/item=198422, https://www.wowhead.com/item=198423 (Shimmering Pigment R1/R2/R3): item identity only, not fish-specific drop proof.
- Retail raw HTML https://www.wowhead.com/item=189143 and https://www.wowhead.com/item=190311: no source-matched Prospecting loot tab found; exact gem-rank P/E remain unknown. Checked 2026-10-29.
- Historical TSM-derived GameData.lua source lines 1999–2009, 1244,1281–1282: identity and source-stated rates only, **not original cast logs**.

## Historical arithmetic with uncertainty
`Primer total = 3+5+2 = 10 pigments / 3 completed five-fish mills = 3.333333 total pigments per mill`.
`TSM hypothetical family rate = 5 × 0.1723 = 0.8615; four families = 3.446; 12 ranks = 10.338`.
`3.446 / (10/3) - 1 = 0.0338` (+3.38%). Similarity is descriptive, not a validation or calibrated confidence score. Exact-rank P(hit) cannot be inferred from aggregate output totals, nor can positive bounds or max skill be inferred from historical generic 2–5. Do not reuse the previously corrected "3.8 herbs per mill" as pigment E.

## Negative conclusions and source selection lessons
- No Wowhead milling/prospecting loot-tab raw count/outof available on these three Retail inputs at extraction time; avoid hourly re-fetch until source changes.
- The two-family Wiki summary should not be interpreted as an exhaustive recipe whitelist; verify with original players and client.
- Source-level family agreement does not establish rank-specific 2026 P/E or independent source ancestry.
- Resourcefulness input savings must never be treated as extra produced pigments; fish-specific eligibility is disputed in historical comments.
