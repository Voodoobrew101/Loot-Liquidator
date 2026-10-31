# Evidence record format

Every evidence file is JSON Lines (`.jsonl`): one record per line, each a complete JSON object.
Unknown values are `null`. Don't leave fields out; write them as `null`.

## Fields every record has

| Field | Meaning |
| --- | --- |
| `id` | Unique ID: `<agent>-<YYYYMMDD>-<n>`, e.g. `midnight-20261031-001` |
| `type` | `drop`, `token`, `exchange`, `noDisenchant`, `recipe`, `rateChange` or `searched` |
| `agent` | Your agent name, e.g. `midnight` |
| `recordedOn` | Today's date, `YYYY-MM-DD` |
| `source` | `{ "url", "title", "author", "published" }`; `published` is the date the data was posted, if shown |
| `originalSource` | URL of the original study if this is a copy or summary, else `null` |
| `dataDate` | When the data was collected, if stated (`YYYY-MM-DD` or a range like `2026-04-02/2026-04-10`), else `null` |
| `patch` | Game patch the data is from, if stated (e.g. `12.0.5`), else `null` |
| `quote` | A short excerpt (under 25 words) showing where the key number came from, or `null` |
| `notes` | Anything useful in plain words, or `null` |
| `replaces` | ID of an earlier record this one corrects, else `null` |

## `drop`: one material from one processing study

One line **per material** in the study. A study with 6 gems is 6 lines with the same `studyKey`.

| Field | Meaning |
| --- | --- |
| `studyKey` | Same value on every line from one study, e.g. `reddit-1f83cnd-aqirite` |
| `method` | `Prospect`, `Mill`, `Disenchant` or `Smelt` |
| `inputItemID`, `inputName` | The item processed (for disenchanting: the gear item, or `null` if the source covers a group) |
| `inputRank` | Quality rank of the input (1, 2, 3) if stated, else `null` |
| `gearGroup` | Disenchanting only, when the source covers a group: `{ "expansion", "quality", "kind": "armor"/"weapon", "itemLevelRange" }`, else `null` |
| `outputItemID`, `outputName` | The material that dropped |
| `outputRank` | Quality rank of the material if stated, else `null` |
| `casts` | Number of operations (prospects, mills, disenchants) in the study, if stated or countable |
| `inputsPerCast` | E.g. 5 ore per prospect, if stated |
| `totalQuantity` | Total of this material received across all casts, if stated |
| `castsWithDrop` | Number of casts that gave at least one of this material, if stated |
| `percentShown` | If the source gives only a percentage, copy it exactly (e.g. `18.3`), else `null` |
| `percentMeaning` | What that percentage means, if clear: `perCast`, `perInput` or `unclear` |
| `minSeen`, `maxSeen` | Smallest and largest amount seen in one cast, if stated |
| `skill`, `specialization`, `stats` | The player's profession details if stated (free text is fine), else `null` |
| `sourceKind` | `study` (real results someone recorded), `personal-pooled` (the owner's own pooled results), or a reference value: `tsm-table`, `compiled-research`, `reference`. Agents normally write `study`. |
| `averageShown`, `averagePer` | If the source gives only an average (e.g. "0.27 per prospect"), copy it, and say what it is per: `cast`, `input` or `1000 inputs`. Else `null`. |
| `histogram` | If the source shows how many casts gave 0, 1, 2… of this material, copy it as `{"0": 120, "1": 60, "2": 20}`. Else `null`. |

**Reference values are starting guesses only.** Records whose `sourceKind` is `tsm-table`,
`compiled-research` or `reference` are never added to study counts. They are only used when an
item has no studies yet, so the same data is never counted twice.

Example, from a real study (Reddit r/woweconomy, Sept 2024, 1,040 Aqirite prospects):

```json
{"id":"war-within-20261031-001","type":"drop","agent":"war-within","recordedOn":"2026-10-31","source":{"url":"https://www.reddit.com/r/woweconomy/comments/1f83cnd","title":"Aqirite prospecting results","author":null,"published":"2024-09-03"},"originalSource":null,"dataDate":null,"patch":null,"quote":null,"notes":"Player had all rank-5 green gear; ore rank not stated.","replaces":null,"studyKey":"reddit-1f83cnd-aqirite","method":"Prospect","inputItemID":null,"inputName":"Aqirite","inputRank":null,"gearGroup":null,"outputItemID":null,"outputName":"Radiant Ruby","outputRank":null,"casts":1040,"inputsPerCast":5,"totalQuantity":210,"castsWithDrop":null,"percentShown":null,"percentMeaning":null,"minSeen":null,"maxSeen":null,"skill":null,"specialization":null,"stats":"all T5 green gear"}
```

(Fill in item IDs when you can look them up.)

## `token`

| Field | Meaning |
| --- | --- |
| `tokenItemID`, `tokenName` | The token |
| `rewards` | List of `{ "itemID", "name", "classes" }`; `classes` is a list, or `null` if any class |
| `howRedeemed` | `use` (right-click), `vendor`, or `unknown` |
| `vendor` | NPC name and location if a vendor is involved, else `null` |
| `cost` | Any extra cost (currency/items), else `null` |
| `listComplete` | `true` if the source shows the full reward list, `false` or `null` otherwise |

## `exchange`

| Field | Meaning |
| --- | --- |
| `giveItemID`, `giveName`, `giveCount` | What you hand over |
| `getItemID`, `getName`, `getCount` | What you receive |
| `where` | `use` (combine/split by right-click), or the vendor NPC and location |
| `requirements` | Reputation, quest, profession, etc., or `null` |

## `noDisenchant`

| Field | Meaning |
| --- | --- |
| `itemID`, `itemName` | Item whose tooltip says "Cannot be disenchanted" (or that source states can't be disenchanted) |

## `recipe`

| Field | Meaning |
| --- | --- |
| `method` | `Prospect`, `Mill`, `Disenchant` or `Smelt` |
| `recipeSpellID`, `recipeName` | The spell or recipe |
| `inputItemID`, `inputName`, `inputsPerCast` | The batch size |
| `otherReagents` | Smelting extra reagents, e.g. `[{"itemID":..., "name":..., "count":...}]`, else `null` |
| `outputItemID`, `outputName`, `outputCount` | For fixed recipes (smelting); `null` for random ones |

## `rateChange`

Workers don't edit `rate-changes.jsonl`; they record a `rateChange` record in their own folder,
and the Master copies confirmed ones into the list.

| Field | Meaning |
| --- | --- |
| `date` | Date of the change, from the official patch or hotfix notes, `YYYY-MM-DD` |
| `patch` | Patch number if it was a patch, else `null` |
| `method` | Which processing method it affects |
| `affects` | Items or groups affected, in words or IDs |
| `wording` | The note's own words (short) |
| `sizeIfGiven` | A number if the note gives one (e.g. `"+20%"`), else `null` |

## `searched`

Use this when a real search found nothing, so nobody repeats it.

| Field | Meaning |
| --- | --- |
| `lookingFor` | What you looked for, e.g. `Mill results for Sanguithorn` |
| `whereLooked` | List of sites or URLs checked |

## `flags.jsonl`

One line per concern: `{"by":"<agent>","date":"YYYY-MM-DD","recordID":"<id or null>","concern":"<plain words>"}`.
