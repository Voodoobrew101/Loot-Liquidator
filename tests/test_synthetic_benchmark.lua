-- Controlled observations/prices exercise the actual resolver, valuation and
-- hypothetical tooltip path. Percentages here are assumptions, not WoW rates.
local count=0
local function check(value,message) assert(value,message);count=count+1 end
local function near(actual,expected) check(type(actual)=='number' and math.abs(actual-expected)<1e-9,tostring(actual)..' ~= '..tostring(expected)) end
local function clone(value)
    if type(value)~='table' then return value end
    local result={} for key,v in pairs(value) do result[key]=clone(v) end return result
end
GetBuildInfo=function()return 'test','123456','',120105 end
GetTime=function()return 100 end
time=function()return 100 end
CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
SlashCmdList={}
wipe=function(t)for key in pairs(t)do t[key]=nil end return t end
local LL={}
for _,name in ipairs({'ProfessionModels.lua','Database.lua','Core.lua','Professions.lua','ConversionEngine.lua','Badges.lua'})do
    assert(loadfile('LootLiquidator/'..name))('LootLiquidator',LL)
end
LL.CharacterKey=function()return 'Player'end
LL.GetResearchProfessionSnapshot=function()return 50,'none',1 end
LL.GetCachedOperationInfo=function()end
LL.EligibleDisenchant=function()return false end
LL.ProfessionProgression=function()return {}end
LL.MarkupColor=function()return ''end
LL.Money=function(_,value)return tostring(value)..' copper'end
LL.GetOutputPrice=function(_,id)return ({[10]=40,[20]=100,[21]=50,[22]=10,[23]=1000})[id] end
local function field(value)
    return {value=value,status=value==nil and 'unknown' or 'measured',confidence=value==nil and 0 or 90,samples=100}
end
local function material(id,e,p,lo,hi)
    return {id=id,expectedQuantity=field(e),dropChance=field(p),minQuantity=field(lo),maxQuantity=field(hi)}
end
local conditional=material(23,.4,nil,nil,nil)
conditional.conditionalReference='ore-specific specialization unlock'
local record={recordID='synthetic:benchmark-baseline',studyID='synthetic:study',source='synthetic observations',
    sourceKey='itemdb',method='Prospect',profession='Jewelcrafting',recipeID=444,inputItemID=10,inputCount=5,
    expansionID=9,fixedReference=true,referenceConditions={},samples=100,
    materials={material(20,2,.5,2,6),material(21,0,0,1,1),material(22,nil,nil,nil,nil),conditional}}
LL.ItemDB={schemaVersion=1,version='synthetic-benchmark-tests',processing={record},mechanicRules={}}
LL.db={characters={Player={professions={Jewelcrafting=true},recipes={[444]={learned=true}}},
    Alt={professions={Jewelcrafting=true},recipes={[444]={learned=true}}}},
    rateProfile=1,professionTooltipProfiles={},tooltipDetail=3,showAverageQuantity=true}
LL:MigrateEvidenceSettings();check(LL:InitializeItemDB())
LL.Conversions={[10]={{method='Prospect',profession='Jewelcrafting',recipeID=444,inputCount=5}}}
local f={id=10,expansionID=9,classID=7,count=5,context={}}
local option={name='Prospect',recipeID=444,inputCount=5,character='Player'}
local function byID(model,id)
    for _,m in ipairs(model.materials)do if m.id==id then return m end end
end
local function save(benchmark,character,expansion,enabled)
    return LL:SetManualProfessionProfile(character or 'Player','Jewelcrafting',expansion or 9,
        {enabled=enabled~=false,benchmark=benchmark})
