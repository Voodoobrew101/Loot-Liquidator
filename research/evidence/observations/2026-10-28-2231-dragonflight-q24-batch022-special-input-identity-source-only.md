# Dragonflight q24 batch022 — item identity source readback (not an empirical observation)

Read 2026-10-28. Worker: loot-liquidator-dragonflight. This Markdown file is source-only item/recipe identity evidence, not an actual completed-cast observation, probability estimate or independent quantitative cohort.

## 194545 Prismatic Ore — second-stage, bound intermediate
- Direct source: https://www.wowhead.com/item=194545/prismatic-ore
- Wowhead item text says Binds when picked up, acquired by specialized Jewelcrafters prospecting Dragon Isles ore, and can itself be prospected for gems.
- Nine assigned GameData TSM-derived gem output records are second-stage candidate outputs. Do not assume an auctionable input price, treat first-stage production as free, or add intermediate resale and its converted output value.
- Imported sourceQuality=1 is not proof of a ranked Prismatic Ore item; actual current-Retail selector eligibility, quantity and output ranks unverified.
- Source-memory already contains this item page: REUSED item identity, not new cohort.

## 199344 Magma Thresher — fish, prospectable descriptor
- Direct source: https://www.wowhead.com/item=199344/magma-thresher
- Item is a fish; its tooltip explicitly says it looks Prospectable, alongside Cooking uses.
- Nine assigned GameData TSM-derived gem output records are fish-prospecting candidates, not conventional ore mappings. Imported sourceQuality=1 is not independently verified as fish item quality.
- Source-memory snapshot did not contain this item URL: NEWLY DISCOVERED original item-identity page, not an empirical conversion experiment.
- Current-Retail selector, actual consumed fish quantity, output quality gate and cast histogram still unknown.

## 200061 Prismatic Leaper — fish, millable descriptor
- Direct source: https://www.wowhead.com/item=200061/prismatic-leaper
- Item is a fish; its tooltip says it looks Millable, alongside Cooking uses.
- Three assigned GameData TSM-derived outputs: 190320 Rousing Fire (https://www.wowhead.com/item=190320), 190322 Rousing Order (https://www.wowhead.com/item=190322), 190328 Rousing Frost (https://www.wowhead.com/item=190328). Output item identities read directly; actual fish-to-elemental drop eligibility/probability still unverified.
- Source-memory already contains this item page: REUSED identity, not new cohort.

## Generic spell limitations
- https://www.wowhead.com/spell=374627/dragon-isles-prospecting says five Dragon Isles ores per operation and salvage effect value 5.
- https://www.wowhead.com/spell=382981/dragon-isles-milling says five Dragon Isles herbs per operation and salvage effect value 5.
- Neither generic spell description proves the special fish or BoP intermediate is accepted by the same selector with five units in 2026 Retail. The five-input source normalization is only a diagnostic until selector and reagent-vector readback.

## Exact source lineage
- Existing GameData.lua TSM-derived records at pinned SHA 1d47c4a961c5dc5af626e659f7d96d1490d3cf9e; all 45 assigned exact line/output identities verified.
- No raw TSM imported matRate or amountOfMats is a verified current-Retail P(hit) or unconditional E. Historical TSM min/max are unverified reference ranges.
- No new compiled mappings, no current-Retail numerical fields and no current-Retail completed-cast cohort were established.

Next: in-client selector captures and zero-inclusive completed-cast histograms with skill, specialization, input/output quality, saved reagents and patch. Prioritize 194545→192837/192838/192839, 199344→192837/192838/192839, 200061→190320/190322/190328.
