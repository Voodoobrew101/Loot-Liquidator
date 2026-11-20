"""Inventory every bundled profession path and actual DB2 perk milestone.

Import once from existing reviewed CSV exports; subsequent coverage audits use
the checked-in reduced snapshot and require no network, game access or CSVs.
This is metadata, not an executable generic yield coefficient generator.
"""
from __future__ import annotations

import argparse
from collections import Counter, defaultdict
import csv
import hashlib
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "database/wago-professions-70783.json"
SNAPSHOT = ROOT / "database/research/profession-effect-catalog-70961.json"
COVERAGE = ROOT / "database/research/profession-effect-coverage.json"
PROFILE_AUDIT = ROOT / "database/research/profession-profile-rule-coverage.json"
RULES = ROOT / "database/research/specialization-effects.json"
BUILD = "12.1.5.70961"
TABLES = (
    "ProfTraitPathNode", "ProfTraitPerkNode", "TraitNodeGroupXTraitNode",
    "TraitNode", "TraitNodeXTraitNodeEntry", "TraitNodeEntry", "TraitDefinition",
    "ProfessionTrait", "ProfessionTraitXEffect", "ProfessionTraitXLabel",
    "ProfessionEffect", "ProfessionEffectType", "Profession", "ProfessionExpansion",
)
ROUTING_TABLES = ("SpellLabel", "SkillLineAbility", "SpellEffect", "SpellName", "CraftingData",
                  "CraftingDataItemQuality", "CraftingDataEnchantQuality", "CraftingDifficulty",
                  "CraftingDifficultyQuality", "CraftingQuality", "Item", "ItemSparse", "SpellMisc", "SpellCastTimes")
PROFESSIONS = {
    "Alchemy": 171, "Blacksmithing": 164, "Enchanting": 333,
    "Engineering": 202, "Herbalism": 182, "Inscription": 773,
    "Jewelcrafting": 755, "Leatherworking": 165, "Mining": 186,
    "Skinning": 393, "Tailoring": 197, "Cooking": 185, "Fishing": 356,
}
EFFECT_DIMENSIONS = {
    0: "skill", 1: "inspiration", 2: "resourcefulness", 3: "finesse",
    4: "deftness", 5: "perception", 6: "craftingSpeed", 7: "multicraft",
    8: "reagentSlotUnlock", 9: "inspiration", 10: "resourcefulness",
    11: "finesse", 12: "deftness", 13: "perception", 14: "craftingSpeed",
    15: "multicraft", 16: "deftness", 17: "gatherRange",
    18: "multicraftAdditionalUnits", 19: "finesseAdditionalUnits",
    20: "inspirationSkill", 21: "resourcefulnessSavedFraction",
    22: "recipeDifficulty", 23: "recipeDifficulty", 24: "skillProgression",
    25: "labelScopedTraitModifier", 26: "ingenuity", 27: "concentrationCost",
    28: "dummyTokenization", 29: "ingenuity", 30: "ingenuityRefundSize",
}
OUTPUT_DIMENSIONS = {
    "skill", "inspiration", "resourcefulness", "finesse", "perception",
    "multicraft", "reagentSlotUnlock", "multicraftAdditionalUnits",
    "finesseAdditionalUnits", "inspirationSkill", "resourcefulnessSavedFraction",
    "recipeDifficulty", "labelScopedTraitModifier", "ingenuity",
    "concentrationCost", "ingenuityRefundSize", "quality", "extraOutputs",
    "outputQuantity", "recipeUnlock",
}
NON_OUTPUT_DIMENSIONS = {"deftness", "craftingSpeed", "gatherRange", "skillProgression", "convenience"}


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def number(value):
    value = float(value)
    return int(value) if value.is_integer() else value


