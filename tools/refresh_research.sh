#!/usr/bin/env bash
# Prepare a fetched research source in this build workspace, without committing
# generated data, creating PRs, changing versions or publishing releases.
#   bash tools/refresh_research.sh [research-ref]
set -euo pipefail
ref="${1:-origin/implementation/five-agent-completion}"

python3 tools/prepare_build_research.py --research-ref "$ref"
