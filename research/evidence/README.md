# Research evidence archive — source observations, NOT a second addon database

**Canonical branch:** `research/processing-confidence` in Voodoobrew101/Loot-Liquidator.  
**Live addon database:** `GameData.lua` only. This archive is **research-only** and must never be loaded as a competing static database by the addon.

## What is already stored here

- `research/ledger/source-inventory.csv`: 389 inventoried source profiles (overlapping, not 389 independently verified recipes).
- `research/ledger/processing-output-fields.csv` and `supplemental-output-fields.csv`: 1,256 initial output source rows with evidence/confidence fields.
- `research/ledger/tsm-invariant-anomalies.csv`: 40 TSM contradictions, retained for investigation.
- `research/ledger/titanium-observed-yields.csv`: 12 historical, source-backed yield observations (NOT guaranteed current Retail).
- `research/ledger/runtime-overlay-map.csv`: 92 output mappings generated in other Lua modules.
- `research/research-sources.md`: reference/provenance notes.
- `research/PROGRESS.md` and `research/run-log.md`: research status and continuation.
- `research/mechanics/ProfessionMechanicsRegistry.json`: versioned profession mechanics, patch effects and blocking policies.
- `research/mechanics/WoWRuntimeAPIRegistry.json`: what a WoW addon can read and what must be externally researched.

**These inventories and aggregate source rows are not full original per-operation experimental records.**

## New storage contract

The version-controlled, long-term raw evidence location is `research/evidence/observations/*.jsonl`. Each JSONL file contains one valid JSON observation per line. See `observation.schema.json` for required keys, metadata and units. Group by one known source study, preserve original observations and add new versions rather than silently rewriting historical evidence.

Always retain:
- One stable study/observation identifier and the original source URL/comment/reference plus retrieved date.
- Game mode, exact Retail client build when known (or `null`), date/hotfix window (or `null`), profession/recipe IDs, item IDs and input/variant quality.
- Real/simulated/proxy profession skill, committed talent ranks, profession gear/stats, buffs, Concentration, resource returns, and precise **unknown reasons** for unavailable values.
- Exact operation count and input quantity; don't use consumed ore count as operation count.
- For each output, raw total quantities, number of casts that produced the output, and a **zero-inclusive histogram of units per cast** when available. Aggregate reports alone support an unconditional mean, not exact P(drop) or conditional whole-number bounds.
- Separate evidence classifications/confidence and provenance per `dropChance`, `yieldMin`, `yieldMax`, `expectedQuantity`, and **per derived transformation**.
- Whether a patch or missing skill condition **blocks normalization**; never assume the transform equals 1.

**Personal privacy:** Do not publish real character names, realms, account information, exact timestamps traceable to an individual, raw chat logs, or player identifiers from user-collected samples without explicit approval. Use anonymized source/cohort IDs. The addon can keep full personal SavedVariables locally; published research requires consent and minimal data.

## Research pipeline

```text
Official sources / published experiments / consensual anonymized in-game logs
    -> immutable raw observations (research/evidence/observations/*.jsonl)
    -> patch, skill, reagent and API applicability validation
    -> research/mechanics/ProfessionMechanicsRegistry.json
    -> audited per-field derived ledgers (research/ledger/*.csv)
    -> candidate current-Retail, condition-labelled baseline (research/proposed/)
    -> tested compilation into main/GameData.lua ONLY after explicit release approval
```

A verified transformation has its own source claim and confidence. A sample from an unknown or mismatched patch retains its original observation and is NOT automatically converted to current Retail.

## Data-store choice

Keep **JSONL + CSV in Git** as the canonical source of truth: diffable, attributable and readable by both research agents. For large-scale analysis, generate SQLite/Parquet locally as reproducible derived indexes or CI artifacts; do not commit mutable binary databases or large unreviewed scrape dumps as the canonical source. Use Git LFS or separate consented archival storage only if raw data grows past practical Git repository limits.

## New study checklist

1. Record the study exactly and identify missing fields as `null`, not zero.
2. Validate against `observation.schema.json`; check item IDs, batch denominators and game version.
3. Link source documentation and independently verify claimed effects.
4. Calculate per-operation unconditional mean only when quantity and eligible operation count are known.
5. Do not invent per-cast occurrence probability or [min,max] from aggregate material totals.
6. Check patch history and modifiers; stop unsupported numeric transformations.
7. Add source-backed ledgers/proposed deltas separately. Commit and verify readback.
8. Do not modify the released `main` automatically.

**Note:** This storage contract does not mean every sample has complete evidence, nor does its presence establish 90/100 confidence.
