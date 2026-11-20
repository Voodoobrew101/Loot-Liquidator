"""Compile typed profession profile effects from the pinned client snapshot.

Description interpretation happens here, never in the addon. Every source entry
and effect has an explicit handler, including structural/non-economic effects.
Qualitative numerical priors carry confidence zero and never invent item IDs or
observed operations. Native labels and conditional state remain part of scope.
"""
from __future__ import annotations

import argparse
from collections import Counter, defaultdict
import copy
import hashlib
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "database/research/profession-effect-catalog-70961.json"
SPECIALIZATION = ROOT / "database/research/specialization-effects.json"
BINDINGS = ROOT / "database/research/profession-output-bindings.json"
QUALITY_MODELS = ROOT / "database/research/shatter-quality-models.json"
OUTPUT = ROOT / "database/profession-profile-rules.lua"
AUDIT = ROOT / "database/research/profession-profile-rule-coverage.json"
REPORT = ROOT / "research/mechanics/2026-11-19-profession-profile-coverage.md"
STAT_NAMES = {"resourcefulness": "resourcefulness", "multicraft": "multicraft", "ingenuity": "ingenuity",
              "finesse": "finesse", "perception": "perception", "deftness": "deftness", "crafting speed": "craftingSpeed"}
ENUMS = {
    0: ("skill", "skill"), 1: ("inspirationSkill", "rating"),
    2: ("resourcefulness", "rating"), 3: ("finesse", "rating"), 4: ("deftness", "rating"),
    5: ("perception", "rating"), 6: ("craftingSpeed", "rating"), 7: ("multicraft", "rating"),
    8: ("eligibility", "flag"), 9: ("inspirationSkill", "percent"),
    10: ("resourcefulness", "percent"), 11: ("finesse", "percent"),
    12: ("deftness", "percent"), 13: ("perception", "percent"),
    14: ("craftingSpeed", "percent"), 15: ("multicraft", "percent"), 16: ("deftness", "percent"),
    17: ("nonOutput", "rating"), 18: ("multicraftExtra", "percent"),
    19: ("finesseExtra", "percent"), 20: ("inspirationSkill", "percent"),
    21: ("resourcefulnessSaved", "percent"), 22: ("difficulty", "skill"),
    23: ("difficulty", "skill"), 24: ("nonOutput", "percent"),
    26: ("ingenuity", "rating"), 27: ("concentrationCost", "percent"),
    29: ("ingenuity", "percent"), 30: ("concentrationRefund", "percent"),
}
METRICS = sorted({metric for metric, _ in ENUMS.values()} | {"recipeUnlock", "extraOutput", "dropChance", "yieldMultiplier"})
UNITS = {"rating", "percent", "skill", "fraction", "quantity", "flag"}
DE_PATHS = {107649: None, 107648: 2, 107647: 3, 107646: 4,
            99890: None, 99889: 2, 99888: 3, 99887: 4}


def load_source(path=SOURCE):
    return json.loads(path.read_text(encoding="utf-8"))


def numeric_keys(value):
    if isinstance(value, list):
        return [numeric_keys(item) for item in value]
    if isinstance(value, dict):
        return {int(key) if isinstance(key, str) and key.isdigit() else key: numeric_keys(item)
                for key, item in value.items()}
    return value


def lua(value):
    if value is None:
        return "nil"
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        if value != value or abs(value) == float("inf"):
            raise ValueError("Nonfinite compiled number")
        return str(value)
    if isinstance(value, str):
        return json.dumps(value, ensure_ascii=False)
    if isinstance(value, list):
        return "{" + ",".join(lua(item) for item in value) + "}"
    return "{" + ",".join("[" + lua(key) + "]=" + lua(item) for key, item in value.items() if item is not None) + "}"


def spell_refs(entry):
    return sorted(({entry["spellID"]} if entry["spellID"] else set()) |
                  {int(value) for value in re.findall(r"\$@spell(?:name|desc)(\d+)", entry["description"], re.I)})


