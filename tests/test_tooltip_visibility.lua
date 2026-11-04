-- Regression fixtures for the screenshot paths: milling, prospecting, and
-- conflicting reference evidence. Every Advanced switch is independent.
local LL={db={}}
CreateFrame=function() return {RegisterEvent=function()end,SetScript=function()end} end
assert(loadfile('LootLiquidator/Badges.lua'))('LootLiquidator',LL)
LL.MarkupColor=function()return ''end
LL.Money=function(_,v)return tostring(v)..' copper'end
LL.SourceOrder={'fixture'}
LL.ProfessionProgression=function()return {}end
local cases={
    {168487,'Mill','M','Reference fallback; current skill/patch applicability unverified'},
    {188658,'Prospect','P','Reference fallback; current skill/patch applicability unverified'},
    {123919,'Prospect','P','Reference fallback; conflicting source mean replaced by a conservative estimate'},
}
local function contains(text,needle,expected)
    assert((text:find(needle,1,true)~=nil)==expected,needle..' expected '..tostring(expected)..' in:\n'..text)
end
local renders=0
for _,case in ipairs(cases) do
    local material={id=10,chance=.2,minQuantity=1,maxQuantity=2,expectedQuantity=.3,
        netExpectedValue=25,provisional=true,unavailableReason='Conditional output excluded from current value',
        derivedMean=true,inconsistentFields=true,rankReferences={{id=11,chance=.1,minQuantity=1,maxQuantity=3}},
        sourceEstimates={fixture={dropChance=.2,inputCount=5,expectedQuantity=.3,sourceConflict=true,appliedRule='fixture rule'}},
        boundsSource='fixture bounds',personalHistogram={[1]=2},personalSamples=2}
    local model={inputCount=5,materials={material,{id=12}},provisional=true,partial=true,
        confidence=33,warning=case[4],adjustment='fixture processing adjustment',samples=2,sources={fixture=1},
        context={profession='Jewelcrafting',effectiveSkill=104,character='Tester',profileKind='live'}}
    local option={name=case[2],letter=case[3],category='destroy',available=false,value=50,yieldModel=model,
        why='Ability manually indicated, but no character/recipe verified',character='Tester'}
    local decision={action=case[3],facts={id=case[1],classID=7},converted=50,vendor=5,
        conversionOptions={option,{name='Craft',profession='Engineering',letter='C',value=20,available=false,
        why='No eligible character with verified recipe/unlock'},
        {name='Smelt',letter='S',available=false}}}
    for level=0,3 do
        for mask=0,7 do
            local processing=mask%2==1
            local profession=math.floor(mask/2)%2==1
            local research=mask>=4
            LL.db={professionTooltipProfiles={Inscription="@hypothetical",Jewelcrafting="@hypothetical",Mining="@hypothetical",Engineering="@hypothetical",},tooltipDetail=level,showTooltipExplanations=processing,
                showProfessionDetails=profession,showResearchDetails=research}
            local tip={lines={}}
            function tip:AddLine(s)self.lines[#self.lines+1]=s end
            function tip:AddDoubleLine(l,r)self.lines[#self.lines+1]=l..' | '..r end
            LL:AppendRecommendationTooltip(tip,decision)
            local text=table.concat(tip.lines,'\n')
            if level==0 then assert(text=='','Off stays empty even with every Advanced switch on')
            else
                contains(text,'provisional',true)
                contains(text,'unavailable estimate',true)
                contains(text,'incomplete data',true)
                contains(text,'50 copper',true)
                contains(text,'Per 5 input',level==3 and processing)
                contains(text,'fixture processing adjustment',level==3 and processing)
                contains(text,'value counts only outputs',level==3 and processing)
                contains(text,option.why,level>=2 and profession)
                contains(text,'No eligible character with verified recipe/unlock',level>=2 and profession)
                contains(text,'On: Tester',level>=2 and profession)
                contains(text,'skill 104',level==3 and profession)
                contains(text,case[4],level==3 and research)
                for _,note in ipairs({'Conditional output excluded','Estimated average:',
                    'Source range retained','Separate rank reference:', 'Source fields disagree',
                    'Profession rule:','Conditional bounds:','Personal x1:', 'effective contribution','Research: 2 casts',
                    'Insufficient Data: no researched yield model'}) do
                    contains(text,note,level==3 and research)
                end
                contains(text,'~20% Material 10 [1-2]',level==3)
                contains(text,'5 copper',level>=2) -- per-input material and vendor prices
                contains(text,'Material 12 (chance unavailable) [yield unavailable]',level==3)
                contains(text,'Insufficient Data',level>=2)
            end
            assert(option.value==50 and material.netExpectedValue==25 and model.partial and model.provisional,
                'rendering preserves valuation and eligibility')
            assert(option.available==false and model.materials[1]==material,'cached models unchanged')
            renders=renders+1
        end
    end
end
print('PASS: '..renders..' tooltip renders: three screenshot paths, four levels, eight Advanced switch combinations')
-- Also use the current shipped evidence for the exact reported item IDs.
LL={}
GetBuildInfo=function()return '12.1.5','123456','',120105 end
GetTime=function()return 100 end
for _,name in ipairs({'ItemDBRuntime.lua','ProfessionModels.lua','Database.lua','ConversionEngine.lua','Badges.lua'}) do
    assert(loadfile('LootLiquidator/'..name))('LootLiquidator',LL)
end
LL.db={professionTooltipProfiles={Inscription="@hypothetical",Jewelcrafting="@hypothetical",Mining="@hypothetical",Engineering="@hypothetical",},tooltipDetail=3,source_legacy_enabled=false,source_personal_enabled=false,source_imported_enabled=false}
LL:MigrateEvidenceSettings()
assert(LL:InitializeItemDB(),LL.itemDBError)
LL.GetOutputPrice=function()return 100 end -- fixture copper prices
LL.ProcessingPlayerConditions=function()return {}end
LL.MarkupColor=function()return ''end
LL.Money=function(_,v)return tostring(v)..' copper'end
LL.ProfessionProgression=function()return {}end
LL.TooltipConversionOptions=nil -- Render this fixture's explicitly supplied models.
for _,case in ipairs(cases) do
    local facts={id=case[1],classID=7,expansionID=case[1]==168487 and 7 or case[1]==188658 and 9 or 6}
    local model=assert(LL:ResolveEvidenceModel(facts,{name=case[2],inputCount=5},nil,1))
    local value=LL:ValueProcessingModel(model,0,true)
    assert(value and value>0 and #model.materials>0,'reported item has priced outputs')
    local function render(research)
        LL.db.showResearchDetails=research
        local tip={lines={}}
        function tip:AddLine(s)self.lines[#self.lines+1]=s end
        function tip:AddDoubleLine(l,r)self.lines[#self.lines+1]=l..' | '..r end
        LL:AppendRecommendationTooltip(tip,{action='A',facts=facts,conversionOptions={{name=case[2],
            letter=case[3],available=false,value=value,yieldModel=model,
            why='Ability manually indicated, but no character/recipe verified'}}})
        return table.concat(tip.lines,'\n')
    end
    local compact=render(false)
    contains(compact,'Reference fallback',false)
    contains(compact,'Ability manually indicated',false)
    contains(compact,'provisional',true)
    contains(compact,'unavailable estimate',true)
    if model.warning then contains(render(true),model.warning,true) end
    assert(LL:ValueProcessingModel(model,0,true)==value,'real evidence valuation unchanged')
end
print('PASS: shipped evidence for 168487, 188658 and 123919 keeps prices and compact warnings; research toggle restores full warnings')
