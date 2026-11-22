-- Numerical fixtures, not game-drop claims. Shared source projections must
-- leave fresh item contexts, observations, valuation, and public models intact.
local checks=0
local function check(value,label)checks=checks+1;assert(value,label)end
local function near(a,b,label)check(type(a)=='number'and math.abs(a-b)<1e-9,label..': '..tostring(a))end
local function clone(v)if type(v)~='table'then return v end local r={}for k,x in pairs(v)do r[k]=clone(x)end return r end
local now=100
GetTime=function()return now end
GetBuildInfo=function()return '12.1.5','70961' end
local LL={db={characters={},source_itemdb_enabled=true,source_itemdb_weight=100,
    source_legacy_enabled=false,source_reference_enabled=false,source_personal_enabled=true,
    source_imported_enabled=true,source_personal_weight=60,source_imported_weight=25}}
for _,file in ipairs({'ProfessionCalculations.lua','Database.lua','ConversionEngine.lua'})do
    assert(loadfile('LootLiquidator/'..file))('LL',LL)
end
LL.ProfessionForMethod=function()return 'Enchanting'end
local effect={metric='yieldMultiplier',amount=100,unit='percent',confidence=100,
    scope={profession='Enchanting',expansionID=9,method='Disenchant'}}
local profile={nodes={[1]={maxRank=1,pointEffects={effect}}},buffs={}}
local data={profiles={['Enchanting:9']=profile},recipes={},recipeQualityModels={},
    items={[100]={bindType=0},[101]={bindType=0}},professionParameters={}}
local function field(v)return{value=v,status='measured',confidence=100,samples=100}end
local function record(id,points,quantity)
    return{recordID=id,studyID=id,source='Independent '..id,sourceKey='itemdb',method='Disenchant',recipeID=13262,
        inputCount=1,expansionID=9,inputRarity=4,inputClassID=4,isDisenchantCategory=true,
        gearKey='gear:9:4:armor',categoryItemLevelMin=1,categoryItemLevelMax=999,referenceContextID='shared',
        baselineProfile={skill=0,specializationPoints={[1]=points}},
        materials={{id=100,rankIDs={100,101},expectedQuantity=field(quantity),dropChance=field(1),
            minQuantity=field(quantity),maxQuantity=field(quantity)}}}
end
local a,b=record('a',0,1),record('b',1,2)
local contexts={}
local state={profession='Enchanting',expansionID=9,character='Actual',skill=20,effectiveSkill=20,
    specialization='none',specializationPoints={[1]=0},stats={},buffsKnown=true,buffs={},contextFlags={}}
LL.ProcessingPlayerConditions=function(self,f)
    if not contexts[f.id]then
        local c=clone(state);c.inputID=f.id;c._cacheKey='input:'..f.id;c._cacheIdentity=f.id
        contexts[f.id]=c
    end
    return contexts[f.id]
end
local projections=0
local apply=LL.ApplyGeneralProfessionModel
LL.ApplyGeneralProfessionModel=function(self,...)projections=projections+1;return apply(self,...)end
local function install(rows)
    LL.ItemDB={schemaVersion=1,version='source-sharing',processing=rows or {a,b},mechanicRules={},
        professionRules={},professionProfiles=data}
    check(LL:InitializeItemDB(),LL.itemDBError)
    contexts={}
end
local option={name='Disenchant',recipeID=13262,inputCount=1}
local function compute(id,personal,imports,override,op)
    local f={id=id,quality=4,classID=4,expansionID=9,itemLevel=441}
    local ctx=override or LL:ProcessingPlayerConditions(f)
    return LL:ComputeEvidenceModel(f,op or option,personal,1,ctx,true,imports),f
end
install()
local first=assert(compute(10));local count=projections
local second=assert(compute(11))
check(count==2 and projections==count,'different ordinary item IDs share each independent source projection')
near(first.materials[1].expectedQuantity,1,'first source profiles normalize independently')
near(second.materials[1].expectedQuantity,1,'shared category numerical projection is unchanged')
check(second.context.inputID==11 and second.projectedContext.inputID==11
    and second.generalProfessionParameters.inputItemID==11,'first item identity never leaks into the next model')
check(first.context~=second.context and first.materials~=second.materials,'public models and item contexts remain distinct')
first.context.contextFlags.changed=true;first.materials[1].expectedQuantity=999
local third=assert(compute(12))
near(third.materials[1].expectedQuantity,1,'mutating a returned model cannot alter a cached source')
check(not third.context.contextFlags.changed,'mutating a returned nested context cannot alter a cached source')
check(a.materials[1].expectedQuantity.value==1 and b.materials[1].expectedQuantity.value==2,
    'raw independent source quantities remain immutable')
