# Midnight queue21 — item identity and source-context reconciliation
**2026-10-28 · 2026-10-28-1914-midnight-q21-batch019 · research-only, SOURCE_ONLY_NOT_NUMERIC**

## Direct item identity checks
Eleven assigned gem item IDs were re-opened individually on Wowhead. Each item page identifies a raw Midnight uncut crafting reagent, but the public text does not establish whether the game's salvage selector accepts it or whether it is a rank-1/rank-2 variant. Names are not unique identifiers; distinct IDs with the same displayed name must remain separate.

| Item ID | Verified item-page name | Exact salvage eligibility | Output-rank histogram |
|---|---|---|---|
| 242606 | Tenebrous Amethyst | UNKNOWN | UNKNOWN |
| 242610 | Flawless Harandar Peridot | UNKNOWN | UNKNOWN |
| 242611 | Flawless Tenebrous Amethyst | UNKNOWN | UNKNOWN |
| 242612 | Flawless Amani Lapis | UNKNOWN | UNKNOWN |
| 242613 | Flawless Sanguine Garnet | UNKNOWN | UNKNOWN |
| 242720 | Harandar Peridot | UNKNOWN | UNKNOWN |
| 242721 | Tenebrous Amethyst | UNKNOWN | UNKNOWN |
| 242724 | Flawless Sanguine Garnet | UNKNOWN | UNKNOWN |
| 242725 | Flawless Tenebrous Amethyst | UNKNOWN | UNKNOWN |
| 242726 | Flawless Harandar Peridot | UNKNOWN | UNKNOWN |
| 242727 | Flawless Amani Lapis | UNKNOWN | UNKNOWN |

Each item-page URL: https://www.wowhead.com/item=242606, https://www.wowhead.com/item=242610, https://www.wowhead.com/item=242611, https://www.wowhead.com/item=242612, https://www.wowhead.com/item=242613, https://www.wowhead.com/item=242720, https://www.wowhead.com/item=242721, https://www.wowhead.com/item=242724, https://www.wowhead.com/item=242725, https://www.wowhead.com/item=242726, https://www.wowhead.com/item=242727.

## Recipe-family evidence
https://www.wowhead.com/spell=1231132/midnight-crushing documents three selectable Midnight gems and one Dusk-Shrouded Stone per operation (salvage effect value 3). It does not expose an item-ID whitelist or per-output-rank cast distribution. Candidate outputs 242620 and 242621 are both identified as Glimmering Gemdust by their individual pages, but this is not evidence that both occur from each input.

## New October player-context source — no cast cohort
https://www.reddit.com/r/woweconomy/comments/1wwd0w0/should_i_use_my_1_time_swap_for_jc_to_go_from_gem/ (2026-10-03) contains two separate player comments: one reports prospecting losses with max talents/blue gear; another says rank-one ore can be profitable while rank-two is intermittent and corrects 'multicraft' to 'resourcefulness'. These are qualitative and price/context dependent. **No original cast denominator, item-ID histogram, or matched market-price snapshot.** The source-memory URL was absent at this run's read, so this is a newly indexed qualitative discussion, not a new numeric study.

## Existing historical data not promoted
Original HeadtripVee pre-/around-hotfix ore percentage tables and Cardinalai's 800 Silver casts were already archived. The Cardinalai rank is unspecified; do not transfer 43/800 Diamond E to Silver R2. Original Thorium '20% per craft over 200 crafts' is a self-report without per-cast hits or timing, so no exact-context P or E promotion.

## Gold-risk guards
- Resourcefulness savings reduce ore/gem cost, never increase produced-output expectedQuantity.
- Gem quality and rank-alternative rows must be mutually exclusive in a valuation; no family-rate copy into both quality IDs.
- All 11 exact salvage candidates remain UNKNOWN until in-client item whitelist confirmation.
- New source qualitative comments cannot establish a current AH liquidation-action flip.
