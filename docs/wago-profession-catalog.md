# Profession choices without an owned profession

The preview bundles 727 paths in 33 profession/expansion catalogs: all eleven
professions with specialization trees in Dragonflight, The War Within and
Midnight. Choose **Simulated**, select an expansion, expand a tree and its
branches, then move the named point sliders. No character scan or profession
access is required. Enchanting includes Disenchanting Delegate and its branches.

Source: public [Wago DB2 tables](https://wago.tools/db2/ProfTraitPathNode?build=12.1.5.70783),
pinned to **12.1.5.70783**, enUS. `database/wago-professions-70783.json` records
source URLs/checksums and the reduced UI catalog. `tools/import_profession_catalog.py`
rebuilds the runtime module from that reviewed snapshot; `--csv-dir` imports a
complete set of public Wago CSV exports. Duplicate identical links are deduplicated;
same-name/same-rank definition revisions are accepted; conflicting names/ranks fail.
Unreachable retired paths are excluded. Unresolved `$` description tokens are omitted.

Names, spend-entry rank limits and parent/child edges are imported, without adding
the separate unlock rank to the point slider. Static client profession APIs can
provide localized descriptions and perk milestone tooltips without a trait config.
If unavailable, bundled English names/rank bounds remain usable. Catalog objects
are copied before enrichment. Existing measured scans and conversion access checks
remain independent.

Unlock conditions have **not** been validated for offline allocations. The UI marks
them unknown and permits simulation rather than locking everything behind the real
character's requirements. Known structured prerequisites from character catalogs
retain their existing enforcement. A Wago edge alone is not treated as a numeric
unlock threshold. Choosing a node never grants learned recipes or real access.

Ratings and effective skill now use nonnegative numeric entry with no fabricated
hard cap. Resourcefulness, Multicraft, Ingenuity and Finesse chance sliders remain
0–100%, with one decimal place. Crafting speed, Deftness and Perception use bonus
percentage fields, which permit values above 100. Rating and percentage have
separate labels/inputs and are not automatically converted. Enter or leaving the
field saves; blank means unknown, negative/nonfinite values are rejected.
These controls do not assert which stats affect a given recipe.

Catalog data supplies no yield formulas, rating curves or promotion of research
mechanics. Tooltip values change only where an approved rule supports the chosen
context. Automated coverage includes all catalogs with an empty character database,
Enchanting names and hierarchy, static milestone enrichment, numeric validation,
speed >100%, collapse preservation and the existing engine contract tests.
In-game rendering and recording remain owner-test items.
