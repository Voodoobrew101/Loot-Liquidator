# Batch 010 additive source-identity erratum (2026-10-28)

**DO NOT use** the original observation `midnight-b010-df-lavingrunatic-60-crumbledstone` for rank-specific Eternity Amber `192849` or Nozdorite `192866`. The source (https://www.wowhead.com/item=192880/crumbled-stone, LavingRunatic) reports **55 Eternity Amber and 5 Nozdorite in 60 casts** without stating either gem's quality rank. The original batch010 archive accidentally represented the two family-level outputs as Q1 item IDs, despite its own warning note. This is an unsupported identity assignment, not merely a low-confidence estimate.

**Authoritative corrected observation for this study:** `midnight-b010-df-lavingrunatic-60-crumbledstone-QUALITY-UNMAPPED-CORRECTED`, stored in `research/evidence/observations/2026-10-28-1008-midnight-batch010-laving-QUALITY-UNMAPPED-CORRECTED.jsonl`. It retains exact Crumbled Stone return `192880` with 11/60 and preserves the two gem-family totals in `unmappedReportedOutputs` with null item IDs. Do not count corrected and original as independent experiments.

The assigned queue keys `output-supp:dragonflight:192880:192849:0` and `output-supp:dragonflight:192880:192866:1` **remain insufficient for Q1**. The Mgnta historical source separately reports rank-2 gems (IDs 192850 and 192867), which also cannot prove Q1 output. The original 35-key CSV already marked those keys blocked and did not promote Q1 numerical values; its QA notes remain applicable. No other batch010 records are superseded.

**QA:** 60 actual 5-stone casts; 55+5 gem-family totals retained; 11 returned Crumbled Stone retained; two rank-specific unsupported mappings removed; 0 additional first-pass keys; 0 production edits. Immutable correction rather than overwrite of original evidence.
