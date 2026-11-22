-- A never-scanned native recipe must retain its talent scope and quality/gold
-- behavior after broad catalog rows are removed. API item facts are fixtures.
local checks=0
local function check(v,label)assert(v,label);checks=checks+1 end
local function near(a,b,label)check(type(a)=='number'and math.abs(a-b)<1e-9,label..': '..tostring(a)..' ~= '..tostring(b))end
local function copy(v)if type(v)~='table'then return v end local out={}for k,x in pairs(v)do out[k]=copy(x)end return out end
local function same(a,b)
    if type(a)~=type(b)then return false end;if type(a)~='table'then return a==b end
    for k,v in pairs(a)do if not same(v,b[k])then return false end end
    for k in pairs(b)do if a[k]==nil then return false end end return true
end
GetTime=function()return 100 end;time=GetTime
GetBuildInfo=function()return '12.1.5','70961' end
CreateFrame=function()return{RegisterEvent=function()end,SetScript=function()end}end
local future={profession='Alchemy',expansionID=10,labels={7},difficulty=100,
    supportsQuality=true,supportsMulticraft=false,supportsResourcefulness=true,
    capabilityConfidence={multicraft=60,resourcefulness=35},outputCount=2,
    outputIDs={301,302},outputQualityItems={{id=301},{id=302}},qualityOrderVerified=true,
    qualityThresholds={{rank=1,fraction=0,sourceRowID=1},{rank=2,fraction=1,sourceRowID=2}},
    sourceAbilityIDs={900000},unusedDescription='This description does not ship for an unused recipe'}
local profiles={schemaVersion=1,items={
    [101]={name='Input',bindType=0},[201]={name='Known output R1',bindType=0,qualityFamilyID=21,qualityRank=1},
    [202]={name='Known output R2',bindType=0,qualityFamilyID=21,qualityRank=2},
    [301]={name='Future output R1',bindType=0,qualityFamilyID=22,qualityRank=1},
    [302]={name='Future output R2',bindType=0,qualityFamilyID=22,qualityRank=2},
    [401]={name='Future bound output',bindType=1,vendorPrice=7},[999]={name='Unrelated item',bindType=0}},
    recipes={[500]={profession='Alchemy',expansionID=10,outputIDs={201}},[600]=future,[601]=copy(future)},
    qualityFamilies={[21]={rankItemIDs={201,202},qualityOrderVerified=true},
        [22]={rankItemIDs={301,302},qualityOrderVerified=true}},
    professionParameters={Alchemy={MinCraftExtraQtyPct=50,MaxCraftExtraQtyPct=150,
        ResourcefulEffectLow=20,ResourcefulEffectHigh=40}},
    profiles={['Alchemy:10']={statKeys={'resourcefulness','multicraft'},nodes={
        [1]={maxRank=1,learningEffects={{entryID=20,metric='skill',amount=10,confidence=90,
            scope={method='Craft',labelIDs={7}}}}}}}}}
local db={processing={{method='Craft',recipeID=500,inputItemID=101,materials={{id=201}},samples=600,
    labels={601},maximumSkill=999}},professionProfiles=profiles,
    restrictions={noDisenchant={401},researchNoDisenchantObservations={{itemID=999,recipeID=600}}},
    tokenRewards={{costs={{kind='currency',id=999}}}}}
local source=copy(db)
local prune=assert(loadfile('tools/prune_runtime_catalog.lua'))()
local reduced,report=prune(profiles,db)
check(same(db,source),'pruning never rewrites numerical/source/native inputs')
check(reduced.items[101]and reduced.items[201]and reduced.items[202],'compiled input/output and native sibling identities remain')
check(not reduced.items[301]and not reduced.items[401]and not reduced.items[999],'unreferenced item metadata is actually removed')
check(reduced.recipes[500]and not reduced.recipes[600]and not reduced.recipes[601],'future recipe records are not eagerly retained')
check(not reduced.recipes[600]and not reduced.recipes[601],
    'sample counts and label IDs cannot accidentally retain matching recipe IDs')
check(not reduced.items[401]and not reduced.items[999],
    'native no-DE flags, observations, currency IDs and skill counts cannot retain item metadata')