def build_recipes(source, items=None, families=None):
    routing = source["recipeRouting"]
    spells = {spell["spellID"]: spell for spell in routing["spells"]}
    data = {row["ID"]: row for row in routing["craftingData"]}
    quality_tiers = {row["ID"]: row["QualityTier"] for row in routing["craftingQualities"]}
    items = items if items is not None else {int(identity): copy.deepcopy(item) for identity, item in routing.get("items", {}).items()}
    families = families if families is not None else {int(identity): copy.deepcopy(family) for identity, family in routing.get("qualityFamilies", {}).items()}
    result = {}
    for native in routing["recipes"]:
        identity = native["spellID"]
        if identity in result:
            result[identity]["sourceAbilityIDs"].append(native["recordID"])
            continue
        spell = spells.get(identity, {})
        recipe = {"profession": native["profession"], "expansionID": native["expansionID"],
                  "parentSkillLineID": native["parentSkillLineID"], "skillLineID": native["skillupSkillLineID"],
                  "minimumSkill": native["minimumSkill"], "requiredSkill": native["minimumSkill"],
                  "labels": native["labels"], "sourceAbilityIDs": [native["recordID"]],
                  "outputs": [], "outputIDs": [], "qualityOrderVerified": False}
        if spell.get("baseDuration") is not None and not any(effect["Effect"] == 302 for effect in spell.get("effects", [])):
            recipe["baseDuration"] = spell["baseDuration"]
            recipe["baseDurationSource"] = spell["castTimeSource"]
        effects = spell.get("effects", [])
        crafting_ids = sorted({effect["craftingDataID"] for effect in effects if effect.get("craftingDataID")})
        output_ids = set()
        for effect in effects:
            if effect["Effect"] in (24, 157) and effect["EffectItemType"]:
                output_ids.add(effect["EffectItemType"])
                if effect["EffectBasePointsF"] > 0:
                    recipe["outputCount"] = effect["EffectBasePointsF"]
            elif effect["Effect"] == 288 and effect["EffectBasePointsF"] > 0:
                recipe["outputCount"] = effect["EffectBasePointsF"]
            elif effect["Effect"] == 296:
                recipe["inputCount"] = effect["EffectBasePointsF"]
                recipe["salvage"] = True
        if len(crafting_ids) == 1:
            craft = data[crafting_ids[0]]
            recipe.update({"craftingDataID": craft["ID"], "difficulty": craft["CraftingDifficulty"],
                           "craftedTreasureID": craft["CraftedTreasureID"] or None})
            recipe["itemBonusTreeID"] = craft["ItemBonusTreeID"]
            if craft["CraftedItemID"]:
                output_ids.add(craft["CraftedItemID"])
            output_ids.update(row["ItemID"] for row in craft["itemQualityRows"] if row["ItemID"])
            output_ids.update(row["ItemID"] for row in craft["enchantQualityRows"] if row["ItemID"])
            ranks = {item: items[item]["qualityRank"] for item in output_ids if items.get(item, {}).get("qualityRank")}
            for row in craft["enchantQualityRows"]:
                if row["ItemID"] and row["ItemID"] not in ranks:
                    ranks[row["ItemID"]] = row["Rank"]
            recipe["outputs"] = [{"itemID": item, "qualityRank": ranks.get(item)} for item in sorted(output_ids)]
            native_family_ids = {items[item].get("qualityFamilyID") for item in output_ids if item in items}
            family_id = next(iter(native_family_ids)) if len(native_family_ids) == 1 else None
            complete_ranks = bool(ranks) and set(ranks) == output_ids and sorted(ranks.values()) == list(range(1, len(ranks) + 1))
            if complete_ranks and len(ranks) >= 2 and not family_id:
                family_id = "crafting-data:" + str(craft["ID"])
                families[family_id] = {"rankItemIDs": [item for item, rank in sorted(ranks.items(), key=lambda pair: pair[1])],
                    "qualityOrderVerified": True, "source": "CraftingDataItemQuality + Item.CraftingQualityID -> CraftingQuality.QualityTier"}
                for item in output_ids:
                    if item in items and not items[item].get("qualityFamilyID"):
                        items[item]["qualityFamilyID"] = family_id
            if complete_ranks:
                recipe["qualityOrderVerified"] = True
                recipe["outputQualityItems"] = {rank: {"id": item} for item, rank in ranks.items()}
                recipe["qualityFamilyID"] = family_id
            recipe["qualityThresholds"] = [{"rank": quality_tiers[row["CraftingQualityID"]],
                "fraction": row["QualityPercentage"] / 100, "sourceRowID": row["ID"]}
                for row in craft["difficultyQualityRows"]]
            recipe["supportsQuality"] = craft["CraftingDifficulty"] > 0 and len(recipe["qualityThresholds"]) > 1
            if craft["ItemBonusTreeID"]:
                recipe.update({"outputKind": "gear-quality", "supportsMulticraft": False,
                               "capabilityEvidence": {"multicraft": "DB2_GEAR_BONUS_TREE_MODEL"},
                               "capabilityConfidence": {"multicraft": 70}})
            elif craft["enchantQualityRows"]:
                recipe.update({"outputKind": "enchant", "supportsMulticraft": False,
                               "capabilityEvidence": {"multicraft": "DB2_ENCHANT_FAMILY_MODEL"},
                               "capabilityConfidence": {"multicraft": 70}})
            elif len(craft["itemQualityRows"]) > 1 and any(effect["Effect"] == 288 for effect in effects):
                recipe.update({"outputKind": "ranked-material-family", "supportsMulticraft": True,
                               "capabilityEvidence": {"multicraft": "DB2_RANKED_MATERIAL_FAMILY_MODEL"},
                               "capabilityConfidence": {"multicraft": 60}})
            if any(effect["Effect"] == 288 for effect in effects):
                recipe["supportsResourcefulness"] = True
                recipe.setdefault("capabilityEvidence", {})["resourcefulness"] = "REGULAR_MODERN_CRAFT_MODEL"
                recipe.setdefault("capabilityConfidence", {})["resourcefulness"] = 35
            difficulty_row = craft.get("difficultyRow") or {}
            if recipe["supportsQuality"] and difficulty_row.get("ConcentrationSkillCurveID") and difficulty_row.get("ConcentrationDifficultyCurveID"):
                recipe["supportsIngenuity"] = True
                recipe.setdefault("capabilityEvidence", {})["ingenuity"] = "NATIVE_CONCENTRATION_CURVES_MODEL"
                recipe.setdefault("capabilityConfidence", {})["ingenuity"] = 60
        recipe["outputIDs"] = sorted(output_ids)
        if not recipe["outputs"]:
            recipe["outputs"] = [{"itemID": item} for item in sorted(output_ids)]
        classes = {items[item]["classID"] for item in output_ids if item in items}
        if len(classes) == 1:
            recipe["outputClassID"] = next(iter(classes))
        if classes & {2, 4}:
            recipe["supportsMulticraft"] = False
            recipe["outputKind"] = "equipment"
            recipe.setdefault("capabilityEvidence", {})["multicraft"] = "NATIVE_ITEM_EQUIPMENT_CLASS"
            recipe.setdefault("capabilityConfidence", {})["multicraft"] = 90
        elif classes and classes <= {0, 3, 7} and native["expansionID"] in (9, 10, 11) and any(effect["Effect"] in (24, 288) for effect in effects):
            recipe["supportsMulticraft"] = True
            if recipe.get("outputKind") == "gear-quality":
                recipe["outputKind"] = "material"
            recipe.setdefault("capabilityEvidence", {})["multicraft"] = "NATIVE_ITEM_MATERIAL_CLASS_MODEL"
            recipe.setdefault("capabilityConfidence", {})["multicraft"] = 60
        if output_ids and all(items.get(item, {}).get("stackable") == 1 for item in output_ids):
            recipe["supportsMulticraft"] = False
            recipe.setdefault("capabilityEvidence", {})["multicraft"] = "NATIVE_NONSTACKABLE_OUTPUT"
            recipe.setdefault("capabilityConfidence", {})["multicraft"] = 85
        # These capability inferences are explicitly distinct from native flags.
        # Exact operation.bonusStats and recipe-specific mechanic rules override
        # them; absent cases remain unknown, not false.
        result[identity] = recipe
    return dict(sorted(result.items())), spells


