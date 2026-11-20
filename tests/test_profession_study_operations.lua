-- Exercise admitted recipe identities through discovery and the quote path.
local checks=0
local function check(v,label) assert(v,label);checks=checks+1 end
local function field(value) return {status='measured',value=value,confidence=70,samples=5} end
local LL={db={characters={Player={professions={},recipes={}}}},ItemDB={schemaVersion=1,processing={}}}
CreateFrame=function()return{RegisterEvent=function()end,SetScript=function()end}end
GetTime=function()return 100 end
time=GetTime
GetBuildInfo=function()return'12.1.5','70961'end
GetItemCount=function()return 100 end
local methods={{'Mill','Inscription'},{'Prospect','Jewelcrafting'},{'Smelt','Mining'},
    {'Recycle','Engineering'},{'Craft','Alchemy'},{'Research','Engineering'},
    {'Unravel','Tailoring'},{'Crush','Jewelcrafting'},{'Thaumaturgy','Alchemy'},{'Refine','Herbalism'}}
for index,entry in ipairs(methods)do
    local recipe=8000+index
    LL.db.characters.Player.professions[entry[2]]=true
    LL.db.characters.Player.recipes[recipe]={learned=true,profession=entry[2]}
    LL.ItemDB.processing[#LL.ItemDB.processing+1]={recordID='operation:'..entry[1],studyID='operation:'..entry[1],
        sourceKey='itemdb',source='fixture controlled study',method=entry[1],profession=entry[2],recipeID=recipe,
        expansionID=11,inputItemID=1001,inputCount=2,inputQualityRank=1,
        requiredInputs={{id=1001,amount=2},{id=1002,amount=3}},
        materials={{id=2000,expectedQuantity=field(3),dropChance=field(1),minQuantity=field(3),maxQuantity=field(3)}}}
end
for _,file in ipairs({'Professions.lua','Database.lua','ConversionEngine.lua'})do assert(loadfile('LootLiquidator/'..file))('LL',LL)end
LL.CharacterKey=function()return'Player'end
check(LL:InitializeItemDB(),LL.itemDBError)
local facts={id=1001,classID=7,expansionID=11,reagentQuality=1,count=100,context={verifiedUnbound=true}}
local operations=LL:ResearchProcessingOperations(facts)
check(#operations==#methods,'every admitted item method enters exact recipe discovery')
for _,entry in ipairs(methods)do
    local found
    for _,operation in ipairs(operations)do if operation.method==entry[1]then found=operation end end
    check(found and found.profession==entry[2] and found.recipeID,'method retains its exact profession and recipe')
    check(not found.allocationCostUnknown and found.extraReagents[1].id==1002 and found.extraReagents[1].amount==3,
        'complete required-input contract retains every extra cost')
    check(LL:ResearchProcessingRecipeOperations(found.recipeID)[1].method==entry[1],
        'recorder and quote discovery share admitted recipe identities')
end
check(#LL:ResearchProcessingOperations({id=1001,expansionID=10,reagentQuality=1})==0,'recipe discovery preserves expansion scope')
check(#LL:ResearchProcessingOperations({id=1001,expansionID=11,reagentQuality=2})==0,'recipe discovery preserves exact input rank')
local craft=LL.ItemDB.processing[5]
craft.requiredInputs=nil
LL:InitializeItemDB()
local unknown
for _,op in ipairs(LL:ResearchProcessingOperations(facts))do if op.method=='Craft'then unknown=op end end
check(unknown and unknown.allocationCostUnknown,'ordinary Craft never assumes study input was the complete reagent bill')
LL.GetOutputPrice=function(_,id)return id==2000 and 100 or id==1002 and 10 or 4 end
LL.GetMaterialPrice=function(self,m)return self:GetOutputPrice(m.id)end
LL.EligibleDisenchant=function()return false end
LL.ResolveEvidenceModel=function(_,_,option)
    return{inputCount=option.inputCount,materials={{id=2000,expectedQuantity=3,confidence=70}},confidence=70}
end
local function quote(method)
    for _,v in ipairs(LL:ConversionOptions(facts))do if v.name==method then return v end end
end
local unpriced=quote('Craft')
check(unpriced and unpriced.yieldModel and unpriced.value==nil and unpriced.partial,
    'unknown recipe costs show material units while refusing free-output gold')
craft.requiredInputs={{id=1001,amount=2},{id=1002,amount=3}}
LL:InitializeItemDB()
local priced=quote('Craft')
check(priced and priced.value==135 and priced.vendorSupplyCost==30,'verified complete recipe costs reach actual quote valuation')
LL.db.characters.Player.recipes[craft.recipeID]=nil
local inaccessible=quote('Craft')
check(inaccessible and not inaccessible.available,'admitted studies and specialization points do not grant an unlearned recipe')
print('PROFESSION STUDY OPERATIONS: '..checks..' checks passed')
