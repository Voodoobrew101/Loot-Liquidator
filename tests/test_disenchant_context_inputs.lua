-- Context plumbing only: these fixtures do not assert a disenchant yield curve.
local count=0
local function check(value,message) assert(value,message);count=count+1 end
local function clone(value)
    if type(value)~='table' then return value end
    local out={} for key,item in pairs(value) do out[key]=clone(item) end return out
end
local epoch=1000000
GetTime=function()return 100 end
time=function()return epoch end
CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
local LL={db={characters={Player={professions={Enchanting=true},details={
    [2909]={parentName='Enchanting',name='Midnight Enchanting',skill=64,maxSkill=100}}}}}}
for _,name in ipairs({'Professions.lua','ConversionEngine.lua'}) do
    assert(loadfile('LootLiquidator/'..name))('LL',LL)
end
LL.CharacterKey=function()return 'Player'end
LL.ProcessingMethodMode=function()return 1 end
local operationReads=0
LL.GetCachedOperationInfo=function()
    operationReads=operationReads+1
    return {baseSkill=999,bonusSkill=150,craftingQuality=2}
end
-- Emulate the existing manual-only skill adjuster. The new input must remain
-- the original Skill even after that generic path has expanded effectiveSkill.
LL.ApplySpecializationSkill=function(_,_,_,context)
    if context.simulated then context.effectiveSkill=context.skill+95 end
    return context
end
local ranks={[107649]=31,[107647]=11,[107648]=1,[107646]=0}
local unlockRanks=1
local missingPath
C_TradeSkillUI={GetProfessionInfoBySkillLineID=function(line)
    check(line==2909,'expansion Skill line is used')
    return {skillLevel=64,maxSkillLevel=100,skillModifier=40}
end}
C_ProfSpecs={
    GetConfigIDForSkillLine=function()return 1 end,
    GetSpecTabIDsForSkillLine=function()return {1}end,
    GetRootPathForTab=function()return 107649 end,
    GetChildrenForPath=function(path)
        if path==107649 then return {107646,107647,107648}end
    end,
    GetUnlockEntryForPath=function(path)
        if path~=missingPath then return path+1000000 end
    end,
}
C_Traits={GetNodeInfo=function(_,path)
    return {currentRank=ranks[path],maxRanks=30+unlockRanks}
end,GetEntryInfo=function(_,entry)
    if entry>1000000 then return {maxRanks=unlockRanks}end
end}
local facts={id=239671,expansionID=11,quality=3,classID=4}
local function clear()
    LL._activeResearchProfileCache=nil;LL._processingContextCache=nil
end
local function conditions()
    clear()
    return LL:ProcessingPlayerConditions(facts,'Disenchant',13262)
end

local live=conditions()
local snapshot=LL.db.characters.Player.researchProfiles['Enchanting:11']
check(live.skill==64 and live.preSpecializationSkill==104,'live pre-spec Skill is base64 plus modifier40')
check(live.effectiveSkill==1149,'generic operation context remains unchanged')
check(live.preSpecializationSkill~=live.effectiveSkill,'DE does not reuse generic operation bonuses')
check(snapshot.preSpecializationSkill==104,'pre-spec Skill is saved for offline use')
check(live.specialization=='107647=11,107648=1,107649=31','raw empirical signature is preserved')
check(snapshot.specialization==live.specialization,'stored raw signature is unchanged')
check(live.specializationSignatureEncoding=='trait-node-current-rank','raw encoding is explicit')
check(live.disenchantSpecializationEncoding=='invested-points','normalized encoding is explicit')
check(live.disenchantSpecializationKnown==true,'verified allocation is known')
check(live.disenchantSpecializationPoints['107649']==30,'raw Delegate31 becomes invested30')
check(live.disenchantSpecializationPoints['107647']==10,'raw Supplier11 becomes invested10')
check(live.disenchantSpecializationPoints['107648']==0 and live.disenchantLearnedSpecializations['107648'],
    'raw learning rank records a learned path with zero invested points')
check(live.disenchantSpecializationPoints['107646']==0 and not live.disenchantLearnedSpecializations['107646'],
    'unlearned raw zero receives no learning bonus')
live.disenchantSpecializationPoints['107647']=999
live.disenchantLearnedSpecializations['107646']=true
check(snapshot.disenchantSpecializationPoints['107647']==10,'context does not mutate stored points')
check(not snapshot.disenchantLearnedSpecializations['107646'],'context does not mutate stored learning')

