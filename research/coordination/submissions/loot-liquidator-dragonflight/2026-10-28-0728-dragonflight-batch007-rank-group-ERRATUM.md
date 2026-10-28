# Dragonflight batch007 — immutable rank-group counting erratum

**Supersedes only one count in original commit `6ba8a1d0437b2b806b6d902ec73de393ff7d907d`**, not the 40-row audit or source observations.

Original report and validation claimed **6 complete three-quality proxy groups**. That was an undercount caused by grouping gem IDs via `floor((outputID-192837)/3)`, which is invalid across sparse item-ID sequences. A separate source-line-contiguous, same-input, same-TSM-tuple, ordered target-quality 1/2/3 verification establishes **11 complete three-rank groups**: 3 under input 190394 and 8 under input 199344. The 40 assigned records, source-line matches, necessary p/E bounds, evidence confidence, blocked mechanics and six original historical cohorts are unchanged.

Exact triples:
- 190394: (192862,192863,192865) lines 1426-1428; (192866,192867,192868) lines 1429-1431; (192869,192870,192871) lines 1432-1434.
- 199344: (192843,192844,192845) lines 1559-1561; (192846,192847,192848) lines 1562-1564; (192849,192850,192851) lines 1565-1567; (192852,192853,192855) lines 1568-1570; (192856,192857,192858) lines 1571-1573; (192859,192860,192861) lines 1574-1576; (192862,192863,192865) lines 1577-1579; (192866,192867,192868) lines 1580-1582.

All groups contain the same historical TSM proxy across output ranks; this is an **aggregation-risk signal**, not proof of equal current-Retail probabilities. No production edits or central ledger modifications.
