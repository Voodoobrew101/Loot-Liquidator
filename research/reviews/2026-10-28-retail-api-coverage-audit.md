# 2026-10-28 — Retail addon API access review for ProfessionMechanicsRegistry

**Status:** Documented-API and current-source review only. **No in-game test performed.**  
**Target:** Retail Midnight 12.x; source snapshot `main` v0.9.70.  
**Companion machine-readable manifest:** [WoWRuntimeAPIRegistry.json](../mechanics/WoWRuntimeAPIRegistry.json) (26 capabilities).  
**Disposition:** The v0.1 research mechanics registry is incomplete for real/simulated profession normalization. It must explicitly express whether contextual fields are **live from the player**, **available only with a suitable open profession/recipe UI**, **previously cached from an alt**, **estimated**, or **not exposed at all**.

## P0: Likely root cause of unchanged skill-sensitive tooltips

1. `Professions.lua` `DisplayedSkillLine()` (lines ~29–62) first calls `C_TradeSkillUI.GetChildProfessionInfo()`, reads `info.professionID`, `info.professionName`, and returns them as **expansion-specific** `skillLineID` and `name`. The documented ProfessionInfo structure describes `professionName` as the **parent profession name**, and `expansionName` is reportedly unreliable. The separate live function `C_TradeSkillUI.GetTradeSkillLine()` directly returns expansion-specific `skillLineID` and display name, but is used only as fallback in the code, so that safer route may be bypassed. There is a documented ambiguity: an observed 12.0.1 behavior of `GetProfessionInfoByRecipeID` uses `professionID` as variant ID; do not assume all these functions have identical semantics. **Audit by live identity cross-check**, rather than claim this is definitively broken on every build.
2. `RecordDisplayedSkillLine()` stores the resulting pair in `character.details[id]`. `GetResearchProfessionSnapshot()` then selects a detail only if its *name contains the expansion label* (e.g. Midnight or Khaz Algar), so a generic parent name, even with valid skill, can make the entire snapshot lookup fail. Also older expansions may have localization problems; match numeric variant IDs first.
3. **Recommended ID retrieval**: `C_TradeSkillUI.GetProfessionChildSkillLineID()` for the selected profession expansion; `C_TradeSkillUI.GetTradeSkillLine()` when valid; `C_TradeSkillUI.GetTradeSkillLineForRecipe(recipeID)` to confirm each recipe's variant skillline; `C_TradeSkillUI.IsRecipeInSkillLine` where available; `C_TradeSkillUI.GetProfessionInfoBySkillLineID(childSkillLineID)` to obtain `skillLevel` and `skillModifier`. Test in a native OWN profession window and reject linked/guild views.
4. `C_ProfSpecs.GetConfigIDForSkillLine(childSkillLineID)`, `GetSpecTabIDsForSkillLine`, `GetChildrenForPath`, `C_Traits.GetNodeInfo`, `GetStateForPath`, `GetStateForPerk` expose current talent state, but `currentRank` may reflect preview/granted ranks. Save **committed purchased ranks and entry IDs** and distinguish uncommitted previews before applying actual bonuses.
5. `ConversionEngine.lua` ~line 79 calls `GetCraftingOperationInfo(recipeID, {}, nil, false)`. Empty reagent allocation can yield nil or an incomplete recipe/quality calculation; **the API needs valid reagent allocation for applicable recipes**. It returns `bonusStats` (`ratingPct`, `bonusRatingPct`, `bonusStatValue`), `baseSkill`, `bonusSkill`, quality thresholds, `concentrationCost`, `ingenuityRefund`. The current engine uses only effective skill and `craftingQuality`, discarding the most useful available stat data.
6. The API's **12.0.0 CraftingReagentInfo field shape changed** to `{reagent={itemID=...},dataSlotIndex=...,quantity=...}`, and schematics gained `variableQuantities`. API callers must be version-aware; do not assume `GetRecipeSchematic.outputItemID` enumerates random outcomes.
7. `ConversionEngine` currently uses `f.quality` as input quality; this often means **item rarity**, not Rank 1/2/3 reagent quality. Use `C_TradeSkillUI.GetItemReagentQualityByItemInfo(itemLink)`, keep input item ID variant and distinct crafting quality output.
8. `ProcessingTracking.lua` and `DisenchantTracking.lua` currently use `UNIT_SPELLCAST_*` + `BAG_UPDATE_DELAYED`, **not** `TRADE_SKILL_ITEM_CRAFTED_RESULT`. The latter has `operationID`, `quantity`, `multicraft`, `resourcesReturned`, `concentrationSpent`, `ingenuityRefund` and quality. **Unknown whether specific prospect, mill, disenchant operations emit it reliably**; test every method with one-cast logs first. Use event as extra evidence, never blindly assume one output event per cast or every event is a processing yield. Reject unrelated bag deltas.

