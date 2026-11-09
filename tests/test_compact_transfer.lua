-- Native API contract fixture using genuine Python-produced zlib/base64 bytes.
-- No alternate codec is implemented here and no live renderer/FPS is claimed.
local LL={}
CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
for _,name in ipairs({'CraftRecording.lua','ImportedResults.lua'})do assert(loadfile('LootLiquidator/'..name))('LL',LL)end
local function read(name)local f=assert(io.open('/tmp/'..name,'rb'));local s=f:read('*a');f:close();return s end
local raw,binary,encoded,wire=read('loot-latest-batch.json'),read('loot-transfer-zlib.bin'),
    read('loot-transfer-base64.txt'),read('loot-transfer-wire.json')
C_EncodingUtil={
    CompressString=function(s,method,level)assert(s==raw and method==1 and level==2);return binary end,
    EncodeBase64=function(s)assert(s==binary);return encoded end,
    DecodeBase64=function(s)assert(s==encoded);return binary end,
    DecompressString=function(s,method)assert(s==binary and method==1);return raw end}
local packed=assert(LL:PackCraftExport(raw))
assert(packed==wire,'Lua envelope matches the portable Python zlib/base64 format byte-for-byte')
local decoded,why,restored=LL.DecodeImportJSON(packed)
assert(decoded,why);assert(restored==raw,'exact native serialized bytes survive packing and decoding')
assert(#decoded.records==169 and #decoded.diagnostics==50 and decoded.totalRetainedRecords==683)
assert(decoded.studies[decoded.exportStudyID].coverageGaps['Disenchant:13262'])
assert(#packed<65536 and not packed:find('|',1,true),'compact copy is bounded and markup-free')
local original=C_EncodingUtil
C_EncodingUtil=nil
assert(not LL:PackCraftExport(raw),'older clients fall back rather than invoking missing APIs')
assert(not LL.DecodeImportJSON(packed),'missing decoder cannot silently import an empty result')
assert(LL.DecodeImportJSON(raw),'raw JSON remains readable without compression APIs')
C_EncodingUtil={CompressString=function()error('unavailable')end,EncodeBase64=original.EncodeBase64}
assert(not LL:PackCraftExport(raw),'native compression failure is handled')
C_EncodingUtil=original
print('PASS: exact 169-cast native-contract zlib/base64 roundtrip, original JSON and unavailable-codec failures')
