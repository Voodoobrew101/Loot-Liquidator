# Dragonflight q26 Batch024 — milling rank grouping evidence (research only)
Date: 2026-10-29. **No new original cast histogram or current Retail economic values.**

## Source and provenance
- https://www.wowhead.com/news/crafting-work-orders-are-here-wowhead-economy-weekly-wrap-up-251-329620: Samadan 2022-10-30 quotes Liqourice5's **single original author** October 22, 2022 Dragonflight beta milling report. Original https://www.reddit.com/r/woweconomy/comments/yaxw94/a_look_at_dragonflight_milling/ is deleted. Beta claim: 5 herbs per mill; **2–5 total pigments**, modeled 3.5 average, herb→single pigment family, quality determined by skill with 125/250 thresholds for recipe difficulty 250, input quality skill contribution +0/+31/+63, illustrative Inspiration bonus +83.3. No raw pigment-per-cast histogram, no current Retail patch bridge; article and deleted original are **not two independent studies**.
- https://www.wow-professions.com/guides/dragon-isles-inscription-leveling-guide-dragonflight: separate secondary Dragon Isles leveling guide also says five herbs give 2–5 pigments. It is not an independent measured cast study.
- https://worldofwarcraft.blizzard.com/en-us/news/23876529: Blizzard's original Dragonflight profession announcement explicitly describes an added **random positive skill roll** and Inspiration. No numeric law for that roll on these exact milling recipes; simple 125/250 deterministic output-rank thresholds are an illustrative beta model, not a 2026 probability.
- https://www.method.gg/guides/what-dragonflight-herbs-do-you-need-to-mill-to-get-each-pigment: September 2023 family mapping agrees Bubble Poppy→Serene and Writhebark→Flourishing, but qualitatively suggests skill can affect quantity, unlike 2022 beta's fixed 2–5. This needs matched observations, not a fabricated coefficient.
- https://www.wowhead.com/item=200061/prismatic-leaper: existing indexed original Primer comment reports **15 fish = 3 completed mills** with pooled 3 Serene R2 and 2 Flourishing R3. It cannot establish per-cast hit probability or the two assigned outputs 190322 / 198412. No new independent sample.

## Skill/quality grouping plot inputs (model only)
Beta illustrative selector Q1 if skill <125, Q2 if 125≤skill<250, Q3 if ≥250. Inspiration +83.3 shown solely as illustrative historical bonus; hidden positive random skill and 2026 mechanics are **excluded**.

| Input | Herb rank | Beta input skill bonus | Base skill 100 no-proc / proc | Base skill 200 no-proc / proc |
|---|---:|---:|---|---|
| Bubble Poppy 191469 | 3 | +63 | Q2 / Q2 | Q3 / Q3 |
| Writhebark 191470 | 1 | +0 | Q1 / Q2 | Q2 / Q3 |
| Writhebark 191471 | 2 | +31 | Q2 / Q2 | Q2 / Q3 |
| Writhebark 191472 | 3 | +63 | Q2 / Q2 | Q3 / Q3 |

These are predicted quality groups, NOT sampled P(hit) or gold E. Validate by plotting independent actual zero-inclusive five-herb casts against exact input ID, output ID/rank, skill, Inspiration proc, specializations, patch and random-skill proximity. Do not use group count as independent-source count.

## Potential gold-overvaluation invariant
Pinned GameData.lua blob 1d47c4a961c5dc5af626e659f7d96d1490d3cf9e: 12 assigned herb rank rows each show `matRate=1`, `amountOfMats=.7`, `minAmount=2,maxAmount=5`. If all three ranks are priced as simultaneous outputs, 3×5×.7=**10.5 pigments** per 5 herbs versus one family-wide 5×.7=**3.5**. This is a **potential 3× naive-summation overvaluation**, not a demonstrated production defect. Fish 200061 has 12 rank-family pigment rows at .1723; naive 12×5×.1723=**10.338** versus 4 family rows ×5×.1723=**3.446**. Fish selector and current yield unverified. Resourcefulness reduces input costs; it is not a pigment multiplier.

## Disposition
Twelve 2–5 **tooltip-only** candidates are source-anchored historical family bounds, already present as TSM reference bounds; no newly filled missing yield cells. Source's maximum-stat profile is an assumption, not measured max skill. All P and current-Retail gold E remain null. Fish two outputs remain unknown.
