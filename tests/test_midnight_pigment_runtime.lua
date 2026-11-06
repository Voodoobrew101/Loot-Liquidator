-- Actual archived calculator -> generated ItemDB -> quality selection/value.
-- The 13-unit source is a model, not a measured chance or cast histogram.
local checks=0
local function check(value,label) assert(value,label);checks=checks+1 end
local function near(actual,expected) check(type(actual)=='number' and math.abs(actual-expected)<1e-9,tostring(actual)..' ~= '..tostring(expected)) end
GetBuildInfo=function() return '12.1.5','70783' end
GetTime=function() return 100 end
time=function() return 100 end
CreateFrame=function() return {RegisterEvent=function()end,SetScript=function()end} end
local LL={db={characters={Player={}},source_personal_enabled=false,source_imported_enabled=false,
    tooltipDetail=3,showAverageQuantity=true,professionTooltipProfiles={Inscription='@hypothetical'}}}
assert(loadfile('LootLiquidator/ItemDBRuntime.lua'))('LL',LL)
for _,name in ipairs({'ProfessionModels.lua','Database.lua','Professions.lua','ConversionEngine.lua','Badges.lua'}) do
    assert(loadfile('LootLiquidator/'..name))('LL',LL)
end
LL:MigrateEvidenceSettings();check(LL:InitializeItemDB())
LL.TooltipConversionOptions=nil
LL.MarkupColor=function() return '' end
LL.Money=function(_,value) return tostring(value)..' copper' end
LL.ProfessionProgression=function() return {} end
local inputs={}
for _,record in ipairs(LL.ItemDB.processing) do
    if record.recordID:find('reference:calculator:gam%-midnight%-milling%-base%-yield:') then inputs[#inputs+1]=record end
end
check(#inputs==8,'all four herb families and both input ranks reach ItemDB')
local skill=364
local activeFacts
LL.ProcessingPlayerConditions=function(_,facts)
    activeFacts=facts
    return {character='Player',simulated=true,profileKind='manual-simulation',effectiveSkill=skill,
        inputQuality=facts.reagentQuality,inputRarity=facts.quality,inputClassID=facts.classID,
        skillQualityOperation={character='Player',recipeID=1269575,inputItemID=facts.id,
            inputQualityRank=facts.reagentQuality,expansionID=11,build='70783',observed=100,
            maxQuality=2,craftingQuality=1,effectiveSkill=364,highQualitySkillThreshold=365,
            allocationVerified=true,concentration=false}}
end
local rankPrices={}
for _,record in ipairs(inputs) do
    local family=record.materials[1].rankIDs
    rankPrices[family[1]]=100;rankPrices[family[2]]=200
end
LL.GetOutputPrice=function(_,id) return rankPrices[id] end
local option={name='Mill',letter='M',recipeID=1269575,inputCount=10,available=false}
local projected=0
for _,record in ipairs(inputs) do
    check(record.sourceKey=='reference' and record.sourceKind=='calculator' and record.fallbackOnly,
        'model estimates remain controlled by the reference source preference')
    check(record.realStudy==false and record.profession=='Inscription' and record.recipeID==1269575)
    check(record.samples==nil,'a workbook planning amount cannot become measured casts')
    local source=record.materials[1]
    check(#record.materials==1 and #source.rankIDs==2,'quality alternatives share one family expectation')
    near(source.expectedQuantity.value,13)
    check(source.dropChance.value==nil and source.minQuantity.value==nil and source.maxQuantity.value==nil)
    local facts={id=record.inputItemID,expansionID=11,reagentQuality=record.inputQualityRank,classID=7,quality=1,count=10}
    LL._processingModelCache=nil;skill=364
    local low=assert(LL:ResolveEvidenceModel(facts,option,nil,1))
    check(#low.materials==1);near(low.materials[1].expectedQuantity,13)
    check(low.materials[1].chance==nil and low.materials[1].minQuantity==nil)
    near(LL:ValueProcessingModel(low,0,true,facts),130)
    LL._processingModelCache=nil;skill=365
    local high=assert(LL:ResolveEvidenceModel(facts,option,nil,1))
    near(high.materials[1].expectedQuantity,13)
    if high.skillQualityApplied then
        projected=projected+1
        near(LL:ValueProcessingModel(high,0,true,facts),260)
        check(high.materials[1].rankIDs==nil and high.materials[1].id~=low.materials[1].id)
    else
        check(record.inputItemID==236778 or record.inputItemID==236779,
            'only the disputed Mana Lily rank mapping remains an unranked family')
        check(high.materials[1].rankIDs and #high.materials[1].rankIDs==2)
        near(LL:ValueProcessingModel(high,0,true,facts),130)
    end
end
check(projected==6,'three supported pigment families now calculate quality for both herb ranks')
local facts={id=236761,expansionID=11,reagentQuality=1,classID=7,quality=1,count=10}
LL._processingModelCache=nil
local model=assert(LL:ResolveEvidenceModel(facts,option,nil,1))
LL:ValueProcessingModel(model,0,true,facts)
local tip={lines={}}
function tip:AddLine(text) self.lines[#self.lines+1]=text end
function tip:AddDoubleLine(left,right) self.lines[#self.lines+1]=left..' | '..right end
local quote={name='Mill',letter='M',recipeID=1269575,inputCount=10,available=false,
    value=model.value,yieldModel=model}
LL:AppendRecommendationTooltip(tip,{action='A',facts=facts,conversionOptions={quote}})
local text=table.concat(tip.lines,'\n')
check(text:find('13.000',1,true) and text:find('chance unavailable',1,true),
    'native tooltip shows the known reference total without inventing a hit rate: '..text)
LL.CanUseConversion=function() return true,nil,'Player' end
LL.EligibleDisenchant=function() return false end
local discovered
for _,quote in ipairs(LL:ConversionOptions(facts)) do if quote.name=='Mill' then discovered=quote end end
check(discovered and discovered.recipeID==1269575 and discovered.inputCount==10,
    'actual conversion discovery retains the Midnight recipe and operation denominator')
near(discovered.yieldModel.materials[1].expectedQuantity,13)
local historical
for _,record in ipairs(LL.LegacyDB.processing) do
    if record.method=='Mill' and record.inputItemID==236761 then historical=record end
end
check(historical and historical.sourceKey=='legacy','curating the reference view never rewrites frozen historical data')
LL.db.source_reference_enabled=false;LL._processingModelCache=nil
check(LL:ResolveEvidenceModel(facts,option,nil,1)==nil,'disabled references cannot supply the model')
print('PASS: '..checks..' Midnight pigment source-family, rank, valuation and tooltip assertions')
