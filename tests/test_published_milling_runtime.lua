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
    if record.reviewedPublishedPrior and record.expansionID==10 then sources[#sources+1]=copy(record)end
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
print('PUBLISHED MILLING RUNTIME: '..checks..' checks passed')
