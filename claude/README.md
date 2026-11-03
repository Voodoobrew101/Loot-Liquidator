# Claude's working copy

This branch (`LootLiquidatorclaude-V0.1`) is Claude's working copy of Loot Liquidator.
See [HANDOFF.md](HANDOFF.md) for the task list, the owner's decisions, how to run the
tests, and the session log.

Running the tests without a system Lua:

```bash
pip install lupa --break-system-packages
PATH="$PWD/tools/lua51-shim:$PATH" bash tests/run.sh
```
