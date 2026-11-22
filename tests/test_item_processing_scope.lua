-- Unrelated extras stay removed; item processing and saved captures remain.
CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
GetBuildInfo=function()return '12.1.5','70961','',120105 end
GetTime=function()return 100 end
SlashCmdList={}
local LL={}
for _,file in ipairs({'ItemDBRuntime.lua','ProfessionModels.lua','ProfessionCalculations.lua',
    'Database.lua','Core.lua','Professions.lua','Settings.lua'})do
    assert(loadfile('LootLiquidator/'..file))('LootLiquidator',LL)
end
for _,name in ipairs({'GatheringSimulationModel','GatheringSimulationPreview',
    'RegisterGatheringSimulationTarget','GetGatheringSimulationTargets','IsGatheringProfession',
    'GetProfessionOpportunityTargets','ProfessionOpportunityPreview','OpportunitySimulationModel',
    'NormalizeSyntheticBenchmark','ApplySyntheticBenchmark','ProfessionThresholdNotes',
    'ProfessionAlternatives','ProfessionProgression','TokenResearchExport','TokenResearchStatus',
    'CollectMerchantTokenOffers','BuildSummary','BuildDetails','RecommendedTSMSetupText'})do
    assert(LL[name]==nil,'Removed extra API returned: '..name)
end
assert(LL.ItemDB.gatheringStudyBaselines==nil,'Gathering study archive must not ship')
assert(LL.ItemDB.professionProfiles.gatheringTargets==nil,'Gathering targets must not ship')
local captures={records={{method='Disenchant',itemID=123,stats={finesse={rating=50},craftingSpeed={rating=61}}}}}
local profiles={Player={['Mining:11']={skill=100,
    benchmark={outputLevel=200,specializationBonus=100},
    stats={finesse={percent=20},perception={percent=10},deftness={percent=5},resourcefulness={percent=8},
        craftingSpeed={rating=61},ingenuity={percent=10},concentration={percent=20}},
    statAnchors={finesse={rating=50,percent=20},resourcefulness={rating=10,percent=8},craftingSpeed={rating=61}}},
    ['Fishing:11']={skill=100},['Herbalism:11']={skill=100},['Skinning:10']={skill=100}}}
local recipe={learned=true,outputID=200,relativeDifficulty=1,canSkillUp=true,numSkillUps=2,firstCraft=true,maxTrivialLevel=50}
local saved={gatheringTargetProfiles={old={}},gatheringSimulationSelections={Mining='old'},
    processingHistory=captures,manualProfessionProfiles=profiles,tooltipDetail=3,
    collectTokenResearch=true,directTokenResearch={records={}},reagentConsumers={},
    professionOpportunitySelections={},showAverageQuantity=true,showMaterialConfidence=true,
    showProfessionThresholds=true,showTooltipExplanations=true,showProfessionDetails=true,
    professionTooltipProfiles={Fishing='@hypothetical',Herbalism='Player',Skinning='@hypothetical',Mining='Player'},
    characters={Player={recipes={[100]=recipe},reagentUses={},professionOptions={['Herbalism:11']={},['Skinning:10']={},['Mining:11']={}},
        researchProfiles={['Herbalism:11']={skill=100,stats={craftingSpeed={rating=61}}}}}}}
LL:RemoveRetiredSettings(saved)
assert(saved.gatheringTargetProfiles==nil and saved.gatheringSimulationSelections==nil,
    'Removed gathering state must be cleaned from existing saved variables')
assert(saved.processingHistory==captures and saved.manualProfessionProfiles==profiles
    and saved.tooltipDetail==3,'Processing records and profile preferences must survive cleanup')
assert(captures.records[1].stats.finesse.rating==50,'Recorded source context must remain intact')
assert(captures.records[1].stats.craftingSpeed.rating==61
    and saved.characters.Player.researchProfiles['Herbalism:11'].stats.craftingSpeed.rating==61,
    'Cleanup cannot rewrite original captures or scanned source context')
local profile=profiles.Player['Mining:11']
assert(profile.skill==100 and profile.stats.resourcefulness.percent==8
    and profile.statAnchors.resourcefulness.rating==10,'Item processing skill and stat settings must survive cleanup')
assert(profile.stats.finesse==nil and profile.stats.perception==nil and profile.stats.deftness==nil
    and profile.statAnchors.finesse==nil,'Gathering-only manual controls must not retain private saved data')
assert(profile.stats.craftingSpeed==nil and profile.stats.ingenuity==nil and profile.stats.concentration==nil
    and profile.statAnchors.craftingSpeed==nil,'Retired non-value controls leave no manual projection state')
assert(profile.benchmark==nil and profiles.Player['Fishing:11']==nil,'Retired benchmark and Fishing-page settings must be removed')
assert(saved.professionTooltipProfiles.Fishing==nil and saved.professionTooltipProfiles.Mining=='Player',
    'Hidden Fishing overrides must not survive removal of its settings page')
assert(profiles.Player['Herbalism:11']==nil and profiles.Player['Skinning:10']==nil
    and saved.professionTooltipProfiles.Herbalism==nil and saved.professionTooltipProfiles.Skinning==nil
    and saved.characters.Player.professionOptions['Herbalism:11']==nil
    and saved.characters.Player.professionOptions['Skinning:10']==nil
    and saved.characters.Player.professionOptions['Mining:11']~=nil,
    'Removed profession simulations/preferences/catalog caches are retired while Smelt options remain')
for _,key in ipairs({'collectTokenResearch','directTokenResearch','professionOpportunitySelections','reagentConsumers',
    'showAverageQuantity','showMaterialConfidence','showProfessionThresholds','showTooltipExplanations','showProfessionDetails'})do
    assert(saved[key]==nil,'Removed extra saved state returned: '..key)
end
assert(recipe.learned==true and recipe.outputID==200,'Actual learned recipe/output must survive planner cleanup')
assert(recipe.relativeDifficulty==nil and recipe.canSkillUp==nil and recipe.numSkillUps==nil
    and recipe.firstCraft==nil and recipe.maxTrivialLevel==nil and saved.characters.Player.reagentUses==nil,
    'Planner-only recipe fields and reverse indexes must be removed')
local fields=0
local function same(a,b,path)
    assert(type(a)==type(b),path..': type changed')
    if type(a)~='table'then assert(a==b,path..': value changed');fields=fields+1;return end
    assert(#a==#b,path..': length changed')
    for k,v in pairs(a)do same(v,b[k],path..'.'..tostring(k))end
    for k in pairs(b)do assert(a[k]~=nil,path..': extra key '..tostring(k))end
end
if arg and arg[1]then
    local old={}
    assert(loadfile(arg[1]))('LootLiquidator',old)
    for _,key in ipairs({'processing','mechanicRules','restrictions','tokenRewards','legacy',
        'modeledDisenchantBaselines','modeledProfessionBaselines'})do
        same(old.ItemDB[key],LL.ItemDB[key],'ItemDB.'..key)
    end
    for _,key in ipairs({'items','qualityFamilies','recipeQualityModels'})do
        same(old.ItemDB.professionProfiles[key],LL.ItemDB.professionProfiles[key],'professionProfiles.'..key)
    end
    for id,recipe in pairs(LL.ItemDB.professionProfiles.recipes)do
        same(old.ItemDB.professionProfiles.recipes[id],recipe,'recipes.'..tostring(id))
    end
end
print(('PASS: unrelated APIs/data removed, saved processing retained; %d processing/source fields unchanged'):format(fields))
