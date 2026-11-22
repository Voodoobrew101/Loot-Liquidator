-- Reviewed Kidneph totals -> per-input priors -> actual resolver/quote/tooltip.
local checks=0
local function check(v,m)assert(v,m);checks=checks+1 end
local function near(a,b,m)check(type(a)=='number'and math.abs(a-b)<1e-8,m..': '..tostring(a)..' ~= '..tostring(b))end
local function copy(v)if type(v)~='table'then return v end local r={}for k,x in pairs(v)do r[k]=copy(x)end return r end
local function same(a,b)
    if type(a)~=type(b)then return false end if type(a)~='table'then return a==b end
    for k,v in pairs(a)do if not same(v,b[k])then return false end end
    for k in pairs(b)do if a[k]==nil then return false end end return true
end
GetBuildInfo=function()return'12.1.5','70961'end
GetTime=function()return 100 end;time=GetTime
CreateFrame=function()return{RegisterEvent=function()end,SetScript=function()end}end
GetItemInfo=function(id)return'Item '..id end
GetItemCount=function()return 10000 end
local LL={db={characters={Player={professions={Inscription={skill=0,maxSkill=100}}}},rateProfile=1,
    professionTooltipProfiles={Inscription='Player'},source_itemdb_enabled=true,
    source_legacy_enabled=false,source_reference_enabled=false,source_personal_enabled=false,source_imported_enabled=false,
    tooltipDetail=3,showAverageQuantity=true,showProfessionDetails=true,showTooltipExplanations=true,showResearchDetails=true}}
for _,file in ipairs({'ItemDBRuntime.lua','ProfessionCatalog.lua','Professions.lua','ProfessionModels.lua',
    'ProfessionCalculations.lua','Database.lua','ConversionEngine.lua','Observations.lua','Badges.lua'})do
    assert(loadfile('LootLiquidator/'..file))('LL',LL)
