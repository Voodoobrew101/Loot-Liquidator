-- Actual multi-study DF epic category. Stub only game/profile/price boundaries.
-- A prior quote attached to item facts must not be copied per source study.
GetBuildInfo=function()return '12.1.5','70961','',120105 end
GetTime=function()return 100 end
CreateFrame=function()return{RegisterEvent=function()end,SetScript=function()end}end
SlashCmdList={}
local LL={}
for line in io.lines('LootLiquidator/LootLiquidator.toc')do
    if line:match('%.lua$')then assert(loadfile('LootLiquidator/'..line))('LL',LL)end
end
LL.db={source_itemdb_enabled=true,source_legacy_enabled=false,source_personal_enabled=false,
    source_imported_enabled=false}
LL:MigrateEvidenceSettings();assert(LL:InitializeItemDB(),LL.itemDBError)
local context={profession='Enchanting',expansionID=9,skill=0,preSpecializationSkill=0,
    simulated=true,specializationPoints={},learnedSpecializations={},stats={},buffs={}}
LL.ProcessingPlayerConditions=function()return context end
LL.GetOutputPrice=function()return 100 end
local facts={id=207160,quality=4,classID=4,expansionID=9,itemLevel=441,count=1}
local option={name='Disenchant',profession='Enchanting',recipeID=13262,inputCount=1}
local first=assert(LL:ResolveEvidenceModel(facts,option,nil,1))
local value=assert(LL:ValueProcessingModel(first,0,true,facts))
facts.conversionOptions={{yieldModel=first}}
local function same(a,b)
    assert(type(a)==type(b),'refresh changed a value type')
    if type(a)~='table'then assert(a==b,'refresh changed a numerical/source field');return end
    for k,v in pairs(a)do same(v,b[k])end
    for k in pairs(b)do assert(a[k]~=nil,'refresh added a source/model field')end
end
LL._processingModelCache=nil
collectgarbage('collect');collectgarbage('stop')
local start=collectgarbage('count')
local nextModel=assert(LL:ResolveEvidenceModel(facts,option,nil,1))
local allocated=collectgarbage('count')-start
collectgarbage('restart');collectgarbage('collect')
assert(allocated<8192,'One real item refresh copied more than 8 MiB of temporary quote graphs')
assert(math.abs(LL:ValueProcessingModel(nextModel,0,true,facts)-value)<1e-9,'gold changed')
same(first,nextModel)
assert(facts.conversionOptions[1].yieldModel==first,'item facts were mutated')
local deSources=0
for _,r in ipairs(LL.ItemDB.processing)do if r.gearKey=='gear:9:4:armor'then deSources=deSources+1 end end
assert(deSources>=100,'allocation regression must exercise the real many-study category')
print(('PASS: %d real category studies refresh in %.1f KiB; all model/source fields and gold unchanged'):format(deSources,allocated))
