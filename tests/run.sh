#!/usr/bin/env bash
set -euo pipefail
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
compiled=$(mktemp)
trap 'rm -f "$compiled"' EXIT
"$lua_bin" tools/compile_itemdb.lua "$compiled"
cmp "$compiled" LootLiquidator/itemdb.lua
python3 tests/validate_package.py
"$lua_bin" research/tests/test_verified_mechanics_adapter.lua
"$lua_bin" tests/test_modernization.lua
"$lua_bin" tests/test_settings.lua
