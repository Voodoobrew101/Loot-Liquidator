-- B2 (owner decision 3): TSM is used only for Auction House prices. The frozen
-- TSM conversion snapshot stays in database/sources for the record, but it is
-- no longer compiled into or shipped with the addon, and nothing reads it.
local L={}
assert(loadfile('database/sources/ReferenceData.lua'))('LootLiquidator',L)
assert(L.ReferenceData.frozen and #L.ReferenceData.frozen.processing>0,'source snapshot kept, not deleted')
assert(io.open('LootLiquidator/itemTSM.lua','r')==nil,'itemTSM.lua must not ship')
local toc=assert(io.open('LootLiquidator/LootLiquidator.toc','r')):read('*a')
assert(not toc:find('itemTSM',1,true),'TOC must not load itemTSM.lua')
local runtime={}
assert(loadfile('LootLiquidator/ItemDBRuntime.lua'))('LootLiquidator',runtime)
for _,r in ipairs(runtime.ItemDB.processing) do assert(r.sourceKey~='itemtsm','frozen TSM record compiled') end
for _,file in ipairs({'Database.lua','ConversionEngine.lua','Settings.lua'}) do
    local text=assert(io.open('LootLiquidator/'..file,'r')):read('*a')
    assert(not text:find('FrozenTSM',1,true),file..' still reads the frozen TSM table')
end
print('PASS: frozen TSM conversion table removed; TSM is used for AH prices only')