end
local function resolve()return assert(LL:ResolveEvidenceModel(f,option,nil,1))end
local live=resolve()
near(byID(live,20).expectedQuantity,2)
local sourceConfidence=live.confidence
check(live.unknownOutputs and live.hasConditionalReferences,'unknown and unlock-only cooutputs remain represented')
-- Validate the SavedVariables boundary and make it independent of caller tables.
local parameters={outputLevel=150,specializationBonus=20,resourcefulnessChance=50,resourcefulnessSaved=50}
check(save(parameters))
parameters.outputLevel=200
near(LL:GetManualProfessionProfile('Player','Jewelcrafting',9).benchmark.outputLevel,150)
for _,invalid in ipairs({false,2,'bad',{unknown=1},{outputLevel=-1},{outputLevel=201},{outputLevel=1.5},
    {specializationBonus=101},{resourcefulnessChance=0/0},{resourcefulnessSaved=math.huge}})do
    check(not save(invalid),'invalid benchmark must be rejected')
end
check(not LL:SetManualProfessionProfile('Player','Jewelcrafting',9,{skill=0/0}),'NaN skill rejected')
check(not LL:SetManualProfessionProfile('Player','Jewelcrafting',9,{skill=math.huge}),'infinite skill rejected')
check(LL:GetManualProfessionProfile('Player','Jewelcrafting',9).benchmark.outputLevel==150,'invalid writes preserve saved assumptions')
-- Actual display projection uses a separate database/context/cache. The real
-- recommendation and performer access remain based on the live profile.
local actual=LL:ConversionOptions(f)
check(#actual==1 and actual[1].available)
near(actual[1].value,40)
local originalCache=LL._processingModelCache
local originalContextCache=LL._processingContextCache
LL.db.professionTooltipProfiles.Jewelcrafting='@hypothetical'
local projected=LL:TooltipConversionOptions(f,actual)
check(#projected==1 and projected[1].available==false,'assumptions cannot grant recipe access')
local scenario=projected[1].yieldModel
near(byID(scenario,20).expectedQuantity,3.6)
near(scenario.expectedInputCount,3.75)
near(projected[1].value,82) -- (360 output + 1.25 saved ore * 40) / ORIGINAL five ore
check(scenario.syntheticBenchmark and scenario.provisional and scenario.simulated)
check(scenario.confidence==0 and scenario.confidenceUnscored and scenario.baselineConfidence==sourceConfidence)
check(not scenario.context.effectiveSkill and scenario.context.incomplete,'explicit assumptions also work with unknown skill')
check(byID(scenario,20).chance==nil and byID(scenario,20).minQuantity==nil and byID(scenario,20).maxQuantity==nil)
near(byID(scenario,20).sourceEstimates.itemdb.expectedQuantity,2)
near(byID(scenario,21).expectedQuantity,0);near(byID(scenario,21).chance,0)
check(byID(scenario,22).expectedQuantity==nil and scenario.unknownOutputs)
check(byID(scenario,23).expectedQuantity==nil and byID(scenario,23).conditionalExpectedQuantity==.4,
    'specialization bonus cannot turn conditional unlock estimates into valued outputs')
near(actual[1].value,40);near(byID(actual[1].yieldModel,20).expectedQuantity,2)
check(actual[1].available and LL.db.rateProfile==1 and LL._processingModelCache==originalCache
    and LL._processingContextCache==originalContextCache,'display simulation cannot alter recommendation caches or rates')
near(record.materials[1].expectedQuantity.value,2)
check(LL:ApplySyntheticBenchmark(f,option,scenario,scenario.context)==scenario,'scenario replay is idempotent')
local tip={lines={}}
function tip:AddLine(text)self.lines[#self.lines+1]=text end
function tip:AddDoubleLine(left,right)self.lines[#self.lines+1]=left..' | '..right end
LL:AppendRecommendationTooltip(tip,{action='A',rawAuction=50,netAuction=50,facts=f,conversionOptions=actual})
local text=table.concat(tip.lines,'\n')
check(text:find('Simulated assumptions',1,true),'actual hypothetical tooltip identifies assumption status')
check(not text:find('Confidence 0%',1,true),'scenario is not advertised as measured zero-percent confidence')
-- Global what-if selection uses the same actual resolver and invalidates its
-- caches when a saved setting changes.
LL.db.rateProfile=3;LL:Invalidate()
local global=resolve();near(byID(global,20).expectedQuantity,3.6)
check(resolve()==global,'resolved scenario is cached without applying assumptions twice')
local ctx=global.context
local stored=LL:GetManualProfessionProfile('Player','Jewelcrafting',9)
stored.benchmark.outputLevel=200
near(ctx.benchmark.outputLevel,150)
check(save({outputLevel=50}))
near(byID(resolve(),20).expectedQuantity,1)
check(save(nil))
local absent=resolve();check(not absent.syntheticBenchmark);near(byID(absent,20).expectedQuantity,2)
check(save({}))
local neutral=resolve();check(not neutral.syntheticBenchmark);near(neutral.confidence,sourceConfidence)
check(LL:ApplySyntheticBenchmark(f,option,neutral,neutral.context)==neutral,'neutral benchmark preserves the exact model')
check(save({outputLevel=0}))
near(byID(resolve(),20).expectedQuantity,0)
check(byID(resolve(),22).expectedQuantity==nil,'zero level cannot manufacture a mean for unknown output')
check(save({outputLevel=200},'Alt',9))
check(save({},'Player',9))
LL.db.rateProfileCharacter='Alt';LL:Invalidate()
near(byID(resolve(),20).expectedQuantity,4)
LL.db.rateProfileCharacter='Player';LL:Invalidate()
near(byID(resolve(),20).expectedQuantity,2)
check(save({outputLevel=200},'Player',10))
near(byID(resolve(),20).expectedQuantity,2)
check(save({outputLevel=200},'Player',9,false))
check(not resolve().syntheticBenchmark,'disabled simulation cannot use stored benchmark settings')
-- Resourcefulness changes input value only, replaces rather than stacks with
-- prior savings, and is ignored for unsupported methods/expansions.
local baseline=clone(live);baseline.expectedInputCount=4
local manual={simulated=true,profileKind='manual-simulation',benchmark={resourcefulnessChance=50,resourcefulnessSaved=50}}
local resource=LL:ApplySyntheticBenchmark(f,option,baseline,manual)
near(resource.expectedInputCount,3.75);near(resource.baselineExpectedInputCount,4)
near(byID(resource,20).expectedQuantity,2)
near(LL:ValueProcessingModel(resource,0,true,f),50)
near(baseline.expectedInputCount,4)
for _,unsupported in ipairs({{method='Disenchant',expansion=9},{method='Smelt',expansion=11},{method='Prospect',expansion=8}})do
    local skipped=LL:ApplySyntheticBenchmark({expansionID=unsupported.expansion},{name=unsupported.method},baseline,manual)
    near(skipped.expectedInputCount,4)
    check(skipped.syntheticResourcefulnessNote:find('skipped',1,true),'unsupported assumptions explain why savings were skipped')
end
local nonmanual={simulated=true,profileKind='offline-snapshot',benchmark={outputLevel=200}}
check(LL:ApplySyntheticBenchmark(f,option,baseline,nonmanual)==baseline,'scanned profiles cannot receive manual factors')
local damaged={simulated=true,profileKind='manual-simulation',benchmark={outputLevel=math.huge}}
check(LL:ApplySyntheticBenchmark(f,option,baseline,damaged)==baseline,'damaged SavedVariables fail closed at runtime')
local fakeContext={simulated=true,profileKind='manual-simulation',benchmark={outputLevel=200}}
local retrySource=clone(live)
local originalCompute,originalReader=LL.ComputeEvidenceModel,LL.ProcessingPlayerConditions
LL.ComputeEvidenceModel=function()return retrySource,nil,true end
LL.ProcessingPlayerConditions=function()return fakeContext end
LL:Invalidate()
near(byID(resolve(),20).expectedQuantity,4)
near(byID(retrySource,20).expectedQuantity,2)
LL.ComputeEvidenceModel=originalCompute;LL.ProcessingPlayerConditions=originalReader
print('PASS: '..count..' synthetic benchmark persistence, resolver, valuation, tooltip, cache and source-isolation assertions')
