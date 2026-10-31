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
        skillFactors={{skill=0,factor=1},{skill=100,factor=2}},status='synthetic',evidenceStatus='VERIFIED_NUMERIC',applyPolicy='EXECUTE',numericTransformValidated=true,independentReview='APPROVED',confidence0to100=94,sourceClaimIDs={'synthetic-a','synthetic-b'}}
end
local patch={ruleID='synthetic-patch',method='Prospect',recipeID=444,inputItemID=10,outputItemID=20,
    expansionID=11,inputQualityRank=2,fromBuild='100',toBuild='200',basis='baseline',expectedMultiplier=1.5,evidenceStatus='VERIFIED_NUMERIC',applyPolicy='EXECUTE',numericTransformValidated=true,independentReview='APPROVED',confidence0to100=94,sourceClaimIDs={'synthetic-a','synthetic-b'}}
LL.ItemDB={schemaVersion=1,version='test',processing={},professionRules={rule('100'),rule('200')},
    personalPatchRules={patch},modelRevision='synthetic/1',mechanicRules={}}
check(LL:InitializeItemDB());LL:MigrateEvidenceSettings()
local target=clone(profile);target.effectiveSkill=100
local raw={sourceKey='personal',patchBuild='100',observationContext=clone(profile),effectiveSamples=50,inputCount=5,
    materials={{id=20,expectedQuantity=2,chance=.5,minQuantity=2,maxQuantity=6,quantityCounts={['0']=25,['4']=25}}}}
local buffed=clone(profile);buffed.buffs={12345}
check(LL:ProjectPersonalEstimate(f,option,raw,buffed,'100')==nil,
    'different unmodeled buffs cannot take the identical-profile fast path')
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
for _,key in ipairs({'legacy'}) do
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
LL.ItemDB.processing={record('itemdb',3),record('legacy',9)} -- B2: no frozen TSM source
check(LL:InitializeItemDB());LL:SetEvidenceSource('legacy',true,100)
local calls=0
LL.ApplyVerifiedMechanics=function(_,_,_,model) calls=calls+1;return model end
LL.ProcessingPlayerConditions=function() return target end
local model=assert(LL:ComputeEvidenceModel(f,option,nil,1,target))
-- A1: legacy blends in at its own source weight (here set to 100) instead of only filling gaps.
near(model.materials[1].expectedQuantity,(6+9)/2)
near(model.sources.legacy,1/2)
LL:SetEvidenceSource('legacy',true,10);LL._processingModelCache=nil
model=assert(LL:ComputeEvidenceModel(f,option,nil,1,target))
near(model.materials[1].expectedQuantity,(6+9*.1)/1.1) -- default weight keeps legacy weak
LL:SetEvidenceSource('legacy',true,100)
near(LL.ItemDB.processing[2].materials[1].expectedQuantity.value,9)
check(calls==0,'fixed sources never enter mechanics adapter')
local low=clone(target);low.effectiveSkill=0
model=assert(LL:ComputeEvidenceModel(f,option,nil,1,low))
-- sourceModel uses the resolved profile; change the profile reader as a real
-- user setting change would, then recompute.
LL.ProcessingPlayerConditions=function() return low end
model=assert(LL:ComputeEvidenceModel(f,option,nil,1,low))
near(model.materials[1].expectedQuantity,(3+9)/2) -- A1: legacy blends at weight 100
near(LL.ItemDB.processing[2].materials[1].expectedQuantity.value,9)
-- B2: old frozen-TSM switches are dropped quietly from saved data.
LL.db={source_tsm_enabled=false,source_tsm_weight=17,source_itemtsm_enabled=true,source_itemtsm_weight=30,frozenTSMMigrated=true}
LL:MigrateEvidenceSettings()
for _,k in ipairs({'source_tsm_enabled','source_tsm_weight','source_itemtsm_enabled','source_itemtsm_weight','frozenTSMMigrated'}) do
    check(LL.db[k]==nil,'retired '..k)
end
check(LL:SetEvidenceSource('itemtsm',true,0)==false,'itemtsm is no longer a source')
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
-- Admission and execution must reject structurally valid unreviewed rules.
local good=rule('200');local rejected=clone(good);rejected.independentReview=nil
check(not LL:ValidateProfessionRules({professionRules={rejected}}),'missing approval rejected')
rejected=clone(good);rejected.sourceClaimIDs={'same','same'}
check(not LL:ValidateProfessionRules({professionRules={rejected}}),'duplicate evidence rejected')
rejected=clone(good);rejected.applyPolicy='PREVIEW_ONLY'
check(not LL:ValidateProfessionRules({professionRules={rejected}}),'preview excluded from executable collection')
LL.ItemDB.professionRules={rejected};near(LL:ApplyProfessionModel(f,option,base,target).materials[1].expectedQuantity,3)
local unreviewedPatch=clone(patch);unreviewedPatch.evidenceStatus=nil
check(not LL:ValidateProfessionRules({personalPatchRules={unreviewedPatch}}),'patch gate enforced')
LL.ItemDB.professionRules={good};LL.ItemDB.personalPatchRules={unreviewedPatch}
check(LL:ProjectPersonalEstimate(f,option,raw,target,'200')==nil,'unreviewed patch cannot execute directly')
local multiple=clone(base);multiple.materials[2]={id=21,expectedQuantity=1}
local partial=LL:ApplyProfessionModel(f,option,multiple,target)
check(partial.projectionIncomplete and not partial.mechanicsApplied,'partial adjustment is not whole-model success')
near(partial.materials[1].expectedQuantity,3);near(multiple.materials[1].expectedQuantity,3)
print('PASS: '..count..' profession/personal projection assertions; synthetic coefficients only')
