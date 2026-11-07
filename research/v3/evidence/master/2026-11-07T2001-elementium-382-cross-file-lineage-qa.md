# Elementium 382-operation joint-outcome source: cross-file identity QA

Reviewed 2026-11-07 UTC by coordinator. **Research-only identity/copy correction candidate. No new casts or independent study; no estimate or addon change.**

## Exact original and two transcriptions

Primary historical author (Wowhead commenter 243051): https://www.wowhead.com/cata/item=52185/elementium-ore . The same original author says 382 Elementium prospects / 1,910 ore and enumerates five mutually exclusive joint results:
- 265 operations: one uncommon, zero rare
- 79: one uncommon, one rare
- 29: two uncommon, zero rare
- 3: one uncommon, two rare
- 6: two uncommon, one rare

Arithmetic directly from those counts: 382 operations, 417 uncommon units, 91 rare units, 382 uncommon-hit operations, 88 rare-hit operations, 294 rare-zero operations; uncommon 0/1/2 histogram = 0/347/35, rare = 294/85/3. Thus historical P(any rare) = 88/382 = 23.0366%, **not** 91/382 = 23.8220% (expected rare units per operation). Historical E(uncommon) = 417/382 = 1.09162 units/operation. These are two tiers jointly observed in **one** cohort, not individual gem item IDs or independent observations per tier. Neither patch, source character skill/build nor current Retail applicability is established.

Existing prior transcription:
- `research/v3/evidence/legacy/2026-11-07T0654-elementium-original-quantity-and-pooled-histograms.jsonl`, original-study IDs `legacy-20261107-0654013` and `legacy-20261107-0654014`; `studyKey=wowhead-cata-elementium-243051-quality-joint-outcomes`; source URL `/cata/item=52185`; `sourceKind=study`; no outputItemID, two named quality-family placeholders.

New worker transcription:
- `research/v3/evidence/legacy/2026-11-07T1950-feliron-adamantite-elementium-original-gaps.jsonl`, IDs `legacy-20261107-1949004`, `legacy-20261107-1949005`; `studyKey=wowhead-elementium-243051-382-joint-category-prospects`; source URL `/ptr/item=52185`; `sourceKind=reference`; the same two quality-family totals and histograms, with alternate family names.

**Newly confirmed lineage gap:** the two pairs have the same original author, denominator, five-bin vector, and material totals but *different* `studyKey`, source route, output-family labels and evidence class. These are **one source cohort, not 764 casts**. The prior 0654 lines were already present before the 1950 worker report. No new research cohort or numeric baseline was added by the second transcription.

## Compiler/valuation guard

Current `research/v3/tools/build_estimates.py` source read at research head `bd119940321f4f4762b38eb05ae31fa43c86a84c`:
- `is_study_row` excludes `sourceKind=reference` from study dedup.
- `study_ref` is file + `studyKey`; `study_identity` also derives an original source page key and group vectors. The `/cata/` URL and generic `/ptr/` URL are not the same normalized source key; the latter drops its ptr suffix.
- `key_of` admits distinct `family:<outputName>` placeholders when outputItemID is null. Here the two files use **different** pseudo-output family names. Independent generated family estimates could therefore be exposed even without any actual item ID.
- References may influence provisional priors in a separate group; study rows may influence measured-looking averages. Do **not** present four rows as distinct cohorts, distribute rarity aggregates among six colors, or call a historical tier-wide chance a modern per-ID tooltip field.

This is an **identified potential compiler/admission defect**, not a claimed reproduced economic overvaluation: no v3 rebuild, current compiled ItemDB audit, actual-engine synthetic price evaluation or in-client test was run for this note. A deterministic evidence/audit fixture should assert one canonical source cohort and hold quality-aggregate output names outside actionable material item-ID groups.

## Follow-up for research worker / coordinator

1. Preserve both append-only original files. Request a worker-owned `replaces` correction or reviewed corrections-file entry for the later duplicate lines, explicitly cross-linking the 0654 original pair; avoid changing original data or inventing a second study.
2. Decide one common canonical source identity independent of /ptr/ versus /cata/ mirrors, and whether an aggregate-of-six outputs is supported by the schema as a *distribution constraint* rather than a tradable item.
3. On a scoped validation branch, exercise `tools/build_estimates.py` and compare `study-audit` plus any family pseudo-output to ensure duplicate references do not create an extra priced material; escalate to integration owner only with actual compiled/valuation proof.
4. Keep original five mutually exclusive outcome counts intact, and do not mistake `P(any rare)` for `E(rare units)` or treat zero rare as zero total gem output.

Guardrails: immutable pinned snapshot `4df9ae8` untouched; no addon branch edits, PR, merges or releases.
