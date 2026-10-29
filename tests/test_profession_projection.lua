-- Synthetic coefficients exercise arithmetic, not claims about WoW mechanics.
local count=0
local function check(v,msg) assert(v,msg);count=count+1 end
local function near(a,b) check(type(a)=='number' and math.abs(a-b)<1e-9,tostring(a)..' ~= '..tostring(b)) end
local function clone(v) if type(v)~='table' then return v end local n={} for k,x in pairs(v) do n[k]=clone(x) end return n end
GetBuildInfo=function() return 'test','200','',120105 end
local LL={db={}}
for _,name in ipairs({'ProfessionModels.lua','Database.lua','ConversionEngine.lua'}) do
    assert(loadfile('LootLiquidator/'..name))('LootLiquidator',LL)
end
local f={id=10,reagentQuality=2,expansionID=11}
local option={name='Prospect',recipeID=444,inputCount=5,character='Tester'}
local profile={effectiveSkill=0,specialization='none',character='Tester',inputQuality=2}
local function rule(build)
    return {ruleID='synthetic-skill-'..build,method='Prospect',recipeID=444,inputItemID=10,outputItemID=20,
        expansionID=11,inputQualityRank=2,build=build,referenceProfile=clone(profile),
        skillFactors={{skill=0,factor=1},{skill=100,factor=2}},status='provisional'}
end
local patch={ruleID='synthetic-patch',method='Prospect',recipeID=444,inputItemID=10,outputItemID=20,
    expansionID=11,inputQualityRank=2,fromBuild='100',toBuild='200',basis='baseline',expectedMultiplier=1.5}
LL.ItemDB={schemaVersion=1,version='test',processing={},professionRules={rule('100'),rule('200')},
    personalPatchRules={patch},modelRevision='synthetic/1',mechanicRules={}}
check(LL:InitializeItemDB());LL:MigrateEvidenceSettings()
local target=clone(profile);target.effectiveSkill=100
local raw={sourceKey='personal',patchBuild='100',observationContext=clone(profile),effectiveSamples=50,inputCount=5,
    materials={{id=20,expectedQuantity=2,chance=.5,minQuantity=2,maxQuantity=6,quantityCounts={['0']=25,['4']=25}}}}
local result=assert(LL:ProjectPersonalEstimate(f,option,raw,profile,'200'))
near(result.materials[1].expectedQuantity,3);near(raw.materials[1].expectedQuantity,2)
near(assert(LL:ProjectPersonalEstimate(f,option,result,profile,'200')).materials[1].expectedQuantity,3)
near(assert(LL:ProjectPersonalEstimate(f,option,raw,target,'200')).materials[1].expectedQuantity,6)
local skilled=clone(raw);skilled.observationContext=clone(target);skilled.materials[1].expectedQuantity=4
near(assert(LL:ProjectPersonalEstimate(f,option,skilled,profile,'200')).materials[1].expectedQuantity,3)
check(result.materials[1].chance==nil and result.materials[1].quantityCounts==nil)
check(raw.materials[1].chance==.5 and raw.materials[1].quantityCounts['0']==25)
LL.ItemDB.personalPatchRules={}
local missing,reason=LL:ProjectPersonalEstimate(f,option,raw,target,'200')
check(missing==nil and reason:find('unknown'))
LL.ItemDB.personalPatchRules={patch,clone(patch)}
check(LL:ProjectPersonalEstimate(f,option,raw,target,'200')==nil,'ambiguous bridge')
LL.ItemDB.personalPatchRules={patch};patch.toBuild='100'
check(LL:ProjectPersonalEstimate(f,option,raw,target,'200')==nil,'cycle')
patch.toBuild='200';patch.expectedMultiplier=0/0
check(LL:ProjectPersonalEstimate(f,option,raw,target,'200')==nil,'invalid coefficient')
patch.expectedMultiplier=1.5
local base={sourceKey='itemdb',patchBuild='200',baselineProfile=clone(profile),materials={{id=20,expectedQuantity=3}}}
near(LL:ApplyProfessionModel(f,option,base,target).materials[1].expectedQuantity,6)
near(base.materials[1].expectedQuantity,3)
local projected=LL:ApplyProfessionModel(f,option,base,target)
check(LL:ApplyProfessionModel(f,option,projected,target)==projected)
for _,key in ipairs({'itemtsm','tsm','legacy'}) do
    local fixed=clone(base);fixed.sourceKey=key
    check(LL:ApplyProfessionModel(f,option,fixed,target)==fixed)
    check(LL:ApplyVerifiedMechanics(f,option,fixed)==fixed)
