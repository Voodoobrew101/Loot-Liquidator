# Serevite ore three-way external rank-label conflict — 2026-11-17T22:18Z

**Scope:** manager-owned, source-identity-only review for Dragonflight T0041/T0046. No new original processing cohort, measured output quantity, completed casts, probability, Retail recipe eligibility, gold valuation, ItemDB code, or live client claim. Research branch prewrite head: `26a6a82d51dce768b471b6b35174200c28967eda`.

## New external-source hazard

The three public Saddlebag Exchange *item ID pages* have a **systematic rotated Serevite quality label**. That is incompatible with two independent rank lists and the existing owner's pinned exact-ID mapping, so a scraped Saddlebag heading must **not** be accepted as an authoritative item-quality rank.

| Serevite item ID | Current Saddlebag heading (conflicting) | Independently corroborated rank | Primary links |
| --- | --- | --- | --- |
| **190394** | **Quality 1** | **Rank 3** | [Saddlebag item 190394](https://saddlebagexchange.com/wow/item-data/190394), [GoldCap Retail item 190394](https://goldcap.gg/retail/us/items/190394) |
| **190395** | **Quality 2** | **Rank 1** | [Saddlebag item 190395](https://saddlebagexchange.com/wow/item-data/190395), [GoldCap Retail item 190395](https://goldcap.gg/retail/us/items/190395) |
| **190396** | **Quality 3** | **Rank 2** | [Saddlebag item 190396](https://saddlebagexchange.com/wow/item-data/190396), [GoldCap Retail item 190396](https://goldcap.gg/retail/us/items/190396) |

- Independent developer documentation [t-mart/wow-auction README — “Item Rank”](https://github.com/t-mart/wow-auction/blob/master/README.md) explicitly states **190395 rank 1, 190396 rank 2, 190394 rank 3**. This developer mapping already appears in earlier project research; **do not credit it as a newly discovered map**.
- A WoW player [provided a concrete `C_CraftingOrders.PlaceNewOrder` macro and itemID substitutions](https://www.wowhead.com/ru/achievement=16791/рәмесленник-торговец) naming `190396` as two-star, `190394` as three-star and `190395` as one-star. This is corroborating posted player code, **not** an executed current-client test. If that localized URL fails, rely on the direct item and developer links above.
- Existing integration source `database/research/input-ranks.json`, blob `126cd3768740b529d6108cdffde67bade7f8f7d9`, **already uses the corroborated mapping**. No existing ItemDB rank bug is demonstrated. GoldCap is also third-party, not Blizzard client verification. The only new finding here is **the contradictory Saddlebag three-item label set**, not three new item identities or market prices.
- Do not generalize this discrepancy to the entire Saddlebag database without comparable evidence. Do not use any page's cached prices, misleading item lore prose, or another site's heading to overwrite exact item IDs or output rank distributions.

## Original source-transcription control, not new progress

Separately read the **original native** [Jallfo Dragonflight JC workbook](https://docs.google.com/spreadsheets/d/1B_CjPU0AUlJkbogauPTdo0W4dUZiP1hxZ8KMZX7qp3Q/edit), tab `Sheet1!A1:X55`, and two existing immutable research source files:
- `research/evidence/observations/2026-10-28-0728-dragonflight-batch007-2022beta-six-cohorts.jsonl`, blob `6f5c75e8a99daecbcb814bbb27643f8bd22159be`: **222/222** original 37-row × 6-profile material-unit fields match current source cell values; archive preserves all six profile contexts, not independent 2026 experiments.
- `research/v3/evidence/dragonflight/2026-10-30T2131-jallfo-beta-six-prospecting-cohorts.jsonl`, blob `6fa190857771f434644a368c063632e0f0c76c0f`: **216** source transcriptions, distributed as 37 × 3 Serevite and 35 × 3 Draconium. The six omitted Draconium glass/stone rows **were already identified** in manager evidence `20261117T1201-jallfo-draconium-glass-stone-transcription-gap.md`; their loss is in v3 transcription, **not** in the 222-row original archive. Do not re-record them as six independent studies. This comparison is an integrity recheck, **not new source recovery**.

**Actual deterministic verification:** **463/463** in-process JavaScript assertions passed on exact original workbook numeric cells, archive row identities, existing v3 profile counts and canonical owner item-rank map. External Saddlebag/GoldCap pages were separately inspected from public pages; those web pages were **not** part of the automated 463 assertions. No Python compiler, Lua addon suite, synthetic-price engine or formatter, saved character data, current-item client tooltip or WoW QA was run.

**Disposition / next priority:** mark Saddlebag Serevite display headings as **conflicting source labels**, preserve already-correct exact ID mapping, and require independent item-rank/client confirmation before any future import that relies solely on this source. Keep workers on new source-original completed-operation/stack/zero measurements and input/rank eligibility; do not ask them to repeat the known Jallfo or t-mart mapping. No current Retail source/output value is newly priceable.
