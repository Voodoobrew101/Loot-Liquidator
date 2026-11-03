# Immutable erratum — Legacy q26 batch024 audit source-parent lookup
2026-10-29 00:41 PDT. **Original audit preserved unchanged.**

The first q26 audit incorrectly labeled three Draconium output identities as `MISMATCH` because its automated parent search scanned only the previous 17 lines. Each Draconium prospecting parent block has more than 17 output rows. A corrected backwards search for the **nearest enclosing `gd.tsmRetail.prospect[inputItemID]` declaration** confirms all three and the 11 fish records match the pinned GameData.lua source blob.

Corrected rows:
- `tsm:prospect:189143:192871:L1244`: line 1244 output 192871, enclosing `gd.tsmRetail.prospect[189143]`.
- `tsm:prospect:190311:192870:L1281`: line 1281 output 192870, enclosing `gd.tsmRetail.prospect[190311]`.
- `tsm:prospect:190311:192871:L1282`: line 1282 output 192871, enclosing `gd.tsmRetail.prospect[190311]`.

**Authoritative replacement audit:** `research/coordination/submissions/loot-liquidator-legacy/2026-10-29-0041-legacy-q26-batch024-14key-fourfield-audit-corrected-v2.jsonl`. It contains all 14 keys with 14/14 identity MATCH. Do not count the original audit and corrected audit as two sets of observations; v2 supersedes original identity labels only. No material identity correction, new mapping, numeric promotion or current-Retail gold value resulted. Improve future validation by walking to the enclosing block header rather than assuming a fixed lookback span.