def entry_scope(node, entry, nodes, recipes):
    labels, origin = list(entry["labelIDs"]), "entry"
    ancestor = node
    seen = set()
    while not labels and ancestor and ancestor["nodeID"] not in seen:
        seen.add(ancestor["nodeID"])
        labels = sorted({label for candidate in ancestor["baseEntries"] for label in candidate["labelIDs"]})
        origin = "node" if ancestor is node else "ancestor"
        ancestor = nodes.get(ancestor.get("parentID"))
    scope = {"labelIDs": labels, "labelSource": origin if labels else "none", "profession": node["profession"],
             "expansionID": node["expansionID"]}
    if node["nodeID"] in DE_PATHS:
        scope["method"] = "Disenchant"
        if DE_PATHS[node["nodeID"]] is not None:
            scope["inputRarity"] = DE_PATHS[node["nodeID"]]
    elif node["profession"] in {"Herbalism", "Mining", "Skinning"}:
        scope["method"] = "Gather"
    text = entry["resolvedDescription"].lower()
    if "prospect" in text:
        scope["method"] = "Prospect"
    elif "milling" in text:
        scope["method"] = "Mill"
    elif "disenchant" in text:
        scope["method"] = "Disenchant"
        for word, rarity in (("uncommon", 2), ("rare", 3), ("epic", 4)):
            if re.search(r"\b" + word + r" (?:items?|equipment)\b", text):
                scope["inputRarity"] = rarity
        if "weapons" in text and "armor" not in text:
            scope["inputClassID"] = 2
    elif "recycling" in text:
        scope["method"] = "Recycle"
    elif "refining" in text:
        scope["method"] = "Refine"
    elif "unraveling" in text:
        scope["method"] = "Unravel"
    elif "cloth" in text and re.search(r"drop|humanoid|found from", text):
        scope["method"] = "Loot"
    elif "darkmoon cards" in text or "mystic items" in text:
        scope["method"] = "Loot"
    elif re.search(r"using (?:tinkers|explosives)|use your tinkers|throw bombs|consum(?:e|ing) (?:a |an )?(?:flask|phial|potion)", text):
        scope["method"] = "Use"
    if "mystic items" in text or "darkmoon cards" in text:
        scope["method"] = "Loot"
    if scope.get("method") == "Disenchant":
        scope["labelContext"] = "disenchant-input"
    refs = spell_refs(entry)
    # Unlock recipe IDs are provenance/availability, not automatically the scope
    # of another simultaneous stat bonus in the same description.
    if refs:
        scope["referencedSpellIDs"] = refs
    if not labels and scope.get("method") not in {"Disenchant", "Gather"}:
        scope["scopeUnknown"] = True
    return scope


def conditions(text, entry):
    result = {}
    refs = spell_refs(entry)
    if "whenever you consume" in text or "consuming " in text:
        result["event"] = "consume"
    elif "first" in text and ("each day" in text or "per day" in text):
        result["event"] = "first-daily-craft"
        result["maxPerDay"] = 1
    if "while active" in text or "subsequent crafts" in text or "stacking up to" in text or "whenever you achieve" in text or "which increases" in text and "hours" in text:
        result["requiresActiveBuff"] = True
        result["spellIDs"] = refs
    duration = re.search(r"(?:within|for) (\d+) (sec(?:onds?)?|min(?:utes?)?|hours?)", text)
    if duration:
        result["durationSeconds"] = int(duration[1]) * (3600 if duration[2].startswith("hour") else 1 if duration[2].startswith("sec") else 60)
    stacks = re.search(r"stacking up to (\d+) times", text)
    if stacks:
        result["maxStacks"] = int(stacks[1])
    if "if all" in text and "recipes are known" in text:
        result["contextFlags"] = {"allRelevantRecipesKnown": True}
    if "when experimenting" in text or "experimentation" in text:
        result.setdefault("contextFlags", {})["experimentation"] = True
    if "overload" in text:
        result.setdefault("contextFlags", {})["overload"] = True
    if "arcane duplication" in text:
        result.setdefault("contextFlags", {})["arcaneDuplication"] = True
    if "defeated" in text or "plant creatures" in text:
        result.setdefault("contextFlags", {})["creatureGather"] = True
    if "if you know its schematic" in text:
        result.setdefault("contextFlags", {})["relevantRecipeKnown"] = True
    if "shattered power lingers" in text:
        result["requiresActiveBuff"] = True
        result.setdefault("contextFlags", {})["elementalShatterActive"] = True
    return result