## Priority API coverage matrix

| Class | Main API(s) | What can be read | Access / limitation |
|---|---|---|---|
| Client version | `GetBuildInfo()` | Client version, build number, interface version | Live per client; **server-side hotfix factors absent** |
| Profession membership | `GetProfessions()`, `GetProfessionInfo()` | Base professions, skill, skill modifier | Current char only; insufficient for every expansion variant |
| Expansion skill | `GetProfessionChildSkillLineID`, `GetTradeSkillLine`, `GetTradeSkillLineForRecipe`, `GetProfessionInfoBySkillLineID` | Exact relevant expansion and skill | Some calls depend on own profession UI / recipe context |
| Specializations | `C_ProfSpecs` + `C_Traits.GetNodeInfo` | Selected tabs, ranks, entries, earned perks | Active/current char; rank states can be preview vs committed |
| Recipe eligibility | `GetRecipeInfo`, `IsRecipeInSkillLine`, `GetRecipeRequirements` | Learned, disabled, craftable, requirements | Some need own loaded profession window; not equal to permanent recipe rate |
| Recipe materials | `GetRecipeSchematic`, `GetSalvagableItemIDs` | Quantity, optional/variable ingredients, salvage input candidates | No guaranteed random output distribution; validate batch |
| Operation stats | `GetCraftingOperationInfo` | Effective skill, bonusStats/ratingPct, quality, concentration/ingenuity | Requires recipe and valid reagent allocation; may not cover all salvage/DE |
| Concentration | `GetConcentrationCurrencyID` + `C_CurrencyInfo.GetCurrencyInfo` | Current available resource | Current character, correct expansion skillline; no generic yield multiplier |
| Gear | `GetProfessionInventorySlots`, `GetInventoryItemLink`, `GetSkillLineForGear`, `C_Item.GetItemStats` | Equipped tool/accessories and stats | No automatic full recipe-specific bonuses; compare operation bonusStats |
| Rank/quality | `GetItemReagentQualityByItemInfo`, `GetRecipeOutputItemData` | Reagent quality, known crafted output rank/ID | Never confuse with item rarity; randomized outcome family still needs research |
| Buffs | `C_UnitAuras.GetPlayerAuraBySpellID` | Known relevant active aura | Explicit spell whitelist; 12.x secret/taint and availability restrictions |
| Inventory | `C_Container.GetContainerItemInfo`, `C_Item.GetItemInfoInstant` | Exact input item/count/ID/links and bound state | Bags/banks when available; item cache and Warbank access caveats |
| Actual processing results | `TRADE_SKILL_ITEM_CRAFTED_RESULT` | Output quantity, resourcefulness returned input, multicraft, concentration spent, ingenuity refund | **Per-method live event coverage UNKNOWN**, no guaranteed per-cast complete histogram |
| Fallback observations | `UNIT_SPELLCAST_SUCCEEDED` + `BAG_UPDATE_DELAYED` | Cast and item delta | Correlate sequentially; mixed bags/loot can contaminate |
| Other characters | Own account `SavedVariables` previously scanned | Last-seen skill, specs, recipes, gear and stats | No reliable live API to query arbitrary offline alt; store timestamp and build |
| Hidden drop models | No documented public addon API | No exact material drop chances, yield distribution or patch multipliers | Require empirical observations and external/official evidence |

## Mandatory registry additions