LL.db.characters.Offline={professions={Enchanting=true},researchProfiles={['Enchanting:11']=clone(snapshot)}}
LL.db.rateProfile=2;LL.db.rateProfileCharacter='Offline'
local previousReads=operationReads
local offline=conditions()
check(offline.profileKind=='offline-snapshot' and not offline.stale,'fresh offline snapshot is identified')
check(offline.preSpecializationSkill==104 and offline.disenchantSpecializationKnown,'offline gets saved pre-spec inputs')
check(offline.disenchantSpecializationPoints['107649']==30,'offline consumes saved normalized points')
check(operationReads==previousReads,'offline does not read current-character operation bonuses')
local savedOffline=LL.db.characters.Offline.researchProfiles['Enchanting:11']
savedOffline.observed=epoch-8*86400
offline=conditions()
check(offline.stale and offline.preSpecializationSkill==nil,'stale Skill is not a live DE model input')
check(offline.disenchantSpecializationKnown==false and offline.disenchantSpecializationPoints==nil,
    'stale allocation is unknown rather than zero')
savedOffline.observed=epoch;savedOffline.bonusSkill=nil
offline=conditions()
check(offline.preSpecializationSkill==nil,'missing modifier is not silently zero')
savedOffline.bonusSkill=40;savedOffline.disenchantSpecializationEncoding=nil
offline=conditions()
check(not offline.disenchantSpecializationKnown and offline.disenchantSpecializationPoints==nil,
    'legacy raw signatures are not guessed into an invested allocation')

LL.db.rateProfile=1;LL.db.rateProfileCharacter=nil
missingPath=107647
live=conditions()
check(live.specialization=='107647=11,107648=1,107649=31','missing mapping does not destroy the raw signature')
check(live.preSpecializationSkill==104,'Skill remains independently known when allocation mapping is missing')
check(not live.disenchantSpecializationKnown and live.disenchantSpecializationPoints==nil,
    'one missing mapping makes the normalized allocation unknown')
check(LL.db.characters.Player.researchProfiles['Enchanting:11'].disenchantSpecializationPoints==nil,
    'unknown mapping does not retain a prior normalized allocation')
missingPath=nil
local entryReader=C_Traits.GetEntryInfo;C_Traits.GetEntryInfo=nil
live=conditions()
check(not live.disenchantSpecializationKnown and live.disenchantSpecializationPoints==nil,
    'unavailable entry API is unknown rather than blind subtract-one')
C_Traits.GetEntryInfo=entryReader

-- A different verified unlock count must use that count, not a fixed offset.
unlockRanks=2;ranks[107649]=32;ranks[107647]=12;ranks[107648]=2
live=conditions()
check(live.disenchantSpecializationPoints['107649']==30 and live.disenchantSpecializationPoints['107647']==10,
    'normalization uses verified unlock maxRanks rather than assuming one')
ranks[107648]=1
live=conditions()
check(not live.disenchantSpecializationKnown,'inconsistent partially unlocked ranks are not normalized')
unlockRanks=1;ranks[107649]=0;ranks[107647]=0;ranks[107648]=0
live=conditions()
check(live.specialization=='none' and live.disenchantSpecializationKnown,'complete raw zero scan is known zero')
check(next(live.disenchantLearnedSpecializations)==nil,'zero scan invents no learned paths')

local manual={enabled=true,skill=104,specialization='107649=30,107647=10',
    learnedSpecializations={['107648']=true}}
LL.GetManualProfessionProfile=function()return manual end
LL.db.rateProfile=3;LL.db.rateProfileCharacter='Player'
local simulated=conditions()
check(simulated.simulated and simulated.preSpecializationSkill==104,'manual104 stays pre-spec104')
check(simulated.effectiveSkill==199,'existing manual skill adjuster still runs once')
check(simulated.specialization=='107649=30,107647=10' and simulated.specializationPoints['107647']==10,
    'manual invested signatures are not decremented')
check(simulated.learnedSpecializations['107648'],'manual explicit learning is retained')
check(simulated.specializationSignatureEncoding=='invested-points','manual signature encoding is explicit')
check(simulated.disenchantSpecializationPoints==nil and simulated.disenchantLearnedSpecializations==nil,
    'manual context cannot inherit live DE allocations')
check(simulated.baseSkill==nil and simulated.bonusSkill==nil,'manual context cannot inherit scanned Skill components')

