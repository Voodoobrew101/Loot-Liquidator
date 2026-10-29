# Wowhead raw Prospecting loot-tab extraction — Legacy q25
**Captured 2026-10-28 · worker loot-liquidator-legacy · source variant and denominator preserved**

The source is the HTML `new Listview({id:'prospecting'})` embedded dataset on each ore item page. `count` is the output's displayed loot-tab count; `outof` is the page's `oreprospected_format` aggregate. These may be mixed historical versions and client-uploaded observations, not current patch-matched completed casts. `stack` is the observed positive stack range; `pctstack` is a conditional distribution string when available. No economic expectedQuantity is derived.

## 36909 — https://www.wowhead.com/item=36909/cobalt-ore
Page variant: RETAIL; page observation denominator 91628; assigned output rows:
```json
[
  {
    "id": 36917,
    "name": "Bloodstone",
    "count": 21139,
    "outof": 91628,
    "stack": [
      1,
      2
    ],
    "pctstack": "{1: 94.5598,2: 5.44018}"
  },
  {
    "id": 36920,
    "name": "Sun Crystal",
    "count": 21132,
    "outof": 91628,
    "stack": [
      1,
      2
    ],
    "pctstack": "{1: 93.763,2: 6.23699}"
  },
  {
    "id": 36923,
    "name": "Chalcedony",
    "count": 21435,
    "outof": 91628,
    "stack": [
      1,
      2
    ],
    "pctstack": "{1: 94.5603,2: 5.4397}"
  },
  {
    "id": 36926,
    "name": "Shadow Crystal",
    "count": 21799,
    "outof": 91628,
    "stack": [
      1,
      2
    ],
    "pctstack": "{1: 94.1282,2: 5.87183}"
  },
  {
    "id": 36929,
    "name": "Huge Citrine",
    "count": 21847,
    "outof": 91628,
    "stack": [
      1,
      2
    ],
    "pctstack": "{1: 93.4636,2: 6.53637}"
  },
  {
    "id": 36932,
    "name": "Dark Jade",
    "count": 21188,
    "outof": 91628,
    "stack": [
      1,
      2
    ],
    "pctstack": "{1: 94.6432,2: 5.35681}"
  }
]
```

## 36910 — https://www.wowhead.com/item=36910/titanium-ore
Page variant: RETAIL; page observation denominator 58769; assigned output rows:
```json
[
  {
    "id": 36917,
    "name": "Bloodstone",
    "count": 13712,
    "outof": 58769,
    "stack": [
      1,
      2
    ],
    "pctstack": "{1: 94.6324,2: 5.36756}"
  },
  {
    "id": 36920,
    "name": "Sun Crystal",
    "count": 13372,
    "outof": 58769,
    "stack": [
      1,
      2
    ],
    "pctstack": "{1: 94.3913,2: 5.60873}"
  },
  {
    "id": 36923,
    "name": "Chalcedony",
    "count": 13766,
    "outof": 58769,
    "stack": [
      1,
      2
    ],
    "pctstack": "{1: 94.007,2: 5.99303}"
  },
  {
    "id": 36926,
    "name": "Shadow Crystal",
    "count": 13663,
    "outof": 58769,
    "stack": [
      1,
      2
    ],
    "pctstack": "{1: 94.2838,2: 5.71617}"
  },
  {
    "id": 36929,
    "name": "Huge Citrine",
    "count": 13703,
    "outof": 58769,
    "stack": [
      1,
      2
    ],
    "pctstack": "{1: 94.607,2: 5.39298}"
  },
  {
    "id": 36932,
    "name": "Dark Jade",
    "count": 13473,
    "outof": 58769,
    "stack": [
      1,
      2
    ],
    "pctstack": "{1: 94.1661,2: 5.83389}"
  },
  {
    "id": 46849,
    "name": "Titanium Powder",
    "count": 33239,
    "outof": 58769,
    "stack": [
      1,
      5
    ],
    "pctstack": "{1: 74.9872,2: 24.1072,3: 0.72806,4: 0.129366,5: 0.0481362}"
  }
]
```