def import_snapshot(folder):
    tables, sources = {}, []
    for name in TABLES:
        path = folder / f"{name}-70961.csv"
        with path.open(encoding="utf-8-sig", newline="") as stream:
            tables[name] = list(csv.DictReader(stream))
        sources.append({"table": name, "build": BUILD,
                        "url": f"https://wago.tools/db2/{name}?build={BUILD}",
                        "sha256": digest(path), "rows": len(tables[name])})
    index = {name: {int(row["ID"]): row for row in rows} for name, rows in tables.items()}
    by_node, by_group, traits_by_definition, effects_by_trait, labels_by_trait = (
        defaultdict(list) for _ in range(5))
    for row in tables["TraitNodeXTraitNodeEntry"]:
        by_node[int(row["TraitNodeID"])].append(row)
    for row in tables["TraitNodeGroupXTraitNode"]:
        by_group[int(row["TraitNodeGroupID"])].append(int(row["TraitNodeID"]))
    for row in tables["ProfessionTrait"]:
        traits_by_definition[int(row["TraitDefinitionID"])].append(int(row["ID"]))
    for row in tables["ProfessionTraitXEffect"]:
        effects_by_trait[int(row["ProfessionTraitID"])].append(row)
    for row in tables["ProfessionTraitXLabel"]:
        labels_by_trait[int(row["ProfessionTraitID"])].append(int(row["LabelID"]))
    effect_types = {int(row["EnumID"]): row["Name_lang"] for row in tables["ProfessionEffectType"]}
    paths = {int(row["TraitNodeID"]): row for row in tables["ProfTraitPathNode"]}
    perks = {int(row["TraitNodeID"]): row for row in tables["ProfTraitPerkNode"]}

    def entries(node_id):
        result = []
        for link in sorted(by_node[node_id], key=lambda row: (int(row["_Index"]), int(row["ID"]))):
            entry = index["TraitNodeEntry"][int(link["TraitNodeEntryID"])]
            definition = index["TraitDefinition"][int(entry["TraitDefinitionID"])]
            trait_ids = sorted(traits_by_definition[int(definition["ID"])])
            effects, labels = [], set()
            for trait_id in trait_ids:
                labels.update(labels_by_trait[trait_id])
                for effect_link in effects_by_trait[trait_id]:
                    effect = index["ProfessionEffect"][int(effect_link["ProfessionEffectID"])]
                    enum = int(effect["ProfessionEffectTypeEnumID"])
                    effects.append({"linkID": int(effect_link["ID"]), "professionTraitID": trait_id,
                                    "effectID": int(effect["ID"]), "typeEnum": enum,
                                    "typeName": effect_types.get(enum), "amount": number(effect["Amount"]),
                                    "tokenIndex": int(effect_link["Field_10_0_0_44649_003"]),
                                    "modifiedReagentSlotID": int(effect["ModifiedCraftingReagentSlotID"])})
            effects.sort(key=lambda effect: effect["linkID"])
            description = definition["OverrideDescription_lang"]
            tokens = sorted(set(re.findall(r"\$(?:ev|en)(\d+)", description, re.I)), key=int)
            resolved = description
            for token in reversed(tokens):
                candidates = {effect["amount"] for effect in effects if effect["tokenIndex"] == int(token) - 1}
                if len(candidates) == 1:
                    resolved = re.sub(r"\$ev" + token + r"(?!\d)", str(candidates.pop()), resolved, flags=re.I)
                names = {effect["typeName"] for effect in effects if effect["tokenIndex"] == int(token) - 1}
                if len(names) == 1 and None not in names:
                    resolved = re.sub(r"\$en" + token + r"(?!\d)", names.pop(), resolved, flags=re.I)
            result.append({"entryID": int(entry["ID"]), "definitionID": int(definition["ID"]),
                           "entryType": int(entry["NodeEntryType"]), "maxRanks": int(entry["MaxRanks"]),
                           "name": definition["OverrideName_lang"], "description": description,
                           "resolvedDescription": resolved, "spellID": int(definition["SpellID"]),
                           "professionTraitIDs": trait_ids, "labelIDs": sorted(labels), "effects": effects,
                           "unresolvedTokens": sorted(set(re.findall(r"\$[A-Za-z][A-Za-z0-9_]*", resolved)))})
        return result

    catalog = read_json(CATALOG)
    nodes, issues = [], []
    for key, tree in sorted(catalog["catalogs"].items()):
        profession, expansion = key.split(":")
        for source in sorted(tree["nodes"], key=lambda node: node["id"]):
            node_id = source["id"]
            path = paths.get(node_id)
            record = {"catalogKey": key, "profession": profession, "expansionID": int(expansion),
                      "lineID": tree["lineID"], "nodeID": node_id, "name": source["name"],
                      "maxInvestedRank": source["maxRank"], "treeID": source["treeID"],
                      "parentID": source.get("parentID"), "baseEntries": entries(node_id), "milestones": []}
            if path:
                record["pathRecordID"] = int(path["ID"])
                group_ids = sorted({int(path["LeftTraitNodeGroupID"]), int(path["RightTraitNodeGroupID"])})
                record["perkGroupIDs"] = group_ids
                perk_ids = sorted({member for group in group_ids for member in by_group[group] if member in perks})
                for perk_id in perk_ids:
                    perk = perks[perk_id]
                    record["milestones"].append({"perkNodeID": perk_id, "perkRecordID": int(perk["ID"]),
                        "investedPoints": int(perk["RequiredPointsInThisNode"]), "flags": int(perk["Flags"]),
                        "entries": entries(perk_id)})
                record["milestones"].sort(key=lambda milestone: (milestone["investedPoints"], milestone["perkNodeID"]))
            else:
                issues.append({"nodeID": node_id, "issue": "NO_CURRENT_PROF_TRAIT_PATH_ROW"})
            if not record["baseEntries"] or not record["milestones"]:
                issues.append({"nodeID": node_id, "issue": "MISSING_BASE_ENTRIES_OR_MILESTONES"})
            nodes.append(record)
    profession_rows = {int(row["SkillLineID"]): row for row in tables["Profession"]}
    professions = []
    for name, skill_line in PROFESSIONS.items():
        row = profession_rows[skill_line]
        professions.append({"profession": name, "parentSkillLineID": skill_line,
                            "professionRecord": {key: number(value) for key, value in row.items()},
                            "expansionRecords": [{key: number(value) for key, value in expansion.items()}
                                for expansion in tables["ProfessionExpansion"] if expansion["ProfessionID"] == row["ID"]]})
    routing = import_recipe_routing(folder, nodes, professions, sources)
    unit_examples = defaultdict(list)
    for node in nodes:
        for entry in [*node["baseEntries"], *[entry for milestone in node["milestones"] for entry in milestone["entries"]]]:
            for effect in entry["effects"]:
                examples = unit_examples[effect["typeEnum"]]
                if len(examples) < 3:
                    examples.append({"nodeID": node["nodeID"], "entryID": entry["entryID"],
                        "profession": node["profession"], "description": entry["resolvedDescription"],
                        "amount": effect["amount"], "labelIDs": entry["labelIDs"]})
    return {"schemaVersion": 1, "build": BUILD, "catalogBuild": catalog["build"],
            "catalogSHA256": digest(CATALOG), "sourcePolicy": "Existing published client tables only; no game operations",
            "scope": "Every node in the bundled 33 modern profession-era catalogs; absent catalogs remain explicit gaps",
            "sources": sources, "professionParameters": professions, "recipeRouting": routing,
            "effectUnits": {
                "ratingEnums": [1, 2, 3, 4, 5, 6, 7, 26],
                "percentageEnums": [9, 10, 11, 12, 13, 14, 15, 16, 18, 19, 20, 21, 27, 29, 30],
                "skillEnums": [0],
                "unitsEvidence": "Enum pairs are retained with their raw/resolved descriptions; flat-stat and percent-text examples establish distinct units. Percentage stacking/recipe response still needs the corresponding typed model.",
                "examplesByEnum": {str(enum): examples for enum, examples in sorted(unit_examples.items())},
                "interpretationCaveat": "The flat/percentage lists classify client effect units; they do not supply a universal rating conversion, proc-stack distribution or percent-stacking law. Token-only and label-scoped effects need exact semantic review.",
                "enum25Warning": "Label-scoped trait modifier, not universally Skill: it also encodes Alchemy extra-transmutagen procs. Interpret the exact definition, labels and spell semantics.",
                "enum28Warning": "Dummy tokenization values are text parameters, not executable multipliers."},
            "nodes": nodes, "importIssues": issues}