check(reduced.recipeScopes[600]and reduced.recipeScopes[601],'future recipe scope remains compact')
check(#reduced.recipeScopes[600]==7,'scope index has only seven compact model fields')
check(reduced.recipeScopes[600].outputIDs==nil and reduced.recipeScopes[600].name==nil
    and reduced.recipeScopes[600].sourceAbilityIDs==nil,'scope index is not a hidden full recipe catalog')
check(report.itemsBefore==7 and report.itemsAfter==3 and report.recipesAfter==1,'pruning report measures actual catalog removal')
check(reduced.qualityFamilies==profiles.qualityFamilies,'small immutable native rank definitions remain available')
local referenced=prune(profiles,db,{rule={recipeID=600}})
check(referenced.recipes[600]and referenced.items[301]and referenced.items[302],'explicit static rule references retain their actual recipe/output metadata')
local alternate=prune(profiles,db,{rule={recipeSpellID=600,alternateRecipeIDs={601}}})
check(alternate.recipes[600]and alternate.recipes[601],'typed recipe spell and alternate-recipe references retain native models')
local quality=prune(profiles,db,{recipeQualityModels={[600]={rankItemIDs={301,302}}}})
check(quality.recipes[600]and quality.items[301]and quality.items[302],
    'recipe quality-model keys retain the actual recipe and exact output ranks')
local function runtime(data)
    local ll={ItemDB={professionProfiles=data}}
    for _,name in ipairs({'Professions.lua','ProfessionCalculations.lua','ConversionEngine.lua'})do
        assert(loadfile('LootLiquidator/'..name))('LL',ll)
    end
    ll.ProcessingPlayerConditions=function()return{skill=90,preSpecializationSkill=90,simulated=true,
        specializationPoints={[1]=1},stats={multicraft={percent=100},resourcefulness={percent=50}}}end
    ll.GetOutputPrice=function(_,id)return id==101 and 40 or id==302 and 300 or 100 end
    return ll
end
local fixed={method='Craft',profession='Alchemy',recipeID=600,inputCount=1,outputID=301,outputCount=2}
local f={id=101,expansionID=10,classID=7,quality=1}
local old=runtime(profiles)
local baseline=old:ProfessionCraftModel(f,fixed)
local beforeValue=old:ValueProcessingModel(baseline,0,true,f)
check(baseline.materials[1].id==302,'fixture actually requires native labels and threshold model to reach rank two')
near(beforeValue,606,'gold fixture includes exact high-quality units and native input savings')
local now=runtime(reduced)
local loaded=false
C_Item={GetItemInfo=function(id)
    if not loaded then return nil end
    local row=profiles.items[id]
    if row then return row.name,'item:'..id,1,1,1,'','',1000,'',123,row.vendorPrice or 0,7,1,row.bindType,10 end
end}
check(now:GetNativeProfessionItem(401)==nil,'uncached item binding remains unknown rather than invented auctionability')
check(reduced.items[401]==nil,'uncached item misses do not allocate catalog rows')
loaded=true
local bound=now:GetNativeProfessionItem(401)
check(bound.bindType==1 and bound.vendorPrice==7,'actual API binding/vendor facts restore the encountered output only')
local zero=now:GetNativeProfessionItem(301)
check(zero.bindType==0 and zero.vendorPrice==0,'real zero binding and zero vendor price remain valid facts')
check(zero.qualityFamilyID==22 and zero.qualityRank==1,'future output uses the preserved exact native quality family')
local saved={learned=true,profession='Alchemy',outputID=301,outputCount=2,reagentSlots={{alternatives={{itemID=101}}}},
    outputQualityItems={{id=301},{id=302}},qualityOrderVerified=true}
local beforeSaved=copy(saved)
now.db={characters={Player={recipes={[600]=saved}}}}
now:RestoreKnownProfessionRecipeMetadata()
check(same(saved,beforeSaved),'startup hydration preserves learned recipe snapshots')
check(reduced.recipes[600]and not reduced.recipes[601],'startup expands only an actual learned recipe')
check(reduced.recipes[600].sourceAbilityIDs==nil,'restored active recipe contains no discarded native bookkeeping')
local retained=reduced.recipes[600]
now:RestoreKnownProfessionRecipeMetadata()
check(reduced.recipes[600]==retained,'repeated hydration reuses the active recipe without duplicate rows')
local actual=now:ProfessionCraftModel(f,fixed)
check(actual.materials[1].id==baseline.materials[1].id,'future learned craft keeps the same quality item identity')
near(actual.materials[1].expectedQuantity,baseline.materials[1].expectedQuantity,'future learned craft keeps exact output units')
near(actual.expectedInputCount,baseline.expectedInputCount,'future learned craft keeps exact input savings')
near(now:ValueProcessingModel(actual,0,true,f),beforeValue,'future learned craft keeps exact gold after pruning')
check(reduced.recipes[600].supportsMulticraft==false,'native recipe Multicraft exclusion survives scope packing')
local wrong=copy(saved);wrong.profession='Engineering'
check(now:RestoreProfessionRecipeMetadata(601,wrong)==nil,'a mismatching native profession cannot acquire a different scope')
check(not reduced.recipes[601],'an incompatible scope does not expand an unused recipe')
print('PASS: '..checks..' native catalog removal, future learned scope/quality/binding and gold checks')
