-- Prices/API fixtures test known zero versus unavailable data, not game prices.
CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
local LL={db={},ItemDB={professionProfiles={items={[3]={bindType=1}}}}}
assert(loadfile('LootLiquidator/Professions.lua'))('LL',LL)
assert(loadfile('LootLiquidator/ConversionEngine.lua'))('LL',LL)
LL.TSMString=function(_,_,id)return 'i:'..id end
LL.Price=function()return nil end
LL.AHFeeRate=function()return .05 end
local vendors={[1]=0,[2]=100,[3]=50}
C_Item={GetItemInfo=function(id)
    if vendors[id]==nil then return nil end
    return 'Loaded fixture',nil,1,1,1,'Fixture','Fixture',1,'',1,vendors[id],7,0,0,11
end}
assert(LL:GetOutputPrice(1)==0,'A ready unbound item with sell price zero has a known zero quote')
assert(LL:GetOutputPrice(2)==100,'Positive vendor output remains unchanged')
assert(LL:GetOutputPrice(4)==nil,'Unloaded item data remains unknown instead of becoming zero')
assert(LL:GetOutputPrice(3)==50,'A bound item retains its ready vendor value')
vendors[3]=0;assert(LL:GetOutputPrice(3)==0,'A bound ready zero remains zero')
vendors[3]=nil;assert(LL:GetOutputPrice(3)==nil,'A bound item with pending API metadata remains unknown')
LL.Price=function(_,source)return source=='dbmarket' and 200 or nil end
assert(LL:GetOutputPrice(1)==190,'A known auction quote still takes precedence and applies the AH cut once')
LL.Price=function()return nil end
local model={inputCount=5,confidence=80,materials={{id=1,expectedQuantity=2}}}
assert(LL:ValueProcessingModel(model,0,true)==0 and model.materials[1].netUnitPrice==0
    and model.materials[1].netExpectedValue==0 and not model.partialPrice,
    'A genuine zero unit quote produces a known zero expected value')
model={inputCount=5,confidence=80,materials={{id=4,expectedQuantity=2}}}
assert(LL:ValueProcessingModel(model,0,true)==nil and model.materials[1].netExpectedValue==nil
    and model.partialPrice,'Missing unit prices remain unavailable in gold calculations')
local pool={rankIDs={1,2},id=1}
assert(LL:GetMaterialPrice(pool)==0,'A known zero is retained when choosing the cheapest supported rank')
pool.rankIDs={4,2};assert(LL:GetMaterialPrice(pool)==100,'An unavailable rank does not undercut a priced rank')
C_Item=nil;GetItemInfo=nil
assert(LL:GetOutputPrice(1)==nil and LL:GetOutputPrice(3)==0,'Existing no-API bound/unbound behavior is preserved')
print('PASS: ready vendor zero is known, pending prices stay nil, bound/auction/rank-pool valuation behavior preserved')