def import_recipe_routing(folder, nodes, professions, sources):
    """Retain native label routing and parent-profession recipes, not eligibility guesses."""
    def rows(name):
        path = folder / f"{name}-70961.csv"
        sources.append({"table": name, "build": BUILD,
                        "url": f"https://wago.tools/db2/{name}?build={BUILD}", "sha256": digest(path)})
        with path.open(encoding="utf-8-sig", newline="") as stream:
            yield from csv.DictReader(stream)

    all_entries = [entry for node in nodes for entry in [*node["baseEntries"],
                   *[entry for milestone in node["milestones"] for entry in milestone["entries"]]]]
    native_labels = {label for entry in all_entries for label in entry["labelIDs"]}
    label_spells = {label: set() for label in native_labels}
    spell_labels = defaultdict(set)
    for row in rows("SpellLabel"):
        label, spell = int(row["LabelID"]), int(row["SpellID"])
        spell_labels[spell].add(label)
        if label in label_spells:
            label_spells[label].add(spell)
    parent_names = {record["parentSkillLineID"]: record["profession"] for record in professions}
    modern_lines = {int(expansion["SkillLineID"]): (record["profession"], int(expansion["ExpansionID"]))
                    for record in professions for expansion in record["expansionRecords"]}
    recipes = []
    for row in rows("SkillLineAbility"):
        parent, child = int(row["SkillLine"]), int(row["SkillupSkillLineID"])
        if parent not in parent_names and child not in modern_lines:
            continue
        recipes.append({"recordID": int(row["ID"]), "spellID": int(row["Spell"]),
                        "profession": parent_names.get(parent) or modern_lines[child][0],
                        "parentSkillLineID": parent, "skillupSkillLineID": child,
                        "expansionID": modern_lines.get(child, (None, None))[1],
                        "minimumSkill": int(row["MinSkillLineRank"]), "acquireMethod": int(row["AcquireMethod"]),
                        "abilityVerb": row["AbilityVerb_lang"],
                        "tradeSkillCategoryID": int(row["TradeSkillCategoryID"]),
                        "labels": sorted(spell_labels[int(row["Spell"])])})
    recipes.sort(key=lambda recipe: (recipe["profession"], recipe["spellID"], recipe["recordID"]))
    wanted = {recipe["spellID"] for recipe in recipes} | {entry["spellID"] for entry in all_entries if entry["spellID"]}
    wanted.update(spell for spells in label_spells.values() for spell in spells)
    wanted.update(int(spell) for entry in all_entries for spell in re.findall(r"\$@spell(?:name|desc)(\d+)", entry["description"], re.I))
    spells = {spell: {"spellID": spell, "labels": sorted(spell_labels[spell]), "effects": []} for spell in wanted}
    for row in rows("SpellName"):
        spell = int(row["ID"])
        if spell in spells:
            spells[spell]["name"] = row["Name_lang"]
    cast_times = {int(row["ID"]): row for row in rows("SpellCastTimes")}
    spell_cast_rows = defaultdict(list)
    for row in rows("SpellMisc"):
        spell = int(row["SpellID"])
        if spell in spells and int(row["DifficultyID"]) == 0:
            spell_cast_rows[spell].append(row)
    for spell, candidates in spell_cast_rows.items():
        indices = {int(row["CastingTimeIndex"]) for row in candidates}
        if len(indices) == 1 and next(iter(indices)) in cast_times:
            index_id = next(iter(indices))
            timing = cast_times[index_id]
            spells[spell]["baseDuration"] = number(timing["Base"]) / 1000
            spells[spell]["castTimeSource"] = {"spellMiscID": int(candidates[0]["ID"]), "spellCastTimesID": index_id,
                "baseMilliseconds": number(timing["Base"]), "minimumMilliseconds": number(timing["Minimum"])}
    effect_fields = ("ID", "SpellID", "DifficultyID", "EffectIndex", "Effect", "EffectAura", "EffectItemType",
                     "EffectBasePointsF", "EffectMiscValue_0", "EffectMiscValue_1", "EffectTriggerSpell")
    crafting = {int(row["ID"]): {key: number(value) for key, value in row.items()} for row in rows("CraftingData")}
    referenced_crafting = set()
    for row in rows("SpellEffect"):
        spell = int(row["SpellID"])
        if spell not in spells:
            continue
        effect = {key: number(row[key]) for key in effect_fields}
        # These two recipe-effect layouts are directly identified in the client
        # tables. Numeric collisions in other effect types are not pointers.
        pointer = int(row["EffectMiscValue_0"]) if int(row["Effect"]) == 288 else (
            int(row["EffectMiscValue_1"]) if int(row["Effect"]) == 296 else None)
        if pointer in crafting:
            effect["craftingDataID"] = pointer
            referenced_crafting.add(pointer)
        spells[spell]["effects"].append(effect)
    qualities = {int(row["ID"]): {key: number(value) for key, value in row.items()} for row in rows("CraftingQuality")}
    difficulty = {int(row["ID"]): {key: number(value) for key, value in row.items()} for row in rows("CraftingDifficulty")}
    difficulty_quality = defaultdict(list)
    for row in rows("CraftingDifficultyQuality"):
        difficulty_quality[int(row["CraftingDifficultyID"])].append({key: number(value) for key, value in row.items()})
    item_quality, enchant_quality = defaultdict(list), defaultdict(list)
    for name, destination in (("CraftingDataItemQuality", item_quality), ("CraftingDataEnchantQuality", enchant_quality)):
        for row in rows(name):
            if int(row["CraftingDataID"]) in referenced_crafting:
                destination[int(row["CraftingDataID"])].append({key: number(value) for key, value in row.items()})
    crafting_rows = []
    for identity in sorted(referenced_crafting):
        row = dict(crafting[identity])
        row["itemQualityRows"] = item_quality[identity]
        row["enchantQualityRows"] = enchant_quality[identity]
        row["difficultyRow"] = difficulty.get(row["CraftingDifficultyID"])
        row["difficultyQualityRows"] = sorted(difficulty_quality[row["CraftingDifficultyID"]], key=lambda item: item["_Order"])
        crafting_rows.append(row)
    referenced_items = {int(effect["EffectItemType"]) for spell in spells.values() for effect in spell["effects"] if effect["EffectItemType"]}
    referenced_items.update(row["CraftedItemID"] for row in crafting_rows if row["CraftedItemID"])
    referenced_items.update(item["ItemID"] for row in crafting_rows for item in row["itemQualityRows"] + row["enchantQualityRows"] if item["ItemID"])
    items, item_universe = {}, []
    for row in rows("Item"):
        identity = int(row["ID"])
        item_universe.append(identity)
        if int(row["CraftingQualityID"]) or int(row["ClassID"]) in (0, 3, 7) or identity in referenced_items:
            quality_id = int(row["CraftingQualityID"])
            items[identity] = {"classID": int(row["ClassID"]), "subclassID": int(row["SubclassID"]),
                "inventoryType": int(row["InventoryType"]), "craftingQualityID": quality_id,
                "qualityRank": qualities.get(quality_id, {}).get("QualityTier"),
                "modifiedCraftingReagentItemID": int(row["ModifiedCraftingReagentItemID"])}
    for row in rows("ItemSparse"):
        identity = int(row["ID"])
        if identity in items:
            items[identity].update({"name": row["Display_lang"], "bonding": int(row["Bonding"]),
                "bindType": int(row["Bonding"]), "vendorPrice": int(row["SellPrice"]),
                "stackable": int(row["Stackable"]), "expansionID": int(row["ExpansionID"])})
    grouped = defaultdict(list)
    for identity, item in items.items():
        if item["qualityRank"] and item["modifiedCraftingReagentItemID"]:
            grouped[item["modifiedCraftingReagentItemID"]].append((item["qualityRank"], identity))
    families, ambiguous_groups = {}, []
    for group, members in sorted(grouped.items()):
        ranked = sorted(members)
        if len(ranked) >= 2 and [rank for rank, _ in ranked] == list(range(1, len(ranked) + 1)):
            families[group] = {"rankItemIDs": [identity for _, identity in ranked],
                "source": "Item.ModifiedCraftingReagentItemID + Item.CraftingQualityID -> CraftingQuality.QualityTier",
                "qualityOrderVerified": True}
            for _, identity in ranked:
                items[identity]["qualityFamilyID"] = group
        elif len(ranked) >= 2:
            ambiguous_groups.append(group)
    return {"semantics": "Native label membership is a scope candidate, not proof that every stat applies. Unlabeled generic Disenchant needs the separate item-rarity context route. SkillLineAbility proves database identity, not that a character learned the recipe.",
            "labelSpellIDs": {str(label): sorted(spell_ids) for label, spell_ids in sorted(label_spells.items())},
            "recipes": recipes, "spells": [spells[spell] for spell in sorted(spells)],
            "craftingData": crafting_rows, "craftingQualities": [qualities[key] for key in sorted(qualities)],
            "items": {str(identity): item for identity, item in sorted(items.items())},
            "itemIDUniverse": sorted(item_universe),
            "qualityFamilies": {str(identity): family for identity, family in families.items()},
            "ambiguousQualityReagentGroups": ambiguous_groups,
            "legacySkillupLinesWithoutExpansionMapping": sorted({recipe["skillupSkillLineID"] for recipe in recipes
                if recipe["expansionID"] is None and recipe["skillupSkillLineID"]}),
            "directItemOutputCaveat": "EffectItemType in salvage spells can be an internal proxy; do not mistake it for an observed material output."}


