local L={}
assert(loadfile('database/sources/GameData.lua'))('LootLiquidator',L)
local original=L.GameData.tsmRetail
assert(loadfile('LootLiquidator/itemTSM.lua'))('LootLiquidator',L)
local function same(a,b)
    assert(type(a)==type(b))
    if type(a)~='table' then assert(a==b);return end
    for k,v in pairs(a) do same(v,b[k]) end
    for k in pairs(b) do assert(a[k]~=nil) end
end
same(original,L.FrozenTSM.rawTables)
local count=0
for _,r in ipairs(L.FrozenTSM.processing) do
    assert(r.sourceKey=='itemtsm' and r.fixedReference)
    for _,m in ipairs(r.materials) do
        local t=assert(m.originalTSM)
        assert(m.dropChance.value==t.matRate)
        assert(m.minQuantity.value==t.minAmount)
        assert(m.maxQuantity.value==t.maxAmount)
        assert(m.expectedQuantity.value==t.amountOfMats*r.inputCount)
        count=count+1
    end
end
assert(count>0)
-- Re-reading after unrelated live-price changes cannot import a new rate.
TSM_API={GetCustomPriceValue=function() return 987654 end}
local reloaded={};assert(loadfile('LootLiquidator/itemTSM.lua'))('LootLiquidator',reloaded)
same(L.FrozenTSM,reloaded.FrozenTSM)
print('PASS: complete frozen TSM raw tables, four-field references and price-update independence')
