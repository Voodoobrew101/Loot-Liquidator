"""Review world-target studies in their own namespace and compile source views.

NPC, GameObject and fishing target IDs are never processing input item IDs. Only
explicit output item identities are checked against the pinned native Item table.
Reported source means/counts remain source-profile observations; the shared Lua
inverse/forward model normalizes them when a target is previewed.
"""
from __future__ import annotations

import argparse
from collections import Counter, defaultdict
import hashlib
import json
import math
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "database/gathering-study-baselines.lua"
REVIEW = ROOT / "database/research/gathering-study-review.json"
NATIVE = ROOT / "database/research/profession-effect-catalog-70961.json"
DEFAULT_ROOTS = (ROOT / "database/research/v3-snapshot/research/v3/evidence",
                 ROOT / "research/v3/evidence", ROOT / "research/evidence",
                 ROOT / "research/gathering-studies")
GATHER_METHODS = {"gather", "gathering", "harvest", "herb", "herbalism", "herbgathering",
                  "mine", "mining", "skin", "skinning", "fish", "fishing", "fishingpool", "fishingzone"}
WORLD_METHODS = GATHER_METHODS | {"loot", "mobloot", "kill", "killloot", "nodeloot", "worldloot"}
PROFESSIONS = {"Herbalism", "Mining", "Skinning", "Fishing", "Tailoring", "Enchanting"}
TARGET_KINDS = {"gameobject", "creature", "fishing-pool", "fishing-zone"}
ERA_NAMES = {"classic": 0, "the burning crusade": 1, "wrath of the lich king": 2, "cataclysm": 3,
             "mists of pandaria": 4, "warlords of draenor": 5, "legion": 6,
             "battle for azeroth": 7, "shadowlands": 8, "dragonflight": 9, "the war within": 10, "midnight": 11}


def canonical(value):
    return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":"), allow_nan=False)


def positive_id(value):
    return type(value) is int and 0 < value <= 2**53 - 1


def finite(value):
    return type(value) in (int, float) and math.isfinite(value) and value >= 0


def method_of(row):
    value = row.get("method") or row.get("processingMethod") or row.get("action")
    return re.sub(r"[^a-z]", "", value.lower()) if isinstance(value, str) else ""


def is_world_row(row):
    return method_of(row) in WORLD_METHODS or isinstance(row.get("nativeTarget"), dict)


def normalize_target(row):
    target = row.get("nativeTarget")
    if not isinstance(target, dict):
        target = None
        for field, kind in (("gameObjectID", "gameobject"), ("gameobjectID", "gameobject"), ("creatureID", "creature"),
                            ("fishingPoolID", "fishing-pool")):
            if field in row:
                target = {"kind": kind, "id": row[field]}
                break
        if target is None:
            return None, "Missing explicit native world target; inputItemID is not a native-target substitute"
    kind = str(target.get("kind", "")).lower().replace("_", "-")
    kind = {"npc": "creature", "game-object": "gameobject", "fishingpool": "fishing-pool",
            "fishingzone": "fishing-zone"}.get(kind, kind)
    identity = target.get("id")
    if kind not in TARGET_KINDS or not positive_id(identity):
        return None, "Native target needs a typed namespace and positive exact integer ID"
    normalized = {"kind": kind, "id": identity}
    zone = target.get("zoneID", row.get("zoneID"))
    if zone is not None:
        if not positive_id(zone):
            return None, "Native target zoneID is invalid"
        normalized["zoneID"] = zone
    return normalized, None


def source_counts(row, output):
    counts = [value for owner in (output, row) for name in ("completedOperations", "completedCasts", "casts", "gathers")
              if (value := owner.get(name)) is not None]
    if counts and (not all(positive_id(value) for value in counts) or len(set(counts)) != 1):
        return None, "Reported completed-operation counts are invalid or contradictory"
    if output.get("castsVerified", row.get("castsVerified")) is False:
        return None, "Reported casts are explicitly unverified, not an actual operation denominator"
    basis = str(output.get("denominatorBasis", row.get("denominatorBasis",
        row.get("castCountBasis", row.get("countBasis", ""))))).lower()
    if any(word in basis for word in ("nominal", "input item", "successful only", "hits only", "estimated casts")):
        return None, "Nominal inputs or positive-hit counts are not completed-operation denominators"
    return counts[0] if counts else None, None