end
if arg and arg[1]then assert(loadfile(arg[1]))('LL',LL)end
LL.CharacterKey=function()return'Player'end
LL.GetResearchProfessionSnapshot=function()return 0,'none'end
LL.GetCachedOperationInfo=function()end
LL.GetOutputPrice=function(_,id)return id==153635 and 100 or id==153636 and 200 or id==153669 and 300 or 50 end
LL.CanUseConversion=function()return true,nil,'Player'end -- Unknown operation must still be unavailable.
LL.EligibleDisenchant=function()return false end
LL.MarkupColor=function()return''end
LL.Money=function(_,v)return tostring(v)..' copper'end
LL.ProfessionProgression=function()return{}end
LL.Invalidate=function(self)self._processingContextCache=nil;self._processingModelCache=nil end
LL:MigrateEvidenceSettings()
local original=LL.ItemDB
local originals=copy(original.processing)
local sources={}
for _,record in ipairs(original.processing)do
    if record.reviewedPublishedPrior and record.reviewedPublishedPrior.kind=='ARCHIVED_PER_INPUT_TOTALS'then sources[#sources+1]=copy(record)end
end
check(#sources==6,'the actual prepared source compiles six complete historical herb vectors')
local totals={[152505]={814,303,136},[152506]={808,279,91},[152507]={832,313,150},
    [152508]={814,332,128},[152509]={799,311,115},[152511]={833,268,118}}
local ids={153635,153636,153669}
local sourceIDs={}
local db={schemaVersion=1,processing=sources,inputs={},professionProfiles=original.professionProfiles}
for _,record in ipairs(sources)do
    check(record.inputCount==1 and record.quantityBasis=='per-input','normalization is one input, not one purported operation')
    check(record.recipeID==nil and record.inputQualityRank==nil,'the source does not invent recipe or input rank')
    check(record.samples==0 and record.sampleSizeKnown==false,'no 200/50 nominal equivalents become observed casts')
    check(#record.materials==3,'all three pigment outcomes share one unique record')
    for _,e in ipairs(record.sourceEvidence)do
        check(not sourceIDs[e.sourceRecordID],'each reviewed row is represented once');sourceIDs[e.sourceRecordID]=true
        check(e.reportedSourceSupportConfidence==68 and e.activeSourceSupportConfidence==20,'archived strength is provenance while active reference support stays capped')
        check(e.inputsProcessed==1000 and e.reportedInputsPerCast==20,'source herb total and original batch remain separate provenance')
    end
    db.inputs[record.inputItemID]=copy(original.inputs[record.inputItemID])
    check(db.inputs[record.inputItemID].method=='Mill' and not db.inputs[record.inputItemID].operationUnverified,
        'the prior-only test retains actual shipped generic input hints without injecting operation flags')
end
LL.ItemDB=db;check(LL:InitializeItemDB(),LL.itemDBError)
local before=copy(sources)
local function material(model,id)for _,m in ipairs(model.materials or{})do if m.id==id then return m end end end
local function render(f,quote)
    local tip={lines={}}
    function tip:AddLine(s)self.lines[#self.lines+1]=s end
    function tip:AddDoubleLine(a,b)self.lines[#self.lines+1]=a..' | '..b end
    LL:AppendRecommendationTooltip(tip,{action='M',facts=f,conversionOptions={quote}})
    return table.concat(tip.lines,'\n'):lower()
end
for _,record in ipairs(sources)do
    local f={id=record.inputItemID,expansionID=7,classID=7,count=100}
    for _,batch in ipairs({1,5,20})do
        local op={name='Mill',profession='Inscription',inputCount=batch}
        local model=assert(LL:ResolveEvidenceModel(f,op,nil,1))
        check(model.reviewedPublishedPriorOnly,'the marker comes from accepted reviewed fields, without fake generic projection')
        check(not model.generalProfessionApplied,'BFA source does not claim a modern skill projection')
        local expectedValue=0
        for index,id in ipairs(ids)do
            local m=assert(material(model,id));local expected=totals[f.id][index]/1000
            near(m.expectedQuantity,expected*batch,'per-input source units rescale across requested display batches')
            near(m.confidence,0,'modeled applicability confidence remains zero')
            check(m.chance==nil and m.minQuantity==nil and m.maxQuantity==nil and m.quantityCounts==nil,
                'unit totals create neither per-cast occurrences, bounds nor histograms')
            expectedValue=expectedValue+expected*LL:GetOutputPrice(id)
        end
        near(LL:ValueProcessingModel(model,0,true,f),expectedValue,'gold per original herb does not change with display batch')
        check(model.valueConfidence==0 and not model.samples and not model.effectiveSamples,'value confidence zero is independent of any invented observed N')
        check(LL:ResolveEvidenceModel(f,op,nil,2)==nil,'personal-only mode excludes historical priors')
    end
    local quote
    for _,q in ipairs(LL:ConversionOptions(f))do if q.name=='Mill'then quote=q end end
    check(quote and quote.yieldModel and quote.available==false,'real conversion quote is informative without inventing a usable source recipe')
    check(quote.recipeID==nil and LL:BestConversion(f)==nil,'informational eligibility creates neither a recipe nor an actionable recommendation')
    local expectedQuoteValue=0
    for index,id in ipairs(ids)do expectedQuoteValue=expectedQuoteValue+totals[f.id][index]/1000*LL:GetOutputPrice(id)end
    near(quote.value,expectedQuoteValue,'actual conversion quote retains the exact published per-herb gold value')
    near(quote.confidence,0,'actual quoted confidence remains zero in scanned mode')
    check(quote.eligibleInput,'accepted reference has a reachable informational tooltip without granting action access')
    local text=render(f,quote)
    check(text:find('confidence 0%',1,true),'actual tooltip displays numeric confidence zero')
    check(not text:find('values normalized per',1,true) and not text:find('recipe batch unverified',1,true),
        'compact tooltip omits batch diagnostics while source/model denominators remain intact')
    for _,word in ipairs({'estimate','provisional','unquantified'})do check(not text:find(word,1,true),'prior-only tooltip avoids an extra '..word..' label')end
    local partial=copy(quote);partial.yieldModel=copy(quote.yieldModel);partial.yieldModel.partial=true
    partial.yieldModel.warning='Missing price for unrelated output';partial.partial=true
    -- Exercise warning rendering on the supplied incomplete quote; choosing
    -- a character would deliberately rebuild it from the complete sources.
    LL.db.professionTooltipProfiles.Inscription='@auto'
    local warning=render(f,partial)
    LL.db.professionTooltipProfiles.Inscription='Player'
    check(not warning:find('partial',1,true) and not warning:find('missing price for unrelated output',1,true),
        'normal tooltip retains numerical rows without partial/missing-price explanation panels')
    check(partial.yieldModel.partial and partial.yieldModel.warning=='Missing price for unrelated output'
        and partial.value==quote.value,'compact presentation preserves partial status and numerical value in the model')
    LL.db.source_itemdb_enabled=false;LL:Invalidate()
    check(LL:ResolveEvidenceModel(f,{name='Mill',inputCount=1},nil,1)==nil,'disabling ItemDB excludes the reviewed reference')
    LL.db.source_itemdb_enabled=true;LL.db.source_itemdb_weight=0;LL:Invalidate()
    check(LL:ResolveEvidenceModel(f,{name='Mill',inputCount=1},nil,1)==nil,'zero ItemDB weight excludes the reviewed reference')
    LL.db.source_itemdb_weight=nil;LL:Invalidate()
end
-- A genuinely counted higher-support cohort retains anchor/weight priority.
local prior=copy(sources[1]);local other=copy(prior)
other.recordID='test:measured-cohort';other.studyID=other.recordID;other.inputCount=20
other.reviewedPublishedPrior=nil;other.baselineProfile=nil;other.baselineProfileConfidence=nil
other.samples=1000;other.sampleSizeKnown=true;other.operationUnverified=nil;other.fixedReference=nil
other.referenceContextID='test:measured-profile';other.referenceConditions={};other.quantityBasis=nil
for _,m in ipairs(other.materials)do
    m.expectedQuantity={value=40,confidence=90,status='measured',samples=1000,sampleSizeKnown=true,independentConfidence=true}
end
other.materials[#other.materials+1]={id=999999,expectedQuantity={value=20,confidence=90,status='measured',samples=1000,sampleSizeKnown=true,independentConfidence=true},
    dropChance={status='unknown',confidence=0},minQuantity={status='unknown',confidence=0},maxQuantity={status='unknown',confidence=0}}
LL.ItemDB={schemaVersion=1,processing={prior,other},professionProfiles=original.professionProfiles}
check(LL:InitializeItemDB(),LL.itemDBError);LL:Invalidate()
local mixed=assert(LL:ResolveEvidenceModel({id=prior.inputItemID,expansionID=7,classID=7},{name='Mill',inputCount=1},nil,1))
check(mixed.referenceContextID=='test:measured-profile','one-input normalization cannot displace an actual measured batch anchor')
for _,id in ipairs(ids)do check(material(mixed,id).expectedQuantity>1.9,'the low-support historical prior does not outweigh a real high-support cohort')end
near(material(mixed,999999).confidence,90,'the prior does not globally cap unrelated measured output confidence')
check(not mixed.reviewedPublishedPriorOnly,'mixed unrelated sources keep their normal uncertainty labels')
other.referenceContextID=prior.referenceContextID
LL.ItemDB={schemaVersion=1,processing={prior,other},professionProfiles=original.professionProfiles}
check(LL:InitializeItemDB(),LL.itemDBError);LL:Invalidate()
local compatible=assert(LL:ResolveEvidenceModel({id=prior.inputItemID,expansionID=7,classID=7},{name='Mill',inputCount=1},nil,1))
for _,id in ipairs(ids)do
    local confidence=material(compatible,id).confidence
    check(confidence>0 and confidence<90,'compatible prior caps only its own accepted confidence contribution')
end
near(material(compatible,999999).confidence,90,'an accepted prior cannot cap a separate measured material')
check(not compatible.reviewedPublishedPriorOnly,'a genuinely mixed accepted model retains ordinary uncertainty labels')
local unreviewed=copy(prior);unreviewed.reviewedPublishedPrior=nil
LL.ItemDB={schemaVersion=1,processing={unreviewed},inputs={
    [prior.inputItemID]={method='Mill',expansion=7,operationUnverified=true}},professionProfiles=original.professionProfiles}
check(LL:InitializeItemDB(),LL.itemDBError);LL:Invalidate()
local unrelated=LL:ConversionOptions({id=prior.inputItemID,expansionID=7,classID=7,count=100})[1]
check(unrelated and unrelated.recipeID==51005 and not unrelated.eligibleInput and not unrelated.available,
    'unreviewed unverified operations retain existing recipe context and display eligibility behavior')
check(same(sources,before) and same(original.processing,originals),'source fields, totals and counts remain unchanged through normalization, pricing and rendering')
print('PUBLISHED PER-INPUT RUNTIME: '..checks..' checks passed')