def dimensions(entry):
    result = {EFFECT_DIMENSIONS.get(effect["typeEnum"], "unknownEffectType") for effect in entry["effects"]}
    text = entry["resolvedDescription"].lower()
    for key, pattern in {
        "skill": r"\bskill\b", "quality": r"\bquality\b|\bconcentration\b",
        "resourcefulness": r"\bresourcefulness\b", "multicraft": r"\bmulticraft\b",
        "finesse": r"\bfinesse\b", "perception": r"\bperception\b",
        "deftness": r"\bdeftness\b", "craftingSpeed": r"crafting speed|craft .*faster",
        "ingenuity": r"\bingenuity\b", "skillProgression": r"skill[- ]?ups?|skill gains?",
        "recipeUnlock": r"learn (?:how )?to (?:craft|create)|learn .*recipe|unlock .*recipe|ability to craft",
        "extraOutputs": r"extract|additional (?:materials?|reagents?|gems?|herbs?|ore|fish|items?)|rare (?:materials?|reagents?|gems?)",
        "outputQuantity": r"more (?:materials?|reagents?|gems?|herbs?|ore|fish)|amount of .*receive|increased? (?:yield|output)",
        "convenience": r"mounted|dismount|movement speed|gather.*combat|damage (?:taken|dealt)",
    }.items():
        if re.search(pattern, text):
            result.add(key)
    # Pure Skill-up prose affects progression rather than current output Skill.
    if "skillProgression" in result and not entry["effects"] and not re.search(r"\+\d+ skill|\badditional skill\b", text):
        result.discard("skill")
    return sorted(result)