-- Exercise the shared forward consumer with the actual milestone arithmetic.
-- Yield endpoints below are fixtures; parity, not their empirical validity, is
-- under test. Neither generic operation Skill nor prior manual expansion may
-- be added to the original pre-specialization input again.
GetBuildInfo=function()return '12.1.5','70961' end
assert(loadfile('LootLiquidator/ProfessionModels.lua'))('LL',LL)
local function skillRule(node,milestones,rarity)
    return {ruleID='context-skill-'..node,kind='skill-per-point',method='Disenchant',profession='Enchanting',
        expansionID=11,build=70961,nodeID=node,maxRank=30,perPoint=1,learningSkill=5,
        skillMilestones=milestones,inputRarity=rarity,applyPolicy='EXECUTE',confidence0to100=60,
        sourceClaimIDs={'context-fixture'}}
end
local curveRule={ruleID='context-curve',method='Disenchant',profession='Enchanting',expansionID=11,
    inputRarity=3,build=70961,applyPolicy='EXECUTE',confidence0to100=25,sourceKey='itemdb',
    sourceClaimIDs={'context-fixture'},rootNodeID=107649,childNodeID=107647,
    skillMaximum=290,primaryRankIDs={243602,243603},
    quantityMilestones={{rank=20,progress=.5},{rank=30,progress=.5}}}
local baseline={recordID='context-baseline',rule=curveRule,inputClassID=4,confidence=25,
    baselineProfile={effectiveSkill=0,childPoints=0},
    materials={{id=243602,expectedQuantity=.8},{id=243603,expectedQuantity=.2}},
    endpointMaterials={{id=243602,expectedQuantity=.629},{id=243603,expectedQuantity=.660}}}
LL.ItemDB={modeledDisenchantBaselines={baseline},specializationRules={
    skillRule(107649,{{rank=10,skill=5},{rank=20,skill=10},{rank=30,skill=20}}),
    skillRule(107647,{{rank=5,skill=5},{rank=10,skill=5},{rank=15,skill=5},{rank=25,skill=10},{rank=30,skill=20}},3)}}
LL.EvidenceSourceWeight=function()return 1 end
local option={name='Disenchant',recipeID=13262}
ranks[107649]=31;ranks[107647]=11;ranks[107648]=1
LL.db.rateProfile=1
local forwardLive=conditions()
local profileLive=assert(LL:DisenchantForwardProfile(facts,option,forwardLive,curveRule))
check(profileLive.preSpecializationSkill==104 and profileLive.effectiveSkill==199,
    'live raw31/11 reaches104+70+25=199 in shared forward profile')
check(profileLive.specializationSkillBonus==95 and profileLive.childPoints==10,'live child milestones are normalized')
local preservedSnapshot=clone(LL.db.characters.Player.researchProfiles['Enchanting:11'])
LL.db.rateProfile=3
local forwardManual=conditions()
local profileManual=assert(LL:DisenchantForwardProfile(facts,option,forwardManual,curveRule))
check(forwardManual.effectiveSkill==199 and profileManual.effectiveSkill==199,
    'manual forward profile does not add95 to an already expanded199')
local fallback={kind='ordinary-reference',materials={}}
local liveModel=LL:ApplyDisenchantBaseline(facts,option,fallback,forwardLive,1)
local manualModel=LL:ApplyDisenchantBaseline(facts,option,fallback,forwardManual,1)
check(liveModel.disenchantBaselineApplied and manualModel.disenchantBaselineApplied,'both profiles consume the compiled baseline')
check(liveModel.context.effectiveSkill==199 and manualModel.context.effectiveSkill==199,'projected contexts preserve parity')
for index,material in ipairs(liveModel.materials) do
    local other=manualModel.materials[index]
    check(material.id==other.id and math.abs(material.expectedQuantity-other.expectedQuantity)<1e-12,
        'live and manual profiles produce identical material quantities')
end
check(LL:ApplyDisenchantBaseline(facts,option,liveModel,forwardLive,1)==liveModel,'baseline forward adjustment is idempotent')
LL.db.rateProfile=1;missingPath=107647
local unmapped=conditions()
check(LL:DisenchantForwardProfile(facts,option,unmapped,curveRule)==nil,'missing mapping prevents a forward profile')
check(LL:ApplyDisenchantBaseline(facts,option,fallback,unmapped,1)==fallback,'missing mapping retains ordinary fallback')
missingPath=nil
LL.db.characters.Offline.researchProfiles['Enchanting:11']=preservedSnapshot
preservedSnapshot.observed=epoch-8*86400
LL.db.rateProfile=2;LL.db.rateProfileCharacter='Offline'
local stale=conditions()
check(LL:DisenchantForwardProfile(facts,option,stale,curveRule)==nil,'stale offline profile is rejected')
check(LL:ApplyDisenchantBaseline(facts,option,fallback,stale,1)==fallback,'stale profile retains ordinary fallback')
print('PASS: '..count..' disenchant snapshot, unlock mapping, offline freshness and live/manual forward input checks')
