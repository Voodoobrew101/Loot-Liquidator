-- Actual catalog node IDs and exported sourced formulas exercise the normal
-- manual-profile -> context -> evidence -> valuation path. Fixture quantities
-- and prices are deterministic; they are not claimed as measured WoW rates.
local checks=0
local function check(value,label) assert(value,label);checks=checks+1 end
local function near(actual,expected,label)
    check(type(actual)=='number' and math.abs(actual-expected)<1e-8,
        (label or '')..': '..tostring(actual)..' ~= '..tostring(expected))
end
local function clone(value)
    if type(value)~='table' then return value end
    local out={} for k,v in pairs(value) do out[k]=clone(v) end return out
end
GetBuildInfo=function() return '12.1.5','70783' end
GetTime=function() return 100 end
time=function() return 100 end
CreateFrame=function() return {RegisterEvent=function()end,SetScript=function()end} end
local LL={db={characters={Player={professions={Jewelcrafting=true,Enchanting=true}}},
    rateProfile=3,rateProfileCharacter='Player',tooltipDetail=3,showAverageQuantity=true,
    source_legacy_enabled=false,source_reference_enabled=false,source_personal_enabled=false,
    source_imported_enabled=false}}
for _,name in ipairs({'Professions.lua','ProfessionModels.lua','Database.lua','ConversionEngine.lua','Badges.lua'}) do
    assert(loadfile('LootLiquidator/'..name))('LL',LL)
