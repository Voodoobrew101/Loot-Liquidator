#!/usr/bin/env bash
set -euo pipefail
export PYTHONDONTWRITEBYTECODE=1
cd "$(dirname "$0")/.."
if command -v lua5.1 >/dev/null 2>&1; then
    lua_bin=$(command -v lua5.1)
    luac_bin=$(command -v luac5.1)
else
    lua_bin=/workspace/.loot-liquidator-tools/lua/usr/bin/lua5.1
    luac_bin=/workspace/.loot-liquidator-tools/lua/usr/bin/luac5.1
fi
for file in LootLiquidator/*.lua database/sources/*.lua database/records.lua database/evidence-baselines.lua database/research-v3-baselines.lua tools/*.lua tests/*.lua research/tests/*.lua; do
    "$luac_bin" -p "$file"
done
python3 tools/import_midnight_enchanting.py --check
python3 tools/evidence_to_baselines.py --check  # D1b: generated baselines are current
python3 tools/disenchant_categories.py --check
python3 tools/capture_observations.py --check
python3 tools/recycling_capture_baselines.py --check
python3 tests/test_build_info.py
python3 tests/test_capture_observations.py
python3 tools/research_v3_to_baselines.py --check  # D1c: research v3 baselines are current
python3 tools/reference_calculators.py --check
python3 tools/skill_quality_to_rules.py --check
python3 tools/import_profession_catalog.py --check
python3 tools/specialization_effects.py --check
python3 tools/att_token_references.py --check
python3 tests/test_att_token_references.py
python3 tests/test_reference_calculators.py
python3 tests/test_skill_quality_pipeline.py
python3 tests/test_midnight_enchanting_import.py
python3 tests/test_disenchant_categories.py
python3 tests/test_specialization_effects_pipeline.py
compiled_dir=$(mktemp -d)
compiled="$compiled_dir/ItemDBRuntime.lua"
trap 'rm -rf "$compiled_dir"' EXIT
"$lua_bin" tools/compile_itemdb.lua "$compiled"
cmp "$compiled" LootLiquidator/ItemDBRuntime.lua
test ! -e "$compiled_dir/itemTSM.lua"  # B2: frozen TSM table is no longer built
test ! -e "$compiled_dir/GameData.lua"  # C3: old estimates live inside ItemDB now
python3 tests/validate_package.py
"$lua_bin" research/tests/test_verified_mechanics_adapter.lua
"$lua_bin" tests/test_modernization.lua
"$lua_bin" tests/test_settings.lua
"$lua_bin" tests/test_profession_catalog.lua
"$lua_bin" tests/test_preview_samples.lua
"$lua_bin" tests/test_preview_refresh.lua
"$lua_bin" tests/test_client_regressions.lua
"$lua_bin" tests/test_badge_decision.lua
"$lua_bin" tests/test_badge_refresh.lua
"$lua_bin" tests/test_cleanup_regressions.lua
"$lua_bin" tests/test_itemdb_metrics.lua
"$lua_bin" tests/test_capture_database.lua
"$lua_bin" tests/test_token_catalog.lua "$compiled_dir"
"$lua_bin" tests/test_token_value_pipeline.lua
"$lua_bin" tests/test_token_transmog_priority.lua
"$lua_bin" tests/test_wayward_tokens.lua
python3 tests/test_token_import.py "$compiled_dir"

"$lua_bin" tests/test_frozen_tsm.lua
"$lua_bin" tests/test_profession_projection.lua
"$lua_bin" tests/test_research_profiles.lua "$compiled_dir"
"$lua_bin" tests/test_craft_recording.lua
"$lua_bin" tests/test_recorder_lookup.lua
"$lua_bin" tests/test_recycling.lua
"$lua_bin" tests/test_radiant_shatter.lua
python3 tests/test_radiant_shatter_contract.py
"$lua_bin" tests/test_salvage_ui.lua
"$lua_bin" tests/test_recipe_coverage.lua
"$lua_bin" tests/test_disenchant_capture.lua
"$lua_bin" tests/test_export_dialog.lua /tmp/loot-disenchant-capture-v2.json /tmp/loot-recycling-capture-v3.json
python3 tests/test_compact_transfer.py
"$lua_bin" tests/test_compact_transfer.lua
"$lua_bin" tests/test_disenchant_recording_categories.lua
"$lua_bin" tests/test_craft_operations.lua
"$lua_bin" tests/test_imported_results.lua
"$lua_bin" tests/test_salvage_imports.lua
"$lua_bin" tests/test_import_target_lookup.lua
"$lua_bin" tests/test_counts_model.lua
"$lua_bin" tests/test_transmog_alts.lua
"$lua_bin" tests/test_appearance_collection.lua
python3 tests/test_craft_export.py
python3 tests/test_recipe_coverage.py
"$lua_bin" tools/audit_profession_scaling.lua

"$lua_bin" tests/test_disenchant_gaps.lua
python3 tests/test_token_research.py
python3 tests/test_token_research_s2.py
python3 tests/test_evidence_check.py
python3 tests/test_evidence_baselines.py
python3 tools/evidence_to_baselines.py tests/fixtures/evidence-v3 "$compiled_dir/fixture-baselines.lua" >/dev/null
"$lua_bin" tools/compile_itemdb.lua "$compiled_dir/ItemDBFixture.lua" "$compiled_dir/fixture-baselines.lua" tests/fixtures/research-v3-empty.lua >/dev/null
"$lua_bin" tests/test_evidence_baselines.lua "$compiled_dir/ItemDBFixture.lua"
python3 tests/test_research_v3_baselines.py
python3 tests/test_research_v3_precision.py
python3 tests/test_research_v3_dedupe.py
python3 tests/test_research_v3_snapshot.py
"$lua_bin" tests/test_research_v3_runtime.lua
"$lua_bin" tests/test_numeric_refresh_tooltip.lua "$compiled_dir"
"$lua_bin" tests/test_tooltip_preferences.lua
"$lua_bin" tests/test_tooltip_visibility.lua
"$lua_bin" tests/test_profession_tooltip_visibility.lua
"$lua_bin" tests/test_profession_tooltip_profiles.lua
"$lua_bin" tests/test_synthetic_benchmark.lua
"$lua_bin" tests/test_skill_quality_capture.lua
"$lua_bin" tests/test_skill_quality_runtime.lua
"$lua_bin" tests/test_midnight_research_runtime.lua
"$lua_bin" tests/test_disenchant_category_runtime.lua
"$lua_bin" tests/test_midnight_pigment_runtime.lua
"$lua_bin" tests/test_profession_simulation.lua
"$lua_bin" tests/test_specialization_effects.lua
"$lua_bin" tests/test_profession_control_support.lua
"$lua_bin" tests/test_reference_fallback.lua
"$lua_bin" tests/test_usable_field_flow.lua
python3 tests/test_research_v3_no_disenchant.py
python3 tests/test_rank_families.py
python3 tests/test_input_ranks.py
python3 tests/test_package_addon.py
python3 tools/audit_usable_data.py --validate --output "$compiled_dir/usable-data-audit"
