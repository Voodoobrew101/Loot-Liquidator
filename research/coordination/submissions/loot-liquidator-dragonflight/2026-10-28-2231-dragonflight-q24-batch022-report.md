# Dragonflight Batch 022 — queue revision 24
2026-10-28 22:31 PDT · worker loot-liquidator-dragonflight · research-only

## Live assignment, lineage and exact P0 audit
Read live queue revision 24, 45 exact keys for assignment 2026-10-28-batch022-dragonflight, master batch021 verdict, source-memory (181 canonical sources / 308 reviews at last incremental replay), research lessons, q23 worker report/source reviews, original GameData.lua and relevant archived item evidence before new direct page reads. The source-memory cache is not a complete directory rebuild.
All 45/45 exact GameData source-line/output/parent input identities match the pinned source blob 1d47c4a961c5dc5af626e659f7d96d1490d3cf9e. No duplicated assigned keys or cross-worker keys. Group counts: Prismatic Ore 194545 (9), Magma Thresher 199344 (9), Prismatic Leaper 200061 (3), and six ordinary Dragon Isles ore ranks 190312/190313/190314/190394/190395/190396 (4 each). These are existing derivative TSM records, not new mappings.

## P0 — high-impact special input classification
1. **194545 Prismatic Ore** (https://www.wowhead.com/item=194545/prismatic-ore): BoP, produced through specialized prospecting and prospectable again. The nine assigned gem rows represent a second-stage conversion. Gold calculations must not assume auctionability or treat intermediate production as free. The TSM imported sourceQuality=1 is not independently established as a real item quality rank.
2. **199344 Magma Thresher** (https://www.wowhead.com/item=199344/magma-thresher): fish with tooltip explicitly describing it as Prospectable. Nine assigned gem outputs are fish-processing candidates, not ordinary ore. New direct-read item identity source, not new quantitative cohort. Imported sourceQuality=1 is not a verified fish rank.
3. **200061 Prismatic Leaper** (https://www.wowhead.com/item=200061/prismatic-leaper): fish with tooltip describing it as Millable. Three assigned source outputs are 190320 Rousing Fire, 190322 Rousing Order, 190328 Rousing Frost, with item identities directly read. Do not assume conventional herb-to-pigment milling output.
Generic Dragon Isles Prospecting spell 374627 (https://www.wowhead.com/spell=374627/dragon-isles-prospecting) and Milling spell 382981 (https://www.wowhead.com/spell=382981/dragon-isles-milling) specify five ore/herb units, respectively. These generic descriptions do not prove special fish or bound intermediate selector acceptance, actual consumed units or skill gates in current Retail. Treat five-unit normalization as diagnostic pending selector readback.

## P1 — four independently scored numeric fields
Across 45 assigned candidate outputs, **180/180 exact current-Retail numeric fields remain UNKNOWN**, each null/confidence 0: dropChance P(at least one output), yieldMin and yieldMax on positive events only, and unconditional expectedQuantity including zero outcomes. The 90 source TSM min/max references remain separately labeled unverified source ranges at 20/100 reference confidence; they are not exact-rank measured bounds. Original current-Retail completed-cast denominators, patch-matched skill/stat contexts and output-quality-specific histograms are absent. No inferred chance from E, midpoint EV, or invented zeros.

## P2 — TSM unit and liquidation risks
All **45/45** raw rows have matRate greater than amountOfMats. Multiplying amountOfMats by five makes all **45/45** compatible with the mathematical P<=E check for positive integer outputs (tolerance 0.0003), but the imported column units are unverified and the special-input reagent counts are unconfirmed. Do not promote matRate to observed P or five times amountOfMats to observed per-operation E.
Additional risks: mutually exclusive output-quality ranks with repeated family rates may inflate conversion EV; Prismatic Ore must be costed as a two-stage BoP intermediate; fish processing needs special eligibility and item classification. No matched 2026 AH prices, actual casts or skill conditions establish a measured liquidation decision flip.

## Continuous improvement and master handoff
- New legitimate compiled mappings: **0**. New verified current-Retail numeric fields: **0**. New original measured cohorts: **0**. New direct-read item identity source: Magma Thresher fish. Reused item identities: Prismatic Ore and Prismatic Leaper. New generic Dragon Isles Milling spell readback. Six source-review events record source discovery/reuse and missing fields; no self-awarded confidence.
- Useful negative findings: fish should not be assumed ore/herbs; imported sourceQuality=1 on unranked special inputs is not verified item rank; BoP intermediate cannot be sold via AH; current spell text does not independently confirm special selector.
- Next exact assigned ID targets: **194545→192837/192838/192839** (two-stage BoP); **199344→192837/192838/192839** (fish prospecting); **200061→190320/190322/190328** (fish milling). Follow-up ore rank keys: **190312→192863/192865** and **190313/190314/190394/190395/190396→192842/192843/192844/192845**. These are q24 assigned or existing rows, not newly self-claimed records.
- Obtain in-client item selector captures with actual reagent counts and skill context, then zero-inclusive completed-cast histograms, output IDs/ranks and Resourcefulness accounting. Reuse indexed authors/sources rather than re-fetch without a change trigger. Assigned q24 scope is audited; master may issue new disjoint assignment.

## Reproducibility and write scope
Audit: research/coordination/submissions/loot-liquidator-dragonflight/2026-10-28-2231-dragonflight-q24-batch022-45key-fourfield-audit.jsonl
Evidence: research/evidence/observations/2026-10-28-2231-dragonflight-q24-batch022-special-input-identity-source-only.md
Reviews: research/coordination/source-reviews/loot-liquidator-dragonflight-2026-10-28-2231-dragonflight-q24-batch022.jsonl
All files unique and worker-owned. No main, production Lua/TOC, shared master ledger, master assignments, canonical registry, source-memory or schedule changed. No Node CLI, independent Lua interpreter or WoW client execution.
