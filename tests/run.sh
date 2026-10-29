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
for file in LootLiquidator/*.lua database/sources/*.lua database/records.lua tools/*.lua tests/*.lua research/tests/*.lua; do
    "$luac_bin" -p "$file"
done
compiled_dir=$(mktemp -d)
compiled="$compiled_dir/ItemDBRuntime.lua"
trap 'rm -rf "$compiled_dir"' EXIT
"$lua_bin" tools/compile_itemdb.lua "$compiled"
cmp "$compiled" LootLiquidator/ItemDBRuntime.lua
cmp "$compiled_dir/itemTSM.lua" LootLiquidator/itemTSM.lua
cmp "$compiled_dir/GameData.lua" LootLiquidator/GameData.lua
python3 tests/validate_package.py
"$lua_bin" research/tests/test_verified_mechanics_adapter.lua
"$lua_bin" tests/test_modernization.lua
"$lua_bin" tests/test_settings.lua

"$lua_bin" tests/test_frozen_tsm.lua
"$lua_bin" tests/test_profession_projection.lua
"$lua_bin" tests/test_research_profiles.lua "$compiled_dir"
"$lua_bin" tests/test_craft_recording.lua
python3 tests/test_craft_export.py
"$lua_bin" tools/audit_profession_scaling.lua