def build_coverage(snapshot, rules_document):
    rules = rules_document.get("rules", [])
    models = rules_document.get("modeledDisenchantRules", [])
    described = rules_document.get("describedEffects", [])
    nodes, status_counts, milestone_count, entry_count = [], Counter(), 0, 0
    typed_audit = read_json(PROFILE_AUDIT) if PROFILE_AUDIT.exists() else {}
    typed_current = typed_audit.get("sourceSnapshotSHA256") == digest(SNAPSHOT)
    typed_entries = {row["entryID"]: row for row in typed_audit.get("entries", [])} if typed_current else {}

    def entry_coverage(entry, matching_rules, point=None):
        nonlocal entry_count
        entry_count += 1
        dims = dimensions(entry)
        mapped = []
        for rule in matching_rules:
            kind = rule.get("kind")
            if point is None and entry["entryType"] == 7 and kind in ("skill-per-point", "replace-family"):
                mapped.append(rule["ruleID"])
            elif point is not None and kind == "skill-per-point":
                if point == 0 and rule.get("learningSkill") is not None or any(
                        milestone["rank"] == point for milestone in rule.get("skillMilestones", [])):
                    mapped.append(rule["ruleID"])
        structural = entry["entryType"] == 9 and not entry["description"] and not entry["effects"] and not entry["spellID"]
        if structural:
            status, reason = "STRUCTURAL_LEARNING_ENTRY", "Learning rank; numerical bonuses are inventoried at the separate zero-point perk"
        elif not dims or "unknownEffectType" in dims or "dummyTokenization" in dims or "labelScopedTraitModifier" in dims and len(dims) == 1:
            status, reason = "REQUIRES_SEMANTIC_REVIEW", "Client row exists; effect semantics or scope are not fully identified"
        elif not set(dims) & OUTPUT_DIMENSIONS and set(dims) <= NON_OUTPUT_DIMENSIONS:
            status, reason = "NON_OUTPUT_EFFECT_INVENTORIED", "Changes time, range, convenience or progression rather than material units per operation"
        elif mapped:
            status, reason = "HAS_NUMERIC_RULE_REQUIRES_SCOPE_REVIEW", "Existing rule covers at least one term; extra effects and recipe applicability must be checked separately"
        else:
            status, reason = "REQUIRES_OUTPUT_MODEL", "Output, quality, input savings, concentration or recipe availability needs an explicit model mapping"
        original_status = status
        typed = typed_entries.get(entry["entryID"])
        if typed:
            status = "TYPED_MECHANISM_MAPPED"
            reason = "Compiled typed handler with explicit confidence; this establishes semantic coverage, not empirical calibration or complete output item identity"
        status_counts[status] += 1
        return {"entryID": entry["entryID"], "definitionID": entry["definitionID"], "dimensions": dims,
                "status": status, "reason": reason, "existingRuleIDs": sorted(mapped),
                "previousNumericRuleCoverage": original_status,
                "typedHandlerCount": typed.get("handlerCount", 0) if typed else 0,
                "directEffectCount": len(entry["effects"]), "unresolvedTokenCount": len(entry["unresolvedTokens"])}

    for source in snapshot["nodes"]:
        matching = [rule for rule in rules if rule.get("profession") == source["profession"]
                    and rule.get("expansionID") == source["expansionID"] and rule.get("nodeID") == source["nodeID"]]
        modeled = [model["ruleID"] for model in models if model.get("expansionID") == source["expansionID"]
                   and source["nodeID"] in (model.get("rootNodeID"), model.get("childNodeID"))]
        record = {key: source[key] for key in ("catalogKey", "profession", "expansionID", "nodeID", "name", "maxInvestedRank")}
        record["existingRuleIDs"] = sorted(rule["ruleID"] for rule in matching)
        record["modeledBaselineRuleIDs"] = sorted(modeled)
        record["describedEffectIDs"] = sorted(effect["effectID"] for effect in described if effect.get("nodeID") == source["nodeID"])
        record["baseEntries"] = [entry_coverage(entry, matching) for entry in source["baseEntries"]]
        record["milestones"] = []
        for milestone in source["milestones"]:
            milestone_count += 1
            record["milestones"].append({"perkNodeID": milestone["perkNodeID"], "investedPoints": milestone["investedPoints"],
                "entries": [entry_coverage(entry, matching, milestone["investedPoints"]) for entry in milestone["entries"]]})
        nodes.append(record)
    catalog_keys = {node["catalogKey"] for node in nodes}
    cells = []
    for profession in PROFESSIONS:
        for expansion in range(12):
            key = f"{profession}:{expansion}"
            present = key in catalog_keys
            status = "CATALOG_INVENTORIED" if present else "NO_BUNDLED_MODERN_TREE" if expansion >= 9 else "LEGACY_MECHANICS_NOT_CATALOGED"
            cells.append({"profession": profession, "expansionID": expansion, "status": status,
                          "requiredWork": [] if present else ["Inventory recipe Skill, eligible stats, historical specialization unlocks and output-affecting spells; no absence-as-zero inference"]})
    parameters = {record["profession"]: record for record in snapshot["professionParameters"]}
    stat_plan = []
    for profession in PROFESSIONS:
        gathering = profession in {"Herbalism", "Mining", "Skinning", "Fishing"}
        stats = ["skill", "perception", "finesse", "deftness"] if gathering else ["skill", "resourcefulness", "multicraft", "ingenuity", "concentration", "craftingSpeed"]
        for stat in stats:
            row = parameters[profession]["professionRecord"]
            bounds = [row["ResourcefulEffectLow"], row["ResourcefulEffectHigh"]] if stat == "resourcefulness" else (
                [row["MinCraftExtraQtyPct"], row["MaxCraftExtraQtyPct"]] if stat == "multicraft" else None)
            stat_plan.append({"profession": profession, "stat": stat,
                "status": "RECIPE_ELIGIBILITY_AND_RESPONSE_MODEL_REQUIRED", "publishedParameterRange": bounds,
                "rangeSemantics": "Client parameter bounds, not measured mean or proof that every recipe supports the stat" if bounds else None,
                "plannedModel": "Separate input cost, output quantity, quality, concentration refunds and time dimensions; use declared confidence for estimated terms"})
    return {"schemaVersion": 1, "build": snapshot["build"], "catalogBuild": snapshot["catalogBuild"],
            "sourceSnapshot": SNAPSHOT.relative_to(ROOT).as_posix(),
            "sourceSnapshotSHA256": digest(SNAPSHOT) if SNAPSHOT.exists() else None,
            "ruleRevision": rules_document.get("revision"),
            "policy": {"purpose": "Exhaustive coverage plan; pending rows are explicit work rather than silently unsupported controls",
                       "estimatesAuthorized": True, "newGameCollectionAuthorized": False,
                       "runtimeDescriptionParsing": False, "confidenceIsUncertaintyIndicator": True,
                       "noInventedObservedCounts": True, "clientCoefficientsDoNotProveRecipeEligibility": True},
            "summary": {"professions": len(PROFESSIONS), "professionEraCells": len(cells),
                        "catalogsInventoried": len(catalog_keys), "catalogNodes": len(nodes),
                        "actualMilestones": milestone_count, "actualEntries": entry_count,
                        "entryCoverageStatuses": dict(sorted(status_counts.items())),
                        "currentNumericNodeRules": len(rules), "currentModeledBaselineRules": len(models),
                        "typedProfileClassificationCurrent": typed_current,
                        "typedProfileClassification": typed_audit.get("summary") if typed_current else None,
                        "sourceImportIssues": len(snapshot["importIssues"])},
            "professionEraCoverage": cells, "statCoveragePlan": stat_plan, "nodes": nodes,
            "openWork": ["Calibrate declared low/zero-confidence quantity, proc and gathering priors using existing published evidence",
                         "Resolve named unpriced output families to primary item IDs; semantic coverage is not complete identity coverage",
                         "Validate recipe-specific stat eligibility and conditional-state assumptions without inventing sample sizes",
                         "Preserve per-recipe stat eligibility, quality ranks, extra-output identities and input refunds separately",
                         "Review all archived studies before automatic build-time evidence inclusion; preserve original cohorts and denominators"]}


