-- Existing sanitized 70783 observations through the full 70961 quote path.
-- Source support is kept distinct from current-build applicability.
local fixture=assert(loadfile('tests/fixtures/personal-de-70783-source-subset.lua'))()
CreateFrame=function()return {RegisterEvent=function()end,SetScript=function()end}end
GetBuildInfo=function()return '12.1.5','70961','',120105 end
GetTime=function()return 100 end
local LL={db={characters={['Fixture-Character']={}},craftResearch=fixture.craftResearch,tooltipDetail=3,
    source_itemdb_weight=81,source_personal_weight=65,source_imported_weight=25}}
for _,name in ipairs({'ItemDBRuntime.lua','Professions.lua','ProfessionModels.lua','ProfessionCalculations.lua',
    'CraftRecording.lua','Observations.lua','Database.lua','ConversionEngine.lua','Badges.lua'})do
    assert(loadfile('LootLiquidator/'..name))('LootLiquidator',LL)
end
local function context()
    return {character='Fixture-Character',profession='Enchanting',recipeID=13262,method='Disenchant',
        expansionID=11,baseSkill=64,bonusSkill=40,skill=104,preSpecializationSkill=104,effectiveSkill=104,
        maxSkill=100,specialization='none',specializationKnown=true,specializationPoints={},
        learnedSpecializations={},buffs={},buffsKnown=true,stats={},profileKind='measured',simulated=false,
        fieldStatus={effectiveSkill='measured',specialization='measured'}}
end
LL.CharacterKey=function()return 'Fixture-Character'end
LL.CaptureCraftContext=function()
    -- Actual recorder reads are deliberately incomplete when its UI is closed.
    return {character='Fixture-Character',profession='Enchanting',profileKind='measured',fieldStatus={}}
end
LL.ProcessingPlayerConditions=context
LL.EligibleDisenchant=function()return true end
LL.DisenchantExpansion=function(_,f)return f.expansionID end
LL.GetOutputPrice=function()return 100 end
LL.MarkupColor=function()return ''end
LL.Money=function(_,value)return ('%.3f copper'):format(value)end
LL.ProfessionProgression=function()return {}end
LL:MigrateEvidenceSettings();assert(LL:InitializeItemDB(),LL.itemDBError)
for _,simulated in ipairs({false,true})do
LL.ProcessingPlayerConditions=function()
    local target=context()
    if simulated then target.simulated=true;target.profileKind='manual-simulation';target.fieldStatus=nil end
    return target
end
for _,mode in ipairs({2,1})do
    LL.db.disenchantDataMode=mode;LL._processingModelCache=nil
    local quote=assert(LL:EvaluateDisenchant({id=264527,classID=4,quality=3,expansionID=11,itemLevel=266,count=1}))
    assert(quote.value~=nil,'matching recorded category must have a numerical quote')
    assert(not quote.yieldModel.insufficientSamples and not quote.yieldModel.partialPrice,
        'historical source-reference status does not pretend that 200 observations are insufficient')
    local source=assert(quote.yieldModel.personalReference,'source-reference context survives fusion')
    assert(source.sourcePatchBuild=='70783' and source.targetPatchBuild=='70961',
        'full quote never relabels old observations as current-build casts')
    assert(source.currentPatchApplicabilityConfidence==0 and source.observationBuildPolicy.unchangedRatesVerified==false,
        'source support does not invent a patch no-change proof')
    assert(quote.yieldModel.personalStats.total==200,'one actual source denominator survives the whole quote')
    assert(quote.yieldModel.context.simulated==simulated,'display context is the actual selected target profile')
    assert(quote.yieldModel.observationContext.simulated~=true,'recorded source never becomes a simulated observation')
    local means={}
    for _,m in ipairs(quote.yieldModel.materials)do means[m.id]=m.expectedQuantity end
    if mode==2 or mode==1 then
        assert(math.abs(means[243602]-.9)<1e-10 and math.abs(means[243603]-.1)<1e-10,
            'matching measured profile preserves the actual shared 200-operation source rates')
        assert(#quote.yieldModel.materials==2,'unknown invested-profile fallback cannot add unrelated material branches')
        assert(type(quote.confidence)=='number' and quote.confidence>0,
            'retained measured source confidence is not discarded as unscored')
    end
    if PERSONAL_QUOTE_DIAGNOSTIC then PERSONAL_QUOTE_DIAGNOSTIC(mode,quote) end
    local tip={lines={}}
    function tip:AddLine(line)self.lines[#self.lines+1]=line end
    function tip:AddDoubleLine(left,right)self.lines[#self.lines+1]=left..' | '..right end
    LL.TooltipConversionOptions=nil
    LL:AppendRecommendationTooltip(tip,{action='D',disenchantEligible=true,
        facts={id=264527,classID=4,quality=3,expansionID=11},conversionOptions={{name='Disenchant',letter='D',value=quote.value,
        yieldModel=quote.yieldModel,available=false,eligibleInput=true,
        tooltipProfileLabel=simulated and 'Simulated' or 'Current character'}}})
    local text=table.concat(tip.lines,'\n')
    assert(not text:find('estimate',1,true),'confidence conveys source uncertainty without an estimate caveat: '..text)
    assert(text:find('90%',1,true) and text:find('10%',1,true),'actual source probabilities reach the rendered material rows')
end
end
-- A selected valuation context need not have recorder-only fieldStatus. Current-
-- build captures with different skill/talents must reach the projection policy,
-- rather than crash or borrow the unchanged measured cohort as an exact match.
for _,record in ipairs(fixture.craftResearch.records)do record.build='70961' end
for _,study in pairs(fixture.craftResearch.studies)do study.build='70961' end
local projections=0
local originalProjection=LL.ProjectPersonalEstimate
for _,simulated in ipairs({false,true})do
    for _,difference in ipairs({'skill','specialization'})do
        local selected=context()
        selected.profileKind=simulated and 'manual-simulation' or 'live'
        selected.simulated=simulated;selected.fieldStatus=nil;selected.skillLineID=2909
        if difference=='skill' then
            selected.skill=105;selected.preSpecializationSkill=105;selected.effectiveSkill=105
        else
            selected.specialization='107649=1';selected.specializationPoints={['107649']=1}
            selected.learnedSpecializations={['107649']=true}
        end
        LL.ProjectPersonalEstimate=function(self,facts,option,raw,target,targetBuild)
            projections=projections+1
            assert(target.profileKind==selected.profileKind and target.fieldStatus==nil,
                'the selected live/manual context reaches the projection policy intact')
            assert(target.effectiveSkill==selected.effectiveSkill and target.specialization==selected.specialization,
                'mismatched skill/talents are not replaced with recorder or source values')
            assert(raw.observationContext.profileKind=='measured' and raw.patchBuild=='70961' and targetBuild=='70961',
                'current-build source identity remains distinct from the selected target')
            return nil,'No approved transform for this differing profile'
        end
        local before=projections
        local result=LL:GetRecordedDisenchantCategoryEstimate(
            {id=264527,classID=4,quality=3,expansionID=11,itemLevel=266,count=1},13262,selected)
        assert(result==nil and projections>before,
            'same-build mismatched '..difference..' '..selected.profileKind..' must fail gracefully through projection policy')
    end
end
LL.ProjectPersonalEstimate=originalProjection
print('PASS: matching personal DE quote and same-build mismatched live/manual profile isolation')
