# Reviewed Retail evidence admission

`database/research/retail-admission.json` is a versioned quarantine of reviewed
research record/cohort identities. The main-branch v3 importer applies it before
both estimator passes, including the published range lookup. It reports excluded
row counts and reasons without editing original JSONL, calculator, corrections,
or the pinned snapshot. Renamed copies retaining a quarantined studyKey are also
excluded. It is not a general game-flavor classifier or proof that every admitted
historical observation applies to current Retail.

Initial review: [MoP Classic Looter audit](https://github.com/Voodoobrew101/Loot-Liquidator/blob/5900a95a96360fe9d6575b4f31065dd699006f71/research/v3/evidence/master/2026-11-09T1205-mop-classic-looter-retail-context-gate.md).
The 16 rows describe five item-specific Classic cohorts with 591 source-reported
operations, not newly measured Retail operations. Positive material hits do not
establish material units. These rows must not influence Retail range or yield
estimates without a separately reviewed applicability mapping. None is present
in the current pinned snapshot; this change protects future refresh admission,
not a demonstrated current live-client pricing regression.

A Classic URL alone does not justify exclusion. Historical original-era studies
can be mirrored on Classic pages. Tests retain both an independent Retail control
and an original-era Classic-mirror control. New excluded identities require review
and provenance; copies that lose all reviewed identity fields are not detected.

The [TWW rank-share audit](https://github.com/Voodoobrew101/Loot-Liquidator/blob/5900a95a96360fe9d6575b4f31065dd699006f71/research/v3/evidence/master/2026-11-09T1307-tww-green-de-share-denominator-audit.md)
identifies an ambiguous denominator, not an implemented rank-mean calculation.
The three original rank records have null numeric chance/mean fields; the 2.85
pooled mean has no ranked output ID. The regression confirms these records produce
no priced baseline. Do not multiply the percentages by 2.85 or promote them as
rank-specific means. Source clarification remains with the research owners.

Fixtures under `tests/fixtures/retail-admission/` are byte-for-byte source extracts
from research commit `5900a95a96360fe9d6575b4f31065dd699006f71`:

- `mop-looter.jsonl`: `research/v3/evidence/legacy/2026-11-09T1159-mopclassic-armor-weapon-looter-hitcounts.jsonl`
- `tww-rank-shares.jsonl`: `research/v3/evidence/war-within/2026-11-09T1235-green-de-original-rank-share.jsonl`

Run `python3 tests/test_retail_admission.py` and the mandatory `tests/run.sh` suite.
No live WoW QA, research refresh, source correction, release, or merge is implied.