def expected_units(row, output):
    count, reason = source_counts(row, output)
    if reason:
        return None, None, reason, None
    total = output.get("totalQuantity")
    if total is not None:
        if not finite(total) or count is None:
            return None, count, "Output totals require a valid reported completed-operation denominator", None
        return total / count, count, None, "reported-total/completed-operations"
    mean = output.get("expectedQuantity", output.get("unconditionalMean"))
    if isinstance(mean, dict):
        if mean.get("status") in ("unknown", "contradictory"):
            return None, count, "Expected quantity field is unknown or contradictory", None
        mean = mean.get("value")
    basis = "reported-unconditional-mean"
    if mean is None and output.get("averageShown") is not None:
        per = str(output.get("averagePer", row.get("averagePer", ""))).lower()
        if per not in {"operation", "cast", "gather", "harvest", "per operation", "completed operation", "fishing cast"}:
            return None, count, "Reported average has no unconditional per-operation basis", None
        mean = output["averageShown"]
        basis = "reported-average-per-operation"
    if not finite(mean):
        return None, count, "No unconditional output mean; occurrence percentages and stack ranges remain separate", None
    return mean, count, None, basis


def compile_rows(rows, known_item_ids, native_recipes=None, native_targets=None):
    native_recipes = native_recipes or {}
    native_targets = native_targets or {}
    review, groups, seen = [], {}, set()
    counts = Counter(reviewedRows=len(rows))
    replaced = {row.get("replaces") for row in rows if isinstance(row, dict) and isinstance(row.get("replaces"), str)}
    for row in rows:
        if not isinstance(row, dict) or not is_world_row(row):
            counts["nonWorldRows"] += 1
            continue
        counts["worldRows"] += 1
        record_id = row.get("id") or row.get("recordID")
        entry = {"recordID": record_id, "locator": row.get("_locator"), "method": row.get("method")}
        reasons = []
        if method_of(row) not in WORLD_METHODS:
            reasons.append("Native world target has no explicit compatible gathering/loot method")
        if record_id in replaced:
            reasons.append("Superseded by an explicit replacement row")
        if row.get("type") in {"rateChange", "mechanic", "restriction", "note", "reference"}:
            entry.update(disposition="PRESERVED_WORLD_METADATA", reasons=["World mechanic/reference metadata is not additional observed operations"])
            review.append(entry);counts[entry["disposition"]] += 1
            continue
        target, reason = normalize_target(row)
        if reason:
            reasons.append(reason)
        recipe_id = row.get("recipeID", row.get("spellID"))
        if recipe_id is not None and not positive_id(recipe_id):
            reasons.append("recipeID/spellID is not an exact native identity")
        native = native_recipes.get(recipe_id, {})
        profession = row.get("profession") or native.get("profession")
        if not profession:
            profession = {"mine": "Mining", "mining": "Mining", "skin": "Skinning", "skinning": "Skinning",
                          "fish": "Fishing", "fishing": "Fishing", "herb": "Herbalism", "herbalism": "Herbalism"}.get(method_of(row))
        expansion = row.get("expansionID", row.get("expansion"))
        if isinstance(expansion, str):
            expansion = ERA_NAMES.get(expansion.lower())
        if expansion is None:
            expansion = native.get("expansionID")
        if profession not in PROFESSIONS or type(expansion) is not int or not 0 <= expansion <= 11:
            reasons.append("World study needs an explicit or native-recipe-resolved profession and expansion")
        if native and (native.get("profession") != profession or native.get("expansionID") not in (None, expansion)):
            reasons.append("Native recipe profession/era conflicts with reported context")
        source = row.get("source") if isinstance(row.get("source"), dict) else {}
        original = row.get("originalSource")
        source_url = (original.get("url") if isinstance(original, dict) else original) or source.get("url")
        source_url = source_url or ("archived-record:" + str(record_id) if record_id else row.get("_locator"))
        if not source_url:
            reasons.append("Missing original source or archived row provenance")
        mode = str(row.get("gameMode", row.get("sourceGameMode", ""))).lower()
        if any(word in mode for word in ("ptr", "classic", "beta")) or any(word in str(source_url).lower() for word in ("/ptr/", "/classic/")):
            reasons.append("Non-Retail/PTR/Beta world data is preserved separately from the current Retail registry")
        profile = row.get("sourceProfile", row.get("baselineProfile"))
        assumed_profile = not isinstance(profile, dict)
        if isinstance(profile, dict):
            assumed_profile = not (any(finite(profile.get(field)) for field in ("skill", "effectiveSkill", "preSpecializationSkill"))
                and (isinstance(profile.get("stats"), dict) or isinstance(profile.get("operationStats"), list))
                and (isinstance(profile.get("specializationPoints"), dict) or profile.get("specialization") == "none"))
        profile = profile if isinstance(profile, dict) else {"skill": 0, "preSpecializationSkill": 0,
                                                           "specializationPoints": {}, "stats": {}}
        try:
            profile_key = canonical(profile)
        except (ValueError, TypeError):
            reasons.append("Invalid numeric source profile")
            profile_key = "invalid"
        outputs = row.get("outputs")
        if not isinstance(outputs, list):
            outputs = [row]
        materials = []
        for output in outputs:
            if not isinstance(output, dict):
                reasons.append("Output row is not an object");continue
            identity = output.get("outputItemID", output.get("itemID", output.get("id") if output is not row else None))
            if not positive_id(identity) or identity not in known_item_ids:
                reasons.append("Output item ID is not verified in the pinned native Item namespace");continue
            mean, operations, error, basis = expected_units(row, output)
            if error:
                reasons.append(error);continue
            confidence = output.get("confidence0to100", row.get("confidence0to100"))
            if not finite(confidence) or confidence > 100:
                confidence = 50 if operations is not None else 25
            if assumed_profile:
                confidence = min(confidence, 0)
            materials.append({"id": identity, "expectedQuantity": mean, "confidence": confidence,
                              "reportedCompletedOperations": operations, "quantityBasis": basis})
        if reasons or not materials:
            entry.update(disposition="HELD_WORLD_STUDY", reasons=sorted(set(reasons or ["No usable material mean"])))
            review.append(entry);counts[entry["disposition"]] += 1
            continue
        cohort = row.get("cohortKey") or row.get("studyKey") or record_id or row.get("_rowSHA256")
        cohort_identity = [source_url, source.get("author"), cohort, target, profession, expansion,
                           recipe_id, profile_key, row.get("patchBuild", row.get("patch"))]
        key = canonical(cohort_identity)
        signature = canonical([key, materials])
        if signature in seen:
            entry.update(disposition="MERGED_ORIGINAL_COHORT_COPY", reasons=["Same original cohort, context and material vector; no additional operations counted"])
            review.append(entry);counts[entry["disposition"]] += 1
            continue
        seen.add(signature)
        group = groups.setdefault(key, {"nativeTarget": target, "profession": profession, "expansionID": expansion,
            "recipeID": recipe_id, "sourceProfile": profile, "sourceProfileAssumed": assumed_profile,
            "sourceURL": source_url, "cohortKey": cohort, "materials": {}, "conflicts": set(), "records": [],
            "label": row.get("label") or row.get("nativeTarget", {}).get("name") or row.get("targetName") or row.get("inputName"),
            "labels": row.get("labels") or native.get("labels", []),
            "sourceMethod": row.get("method"), "method": "Gather" if method_of(row) in GATHER_METHODS else "Loot", "reviewEntries": []})
        group["records"].append({"recordID": record_id, "locator": row.get("_locator"),
                                 "rawSHA256": row.get("_rowSHA256"), "sourceURL": source_url})
        for material in materials:
            previous = group["materials"].get(material["id"])
            if previous and (previous["expectedQuantity"] != material["expectedQuantity"]
                             or previous["reportedCompletedOperations"] != material["reportedCompletedOperations"]):
                group["conflicts"].add(material["id"])
            else:
                group["materials"][material["id"]] = material
        entry["outputItemIDs"] = [material["id"] for material in materials]
        group["reviewEntries"].append(entry)
        entry.update(disposition="ADMITTED_WORLD_SOURCE_VIEW", reasons=["Explicit native target and unconditional source-profile material means"])
        review.append(entry);counts[entry["disposition"]] += 1
    targets = {}
    for key, group in sorted(groups.items()):
        materials = [material for identity, material in sorted(group["materials"].items()) if identity not in group["conflicts"]]
        if group["conflicts"]:
            for entry in group["reviewEntries"]:
                if set(entry["outputItemIDs"]) & group["conflicts"]:
                    accepted = set(entry["outputItemIDs"]) - group["conflicts"]
                    entry["disposition"] = "PARTIALLY_ADMITTED_WORLD_SOURCE_VIEW" if accepted else "HELD_CONFLICTING_COHORT_OUTPUT"
                    entry["reasons"] = ["Same original cohort reports incompatible means/counts for one material; no averaging or denominator addition"]
        if not materials:
            continue
        native = native_targets.get(group["recipeID"], {})
        world = group["nativeTarget"]
        native_id = world["kind"] + ":" + str(world["id"]) + (":zone:" + str(world["zoneID"]) if world.get("zoneID") else "")
        identity = "world-study:" + hashlib.sha256(key.encode()).hexdigest()[:20]
        reported_counts = {material["reportedCompletedOperations"] for material in materials}
        baseline = {"inputCount": 1, "materials": materials, "confidence": min(material["confidence"] for material in materials),
                    "sourceProfileView": True, "unknownOutputs": True}
        if len(reported_counts) == 1 and None not in reported_counts:
            baseline["reportedCompletedOperations"] = next(iter(reported_counts))
        result = {"targetID": identity, "nativeTargetID": native_id, "nativeTarget": world,
                  "label": group["label"] or native.get("label") or native_id, "method": group["method"],
                  "profession": group["profession"], "expansionID": group["expansionID"], "recipeID": group["recipeID"],
                  "labels": group["labels"], "baseline": baseline, "sourceProfile": group["sourceProfile"],
                  "sourceProfileAssumed": group["sourceProfileAssumed"], "provenance": group["records"],
                  "cohortKey": group["cohortKey"], "sourceURL": group["sourceURL"],
                  "normalizationPolicy": "shared-runtime-inverse-then-forward-at-preview", "countsAreSourceReported": True}
        for field in ("primaryOutputIDs", "primaryFamilyID", "difficulty", "difficultyConfidence", "qualityThresholds", "qualityConfidence"):
            if field in native:
                result[field] = native[field]
        targets[identity] = result
    counts["empiricalTargets"] = len(targets)
    for name in list(counts):
        if name.startswith(("ADMITTED_", "HELD_", "MERGED_", "PRESERVED_", "PARTIALLY_")):
            del counts[name]
    counts.update(Counter(row["disposition"] for row in review))
    return {"schemaVersion": 1, "revision": "gathering-study-baselines/1", "gatheringTargets": targets,
            "review": {"summary": dict(sorted(counts.items())), "rows": review,
                       "policy": "World identities stay native; no item-input alias, fabricated count, positive-only mean or range midpoint",
                       "rowCountsAreNotIndependentOperations": True}}