end
local field=function(v) return {value=v,status='measured',confidence=90} end
local function record(key,e)
    return {recordID=key,sourceKey=key,method='Prospect',recipeID=444,inputItemID=10,inputQualityRank=2,
        expansionID=11,inputCount=5,studyID=key,source=key,samples=50,patchBuild='200',
        fixedReference=key~='itemdb',referenceConditions={},baselineProfile=key=='itemdb' and clone(profile) or nil,
        materials={{id=20,expectedQuantity=field(e),dropChance=field(nil),minQuantity=field(nil),maxQuantity=field(nil)}}}
end
LL.ItemDB.processing={record('itemdb',3),record('itemtsm',4),record('legacy',9)}
check(LL:InitializeItemDB());LL:SetEvidenceSource('legacy',true,100)
local calls=0
LL.ApplyVerifiedMechanics=function(_,_,_,model) calls=calls+1;return model end
LL.ProcessingPlayerConditions=function() return target end
local model=assert(LL:ComputeEvidenceModel(f,option,nil,1,target))
near(model.materials[1].expectedQuantity,(6+4*.3)/1.3)
near(model.materials[1].sourceContributions.itemtsm,.3/1.3)
check(model.sources.legacy==nil,'legacy only fills missing fields')
near(LL.ItemDB.processing[2].materials[1].expectedQuantity.value,4)
check(calls==0,'fixed sources never enter mechanics adapter')
local low=clone(target);low.effectiveSkill=0
model=assert(LL:ComputeEvidenceModel(f,option,nil,1,low))
-- sourceModel uses the resolved profile; change the profile reader as a real
-- user setting change would, then recompute.
LL.ProcessingPlayerConditions=function() return low end
model=assert(LL:ComputeEvidenceModel(f,option,nil,1,low))
near(model.materials[1].expectedQuantity,(3+4*.3)/1.3)
near(LL.ItemDB.processing[2].materials[1].expectedQuantity.value,4)
LL.db={source_tsm_enabled=false,source_tsm_weight=17};LL:MigrateEvidenceSettings()
check(LL.db.source_itemtsm_enabled==false);near(LL.db.source_itemtsm_weight,17)
LL:SetEvidenceSource('itemtsm',true,0);LL:MigrateEvidenceSettings()
near(LL.db.source_itemtsm_weight,0)
-- No shipped coefficient means a truthful stable unadjusted baseline.
LL.ItemDB.professionRules={}
local stable=LL:ApplyProfessionModel(f,option,base,target)
near(stable.materials[1].expectedQuantity,3);check(not stable.mechanicsApplied)
-- Exercise the real SavedVariables -> cast baseline -> patch projection path.
CreateFrame=function() return {RegisterEvent=function() end,SetScript=function() end} end
local savedProfile={effectiveSkill=0,baseSkill=0,specialization='none',character='Tester',
    skillLineID=1,equipment={},fieldStatus={equipment='measured'},inputIdentity={{itemID=10,quantity=5,qualityRank=2}}}
local P={db={craftResearch={records={{studyID='old-study',contextID='old-context',recipeID=444,method='Prospect',
    build='100',operationID='sample',outputCoverage='complete',inputs={{itemID=10,quantity=5}},
    outputs={{itemID=20,quantity=2}}}},contexts={['old-context']=clone(savedProfile)},
    studies={['old-study']={build='100'}},sequence=0,droppedRecords=0}},
    ItemDB={modelRevision='integration/1',professionRules={rule('100'),rule('200')},personalPatchRules={clone(patch)}}}
for _,r in ipairs(P.ItemDB.professionRules) do r.referenceProfile=clone(savedProfile) end
P.CharacterKey=function() return 'Tester' end
P.CaptureCraftContext=function() return clone(savedProfile) end
assert(loadfile('LootLiquidator/ProfessionModels.lua'))('LootLiquidator',P)
assert(loadfile('LootLiquidator/CraftRecording.lua'))('LootLiquidator',P)
local migrated=assert(P:GetRecordedProcessingEstimate(f,'Prospect',5,444))
near(migrated.materials[1].expectedQuantity,3)
near(P.db.craftResearch.records[1].outputs[1].quantity,2)
near(assert(P:GetRecordedProcessingEstimate(f,'Prospect',5,444)).materials[1].expectedQuantity,3)
P.ItemDB.personalPatchRules={}
check(P:GetRecordedProcessingEstimate(f,'Prospect',5,444)==nil)
check(P.personalProjectionStatus:find('unknown'))
print('PASS: '..count..' profession/personal projection assertions; synthetic coefficients only')
