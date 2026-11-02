-- Owner's current clarification restores usable conversion references inside
-- the one ItemDB. Historical raw data stays immutable; no second runtime module.
local L={}
assert(loadfile('database/sources/ReferenceData.lua'))('LootLiquidator',L)
assert(L.ReferenceData.frozen and #L.ReferenceData.frozen.processing>0,'source snapshot kept, not deleted')
assert(io.open('LootLiquidator/itemTSM.lua','r')==nil,'itemTSM.lua must not ship')
local toc=assert(io.open('LootLiquidator/LootLiquidator.toc','r')):read('*a')
assert(not toc:find('itemTSM',1,true),'TOC must not load itemTSM.lua')
local runtime={}
assert(loadfile('LootLiquidator/ItemDBRuntime.lua'))('LootLiquidator',runtime)
local count=0
for _,r in ipairs(runtime.ItemDB.processing) do
    assert(r.sourceKey~='itemtsm','dedicated itemtsm source must not return')
    if r.sourceKey=='reference' then
        count=count+1
        assert(r.fallbackOnly and r.fixedReference and r.provisional)
    end
end
assert(count>=130,'historical conversion references must reach ItemDB')
for _,file in ipairs({'Database.lua','ConversionEngine.lua','Settings.lua'}) do
    local text=assert(io.open('LootLiquidator/'..file,'r')):read('*a')
    assert(not text:find('FrozenTSM',1,true),file..' still reads the frozen TSM table')
end
print('PASS: usable historical references compiled as labeled fallbacks inside one ItemDB')
