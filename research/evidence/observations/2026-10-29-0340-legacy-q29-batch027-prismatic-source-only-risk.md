# Legacy q29 batch027 — Prismatic Leaper source-only model-risk reconciliation

**2026-10-29 03:40 PDT · no newly measured observations; no new independent source ancestry**

- Reused original 2023 Reddit source: https://www.reddit.com/r/woweconomy/comments/100anp2. Historical five fish/mill; four pigment families named; several commenters say fish-specific Resourcefulness does not trigger, but no denominator, skill, patch or controlled test. **Do not assert 0% current Retail savings.**
- Reused original Primer comment: https://www.wowhead.com/item=200061/prismatic-leaper. 15 fish / 3 explicitly completed mills -> 3 Serene R2 (198413), 5 Flourishing R2 (198416), 2 Flourishing R3 (198417), with no cast-by-cast histogram. This is an existing single original cohort; other nine ranks unreported, not proven absent.
- Reused secondary Wiki: https://warcraft.wiki.gg/wiki/Prismatic_Leaper. Only Serene/Flourishing listed; original participant additionally named Blazing/Shimmering. **No proof of 2026 selector whitelist.**
- Historical derivative source: https://github.com/Voodoobrew101/Loot-Liquidator/blob/main/GameData.lua at blob `1d47c4a961c5dc5af626e659f7d96d1490d3cf9e`, lines 1994–2010. Twelve rows 198412–198423 repeat `matRate=0.2462`, `amountOfMats=0.1723`, `minAmount=2`, `maxAmount=5`, with four family triplets of targetQuality 1–3.
- Arithmetic hypothesis only: 5×0.1723=0.8615 per five-fish-equivalent rank row; 4×0.8615=3.446 family-level, 12×0.8615=10.338 naive all-rank sum; 10.338/3.446=3. Prior q26 source-only note already described this arithmetic. This q29 review independently verifies exact twelve assigned source-line identities and prioritizes rank gating. **Neither 3.446 nor 10.338 is a measured 2026 E**.
- Reused ambiguous 2022 original comment: https://www.reddit.com/r/woweconomy/comments/yaxw94/a_look_at_dragonflight_milling reports “about 2k milled” and “3.8 herbs per mill”; output units and denominator remain ambiguous. Do not promote this to pigment E.
- No new output quantities, P(hit), positive min/max, or 2026 skill multipliers; all assigned numeric fields unknown. Fish-specific Resourcefulness is a cost-side mechanics question, not a production-yield increment.

**Next original dataset requirement:** 2026 Retail fish-specific 5-fish operation IDs, all output rank IDs per completed cast including zeros, actual casts, Resourcefulness input refunds, effective skill, profession talents/gear, build.
