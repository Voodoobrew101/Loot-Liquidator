-- The two published Mycobloom means survive source -> baseline -> real quote.
local checks=0
local function check(v,label)assert(v,label);checks=checks+1 end
local function near(a,b,label)check(type(a)=='number'and math.abs(a-b)<1e-8,label..': '..tostring(a)..' ~= '..tostring(b))end
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
local LL={db={characters={Player={professions={Inscription=true}}},rateProfile=3,rateProfileCharacter='Player',
    professionTooltipProfiles={Inscription='@hypothetical'},source_itemdb_enabled=true,
    source_legacy_enabled=false,source_reference_enabled=false,source_personal_enabled=false,source_imported_enabled=false}}
for _,file in ipairs({'ItemDBRuntime.lua','ProfessionCatalog.lua','Professions.lua','ProfessionModels.lua',
    'ProfessionCalculations.lua','Database.lua','ConversionEngine.lua','Observations.lua','Badges.lua'})do
    assert(loadfile('LootLiquidator/'..file))('LL',LL)
end
LL.CharacterKey=function()return'Player'end
LL.GetResearchProfessionSnapshot=function()return 0,'none'end
LL.GetCachedOperationInfo=function()end
LL.GetOutputPrice=function(_,id)return id==222620 and 900 or id==222619 and 300 or 100 end
LL.CanUseConversion=function()return false,'Informational fixture','Current character'end
LL.EligibleDisenchant=function()return false end
LL.MarkupColor=function()return''end
LL.Money=function(_,v)return tostring(v)..' copper'end
LL.ProfessionProgression=function()return{}end
LL.Invalidate=function(self)self._processingContextCache=nil;self._processingModelCache=nil end
LL:MigrateEvidenceSettings()
local original=LL.ItemDB
local sources={}
for _,record in ipairs(original.processing)do
    if record.reviewedPublishedPrior and not record.reviewedBacklogModel
        and record.expansionID==10 then sources[#sources+1]=copy(record)end
end
check(#sources==2,'both exact published priors ship in compiled ItemDB')
check(LL:InitializeItemDB(),LL.itemDBError)
check(LL:SetManualProfessionProfile('Player','Inscription',10,{enabled=true,skill=0,specialization='none',stats={},buffs={}}),'full shipped-data target profile saves')
for _,record in ipairs(sources)do
    local f={id=record.inputItemID,expansionID=10,classID=7,reagentQuality=record.inputQualityRank,count=100}
    local model=assert(LL:ResolveEvidenceModel(f,{name='Mill',profession='Inscription',recipeID=444181,inputCount=10},nil,1))
    local quantity=0
    for _,material in ipairs(model.materials)do quantity=quantity+(material.expectedQuantity or 0)end
    near(quantity,record.inputItemID==210796 and 11.5 or 13.5,'full shipped-data resolver retains the published mean over weaker incompatible contexts')
end
local before=copy(sources)
local db={schemaVersion=1,processing=sources,professionProfiles=original.professionProfiles}
db.modeledProfessionBaselines=assert(loadfile('tools/profession_baselines.lua'))()(db,LL)
LL.ItemDB=db
check(LL:InitializeItemDB(),LL.itemDBError)
check(LL:SetManualProfessionProfile('Player','Inscription',10,{enabled=true,skill=0,specialization='none',stats={},buffs={}}),'zero target profile saves')
for _,record in ipairs(sources)do
    local expected=record.inputItemID==210796 and 11.5 or 13.5
    local baseline=assert(db.modeledProfessionBaselines[record.recordID])
    near(baseline.materials[1].expectedQuantity,expected,'explicit zero-profile inverse preserves the original source mean')
    check(baseline.baselineConfidence==0 and baseline.sourceProfileAssumed,'assumed source normalization retains confidence zero')
    check(record.samples==0 and record.materials[1].expectedQuantity.samples==0,'the prior adds no observed operations')
    local f={id=record.inputItemID,expansionID=10,classID=7,reagentQuality=record.inputQualityRank,count=100}
    local op={name='Mill',profession='Inscription',recipeID=444181,inputCount=10}
    local model=assert(LL:ResolveEvidenceModel(f,op,nil,1))
    local quantity,value=0,0
    for _,material in ipairs(model.materials)do
        quantity=quantity+(material.expectedQuantity or 0)
        value=value+(material.expectedQuantity or 0)*LL:GetMaterialPrice(material)
        check(material.confidence==0,'projected material uses the declared source-profile confidence zero')
        check(material.chance==nil and material.minQuantity==nil and material.maxQuantity==nil,
            'source means do not invent per-cast chance or stack bounds')
        check(not material.quantityCounts and not material.histogram,'source means do not become synthetic observed samples')
    end
    near(quantity,expected,'actual resolver conserves the published source units')
    near(LL:ValueProcessingModel(model,0,true,f),value/10,'actual value uses modeled materials per ten original herbs')
    check(model.valueConfidence==0,'tooltip uncertainty signal remains confidence zero')
    local quote
    for _,candidate in ipairs(LL:ConversionOptions(f))do if candidate.recipeID==444181 then quote=candidate end end
    check(quote and quote.yieldModel and not quote.available,'real recipe quote exists without granting action access')
    near(quote.value,value/10,'source mean reaches real quote gold valuation')
    check(quote.confidence==0,'real quote confidence remains zero')
    local tip={lines={}}
    function tip:AddLine(text)self.lines[#self.lines+1]=text end
    function tip:AddDoubleLine(a,b)self.lines[#self.lines+1]=a..' | '..b end
    LL.db.tooltipDetail=3;LL.db.showAverageQuantity=true;LL.db.showProfessionDetails=true
    LL:AppendRecommendationTooltip(tip,{facts=f,conversionOptions={quote}})
    check(table.concat(tip.lines,'\n'):lower():find('confidence',1,true),'actual tooltip renders the retained prior with its confidence')
    check(LL:ResolveEvidenceModel(f,op,nil,2)==nil,'personal-only observation mode excludes published priors')
    LL.db.source_itemdb_enabled=false;LL:Invalidate()
    check(LL:ResolveEvidenceModel(f,op,nil,1)==nil,'ItemDB source preference disables the retained prior')
    LL.db.source_itemdb_enabled=true;LL:Invalidate()
end
check(same(sources,before),'normalization, projection and rendering preserve the original numerical prior records')
-- Applicability confidence is separate from source-support blending. These
-- synthetic means/factors test that contract through the real evidence fusion;
-- they do not describe additional game studies or profession coefficients.
local function blendRecord(id,mean,confidence,samples)
    return {recordID=id,studyID=id,source=id,sourceKey='itemdb',fixedReference=true,
        method='Mill',profession='Inscription',expansionID=11,recipeID=1269575,inputItemID=900001,inputCount=10,
        baselineProfile={skill=0,preSpecializationSkill=0,specializationPoints={},stats={}},
        materials={{id=900002,expectedQuantity={value=mean,status='historical',confidence=confidence,
            samples=samples,sampleSizeKnown=samples>0},dropChance={status='unknown',confidence=0},
            minQuantity={status='unknown',confidence=0},maxQuantity={status='unknown',confidence=0}}}}
end
local ordinary,prior=blendRecord('blend:observed',2,80,100),blendRecord('blend:explicit-prior',10,20,0)
prior.reviewedPublishedPrior={kind='SYNTHETIC_CONFIDENCE_TEST'}
prior.baselineProfileConfidence=0;prior.baselineProfileAssumed=true
prior.materials[1].expectedQuantity.modelConfidenceCap=0
local records={ordinary,prior}
LL.ItemDB={schemaVersion=1,processing=records,professionProfiles=original.professionProfiles}
LL.ItemDB.modeledProfessionBaselines=assert(loadfile('tools/profession_baselines.lua'))()(LL.ItemDB,LL)
check(LL:InitializeItemDB(),LL.itemDBError)
local savedRecords=copy(records)
local facts={id=900001,expansionID=11,classID=7,count=10}
local operation={name='Mill',profession='Inscription',recipeID=1269575,inputCount=10}
LL.ProcessingPlayerConditions=function()return {character='Player',profession='Inscription',expansionID=11,
    skill=0,effectiveSkill=0,preSpecializationSkill=0,specialization='none',specializationPoints={},learnedSpecializations={},
    stats={},buffs={},simulated=true,profileKind='manual-simulation',confidenceTestTarget=true}end
local general=LL.ApplyGeneralProfessionModel
local function fuse(project)
    LL:Invalidate();LL.ApplyGeneralProfessionModel=project and general or nil
    return assert(LL:ComputeEvidenceModel(facts,operation,nil,1,LL:ProcessingPlayerConditions()))
end
local sourceBlend,identityBlend=fuse(false),fuse(true)
near(identityBlend.materials[1].expectedQuantity,sourceBlend.materials[1].expectedQuantity,
    'explicit prior identity cap cannot reweight a mixed source mean')
local expectedMean=(2*LL:EvidenceReliability(ordinary.materials[1].expectedQuantity,ordinary)
    +10*LL:EvidenceReliability(prior.materials[1].expectedQuantity,prior))
    /(LL:EvidenceReliability(ordinary.materials[1].expectedQuantity,ordinary)
    +LL:EvidenceReliability(prior.materials[1].expectedQuantity,prior))
near(identityBlend.materials[1].expectedQuantity,expectedMean,'source support determines blending before model confidence cap')
check(identityBlend.materials[1].confidence<80,'explicit zero-confidence prior still lowers displayed blended confidence')
local parameters=LL.ProfessionProfileParameters
LL.ProfessionProfileParameters=function(self,profession,expansion,context,op,f)
    local params=parameters(self,profession,expansion,context,op,f)
    if context.confidenceTestTarget then params.outputFactor=1.25;params.confidence=25 end
    return params
end
local positive=fuse(true)
near(positive.materials[1].expectedQuantity,sourceBlend.materials[1].expectedQuantity*1.25,
    'positive transform applies once without changing the sources relative support')
check(positive.materials[1].confidence<=25,'positive transform cannot exceed its explicit applicability cap')
check(ordinary.materials[1].expectedQuantity.samples==100 and prior.materials[1].expectedQuantity.samples==0,
    'source observations never change under identity or positive transforms')
LL.ProfessionProfileParameters=parameters
-- Existing imported ordinal support must be retained even if statistical
-- confidence is unknown; it must not be replaced with the fallback weight.
ordinary.materials[1].expectedQuantity.evidenceScore=70
prior.materials[1].expectedQuantity.evidenceScore=35
ordinary.materials[1].expectedQuantity.confidence=0
local ordinalSource,ordinalIdentity=fuse(false),fuse(true)
near(ordinalIdentity.materials[1].expectedQuantity,ordinalSource.materials[1].expectedQuantity,
    'existing ordinal evidence scores survive an identity model-confidence cap')
LL.ApplyGeneralProfessionModel=general
ordinary.materials[1].expectedQuantity.evidenceScore=nil
prior.materials[1].expectedQuantity.evidenceScore=nil
ordinary.materials[1].expectedQuantity.confidence=80
check(same(records,savedRecords),'confidence projection never mutates source fields or sample counts')
print('PUBLISHED MILLING RUNTIME: '..checks..' checks passed')