local quote=100
LL.GetOutputPrice=function()return quote end;LL.AHFeeRate=function()return 0 end
near(LL:ValueProcessingModel(third,0,true),100,'valuation uses the fresh output quote')
quote=250
local fresh=assert(compute(13))
near(LL:ValueProcessingModel(fresh,0,true),250,'cached sources never retain output prices')

local personal={professionProjected=true,effectiveSamples=100,inputCount=1,
    materials={{id=100,expectedQuantity=3,chance=1,minQuantity=3,maxQuantity=3,confidence=85}}}
local imported=record('import',0,5);imported.sourceKey='imported';imported.inputItemID=14
imported.gearKey=nil;imported.isDisenchantCategory=nil;imported.fixedReference=true
local withOthers=assert(compute(14,personal,{imported}));count=projections
check(withOthers.materials[1].sourceEstimates.personal and withOthers.materials[1].sourceEstimates.imported,
    'enabled personal and imported providers remain in fresh fusion')
personal.materials[1].expectedQuantity=7;personal.materials[1].minQuantity=7;personal.materials[1].maxQuantity=7
imported.materials[1].expectedQuantity.value=9
local updated=assert(compute(14,personal,{imported}))
near(updated.materials[1].sourceEstimates.personal.expectedQuantity,7,'changed personal quantities are not cached')
near(updated.materials[1].sourceEstimates.imported.expectedQuantity,9,'changed imported quantities are not cached')
check(projections==count,'personal/imported availability does not disable safe category source reuse')

state.skill=50;state.effectiveSkill=50;contexts={};count=projections
compute(15);check(projections==count+2,'changed actual skill uses a separate scope')
state.specializationPoints[1]=1;contexts={};count=projections
near(assert(compute(16)).materials[1].expectedQuantity,2,'changed specialization uses its actual projection')
check(projections==count+2,'changed specialization cannot reuse the previous scope')
state.stats={resourcefulness={percent=25}};contexts={};count=projections
compute(17);check(projections==count+2,'changed stat context is isolated even for a stat this method ignores')
state.buffs={['77']=true};contexts={};count=projections
compute(18);check(projections==count+2,'changed buff state is isolated')
check(#LL._categorySourceProjectionCache.scopes<=2,'the shared source cache retains at most two scopes')
now=106;count=projections;compute(19)
check(projections==count+2,'shared sources expire after five seconds')
LL._categorySourceProjectionCache=nil;count=projections;compute(20)
check(projections==count+2,'explicit invalidation clears shared source reuse')
data.revision='next';count=projections;compute(21)
check(projections==count+2,'native data revision invalidates shared source reuse')
data.items[101].bonding=1;count=projections;compute(22)
check(projections==count+2,'in-place alternate binding changes invalidate every affected rank pool')
data.items[101]={bindType=0};count=projections;compute(23)
check(projections==count+2,'native item hydration/replacement invalidates output policy reuse')

-- Direct callers may supply a context different from the actual target reader.
local custom=clone(state);custom.skill=999;count=projections
compute(24,nil,nil,custom);compute(25,nil,nil,custom)
check(projections==count+4,'custom caller contexts use the original uncached transform path')
local wrongOption=clone(option);wrongOption.expansionID=10;count=projections
compute(26,nil,nil,nil,wrongOption);compute(27,nil,nil,nil,wrongOption)
check(projections==count+4,'explicit operation expansion overrides never enter category reuse')

effect.scope.inputItemIDs={30};contexts={};count=projections
compute(30);compute(31)
check(projections==count+4,'item-scoped native effects require separate source projections')
effect.scope.inputItemIDs=nil
LL.ItemDB.professionRules={{method='Disenchant',expansionID=9,inputItemID=32}};count=projections
compute(32);compute(33)
check(projections==count+4,'item-specific profession rules conservatively bypass reuse')
LL.ItemDB.professionRules={}
LL.ItemDB.mechanicRules={{method='Disenchant',expansionID=9,inputItemID=34}};count=projections
compute(34);compute(35)
check(projections==count+4,'item-specific mechanic rules conservatively bypass reuse')
LL.ItemDB.mechanicRules={}
local special=clone(a);special.recordID='override';special.studyID='override';special.reviewedEffectOverrides={}
install({special});count=projections;compute(36);compute(37)
check(projections==count+2,'source-specific reviewed overrides never reuse a projected source')
local bounded={}
for i=1,270 do bounded[i]=record('bounded:'..i,0,1)end
install(bounded);compute(40)
check(LL._categorySourceProjectionCache.scopes[1].count==256,'a scope retains at most 256 source projections')
count=projections;compute(41)
check(projections==count+14,'sources beyond the cache bound retain their ordinary uncached path')
print('CATEGORY SOURCE PROJECTION CACHE: '..checks..' checks passed')