def serialized(value):
    return json.dumps(value, ensure_ascii=False, indent=2) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--csv-dir", type=Path, help="Import existing build70961 source exports into the reduced snapshot")
    parser.add_argument("--check", action="store_true", help="Verify deterministic metadata without writing")
    args = parser.parse_args()
    if args.csv_dir:
        source = import_snapshot(args.csv_dir)
        if args.check:
            if not SNAPSHOT.exists() or SNAPSHOT.read_text(encoding="utf-8") != serialized(source):
                raise SystemExit("Profession source snapshot is stale")
        else:
            SNAPSHOT.write_text(serialized(source), encoding="utf-8", newline="\n")
    source = read_json(SNAPSHOT)
    if source["catalogSHA256"] != digest(CATALOG):
        raise SystemExit("Profession catalog changed; reimport the source inventory")
    coverage = build_coverage(source, read_json(RULES))
    rendered = serialized(coverage)
    if args.check:
        if not COVERAGE.exists() or COVERAGE.read_text(encoding="utf-8") != rendered:
            raise SystemExit("Profession effect coverage plan is stale")
    else:
        COVERAGE.write_text(rendered, encoding="utf-8", newline="\n")
    print(json.dumps(coverage["summary"], sort_keys=True))


if __name__ == "__main__":
    main()
