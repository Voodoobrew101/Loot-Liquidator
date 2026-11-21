-- Source facts use the real policy/filter and actual item tooltip renderer.
-- Fixture prices demonstrate that none of these facts joins economic values.
local LL={db={tooltipDetail=3,showResearchDetails=true}}
CreateFrame=function() return {RegisterEvent=function()end,SetScript=function()end} end
GetBuildInfo=function() return '12.1.5','123456','',120105 end
GetItemInfo=function(id) return ({[16204]='Illusion Dust',[219946]='Storm Dust'})[id] end
for _,file in ipairs({'Database.lua','Observations.lua','ReviewedSourceFacts.lua','Badges.lua'}) do
    assert(loadfile('LootLiquidator/'..file))('LootLiquidator',LL)
end
LL.MarkupColor=function()return ''end
LL.Money=function(_,v)return tostring(v)..' copper'end
LL.ProfessionProgression=function()return {}end
local checks=0
local function check(ok,message)checks=checks+1;assert(ok,message)end
local function fact(id,metric,value,extra)
    local f={factID=id,method='Disenchant',inputItemID=15278,expansionID=0,
        outputItemID=16204,metric=metric,value=value,confidence0to100=0,
        sourceSupportConfidence=20,sourceKey='itemdb',sourceStudyKey='native-one',
        sourceURL='https://github.com/example/pinned-source',
        sourceProfile={skill=75,specialization='original source allocation'},nativeInputVariant='15278:0:887'}
    for k,v in pairs(extra or {}) do f[k]=v end
    return f
end
local original=fact('a','conditionalMeanUnitsPerPositiveEvent',3.5)
LL.ItemDB={reviewedSourceFacts={schemaVersion=1,facts={original}}}
local f={id=15278,expansionID=0,classID=2,quality=2,reagentQuality=1,nativeInputVariant='15278:0:0'}
local option={name='Disenchant',profession='Enchanting',letter='D',available=false,eligibleInput=false,
    value=nil,recipeID=0,yieldModel={materials={},confidence=0}}