## 72094 — https://www.wowhead.com/mop-classic/item=72094/black-trillium-ore
Page variant: MOP_CLASSIC_REDIRECT_QUARANTINED; page observation denominator 4586; assigned output rows:
```json
[
  {
    "id": 76130,
    "name": "Tiger Opal",
    "count": 504,
    "outof": 4586,
    "stack": [
      1,
      1
    ],
    "pctstack": null
  },
  {
    "id": 76133,
    "name": "Lapis Lazuli",
    "count": 596,
    "outof": 4586,
    "stack": [
      1,
      1
    ],
    "pctstack": null
  },
  {
    "id": 76134,
    "name": "Sunstone",
    "count": 680,
    "outof": 4586,
    "stack": [
      1,
      1
    ],
    "pctstack": null
  },
  {
    "id": 76135,
    "name": "Roguestone",
    "count": 734,
    "outof": 4586,
    "stack": [
      1,
      1
    ],
    "pctstack": null
  },
  {
    "id": 76136,
    "name": "Pandarian Garnet",
    "count": 557,
    "outof": 4586,
    "stack": [
      1,
      1
    ],
    "pctstack": null
  },
  {
    "id": 76137,
    "name": "Alexandrite",
    "count": 647,
    "outof": 4586,
    "stack": [
      1,
      1
    ],
    "pctstack": null
  }
]
```

## 72103 — https://www.wowhead.com/mop-classic/item=72103/white-trillium-ore
Page variant: MOP_CLASSIC_REDIRECT_QUARANTINED; page observation denominator 4851; assigned output rows:
```json
[
  {
    "id": 76130,
    "name": "Tiger Opal",
    "count": 727,
    "outof": 4851,
    "stack": [
      1,
      1
    ],
    "pctstack": null
  },
  {
    "id": 76133,
    "name": "Lapis Lazuli",
    "count": 671,
    "outof": 4851,
    "stack": [
      1,
      1
    ],
    "pctstack": null
  },
  {
    "id": 76134,
    "name": "Sunstone",
    "count": 779,
    "outof": 4851,
    "stack": [
      1,
      1
    ],
    "pctstack": null
  },
  {
    "id": 76135,
    "name": "Roguestone",
    "count": 711,
    "outof": 4851,
    "stack": [
      1,
      1
    ],
    "pctstack": null
  },
  {
    "id": 76136,
    "name": "Pandarian Garnet",
    "count": 726,
    "outof": 4851,
    "stack": [
      1,
      1
    ],
    "pctstack": null
  },
  {
    "id": 76137,
    "name": "Alexandrite",
    "count": 499,
    "outof": 4851,
    "stack": [
      1,
      1
    ],
    "pctstack": null
  }
]
```

## 123919 — https://www.wowhead.com/item=123919/felslate
Page variant: RETAIL; page observation denominator 2194; assigned output rows:
```json
[
  {
    "id": 130178,
    "name": "Furystone",
    "count": 20,
    "outof": 2194,
    "stack": [
      2,
      5
    ],
    "pctstack": "{2: 5,3: 15,5: 80}"
  },
  {
    "id": 130179,
    "name": "Eye of Prophecy",
    "count": 22,
    "outof": 2194,
    "stack": [
      2,
      5
    ],
    "pctstack": "{2: 22.7273,3: 59.0909,4: 9.09091,5: 9.09091}"
  },
  {
    "id": 130180,
    "name": "Dawnlight",
    "count": 18,
    "outof": 2194,
    "stack": [
      2,
      5
    ],
    "pctstack": "{2: 22.2222,3: 11.1111,4: 38.8889,5: 27.7778}"
  },
  {
    "id": 130181,
    "name": "Pandemonite",
    "count": 17,
    "outof": 2194,
    "stack": [
      2,
      5
    ],
    "pctstack": "{2: 58.8235,4: 11.7647,5: 29.4118}"
  },
  {
    "id": 130182,
    "name": "Maelstrom Sapphire",
    "count": 14,
    "outof": 2194,
    "stack": [
      2,
      5
    ],
    "pctstack": "{2: 71.4286,3: 14.2857,4: 7.14286,5: 7.14286}"
  },
  {
    "id": 130183,
    "name": "Shadowruby",
    "count": 17,
    "outof": 2194,
    "stack": [
      2,
      5
    ],
    "pctstack": "{2: 5.88235,3: 17.6471,4: 70.5882,5: 5.88235}"
  }
]
```


Titanium Powder raw stack=[1,5], but conservative tooltip range=[1,2] only; retain raw observed maximum separately. This is deliberate display underestimation, not a claim of true max. MoP Classic data is archived solely for source review, not used as Retail fallback. `maxstat/skill` is a fallback label, not an observed source condition. All gold fields remain unknown.
