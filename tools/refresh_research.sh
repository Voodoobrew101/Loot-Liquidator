#!/usr/bin/env bash
# Pull the latest research into the pinned snapshot and regenerate every file built from it.
# Used by .github/workflows/research-refresh.yml; safe to run by hand.
#   bash tools/refresh_research.sh [research-ref]
set -euo pipefail
ref="${1:-origin/implementation/five-agent-completion}"

python3 tools/research_v3_to_baselines.py --refresh "$ref"

# Some generators read each other's output, so run the chain twice to settle.
for pass in 1 2; do
  python3 tools/import_midnight_enchanting.py
  python3 tools/reference_calculators.py
  python3 tools/skill_quality_to_rules.py
  python3 tools/research_v3_to_baselines.py
  python3 tools/evidence_to_baselines.py
  python3 tools/capture_observations.py
  python3 tools/att_token_references.py
done
python3 tools/recycling_capture_baselines.py --check
lua5.1 tools/compile_itemdb.lua LootLiquidator/ItemDBRuntime.lua