1. Add `runtimeApiRef` to each mechanic and baseline context requiring an observable value, with `scope` (player/recipe/UI/event/saved-alt/not-exposed), `availability`, `requiredContext`, `readTimestamp`, `clientBuild`, `source=live_api|saved_alt|manual_simulation|external_evidence`, and `uncertainty`.
2. Add stable numerical child `skillLineID` vs parent profession ID, and `recipeID`. Do not rely on localized profession names alone or assume expansionIDs equal skillLineIDs.
3. Record **effective skill decomposition** when known: base skill, skill modifier, specialized bonus, operation base/bonus skill, gear vs other contributions if exposed. Don't add an unknown bonus to an already effective value.
4. Record actual specialization **nodeID, entryID, purchased rank and committed status**, plus mechanic rule applicability. Raw node states don't magically define a probability coefficient.
5. Record **profession gear inventory slot/item link**, actual item ID, item quality, stat ratings and skill bonuses if known, and whether the server's operation stat summary confirms them.
6. Preserve current `concentration` currency and operation `concentrationCost` (not a bonus yield), `ingenuityRefund`, stat `ratingPct`, `resourcefulness` returned-resource events, `multicraft` proc counts, and per-cast resource inputs.
7. Distinguish recipe `craftable`, `learned`, `disabled`, resource availability and output eligibility from historical drop probability.
8. Add event observation **completeness** flags: method tested, complete per-cast item histogram or partial event output, ignored other loot, failed craft, consumed input, bonus output, refunded ingredients; don't derive P(drop) from aggregate output totals.
9. Only one shipped bundled material mapping source: `GameData.lua`. The API registry remains **research-only** and exposes how to *read live context*, not alternate permanent yield mappings.
10. Live validation on a test character: DF prospect Rank1/3, TWW prospect/milling, Midnight prospect/milling and green/blue DE; verify API nil/data behavior with profession window closed/open, no profession, applied vs un-applied Concentration, correct specialization ranks, equipped gear changes and actual output events.

## Correctly limited conclusions

- This review verifies **documented API availability**, not the success of those APIs under all 2026 Retail recipe contexts.
- No documented addon API returns numeric hidden prospect/mill/disenchant probability or a historical hotfix multiplier.
- `GetRecipeSchematic` output quantity ranges pertain to **recipe output descriptions**, not necessarily per-output random material conditional yield limits.
- `GetProfessionInfoByRecipeID` documentation includes version-dependent variant-ID ambiguity. Validate via `GetTradeSkillLineForRecipe` and own-window context rather than depending on its `professionID` interpretation.
- `GetBuildInfo` gives the **client** patch build; exact server-side hotfix activation times may need externally versioned data.
- Do not use the vendor or AH price provided by TSM as a substitute for verified process output distribution; net price and output units remain separate.

## Primary source references

- https://warcraft.wiki.gg/wiki/API_C_TradeSkillUI.GetTradeSkillLineForRecipe
- https://warcraft.wiki.gg/wiki/API_C_TradeSkillUI.GetTradeSkillLine
- https://warcraft.wiki.gg/wiki/API_C_TradeSkillUI.GetProfessionInfoBySkillLineID
- https://warcraft.wiki.gg/wiki/API_C_TradeSkillUI.GetRecipeInfo
- https://warcraft.wiki.gg/wiki/API_C_TradeSkillUI.GetRecipeSchematic
- https://warcraft.wiki.gg/wiki/API_C_TradeSkillUI.GetCraftingOperationInfo
- https://warcraft.wiki.gg/wiki/API_C_TradeSkillUI.GetItemReagentQualityByItemInfo
- https://warcraft.wiki.gg/wiki/API_C_Traits.GetNodeInfo
- https://warcraft.wiki.gg/wiki/API_C_ProfSpecs.GetStateForPerk
- https://warcraft.wiki.gg/wiki/API_C_TradeSkillUI.GetConcentrationCurrencyID
- https://warcraft.wiki.gg/wiki/API_C_CurrencyInfo.GetCurrencyInfo
- https://warcraft.wiki.gg/wiki/Event:TRADE_SKILL_ITEM_CRAFTED_RESULT
- https://warcraft.wiki.gg/wiki/API_C_Container.GetContainerItemInfo
- https://warcraft.wiki.gg/wiki/API_GetBuildInfo
- https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_Tutorials/Blizzard_Tutorials_Professions.lua

**Next:** Implement a gated in-client read-only diagnostic, compare real recipe result API data to bag deltas, and repair skillline identification on a test branch. Do not promote untested code to release main.
