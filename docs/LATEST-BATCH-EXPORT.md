# Latest-batch export and native copy-window bounds

The owner captured 2 FPS with a blank all-history export window and 110 FPS
after closing it while Settings stayed open. The pasted export is 1,805,127
bytes and contains 683 retained records, 73 contexts and 50 diagnostics. This
before/after isolates the export window as the immediate trigger; it does not
prove a particular native renderer implementation detail or a live FPS result
for the repair. The owner requests only the most recent batch by default.

The normal Export and Export pages buttons now freeze only the active batch,
or the most recent recorded batch if none is active. Include its records,
referenced contexts, study metadata and diagnostics. An active empty batch is
exported as empty rather than silently substituting older results. The account
ledger is never pruned or reset by exporting. Internal all-history calls remain
available and the original raw serializer is unchanged by default.

Large exports use C_EncodingUtil.CompressString with the documented Zlib and
OptimizeForSize enums, then EncodeBase64. The JSON transport envelope declares
loot-liquidator.cast-transfer/1, zlib-base64, the uncompressed byte count and
the payload. The strict Lua importer and Python validator accept this envelope
and original raw JSON. Validate size, codec success and the inner research
schema; Python also bounds decompression and rejects trailing/truncated streams.
No mechanics or coverage flags are removed. Compression API absence/failure
falls back to pages. Oversize pages/reports show a small explanation with the
SavedVariables fallback instead of loading unsafe text or silently truncating it.

The native EditBox never receives more than 65,536 bytes. Avoid redundant
width/height writes and guard reentrant fitting. Closing clears the native
text and selection, stored display text and the frozen paging callback. The
latest 169-record batch in the owner upload serializes to 432,038 bytes; a real
portable zlib/base64 test produces a 14,788-byte copy envelope containing every
record, context, diagnostic and gap. This is a byte-size measurement, not a
live-renderer benchmark. The ordinary flow remains Export, Ctrl+C, close.

CopyToClipboard is protected and cannot be used by ordinary addon code. Export
never calls it or attempts to bypass its restrictions. Contract fixtures throw
if it is called. Native selection prepares Ctrl+C without extra page copying
for the measured batch. No external clipboard helper is installed.

Validation includes the native-widget fixture and frozen paging/skin checks,
latest-study selection, no mutation of 683 saved records, exact payload bytes,
real Python zlib/base64 roundtrip, the Lua native-API contract, damaged length,
codec, base64, truncated/trailing payload rejection and unavailable-codec paths.
The full tests/run.sh suite passes with byte-identical fresh ItemDB compilation.

Primary client declarations:
- https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/EncodingUtilDocumentation.lua
- https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/OsDocumentation.lua
