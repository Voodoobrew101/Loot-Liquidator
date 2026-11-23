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
python3 tests/test_recycling_zero_prior.py
python3 tests/test_build_info.py
python3 tests/test_capture_observations.py
python3 tests/test_skill82_cohort_audit.py
python3 tools/research_v3_to_baselines.py --check  # D1c: research v3 baselines are current
python3 tools/research_build_review.py --check
python3 tools/profession_effect_inventory.py --check
python3 tools/profession_profile_rules.py --check
python3 tests/test_profession_effect_inventory.py
python3 tests/test_profession_profile_rules.py
python3 tests/test_processing_profile_pruning.py
python3 tools/reference_calculators.py --check
python3 tools/skill_quality_to_rules.py --check
python3 tools/import_profession_catalog.py --check
python3 tools/specialization_effects.py --check
python3 tools/att_token_references.py --check
python3 tests/test_att_token_references.py
python3 tests/test_legacy_gear_tokens.py
python3 tests/test_legacy_omni_tokens.py
python3 tests/test_modern_gear_tokens.py
python3 tests/test_reference_calculators.py
python3 tests/test_skill_quality_pipeline.py
python3 tests/test_midnight_enchanting_import.py
python3 tests/test_disenchant_categories.py
python3 tests/test_specialization_effects_pipeline.py
python3 tests/test_crystal_collector_extras_metadata.py
python3 tests/test_build_research_pipeline.py
python3 tests/test_source_catalogue_review.py
python3 tests/test_source_catalogue_registry.py
python3 tests/test_reviewed_catalogue_proof_stage.py
python3 tests/test_profession_output_clauses.py
python3 tests/test_assemble_source_catalogue.py
python3 tests/test_processing_source_fact_translation.py
python3 tests/test_curseforge_release.py
python3 tests/test_curseforge_workflow_policy.py
python3 tests/test_profession_study_admission.py
python3 tests/test_shatter_quality_models.py
python3 tests/test_published_milling_priors.py
python3 tests/test_published_per_input_priors.py
python3 tests/test_reviewed_source_catalogue.py
compiled_dir=$(mktemp -d)
compiled="$compiled_dir/ItemDBRuntime.lua"
trap 'rm -rf "$compiled_dir"' EXIT
"$lua_bin" tools/compile_itemdb.lua "$compiled"
cmp "$compiled" LootLiquidator/ItemDBRuntime.lua
"$lua_bin" tests/test_itemdb_memory.lua
"$lua_bin" tests/test_decision_cache_memory.lua
"$lua_bin" tests/test_processing_refresh_allocation.lua
"$lua_bin" tests/test_profession_projection_memo.lua
"$lua_bin" tests/test_category_source_projection_cache.lua
"$lua_bin" tests/test_final_model_binding_cache.lua
"$lua_bin" tests/test_badge_cache_capacity.lua
"$lua_bin" tests/test_badge_next_frame_budget.lua
"$lua_bin" tests/test_output_price_request_memo.lua
"$lua_bin" tests/test_tooltip_render_allocation.lua
"$lua_bin" tests/test_tooltip_sort_stability.lua
"$lua_bin" tests/test_recorded_category_allocations.lua
"$lua_bin" tests/test_recorded_processing_query_gates.lua
"$lua_bin" tests/test_fixed_craft_personal_lookup.lua
"$lua_bin" tests/test_compact_static_tables.lua
"$lua_bin" tests/test_item_processing_scope.lua
"$lua_bin" tests/test_itemdb_serialization_parity.lua
test ! -e "$compiled_dir/itemTSM.lua"  # B2: frozen TSM table is no longer built
test ! -e "$compiled_dir/GameData.lua"  # C3: old estimates live inside ItemDB now
python3 tests/validate_package.py
"$lua_bin" research/tests/test_verified_mechanics_adapter.lua
"$lua_bin" tests/test_modernization.lua
"$lua_bin" tests/test_guild_bank_budget.lua
"$lua_bin" tests/test_native_visibility.lua
"$lua_bin" tests/test_settings.lua
"$lua_bin" tests/test_native_stat_reference_receipt.lua
"$lua_bin" tests/test_published_milling_runtime.lua
"$lua_bin" tests/test_published_per_input_runtime.lua
"$lua_bin" tests/test_profession_catalog.lua
"$lua_bin" tests/test_preview_samples.lua
"$lua_bin" tests/test_preview_refresh.lua
"$lua_bin" tests/test_client_regressions.lua
"$lua_bin" tests/test_badge_decision.lua
"$lua_bin" tests/test_badge_refresh.lua
"$lua_bin" tests/test_badge_async_item_info.lua
"$lua_bin" tests/test_pawn_private_tooltip.lua
"$lua_bin" tests/test_cleanup_regressions.lua
"$lua_bin" tests/test_itemdb_metrics.lua
"$lua_bin" tests/test_capture_database.lua
"$lua_bin" tests/test_token_catalog.lua "$compiled_dir"
"$lua_bin" tests/test_token_value_pipeline.lua
"$lua_bin" tests/test_token_transmog_priority.lua
"$lua_bin" tests/test_wayward_tokens.lua
"$lua_bin" tests/test_castle_nathria_tokens.lua
"$lua_bin" tests/test_sepulcher_tokens.lua
python3 tests/test_token_import.py "$compiled_dir"

