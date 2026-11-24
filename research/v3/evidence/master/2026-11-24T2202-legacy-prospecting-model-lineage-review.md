# Historical Retail prospecting pseudo-recipe lineage — 2026-11-24

Reviewed at 2026-11-24T22:01:45.528Z; research head ee1bd58f5296ee2eca12a8eca3b715e38d23d4d4; main 2db9929050b8532645149dea5a3c5fa8aa0a035a. Follow-up to the legacy worker's 21:41 UTC checkpoint, not a recatalogue of the owner-assigned cutoff. No measured sample, no new in-game work and no runtime/model change.

## Pinned sources and semantics

- [GnomeWorks](https://github.com/remcoros/gnomeworks/blob/10f08f0527e8117ca3a02b89d0f7976c2daabfab/PseudoTrades/Prospecting.lua), Git blob e01410c34ec2e945f854dd3874ba090f8f1257c6, historical 2012-era source. In the pseudo-recipe registration the reagent cache receives exactly five ore and the output cache receives the stored coefficient directly as `numMade`; `GetRecipeData` returns the stored table and five-ore reagent table.
- [DugiWorkshop](https://github.com/JackTrapper/DugiWorkshop/blob/f2f65db529db7923c0268e47c76d1a9d5131cfd7/pricingSupport/prospecting_support.lua), Git blob 63bd0fca9cb233894b750f12838f4e79e30e7540, historical 2018-era source. It registers the same gem table as recipe outputs with five ore as reagent count.
- [ReagentMaker historical annotated source](https://repos.wowace.com/wow/reagentmaker/annotate/default/ProspectingData.lua), revision 42baf007f3c7 (2015-07-30); attributes data to Enchantrix. This is a separate historical model with rounded coefficients (Cobalt common 0.25, rare 0.013 per 5); not exact upstream proof for either GitHub table. Original observations, collection patch, operation counts and model provenance remain unknown.

The two GitHub sources share **13 exact vectors and 130 identical input/output model entries**, not two independent cohorts. GnomeWorks has four additional historical Pandaria vectors (52 entries) that DugiWorkshop's inspected table omits. These are historical original-era retail code models, not the owner's MoP Classic illustration; do not use them as current rates or proof of eligibility. All 182 unique source coefficients remain candidate reference quantities per five-ore pseudo-recipe; no hit probabilities, empirical ranges, casts, zeros, refunds or measured confidence. Equal vectors identify a model alias, not a proven historical source genealogy or new measured samples.

## Comparison against current main frozen reference (not compiled runtime)

The exact frozen TSM records are read from `database/sources/ReferenceData.lua` blob e47143ee72be8e9fd3128ebad62e364774608c4f. Match input and output IDs, not coefficient equality alone. This only checks existing frozen-source overlaps. It does not establish whether later research models fill the same fields or what actual runtime chooses.

[
  {
    "id": 2770,
    "modelRows": 3,
    "frozenTSMRows": 3,
    "sharedIDs": 3,
    "exactValues": 0,
    "modelOnlyIDs": []
  },
  {
    "id": 2771,
    "modelRows": 6,
    "frozenTSMRows": 6,
    "sharedIDs": 6,
    "exactValues": 1,
    "modelOnlyIDs": []
  },
  {
    "id": 2772,
    "modelRows": 5,
    "frozenTSMRows": 4,
    "sharedIDs": 4,
    "exactValues": 1,
    "modelOnlyIDs": [
      7910
    ]
  },
  {
    "id": 3858,
    "modelRows": 7,
    "frozenTSMRows": 2,
    "sharedIDs": 2,
    "exactValues": 0,
    "modelOnlyIDs": [
      7910,
      12361,
      12364,
      12799,
      12800
    ]
  },
  {
    "id": 10620,
    "modelRows": 5,
    "frozenTSMRows": 5,
    "sharedIDs": 5,
    "exactValues": 0,
    "modelOnlyIDs": []
  },
  {
    "id": 23424,
    "modelRows": 12,
    "frozenTSMRows": 12,
    "sharedIDs": 12,
    "exactValues": 0,
    "modelOnlyIDs": []
  },
  {
    "id": 23425,
    "modelRows": 13,
    "frozenTSMRows": 12,
    "sharedIDs": 12,
    "exactValues": 0,
    "modelOnlyIDs": [
      24243
    ]
  },
  {
    "id": 36909,
    "modelRows": 12,
    "frozenTSMRows": 12,
    "sharedIDs": 12,
    "exactValues": 0,
    "modelOnlyIDs": []
  },
  {
    "id": 36910,
    "modelRows": 18,
    "frozenTSMRows": 18,
    "sharedIDs": 18,
    "exactValues": 0,
    "modelOnlyIDs": []
  },
  {
    "id": 36912,
    "modelRows": 12,
    "frozenTSMRows": 12,
    "sharedIDs": 12,
    "exactValues": 0,
    "modelOnlyIDs": []
  },
  {
    "id": 52183,
    "modelRows": 13,
    "frozenTSMRows": 12,
    "sharedIDs": 12,
    "exactValues": 0,
    "modelOnlyIDs": [
      52327
    ]
  },
  {
    "id": 52185,
    "modelRows": 12,
    "frozenTSMRows": 12,
    "sharedIDs": 12,
    "exactValues": 0,
    "modelOnlyIDs": []
  },
  {
    "id": 53038,
    "modelRows": 12,
    "frozenTSMRows": 12,
    "sharedIDs": 12,
    "exactValues": 6,
    "modelOnlyIDs": []
  },
  {
    "id": 72092,
    "modelRows": 13,
    "frozenTSMRows": 12,
    "sharedIDs": 12,
    "exactValues": 0,
    "modelOnlyIDs": [
      90407
    ]
  },
  {
    "id": 72093,
    "modelRows": 13,
    "frozenTSMRows": 12,
    "sharedIDs": 12,
    "exactValues": 0,
    "modelOnlyIDs": [
      90407
    ]
  },
  {
    "id": 72094,
    "modelRows": 13,
    "frozenTSMRows": 12,
    "sharedIDs": 12,
    "exactValues": 0,
    "modelOnlyIDs": [
      90407
    ]
  },
  {
    "id": 72103,
    "modelRows": 13,
    "frozenTSMRows": 12,
    "sharedIDs": 12,
    "exactValues": 0,
    "modelOnlyIDs": [
      90407
    ]
  }
]

For Fel Iron the source pseudo-recipe total is 1.174 gem units per modeled five ore. The frozen TSM vector is six common 0.1825 plus six rare 0.015 (1.185). For Cobalt the source total is 1.568; frozen TSM has six contradictory 2.5 common entries plus six rare 0.015 (15.09). Current main `tools/compile_itemdb.lua` lines 57–66 preserves originals and repairs incompatible E/P/range as P*minimum positive yield, and `tests/test_reference_fallback.lua` lines 62–67 asserts the 36917 modeled fallback becomes 0.235 rather than 2.5. Do not report the impossible frozen value as live behavior. The GnomeWorks model common coefficients 0.244–0.255 are consistent in magnitude with the existing conservative reference but do not independently validate its current applicability or measured probabilities. No regression suite executed in this run.

Cutoff manifest exact source-name screen: ["github.com/amdam/wow_retail_wtf/blob/981c4755d0541737b3e09effe0e87cc5bfad8526/account/doomage/savedvariables/enchantrix.lua","github.com/daniel-d-salas/wowinterface/blob/bc54cd8ea7f83e21f84d146975259c18a653c944/wtf/account/riku6/savedvariables/enchantrix.lua","github.com/nfgallimore/wow/blob/6a3ca4f6d00e3919672dbb9908fba6a7fea09a9c/wtf/account/cyberuke/savedvariables/enchantrix.lua","github.com/ozzieem/wow_3.3.5_addons/blob/0337b2b7be836229254771a9e573059dbf5e51b4/wtf/account/ozzieem/savedvariables/enchantrix.lua","github.com/rbutera/modernclassicmac/blob/b8871f80894a3df52467b0306d209db2dc0794a5/wtf/account/zeropositive/savedvariables/enchantrix.lua","repos.wowace.com/wow/reagentmaker/file/default/prospectingdata.lua"]; absence by name is not proof of independence. Next trigger: original upstream Enchantrix/LSW evidence, exact model ancestry, or independently justified gap-only admission with consumer checks; no unchanged re-transcription. Preserve existing usable values. Model aliases must not inflate observed study counts.

## Source coefficients (model metadata, not drop records)

```json
[
  {
    "id": 2770,
    "name": "Copper Ore",
    "coefficients": {
      "774": 0.499,
      "818": 0.501,
      "1210": 0.099
    },
    "rows": 3,
    "exact": true,
    "quantitySum": 1.099
  },
  {
    "id": 2771,
    "name": "Tin Ore",
    "coefficients": {
      "1206": 0.398,
      "1210": 0.399,
      "1529": 0.033,
      "1705": 0.4,
      "3864": 0.032,
      "7909": 0.031
    },
    "rows": 6,
    "exact": true,
    "quantitySum": 1.293
  },
  {
    "id": 2772,
    "name": "Iron Ore",
    "coefficients": {
      "1529": 0.368,
      "1705": 0.363,
      "3864": 0.371,
      "7909": 0.05,
      "7910": 0.048
    },
    "rows": 5,
    "exact": true,
    "quantitySum": 1.2
  },
  {
    "id": 3858,
    "name": "Mithril Ore",
    "coefficients": {
      "3864": 0.367,
      "7909": 0.366,
      "7910": 0.37,
      "12361": 0.025,
      "12364": 0.023,
      "12799": 0.027,
      "12800": 0.025
    },
    "rows": 7,
    "exact": true,
    "quantitySum": 1.203
  },
  {
    "id": 10620,
    "name": "Thorium Ore",
    "coefficients": {
      "7910": 0.161,
      "12361": 0.336,
      "12364": 0.335,
      "12799": 0.333,
      "12800": 0.332
    },
    "rows": 5,
    "exact": true,
    "quantitySum": 1.497
  },
  {
    "id": 23424,
    "name": "Fel Iron Ore",
    "coefficients": {
      "21929": 0.183,
      "23077": 0.185,
      "23079": 0.183,
      "23107": 0.183,
      "23112": 0.189,
      "23117": 0.178,
      "23436": 0.012,
      "23437": 0.012,
      "23438": 0.012,
      "23439": 0.013,
      "23440": 0.012,
      "23441": 0.012
    },
    "rows": 12,
    "exact": true,
    "quantitySum": 1.174
  },
  {
    "id": 23425,
    "name": "Adamantite Ore",
    "coefficients": {
      "21929": 0.184,
      "23077": 0.181,
      "23079": 0.186,
      "23107": 0.183,
      "23112": 0.187,
      "23117": 0.179,
      "23436": 0.037,
      "23437": 0.037,
      "23438": 0.036,
      "23439": 0.038,
      "23440": 0.037,
      "23441": 0.036,
      "24243": 1
    },
    "rows": 13,
    "exact": true,
    "quantitySum": 2.321
  },
  {
    "id": 36909,
    "name": "Cobalt Ore",
    "coefficients": {
      "36917": 0.244,
      "36918": 0.012,
      "36920": 0.246,
      "36921": 0.012,
      "36923": 0.248,
      "36924": 0.012,
      "36926": 0.254,
      "36927": 0.012,
      "36929": 0.255,
      "36930": 0.014,
      "36932": 0.246,
      "36933": 0.013
    },
    "rows": 12,
    "exact": true,
    "quantitySum": 1.568
  },
  {
    "id": 36910,
    "name": "Titanium Ore",
    "coefficients": {
      "36917": 0.251,
      "36918": 0.042,
      "36919": 0.04,
      "36920": 0.246,
      "36921": 0.041,
      "36922": 0.046,
      "36923": 0.255,
      "36924": 0.042,
      "36925": 0.046,
      "36926": 0.252,
      "36927": 0.04,
      "36928": 0.045,
      "36929": 0.251,
      "36930": 0.043,
      "36931": 0.046,
      "36932": 0.252,
      "36933": 0.041,
      "36934": 0.045
    },
    "rows": 18,
    "exact": true,
    "quantitySum": 2.024
  },
  {
    "id": 36912,
    "name": "Saronite Ore",
    "coefficients": {
      "36917": 0.182,
      "36918": 0.041,
      "36920": 0.185,
      "36921": 0.04,
      "36923": 0.181,
      "36924": 0.044,
      "36926": 0.182,
      "36927": 0.041,
      "36929": 0.184,
      "36930": 0.041,
      "36932": 0.185,
      "36933": 0.041
    },
    "rows": 12,
    "exact": true,
    "quantitySum": 1.347
  },
  {
    "id": 52183,
    "name": "Pyrite Ore",
    "coefficients": {
      "52177": 0.16,
      "52178": 0.16,
      "52179": 0.16,
      "52180": 0.16,
      "52181": 0.16,
      "52182": 0.16,
      "52190": 0.08,
      "52191": 0.08,
      "52192": 0.08,
      "52193": 0.08,
      "52194": 0.08,
      "52195": 0.08,
      "52327": 2
    },
    "rows": 13,
    "exact": true,
    "quantitySum": 3.44
  },
  {
    "id": 52185,
    "name": "Elementium Ore",
    "coefficients": {
      "52177": 0.1875,
      "52178": 0.1875,
      "52179": 0.1875,
      "52180": 0.1875,
      "52181": 0.1875,
      "52182": 0.1875,
      "52190": 0.0417,
      "52191": 0.0417,
      "52192": 0.0417,
      "52193": 0.0417,
      "52194": 0.0417,
      "52195": 0.0417
    },
    "rows": 12,
    "exact": true,
    "quantitySum": 1.3752
  },
  {
    "id": 53038,
    "name": "Obsidium Ore",
    "coefficients": {
      "52177": 0.25,
      "52178": 0.25,
      "52179": 0.25,
      "52180": 0.25,
      "52181": 0.25,
      "52182": 0.25,
      "52190": 0.015,
      "52191": 0.015,
      "52192": 0.015,
      "52193": 0.015,
      "52194": 0.015,
      "52195": 0.015
    },
    "rows": 12,
    "exact": true,
    "quantitySum": 1.59
  },
  {
    "id": 72092,
    "name": "Ghost Iron Ore",
    "coefficients": {
      "76130": 0.25,
      "76131": 0.05,
      "76133": 0.25,
      "76134": 0.25,
      "76135": 0.25,
      "76136": 0.25,
      "76137": 0.25,
      "76138": 0.05,
      "76139": 0.05,
      "76140": 0.05,
      "76141": 0.05,
      "76142": 0.05,
      "90407": 0.8
    },
    "rows": 13,
    "exact": false,
    "quantitySum": 2.6
  },
  {
    "id": 72093,
    "name": "Kyparite",
    "coefficients": {
      "76130": 0.3,
      "76131": 0.1,
      "76133": 0.3,
      "76134": 0.3,
      "76135": 0.3,
      "76136": 0.3,
      "76137": 0.3,
      "76138": 0.1,
      "76139": 0.1,
      "76140": 0.1,
      "76141": 0.1,
      "76142": 0.1,
      "90407": 1
    },
    "rows": 13,
    "exact": false,
    "quantitySum": 3.4
  },
  {
    "id": 72094,
    "name": "Black Trillium Ore",
    "coefficients": {
      "76130": 0.1,
      "76131": 0.3,
      "76133": 0.1,
      "76134": 0.1,
      "76135": 0.1,
      "76136": 0.3,
      "76137": 0.1,
      "76138": 0.3,
      "76139": 0.1,
      "76140": 0.3,
      "76141": 0.3,
      "76142": 0.3,
      "90407": 1
    },
    "rows": 13,
    "exact": false,
    "quantitySum": 3.4
  },
  {
    "id": 72103,
    "name": "White Trillium Ore",
    "coefficients": {
      "76130": 0.1,
      "76131": 0.3,
      "76133": 0.1,
      "76134": 0.1,
      "76135": 0.1,
      "76136": 0.3,
      "76137": 0.1,
      "76138": 0.3,
      "76139": 0.1,
      "76140": 0.3,
      "76141": 0.3,
      "76142": 0.3,
      "90407": 1
    },
    "rows": 13,
    "exact": false,
    "quantitySum": 3.4
  }
]
```
