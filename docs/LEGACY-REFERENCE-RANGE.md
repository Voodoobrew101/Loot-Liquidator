# Preserve one historical reference range

The addon build preserves one archived positive quantity lost by source correction [98ed0cc](https://github.com/Voodoobrew101/Loot-Liquidator/commit/98ed0ccf106ef37344a29066aa6d12f832d71777). This is an independent compatibility safeguard, not a research-source edit or new study. It has no dependency on PR65 and does not replace that PR's denominator/duplicate admission protection for older source snapshots.

## Reviewed facts

Canonical `legacy-20261106-004102` quotes an unidentified Thottbot commenter: “I've made about 25 runecloth headbands, and only got two greater eternal essences from one disenchant.” About 25 made is not a measured disenchant denominator. The original correctly retains unknown casts and one positive event yielding two essence units, but has no machine-readable bounds.

Later `legacy-20261110-24702` adds minSeen/maxSeen=2 and a positive-only histogram. Replacement `legacy-20261110-24914` retains the same quotation, total2/hit1/null casts but changes sourceKind to reference and clears both bounds/histogram. Loader replacement removes24702 before the addon can preserve its range. The new reference classification is retained: this is the same source, not another cohort.

Three original source files are immutable byte-identical fixtures under `tests/fixtures/legacy-reference-range`. `SOURCES.json` records exact paths and SHA256 hashes at correction98ed0cc; those files are unchanged at research9d4d8e3c. They are regression evidence, not new runtime inputs or a refreshed snapshot.

- [Canonical original](https://github.com/Voodoobrew101/Loot-Liquidator/blob/98ed0ccf106ef37344a29066aa6d12f832d71777/research/v3/evidence/legacy/2026-11-06T0042-runecloth-original-essence-observations.jsonl)
- [Positive-range transcription](https://github.com/Voodoobrew101/Loot-Liquidator/blob/98ed0ccf106ef37344a29066aa6d12f832d71777/research/v3/evidence/legacy/2026-11-10T0248-new-original-disenchant-cohorts.jsonl)
- [Replacement24914, line14](https://github.com/Voodoobrew101/Loot-Liquidator/blob/98ed0ccf106ef37344a29066aa6d12f832d71777/research/v3/evidence/legacy/2026-11-10T1143-false-cast-and-duplicate-cohort-replacements.jsonl#L14)

## Exact fail-closed contract

`tools/research_v3_reference_ranges.py` is called on loaded rows immediately after the calculator's replacement/correction stage, before rank resolution and before any admission/range/count pass. Only when target24914 and canonical004102 each occur exactly once and match their complete reviewed loaded-row fingerprints does it shallow-copy24914 with minSeen=maxSeen=2. All other fields and all other rows are unchanged. The source snapshot is never mutated.

Fingerprints are SHA256 over UTF-8 canonical JSON with sorted keys, compact separators, ASCII escapes and no nonfinite values. They include the normalized `_file` path and every source/provenance, classification, replacement, identity, quantity, histogram, null and optional field. The expected digests are addon-owned constants, not source-supplied hashes. JSON booleans/floats cannot impersonate integer observations. Missing, extra, changed, duplicated or malformed fields fail closed, including edits to notes, source URL, quote, studyKey or canonical original. Row/key ordering is irrelevant. This deliberately favors a harmless missed repair over guessing when source changes; changed evidence needs review.

An upstream range correction, canonical enrichment, removal or replacement of24914 makes this safeguard a no-op. It never resurrects24702, overrides corrected bounds, restores a denominator, creates a count/histogram, or marks an observation as a study. A valid replacement chain is still owned by the research loader. Existing admission holds remain free to remove the repaired row before both estimator passes.

The estimator can use reference bounds in its published-range pass; the addon excludes reference rows from counted studies.24914 remains `used=false`, `reference:noUsableValue`, `range=true` under raw usage accounting. All casts/hit weights, EV, chance, confidence and field statuses remain unchanged.

## Impact and limits

Frozen research9d4d8e3c produces exactly one changed compiled ItemDB leaf: Runecloth Headband13866 / Greater Eternal Essence16203 minimum1→2. Its maximum6, EV0.5393, effective average sample260.5, probability and confidence are unchanged. All other complete records, ordering and non-processing data remain equal. The result remains a provisional/estimated aggregate range. A single positive event does not establish a guaranteed minimum, zero-inclusive distribution, new rate, measured certainty or current Retail applicability.

Verified on actual main (611 generated /884 compiled), PR65 (606/879) and published-only PR51–65 integration (602/875). The correction's valid Adamantite denominator fix, Headband null denominator, Warmaul deduplication, canonical originals,24705 and all unrelated evidence are preserved. Current consumed pin4df9ae8 contains neither affected future identity, so generated production data and runtime payload remain unchanged. No current-shipped defect or live-game QA is claimed.

Source-owner append-only preservation remains the preferred cross-consumer solution. Once that lands, verify it and remove this compatibility rule in a separate reviewed change if appropriate. Do not expand these fixed fingerprints automatically or infer missing bounds from arbitrary source text or metadata.