"$lua_bin" tests/test_frozen_tsm.lua
"$lua_bin" tests/test_profession_projection.lua
"$lua_bin" tests/test_research_profiles.lua "$compiled_dir"
"$lua_bin" tests/test_craft_recording.lua
"$lua_bin" tests/test_recorder_context_capacity.lua
"$lua_bin" tests/test_craft_allocation_diagnostics.lua
"$lua_bin" tests/test_craft_allocation_compatibility.lua
python3 tests/test_craft_allocation_diagnostics.py
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
"$lua_bin" tests/test_personal_disenchant_source_reference.lua
"$lua_bin" tests/test_personal_disenchant_quote.lua
"$lua_bin" tests/test_disenchant_profile_scope_cache.lua
python3 tests/test_disenchant_aura_scope.py
"$lua_bin" tests/test_craft_operations.lua
"$lua_bin" tests/test_imported_results.lua
"$lua_bin" tests/test_salvage_imports.lua
python3 tests/test_disenchant_import_archive.py
# Frozen code-only PR51 baseline, independent of Git history or network access.
echo "e81277e142acca3f9a44e21146e5b1690b5adf1db584793f61cc1f279b7110b4  tests/fixtures/pr51/ImportedResults.lua" | sha256sum -c -
"$lua_bin" tests/test_native_profile_precision.lua tests/fixtures/pr51/ImportedResults.lua
"$lua_bin" tests/test_import_target_lookup.lua
"$lua_bin" tests/test_counts_model.lua
"$lua_bin" tests/test_output_price_vendor_zero.lua
"$lua_bin" tests/test_midpoint_inference_recovery.lua
"$lua_bin" tests/test_observed_bound_proof_validation.lua
"$lua_bin" tests/test_transmog_alts.lua
"$lua_bin" tests/test_appearance_collection.lua
"$lua_bin" tests/test_appearance_positive_shortcut.lua
"$lua_bin" tests/test_appearance_invalidation.lua
"$lua_bin" tests/test_salvage_refund_blend.lua
python3 tests/test_craft_export.py
python3 tests/test_recipe_coverage.py
"$lua_bin" tools/audit_profession_scaling.lua

