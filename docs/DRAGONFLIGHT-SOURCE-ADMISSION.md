# Pdpaul ten-weapon source hold

This future-refresh-only guard extends PR52's version-1 reviewed Retail admission policy. It changes no research source, estimator, pinned snapshot, generated runtime, rate, coefficient or profession normalization.

## Why this source is held

The existing observation is genuine: ten green weapons yielded 25 Chromatic Dust; the author states Draconic Disenchantment maxed. Weapon IDs, item origin/levels/bonuses, build/date, exact skill and other specialization allocations are unknown. A Dragonflight talent-page location does not prove Dragonflight weapon origin. Known maxed specialization is not represented by a generic character-independent category.

The [master review](https://github.com/Voodoobrew101/Loot-Liquidator/blob/eb5d1ddf545ac85b8412b0fa0077dbe8787103f0/research/v3/evidence/master/2026-11-09T2102-df-pdpaul-ten-weapon-context-gate.md) explicitly holds generic gear-group admission pending input-era/identity and applicable specialization scope. Retaining an incomplete observation for research is distinct from admitting it to an addon baseline. This is not a generic ban on small or incomplete studies.

Two retained transcriptions describe the same cohort:

- `dragonflight-20261108-840011`, studyKey `wowhead-insight-of-blue-Pdpaul-10-green-weapons`, [earlier source line 11](https://github.com/Voodoobrew101/Loot-Liquidator/blob/e3c83049b71ac262cfb19492fdb4be13c5a32c90/research/v3/evidence/dragonflight/2026-11-08T0841-three-looter-and-two-firsthand-de-cohorts.jsonl#L11).
- `dragonflight-20261109-204001`, studyKey `wowhead-pdpaul-insight-blue-ten-green-weapons`, [later transcription](https://github.com/Voodoobrew101/Loot-Liquidator/blob/e3c83049b71ac262cfb19492fdb4be13c5a32c90/research/v3/evidence/dragonflight/2026-11-09T2040-pdpaul-ten-green-weapons-25-dust.jsonl).

The original files are preserved byte-identically in `tests/fixtures/dragonflight-admission/`. SHA256 values are checked by the focused test: earlier full file `b06661f77ed0acf91d2a304fd1d99d6e53bc8831b45458c382759bfa353fe99c`; later file `6e5c8014d45241c0eba0bed840a8751aa1050c12a0f18f8b6147ee753025fca9`. The earlier file includes unrelated rows which remain admissible.

## Exact boundary and limits

The existing policy matches global record ID **OR** global studyKey, independent of file path, source kind, material, URL, expansion or prose. A renamed row retaining either identifier stays held, including a replacement retaining its studyKey. Reusing an ID elsewhere is held intentionally; this is not file-scoped matching. A copy replacing both identifiers needs a separate review. No URL/text parser, expansion/material blacklist or second identity mechanism is added.

Admission runs after the unchanged calculator's loading/corrections/replacement handling and rank normalization, but before both the published-range and counted-yield passes, name learning and grouping. Held quantities, ranges and source kinds cannot leak into those passes. **Existing limitation:** loader replacement processing happens first. A synthetic held row with `replaces` can already suppress another row before admission; this guard does not restore it. Neither real transcription has `replaces`. Corrections or a fully renamed replacement can change review identity; assess those separately. Tests document, rather than silently alter, these semantics.

PR52 Classic holds remain unchanged. Combining with PR59 must preserve its Anniversary rule and structural policy validation. PR54's imported-personal Disenchant hold is a different path. No pending fixed40/geared cohort admission or other source-policy update is included.

## Reproduction and scope of confidence

Unchanged research e3c83049 deduplicates the Nov 9 row; Nov 8 supplies one ten-operation mean. Excluding only Nov 9 changes zero outputs. Before this hold, the adapter creates `evidence:v3:Disenchant:gear:9:2:weapon:x1` for output 194123: mean 2.5 measured aggregate, chance 1 and range 1–3 explicitly provisional. Existing half weighting/confidence are assumptions, not measured occurrence or proof of applicability. The candidate is visibly provisional; missing scope is still not supplied by that label.

Holding both identities removes one cohort, not twenty operations. This record is absent from shipped pin 4df9ae8. A full future research refresh is not performed or authorized here; source arithmetic and uncertainty coefficients are unchanged. Original research stays available for a later correctly scoped admission decision.

Run `python3 tests/test_dragonflight_admission.py` and the full `tests/run.sh` before integration. Focused tests preserve source hashes, reproduce unguarded admission/new-copy-only no-op, test each global identifier, independent same-material controls, unrelated rows, both estimator passes, source-kind variations and replacement semantics. Offline tests and fixture compilation do not establish live WoW UI performance or empirical calibration.
