-- Actual new shared cohorts must work without the source character or ledger.
local data=assert(loadfile(arg and arg[1]or'database/disenchant-category-baselines.lua'))()
local records={}
for _,r in ipairs(data.processing)do
    if r.sourceKind=='reviewed-player-retained-subset'then records[#records+1]=r end
end
assert(#records==4,'four reviewed category/profile cohorts required')
GetTime=function()return 100 end
GetBuildInfo=function()return'12.1.5','70961'end
CreateFrame=function()return{RegisterEvent=function()end,SetScript=function()end}end
local checks=0
local function check(v,why)assert(v,why);checks=checks+1 end
local function near(a,b,why)check(type(a)=='number'and math.abs(a-b)<1e-8,why..': '..tostring(a)..' ~= '..tostring(b))end
local function copy(v)if type(v)~='table'then return v end;local out={}for k,x in pairs(v)do out[k]=copy(x)end;return out end
local shipped={};assert(loadfile('LootLiquidator/ItemDBRuntime.lua'))('LL',shipped)
local LL={db={source_itemdb_enabled=true,source_legacy_enabled=false,source_reference_enabled=false,
    source_personal_enabled=false,source_imported_enabled=false,characters={['Different - Realm']={professions={Enchanting=true}}}},
    ItemDB={schemaVersion=1,version='actual-reviewed-retained-capture',processing=records,
        professionProfiles=shipped.ItemDB.professionProfiles,mechanicRules={}}}
for _,file in ipairs({'ProfessionModels.lua','ProfessionCalculations.lua','Database.lua','ConversionEngine.lua'})do
    assert(loadfile('LootLiquidator/'..file))('LL',LL)
end
LL.CharacterKey=function()return'Different - Realm'end
LL.GetOutputPrice=function(_,id)return 100+id%17,'fixture net quote'end
local ctx
LL.ProcessingPlayerConditions=function()return ctx end
local operations=0
for index,r in ipairs(records)do
    operations=operations+r.observedOperations
    ctx=copy(r.baselineProfile);ctx.character='Different - Realm';ctx._cacheIdentity=index;ctx._cacheKey='source-profile-'..index
    ctx.profileKind='live';ctx.simulated=false
    local facts={id=999000+index,classID=r.inputClassID,quality=r.inputRarity,expansionID=r.expansionID,
        itemLevel=100,count=1,context={isBound=true}}
    local option={name='Disenchant',profession='Enchanting',recipeID=13262,inputCount=1}
    local model=assert(LL:ResolveEvidenceModel(facts,option,nil,1))
    check(model.sources.itemdb==1 and not model.sources.personal,'another character uses shared evidence without private records')
    check(model.gearKey==r.gearKey,'source category retained')
    local expected,byID=0,{}
    for _,m in ipairs(r.materials)do
        byID[m.id]=m
        expected=expected+m.expectedQuantity.value*LL:GetOutputPrice(m.id)
    end
    for _,m in ipairs(model.materials)do
        local source=assert(byID[m.id],'no unobserved material introduced')
        near(m.expectedQuantity,source.expectedQuantity.value,'recorded source mean reaches another character unchanged')
        near(m.chance,source.dropChance.value,'recorded source probability is not applied twice')
    end
    near(LL:ValueProcessingModel(model,0,true,facts),expected,'gold is actual E times net quote, independent of drop-rate display')
    check(LL.db.craftResearch==nil,'no copied personal ledger required')
end
check(operations==93,'exact admitted operation total preserved')
print('PASS: '..checks..' actual reviewed capture category/profile/source-to-gold checks')
