#!/usr/bin/env python3
"""Check the master prompt registry and bundled plugin snapshot."""
import json
import pathlib
import sys

ROOT=pathlib.Path(__file__).resolve().parents[1]
LIB=ROOT/"docs/master-prompts"
PKG=ROOT/"tools/prompt-manager-plugin"
idx=json.loads((LIB/"registry.json").read_text(encoding="utf-8"))
snapshot=json.loads((PKG/"skills/manage-loot-liquidator-prompts/references/registry.json").read_text(encoding="utf-8"))
assert idx==snapshot, "Plugin registry snapshot is stale"
assert len(idx["entries"]) == len(set(x["id"] for x in idx["entries"])), "Duplicate prompt IDs"
for e in idx["entries"]:
    path=e["path"]
    if e["status"] == "awaiting_full_text":
        assert path is None and e["version"] is None, e["id"]
        continue
    assert path and path.startswith("prompts/") and ".." not in path, e["id"]
    text=(LIB/path).read_text(encoding="utf-8")
    bundled=(PKG/"skills/manage-loot-liquidator-prompts/references"/path).read_text(encoding="utf-8")
    assert text and text==bundled, f"Mismatch: {e['id']}"
assert len(json.loads((PKG/"plugin.json").read_text(encoding="utf-8"))["extensions"]["com.openai"]["interface"]["shortDescription"]) <= 30
print("PASS: registry, references, versions, snapshots and plugin manifest")
