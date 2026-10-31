# Checking the tier-token lists (Checker agent)

Owner decision (2026-10-31): the **research team** double-checks the token lists and puts the checked result into
its ItemDB export. Claude's branch never marks anything approved. This page says exactly how.

## What to check

Two staged lists on branch `LootLiquidatorclaude-V0.1` (read them there; they are research, not shipped):

| File | Season | Tokens | Rewards |
| --- | --- | --- | --- |
| `database/research/tokens-midnight-s1.json` | Midnight Season 1 (Tier 35, The Voidspire etc.) | 20 + Chiming Void Curio | 65 |
| `database/research/tokens-midnight-s2.json` | Midnight Season 2 (Tier 36, The Venomous Abyss) | 20 + Slumbering Coil Curio | 65 |

Every token ID and reward ID in those files has the page it was read from (`sources`, `source`, `evidence`).

## How to check (one token at a time)

1. Open the token's Wowhead page (`https://www.wowhead.com/item=<tokenID>`). Confirm the name, that it is a
   tier token for the listed armor type, and its item class (expected: Miscellaneous = class **15**, shown as
   "Junk"). Write the class number you saw.
2. Confirm the token's reward list: each class in `classes` gets exactly one piece, and each `itemID` opens the
   right piece (the warcraft.wiki.gg token page has a "Creates" list; the Wowhead piece page names its slot and class).
3. Check the weak spots first:
   - Season 1: **249960** (Luminant Verdict's Greaves) — its name was cut off in the original snippet.
   - Season 2: the 52 piece IDs that come only from MythicDrake item URLs (one source each). The evoker head/hands
     question is settled (Magmashapers = head 271501, Ebon Greathorns = hands 271502); confirm it anyway.
4. Find the game build range the list is valid for (`patchStartBuild` = first build the token existed with these
   rewards; `patchEndBuild` = last build you have seen it unchanged, e.g. the current live build).
5. For each token: if everything matches, write one record into the export (format below). If anything does not
   match, do **not** write a record; add a `check` evidence record with `"result": "mismatch"` and a note
   (see `README.md`), so Claude can fix the staged list.
6. Curios (Chiming Void Curio, Slumbering Coil Curio) are exchanges: one record with `kind = 'exchange'` and a
   `costs` entry per reward (`{kind='item', id=<curioID>, quantity=1}`). If you cannot confirm the full reward
   list and costs, leave the curio out; the addon still works without it.

## Where to write it

Your ItemDB export `research/proposed/itemdb.lua` (on your branch) returns one table. Add a `tokenRewards` list to
it, next to `processing` and `mechanicRules`:

```lua
return {schemaVersion='0.2.0', processing={...}, mechanicRules={...},
  tokenRewards={
    {recordID='token:s2:270913', tokenID=270913, kind='open', gameMode='Retail', inputClassID=15,
     rewards={271457, 271466, 271475},           -- Warrior, Paladin, Death Knight pieces
     listComplete=true, requirementsReviewed=true, requirements={},
     evidenceStatus='VERIFIED_RELATIONSHIP', independentReview='APPROVED',
     reviewedBy='Checker agent, run 2026-11-02', confidence0to100=95,
     patchStartBuild=68209, patchEndBuild=70575, sourceRevision='research run 2026-11-02',
     sourceURLs={'https://www.wowhead.com/item=270913/venomforged-idol',
                 'https://warcraft.wiki.gg/wiki/Venomforged_Idol'}},
  }}
```

Rules (the addon refuses the whole list if any record breaks them, so Claude's build skips a bad record and reports why):

- `recordID`: unique text; use `token:s1:<tokenID>` / `token:s2:<tokenID>`.
- `tokenID`, every reward ID, both build numbers: whole numbers above 0. A reward is never the token itself and
  never listed twice.
- `kind`: `'open'` (token opens into one piece) or `'exchange'` (curio; needs `costs`, keyed by reward ID as text).
- `gameMode='Retail'`; `inputClassID` = the token's item class number (0–20, never 7).
- `listComplete=true` only when every reward is listed; `requirementsReviewed=true`; `requirements={}`.
- `evidenceStatus='VERIFIED_RELATIONSHIP'`, `independentReview='APPROVED'`, `reviewedBy` = who checked it.
- `confidence0to100` between 90 and 100 (below 90: leave the record out and keep researching).
- `sourceURLs`: at least 2 different `https://` links. `sourceRevision`: any non-empty label for this run.
- No chances or amounts (`dropChance`, `expectedQuantity`, `probability`) on token records.
- Two records for the same `tokenID` must not have overlapping build ranges.

## What happens next

Claude refreshes `database/research/itemdb.lua` from your export and rebuilds ItemDB (task C4b2).
`tools/compile_itemdb.lua` checks every record with the addon's own check; good ones ship, bad ones are listed in
the build output (`Token record skipped: …`) and in `ItemDB.buildReport.tokenRewardsSkipped`, never shipped.
Token lists put in `database/records.lua` stop the build: that file is not the place for them.