local result=LL:ReviewedProcessingSourceFacts(f,option,{skill=250,simulated=true})
check(#result==1 and result[1].value==3.5,'source conditional quantity is queryable')
check(result[1].sourceContextOnly and result[1].targetProfileAdjusted==false,'source context never target calibration')
check(result[1].nativeInputVariant=='15278:0:887','exact original variant preserved, not declared target match')
result[1].sourceProfile.skill=999
check(original.sourceProfile.skill==75,'query returns detached metadata')
local function render(decision)
    local tip={lines={}}
    function tip:AddLine(s)self.lines[#self.lines+1]=s end
    function tip:AddDoubleLine(l,r)self.lines[#self.lines+1]=l..' | '..r end
    LL:AppendRecommendationTooltip(tip,decision or {facts=f,conversionOptions={option}})
    return table.concat(tip.lines,'\n')
end
local text=render()
check(text:find('Processing source facts',1,true),'actual tooltip includes source section without an available option')
check(text:find('3.5 units per positive result',1,true),'conditional quantity denominator rendered')
check(text:find('Confidence 0%',1,true),'explicit zero modeling confidence survives')
check(text:find('Source context: skill 75',1,true) and text:find('15278:0:887',1,true),'original profile/variant visible on real item tooltip')
check(not text:find('250',1,true),'target skill is not substituted into source fact')
for _,forbidden in ipairs({'estimate','provisional','unquantified','gold','copper','Research: 1 casts'}) do
    check(not text:find(forbidden,1,true),'source fact does not display '..forbidden)
end
check(option.available==false and option.value==nil and option.yieldModel.materials[1]==nil,'source rendering does not grant availability or fabricate output model')
check(f.nativeInputVariant=='15278:0:0' and original.value==3.5,'target and source remain unchanged')
-- A bound/vendor-only recommendation with no candidate option still exposes
-- the informational source facts, and does not add a conversion option.
local decision={facts=f,conversionOptions={},action=nil,disenchantEligible=false}
check(render(decision):find('3.5 units per positive result',1,true),'source facts survive missing option/action')
check(#decision.conversionOptions==0 and decision.action==nil,'no fake option added')

for detail=0,3 do
    LL.db.tooltipDetail=detail
    for _,research in ipairs({false,true})do
        LL.db.showResearchDetails=research
        local s=render()
        check((s:find('Processing source facts',1,true)~=nil)==(detail==3 and research),'only Research/Breakdown shows facts')
    end
end
LL.db.tooltipDetail=3;LL.db.showResearchDetails=true
for _,setting in ipairs({'source_itemdb_enabled','source_itemdb_weight','disenchantDataMode'})do
    if setting=='source_itemdb_enabled' then LL.db[setting]=false
    elseif setting=='source_itemdb_weight' then LL.db[setting]=0
    else LL.db[setting]=2 end
    check(#LL:ReviewedProcessingSourceFacts(f,option)==0,'source policy excludes '..setting)
    check(not render():find('Processing source facts',1,true),'actual tooltip respects '..setting)
    LL.db[setting]=nil
end
LL.db.professionTooltipProfiles={Enchanting='@hide'}
check(#LL:ReviewedProcessingSourceFacts(f,option)==0 and not render():find('Processing source facts',1,true),'hidden profession source facts stay hidden')
LL.db.professionTooltipProfiles=nil
check(#LL:ReviewedProcessingSourceFacts(f,option,nil,2)==0,'explicit personal-only mode filters ItemDB source facts')
check(#LL:ReviewedProcessingSourceFacts(f,{name='Prospect'})==0,'method mismatch excluded')
for _,changes in ipairs({{id=99},{expansionID=11},{classID=4},{quality=3},{reagentQuality=2}})do
    local actual={}for k,v in pairs(f)do actual[k]=v end
    for k,v in pairs(changes)do actual[k]=v end
    local constrained=fact('c','rankUnitShare',.3,{inputClassID=2,inputRarity=2,inputQualityRank=1})
    LL.ItemDB.reviewedSourceFacts.facts={constrained}
    check(#LL:ReviewedProcessingSourceFacts(actual,option)==0,'identity/category/rank mismatch excluded')
end
LL.ItemDB.reviewedSourceFacts.facts={fact('family','sourceOccurrenceFraction',.25,{inputItemID=false,inputFamilyIDs={15278,99}})}
LL.ItemDB.reviewedSourceFacts.facts[1].inputItemID=nil
check(#LL:ReviewedProcessingSourceFacts(f,option)==1,'explicit input family selector works')
LL.ItemDB.reviewedSourceFacts.facts={fact('gear','rankUnitShare',.4,{gearKey='gear:0:2:weapon'})}
LL.ItemDB.reviewedSourceFacts.facts[1].inputItemID=nil
check(#LL:ReviewedProcessingSourceFacts(f,option)==1,'exact gear group selector works')
for _,extra in ipairs({{value=-1},{value=0/0},{metric='expectedQuantity'},
    {metric='referenceMeanUnitsPerOperation'},{sourceKey='personal'},
    {metric='sourceOccurrenceFraction',value=2},{outputRank=0},
    {metric='conditionalStackRange',lower=3,upper=1}})do
    LL.ItemDB.reviewedSourceFacts.facts={fact('bad','conditionalMeanUnitsPerPositiveEvent',2,extra)}
    check(#LL:ReviewedProcessingSourceFacts(f,option)==0,'invalid dimension/identity/source/numeric fact excluded')
end
local named=fact('named','referenceMeanUnitsPerOperation',.42,{outputName='Original unnamed shard',outputRank=1})
named.outputItemID=nil
LL.ItemDB.reviewedSourceFacts.facts={named}
check(render():find('Original unnamed shard [R1]',1,true) and render():find('0.42 source units per operation',1,true),'named/unpriced source mean rendered without a fabricated item ID')
local list={original,fact('b','sourceOccurrenceFraction',.25),fact('c','conditionalStackRange',nil,{lower=1,upper=3}),fact('d','rankUnitShare',.3542)}
for i=5,15 do list[#list+1]=fact(('z%02d'):format(i),'conditionalMeanUnitsPerPositiveEvent',i)end
LL.ItemDB.reviewedSourceFacts.facts=list
check(#LL:ReviewedProcessingSourceFacts(f,option)==15,'all underlying matching facts remain queryable')
text=render()
check(text:find('source occurrences 25%',1,true),'source occurrence fraction labeled independently')
check(text:find('1–3 units per positive result',1,true),'positive stack interval rendered')
check(text:find('35.42% of source material units',1,true),'rank share denominator rendered')
check(text:find('+11 more source facts',1,true),'presentation bounded deterministically')
check(text==render(),'tooltip deterministic without storing stale render state')
-- Existing valuation/access fields are untouched even with many source facts.
option.value=765;option.available=false;option.yieldModel.materials={{id=16204,expectedQuantity=.1,netExpectedValue=7}}
local priced=render({action='A',rawAuction=1234,vendor=12,facts=f,conversionOptions={option}})
check(option.value==765 and option.available==false and option.yieldModel.materials[1].expectedQuantity==.1,'source facts do not change an existing priced option')
check(priced:find('1234 copper',1,true) and priced:find('12 copper',1,true),'existing item valuation renderer remains intact')
check(not priced:find('3.5 copper',1,true),'conditional units never become money')
LL.ItemDB.reviewedSourceFacts.facts={}
check(not render():find('Processing source facts',1,true),'source removal has no stale tooltip facts')
-- A known-rank source mean remains useful when inverse normalization is
-- unidentified. Its value/profile/epoch stay source-specific and never enterEV.
for _,case in ipairs({{'sourceProfileMeanUnitsPerInput','net-input','net input'},
    {'sourceProfileMeanUnitsPerInput','gross-input','gross input'},
    {'sourceProfileMeanUnitsPerOperation','operation','operation'}})do
    local known=fact('source-mean',case[1],2.375,{unit=case[2],outputRank=1,
        sourceProfile={skill=75,specialization='source maxed',dataDate='2024-09-24'}})
    LL.ItemDB.reviewedSourceFacts.facts={known}
    local rows=LL:ReviewedProcessingSourceFacts(f,option,{skill=999,simulated=true})
    check(#rows==1 and rows[1].outputItemID==16204 and rows[1].value==2.375,'known source mean query allowed without target adjustment')
    text=render()
    check(text:find('source-profile mean 2.375 units per '..case[3],1,true),'source quantity basis explicitly rendered')
    check(text:find('2024-09-24',1,true) and text:find('skill 75',1,true),'source profile and epoch preserved')
    check(not text:find('999',1,true) and not text:find('2.375 copper',1,true),'source mean is neither target yield nor money')
    check(option.available==false and option.value==765,'known source mean does not grant access/change valuation')
    LL.db.disenchantDataMode=2
    check(#LL:ReviewedProcessingSourceFacts(f,option)==0,'known source mean respects personal-only policy')
    LL.db.disenchantDataMode=nil
end
for _,case in ipairs({
    {'sourceRefundFractionOfReportedInputBudget',.06625,'6.625% returned units per reported nominal input budget','returned-input-per-nominal-input'},
    {'sourceModeledReturnFractionPerResourcefulnessEvent',.301136,'30.114% modeled returned-input fraction','modeled-returned-input-fraction-per-resourcefulness-event'},
    {'sourceReturnFractionPerAcceptedResourcefulnessEvent',.46729,'46.729% returned-input fraction per accepted','returned-input-fraction-per-accepted-resourcefulness-event'},
    {'sourceNominalEventsPerInput',.108,'0.108 source events per modeled input','events-per-modeled-input'},
    {'sourceNominalEventsPerOperation',.54,'0.54 source events per modeled operation','events-per-modeled-operation'}})do
    LL.ItemDB.reviewedSourceFacts.facts={fact('input-dimension',case[1],case[2],{unit=case[4]})}
    check(#LL:ReviewedProcessingSourceFacts(f,option,{})==1,'input-return/event dimension is queryable')
    local rendered=render()
    check(rendered:find(case[3],1,true),'input return/event dimension retains its own denominator: '..rendered)
    check(not rendered:find('chance',1,true) and not rendered:find(tostring(case[2])..' copper',1,true),
        'input-return/event quantity is not a probability or money')
    check(option.value==765 and option.available==false,'informational input dimensions preserve action and EV')
    LL.ItemDB.reviewedSourceFacts.facts[1].unit='probability'
    check(#LL:ReviewedProcessingSourceFacts(f,option,{})==0,'incompatible input/event dimension is rejected')
end
print('PASS: '..checks..' reviewed source-fact policy, scope, dimension and real tooltip checks')
