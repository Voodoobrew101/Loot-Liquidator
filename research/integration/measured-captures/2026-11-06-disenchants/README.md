# Disenchant research intake — November 6, 2026

Status: complete two-page export structurally validated; raw research retained; baseline promotion blocked.

Both original pages are preserved byte-for-byte. Together they contain all 46 declared records with 46 unique operation IDs. The newly supplied page 2 adds 21 complete-output disenchant captures from study 8.

Studies 7 and 8 contain 44 November 6 disenchant operations: 42 with complete captured outputs and 2 unresolved. The other 2 records are older unresolved operations. Across the entire export there are 42 complete captures and 4 unresolved casts. These counts identify the new sessions, not verified novelty against every prior export. Operation IDs remain the deduplication keys for future intakes.

The existing tools/validate_craft_export.py validator passes the combined export, including page completeness, context/study/build identity, provenance, measured/non-simulated status and item vectors. Additional checks confirm each record has one consumed input matching its context and no operation ID appears twice.

All represented studies are explicitly censored. The existing baseline compiler therefore emits 0 eligible baseline cohorts and 42 excluded cohorts. Receiving page 2 resolves the incomplete-export blocker but does not resolve capture censorship. Complete output records remain provisional observations; they do not establish approved yield rates, guaranteed bounds, or skill coefficients.

14 contexts report effectiveSkill=0 and maxSkill=0 while labeling skill measured; retain those raw values but do not interpret them as verified zero-skill baselines. Specialization strings are retained and operation stats remain unknown.

The raw export preserves 50 distinct diagnostic entries (repeated across pages are counted once). Diagnostics are review candidates, not additional successful casts. Unresolved empty output records are not evidence of zero yield.

Files: cast-page-1.json and cast-page-2.json are the exact sources; observations.jsonl indexes all 46 records; intake-review.json records counts, validation and source SHA-256 hashes; staged-baselines.json is the existing compiler output with exclusion reasons. No production addon, item database, yield rate, or mechanic was changed.

Next review: investigate censored sessions and capture diagnostics, verify profession-context readings, and collect a fresh complete uncensored controlled study before considering numerical baselines. Do not remove censorship flags to force inclusion.