def compile_entry(node, entry, nodes, recipes):
    text = entry["resolvedDescription"].lower()
    scope = entry_scope(node, entry, nodes, recipes)
    condition = conditions(text, entry)
    refs = spell_refs(entry)
    output_ids = sorted({item for spell in refs for item in recipes.get(spell, {}).get("outputIDs", [])})
    provenance = {"entryID": entry["entryID"], "definitionID": entry["definitionID"]}
    compiled = []

    def emit(metric, amount=1, unit="flag", confidence=90, mechanism=None, source_effects=None, **extra):
        result = {"metric": metric, "amount": amount, "unit": unit, "confidence": confidence,
                  **provenance, "scope": dict(scope), "mechanism": mechanism or metric,
                  "sourceEffectIDs": source_effects or [], **extra}
        if condition:
            result["condition"] = dict(condition)
            if condition.get("requiresActiveBuff"):
                result["condition"]["manualStateKey"] = entry["entryID"]
        result["effectID"] = "entry:" + str(entry["entryID"]) + ":" + metric + ":" + str(len(compiled) + 1)
        compiled.append(result)

    custom = []
    for effect in entry["effects"]:
        enum = effect["typeEnum"]
        if enum in ENUMS:
            metric, unit = ENUMS[enum]
            extra = {"operator": "subtract"} if enum in (22, 27) else {}
            if enum == 8:
                extra["reagentSlotID"] = effect["modifiedReagentSlotID"]
            extra["sourceAmount"] = effect["amount"]
            emit(metric, 1 if enum == 8 else effect["amount"], unit, 85 if enum not in (18, 19, 20, 21, 24) else 60,
                 mechanism="client-effect-" + str(enum), source_effects=[effect["effectID"]], **extra)
        elif enum == 25 and (node["nodeID"] in DE_PATHS or re.search(r"\bskill\b", text) and not re.search(r"skill.?ups?|chance|additional .*materials|transmutagen", text)):
            emit("skill", effect["amount"], "skill", 60 if node["nodeID"] == 107646 else 80,
                 mechanism="label-scoped-skill", source_effects=[effect["effectID"]])
        else:
            custom.append(effect)
    custom_ids = sorted({effect["effectID"] for effect in custom})
    numeric_metrics = {effect["metric"] for effect in compiled}

    # Blank/narrative path-learning entries have no material-unit coefficient.
    if entry["entryType"] == 9 and not entry["effects"]:
        emit("nonOutput", mechanism="path-learning", source_effects=custom_ids)
    else:
        # Resolve static stat numbers in token-only buff descriptions without
        # treating their dummy stack-count/duration values as stat magnitudes.
        stat_number = re.search(r"\+(\d+(?:\.\d+)?) (?:resourcefulness|multicraft|ingenuity|finesse|perception|deftness|crafting speed)", text)
        if not stat_number and any(name in text for name in STAT_NAMES):
            stat_number = re.search(r"(?:ingenuity|multicraft|resourcefulness|finesse|perception|deftness|crafting speed) by (\d+)(?![%\d])", text)
        if stat_number and (custom or not entry["effects"]):
            for name, key in STAT_NAMES.items():
                if name in text and key not in numeric_metrics:
                    emit(key, float(stat_number[1]), "rating", 60 if not condition else 25,
                         mechanism="conditional-stat-buff" if condition else "explicit-text-stat", source_effects=custom_ids)
        stat_percent = re.search(r"(\d+(?:\.\d+)?)% (?:crafting speed|resourcefulness|multicraft|ingenuity|finesse|perception|deftness)", text)
        if stat_percent and (custom or not entry["effects"]):
            for name, key in STAT_NAMES.items():
                if name in text and key not in numeric_metrics:
                    emit(key, float(stat_percent[1]), "percent", 50 if condition else 70,
                         mechanism="conditional-stat-buff" if condition else "explicit-text-stat", source_effects=custom_ids)
        if re.search(r"learn|unlock|discover|allows you|ability to|may now", text) and refs:
            emit("recipeUnlock", mechanism="native-spell-unlock", source_effects=custom_ids,
                 recipeIDs=refs, outputItemIDs=output_ids)
        elif re.search(r"discover .*transmutations|discover .*recipes|learn .*recipes|teaches you the recipe|can now create", text):
            emit("recipeUnlock", mechanism="recipe-unlock-identity-unresolved", source_effects=custom_ids,
                 recipeIDs=refs, outputItemIDs=output_ids, identityUnresolved=not bool(refs))
        if re.search(r"sub-specialization|subspecialization|specialization of your choice|final specialization", text):
            emit("nonOutput", mechanism="specialization-branch-unlock", source_effects=custom_ids)

        savings_term = "resourcefulness" in text and bool(re.search(r"sav|refund|recover|effectiveness|yield", text))
        if savings_term and "resourcefulnessSaved" not in numeric_metrics:
            percent = re.search(r"(\d+(?:\.\d+)?)%", text)
            emit("resourcefulnessSaved", float(percent[1]) if percent else 5, "percent", 70 if percent else 0,
                 mechanism="resourcefulness-input-savings", source_effects=custom_ids)
        if ("refund" in text or "return" in text) and "concentration" in text and "concentrationRefund" not in numeric_metrics:
            percent = re.search(r"(\d+(?:\.\d+)?)%", text)
            emit("concentrationRefund", float(percent[1]) if percent else 5, "percent", 70 if percent else 0,
                 mechanism="concentration-refund", source_effects=custom_ids)

        # These are per-operation quantity/occurrence opportunities, not a
        # universal interpretation of enum25. Unknown output identities are
        # referenced through the selected legal recipe/baseline, never invented.
        pure_non_material = bool(re.search(r"malfunction|explod(?:e|ing) in your face|success chance|recovery time|exhaust.*magic|additional bolts per day|last twice as long|teleport|portals?|restore \d+ vigor|protective layer|freezing targets|slowfall|slowed by|knockback|hallucinations|caught in the sticky|immediately set one off|frequency in which|gather.*quicker|abilities cause the enemy|hazardous outcome", text))
        buff_configuration = bool(re.search(r"(?:maximum stacks|effectiveness) of \$@spellname\d+|maximum stacks.*doubled", text))
        if pure_non_material or buff_configuration:
            emit("nonOutput", mechanism="conditional-buff-configuration" if buff_configuration else "time-convenience-progression", source_effects=custom_ids)
        if re.search(r"rate you can .*by (\d+)%", text):
            speed = re.search(r"rate you can .*by (\d+)%", text)
            emit("craftingSpeed", int(speed[1]), "percent", 60, mechanism="processing-speed", source_effects=custom_ids)
        extra_pattern = r"additional (?:materials?|reagents?|items?|gems?|transmutagen|.*transmutagen|herb|rousing|ore|alchemical)|extract|(?:chance|sometimes) to (?:receive|recover|create|find|obtain)|sometimes (?:reveal|recover|spot)|now (?:also )?grant|yield(?:s)? .*extra|increas.*(?:yield|output)|more .*when multicrafting|amount of .*receive|chance.*(?:gather|find|uncover|acquir|retriev|locate|collect|recover|yield|contain|dislodge|grant)|more often|more likely to find|sometimes.*(?:result|draw|grant)|more .*motes|(?:minimum|maximum) (?:amount|possible yield|scrap yield)|grant you \d+ soulbound|rec(?:ei|ie)ve additional|grants? (?:additional|bonus)|retain.*(?:vial|shards)|now yield a small amount|now also grant|can now drop|can now discover|able to (?:collect|retrieve)|may (?:acquire|impulsively)|grant.*scrap|cloth.*(?:drop|found from)|(?:locate|find|spot).*diamonds|extra materials|gain a random|number of motes|more herb chunks|more writhing|amount of reagents.*increased|twice as many|often recover|chance to also create|find darkmoon cards|collect wildercloth|more ore from finesse|guarantee a rousing element"
        discovery_only = bool(re.search(r"discover.*recipes|learn.*recipes", text)) and not re.search(r"additional|yield|grant|recover|receive", text)
        if re.search(extra_pattern, text) and not pure_non_material and not buff_configuration and not savings_term and not discovery_only and not ("multicraftExtra" in numeric_metrics and "multicraft" in text):
            amount = re.search(r"(?:grant you|gain|yields?|receive) (\d+) (?:additional |extra |soulbound |conjured )", text)
            explicit_percent = re.search(r"(\d+(?:\.\d+)?)%", text)
            finesse_conditional = "finesse" in text and "finesseExtra" not in numeric_metrics
            metric = "finesseExtra" if finesse_conditional else "dropChance" if explicit_percent else "extraOutput"
            magnitude = float(explicit_percent[1]) if explicit_percent else 5 if finesse_conditional else float(amount[1]) if amount else .05
            unit = "percent" if finesse_conditional or explicit_percent else "quantity"
            if amount is None and not explicit_percent and not finesse_conditional:
                magnitude = .0001 if "extremely rare" in text else .001 if "very rare" in text or "diamond" in text else .05
            relative = bool(explicit_percent and ("increase" in text or "increased" in text) and not re.search(r"\+\d+(?:\.\d+)?%", text))
            specific_loot = "darkmoon cards" in text or "mystic items" in text
            emit(metric, magnitude, unit, 50 if amount or explicit_percent else 0,
                 mechanism="finesse-conditional-yield-prior" if finesse_conditional else "explicit-extra-output" if amount or explicit_percent else "qualitative-extra-output-prior", source_effects=custom_ids,
                 outputItemIDs=output_ids, recipeIDs=refs,
                 legalOutputRefs={"kind": "native-recipe-or-selected-baseline", "recipeIDs": refs, "itemIDs": output_ids},
                 economicPolicy="nontradable" if "soulbound" in text else "normal",
                 identityUnresolved=not bool(output_ids),
                 operator="multiply" if relative else "add",
                 baselineOutputFallback=not specific_loot,
                 targetFamily="Darkmoon Cards" if "darkmoon cards" in text else "Mystic Items" if "mystic items" in text else None)
        if ("breakthrough" in text or "discover" in text) and "chance" in text:
            percent = re.search(r"(\d+(?:\.\d+)?)%", text)
            emit("eligibility", float(percent[1]) if percent else 5, "percent", 50 if percent else 0,
                 mechanism="recipe-discovery-chance", source_effects=custom_ids)
        if "chance to not consume" in text:
            emit("resourcefulnessSaved", 5, "percent", 0, mechanism="consumable-refund-prior", source_effects=custom_ids)
        if "see camoflauged herbs" in text or "lure the elite" in text or "ability to get useful herbs" in text:
            emit("eligibility", mechanism="gather-target-unlock", source_effects=custom_ids)
        if "shattered power lingers" in text and "skill" not in numeric_metrics:
            emit("skill", 1, "skill", 0, mechanism="conditional-shatter-skill-prior", source_effects=custom_ids)
        if "guarantee a rousing element" in text:
            compiled[:] = [effect for effect in compiled if effect["metric"] != "extraOutput"]
            emit("dropChance", 100, "percent", 0, mechanism="guaranteed-specific-output-occurrence",
                 source_effects=custom_ids, operator="set", targetFamily="Rousing Elements",
                 identityUnresolved=True, baselineOutputFallback=False,
                 requiredContextFlags={"specificElementalCloth": True})
        if not compiled or custom and not any(effect["sourceEffectIDs"] for effect in compiled):
            if re.search(r"cooldown|recharg|charges?|duration|last longer|minutes longer|lasts an additional|more frequently|higher capacity|mounted|dismount|movement|combat|damage|heal|health|repair|skill.?ups?|skill gain|range|radius|reach|knowledge|slow|sticky|hallucination|exhaust|wyrmhole|triangulate", text):
                emit("nonOutput", mechanism="time-convenience-progression", source_effects=custom_ids)
            elif refs and not text:
                emit("recipeUnlock", mechanism="native-spell-unlock", source_effects=custom_ids,
                     recipeIDs=refs, outputItemIDs=output_ids)
            elif custom or entry["description"]:
                emit("extraOutput", .01, "quantity", 0, mechanism="unresolved-qualitative-output-prior",
                     source_effects=custom_ids, outputItemIDs=output_ids, recipeIDs=refs,
                     legalOutputRefs={"kind": "native-recipe-or-selected-baseline", "recipeIDs": refs, "itemIDs": output_ids},
                     identityUnresolved=not bool(output_ids), requiresSemanticReview=True)
            else:
                emit("nonOutput", mechanism="structural-entry", source_effects=custom_ids)
    # Any special entry portion still has an explicit handler rather than being
    # silently dropped beside a separately recognized numeric stat effect.
    assigned = {identity for effect in compiled for identity in effect["sourceEffectIDs"]}
    remaining = sorted(set(custom_ids) - assigned)
    if remaining:
        emit("extraOutput", .01, "quantity", 0, mechanism="unresolved-client-modifier-prior", source_effects=remaining,
             legalOutputRefs={"kind": "native-recipe-or-selected-baseline", "recipeIDs": refs, "itemIDs": output_ids},
             identityUnresolved=not bool(output_ids), requiresSemanticReview=True)
    return compiled