"$lua_bin" tests/test_disenchant_gaps.lua
"$lua_bin" tools/disenchant_research_gaps.lua database/research/disenchant-gaps.lua --check
python3 tests/test_token_source_applicability.py
python3 tests/test_token_source_compiler.py "$lua_bin"
python3 tests/test_token_research.py
python3 tests/test_token_research_s2.py
python3 tests/test_token_staged_fallback.py
python3 tests/test_evidence_check.py
python3 tests/test_evidence_baselines.py
python3 tools/evidence_to_baselines.py tests/fixtures/evidence-v3 "$compiled_dir/fixture-baselines.lua" >/dev/null
"$lua_bin" tools/compile_itemdb.lua "$compiled_dir/ItemDBFixture.lua" "$compiled_dir/fixture-baselines.lua" tests/fixtures/research-v3-empty.lua >/dev/null
"$lua_bin" tests/test_evidence_baselines.lua "$compiled_dir/ItemDBFixture.lua"
python3 tests/test_research_v3_baselines.py
python3 tests/test_observed_bound_provenance.py
python3 tests/test_observed_bound_guard_edges.py
python3 tests/test_research_v3_precision.py
python3 tests/test_research_v3_dedupe.py
python3 tests/test_research_v3_reference_ranges.py
python3 tests/test_research_v3_snapshot.py
python3 tests/test_retail_admission.py
python3 tests/test_anniversary_admission.py
python3 tests/test_dragonflight_admission.py
python3 tests/test_legacy_cohort_admission.py
"$lua_bin" tests/test_research_v3_runtime.lua
"$lua_bin" tests/test_numeric_refresh_tooltip.lua "$compiled_dir"
"$lua_bin" tests/test_tooltip_preferences.lua
"$lua_bin" tests/test_tooltip_visibility.lua
"$lua_bin" tests/test_tooltip_material_contract.lua
"$lua_bin" tests/test_tooltip_baseline_display_integration.lua
"$lua_bin" tests/test_tooltip_gold_visibility.lua
"$lua_bin" tests/reviewed_source_facts.lua
"$lua_bin" tests/test_reviewed_net_input_basis.lua
"$lua_bin" tests/test_reviewed_quality_profile.lua
"$lua_bin" tests/test_profession_tooltip_visibility.lua
"$lua_bin" tests/test_profession_tooltip_profiles.lua
"$lua_bin" tests/test_tooltip_projection_cache.lua
"$lua_bin" tests/test_skill_quality_capture.lua
"$lua_bin" tests/test_skill_quality_runtime.lua
"$lua_bin" tests/test_native_quality_distribution.lua
"$lua_bin" tests/test_midnight_research_runtime.lua
"$lua_bin" tests/test_disenchant_category_runtime.lua
python3 tests/test_reviewed_disenchant_capture.py
"$lua_bin" tests/test_reviewed_disenchant_capture_runtime.lua
"$lua_bin" tests/test_reviewed_disenchant_full_corpus.lua
python3 tests/test_disenchant_item_categories.py
"$lua_bin" tests/test_disenchant_category_records.lua
"$lua_bin" tests/test_disenchant_category_scoped_contract.lua
"$lua_bin" tests/test_midnight_pigment_runtime.lua
"$lua_bin" tests/test_profession_simulation.lua
"$lua_bin" tests/test_specialization_effects.lua
"$lua_bin" tests/test_disenchant_skill_formulas.lua
"$lua_bin" tests/test_disenchant_context_inputs.lua
"$lua_bin" tests/test_disenchant_baseline_pipeline.lua
"$lua_bin" tests/test_disenchant_baseline_runtime.lua
"$lua_bin" tests/test_reviewed_disenchant_prior.lua
"$lua_bin" tests/test_crystal_collector_extras.lua
"$lua_bin" tests/test_profession_calculations.lua
"$lua_bin" tests/test_profession_tooltip_metrics.lua
"$lua_bin" tests/test_processing_zero_bonus_regression.lua
"$lua_bin" tests/test_numerical_pipeline_stages.lua
"$lua_bin" tests/test_prospecting_output_gates.lua
"$lua_bin" tests/test_prospecting_quality_display.lua
"$lua_bin" tests/test_prospect_group_identity.lua
python3 tests/test_crushed_ore_quality_placeholders.py
"$lua_bin" tests/test_crushed_ore_quality_runtime.lua
"$lua_bin" tests/test_milling_rate_display.lua
"$lua_bin" tests/test_disenchant_rate_display.lua
"$lua_bin" tests/test_processing_inverse_edge_cases.lua
"$lua_bin" tests/test_gem_replacement_milestones.lua
"$lua_bin" tests/test_profession_baseline_pipeline.lua
"$lua_bin" tests/test_shatter_profession_runtime.lua
"$lua_bin" tests/test_profession_all_contexts.lua
"$lua_bin" tests/test_profession_buff_pipeline.lua
"$lua_bin" tests/test_profession_aura_cache.lua
"$lua_bin" tests/test_profession_study_operations.lua
"$lua_bin" tests/test_profession_control_support.lua
"$lua_bin" tests/test_profession_tooltip_scope.lua
"$lua_bin" tests/test_runtime_catalog_pruning.lua
"$lua_bin" tests/test_profession_build_compatibility.lua
"$lua_bin" tests/test_reference_fallback.lua
"$lua_bin" tests/test_usable_field_flow.lua
python3 tests/test_research_v3_no_disenchant.py
python3 tests/test_scoped_disenchant_restrictions.py
"$lua_bin" tests/test_scoped_disenchant_restrictions.lua
"$lua_bin" tests/test_reviewed_use_container.lua
python3 tests/test_rank_families.py
python3 tests/test_input_ranks.py
python3 tests/test_build_info.py
python3 tests/test_package_addon.py
python3 tools/audit_usable_data.py --validate --output "$compiled_dir/usable-data-audit"
