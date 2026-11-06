-- Source-exported rules drive quality/pricing, without rewriting yield studies.
local checks=0
local function check(value,message) assert(value,message);checks=checks+1 end
local function near(actual,expected) check(type(actual)=='number' and math.abs(actual-expected)<1e-9,tostring(actual)..' ~= '..tostring(expected)) end
local function copy(value)
    if type(value)~='table' then return value end
    local result={} for k,v in pairs(value) do result[k]=copy(v) end return result
end
GetBuildInfo=function() return 'test','70783' end
GetTime=function() return 100 end
time=function() return 100 end
CreateFrame=function() return {RegisterEvent=function()end,SetScript=function()end} end
local LL={db={}}
for _,name in ipairs({'ProfessionModels.lua','Database.lua','Professions.lua','ConversionEngine.lua'}) do
    assert(loadfile('LootLiquidator/'..name))('LootLiquidator',LL)
end
local exported=assert(loadfile('database/skill-quality-rules.lua'))()
check(#exported.skillQualityRules>0,'research exporter must ship usable rules')
local rule
for _,candidate in ipairs(exported.skillQualityRules) do if candidate.method=='Prospect' then rule=candidate end end
check(rule and rule.recipeID==1231127 and rule.expansionID==11)
local family=assert(rule.outputFamilies[1])
local low,high=family.rankItemIDs[1],family.rankItemIDs[2]
local function field(value) return {value=value,status='measured',confidence=90,samples=100} end
local source={recordID='quality:test',studyID='quality:study',source='controlled family-total fixture',
    sourceKey='itemdb',fixedReference=true,referenceConditions={},method='Prospect',recipeID=rule.recipeID,
    inputItemID=10,inputCount=5,expansionID=11,materials={{id=low,rankIDs={high,low},
        expectedQuantity=field(2),dropChance=field(.5),minQuantity=field(2),maxQuantity=field(6)}}}
LL.ItemDB={schemaVersion=1,version='quality:test',processing={source},mechanicRules={},skillQualityRules=exported.skillQualityRules}
LL:MigrateEvidenceSettings();check(LL:InitializeItemDB())
LL.GetOutputPrice=function(_,id) return id==high and 300 or 100 end
local facts={id=10,expansionID=11,reagentQuality=1}
local option={name='Prospect',recipeID=rule.recipeID,inputCount=5}
local snapshot={recipeID=rule.recipeID,inputItemID=10,inputQualityRank=1,expansionID=11,build='70783',
    observed=100,effectiveSkill=366,craftingQuality=2,highQualitySkillThreshold=365,
    character='Player',maxQuality=2,allocationVerified=true,concentration=false}
local context={simulated=true,profileKind='manual-simulation',effectiveSkill=364,
    character='Player',skillQualityOperation=copy(snapshot),benchmark={}}
LL.ProcessingPlayerConditions=function() return context end
local function resolve()
    LL._processingModelCache=nil
    return assert(LL:ResolveEvidenceModel(facts,option,nil,1))
end
local silver=resolve()
check(silver.skillQualityApplied and silver.materials[1].id==low)
check(silver.materials[1].rankIDs==nil and silver.materials[1].sourceRankIDs[1]==high,
    'unordered source IDs must use the explicit rank mapping')
near(silver.materials[1].expectedQuantity,2)
near(LL:ValueProcessingModel(silver,0,true,facts),40)
check(silver.materials[1].chance==nil and silver.materials[1].minQuantity==nil)
check(silver.confidence<=rule.confidence0to100 and silver.baselineConfidence>=silver.confidence)
context.effectiveSkill=365
local gold=resolve()
check(gold.materials[1].id==high,'quality changes AT the exact measured boundary, without a blanket +1')
near(gold.materials[1].expectedQuantity,2)
near(LL:ValueProcessingModel(gold,0,true,facts),120)
check(LL:ApplySkillQualityModel(facts,option,gold,context)==gold,'quality projection is idempotent')
near(source.materials[1].expectedQuantity.value,2)
check(source.materials[1].rankIDs[1]==high,'raw family evidence stays unchanged')
context.benchmark={outputLevel=150,specializationBonus=20}
local combined=resolve()
check(combined.skillQualityApplied and combined.syntheticBenchmark and combined.materials[1].id==high)
near(combined.materials[1].expectedQuantity,3.6)
near(LL:ValueProcessingModel(combined,0,true,facts),216)
context.benchmark={}
-- A real-character quote uses its exact operation quality, not a synthetic
-- skill value or another character's cached operation.
context.simulated=false;context.profileKind='live';context.effectiveSkill=0
check(resolve().materials[1].id==high)
context.simulated=true;context.profileKind='manual-simulation';context.effectiveSkill=365
for _,damage in ipairs({
    {build='70782'},{recipeID=1},{inputItemID=11},{inputQualityRank=2},{expansionID=10},
    {allocationVerified=false},{concentration=true},{highQualitySkillThreshold=0},
    {highQualitySkillThreshold=0/0},{observed=101},{character='Alt'},{maxQuality=3},
}) do
    context.skillQualityOperation=copy(snapshot)
    for key,value in pairs(damage) do context.skillQualityOperation[key]=value end
    check(not resolve().skillQualityApplied,'damaged/mismatched operation must not select a rank')
end
context.skillQualityOperation=copy(snapshot)
local rules=LL.ItemDB.skillQualityRules
LL.ItemDB.skillQualityRules={copy(rule)}
LL.ItemDB.skillQualityRules[1].inputItemIDs={11}
check(not resolve().skillQualityApplied,'item-restricted research cannot apply to another input')
LL.ItemDB.skillQualityRules=rules
time=function() return 604901 end
check(not resolve().skillQualityApplied,'expired operation snapshots cannot select a rank')
time=function() return 100 end
local raw={inputCount=5,confidence=90,materials={
    {id=low,rankIDs={high,low},expectedQuantity=nil,conditionalExpectedQuantity=.2,conditionalRequirement='locked'},
    {id=999,expectedQuantity=nil},
}}
check(LL:ApplySkillQualityModel(facts,option,raw,context)==raw,'unknown and conditional outputs remain unavailable')
local exact={inputCount=5,confidence=90,materials={{id=low,expectedQuantity=2}}}
check(LL:ApplySkillQualityModel(facts,option,exact,context)==exact,
    'a rank-specific study cannot stand in for a complete family-total study')
local overlap={inputCount=5,confidence=90,materials={{id=low,rankIDs={low,high},expectedQuantity=2},{id=high,expectedQuantity=1}}}
check(LL:ApplySkillQualityModel(facts,option,overlap,context)==overlap,'overlapping cohorts cannot be summed')
local unknownFamily={inputCount=5,confidence=90,materials={{id=1,rankIDs={1,2},expectedQuantity=2}}}
check(LL:ApplySkillQualityModel(facts,option,unknownFamily,context)==unknownFamily,'unverified mappings stay unknown')
local glass
for _,candidate in ipairs(rule.outputFamilies) do if candidate.name=='Crystalline Glass' then glass=candidate end end
check(glass and glass.rankItemIDs[1]==242787 and glass.rankItemIDs[2]==242786,'primary refine recipe resolves reverse-numbered Glass ranks')
local glassRaw={inputCount=5,confidence=90,materials={{id=242786,rankIDs={242786,242787},expectedQuantity=2}}}
check(LL:ApplySkillQualityModel(facts,option,glassRaw,context).materials[1].id==242786)
context.effectiveSkill=364
check(LL:ApplySkillQualityModel(facts,option,glassRaw,context).materials[1].id==242787)
local zero={inputCount=5,confidence=90,materials={{id=low,rankIDs={low,high},expectedQuantity=0}}}
near(LL:ApplySkillQualityModel(facts,option,zero,context).materials[1].expectedQuantity,0)
local mixed={inputCount=5,confidence=90,materials={
    {id=low,rankIDs={low,high},expectedQuantity=2,confidence=90},
    {id=999,expectedQuantity=100,confidence=90},
}}
local mixedProjection=LL:ApplySkillQualityModel(facts,option,mixed,context)
LL:ValueProcessingModel(mixedProjection,0,true,facts)
check(mixedProjection.valueConfidence<=rule.confidence0to100,
    'high-value unaffected outputs cannot lift the projected option above its rule confidence cap')
print('PASS: '..checks..' compiled skill-quality boundary, valuation, provenance and assumption-isolation assertions')