def build_gathering_targets(recipes, spells, items, families):
    by_name = defaultdict(list)
    for identity, item in items.items():
        if item.get("name") and item["classID"] == 7 and item["subclassID"] in (6, 7, 9):
            name = item["name"].lower()
            by_name[name].append(identity)
            if name.endswith(" ore"):
                by_name[name[:-4]].append(identity)
    by_expansion = defaultdict(dict)
    for name, identities in by_name.items():
        for expansion in {items[identity].get("expansionID") for identity in identities}:
            by_expansion[expansion][name] = [identity for identity in identities if items[identity].get("expansionID") == expansion]
    alias_patterns = {expansion: [(re.compile(r"(?<!\w)" + re.escape(name) + r"(?!\w)"), identities)
        for name, identities in sorted(names.items(), key=lambda pair: (-len(pair[0]), pair[0]))]
        for expansion, names in by_expansion.items()}
    result = {}
    for spell_id, recipe in recipes.items():
        if recipe["profession"] not in {"Herbalism", "Mining", "Skinning"} or recipe.get("expansionID") not in (9, 10, 11):
            continue
        spell = spells.get(spell_id, {})
        effects = [effect for effect in spell.get("effects", []) if effect["Effect"] == 302]
        name = spell.get("name", "").lower()
        matches = by_expansion[recipe["expansionID"]].get(name, [])
        exact_name = bool(matches) and all(items[identity]["name"].lower() == name for identity in matches)
        if effects and not matches:
            for pattern, candidates in alias_patterns[recipe["expansionID"]]:
                if pattern.search(name):
                    matches = candidates
                    break
        if not effects or not matches:
            continue
        ranked = sorted((items[identity].get("qualityRank") or 1, identity) for identity in matches)
        if [rank for rank, _ in ranked] != list(range(1, len(ranked) + 1)):
            continue
        family_ids = {items[identity].get("qualityFamilyID") for _, identity in ranked}
        if len(ranked) > 1 and (len(family_ids) != 1 or None in family_ids):
            continue
        maximum = len(ranked)
        difficulty_parameter = max(effect["EffectBasePointsF"] for effect in effects)
        thresholds = [{"rank": rank, "fraction": (rank - 1) / (maximum - 1) if maximum > 1 else 0,
                       "confidence": 0, "model": "even-tier-gathering-threshold-prior"} for rank, _ in ranked]
        generic_spell = {"Herbalism": 2366, "Mining": 2575, "Skinning": 8613}[recipe["profession"]]
        generic_timing = spells.get(generic_spell, {})
        duration = generic_timing.get("baseDuration")
        target = {"spellID": spell_id, "recipeID": spell_id, "name": spell["name"],
            "targetID": "native-gather-spell:" + str(spell_id), "nativeTargetID": "spell:" + str(spell_id),
            "label": spell["name"], "method": "Gather", "qualityConfidence": 0,
            "profession": recipe["profession"], "expansionID": recipe["expansionID"], "skillLineID": recipe["skillLineID"],
            "minimumSkill": recipe["minimumSkill"], "requiredSkill": recipe["requiredSkill"], "labels": recipe["labels"],
            "primaryOutputIDs": [identity for _, identity in ranked], "primaryFamilyID": next(iter(family_ids)),
            "qualityOrderVerified": True, "identityConfidence": 90 if exact_name else 80,
            "identitySource": "Native SkillLineAbility + gathering Effect302 + exact/ore-suffix/material-modifier native names + Item crafting quality",
            "sourceAbilityIDs": recipe["sourceAbilityIDs"], "sourceEffectIDs": [effect["ID"] for effect in effects],
            "difficulty": difficulty_parameter, "nativeDifficultyParameter": difficulty_parameter,
            "difficultySourceField": "SpellEffect.EffectBasePointsF", "difficultyConfidence": 0,
            "qualityThresholds": thresholds,
            "baseline": {"inputCount": 1, "confidence": 0,
                "baselineProfile": {"skill": recipe["minimumSkill"], "preSpecializationSkill": recipe["minimumSkill"],
                                    "specializationPoints": {}, "stats": {}},
                "materials": [{"id": ranked[0][1], "expectedQuantity": 1, "confidence": 0}],
                "primaryOutputIDs": [identity for _, identity in ranked],
                "model": "canonical-unit-minimum-profile-prior", "observedYield": False}}
        if duration is not None and duration > 0:
            target["baseDuration"] = duration
            target["baseDurationSource"] = {"genericGatheringSpellID": generic_spell, **generic_timing["castTimeSource"]}
            target["baseline"]["duration"] = duration
            recipe["baseDuration"] = duration
            recipe["baseDurationSource"] = target["baseDurationSource"]
        result[spell_id] = target
    return result


