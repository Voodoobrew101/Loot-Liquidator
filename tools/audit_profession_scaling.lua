-- Focused scaling audit. Synthetic mechanics below are tests, never WoW rates.
-- Exit 1 means the audit reproduced an unresolved correctness defect.
local passed,failed=0,0
local function check(name,ok,detail)
    if ok then passed=passed+1;print('PASS: '..name)
    else failed=failed+1;print('FAIL: '..name..(detail and ' — '..detail or '')) end
end
local function load(namespace,file) assert(loadfile('LootLiquidator/'..file))('LootLiquidator',namespace) end
local runtime={};load(runtime,'ItemDBRuntime.lua')
local research=assert(loadfile('database/research/itemdb.lua'))()
check('Runtime database ships no unverified scaling coefficients',#runtime.ItemDB.mechanicRules==0)
check('Latest research database ships no approved coefficients',#research.mechanicRules==0)
check('Copied research schema is distinguished from the runtime schema',research.schemaVersion~=runtime.ItemDB.schemaVersion)
local A={ItemDB=runtime.ItemDB,db={}}
load(A,'Database.lua');load(A,'ConversionEngine.lua');A:MigrateEvidenceSettings()
local sample
for _,r in ipairs(A.ItemDB.processing) do
    if r.sourceKey=='itemdb' and r.inputItemID and r.method~='Smelt' then
        for _,m in ipairs(r.materials) do if m.expectedQuantity.value~=nil then sample=r;break end end
        if sample then break end
    end
end
assert(sample,'Missing baseline record for skill comparison')
local selectedSkill=20
A.ProcessingPlayerConditions=function() return {skill=selectedSkill,effectiveSkill=selectedSkill,inputQuality=sample.inputQualityRank,character='Audit'} end
local input={id=sample.inputItemID,expansionID=sample.expansionID,reagentQuality=sample.inputQualityRank,classID=7,quality=1}
local operation={name=sample.method,inputCount=sample.inputCount,recipeID=sample.recipeID,character='Audit'}
local low=assert(A:ResolveEvidenceModel(input,operation,nil,1))
selectedSkill=100
local high=assert(A:ResolveEvidenceModel(input,operation,nil,1))
local unchanged=#low.materials==#high.materials and not high.mechanicsApplied
for i,m in ipairs(low.materials) do
    unchanged=unchanged and m.id==high.materials[i].id and m.expectedQuantity==high.materials[i].expectedQuantity
end
check('Actual database keeps skill 20 and skill 100 yields unadjusted without coefficients',unchanged)

GetBuildInfo=function() return 'test','123456','',120105 end
local LL={GameData={verifiedMechanicsRules={}}}
load(LL,'ConversionEngine.lua')
LL.CharacterKey=function() return 'Tester - Realm' end
LL.ProcessingPlayerConditions=function() return {skill=100} end
local f={id=10,reagentQuality=2,quality=3,expansionID=11}
local option={name='Prospect',recipeID=444,character='Tester - Realm'}
local function base()
    return {inputCount=5,patchBuild='123450',referenceContextID='cohort',materials={
        {id=20,expectedQuantity=2,chance=.5,probabilityVerified=true,minQuantity=1,maxQuantity=4}}}
end
local function rule(target,parameters)
    return {ruleID='synthetic-audit-only',evidenceStatus='VERIFIED_NUMERIC',applyPolicy='EXECUTE',
        applies='VERIFIED_APPLIES',confidence0to100=95,sourceClaimIDs={'synthetic-audit-only'},
        method=option.name,recipeID=444,inputItemID=10,inputQualityRank=2,outputItemID=20,
        expansionID=11,sourceBuild='123450',targetBuild='123456',sourceReferenceContextID='cohort',
        targetConditions={skill=100},effectTarget=target,formulaID='MULTIPLY',parameters=parameters}
end
local r=rule('OUTPUT_UNCONDITIONAL_EXPECTATION',{multiplier=1.5})
LL.GameData.verifiedMechanicsRules={r}
local original=base();local transformed=LL:ApplyVerifiedMechanics(f,option,original)
check('A scoped synthetic expectation coefficient applies',transformed.materials[1].expectedQuantity==3)
check('Original reference remains immutable',original.materials[1].expectedQuantity==2)
check('Applying an already transformed model does not double-scale',LL:ApplyVerifiedMechanics(f,option,transformed).materials[1].expectedQuantity==3)
r.parameters={}
check('Missing coefficients preserve the reference',LL:ApplyVerifiedMechanics(f,option,base()).materials[1].expectedQuantity==2)
r.parameters={multiplier=1.5};r.confidence0to100=101
local invalid=LL:ApplyVerifiedMechanics(f,option,base())
check('Confidence outside 0–100 is rejected',invalid.materials[1].expectedQuantity==2,
    'confidence=101 still changes EV from 2 to '..invalid.materials[1].expectedQuantity)
r.confidence0to100=95;r.effectTarget='OUTPUT_OCCURRENCE';r.parameters={multiplier=0}
local inconsistent=LL:ApplyVerifiedMechanics(f,option,base()).materials[1]
check('Transformed distributions keep zero occurrence consistent with EV',
    inconsistent.chance~=0 or inconsistent.expectedQuantity==nil or inconsistent.expectedQuantity==0,
    'dropChance='..tostring(inconsistent.chance)..', expectedQuantity='..tostring(inconsistent.expectedQuantity))
-- Equipment rarity is not a reagent quality rank. A gear-scoped rule has no rank.
r=rule('OUTPUT_UNCONDITIONAL_EXPECTATION',{multiplier=1.5})
r.method='Disenchant';r.recipeID=13262;r.inputQualityRank=nil;r.inputRarity=3;r.inputClassID=4
LL.GameData.verifiedMechanicsRules={r}
local gear={id=10,quality=3,classID=4,expansionID=11}
local de=LL:ApplyVerifiedMechanics(gear,{name='Disenchant',recipeID=13262,character='Tester - Realm'},base())
check('Equipment rules can express non-reagent quality applicability',de.materials[1].expectedQuantity==3,
    'mandatory inputQualityRank blocks all ordinary equipment with no reagent rank')
-- Reproduce API fallback with a changed skill/gear bonus and unavailable traits.
CreateFrame=function() return {RegisterEvent=function() end,SetScript=function() end} end
UnitName=function() return 'Tester' end
GetRealmName=function() return 'Realm' end
GetTime=function() return 100 end
time=function() return 10000000 end
C_TradeSkillUI={GetProfessionInfoBySkillLineID=function() return {skillLevel=70,skillModifier=0} end}
C_ProfSpecs=nil;C_Traits=nil
local P={db={characters={['Tester - Realm']={professions={Jewelcrafting={}},
    details={[11]={name='Midnight Jewelcrafting',parentName='Jewelcrafting',skill=70}},
    researchProfiles={['Jewelcrafting:11']={skill=60,bonusSkill=10,specialization='999=3',lineID=11,observed=1}}}}},
    DisenchantTables={[11]={name='Midnight'}}}
load(P,'Professions.lua');load(P,'ConversionEngine.lua')
local context=P:ProcessingPlayerConditions(f,'Prospect',444,'Tester - Realm')
check('Fresh base skill does not reuse an old equipment bonus',context.bonusSkill~=10,
    'live skill=70, live modifier=0, cached bonus=10 => effectiveSkill='..tostring(context.effectiveSkill))
check('Unavailable current trait data is labeled stale or unverified',context.specialization~='999=3' or context.stale or context.incomplete,
    'old specialization is reused while profileKind='..tostring(context.profileKind)..' and stale='..tostring(context.stale))
print(('SCALING AUDIT: %d passed, %d failed; no live-client testing'):format(passed,failed))
os.exit(failed==0 and 0 or 1)
