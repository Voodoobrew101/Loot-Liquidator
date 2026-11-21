-- Sanitized existing captures:200 complete104-skill/zero-spec rarearmor
-- observations. This fixture is not200newcasts, a70961study, or a no-change
-- hotfix claim. Negative controls are separate retained source contexts.
local fixture=assert(loadfile('tests/fixtures/personal-de-70783-source-subset.lua'))()
local function copy(x)if type(x)~='table'then return x end local y={}for k,v in pairs(x)do y[k]=copy(v)end return y end
local function same(a,b)
    if type(a)~=type(b)then return false end
    if type(a)~='table'then return a==b end
    for k,v in pairs(a)do if not same(v,b[k])then return false end end
    for k in pairs(b)do if a[k]==nil then return false end end return true
end
local checks=0
local function check(v,why)checks=checks+1;assert(v,why)end
local currentBuild='70961'
CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
GetBuildInfo=function()return '12.1.5',currentBuild,'',120105 end
local live={character='Fixture-Character',profession='Enchanting',method='Disenchant',recipeID=13262,
    baseSkill=64,bonusSkill=40,preSpecializationSkill=104,effectiveSkill=104,maxSkill=100,
    specialization='none',specializationKnown=true,specializationPoints={},learnedSpecializations={},
    skillLineID=2909,profileKind='measured',simulated=false,buffs={},buffsKnown=true,
    equipment={tool='different-native-item-instance'},observed=123456,
    fieldStatus={equipment='measured',effectiveSkill='measured',specialization='measured'}}
