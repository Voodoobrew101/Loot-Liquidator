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

## Anniversary source-review hold (November 9)

The separate Anniversary extension is stacked on PR52 head
`18e53c3404b647f42c16f99913484b5430aeb0ff`; it does not modify that PR. It reuses
the same exact recordID/studyKey policy, without a second parser or any item,
URL, skill-text or notes-based blacklist. The addon CI pull-request base list
includes `fix/retail-evidence-admission` so native Lua tests also run for the stack.

[The 16 source rows](https://github.com/Voodoobrew101/Loot-Liquidator/blob/462a7cc70fd4871aa51a90ec351bf4390241614c/research/v3/evidence/war-within/2026-11-08T2228-anniversary-mixed-enchanting-source-hits.jsonl)
explicitly hold current TWW baseline/gold-EV promotion pending Master review and
rank/variant reconciliation. They cover three rolling Looter populations for
224744, 224745 and 224747 (32, 199 and 53 reported disenchants, respectively), not
16 independent studies. Modern input reissues show mixed historical/modern
materials, while actual sampled item variants and collection epochs are unknown.
This is a source-review hold, not a claim that all Anniversary items or mixed
material observations are invalid or non-Retail.

Research head `462a7cc70fd4871aa51a90ec351bf4390241614c` retains that hold. A full
research-tree identity and item-ID search found no later correction, Master
promotion or independent exact-item support superseding it. Its existing earlier
[11-row transcription](https://github.com/Voodoobrew101/Loot-Liquidator/blob/462a7cc70fd4871aa51a90ec351bf4390241614c/research/v3/evidence/war-within/2026-11-08T0822-anniversary-defias-blackguard-looter.jsonl)
covers the same 224744/224745 source occurrences with different study keys,
unknown output IDs and gear groups of unspecified rarity. It produces no priced
baseline, remains unchanged, and is not independent evidence. The exact-identity
policy does not recognize those different keys; future identity repair would
require renewed source review. Unknown/malformed identity fields do not trigger
heuristic matching: either surviving exact ID suffices, but losing both is not
recognized by this policy. This is not general malformed-evidence validation.

Without this extension, a future snapshot refresh creates three priced exact-item
baselines despite the explicit source hold. Both range and counted-yield passes
now omit the 16 rows. Existing pinned `4df9ae8b1359d934828e4d0e6d39a9a4dba26fae`
builds remain unchanged. The complete current-research comparison against PR52
must remove only those three records and leave every remaining record identical.
No original evidence, snapshot, confidence formula, runtime baseline or addon
version changes. No research row is promoted by this change.

Two byte-identical fixtures from research `462a7cc7` preserve the evidence:

- `anniversary-held.jsonl`: `2026-11-08T2228-anniversary-mixed-enchanting-source-hits.jsonl`,
  SHA256 `7e3cd720753be660e92fddb53c58b2a2039295389d2dd36a34168d2ce85582e5`.
- `anniversary-earlier.jsonl`: `2026-11-08T0822-anniversary-defias-blackguard-looter.jsonl`.

Run `python3 tests/test_anniversary_admission.py` and the mandatory `tests/run.sh`.
The broader v3 importer deliberately pools provisional historical studies and
half-weights unknown-minimum-skill evidence. This extension does not supply exact
skill/gear/profile applicability. The 18 preserved skill82/104 source rows remain
reference-only; removing those rows from the current research dry run changes no
baseline. Exact-context admission and censored-cohort handling remain separate
work, not repaired by this quarantine.

The shared loader also validates the policy before matching. A v1 policy must be
an object with integer version 1 and an exclusions array; each rule must be an
object with recordIDs/studyKeys arrays of nonempty strings (at least one identity
across them), plus nonempty reason/review strings. Invalid structure raises a
build error rather than silently disabling a hold. An explicitly empty exclusions
array remains valid; extra metadata fields remain allowed. This does not validate
research rows, verify review URLs, or detect semantic removal of valid rules.
