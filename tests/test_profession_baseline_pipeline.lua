-- Builder immutability and actual resolver/quote wiring use the shipped data.
local checks=0
local function check(v,label) assert(v,label);checks=checks+1 end
local function near(v,w,label) check(type(v)=='number' and math.abs(v-w)<1e-8,label..': '..tostring(v)..' ~= '..tostring(w)) end
local function copy(v)
    if type(v)~='table' then return v end
    local r={} for k,x in pairs(v) do r[k]=copy(x) end return r
end
local function same(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~='table' then return a==b end
    for k,v in pairs(a) do if not same(v,b[k]) then return false end end
    for k in pairs(b) do if a[k]==nil then return false end end
    return true
end
GetBuildInfo=function() return '12.1.5','70961' end
GetTime=function() return 100 end
time=function() return 100 end
CreateFrame=function() return {RegisterEvent=function()end,SetScript=function()end} end
GetItemInfo=function(id) return 'Item '..id end
GetItemCount=function() return 100000 end
local LL={db={characters={Player={professions={}}},rateProfile=3,rateProfileCharacter='Player',
    source_itemdb_enabled=true,source_legacy_enabled=true,source_reference_enabled=true,
    source_personal_enabled=false,source_imported_enabled=false}}
for _,file in ipairs({'ItemDBRuntime.lua','ProfessionCatalog.lua','Professions.lua','ProfessionModels.lua',
    'ProfessionCalculations.lua','Database.lua','ConversionEngine.lua','Observations.lua','Badges.lua'}) do
    assert(loadfile('LootLiquidator/'..file))('LL',LL)
end
LL.CharacterKey=function() return 'Player' end
LL.GetResearchProfessionSnapshot=function() return 100,'none' end
LL.GetCachedOperationInfo=function() end
LL.GetOutputPrice=function(_,id) return id==241302 and 300 or 100 end
LL.EligibleDisenchant=function() return false end
LL.CanUseConversion=function() return false,'Informational test recipe','Current character' end
LL.Invalidate=function(self) self._processingContextCache=nil;self._processingModelCache=nil end
LL:MigrateEvidenceSettings()
local originalDB=LL.ItemDB
local sourceSnapshot=copy(originalDB.processing)
local build=assert(loadfile('tools/profession_baselines.lua'))()
local derived=build(originalDB,LL)
check(same(originalDB.processing,sourceSnapshot),'building preserves every original source field and count')
local byID={} for _,r in ipairs(originalDB.processing) do byID[r.recordID]=r end
local builtCount=0
for id,baseline in pairs(derived) do
    builtCount=builtCount+1
    local raw=assert(byID[id])
    check(#baseline.materials==#raw.materials,'derived baseline preserves material count')
    for index,m in ipairs(baseline.materials) do
        check(m.id==raw.materials[index].id,'derived material order and identity match the source')
        check(m.samples==nil and m.observedSamples==nil and m.chance==nil,'derived means create no observations')
    end
    if not raw.baselineProfile then
        check(baseline.sourceProfileAssumed and baseline.baselineConfidence<=5,'unknown source profile keeps its declared prior cap')
    end
end
check(builtCount>0,'real compiled processing records produce derived baselines')

local recipe=1230867
local op={name='Craft',recipeID=recipe,inputCount=5,profession='Alchemy'}
local f={id=900001,expansionID=11,classID=7,quality=2,count=20}
local sourceProfile={skill=100,preSpecializationSkill=100,specializationPoints={},
    stats={multicraft={percent=25},resourcefulness={percent=25},craftingSpeed={percent=25}}}
local p=LL:ProfessionProfileParameters('Alchemy',11,sourceProfile,op,f)
local function field(v) return {value=v,status='measured',confidence=80,samples=100} end
local function material(id,value)
    return {id=id,expectedQuantity=field(value),dropChance={status='unknown',confidence=0},
        minQuantity={status='unknown',confidence=0},maxQuantity={status='unknown',confidence=0}}
end
local known={recordID='test:known-profile',method='Craft',profession='Alchemy',expansionID=11,
    inputItemID=f.id,inputCount=5,recipeID=recipe,sourceKey='itemdb',source='Synthetic mathematical fixture',
    studyID='test:known',samples=100,referenceContextID='test:canonical',referenceConditions={},
    baselineProfile=sourceProfile,expectedInputCount=5*p.inputFactor,duration=10,
    materials={material(241303,2*p.outputFactor),material(241302,p.outputFactor)}}
local unknown=copy(known);unknown.recordID='test:unknown-profile';unknown.baselineProfile=nil
local small={processing={known,unknown},professionProfiles=originalDB.professionProfiles}
local before=copy(small.processing)
local normalized=build(small,LL)
check(same(small.processing,before),'known-profile normalization preserves all raw source evidence')
local k=assert(normalized[known.recordID]);local u=assert(normalized[unknown.recordID])
near(k.materials[1].expectedQuantity,2,'Multicraft inverse restores the first baseline mean')
near(k.materials[2].expectedQuantity,1,'Multicraft inverse restores the second baseline mean')
near(k.expectedInputCount,5,'Resourcefulness inverse restores nominal input consumption')
near(k.duration,10,'normalization retains raw duration metadata without forecasting time')
check(k.baselineConfidence<=p.confidence,'source normalization carries its transformation uncertainty')
check(u.sourceProfileAssumed and u.baselineConfidence<=5,'unprofiled source uses a separate low-confidence prior')
near(u.materials[1].expectedQuantity,unknown.materials[1].expectedQuantity.value,'unknown source observations are not relabeled as measured zero-skill data')
k.sourceProfile.skill=999
check(known.baselineProfile.skill==100,'derived profile does not alias the original observed profile')

local function set(profession,stats)
    LL.db.characters.Player.professions[profession]=true
    check(LL:SetManualProfessionProfile('Player',profession,11,{enabled=true,skill=600,specialization='none',stats=stats or {},buffs={}}),
        'manual target profile saves for '..profession)
end
local crafting={{'Alchemy',1230867},{'Blacksmithing',1229598},{'Enchanting',1236098},
    {'Engineering',1229755},{'Inscription',1230016},{'Jewelcrafting',1230437},
    {'Leatherworking',1237486},{'Tailoring',1227926},{'Cooking',1226166}}
for index,row in ipairs(crafting) do
    local profession,spell=row[1],row[2]
    local native=assert(originalDB.professionProfiles.recipes[spell])
    local input={id=990000+index,expansionID=11,classID=7,quality=2,count=100}
    local candidate={method='Craft',profession=profession,recipeID=spell,inputCount=1,
        outputID=native.outputIDs[1],outputCount=native.outputCount or 1,confidence='verified'}
    LL.db.recipeCandidates={[input.id]={[spell]=candidate}}
    set(profession,{multicraft={percent=25},resourcefulness={percent=25}})
    local quotes=LL:ConversionOptions(input)
    local quote for _,q in ipairs(quotes) do if q.recipeID==spell then quote=q end end
    check(quote and quote.yieldModel and quote.yieldModel.generalProfessionApplied,profession..' native discovery reaches the quote calculation')
    check(not quote.available,'an informational fixture does not authorize an invented action')
    check(type(quote.value)=='number',profession..' quote is valued after projection')
    LL.db.source_itemdb_enabled=false;LL:Invalidate()
    local withoutResearch for _,q in ipairs(LL:ConversionOptions(input)) do if q.recipeID==spell then withoutResearch=q end end
    check(withoutResearch and withoutResearch.yieldModel,'known native fixed recipes remain independent of researched-yield source toggles')
    LL.db.source_itemdb_enabled=true
end
LL.db.recipeCandidates=nil
-- Different empirical profiles normalize independently before weighted fusion.
local neutral=copy(known);neutral.recordID='test:neutral';neutral.studyID='test:neutral'
neutral.baselineProfile={skill=100,preSpecializationSkill=100,stats={},specializationPoints={}}
neutral.materials={material(999998,2)}
local boosted=copy(neutral);boosted.recordID='test:boosted';boosted.studyID='test:boosted';boosted.sourceKey='legacy'
boosted.baselineProfile={skill=100,preSpecializationSkill=100,stats={multicraft={percent=25}},specializationPoints={}}
boosted.materials[1].expectedQuantity.value=2*p.outputFactor
local fixtureDB={schemaVersion=1,processing={neutral,boosted},mechanicRules={},professionProfiles=originalDB.professionProfiles,
    inputs={[f.id]={method='Craft',batch=5,expansion=11}},modeledProfessionBaselines={}}
fixtureDB.modeledProfessionBaselines=build(fixtureDB,LL)
LL.ItemDB=fixtureDB
check(LL:InitializeItemDB(),LL.itemDBError)
set('Alchemy',{multicraft={percent=50}})
local target=LL:ProcessingPlayerConditions(f,'Craft',recipe,nil,'Alchemy')
local targetParams=LL:ProfessionProfileParameters('Alchemy',11,target,op,f)
local fused=assert(LL:ResolveEvidenceModel(f,op,nil,1))
near(fused.materials[1].expectedQuantity,2*targetParams.outputFactor,'mixed sources are projected independently before fusion')
check(fused.sources.itemdb>0 and fused.sources.legacy>0,'independently projected sources both retain their identities')
LL:SetEvidenceSource('itemdb',true,10);LL:SetEvidenceSource('legacy',true,90)
local reweighted=assert(LL:ResolveEvidenceModel(f,op,nil,1))
check(reweighted.sources.legacy>reweighted.sources.itemdb,'user source weights still control the projected evidence mix')
near(reweighted.materials[1].expectedQuantity,2*targetParams.outputFactor,'source reweighting does not apply the profile curve twice')
LL:SetEvidenceSource('itemdb',true,100);LL:SetEvidenceSource('legacy',true,10)
LL.db.source_legacy_enabled=false;LL:Invalidate()
local one=assert(LL:ResolveEvidenceModel(f,op,nil,1))
near(one.materials[1].expectedQuantity,2*targetParams.outputFactor,'source toggle does not change canonical source units')
LL.db.source_itemdb_enabled=false;LL:Invalidate()
check(LL:ResolveEvidenceModel(f,op,nil,1)==nil,'all contributing research source toggles are respected')
-- A personal observation retains its own weaker confidence and sample lineage.
local personal={studyID='test:personal',inputCount=5,effectiveSamples=80,samples=80,patchBuild=70961,
    confidence=8,ruleConfidence=6,observationContext=copy(boosted.baselineProfile),
    materials={{id=999998,expectedQuantity=2*p.outputFactor,confidence=8}}}
personal.observationContext.character='Player'
local personalBefore=copy(personal)
LL.db.source_personal_enabled=true;LL:Invalidate()
local personalOnly=assert(LL:ResolveEvidenceModel(f,op,personal,2))
near(personalOnly.materials[1].expectedQuantity,2*targetParams.outputFactor,'personal source observations use their own inverse and target projection')
check(personalOnly.sources.personal==1 and not personalOnly.sources.itemdb and not personalOnly.sources.legacy,
    'personal-only mode excludes research sources after profile projection')
check(personalOnly.materials[1].confidence<=6,'personal source confidence is not replaced by a stronger model confidence')
check(same(personal,personalBefore),'projecting personal evidence preserves its original means, counts and captured profile')
-- Independent studies of one source need a weighted source mean, not the last
-- study value, when the fused material family is routed to another quality.
local firstStudy=copy(known);firstStudy.recordID='test:repeated:a';firstStudy.studyID='test:repeated:a'
firstStudy.sourceKey='itemdb';firstStudy.materials={material(241303,2)}
firstStudy.baselineProfile={skill=100,preSpecializationSkill=100,stats={},specializationPoints={}}
local secondStudy=copy(firstStudy);secondStudy.recordID='test:repeated:b';secondStudy.studyID='test:repeated:b'
secondStudy.materials={material(241303,4)}
local repeatedDB={schemaVersion=1,processing={firstStudy,secondStudy},mechanicRules={},professionProfiles=originalDB.professionProfiles,
    inputs={[f.id]={method='Craft',batch=5,expansion=11}}}
repeatedDB.modeledProfessionBaselines=build(repeatedDB,LL)
LL.ItemDB=repeatedDB;check(LL:InitializeItemDB(),LL.itemDBError)
LL.db.source_itemdb_enabled=true;LL.db.source_personal_enabled=false;LL:Invalidate();set('Alchemy',{})
local repeated=assert(LL:ResolveEvidenceModel(f,op,nil,1))
local rankOne,rankTwo=0,0
for _,m in ipairs(repeated.materials) do
    if m.id==241303 then rankOne=rankOne+(m.expectedQuantity or 0) end
    if m.id==241302 then rankTwo=rankTwo+(m.expectedQuantity or 0) end
end
near(rankOne,0,'every compatible study contribution follows the selected native quality')
near(rankTwo,3,'same-source studies preserve their weighted three-unit mean after quality projection')
check(same(originalDB.processing,sourceSnapshot),'full pipeline leaves every shipped observation field/count unchanged')
print('PROFESSION BASELINE PIPELINE: '..checks..' checks passed')