local LL={db={craftResearch=copy(fixture.craftResearch)},CharacterKey=function()return 'Fixture-Character'end}
LL.CaptureCraftContext=function()return copy(live)end
assert(loadfile('LootLiquidator/ProfessionModels.lua'))('LootLiquidator',LL)
assert(loadfile('LootLiquidator/CraftRecording.lua'))('LootLiquidator',LL)
local rawBefore=copy(LL.db.craftResearch)
local f={id=264527,expansionID=11,quality=3,classID=4,itemLevel=266}
local estimate=assert(LL:GetLearnedDisenchantEstimate(f))
check(estimate.samples==200 and estimate.effectiveSamples==200,'only complete104zero-spec rarearmor source observations enter this category')
check(estimate.gearKey=='gear:11:3:armor','category uses expansion/rarity/armor-vs-weapon')
check(estimate.patchBuild=='70783' and estimate.sourcePatchBuild=='70783' and estimate.targetPatchBuild=='70961','historical source build never relabeled current')
check(estimate.currentPatchApplicabilityConfidence==0 and estimate.sourceApplicabilityConfidence==0,'current patch applicability remains separate from source200support')
check(estimate.observationBuildPolicy.unchangedRatesVerified==false,'no unsupported no-change patch bridge')
check(estimate.observationBuildPolicy.sourceClientVersionKnown==false,'legacy source client version remains unknown')
check(estimate.numericTransformApplied==false and estimate.personalSourceProfileMatched,'same relevant profile reuses quantities without inverse skill assumptions')
check(estimate.sourceReferenceOnly and estimate.professionProjected,'reference is available to the comparison pipeline without granting a profession')
check(estimate.coverageCensored==false and estimate.studyCoverageCensored==true,'unresolved OTHER profiles do not censor the104source subgroup; original study gap retained')
check(estimate.excludedUnresolvedOperations==0,'none of the four retained unresolved controls belongs to this104zero-spec scope')
local byID={}for _,m in ipairs(estimate.materials)do byID[m.id]=m end
check(byID[243602].expectedQuantity==.9 and byID[243603].expectedQuantity==.1,'actual source rank unit means retained')
check(byID[243602].chance==.9 and byID[243603].chance==.1,'actual material-positive operation fractions retained')
check(byID[243602].samples==200 and byID[243603].samples==200,'one shared200operation denominator, not400casts')
check(byID[243602].quantityCounts['1']==180 and byID[243602].quantityCounts['0']==20,'R1source histogram preserved')
check(byID[243603].quantityCounts['1']==20 and byID[243603].quantityCounts['0']==180,'R2source histogram preserved')
check(byID[243602].minQuantity==1 and byID[243602].maxQuantity==1,'positive-source bounds retain observed unit meaning')
check(#estimate.materials==2,'no knowledge currency or generic speculative extras invented')
for _,id in ipairs({272228,244752,245341})do
    local target=copy(f);target.id=id
    check(LL:GetLearnedDisenchantEstimate(target).samples==200,'other studied/unseen armor IDs use same tested category')
end
local weapon=copy(f);weapon.classID=2;weapon.id=264627
check(LL:GetLearnedDisenchantEstimate(weapon)==nil,'rarearmor source cannot become rareweapon evidence')
local legion=copy(f);legion.expansionID=6;legion.id=134459
check(LL:GetLearnedDisenchantEstimate(legion)==nil,'Timewarped ilvl does not reclassify Legion item as Midnight')
local source=copy(estimate.observationContext)
local manual={character='Fixture-Character',profession='Enchanting',skill=104,preSpecializationSkill=104,
    effectiveSkill=104,specialization='none',specializationPoints={},learnedSpecializations={},
    profileKind='manual-simulation',simulated=true}
local projected=assert(LL:ProjectPersonalEstimate(f,{name='Disenchant',recipeID=13262},estimate,manual,'70961'))
check(projected.samples==200 and projected.materials[1].chance==estimate.materials[1].chance,'manual104zero-spec keeps actual source probabilities/counts')
check(projected.observationContext.effectiveSkill==104 and projected.projectedContext.skill==104,'source profile and target profile stay separate')
manual.skill=0;manual.preSpecializationSkill=0;manual.effectiveSkill=0
check(LL:ProjectPersonalEstimate(f,{name='Disenchant',recipeID=13262},estimate,manual,'70961')==nil,'intentional manual0 never silently becomes104')
manual.skill=104;manual.preSpecializationSkill=104;manual.effectiveSkill=104
manual.specializationPoints[107648]=10
check(LL:ProjectPersonalEstimate(f,{name='Disenchant',recipeID=13262},estimate,manual,'70961')==nil,'source zero-spec evidence not silently reused at nonzero allocation')
manual.specializationPoints={};manual.buffs={[12345]=true}
check(LL:ReuseDisenchantSourceProfile(f,{name='Disenchant',recipeID=13262},estimate,manual,'70961')==nil,'different active buff context does not match')
manual.buffs={};manual.character='Other-Fixture-Character'
check(LL:ReuseDisenchantSourceProfile(f,{name='Disenchant',recipeID=13262},estimate,manual,'70961')==nil,'other-character access not granted by source captures')
manual.character='Fixture-Character'
local knownOld=copy(estimate);knownOld.clientVersion='12.1.0'
check(LL:ReuseDisenchantSourceProfile(f,{name='Disenchant',recipeID=13262},knownOld,manual,'70961')==nil,'known different client version requires its own policy')
check(LL:ReuseDisenchantSourceProfile(f,{name='Disenchant',recipeID=13262},estimate,manual,'70575')==nil,'future source build not projected backward')
local simulatedSource=copy(estimate);simulatedSource.observationContext.simulated=true
check(LL:ReuseDisenchantSourceProfile(f,{name='Disenchant',recipeID=13262},simulatedSource,manual,'70961')==nil,'manual source never becomes measured support')
local unknownSource=copy(estimate);unknownSource.observationContext.fieldStatus.specialization='unknown'
check(LL:ReuseDisenchantSourceProfile(f,{name='Disenchant',recipeID=13262},unknownSource,manual,'70961')==nil,'unknown source specialization never becomes zero specialization evidence')
-- The general strict recorder API still refuses censored recipes. Only the
-- zero-spec scoped source-reference query opts into complete retained records.
local matching
for _,r in ipairs(LL.db.craftResearch.records)do
    local c=LL.db.craftResearch.contexts[r.contextID]
    if c.effectiveSkill==104 and c.specialization=='none'and r.inputs[1].rarity==3 then matching=r;break end
end
check(LL:CraftBaseline(matching.studyID,matching.contextID,13262)==nil,'strict baseline/export coverage guard preserved')
local complete=assert(LL:CraftBaseline(matching.studyID,matching.contextID,13262,{allowCompleteDisenchantSubset=true}))
check(complete.studyCoverageCensored and complete.excludedUnresolvedOperations==0,'source-reference subset states coverage basis explicitly')
-- If an unresolved receipt DOES enter the exact context, it is excluded and
-- listed, never transformed into a zero bin or counted as a completed result.
local unresolved=copy(matching);unresolved.operationID='fixture-unresolved-same-context';unresolved.outputCoverage='unresolved';unresolved.outputs={}
LL.db.craftResearch.records[#LL.db.craftResearch.records+1]=unresolved
local subset=assert(LL:CraftBaseline(matching.studyID,matching.contextID,13262,{allowCompleteDisenchantSubset=true}))
check(subset.operations==complete.operations and subset.excludedUnresolvedOperations==1,'unresolved receipt does not enter source denominator')
check(subset.coverageCensored and subset.excludedUnresolvedRecordIDs[1]==unresolved.operationID,'same-context excluded receipt precisely identified')
check(same(subset.materials,complete.materials),'unresolved receipt never becomes a guessed zero result')
LL.db.craftResearch.records[#LL.db.craftResearch.records]=nil
currentBuild='70783'
check(LL:GetLearnedDisenchantEstimate(f).samples==200,'same-build source profile also survives irrelevant full-context formatting changes')
-- Raw saved observations and coverage flags are never rewritten by querying.
for id,study in pairs(rawBefore.studies)do
    check(LL.db.craftResearch.studies[id].censored==study.censored,'source study censor flag preserved')
    check(same(LL.db.craftResearch.studies[id].coverageGaps,study.coverageGaps),'source coverage gap preserved')
end
check(same(LL.db.craftResearch.records,rawBefore.records) and same(LL.db.craftResearch.contexts,rawBefore.contexts),'original records/contexts remain immutable')
print('PASS: '..checks..' sanitized existing-personal-source category/profile/build/coverage checks')