def build(source):
    items = {int(identity): copy.deepcopy(item) for identity, item in source["recipeRouting"].get("items", {}).items()}
    families = {int(identity): copy.deepcopy(family) for identity, family in source["recipeRouting"].get("qualityFamilies", {}).items()}
    recipes, spells = build_recipes(source, items, families)
    gathering_targets = build_gathering_targets(recipes, spells, items, families)
    nodes = {node["nodeID"]: node for node in source["nodes"]}
    globals_by_name = {row["profession"]: {"parentSkillLineID": row["parentSkillLineID"], **row["professionRecord"]}
                       for row in source["professionParameters"]}
    profiles, statuses, clusters, entry_audit = {}, Counter(), {}, []
    unresolved_output, conditional_unknown, effect_summary = [], [], Counter()
    dedicated_rules = json.loads(SPECIALIZATION.read_text(encoding="utf-8"))["rules"]
    binding_document = json.loads(BINDINGS.read_text(encoding="utf-8")) if BINDINGS.exists() else {}
    output_bindings = {row["entryID"]: row for row in binding_document.get("bindings", [])}
    for source_node in source["nodes"]:
        key = source_node["catalogKey"]
        profile = profiles.setdefault(key, {"profession": source_node["profession"], "expansionID": source_node["expansionID"],
            "lineID": source_node["lineID"], "parentSkillLineID": globals_by_name[source_node["profession"]]["parentSkillLineID"],
            "nodes": {}})
        node = {"name": source_node["name"], "maxRank": source_node["maxInvestedRank"], "parentID": source_node["parentID"],
                "pointEffects": [], "learningEffects": [], "milestones": []}

        def convert(entry):
            effects = compile_entry(source_node, entry, nodes, recipes)
            for effect in effects:
                shatter = recipes.get(470726)
                if effect["metric"] == "skill" and effect["scope"].get("method") == "Disenchant" and shatter:
                    if set(effect["scope"].get("labelIDs", [])) & set(shatter.get("labels", [])):
                        effect["scope"]["alternateRecipeIDs"] = [470726]
                        effect["scope"]["alternateMethod"] = "Craft"
                if effect["metric"] == "finesseExtra":
                    effect["outputBinding"] = {"kind": "gather-target-primary", "itemIDs": []}
                    effect["identityUnresolved"] = False
                    effect["identityConfidence"] = 80
                binding = output_bindings.get(entry["entryID"])
                if binding and effect["metric"] in {"extraOutput", "dropChance"}:
                    kind = {"verified-recipe-primary": "recipe-primary",
                            "verified-gather-target-primary": "gather-target-primary",
                            "fixed-family": "fixed-family", "named-family": "named-family"}.get(binding["kind"])
                    if kind:
                        effect["outputBinding"] = {"kind": kind, "itemIDs": binding.get("itemIDs", [])}
                        family_name = binding.get("name") or binding.get("familyName")
                        if family_name:
                            effect["outputBinding"]["name"] = family_name
                        for flag in ("requiresTargetOutputFilter", "requiresRenownedTarget"):
                            if binding.get(flag):
                                effect["outputBinding"][flag] = True
                        if kind == "named-family":
                            if not effect["outputBinding"]["name"]:
                                raise ValueError("Named output binding has no source-backed family name")
                        effect["outputItemIDs"] = binding.get("itemIDs", [])
                        effect["identityConfidence"] = binding["identityConfidence0to100"]
                        effect["identityUnresolved"] = kind == "named-family"
                        effect["baselineOutputFallback"] = False
                        effect["economicPolicy"] = binding.get("economicPolicy", effect.get("economicPolicy", "normal"))
                        effect["bindingSourceEntryID"] = binding["entryID"]
            source_ids = {effect["effectID"] for effect in entry["effects"]}
            covered = {identity for effect in effects for identity in effect["sourceEffectIDs"]}
            if not source_ids <= covered:
                raise ValueError(f"Unmapped effect at entry {entry['entryID']}")
            for effect in effects:
                if effect["metric"] not in METRICS or effect["unit"] not in UNITS:
                    raise ValueError("Unsupported typed effect")
                statuses[effect["mechanism"]] += 1
                if effect["metric"] == "nonOutput":
                    effect_summary["explicitNonOutputHandlers"] += 1
                elif effect.get("outputBinding", {}).get("kind") == "named-family":
                    effect_summary["namedUnpricedOutputHandlers"] += 1
                elif effect["metric"] in {"extraOutput", "dropChance"} and effect.get("identityUnresolved"):
                    effect_summary["unresolvedOutputIdentityHandlers"] += 1
                else:
                    effect_summary["typedNumericOrEligibilityHandlers"] += 1
                if effect["metric"] in {"extraOutput", "dropChance"} and effect.get("identityUnresolved"):
                    effect_summary["unresolvedOutputItemIDHandlers"] += 1
                    unresolved_output.append({"entryID": entry["entryID"], "definitionID": entry["definitionID"],
                        "nodeID": source_node["nodeID"], "nodeName": source_node["name"], "profession": source_node["profession"],
                        "expansionID": source_node["expansionID"], "metric": effect["metric"], "mechanism": effect["mechanism"],
                        "description": entry["resolvedDescription"], "scope": effect["scope"],
                        "knownSpellIDs": spell_refs(entry), "knownOutputItemIDs": effect.get("outputItemIDs", []),
                        "outputBinding": effect.get("outputBinding"), "confidence": effect["confidence"]})
                if effect["confidence"] == 0 and effect["metric"] != "nonOutput":
                    effect_summary["zeroConfidenceModelTerms"] += 1
                if effect.get("outputBinding", {}).get("requiresTargetOutputFilter"):
                    effect_summary["targetFilteredOutputHandlers"] += 1
                if effect.get("condition", {}).get("requiresActiveBuff") and not effect["condition"].get("spellIDs"):
                    conditional_unknown.append({"entryID": entry["entryID"], "nodeID": source_node["nodeID"],
                        "nodeName": source_node["name"], "metric": effect["metric"], "manualStateKey": entry["entryID"],
                        "description": entry["resolvedDescription"]})
            cluster_id = hashlib.sha256(entry["resolvedDescription"].encode()).hexdigest()[:16]
            cluster = clusters.setdefault(cluster_id, {"description": entry["resolvedDescription"], "entryIDs": [],
                "mechanisms": sorted({effect["mechanism"] for effect in effects}), "metrics": sorted({effect["metric"] for effect in effects})})
            cluster["mechanisms"] = sorted(set(cluster["mechanisms"]) | {effect["mechanism"] for effect in effects})
            cluster["metrics"] = sorted(set(cluster["metrics"]) | {effect["metric"] for effect in effects})
            cluster["entryIDs"].append(entry["entryID"])
            entry_audit.append({"nodeID": source_node["nodeID"], "entryID": entry["entryID"],
                "sourceEffectIDs": sorted(source_ids), "handlerCount": len(effects), "clusterID": cluster_id})
            return effects

        for entry in source_node["baseEntries"]:
            target = node["pointEffects"] if entry["entryType"] == 7 else node["learningEffects"]
            effects = convert(entry)
            if entry["entryType"] == 7:
                dedicated = [rule["ruleID"] for rule in dedicated_rules if rule.get("nodeID") == source_node["nodeID"]
                             and rule.get("expansionID") == source_node["expansionID"]
                             and rule.get("kind") in ("replace-family", "quantity-multiplier")]
                if dedicated:
                    for effect in effects:
                        if effect["metric"] in {"extraOutput", "dropChance", "yieldMultiplier", "eligibility"}:
                            effect["dedicatedHandler"] = "specialization-rule"
                            effect["dedicatedRuleIDs"] = sorted(dedicated)
            target.extend(effects)
        for milestone in source_node["milestones"]:
            effects = [effect for entry in milestone["entries"] for effect in convert(entry)]
            dedicated = [rule["ruleID"] for rule in dedicated_rules if rule.get("nodeID") == source_node["nodeID"]
                         and rule.get("expansionID") == source_node["expansionID"] and rule.get("kind") == "replace-family"]
            if dedicated and any("instead of" in entry["resolvedDescription"].lower() for entry in milestone["entries"]):
                for effect in effects:
                    if effect["metric"] in {"extraOutput", "dropChance", "yieldMultiplier", "eligibility"}:
                        effect["dedicatedHandler"] = "specialization-rule"
                        effect["dedicatedRuleIDs"] = sorted(dedicated)
                        effect["dedicatedMechanism"] = "conserved-family-replacement"
            if milestone["investedPoints"] == 0:
                node["learningEffects"].extend(effects)
            node["milestones"].append({"rank": milestone["investedPoints"], "perkNodeID": milestone["perkNodeID"],
                "learning": milestone["investedPoints"] == 0, "effects": effects if milestone["investedPoints"] else []})
        profile["nodes"][source_node["nodeID"]] = node
    for profession in ("Cooking", "Fishing"):
        native = next(row for row in source["professionParameters"] if row["profession"] == profession)
        expansions = {row["ExpansionID"]: row for row in native["expansionRecords"]}
        for expansion in (9, 10, 11):
            profiles[f"{profession}:{expansion}"] = {"profession": profession, "expansionID": expansion,
                "parentSkillLineID": native["parentSkillLineID"], "lineID": expansions.get(expansion, {}).get("SkillLineID"), "nodes": {}}
    for key, profile in profiles.items():
        name = profile["profession"]
        profile["professionParameters"] = globals_by_name[name]
        profile["statKeys"] = (["skill", "perception"] if name == "Fishing" else
            ["skill", "finesse", "perception", "deftness"] if name in {"Herbalism", "Mining", "Skinning"} else
            ["skill", "resourcefulness", "multicraft", "craftingSpeed"] if name == "Cooking" else
            ["skill", "resourcefulness", "multicraft", "ingenuity", "craftingSpeed"])
    document = {"schemaVersion": 1, "revision": "profession-profile-rules/1", "build": 70961, "clientVersion": "12.1.5",
        "profiles": dict(sorted(profiles.items())), "professionParameters": globals_by_name,
        "recipes": recipes, "items": items, "qualityFamilies": families, "gatheringTargets": gathering_targets, "metrics": METRICS,
        "sourceSnapshotSHA256": hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
        "specializationRulesSHA256": hashlib.sha256(SPECIALIZATION.read_bytes()).hexdigest(),
        "outputBindingsSHA256": hashlib.sha256(BINDINGS.read_bytes()).hexdigest() if BINDINGS.exists() else None,
        "modelPolicy": {"qualitativePriorConfidence": 0, "unknownExtraExpectedUnitsPrior": .05,
                        "unclassifiedExpectedUnitsPrior": .01, "unobservedSampleCountsInvented": False,
                        "ratingFallbackSlope": .1, "ratingFallbackUnit": "percentage-points-per-rating", "ratingFallbackConfidenceCap": 10,
                        "resourcefulnessSavedMidpointFraction": .3, "resourcefulnessConfidenceCap": 15,
                        "multicraftExtraMidpointFraction": 1.255, "multicraftConfidenceCap": 15,
                        "finesseConditionalExtraPrimaryUnits": 1, "finesseConfidenceCap": 5,
                        "perceptionRareDiscoveryModel": "1 + chance; not a universal primary quantity multiplier", "perceptionConfidenceCap": 5,
                        "legacyDisenchantHighestRankShare": .66, "legacyDisenchantNextRankShare": .34,
                        "legacyDisenchantBaseSkillMaximum": 140, "legacyDisenchantConfidenceCap": 0,
                        "legacyDisenchantScope": "Native scoped maximum specialization skill; preserve primary pool; transferred prior, not an empirical legacy rank curve",
                        "gatheringCanonicalPrimaryUnits": 1, "gatheringQualityDifficultyConfidenceCap": 0,
                        "gatheringQualityModel": "Evenly spaced rank fractions across the native difficulty-like parameter; exact native operation overrides",
                        "inverseAmbiguityPolicy": "Fail closed; no fabricated identifiable inverse"}}
    if QUALITY_MODELS.exists():
        quality_document = json.loads(QUALITY_MODELS.read_text(encoding="utf-8"))
        document["recipeQualityModels"] = numeric_keys(quality_document.get("recipeQualityModels", {}))
        document["recipeQualityModelsSHA256"] = hashlib.sha256(QUALITY_MODELS.read_bytes()).hexdigest()
    unresolved_groups = defaultdict(list)
    for row in unresolved_output:
        name = (row.get("outputBinding") or {}).get("name") or "Unbound identity"
        unresolved_groups[name].append(row)
    audit = {"schemaVersion": 1, "revision": document["revision"], "sourceSnapshotSHA256": document["sourceSnapshotSHA256"], "summary": {
        "profiles": len(profiles), "nodes": len(nodes), "milestones": sum(len(node["milestones"]) for node in nodes.values()),
        "entries": len(entry_audit), "recipes": len(recipes), "typedHandlers": sum(statuses.values()),
        "mechanisms": dict(sorted(statuses.items())), "unmappedSourceEffects": 0,
        "itemQualityFamilies": len(families), "itemMetadataRows": len(items), "gatheringTargets": len(gathering_targets),
        **dict(effect_summary)}, "unresolvedOutputIdentities": unresolved_output,
        "unresolvedOutputFamilies": dict(sorted(unresolved_groups.items())),
        "conditionalBuffIdentitiesWithoutNativeSpellID": conditional_unknown,
        "entries": entry_audit, "descriptionClusters": dict(sorted(clusters.items()))}
    return document, audit