def read_rows(roots):
    rows, files = [], {}
    for root in roots:
        if not root.exists():
            continue
        for path in sorted(root.rglob("*.jsonl")):
            relative = path.relative_to(ROOT).as_posix() if path.is_relative_to(ROOT) else path.as_posix()
            files[relative] = hashlib.sha256(path.read_bytes()).hexdigest()
            for line_number, line in enumerate(path.read_text(encoding="utf-8-sig").splitlines(), 1):
                if not line.strip():
                    continue
                try:
                    row = json.loads(line)
                except ValueError:
                    continue
                if isinstance(row, dict):
                    row["_locator"] = relative + ":" + str(line_number)
                    row["_rowSHA256"] = hashlib.sha256(canonical({key: value for key, value in row.items() if not key.startswith("_")}).encode()).hexdigest()
                    rows.append(row)
    return rows, files


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    import profession_profile_rules as profiles
    source = json.loads(NATIVE.read_text(encoding="utf-8"))
    rows, files = read_rows(DEFAULT_ROOTS)
    native_recipes = {row["spellID"]: row for row in source["recipeRouting"]["recipes"]}
    native_targets = profiles.build(source)[0]["gatheringTargets"] if any(is_world_row(row) for row in rows) else {}
    result = compile_rows(rows, set(source["recipeRouting"]["itemIDUniverse"]), native_recipes, native_targets)
    result["sourceFiles"] = files
    result["review"]["sourceFiles"] = files
    outputs = {OUTPUT: "-- Generated native-world study views; source counts are not duplicated.\nreturn " + profiles.lua(result) + "\n",
               REVIEW: json.dumps(result["review"], ensure_ascii=False, indent=2) + "\n"}
    for path, text in outputs.items():
        if args.check:
            if not path.exists() or path.read_text(encoding="utf-8") != text:
                raise SystemExit("Stale gathering study artifact: " + path.name)
        else:
            path.write_text(text, encoding="utf-8", newline="\n")
    print(json.dumps(result["review"]["summary"], sort_keys=True))


if __name__ == "__main__":
    main()
