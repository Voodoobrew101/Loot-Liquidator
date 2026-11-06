# Profession choices without an owned profession

The preview bundles 727 paths in 33 profession/expansion catalogs: all eleven
professions with specialization trees in Dragonflight, The War Within and
Midnight. Choose **Simulated**, select an expansion, and move the named point
sliders under each tree and its indented branches. No character scan or profession
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

Profession sliders now use the same Blizzard Settings slider factory, native
artwork, steppers and value formatter as Pricing & Actions, in whole-number steps.
One **Advanced** button sits directly below the character/expansion selectors and
status text. It starts collapsed and contains effective skill, all specialization
trees with indented branch sliders, stats, buffs, scan refresh and captured details.
There are no nested disclosures. Collapsing it retains saved choices.

The refresh path lays out visible controls before hiding unused ones. It never
hides/re-shows the active slider during OnValueChanged, which previously cancelled
mouse dragging. Tests assert that repeated drag-like updates do not hide its holder.

Chance sliders span 0–100%. Starting editing spans are 0–300 effective skill,
0–1000 rating and 0–200 speed/Perception bonus percentage. These are UI spans,
not researched game caps. Saved values above those spans expand the slider range
on load. Ratings and percentages have separate labels and are not converted.
Unedited unknown stats stay unknown in saved data even though their slider rests
at zero. Negative/nonfinite values remain rejected by the profile API. These
controls do not assert which stats affect a given recipe.

Catalog data supplies no yield formulas, rating curves or promotion of research
mechanics. Tooltip values change only where an approved rule supports the chosen
context. Automated coverage includes all catalogs with an empty character database,
Enchanting names and hierarchy, static milestone enrichment, numeric validation,
speed >100%, collapse preservation and the existing engine contract tests.
In-game rendering and recording remain owner-test items.