def render(document):
    return "-- Generated by tools/profession_profile_rules.py; typed client effects and explicit model priors.\nreturn " + lua(document) + "\n"


def render_report(document, audit):
    summary = audit["summary"]
    lines = ["# Profession profile source and model coverage — November 19, 2026", "",
        "Generated from pinned public client tables and existing reviewed output bindings. No new in-game collection was performed.", "",
        f"The compiler maps {summary['nodes']} paths and {summary['milestones']} actual milestones ({summary['entries']} client entries) into {summary['typedHandlers']} typed handlers across 39 modern profession profiles. Cooking and Fishing have stat profiles without invented specialization trees. Legacy recipe identities and minimum Skill remain separate from modern specialization catalogs.", "",
        f"This is semantic coverage, **not complete empirical calibration**. There are {summary.get('explicitNonOutputHandlers', 0)} explicit structural, timing, convenience or progression handlers; {summary.get('zeroConfidenceModelTerms', 0)} output/profile terms use declared zero-confidence models; and {summary.get('namedUnpricedOutputHandlers', 0)} output terms retain source-backed family names with unresolved item IDs. Those named outcomes carry no invented Auction House valuation.", "",
        f"Primary Item → CraftingQuality joins establish {summary['itemQualityFamilies']} ordered families. Item IDs are never numerically sorted to infer quality. The dataset includes {summary['recipes']} native recipe identities, {summary['itemMetadataRows']} reduced item rows and {summary['gatheringTargets']} material-named native gathering targets.", "",
        "Gathering targets use an explicit canonical one-unit rank-1 minimum-profile prior at confidence zero, without a fabricated sample count. Gathering Effect302 base points are retained as a difficulty-like parameter, never interpreted as material quantity. Evenly spaced quality thresholds are declared models unless a live native operation supplies exact thresholds.", "",
        "Recipe timing comes from SpellMisc.CastingTimeIndex → SpellCastTimes.Base, converted from milliseconds to seconds. Equipment and conditional profession speed are applied afterward. Recipe stat capability models retain their evidence/confidence and defer to native operation stat eligibility.", "",
        "## Named outputs with unresolved item identity", "",
        "These are known semantic outcome families. Their proc magnitudes may also be provisional. Exact node/entry descriptions, native references, scopes and confidence remain in the machine-readable coverage JSON.", "",
        "| Source-backed family | Entries | Node names |", "| --- | ---: | --- |"]
    for name, rows in audit["unresolvedOutputFamilies"].items():
        names = ", ".join(sorted({row["nodeName"] for row in rows}))
        lines.append(f"| {name.replace('|', '/')} | {len(rows)} | {names.replace('|', '/')} |")
    condition_rows = audit["conditionalBuffIdentitiesWithoutNativeSpellID"]
    unique_conditions = {row["entryID"]: row for row in condition_rows}
    lines += ["", "## Conditional state without a native aura identity", "",
              f"{len(unique_conditions)} client entries lack a verified native aura spell ID. They retain explicit entry-specific manual state keys; the compiler does not invent spell IDs or assume these buffs are active.", "",
              "| Entry | Node | Manual state key |", "| ---: | --- | ---: |"]
    for identity, row in sorted(unique_conditions.items()):
        lines.append(f"| {identity} | {row['nodeName']} | {identity} |")
    lines += ["", "## Primary source routes", "",
        "- [Pinned Item table](https://wago.tools/db2/Item?build=12.1.5.70961): native class, inventory type, crafting quality and reagent-family identity.",
        "- [Pinned ItemSparse table](https://wago.tools/db2/ItemSparse?build=12.1.5.70961): item names, binding and vendor values.",
        "- [Pinned profession perk nodes](https://wago.tools/db2/ProfTraitPerkNode?build=12.1.5.70961): actual invested-point milestone boundaries.",
        "- [Pinned profession effects](https://wago.tools/db2/ProfessionEffect?build=12.1.5.70961): client effect amounts and types; custom enums are interpreted by their exact definition and label scope.",
        "- [Pinned spell timing](https://wago.tools/db2/SpellCastTimes?build=12.1.5.70961): static cast-time parameters.",
        "", "Source hashes and exact join IDs are retained in database/research/profession-effect-catalog-70961.json. Typed entry mappings and unresolved identity groups are in database/research/profession-profile-rule-coverage.json. Original studies and their denominators are not changed by this compiler.", ""]
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    document, audit = build(load_source())
    outputs = {OUTPUT: render(document), AUDIT: json.dumps(audit, ensure_ascii=False, indent=2) + "\n",
               REPORT: render_report(document, audit)}
    for path, text in outputs.items():
        if args.check:
            if not path.exists() or path.read_text(encoding="utf-8") != text:
                raise SystemExit(f"Stale profession profile output: {path.name}")
        else:
            path.write_text(text, encoding="utf-8", newline="\n")
    print(json.dumps(audit["summary"], sort_keys=True))


if __name__ == "__main__":
    main()
