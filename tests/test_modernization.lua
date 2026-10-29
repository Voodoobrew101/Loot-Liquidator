-- Deterministic offline fixtures. WoW UI/game execution is deliberately separate.
local count=0
local function check(value,message) assert(value,message);count=count+1 end
local function eq(a,b,message) check(a==b,(message or 'mismatch')..': '..tostring(a)..' ~= '..tostring(b)) end
local function near(a,b,message) check(type(a)=='number' and math.abs(a-b)<1e-9,tostring(a)..' != '..tostring(b)) end
local function clone(t) if type(t)~='table' then return t end local out={} for k,v in pairs(t) do out[k]=clone(v) end return out end
local root='LootLiquidator/'
local frames,current,boot={},nil,nil
SlashCmdList={};max,min=math.max,math.min
function wipe(t) for k in pairs(t) do t[k]=nil end end
GetTime=function() return 100 end
time=function() return 2000000 end
GetBuildInfo=function() return '12.1.5','123456','',120105 end
UnitName=function() return 'Tester' end
GetRealmName=function() return 'Realm' end
function CreateFrame()
    local f={events={},scripts={}}
    function f:RegisterEvent(event) self.events[event]=true end
    function f:SetScript(event,fn) self.scripts[event]=fn end
    frames[#frames+1]=f
    if current=='Core.lua' then boot=f end
    return f
end
local LL={}
local manifest={}
for line in io.lines(root..'LootLiquidator.toc') do
    if line:match('%.lua$') then
        current=line;manifest[#manifest+1]=line
        assert(loadfile(root..line))('LootLiquidator',LL)
    end
end
check(not LL.itemDBError,LL.itemDBError)
eq(#manifest,20,'runtime source count')
check(LL.ApplyVerifiedMechanics and LL.ResolveEvidenceModel and LL.QueueGuildRefresh and LL.QueueBlizzardBagRefresh)
-- Names present before consolidation remain available.
for _,name in ipairs({'SetIgnoreEntry','IsIgnoredAction','CanUseConversion','RecordProfessions',
    'SetAltMethodEnabled','RegisterNativeRosterTable','TokenResearchExport','Paint','ClearButton',
    'GetLearnedDisenchantEstimate','GetLearnedProcessingEstimate','ExportProcessingData',
    'ExportDisenchantData','GetAuctionOperationNames','CreateItemIgnorePanel','RecommendedTSMSetupText'}) do
    check(type(LL[name])=='function','missing preserved API '..name)
end
LootLiquidatorDB={prospectingDataMode=2,processingModes={P=4},characters={},appearance={colors={A={.1,.2,.3}}}}
boot.scripts.OnEvent(boot,'ADDON_LOADED','LootLiquidator')
eq(LL.db.prospectingDataMode,2,'migration preserves personal-only policy')
eq(LL.db.processingModes.P,4,'migration preserves manual mode')
near(LL.db.appearance.colors.A[1],.1)
for key,defaults in pairs(LL.SourceDefaults) do
    eq(LL.db['source_'..key..'_enabled'],defaults[1]);eq(LL.db['source_'..key..'_weight'],defaults[2])
end
LL:SetEvidenceSource('itemtsm',false,17);LL:MigrateEvidenceSettings()
eq(LL.db.source_itemtsm_weight,17);eq(LL.db.source_itemtsm_enabled,false)
local migrated=clone(LL.db)
LL.db={processingFallbackMode=3,prospectingDataMode=3}
LL:MigrateEvidenceSettings();eq(LL.db.millingDataMode,2);eq(LL.db.prospectingDataMode,3)
LL.db.millingDataMode=1;LL:MigrateEvidenceSettings();eq(LL.db.millingDataMode,1,'migration runs once')
LL.db=migrated
-- Isolate engine fixtures from UI redraw effects while retaining cache invalidation.
LL.Invalidate=function(self) self._processingModelCache=nil;self._professionOperationCache=nil;self._processingContextCache=nil end
local liveConditions=LL.ProcessingPlayerConditions
LL.ProcessingPlayerConditions=function() return {skill=100,effectiveSkill=100,inputQuality=2,character='Tester - Realm',profileKind='live'} end
local function field(v,status,confidence) return {value=v,status=status or 'measured',confidence=confidence or 90} end
local function record(source,id,e,p,lo,hi)
    return {recordID=id,method='Prospect',profession='Jewelcrafting',inputItemID=10,
        inputCount=5,sourceKey=source,studyID=id,referenceContextID='cohort',
        patchBuild='123456',referenceConditions={},samples=30,source=id,fieldConfidence=90,
        materials={{id=20,expectedQuantity=field(e),dropChance=field(p),
            minQuantity=field(lo),maxQuantity=field(hi)}}}
end
local function install(records)
    LL.ItemDB={schemaVersion=1,version='fixture',processing=records,mechanicRules={}}
    check(LL:InitializeItemDB(),LL.itemDBError)
    LL:ResetEvidenceSources();LL.db.processingFallbackMode=1
end
local f={id=10,quality=3,reagentQuality=2,expansionID=11}
local option={name='Prospect',inputCount=5,recipeID=444,character='Tester - Realm'}
local function model(mode,personal) LL:Invalidate();return LL:ResolveEvidenceModel(f,option,personal,mode or 1) end
local a=record('itemdb','a',2,.5,2,6)
local b=record('itemtsm','b',4,.8,2,6)
install({a,b})
local m=model();near(m.materials[1].expectedQuantity,3.2/1.3)
near(m.sources.itemdb,1/1.3);near(m.sources.itemtsm,.3/1.3)
near(m.materials[1].chance,(.5+.8*.3)/1.3)
eq(m.materials[1].minQuantity,2);eq(m.materials[1].maxQuantity,6)
-- Price is net already; no second occurrence or fee multiplier.
LL.GetOutputPrice=function(_,id) if id==20 then return 100 end end
near(LL:ValueProcessingModel(m,10,true),(100*(3.2/1.3)-10)/5)
near(m.materials[1].netExpectedValue,100*(3.2/1.3))
LL:SetEvidenceSource('itemtsm',true,0);near(model().materials[1].expectedQuantity,2)
LL:SetEvidenceSource('itemdb',false);eq(model(),nil,'all effective weights zero')
LL:SetEvidenceSource('itemtsm',true,30);near(model().materials[1].expectedQuantity,4)
install({a,b});b.referenceContextID='different';near(model().materials[1].expectedQuantity,2)
b.referenceContextID='cohort';b.studyID='a';m=model();near(m.materials[1].expectedQuantity,2);eq(m.sources.itemtsm,nil)
-- Personal-only really excludes all external source records.
local personal={effectiveSamples=100,inputCount=5,materials={{id=20,expectedQuantity=7,chance=1,minQuantity=5,maxQuantity=10}}}
m=model(2,personal);near(m.materials[1].expectedQuantity,7);eq(m.sources.itemdb,nil);near(m.sources.personal,1)
eq(model(2),nil)
install({a});a.materials[1].expectedQuantity=field(2,'provisional',20);a.provisional=true
m=model();near(m.materials[1].expectedQuantity,2);check(m.provisional);eq(m.confidence,20)
-- Unknown means and known zero stay distinct; zero doesn't require a price.
a.materials[1].expectedQuantity=field(nil,'unknown',0);eq(model(),nil)
a.materials[1].expectedQuantity=field(0);a.materials[1].dropChance=field(0)
a.materials[1].minQuantity=field(nil,'unknown',0);a.materials[1].maxQuantity=field(nil,'unknown',0)
m=model();eq(m.materials[1].expectedQuantity,0);near(LL:ValueProcessingModel(m,0,true),0)
a.materials[1].expectedQuantity=field(2);a.materials[1].dropChance=field(nil,'unknown',0)
m=model();eq(m.materials[1].chance,nil);eq(m.materials[1].minQuantity,nil)
-- Batch units normalize means only; per-cast probabilities and bounds cannot be rescaled.
a.inputCount=10;a.materials[1].dropChance=field(.5);a.materials[1].minQuantity=field(1);a.materials[1].maxQuantity=field(6)
m=model();near(m.materials[1].expectedQuantity,1);eq(m.materials[1].chance,nil);eq(m.materials[1].minQuantity,nil)
a.inputCount=5;a.hotfixBlocked=true;eq(model(),nil);a.hotfixBlocked=nil
for _,change in ipairs({function(r)r.patchEndBuild=123455 end,function(r)r.recipeID=999 end,
    function(r)r.inputQualityRank=1 end,function(r)r.referenceConditions={skill=50} end}) do
    local r=clone(a);change(r);install({r});eq(model(),nil)
end
local bad=clone(a);bad.materials[1].dropChance.value=1.1
check(not LL:ValidateItemDB({schemaVersion=1,processing={bad}}))
check(not LL:ValidateItemDB({schemaVersion=1,processing={a,a}}))
eq(LL:ValidateItemDB({schemaVersion=999,processing={}}),false)
-- Real, explicitly simulated, and offline contexts never borrow each other's stats.
LL.ProcessingPlayerConditions=liveConditions
LL.db.characters={['Tester - Realm']={professions={Jewelcrafting={}},details={},altMethods={P=true},
    researchProfiles={}},['Alt - Realm']={researchProfiles={['Jewelcrafting:11']={skill=40,specialization='none',lineID=2,observed=1}},altMethods={P=true}}}
LL.GetResearchProfessionSnapshot=function() return 70,'12=3',1 end
C_TradeSkillUI={GetCraftingOperationInfo=function() return {baseSkill=70,bonusSkill=15,craftingQuality=2,bonusStats={}} end}
LL.db.processingModes.P=2
local c=LL:ProcessingPlayerConditions(f,'Prospect',444,'Tester - Realm')
eq(c.effectiveSkill,85);eq(c.inputQuality,2);eq(c.skill,70)
c=LL:ProcessingPlayerConditions(f,'Prospect',444,'Alt - Realm');eq(c.effectiveSkill,40);check(c.stale);eq(c.bonusSkill,nil)
check(LL:SetManualProfessionProfile('Alt - Realm','Jewelcrafting',11,{enabled=true,skill=90,specialization='12=5'}))
LL.db.processingModes.P=4
c=LL:ProcessingPlayerConditions(f,'Prospect',444,'Alt - Realm');eq(c.effectiveSkill,90);check(c.simulated);eq(c.operationStats,nil)
LL.db.processingModes.P=1
c=LL:ProcessingPlayerConditions(f,'Prospect',444,'Alt - Realm');eq(c.effectiveSkill,40);check(not c.simulated)
check(not LL:SetManualProfessionProfile('Alt - Realm','Jewelcrafting',11,{enabled=true,skill=-2}))
-- Verified transformations can bridge only explicitly covered source conditions.
LL.ProcessingPlayerConditions=function() return {skill=100,effectiveSkill=100,inputQuality=2,character='Tester - Realm',profileKind='live'} end
local reference=record('itemdb','numeric',2,.5,1,5)
reference.referenceConditions={skill=50}
install({reference});eq(model(),nil,'unbridged source skill mismatch')
local rule={ruleID='numeric-fixture-only',method='Prospect',recipeID=444,inputItemID=10,inputQualityRank=2,
    outputItemID=20,expansionID=11,sourceBuild='123456',targetBuild='123456',
    sourceReferenceContextID='cohort',targetConditions={skill=100},sourceClaimIDs={'synthetic-test'},
    evidenceStatus='VERIFIED_NUMERIC',applyPolicy='EXECUTE',applies='VERIFIED_APPLIES',
    confidence0to100=90,effectTarget='OUTPUT_UNCONDITIONAL_EXPECTATION',formulaID='MULTIPLY',parameters={multiplier=1.5}}
LL.ItemDB.mechanicRules={rule};LL.GameData.verifiedMechanicsRules=LL.ItemDB.mechanicRules
m=model();near(m.materials[1].expectedQuantity,3);eq(m.materials[1].chance,nil);eq(m.adjustment,'character-adjusted')
local raw={inputCount=5,patchBuild='123456',referenceContextID='cohort',materials={{id=20,expectedQuantity=2}}}
local adjusted=LL:ApplyVerifiedMechanics(f,option,raw)
eq(LL:ApplyVerifiedMechanics(f,option,adjusted),adjusted,'do not apply a rule twice')
local cost=clone(rule);cost.ruleID='cost-fixture';cost.effectTarget='EXPECTED_INPUT_CONSUMPTION';cost.parameters.multiplier=.8
LL.ItemDB.mechanicRules={rule,cost};LL.GameData.verifiedMechanicsRules=LL.ItemDB.mechanicRules
m=model();near(m.expectedInputCount,4)
LL.GetOutputPrice=function(_,id) return id==20 and 100 or id==10 and 50 end
near(LL:ValueProcessingModel(m,0,true,f),70)
near(m.materials[1].expectedQuantity,3,'cost dimension does not change output')
rule.parameters={};cost.parameters={}
reference.referenceConditions={}
m=model();near(m.materials[1].expectedQuantity,2);eq(m.mechanicsApplied,nil)
-- The actual option and tooltip share the final model, including value fields.
install({record('itemdb','integration',2,.5,1,5)})
LL.db.processingModes.P=2;LL.db.prospectingDataMode=1
LL.Conversions={[10]={{method='Prospect',inputCount=5,requiredSpell=444,profession='Jewelcrafting'}}}
LL.CanUseConversion=function() return true,nil,'Tester - Realm' end
LL.EligibleDisenchant=function() return false end
LL.GetLearnedProcessingEstimate=function() return nil end
f.classID=7;f.count=5
local options=LL:ConversionOptions(f)
eq(#options,1);near(options[1].value,40)
near(options[1].yieldModel.materials[1].netExpectedValue,200)
local integrationRecord=LL.ItemDB.processing[1]
local savedMaterial=clone(integrationRecord.materials[1])
integrationRecord.materials[1].expectedQuantity=field(0)
integrationRecord.materials[1].dropChance=field(0)
integrationRecord.materials[1].minQuantity=field(nil,'unknown',0)
integrationRecord.materials[1].maxQuantity=field(nil,'unknown',0)
LL:Invalidate();eq(LL:ConversionOptions(f)[1].value,0,'known zero is not insufficient data')
integrationRecord.materials[1]=savedMaterial;LL:Invalidate()

LL.db.tooltipDetail=3;LL.db.showTooltips=true;LL.db.showMaterialBreakdown=true
LL.ProfessionProgression=function() return {} end
local tooltip={lines={}}
function tooltip:AddLine(text) self.lines[#self.lines+1]=text end
function tooltip:AddDoubleLine(left,right) self.lines[#self.lines+1]=left..' '..right end
LL:AppendRecommendationTooltip(tooltip,{action='P',facts=f,conversionOptions=options,count=1,method='Prospect'})
local rendered=table.concat(tooltip.lines,'\n')
check(rendered:find('EV 2.000',1,true),'tooltip expected units')
check(rendered:find('50%',1,true),'tooltip probability')
check(rendered:find('itemdb: 100.0%',1,true),'tooltip actual source contributions')
near(options[1].yieldModel.materials[1].expectedQuantity,2,'tooltip must not recalculate')
options[1].yieldModel.confidenceUnscored=true;tooltip.lines={}
LL:AppendRecommendationTooltip(tooltip,{action='P',facts=f,conversionOptions=options,count=1,method='Prospect'})
check(table.concat(tooltip.lines,'\n'):find('Confidence unscored',1,true),'unreviewed captures do not display a numeric confidence claim')
options[1].yieldModel.confidenceUnscored=nil
-- Method off and insufficient batch remain eligibility gates.
LL.db.processingModes.P=3;eq(#LL:ConversionOptions(f),0)
LL.db.processingModes.P=2;f.count=1;eq(LL:ConversionOptions(f)[1].available,false)
-- Prices are recomputed on the same cached distribution.
LL.GetOutputPrice=function() return nil end
m=model();eq(LL:ValueProcessingModel(m,0,true),nil);check(m.partialPrice)
LL.GetOutputPrice=function() return 200 end
near(LL:ValueProcessingModel(m,0,true),80)

-- Personal recorders keep observations, but never pool another character/build/recipe.
LL.db.recordConversions=true;LL.db.processingLearning=nil
LL.GetResearchProfessionSnapshot=function() return 70,'12=3',1 end
check(LL:SaveProcessingObservation('Prospect',f,5,{[20]=2},444))
local pool=LL:MatchingProcessingResearch(f,'Prospect',5,444)
eq(pool.total,1);near(pool.mats[20].quantity,2)
check(LL:MatchingProcessingResearch(f,'Prospect',5,445)==nil,'recipe-scoped observations')
local currentCharacterKey=LL.CharacterKey
LL.CharacterKey=function() return 'Different - Realm' end
eq(LL:MatchingProcessingResearch(f,'Prospect',5,444),nil,'no cross-character pooling')
LL.CharacterKey=currentCharacterKey
local currentBuild=GetBuildInfo
GetBuildInfo=function() return '12.1.5','123457','',120105 end
eq(LL:MatchingProcessingResearch(f,'Prospect',5,444),nil,'no cross-build pooling')
GetBuildInfo=currentBuild
check(LL:ExportProcessingData():find('Prospect,10',1,true),'observation CSV remains available')
-- Primary entries without a usable mean do not hide a usable external fallback.
local unknown=record('itemdb','unknown',nil,nil,nil,nil)
unknown.materials[1].expectedQuantity.status='unknown'
local fallback=record('itemtsm','fallback',4,.8,1,6)
install({unknown,fallback});m=model();near(m.materials[1].expectedQuantity,4);eq(m.sources.itemdb,nil)
local conflict=record('itemdb','low',1,.2,1,9)
local opposite=record('itemtsm','high',9,1,1,9)
install({conflict,opposite});m=model();check(m.conflictingMeans);check(m.confidence<90)
-- Native guild-bank event dispatch preserves the guild item-instance context.
LL.db.showGuildBank=true
local evaluated,painted
LL.Evaluate=function(_,link,context) evaluated=context;return {action='V'} end
LL.Paint=function(_,button,link,result) painted=result end
LL.ClearButton=function() end
LL.RememberATTItem=function() end
local button={}
GuildBankFrame={Columns={{Buttons={button}}},IsShown=function() return true end,HookScript=function() end}
GetCurrentGuildBankTab=function() return 1 end
GetGuildBankItemLink=function(_,slot) return slot==1 and 'item:10' or nil end
GetGuildBankItemInfo=function() return nil,5 end
for _,frame in ipairs(frames) do
    if frame.events.GUILDBANKFRAME_OPENED then frame.scripts.OnEvent(frame,'GUILDBANKFRAME_OPENED') end
end
check(evaluated and evaluated.guild and evaluated.count==5 and evaluated._LLFastBadge)
check(painted and painted.action=='V')

-- Compile/load artifact has no runtime source-file or internet requirement.
local shipped={};assert(loadfile(root..'ItemDBRuntime.lua'))('LootLiquidator',shipped)
check(#shipped.ItemDB.processing>0);check(LL:ValidateItemDB(shipped.ItemDB))
local originalSettings={source_itemdb_enabled=LL.db.source_itemdb_enabled}
LL.ItemDB=shipped.ItemDB;LL:InitializeItemDB();LL:MigrateEvidenceSettings()
-- Compiler migration doesn't synthesize occurrence or conditional bounds.
for _,r in ipairs(LL.ItemDB.processing) do
    for _,material in ipairs(r.materials) do
        if r.researchRecord then
            eq(material.dropChance.value,r.researchRecord.dropChance.value)
            eq(material.minQuantity.value,r.researchRecord.yieldMin.value)
            eq(material.maxQuantity.value,r.researchRecord.yieldMax.value)
        end
    end
end
print('PASS: '..count..' modernization assertions; 20 modules loaded; in-game QA pending')
