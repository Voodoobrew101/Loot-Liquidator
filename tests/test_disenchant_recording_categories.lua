-- Different gear IDs in one disenchant category share measured results.
local checks=0
local function eq(a,b,message)
    assert(a==b,(message or '')..': '..tostring(a)..' ~= '..tostring(b));checks=checks+1
end
local function copy(t)
    if type(t)~='table' then return t end
    local result={} for key,value in pairs(t) do result[key]=copy(value) end return result
end
GetBuildInfo=function() return 'test','123456','',120105 end
time=function() return 1000 end
CreateFrame=function() return {RegisterEvent=function() end,SetScript=function() end} end
local LL={db={recordDisenchants=true,recordConversions=true},CharacterKey=function() return 'Tester-Realm' end}
assert(loadfile('LootLiquidator/CraftRecording.lua'))('LootLiquidator',LL)
assert(loadfile('LootLiquidator/ProfessionModels.lua'))('LootLiquidator',LL)
local currentSpec='delegate=10'
LL.CaptureCraftContext=function(_,recipe,f,method)
    return {character='Tester-Realm',recipeID=recipe,method=method,profession='Enchanting',
        profileKind='measured',simulated=false,skillLineID=1234,baseSkill=75,bonusSkill=5,
        effectiveSkill=80,specialization=currentSpec,equipment={},fieldStatus={equipment='measured'},
        inputExpansionID=f and f.expansionID,observed=time()}
end
local function facts(id,rarity,class,expansion)
    return {id=id,quality=rarity or 3,classID=class or 4,expansionID=expansion or 11,
        itemLevel=id,link='item:'..id..':unique-link'}
end
local function record(id,input,outputs,profile)
    local context=profile or LL:CaptureCraftContext(13262,input,'Disenchant')
    local item={itemID=input.id,quantity=1,rarity=input.quality,classID=input.classID,
        expansionID=input.expansionID,itemLevel=input.itemLevel,hyperlink=input.link}
    local ok,why=LL:RecordCraftObservation({operationID=id,recipeID=13262,method='Disenchant',
        successful=true,character='Tester-Realm',build='123456',context=context,
        inputs={item},outputs=outputs,outputCoverage='complete'})
    assert(ok,why)
    return LL.db.craftResearch.records[#LL.db.craftResearch.records]
end
local function byID(estimate,id)
    for _,material in ipairs(estimate.materials) do if material.id==id then return material end end
    error('Missing material '..id)
end
local first=record('armor-one',facts(101),{{itemID=500,quantity=2}})
record('armor-two',facts(102),{{itemID=501,quantity=1}})
LL:StartCraftStudy('another complete study')
record('armor-three',facts(103),{{itemID=500,quantity=4}})
record('weapon',facts(104,3,2),{{itemID=500,quantity=99}})
record('epic',facts(105,4),{{itemID=500,quantity=98}})
record('other-expansion',facts(106,3,4,10),{{itemID=500,quantity=97}})
local unseen=facts(999)
local estimate=assert(LL:GetLearnedDisenchantEstimate(unseen))
eq(estimate.gearKey,'gear:11:3:armor')
eq(estimate.isDisenchantCategory,true)
eq(estimate.effectiveSamples,3,'casts aggregate across gear IDs and clean studies')
eq(#estimate.memberInputItemIDs,3)
eq(#estimate.sourceRecordIDs,3,'each completed cast contributes once')
eq(byID(estimate,500).expectedQuantity,2,'units are divided by all complete category casts')
eq(byID(estimate,500).chance,2/3)
eq(byID(estimate,500).minQuantity,2)
eq(byID(estimate,500).maxQuantity,4)
eq(byID(estimate,500).quantityCounts['0'],1)
eq(byID(estimate,501).chance,1/3,'complete captures retain observed zeros for cooutputs')
eq(byID(estimate,501).quantityCounts['0'],2)
eq(LL:GetLearnedDisenchantEstimate(facts(101)).effectiveSamples,3,'studied item uses the same category')
eq(LL:GetLearnedDisenchantEstimate(facts(199,3,2)).effectiveSamples,1,'weapon results stay separate')
eq(LL:GetLearnedDisenchantEstimate(facts(199,4)).effectiveSamples,1,'rarity stays separate')
eq(LL:GetLearnedDisenchantEstimate(facts(199,3,4,10)).effectiveSamples,1,'expansion stays separate')
eq(LL:GetLearnedDisenchantEstimate(facts(199,2)),nil,'an unobserved category has no personal estimate')
eq(LL:GetLearnedDisenchantEstimate(facts(101,2)),nil,'the same item ID at another rarity cannot borrow old variant results')
-- Raw item identity and variants remain unchanged for research exports.
local d=LL.db.craftResearch
eq(d.contexts[first.contextID].inputIdentity[1].itemID,101)
eq(d.contexts[first.contextID].inputIdentity[1].hyperlink,'item:101:unique-link')
eq(d.contexts[first.contextID].inputIdentity[1].itemLevel,101)
eq(d.records[1].inputs[1].classID,4)
-- A changed specialization starts another group; no casts or denominators leak.
currentSpec='delegate=20'
LL:StartCraftStudy('new specialization')
record('new-spec',facts(107),{{itemID=500,quantity=8}})
estimate=assert(LL:GetLearnedDisenchantEstimate(unseen))
eq(estimate.effectiveSamples,1)
eq(byID(estimate,500).expectedQuantity,8)
currentSpec='delegate=10'
eq(LL:GetLearnedDisenchantEstimate(unseen).effectiveSamples,3,'an older matching profile remains usable')
-- Imported/other-character raw records cannot enter this personal category.
local foreign=copy(d.records[1]);foreign.operationID='foreign';foreign.character='Other-Realm'
foreign.studyID='foreign-study';foreign.contextID='foreign-context'
d.studies[foreign.studyID]={character='Other-Realm',build='123456'}
d.contexts[foreign.contextID]=copy(d.contexts[first.contextID]);d.contexts[foreign.contextID].character='Other-Realm'
d.records[#d.records+1]=foreign
eq(LL:GetLearnedDisenchantEstimate(unseen).effectiveSamples,3)
-- Missing physical classification is retained as exact-item evidence only.
LL:StartCraftStudy('old metadata')
local unknown=facts(201);unknown.classID=nil;unknown.expansionID=nil
record('unknown-classification',unknown,{{itemID=500,quantity=30}})
eq(LL:GetLearnedDisenchantEstimate(unseen).effectiveSamples,3)
eq(LL:GetLearnedDisenchantEstimate(unknown).effectiveSamples,1,'older exact-item observations remain usable')
local changedUnknown=copy(unknown);changedUnknown.quality=4
eq(LL:GetLearnedDisenchantEstimate(changedUnknown),nil,'known rarity still guards incompletely classified old records')
-- A censored study never supplies a partial denominator to a category.
LL:StartCraftStudy('censored')
record('censored-cast',facts(108),{{itemID=500,quantity=90}})
d.studies[d.activeStudy].censored=true
eq(LL:GetLearnedDisenchantEstimate(unseen).effectiveSamples,3)
-- A different game build cannot be pooled into the current category.
local previousBuild=GetBuildInfo
GetBuildInfo=function() return 'test','999999','',120105 end
eq(LL:GetLearnedDisenchantEstimate(unseen),nil)
GetBuildInfo=previousBuild
print('PASS: '..checks..' personal disenchant category assertions')