end
LL.CharacterKey=function() return 'Player' end
LL.GetResearchProfessionSnapshot=function() return 0,'none' end
LL.GetCachedOperationInfo=function() end
LL.MarkupColor=function() return '' end
LL.Money=function(_,value) return tostring(value)..' copper' end
LL.ProfessionProgression=function() return {} end
LL.GetOutputPrice=function(_,id) return id==212498 and 10 or 100 end
LL.Invalidate=function(self) self._processingModelCache=nil;self._processingContextCache=nil end
LL:MigrateEvidenceSettings()
local exported=assert(loadfile('database/specialization-effects.lua'))()
local rules=exported.specializationRules
check(type(rules)=='table' and #rules>0,'the sourced point rules are generated')
local function field(value)
    return {value=value,status=value==nil and 'unknown' or 'measured',confidence=value==nil and 0 or 90,samples=100}
end
local function material(id,mean)
    return {id=id,expectedQuantity=field(mean),dropChance=field(.5),minQuantity=field(1),maxQuantity=field(4)}
end
local source={recordID='specialization-fixture',studyID='controlled-fixture',source='controlled fixture',
    sourceKey='itemdb',method='Prospect',recipeID=434018,inputItemID=210930,inputCount=5,
    expansionID=10,fixedReference=true,referenceConditions={},samples=100,
    materials={material(212498,2),material(212495,1)}}
LL.ItemDB={schemaVersion=1,version='specialization-runtime',processing={source},mechanicRules={},
    specializationRules=rules,specializationRevision=exported.revision}
check(LL:InitializeItemDB(),LL.itemDBError)
local facts={id=210930,expansionID=10,reagentQuality=1,classID=7,count=5}
local option={name='Prospect',recipeID=434018,inputCount=5}
local function set(profession,expansion,points,skill)
    check(LL:SetManualProfessionProfile('Player',profession,expansion,
        {enabled=true,skill=skill or 0,specialization=points,buffs={}}),'manual point slider profile saves')
end
local function resolve(input,operation)
    return LL:ResolveEvidenceModel(input or facts,operation or option,nil,1)
end
local function output(model,id)
    for _,m in ipairs(model.materials) do if m.id==id then return m end end
end
set('Jewelcrafting',10,'none')
local neutral=assert(resolve())
near(output(neutral,212498).expectedQuantity,2)
near(LL:ValueProcessingModel(neutral,0,true,facts),24)
set('Jewelcrafting',10,'98660=10')
local half=assert(resolve())
near(output(half,212498).expectedQuantity,1.8,'ten Ruby points replace ten percent of the amber reservoir')
near(output(half,212495).expectedQuantity,1.2)
near(LL:ValueProcessingModel(half,0,true,facts),27.6)
set('Jewelcrafting',10,'98660=20')
local full=assert(resolve())
near(output(full,212498).expectedQuantity,1.6)
near(output(full,212495).expectedQuantity,1.4)
near(LL:ValueProcessingModel(full,0,true,facts),31.2,'point slider changes the normal priced quote')
near(source.materials[1].expectedQuantity.value,2,'raw donor evidence remains immutable')
near(source.materials[2].expectedQuantity.value,1,'raw target evidence remains immutable')
check(full.specializationEffectsApplied and full.provisional and full.simulated)
check(full.confidence<=70 and full.ruleConfidence<=70,'source confidence caps derived values')
check(output(full,212498).chance==nil and output(full,212495).chance==nil,'a replacement mean does not fabricate cast probabilities')
check(output(full,212495).minQuantity==nil and output(full,212495).maxQuantity==nil,'old quantity bounds are not retained after conversion')
near(output(full,212495).sourceEstimates.itemdb.expectedQuantity,1,'source mean stays available as provenance')
check(LL:ApplySpecializationEffects(facts,option,full,full.context)==full,'cached replay never applies the point effect twice')
local function render(quote)
    local tip={lines={}}
    function tip:AddLine(text) self.lines[#self.lines+1]=text end
    function tip:AddDoubleLine(left,right) self.lines[#self.lines+1]=left..' | '..right end
    LL:AppendRecommendationTooltip(tip,{action='P',facts=facts,conversionOptions={{name='Prospect',letter='P',
        profession='Jewelcrafting',recipeID=434018,inputCount=5,available=true,value=31.2,yieldModel=quote}}})
    return table.concat(tip.lines,'\n')
end
local text=render(full)
check(text:find('1.400',1,true) and text:find('1.600',1,true),'changed node-point quantities reach actual material tooltip rows')
LL.db.showAverageQuantity=false
text=render(full)
check(not text:find('1.400',1,true) and not text:find('1.600',1,true),'specialization effects respect the saved average-display preference')
near(full.value,31.2,'hiding averages does not change the specialization valuation')
LL.db.showAverageQuantity=true
set('Jewelcrafting',10,'98659=20,98660=20,98661=20,98662=20')
local all=assert(resolve())
near(output(all,212498).expectedQuantity,.4,'all colors share the original reservoir')
near(output(all,212495).expectedQuantity,1.4)
near(output(all,212508).expectedQuantity,.4)
near(output(all,212511).expectedQuantity,.4)
near(output(all,212505).expectedQuantity,.4)
local total=0 for _,m in ipairs(all.materials) do total=total+(m.expectedQuantity or 0) end
near(total,3,'replacement conserves total gem units across all four sliders')
set('Jewelcrafting',10,'98660=21')
near(output(assert(resolve()),212498).expectedQuantity,2,'out-of-range points cannot amplify a rule')
set('Jewelcrafting',10,'none')
local reset=assert(resolve())
near(output(reset,212498).expectedQuantity,2,'zero points restore the selected baseline')
check(not reset.specializationEffectsApplied)
local context={simulated=true,profileKind='manual-simulation',skill=100,effectiveSkill=100,
    profession='Enchanting',specialization='107649=10,107648=20,107647=30'}
local green={id=999991,expansionID=11,quality=2,classID=4}
local rare=clone(green);rare.id=999992;rare.quality=3
local epic=clone(green);epic.id=999993;epic.quality=4
local de={name='Disenchant',recipeID=13262,inputCount=1}
near(LL:ApplySpecializationSkill(green,de,context).effectiveSkill,130,'green receives only the generic and uncommon skill nodes')
near(LL:ApplySpecializationSkill(rare,de,context).effectiveSkill,140,'rare receives only the generic and rare skill nodes')
near(LL:ApplySpecializationSkill(epic,de,context).effectiveSkill,110,'epic does not receive green or rare node bonuses')
local projected=LL:ApplySpecializationSkill(rare,de,context)
near(LL:ApplySpecializationSkill(rare,de,projected).effectiveSkill,140,'effective skill adds node bonuses exactly once')
near(context.effectiveSkill,100,'the caller-owned base context is unchanged')
projected.specialization='107649=5';projected.specializationPoints=nil
near(LL:ApplySpecializationSkill(rare,de,projected).effectiveSkill,105,'recalculating lower points uses the stored base skill')
local wrongEra=clone(rare);wrongEra.expansionID=9
check(LL:ApplySpecializationSkill(wrongEra,de,context)==context,'Midnight point effects do not cross expansions')
local live=clone(context);live.simulated=false;live.profileKind='live'
check(LL:ApplySpecializationSkill(rare,de,live)==live,'real scanned effective skill is never double-boosted')
local unknown=clone(context);unknown.specialization=nil;unknown.specializationPoints=nil
check(LL:ApplySpecializationSkill(rare,de,unknown)==unknown,'unknown specialization remains usable without inferred points')
local beforeBuild=GetBuildInfo
GetBuildInfo=function() return 'test','70782' end
check(LL:ApplySpecializationSkill(rare,de,context)==context,'a rule from another build cannot alter the context')
GetBuildInfo=beforeBuild
LL.db.source_itemdb_enabled=false;LL:Invalidate()
check(resolve()==nil,'points cannot bypass a disabled evidence source')
LL.db.source_itemdb_enabled=true;LL:Invalidate()
check(LL:ResolveEvidenceModel(facts,option,nil,2)==nil,'personal-only policy stays strict')
-- One real Prospecting Pro point crosses a captured exact-input quality
-- threshold; this changes price without inventing a quantity multiplier.
local qualityExport=assert(loadfile('database/skill-quality-rules.lua'))()
local qualityRule
for _,rule in ipairs(qualityExport.skillQualityRules) do if rule.method=='Prospect' then qualityRule=rule end end
local family=qualityRule.outputFamilies[1]
local low,high=family.rankItemIDs[1],family.rankItemIDs[2]
local qualityInput={id=10,expansionID=11,reagentQuality=1,classID=7,count=5}
local qualityOption={name='Prospect',recipeID=1231127,inputCount=5}
local qualitySource=clone(source)
qualitySource.recordID='quality-points';qualitySource.studyID=qualitySource.recordID
qualitySource.inputItemID=10;qualitySource.recipeID=1231127;qualitySource.expansionID=11
qualitySource.materials={material(low,2)};qualitySource.materials[1].rankIDs={low,high}
LL.ItemDB={schemaVersion=1,version='point-quality',processing={qualitySource},mechanicRules={},
    specializationRules=rules,skillQualityRules=qualityExport.skillQualityRules}
check(LL:InitializeItemDB(),LL.itemDBError)
local previousPrice,previousOperation=LL.GetOutputPrice,LL.GetSkillQualityOperation
LL.GetOutputPrice=function(_,id) return id==high and 300 or 100 end
LL.GetSkillQualityOperation=function()
    return {recipeID=1231127,inputItemID=10,inputQualityRank=1,expansionID=11,build='70783',
        observed=100,craftingQuality=2,highQualitySkillThreshold=365,
        character='Player',maxQuality=2,allocationVerified=true,concentration=false}
end
set('Jewelcrafting',11,'none',364)
local lowQuote=assert(resolve(qualityInput,qualityOption))
check(lowQuote.materials[1].id==low)
near(LL:ValueProcessingModel(lowQuote,0,true,qualityInput),40)
set('Jewelcrafting',11,'106982=1',364)
local highQuote=assert(resolve(qualityInput,qualityOption))
check(highQuote.materials[1].id==high,'one sourced specialization skill point changes captured output quality')
near(highQuote.context.effectiveSkill,365)
near(highQuote.materials[1].expectedQuantity,2,'skill quality selection preserves total units')
near(LL:ValueProcessingModel(highQuote,0,true,qualityInput),120)
check(highQuote.ruleConfidence<=70,'the skill point source caps a quality projection')
LL.GetOutputPrice=previousPrice;LL.GetSkillQualityOperation=previousOperation
-- The shipped category resolver must choose the observed max-specialization
-- reference only at BOTH required point caps. It covers every matching item.
local shipped={};assert(loadfile('LootLiquidator/ItemDBRuntime.lua'))('LL',shipped)
LL.ItemDB=shipped.ItemDB;check(LL:InitializeItemDB(),LL.itemDBError)
set('Enchanting',11,'none')
local categoryBase=assert(resolve(rare,de))
local baseShard=output(categoryBase,243602).expectedQuantity
set('Enchanting',11,'107649=30,107647=29')
local below=assert(resolve(rare,de))
near(output(below,243602).expectedQuantity,baseShard,'a below-cap node cannot claim the max-specialization study')
set('Enchanting',11,'107649=30,107647=30')
local studied=assert(resolve(rare,de))
near(output(studied,243602).expectedQuantity,.629,'both point caps select the source-backed shard result')
near(output(studied,243603).expectedQuantity,.660)
check(output(studied,243602).chance==nil,'the units-only capstone reference does not invent occurrence rates')
check(studied.gearKey=='gear:11:3:armor' and studied.specializationEffectsApplied)
for _,m in ipairs(studied.materials) do check(m.confidence<=60,'material confidence respects the matched point-context scope') end
local requested=LL:ProcessingPlayerConditions(rare,'Disenchant',13262)
local personalOnly={inputCount=1,referenceContextID='personal-only',confidence=90,
    materials={{id=243602,expectedQuantity=1,confidence=90}}}
local unchangedReference=LL:ApplySpecializationEffects(rare,de,personalOnly,requested)
check(not unchangedReference.specializationReferenceRule and not unchangedReference.specializationEffectsApplied,
    'an excluded external reference cannot be claimed for a personal-only model')
local original=clone(rare);original.id=239671
near(output(assert(resolve(original,de)),243602).expectedQuantity,.629,'source and unseen items use the same matching reference')
local weapon=clone(rare);weapon.classID=2
local weaponContext=LL:ProcessingPlayerConditions(weapon,'Disenchant',13262)
check(not weaponContext.referenceContextID,'armor evidence is not applied to a rare weapon')
set('Enchanting',11,'none')
near(output(assert(resolve(rare,de)),243602).expectedQuantity,baseShard,'reset restores ordinary category research')
print('PASS: '..checks..' sourced specialization points, shared reservoir, scope, skill, reference selection and valuation assertions')
